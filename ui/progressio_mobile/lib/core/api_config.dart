class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5193/api/',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String resolve(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase$normalizedPath';
  }

  static String? resolveResource(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final value = path.trim();
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return value;

    final apiUri = Uri.parse(baseUrl);
    final origin = apiUri.replace(path: '/', query: null, fragment: null);
    final relativePath = value.startsWith('/') ? value.substring(1) : value;
    return origin.resolve(relativePath).toString();
  }
}
