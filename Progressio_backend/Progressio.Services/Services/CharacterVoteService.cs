using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Progressio.Model.Exceptions;
using Progressio.Model.Requests.VoteRequests;
using Progressio.Model.Responses.VoteResponses;
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
    public class CharacterVoteService : ICharacterVoteService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<CharacterVoteService> _logger;
        private readonly IValidator<CharacterVoteRequest> _voteValidator;

        public CharacterVoteService(
        ApplicationDbContext db,
        ILogger<CharacterVoteService> logger,
        IValidator<CharacterVoteRequest> voteValidator)
        {
            _db = db;
            _logger = logger;
            _voteValidator = voteValidator;
        }

        public async Task<CharacterVoteResponse?> VoteAsync(int userId, CharacterVoteRequest request)
        {
            var validationResult = await _voteValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new BusinessException(string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage)));


            var character = await _db.Characters
                .FirstOrDefaultAsync(c => c.Id == request.CharacterId)
                ?? throw new NotFoundException("Character", request.CharacterId);


            if (request.EpisodeId.HasValue)
            {
                var episodeExists = await _db.Episodes.AnyAsync(e => e.Id == request.EpisodeId.Value);
                if (!episodeExists)
                    throw new NotFoundException("Episode", request.EpisodeId.Value);
            }

            if (request.ChapterId.HasValue)
            {
                var chapterExists = await _db.Chapters.AnyAsync(c => c.Id == request.ChapterId.Value);
                if (!chapterExists)
                    throw new NotFoundException("Chapter", request.ChapterId.Value);
            }


            var existing = await _db.CharacterVotes
                .FirstOrDefaultAsync(v =>
                    v.UserId == userId &&
                    v.CharacterId == request.CharacterId &&
                    v.EpisodeId == request.EpisodeId &&
                    v.ChapterId == request.ChapterId);

            if (existing is not null)
            {
                if (existing.VoteType == request.VoteType)
                {

                    _db.CharacterVotes.Remove(existing);
                    await _db.SaveChangesAsync();
                    _logger.LogInformation("User {UserId} removed vote for Character {CharacterId}", userId, request.CharacterId);
                    return null;
                }
                else
                {

                    existing.VoteType = request.VoteType;
                    await _db.SaveChangesAsync();
                    _logger.LogInformation("User {UserId} changed vote for Character {CharacterId} to {VoteType}", userId, request.CharacterId, request.VoteType);
                    return MapToResponse(existing, character.Name);
                }
            }


            var vote = new CharacterVote
            {
                UserId = userId,
                CharacterId = request.CharacterId,
                EpisodeId = request.EpisodeId,
                ChapterId = request.ChapterId,
                VoteType = request.VoteType,
                CreatedAt = DateTime.UtcNow
            };

            _db.CharacterVotes.Add(vote);
            await _db.SaveChangesAsync();

            _logger.LogInformation("User {UserId} voted {VoteType} for Character {CharacterId}", userId, request.VoteType, request.CharacterId);

            return MapToResponse(vote, character.Name);
        }
        public async Task<PagedResult<CharacterVoteResponse>> GetMyVotesAsync(
            int userId,
            BaseSearchObject search)
        {
            var query = _db.CharacterVotes
                .AsNoTracking()
                .Where(v => v.UserId == userId);

            var totalCount = await query.CountAsync();
            var items = await query
                .OrderByDescending(v => v.CreatedAt)
                .Skip((search.Page - 1) * search.PageSize)
                .Take(search.PageSize)
                .Select(v => new CharacterVoteResponse
                {
                    Id = v.Id,
                    UserId = v.UserId,
                    CharacterId = v.CharacterId,
                    CharacterName = v.Character.Name,
                    EpisodeId = v.EpisodeId,
                    ChapterId = v.ChapterId,
                    VoteType = v.VoteType,
                    CreatedAt = v.CreatedAt
                })
                .ToListAsync();

            return new PagedResult<CharacterVoteResponse>
            {
                Items = items,
                TotalCount = totalCount,
                Page = search.Page,
                PageSize = search.PageSize
            };
        }
        private static CharacterVoteResponse MapToResponse(CharacterVote vote, string characterName)
        {
            return new CharacterVoteResponse
            {
                Id = vote.Id,
                UserId = vote.UserId,
                CharacterId = vote.CharacterId,
                CharacterName = characterName,
                EpisodeId = vote.EpisodeId,
                ChapterId = vote.ChapterId,
                VoteType = vote.VoteType,
                CreatedAt = vote.CreatedAt
            };
        }

    }
}

