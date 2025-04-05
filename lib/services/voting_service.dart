import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import 'package:logger/logger.dart';

class VotingService {
  static final logger = Logger();

  static Future<Map<String, dynamic>> castVote({
    required String voterAdmissionNumber,
    required String candidateAdmissionNumber,
    required String votingCode,
  }) async {
    try {
      final requestBody = {
        'voterAdmissionNumber': voterAdmissionNumber,
        'candidateAdmissionNumber': candidateAdmissionNumber,
        'votingCode': votingCode,
      };

      logger.i('Sending vote request to: $baseUrl/api/votes');
      logger.i('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/votes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      logger.i('Response status code: ${response.statusCode}');
      logger.i('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cast vote',
        };
      }
    } catch (e, stackTrace) {
      logger.e('Error casting vote: $e');
      logger.e('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}
