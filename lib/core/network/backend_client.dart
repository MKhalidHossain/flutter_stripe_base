import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

class BackendClient {
  BackendClient({required String baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl.replaceAll(RegExp(r'/$'), ''),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          );

  final Dio _dio;

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      final body = response.data;

      if (body is Map<String, dynamic>) {
        return body;
      }

      throw const AppException(
        'Backend did not return a JSON object. Check your Stripe API response format.',
      );
    } on DioException catch (error) {
      throw AppException(_messageFromDio(error));
    }
  }

  String _messageFromDio(DioException error) {
    final responseBody = error.response?.data;

    if (responseBody is Map<String, dynamic>) {
      final message =
          responseBody['message'] ??
          responseBody['error'] ??
          responseBody['detail'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Backend request timed out. Make sure your Stripe server is running.';
      case DioExceptionType.connectionError:
        return 'Could not reach STRIPE_BACKEND_URL. Check your emulator/device network and backend host.';
      default:
        return error.message ??
            'Backend request failed. Check your Stripe server logs.';
    }
  }
}
