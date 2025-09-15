import 'package:dio/dio.dart';
import 'package:omranefront/core/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient().client;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> selfRegister({
    required String email,
    required String password,
    required String name,
    required String studentId,
  }) async {
    final res = await _dio.post(
      '/auth/self-register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'studentId': studentId,
      },
    );
    return res.data as Map<String, dynamic>;
  }
}
