import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kuraa/constants/api_constants.dart';
import '../../../services/user_service.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _regNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _regNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'admissionNumber': _regNumberController.text,
                'password': _passwordController.text,
              }),
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException(
                  'Connection timed out. Please try again.',
                );
              },
            );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Ensure admission number is included in the saved data
          responseData['admissionNumber'] = _regNumberController.text;

          // Save user data
          await UserService.saveUserData(responseData);

          if (!mounted) return;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${responseData['fullName']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Wait for snackbar to show before navigation
          await Future.delayed(const Duration(seconds: 1));

          if (!mounted) return;

          // Navigate to get-code screen
          Navigator.pushReplacementNamed(context, '/get-code');
        } else {
          setState(() {
            _errorMessage = 'Invalid credentials';
          });
        }
      } catch (e) {
        logger.e('Error details: $e');
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your registration number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
