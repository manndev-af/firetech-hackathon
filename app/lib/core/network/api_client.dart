import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/api_exception.dart';
import 'api_interceptor.dart';

/// HTTP API client foundation for connecting Flutter to the backend server.
class ApiClient {
  ApiClient({
    required this.baseUri,
    HttpClient? httpClient,
    this.interceptors = const [],
  }) : _httpClient = httpClient ?? HttpClient();

  final Uri baseUri;
  final HttpClient _httpClient;
  final List<ApiInterceptor> interceptors;

  Future<Object?> get(
    String path, {
    Map<String, String> headers = const {},
  }) {
    return _send('GET', path, headers: headers);
  }

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return _send('POST', path, body: body, headers: headers);
  }

  Future<Object?> patch(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return _send('PATCH', path, body: body, headers: headers);
  }

  Future<Object?> delete(
    String path, {
    Map<String, String> headers = const {},
  }) {
    return _send('DELETE', path, headers: headers);
  }

  Future<Object?> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required String fileField,
    required String mimeType,
    Map<String, String> fields = const {},
    Map<String, String> headers = const {},
  }) async {
    final uri = baseUri.resolve(path);
    final boundary = '----NutriLensBoundary${DateTime.now().microsecondsSinceEpoch}';
    try {
      if (kDebugMode) {
        debugPrint('[ApiClient] POST (Multipart) $uri');
      }
      final request = await _httpClient.openUrl('POST', uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      var requestHeaders = Map<String, String>.of(headers);
      for (final interceptor in interceptors) {
        requestHeaders = await interceptor.onRequest(requestHeaders);
      }
      requestHeaders.forEach(request.headers.set);

      for (final entry in fields.entries) {
        request.write('--$boundary\r\n');
        request.write('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
        request.write('${entry.value}\r\n');
      }

      request.write('--$boundary\r\n');
      request.write('Content-Disposition: form-data; name="$fileField"; filename="$filename"\r\n');
      request.write('Content-Type: $mimeType\r\n\r\n');
      request.add(fileBytes);
      request.write('\r\n');

      request.write('--$boundary--\r\n');

      final response = await request.close();
      for (final interceptor in interceptors) {
        await interceptor.onResponse(response.statusCode, {});
      }
      final responseBody = await utf8.decodeStream(response);
      return _handleResponse(response.statusCode, responseBody);
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(message: 'Tidak dapat terhubung ke server: ${error.message}');
    } on FormatException catch (error) {
      throw ApiException(message: 'Format respons tidak valid: ${error.message}');
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    required Map<String, String> headers,
  }) async {
    final uri = baseUri.resolve(path);
    try {
      if (kDebugMode) {
        debugPrint('[ApiClient] $method $uri');
      }
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
      return _handleResponse(response.statusCode, responseBody);
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(message: 'Tidak dapat terhubung ke server: ${error.message}');
    } on FormatException catch (error) {
      throw ApiException(message: 'Format respons tidak valid: ${error.message}');
    }
  }

  Object? _handleResponse(int statusCode, String responseBody) {
    if (statusCode == 204) return null;
    Object? decoded;
    if (responseBody.isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        // Not a JSON response
      }
    }
    if (statusCode < 200 || statusCode >= 300) {
      String message = responseBody.isEmpty ? 'Permintaan API gagal.' : responseBody;
      String? code;
      if (decoded is Map) {
        if (decoded['message'] is String) {
          message = decoded['message'] as String;
        }
        if (decoded['data'] is Map && (decoded['data'] as Map)['code'] is String) {
          code = (decoded['data'] as Map)['code'] as String;
        }
      }
      throw ApiException(message: message, statusCode: statusCode, code: code);
    }
    if (decoded is Map && decoded.containsKey('success') && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  void close({bool force = false}) => _httpClient.close(force: force);
}
