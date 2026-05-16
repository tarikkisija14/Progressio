using System.Security.Cryptography;
using System.Text;

namespace Progressio.Commom.Services;

public class CryptoService
{
    
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password, BCrypt.Net.BCrypt.GenerateSalt(12));
    }

   
    public bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }

   
    public string GenerateSecureToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    
    public string HashToken(string token)
    {
        var saltedToken = token + "progressio_salt_2025";
        var bytes = Encoding.UTF8.GetBytes(saltedToken);
        var hash = SHA256.HashData(bytes);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}