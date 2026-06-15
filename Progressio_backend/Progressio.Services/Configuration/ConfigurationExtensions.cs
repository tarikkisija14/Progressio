using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Progressio.Services.Configuration
{
    public static class ConfigurationExtensions
    {
        public static string GetRequiredValue(this IConfiguration configuration, string key)
        {
            var value = configuration[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Configuration value '{key}' is required.");

            return value;
        }

        public static int GetRequiredInt(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequiredValue(key);
            if (!int.TryParse(value, out var parsed))
                throw new InvalidOperationException($"Configuration value '{key}' must be a valid integer.");

            return parsed;
        }

        public static double GetRequiredDouble(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequiredValue(key);
            if (!double.TryParse(
                    value,
                    System.Globalization.NumberStyles.Float,
                    System.Globalization.CultureInfo.InvariantCulture,
                    out var parsed))
            {
                throw new InvalidOperationException(
                    $"Configuration value '{key}' must be a valid invariant-culture number.");
            }

            return parsed;
        }

        public static bool GetRequiredBool(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequiredValue(key);
            if (!bool.TryParse(value, out var parsed))
                throw new InvalidOperationException($"Configuration value '{key}' must be true or false.");

            return parsed;
        }
    }
}
