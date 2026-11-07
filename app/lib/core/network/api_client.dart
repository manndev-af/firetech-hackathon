import 'dart:convert';
import 'dart:io';

import '../utils/api_exception.dart';
import 'api_interceptor.dart';

/// Small `dart:io` API client foundation. Supply the backend base URI at
/// composition time; no environment-specific URL is assumed here.
class ApiClient {
  ApiClient({
    required this.baseUri,
    HttpClient? httpClient,
    this.interceptors = const [],
  }) : _httpClient = httpClient ?? HttpClient();

  final Uri baseUri;
  final HttpClient _httpClient;
  final List<ApiInterceptor> interceptors;

  Future<Object?> get(String path, {Map<String, String> headers = const {}}) {
    return _send('GET', path, headers: headers);
  }

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return _send('POST', path, body: body, headers: headers);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    required Map<String, String> headers,
  }) async {
    final uri = baseUri.resolve(path);
    try {
      final request = await _httpClient.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      var requestHeaders = Map<String, String>.of(headers);
      for (final interceptor in interceptors) {
        requestHeaders = await interceptor.onRequest(requestHeaders);
      }
      requestHeaders.forEach(request.headers.set);
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      for (final interceptor in interceptors) {
        await interceptor.onResponse(response.statusCode, {});
      }
      final responseBody = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: responseBody.isEmpty ? 'API request failed.' : responseBody,
          statusCode: response.statusCode,
        );
      }
      if (responseBody.isEmpty) return null;
      return jsonDecode(responseBody);
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(message: 'Unable to reach the API: ${error.message}');
    } on FormatException catch (error) {
      throw ApiException(message: 'Invalid API response: ${error.message}');
    }
  }

  void close({bool force = false}) => _httpClient.close(force: force);
}
