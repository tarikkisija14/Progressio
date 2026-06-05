using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.AchievmentRequests;
using Progressio.Model.Responses.AchievementResponses;
using Progressio.Model.SearchObjects;
using Progressio.Services.Base;
using Progressio.Services.Database;
using Progressio.Services.Database.Entities;

namespace Progressio.Services.Services
{
    public class AchievementService
        : BaseCRUDService<Achievement, AchievementResponse, AchievementSearchObject, AchievementInsertRequest, AchievementUpdateRequest>,
          IAchievementService
    {
        private readonly ILogger<AchievementService> _logger;

        public AchievementService(
            ApplicationDbContext db,
            IValidator<AchievementInsertRequest> insertValidator,
            IValidator<AchievementUpdateRequest> updateValidator,
            ILogger<AchievementService> logger)
            : base(db, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        protected override IQueryable<Achievement> AddFilter(IQueryable<Achievement> query, AchievementSearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search.Code))
                query = query.Where(a => a.Code.Contains(search.Code));

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(a => a.Name.Contains(search.Name));

            return query;
        }

        protected override async Task BeforeInsertAsync(AchievementInsertRequest request, Achievement entity)
        {
            var codeExists = await _db.Achievements.AnyAsync(a => a.Code == request.Code);
            if (codeExists)
                throw new BusinessException($"An achievement with code '{request.Code}' already exists.");
        }

        public async Task<PagedResult<UserAchievementResponse>> GetUserAchievementsAsync(int userId, BaseSearchObject search)
        {
            var userExists = await _db.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
                throw new NotFoundException("User", userId);

            return await QueryUserAchievementsAsync(userId, search);
        }

        public async Task<PagedResult<UserAchievementResponse>> GetMyAchievementsAsync(int currentUserId, BaseSearchObject search)
        {
            return await QueryUserAchievementsAsync(currentUserId, search);
        }

        private async Task<PagedResult<UserAchievementResponse>> QueryUserAchievementsAsync(int userId, BaseSearchObject search)
        {
            var query = _db.UserAchievements
                .Include(ua => ua.User)
                .Include(ua => ua.Achievement)
                .Where(ua => ua.UserId == userId);

            var totalCount = await query.CountAsync();
            var pageSize = Math.Min(search.PageSize, 100);

            var items = await query
                .OrderByDescending(ua => ua.EarnedAt)
                .Skip((search.Page - 1) * pageSize)
                .Take(pageSize)
                .Select(ua => new UserAchievementResponse
                {
                    Id = ua.Id,
                    UserId = ua.UserId,
                    UserFullName = ua.User.FirstName + " " + ua.User.LastName,
                    AchievementId = ua.AchievementId,
                    AchievementCode = ua.Achievement.Code,
                    AchievementName = ua.Achievement.Name,
                    AchievementDescription = ua.Achievement.Description,
                    AchievementIconUrl = ua.Achievement.IconUrl,
                    EarnedAt = ua.EarnedAt
                })
                .ToListAsync();

            return new PagedResult<UserAchievementResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = pageSize
            };
        }
    }
}