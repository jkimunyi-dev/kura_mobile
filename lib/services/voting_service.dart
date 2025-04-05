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
      final queryParameters = {
        'voterAdmissionNumber': voterAdmissionNumber,
        'candidateAdmissionNumber': candidateAdmissionNumber,
        'votingCode': votingCode,
      };

      final uri = Uri.parse(
        '$baseUrl/api/votes',
      ).replace(queryParameters: queryParameters);

      logger.i('Sending vote request to: $uri');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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
