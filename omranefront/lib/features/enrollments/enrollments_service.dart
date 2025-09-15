import 'package:dio/dio.dart';
import 'package:omranefront/core/api_client.dart';

class EnrollmentsService {
  final Dio _dio = ApiClient().client;

  Future<List<dynamic>> listAll() async {
    final res = await _dio.get('/enrollments');
    if (res.data['success'] == true) {
      return (res.data['enrollments'] as List).cast<dynamic>();
    }
    throw Exception(res.data['message'] ?? 'Failed to load enrollments');
  }

  Future<Map<String, dynamic>> enroll({
    required String courseId,
    String? studentId,
  }) async {
    final res = await _dio.post(
      '/enrollments',
      data: {
        'courseId': courseId,
        if (studentId != null) 'studentId': studentId,
      },
    );
    if (res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['enrollment']);
    }
    throw Exception(res.data['message'] ?? 'Enrollment failed');
  }

  Future<List<dynamic>> myCourses() async {
    final res = await _dio.get('/enrollments/my-courses');
    if (res.data['success'] == true) {
      return (res.data['enrollments'] as List).cast<dynamic>();
    }
    throw Exception(res.data['message'] ?? 'Failed to load my courses');
  }

  Future<void> unenroll(String enrollmentId) async {
    final res = await _dio.delete('/enrollments/$enrollmentId');
    if (res.data['success'] == true) return;
    throw Exception(res.data['message'] ?? 'Unenrollment failed');
  }

  Future<Map<String, dynamic>> update(
    String enrollmentId, {
    String? status,
    dynamic grade,
  }) async {
    final res = await _dio.put(
      '/enrollments/$enrollmentId',
      data: {if (status != null) 'status': status, 'grade': grade},
    );
    if (res.data['success'] == true) {
      return Map<String, dynamic>.from(res.data['enrollment']);
    }
    throw Exception(res.data['message'] ?? 'Failed to update enrollment');
  }
}
