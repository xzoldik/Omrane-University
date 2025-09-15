import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

void configureDioForPlatform(Dio dio) {
  // Enable sending/receiving cookies on web
  dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
}
