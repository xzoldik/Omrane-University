import 'package:dio/dio.dart';
import 'package:omranefront/core/api_client.dart';

class StudentsService {
  final Dio _dio = ApiClient().client;

  Future<List<dynamic>> getStudents() async {
    final res = await _dio.get('/students');
    if (res.data['success'] == true) {
      return (res.data['students'] as List).cast<dynamic>();
    }
    throw Exception(res.data['message'] ?? 'Failed to load students');
  }

  Future<Map<String, dynamic>> getStudent(String id) async {
    final res = await _dio.get('/students/$id');
    if (res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['student']);
    }
    throw Exception(res.data['message'] ?? 'Failed to load student');
  }

  Future<Map<String, dynamic>> updateStudent(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final res = await _dio.put('/students/$id', data: payload);
    if (res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['student']);
    }
    throw Exception(res.data['message'] ?? 'Failed to update student');
  }

  Future<Map<String, dynamic>> registerStudent({
    required String email,
    required String password,
    required String name,
    required String studentId,
  }) async {
    final res = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
        'studentId': studentId,
      },
    );
    if (res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['student']);
    }
    throw Exception(res.data['message'] ?? 'Failed to register student');
  }

  Future<void> deleteStudent(String id) async {
    final res = await _dio.delete('/students/$id');
    if (res.data['success'] == true) return;
    throw Exception(res.data['message'] ?? 'Failed to delete student');
  }

  Future<List<dynamic>> getStudentEnrollments(String id) async {
    final res = await _dio.get('/students/$id/enrollments');
    if (res.data['success'] == true) {
      return (res.data['enrollments'] as List).cast<dynamic>();
    }
    throw Exception(res.data['message'] ?? 'Failed to load enrollments');
  }
}
