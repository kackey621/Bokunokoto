import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);
const String platformHeader = 'X-BK-Platform';
const String platformValue = 'flutter';

final apiClientProvider = Provider<Dio>((ref) {
  final auth = ref.watch(authNotifierProvider);
  return createDioClient(auth.firebaseUser);
});

Dio createDioClient(user) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        platformHeader: platformValue,
      },
    ),
  );

  // Add interceptor for token injection
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 - token might have expired
        if (error.response?.statusCode == 401) {
          // TODO: Refresh token or redirect to login
        }
        return handler.next(error);
      },
    ),
  );

  // Debug logging in development
  // dio.interceptors.add(LoggingInterceptor());

  return dio;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message (HTTP $statusCode)';
}

extension DioErrorHandler on DioException {
  ApiException toApiException() {
    String message = 'An error occurred';
    int? statusCode;

    if (response != null) {
      statusCode = response!.statusCode;
      if (response!.data is Map) {
        message = response!.data['error'] ?? message;
      }
    } else {
      message = message.toString();
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalError: this,
    );
  }
}
