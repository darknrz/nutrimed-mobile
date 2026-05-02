import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expirado → limpiar y redirigir al login
      await _storage.clearTokens();
      // TODO: emitir evento de logout global con BLoC
    }
    handler.next(err);
  }
}