import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/api_constants.dart';
import '../../../services/user_service.dart';

class GetCodeScreen extends StatefulWidget {
  const GetCodeScreen({super.key});

  @override
  State<GetCodeScreen> createState() => _GetCodeScreenState();
}

class _GetCodeScreenState extends State<GetCodeScreen> {
  final logger = Logger();
  bool _isLoading = true;
  String? _votingCode;
  String _message = '';
  bool _isValid = false;
  bool _isExpired = false;
  bool _isUsed = false;
  DateTime? _expiresAt;
  String? _admissionNumber;

  @override
  void initState() {
    super.initState();
    _loadAdmissionNumber();
  }

  Future<void> _loadAdmissionNumber() async {
    try {
      final storedAdmissionNumber = await UserService.getAdmissionNumber();

      if (storedAdmissionNumber != null && storedAdmissionNumber.isNotEmpty) {
        if (mounted) {
          setState(() {
            _admissionNumber = storedAdmissionNumber;
          });
          _fetchVotingCode();
        }
      } else {
        if (mounted) {
          setState(() {
            _message = 'No admission number found. Please login again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      logger.e('Error loading admission number: $e');
      if (mounted) {
        setState(() {
          _message = 'Error loading user data. Please login again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchVotingCode() async {
    try {
      if (_admissionNumber == null || _admissionNumber!.isEmpty) {
        logger.e('No admission number available');
        setState(() {
          _message = 'No admission number available. Please login again.';
          _isLoading = false;
        });
        return;
      }

      logger.d('Using admission number: $_admissionNumber');

      final url =
          '$baseUrl/api/voting-code?admissionNumber=${Uri.encodeComponent(_admissionNumber!)}';
      logger.d('Request URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              logger.e('Request timed out after 5 seconds');
              throw TimeoutException(
                'Request took too long. Please check your internet connection.',
              );
            },
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        logger.d('Response received successfully');

        if (!mounted) return;

        setState(() {
          _votingCode = data['code'];
          _isValid = data['isValid'];
          _isExpired = data['isExpired'];
          _isUsed = data['isUsed'];
          _expiresAt = DateTime.parse(data['expiresAt']);

          if (data['hasCode']) {
            if (_isUsed) {
              _message = 'This voting code has already been used';
            } else if (_isExpired) {
              _message = 'This voting code has expired';
            } else {
              _message = 'Your voting code has been generated successfully!';
            }
          } else {
            _message = 'Generating your voting code...';
          }
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        logger.e('Server error: ${response.statusCode}');

        if (!mounted) return;

        setState(() {
          _message = errorData['message'] ?? 'Failed to fetch voting code';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error: $e');
      if (!mounted) return;
      setState(() {
        _message = 'Network error. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Get Your Voting Code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Debug info section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Debug Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Current Admission Number: ${_admissionNumber ?? 'null'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Fetching your voting code...'),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getMessageColor(),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_message.contains('timed out') ||
                        _message.contains('error'))
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: _fetchVotingCode,
                          child: const Text('Retry'),
                        ),
                      ),
                    if (_votingCode != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _getMessageColor(),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _votingCode!,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            if (_expiresAt != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Expires: ${_formatDateTime(_expiresAt!)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Continue to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMessageColor() {
    if (_isUsed) return Colors.red;
    if (_isExpired) return Colors.orange;
    if (_votingCode != null) return Colors.green;
    return Colors.orange;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
