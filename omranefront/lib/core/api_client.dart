import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'http_adapter_stub.dart' if (dart.library.html) 'http_adapter_web.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
        // extra can hint at credentials, but web requires adapter config below
        extra: {'withCredentials': true},
      ),
    );

    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
    // Ensure cookies are configured per-platform (web enables withCredentials)
    configureDioForPlatform(_dio);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // Optionally log or transform errors
          return handler.next(e);
        },
      ),
    );
  }

  late final Dio _dio;
  late final CookieJar _cookieJar;

  Dio get client => _dio;
}
