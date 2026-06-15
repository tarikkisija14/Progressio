using System.Security.Cryptography;
using System.Text;

namespace Progressio.Commom.Services;

public sealed class CryptoService
{
    private readonly byte[] _tokenHashKey;

    public CryptoService(string tokenHashKey)
    {
        if (string.IsNullOrWhiteSpace(tokenHashKey) || tokenHashKey.Length < 32)
            throw new ArgumentException(
                "Token hash key must contain at least 32 characters.",
                nameof(tokenHashKey));

        _tokenHashKey = Encoding.UTF8.GetBytes(tokenHashKey);
    }

    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(
            password,
            BCrypt.Net.BCrypt.GenerateSalt(12));
    }

    public bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }

    public string GenerateSecureToken()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    }

    public string HashToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new ArgumentException("Token is required.", nameof(token));

        using var hmac = new HMACSHA256(_tokenHashKey);
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}