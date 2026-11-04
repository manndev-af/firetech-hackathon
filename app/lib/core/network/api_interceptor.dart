/// Hooks for adding request headers and handling API responses.
/// Implementations can be injected into [ApiClient] when needed.
abstract interface class ApiInterceptor {
  Future<Map<String, String>> onRequest(Map<String, String> headers);

  Future<void> onResponse(int statusCode, Map<String, String> headers);
}
