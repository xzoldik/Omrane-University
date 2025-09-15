import 'package:dio/dio.dart';
import 'package:omranefront/core/api_client.dart';

class CoursesService {
  final Dio _dio = ApiClient().client;

  Exception _asReadableError(Object err) {
    if (err is DioException) {
      final status = err.response?.statusCode;
      final data = err.response?.data;
      String? backendMsg;
      if (data is Map<String, dynamic>) {
        backendMsg = data['message']?.toString();
      } else if (data is String) {
        backendMsg = data;
      }
      final base = 'Request failed${status != null ? ' ($status)' : ''}';
      return Exception(backendMsg != null ? '$base: $backendMsg' : base);
    }
    return Exception(err.toString());
  }

  Future<List<dynamic>> getCourses() async {
    try {
      final res = await _dio.get('/courses');
      if (res.data is Map<String, dynamic> && res.data['success'] == true) {
        return (res.data['courses'] as List).cast<dynamic>();
      }
      throw Exception(res.data['message'] ?? 'Failed to load courses');
    } catch (e) {
      throw _asReadableError(e);
    }
  }

  Future<Map<String, dynamic>> getCourse(String id) async {
    try {
      final res = await _dio.get('/courses/$id');
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['course']);
      }
      throw Exception(res.data['message'] ?? 'Failed to load course');
    } catch (e) {
      throw _asReadableError(e);
    }
  }

  Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.post('/courses', data: payload);
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['course']);
      }
      throw Exception(res.data['message'] ?? 'Failed to create course');
    } catch (e) {
      throw _asReadableError(e);
    }
  }

  Future<Map<String, dynamic>> updateCourse(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.put('/courses/$id', data: payload);
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['course']);
      }
      throw Exception(res.data['message'] ?? 'Failed to update course');
    } catch (e) {
      throw _asReadableError(e);
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      final res = await _dio.delete('/courses/$id');
      if (res.data['success'] == true) return;
      throw Exception(res.data['message'] ?? 'Failed to delete course');
    } catch (e) {
      throw _asReadableError(e);
    }
  }

  Future<List<dynamic>> getCourseStudents(String id) async {
    try {
      final res = await _dio.get('/courses/$id/students');
      if (res.data['success'] == true) {
        return (res.data['enrolledStudents'] as List).cast<dynamic>();
      }
      throw Exception(
        res.data['message'] ?? 'Failed to load enrolled students',
      );
    } catch (e) {
      throw _asReadableError(e);
    }
  }
}
