import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../data/models/candidate_model.dart';
import '../widgets/candidate_card.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  List<CandidateModel> _candidates = [];
  List<CandidateModel> _filteredCandidates = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Fetching candidates from: $baseUrl/api/candidates');
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/candidates'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out. Please try again.');
            },
          );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded ${data.length} candidates');

        final List<CandidateModel> parsedCandidates = [];

        for (var json in data) {
          try {
            final candidate = CandidateModel.fromJson(json);
            parsedCandidates.add(candidate);
          } catch (e, stackTrace) {
            print('Error parsing candidate: $e');
            print('Stack trace: $stackTrace');
            print('Problematic JSON: $json');
            // Continue parsing other candidates even if one fails
            continue;
          }
        }

        setState(() {
          _candidates = parsedCandidates;
          _filteredCandidates = parsedCandidates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load candidates. Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching candidates: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterCandidates(String query) {
    setState(() {
      _filteredCandidates =
          _candidates
              .where(
                (candidate) => candidate.user.fullName.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterCandidates,
              decoration: InputDecoration(
                hintText: 'Search candidates...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : ListView.builder(
                      itemCount: _filteredCandidates.length,
                      itemBuilder: (context, index) {
                        return CandidateCard(
                          candidate: _filteredCandidates[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
