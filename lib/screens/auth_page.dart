// lib/screens/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'home_page.dart';
import 'onboarding_page.dart';
import '../models/contact_model.dart';
import '../services/storage_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loginPhoneController = TextEditingController();
  final _storageService = StorageService();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _loginPhoneController.dispose();
    super.dispose();
  }

  String _hashPhone(String phone) {
    final bytes = utf8.encode(phone.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _register() async {
    if (_nameController.text.trim().isEmpty || !_isValidPhone(_phoneController.text)) {
      _showError("Please enter a valid name and 10-digit phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();
      
      // Check if user already exists
      final existingPhone = prefs.getString('userPhone');
      if (existingPhone != null && existingPhone == phone) {
        _showError("An account with this phone number already exists. Please login instead.");
        setState(() => _isLoading = false);
        return;
      }

      // Store user data with consistent keys
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isFirstTime', true);
      await prefs.setString('userName', name);
      await prefs.setString('userPhone', phone);
      await prefs.setString('userPhoneHash', _hashPhone(phone));
      
      // Store profile data with same keys
      await prefs.setString('profile_name', name);
      await prefs.setString('profile_contact', phone);

      print('✅ User registered: $name, $phone');

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const OnboardingPage())
        );
      }
    } catch (e) {
      print('❌ Registration error: $e');
      _showError("Registration failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _login() async {
    if (!_isValidPhone(_loginPhoneController.text)) {
      _showError("Please enter a valid 10-digit phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final inputPhone = _loginPhoneController.text.trim();
      final storedPhone = prefs.getString('userPhone');
      
      // Enhanced authentication - verify against stored phone number
      if (storedPhone == null) {
        _showError("No account found. Please register first.");
        setState(() => _isLoading = false);
        return;
      }

      if (storedPhone != inputPhone) {
        _showError("Phone number doesn't match registered account. Please check and try again.");
        setState(() => _isLoading = false);
        return;
      }

      // Login successful
      final userName = prefs.getString('userName') ?? "User";
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isFirstTime', false);

      print('✅ User logged in: $userName, $inputPhone');

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => HomePage(userName: userName))
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      _showError("Login failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length == 10;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined, 
                  size: 80, 
                  color: Theme.of(context).primaryColor
                ),
                const SizedBox(height: 20),
                Text(
                  "Welcome to ResQnow",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  "Your reliable partner in emergencies.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600
                  )
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: "Register"),
                          Tab(text: "Login")
                        ],
                        labelStyle: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRegisterForm(),
                            _buildLoginForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(userName: "Guest")
                      )
                    );
                  },
                  child: const Text("Skip for now"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Full Name",
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: "Phone Number (10 digits)",
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              counterText: "", // Hide character counter
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text("Register"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _loginPhoneController,
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: "Phone Number (10 digits)",
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
              counterText: "", // Hide character counter
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text("Login"),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Enter the phone number you used during registration",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}