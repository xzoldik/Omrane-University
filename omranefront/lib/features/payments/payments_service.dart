import 'package:dio/dio.dart';
import 'package:omranefront/core/api_client.dart';
import 'package:flutter/foundation.dart';

class PaymentsService {
  final Dio _dio = ApiClient().client;

  Future<List<dynamic>> listAll() async {
    try {
      final res = await _dio.get('/payments');
      if (res.data['success'] == true) {
        return (res.data['payments'] as List).cast<dynamic>();
      }
      throw Exception(res.data['message'] ?? 'Failed to load payments');
    } on DioException catch (e) {
      final msg = _formatDioError('GET /payments', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<List<dynamic>> myPayments() async {
    try {
      final res = await _dio.get('/payments/my-payments');
      if (res.data['success'] == true) {
        return (res.data['payments'] as List).cast<dynamic>();
      }
      throw Exception(res.data['message'] ?? 'Failed to load my payments');
    } on DioException catch (e) {
      final msg = _formatDioError('GET /payments/my-payments', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> myFees() async {
    try {
      final res = await _dio.get('/payments/my-fees');
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data);
      }
      throw Exception(res.data['message'] ?? 'Failed to load my fees');
    } on DioException catch (e) {
      final msg = _formatDioError('GET /payments/my-fees', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> createPayment({
    required String courseId,
    required num amount,
    required String paymentMethod,
    String? studentId,
  }) async {
    final payload = {
      'courseId': courseId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (studentId != null) 'studentId': studentId,
    };
    debugPrint('POST /payments payload: $payload');
    try {
      final res = await _dio.post('/payments', data: payload);
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['payment']);
      }
      throw Exception(res.data['message'] ?? 'Payment failed');
    } on DioException catch (e) {
      final msg = _formatDioError('POST /payments', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> getPayment(String id) async {
    try {
      final res = await _dio.get('/payments/$id');
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['payment']);
      }
      throw Exception(res.data['message'] ?? 'Failed to load payment');
    } on DioException catch (e) {
      final msg = _formatDioError('GET /payments/$id', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> updatePaymentStatus(
    String id,
    String status,
  ) async {
    try {
      final res = await _dio.put('/payments/$id', data: {'status': status});
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['payment']);
      }
      throw Exception(res.data['message'] ?? 'Failed to update payment');
    } on DioException catch (e) {
      final msg = _formatDioError('PUT /payments/$id', e);
      debugPrint(msg);
      throw Exception(msg);
    }
  }

  String _formatDioError(String action, DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final serverMsg = (data is Map && data['message'] != null)
        ? data['message']
        : e.message;
    return '[PaymentsService] $action failed: HTTP $status - $serverMsg';
  }
}
