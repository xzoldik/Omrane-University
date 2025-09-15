import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:omranefront/features/auth/auth_service.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final String name;
  final String? studentId;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.studentId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    name: json['name'] as String,
    studentId: json['studentId'] as String?,
  );
}

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.login(email, password);
      if (data['success'] == true) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return true;
      } else {
        _error = data['message']?.toString() ?? 'Login failed';
        return false;
      }
    } catch (e) {
      // Surface friendlier Dio errors
      _error = e is DioException
          ? (e.response?.data is Map &&
                    (e.response?.data as Map)['message'] != null
                ? ((e.response?.data as Map)['message'] as String)
                : 'Network error: ${e.response?.statusCode ?? ''} ${e.message}')
          : e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMe() async {
    try {
      final data = await _service.me();
      if (data['success'] == true && data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      // Best-effort server logout with short timeout to prevent hangs
      await _service.logout().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Swallow errors; we'll still clear local session
    } finally {
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String studentId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.selfRegister(
        email: email,
        password: password,
        name: name,
        studentId: studentId,
      );
      if (data['success'] == true && data['user'] != null) {
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return true;
      }
      _error = data['message']?.toString() ?? 'Registration failed';
      return false;
    } catch (e) {
      _error = e is DioException
          ? (e.response?.data is Map &&
                    (e.response?.data as Map)['message'] != null
                ? ((e.response?.data as Map)['message'] as String)
                : 'Network error: ${e.response?.statusCode ?? ''} ${e.message}')
          : e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
