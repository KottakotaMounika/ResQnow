import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class AuthService {
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Generate OTP (Mock implementation)
  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  // Validate phone number (Indian format - 10 digits)
  bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }
  
  // Send OTP (Mock implementation)
  Future<bool> sendOTP(String phone, String otp) async {
    try {
      // Store OTP temporarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_otp_$phone', otp);
      await prefs.setInt('otp_timestamp_$phone', DateTime.now().millisecondsSinceEpoch);
      
      print('Mock OTP sent: $otp to $phone');
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }
  
  // Verify OTP
  Future<bool> verifyOTP(String phone, String enteredOTP) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOTP = prefs.getString('temp_otp_$phone');
      final timestamp = prefs.getInt('otp_timestamp_$phone');
      
      if (storedOTP == null || timestamp == null) {
        return false;
      }
      
      // Check if OTP is expired (5 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > 5 * 60 * 1000) {
        await prefs.remove('temp_otp_$phone');
        await prefs.remove('otp_timestamp_$phone');
        return false;
      }
      
      final isValid = storedOTP == enteredOTP;
      
      if (isValid) {
        await prefs.remove('temp_otp_$phone');
        await prefs.remove('otp_timestamp_$phone');
      }
      
      return isValid;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }
  
  // Register user
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    String? email,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUser(phone);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'User already exists with this phone number',
        };
      }
      
      // Create new user
      final userId = await _dbHelper.insertUser({
        'phone': phone,
        'name': name,
        'email': email,
        'is_verified': 1,
      });
      
      // Store current user session
      await _storeUserSession(userId, phone, name, email);
      
      return {
        'success': true,
        'message': 'Registration successful',
        'userId': userId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login(String phone) async {
    try {
      final user = await _dbHelper.getUser(phone);
      if (user == null) {
        return {
          'success': false,
          'message': 'No account found with this phone number',
        };
      }
      
      // Store current user session
      await _storeUserSession(
        user['id'],
        user['phone'],
        user['name'],
        user['email'],
      );
      
      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }
  
  // Store user session
  Future<void> _storeUserSession(int userId, String phone, String name, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'id': userId,
      'phone': phone,
      'name': name,
      'email': email,
    };
    
    await prefs.setString(_currentUserKey, json.encode(userData));
    await prefs.setBool(_isLoggedInKey, true);
  }
  
  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_currentUserKey);
      
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
