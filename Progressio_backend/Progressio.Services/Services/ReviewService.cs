using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Enums;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.ReviewRequests;
using Progressio.Model.Responses.ReviewResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Services
{
    public class ReviewService : IReviewService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<ReviewService> _logger;
        private readonly IValidator<ReviewInsertRequest> _insertValidator;
        private readonly IValidator<ReviewUpdateRequest> _updateValidator;


        public ReviewService(
        ApplicationDbContext db,
        ILogger<ReviewService> logger,
        IValidator<ReviewInsertRequest> insertValidator,
        IValidator<ReviewUpdateRequest> updateValidator)
        {
            _db = db;
            _logger = logger;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }

        public async Task<ReviewResponse> CreateReviewAsync(int userId, ReviewInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));


            var content = await _db.Contents
                .FirstOrDefaultAsync(c => c.Id == request.ContentId && c.IsActive)
                ?? throw new NotFoundException("Content", request.ContentId);


            var progress = await _db.UserContentProgresses
                .FirstOrDefaultAsync(p => p.UserId == userId && p.ContentId == request.ContentId);

            if (progress is null || progress.Status != ProgressStatus.Completed)
                throw new BusinessException("You can only review content that you have completed.");


           
            var existing = await _db.Reviews
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ContentId == request.ContentId && r.IsVisible);

            if (existing is not null)
                throw new BusinessException("You have already reviewed this content.");

            var review = new Review
            {
                UserId = userId,
                ContentId = request.ContentId,
                Rating = request.Rating,
                Title = request.Title,
                Body = request.Body,
                HasSpoiler = request.HasSpoiler,
                CreatedAt = DateTime.UtcNow,
                IsVisible = true
            };

            _db.Reviews.Add(review);

            
            await RecalculateAvgRatingAsync(content);

            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} created a review for Content {ContentId}", userId, request.ContentId);

            return await BuildReviewResponseAsync(review.Id);
        }
        public async Task<ReviewResponse> UpdateReviewAsync(int userId, int reviewId, ReviewUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));

            var review = await _db.Reviews
                .Include(r => r.Content)
                .FirstOrDefaultAsync(r => r.Id == reviewId && r.IsVisible)
                ?? throw new NotFoundException("Review", reviewId);

            if (review.UserId != userId)
                throw new ForbiddenException("You can only edit your own reviews.");

            var oldRating = review.Rating;

            review.Rating = request.Rating;
            review.Title = request.Title;
            review.Body = request.Body;
            review.HasSpoiler = request.HasSpoiler;

          
            if (oldRating != request.Rating)
                await RecalculateAvgRatingAsync(review.Content);

            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} updated review {ReviewId}", userId, reviewId);

            return await BuildReviewResponseAsync(review.Id);
        }
        public async Task<PagedResult<ReviewResponse>> GetReviewsForContentAsync(ReviewSearchObject searchObject)
        {
            var query = _db.Reviews
                .Include(r => r.User)
                .Include(r => r.Content)
                .Where(r => r.IsVisible)
                .AsQueryable();

            if (searchObject.ContentId.HasValue)
                query = query.Where(r => r.ContentId == searchObject.ContentId.Value);


            if (searchObject.HideSpoilers == true)
                query = query.Where(r => !r.HasSpoiler);

            var totalCount = await query.CountAsync();

            var pageSize = Math.Min(searchObject.PageSize, 100);
            var skip = (searchObject.Page - 1) * pageSize;

            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .Select(r => new ReviewResponse
                {
                    Id = r.Id,
                    UserId = r.UserId,
                    UserFullName = r.User.FirstName + " " + r.User.LastName,
                    UserProfileImageUrl = r.User.ProfileImageUrl,
                    ContentId = r.ContentId,
                    ContentTitle = r.Content.Title,
                    Rating = r.Rating,
                    Title = r.Title,
                    Body = r.Body,
                    HasSpoiler = r.HasSpoiler,
                    CreatedAt = r.CreatedAt,
                    IsVisible = r.IsVisible,
                    LikeCount = r.LikeCount
                })
                .ToListAsync();

            return new PagedResult<ReviewResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = searchObject.Page,
                PageSize = pageSize
            };
        }
        public async Task<ReviewResponse?> GetMyReviewForContentAsync(int userId, int contentId)
        {
            var review = await _db.Reviews
                .Include(r => r.User)
                .Include(r => r.Content)
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ContentId == contentId && r.IsVisible);

            if (review is null)
                return null;

            return new ReviewResponse
            {
                Id = review.Id,
                UserId = review.UserId,
                UserFullName = review.User.FirstName + " " + review.User.LastName,
                UserProfileImageUrl = review.User.ProfileImageUrl,
                ContentId = review.ContentId,
                ContentTitle = review.Content.Title,
                Rating = review.Rating,
                Title = review.Title,
                Body = review.Body,
                HasSpoiler = review.HasSpoiler,
                CreatedAt = review.CreatedAt,
                IsVisible = review.IsVisible,
                LikeCount = review.LikeCount
            };
        }
        public async Task AdminDeleteReviewAsync(int reviewId)
        {
            var review = await _db.Reviews
                .FirstOrDefaultAsync(r => r.Id == reviewId)
                ?? throw new NotFoundException("Review", reviewId);

           
            if (!review.IsVisible)
            {
                _logger.LogInformation("Admin delete on already-hidden review {ReviewId} — no-op.", reviewId);
                return;
            }

            review.IsVisible = false;

            var content = await _db.Contents.FirstOrDefaultAsync(c => c.Id == review.ContentId);
            if (content is not null)
                await RecalculateAvgRatingAsync(content);

            await _db.SaveChangesAsync();

            _logger.LogInformation("Admin soft-deleted review {ReviewId}", reviewId);
        }
      
        private async Task RecalculateAvgRatingAsync(Content content)
        {
            var visibleRatings = await _db.Reviews
                .Where(r => r.ContentId == content.Id && r.IsVisible)
                .Select(r => r.Rating)
                .ToListAsync();

            content.TotalRatings = visibleRatings.Count;
            content.AvgRating = visibleRatings.Count > 0
                ? Math.Round(visibleRatings.Average(r => r), 2)
                : 0;
        }
        private async Task<ReviewResponse> BuildReviewResponseAsync(int reviewId)
        {
            var review = await _db.Reviews
                .Include(r => r.User)
                .Include(r => r.Content)
                .FirstAsync(r => r.Id == reviewId);

            return new ReviewResponse
            {
                Id = review.Id,
                UserId = review.UserId,
                UserFullName = review.User.FirstName + " " + review.User.LastName,
                UserProfileImageUrl = review.User.ProfileImageUrl,
                ContentId = review.ContentId,
                ContentTitle = review.Content.Title,
                Rating = review.Rating,
                Title = review.Title,
                Body = review.Body,
                HasSpoiler = review.HasSpoiler,
                CreatedAt = review.CreatedAt,
                IsVisible = review.IsVisible,
                LikeCount = review.LikeCount
            };
        }
    }
}