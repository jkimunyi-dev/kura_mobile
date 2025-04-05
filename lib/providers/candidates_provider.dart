import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../data/models/candidate_model.dart';

class CandidatesProvider with ChangeNotifier {
  final Map<int, List<CandidateModel>> _candidatesByPosition = {};
  final Map<int, Map<String, dynamic>> _metricsByPosition = {};
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;
  
  Map<int, String> positionNames = {
    1: 'Class Representative',
    2: 'Faculty Representative',
    3: 'President',
    4: 'Vice President',
    5: 'Secretary General',
  };

  List<CandidateModel>? getCandidatesForPosition(int positionId) {
    return _candidatesByPosition[positionId];
  }

  Map<String, dynamic>? getMetricsForPosition(int positionId) {
    return _metricsByPosition[positionId];
  }

  Future<void> fetchMetricsForPosition(int positionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/position/$positionId/metrics'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _metricsByPosition[positionId] = json.decode(response.body);
      } else {
        _error = 'Failed to load metrics for ${positionNames[positionId]}';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllMetrics() async {
    _error = '';
    for (int positionId in positionNames.keys) {
      await fetchMetricsForPosition(positionId);
    }
  }
}