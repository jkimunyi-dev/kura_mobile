import 'package:flutter/material.dart';
import 'package:kuraa/core/constants/app_colors.dart';
import 'package:kuraa/presentation/screens/my_vote/my_vote_screen.dart';
import 'package:provider/provider.dart';
import '../../../services/user_service.dart';
import '../../../providers/candidates_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/api_constants.dart';
import '../../../data/models/candidate_model.dart';
import '../../widgets/candidate_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _fullName = userData['fullName'];
      });

      // Show welcome message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome $_fullName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome ${_fullName ?? ''}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'My Vote',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.poll), label: 'Results'),
        ],
      ),
    );
  }

  final List<Widget> _screens = [
    const HomeTab(),
    const MyVoteTab(),
    const ResultsTab(),
  ];
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<CandidateModel> _candidates = [];
  List<CandidateModel> _filteredCandidates = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      // Try to load from cache first
      final cachedData = await UserService.getCachedCandidates();
      if (cachedData != null) {
        setState(() {
          _candidates =
              cachedData.map((json) => CandidateModel.fromJson(json)).toList();
          _filteredCandidates = _candidates;
          _isLoading = false;
        });
        return;
      }

      // If no cache or expired, fetch from API
      await _fetchCandidates();
    } catch (e) {
      print('Error loading candidates: $e');
      setState(() {
        _errorMessage = 'Error loading candidates';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCandidates() async {
    try {
      print('Fetching candidates from: $baseUrl/api/candidates');
      final response = await http.get(
        Uri.parse('$baseUrl/api/candidates'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Save to cache
        await UserService.saveCandidates(List<Map<String, dynamic>>.from(data));

        setState(() {
          _candidates =
              data.map((json) => CandidateModel.fromJson(json)).toList();
          _filteredCandidates = _candidates;
          _isLoading = false;
        });
      } else {
        print('Failed with status code: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Failed to load candidates';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching candidates: $e');
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  void _filterCandidates() {
    if (_selectedPosition == null) {
      _filteredCandidates = _candidates;
    } else {
      _filteredCandidates =
          _candidates.where((c) => c.position.id == _selectedPosition).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Categories Dropdown
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Position',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedPosition,
                      hint: const Text('All Positions'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Positions'),
                        ),
                        ...Provider.of<CandidatesProvider>(
                          context,
                        ).positionNames.entries.map(
                          (entry) => DropdownMenuItem<int?>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                          _filterCandidates();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Candidates List
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : _filteredCandidates.isEmpty
                  ? const Center(child: Text('No candidates available'))
                  : RefreshIndicator(
                    onRefresh: _fetchCandidates,
                    child: ListView.builder(
                      itemCount: _filteredCandidates.length,
                      itemBuilder: (context, index) {
                        return CandidateCard(
                          candidate: _filteredCandidates[index],
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(int? positionId, String label) {
    final isSelected = _selectedPosition == positionId;
    final color =
        positionId != null
            ? AppColors.getPositionColor(positionId)
            : Colors.grey;

    return Material(
      color: isSelected ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPosition = isSelected ? null : positionId;
            _filterCandidates();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class MyVoteTab extends StatelessWidget {
  const MyVoteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyVoteScreen(); // Use MyVoteScreen instead of just text
  }
}

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  int _selectedPosition = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CandidatesProvider>().fetchAllMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CandidatesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error.isNotEmpty) {
          return Center(child: Text(provider.error));
        }

        return Column(
          children: [
            _buildPositionCategories(provider),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchAllMetrics(),
                child: _buildPositionResults(provider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPositionCategories(CandidatesProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Position',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPosition,
                  isExpanded: true,
                  items:
                      provider.positionNames.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPosition = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionResults(CandidatesProvider provider) {
    final metrics = provider.getMetricsForPosition(_selectedPosition);
    if (metrics == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metrics['positionName'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMetricsCard(metrics),
          const SizedBox(height: 16),
          _buildWinningCandidateCard(metrics),
          const SizedBox(height: 16),
          const Text(
            'Candidates',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildCandidatesList(metrics),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(Map<String, dynamic> metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMetricRow(
              'Total Candidates',
              metrics['totalCandidates'].toString(),
            ),
            _buildMetricRow('Total Votes', metrics['totalVotes'].toString()),
            _buildMetricRow(
              'Voter Turnout',
              '${(metrics['voterTurnout'] * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinningCandidateCard(Map<String, dynamic> metrics) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leading Candidate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              metrics['winningCandidate'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCandidatesList(Map<String, dynamic> metrics) {
    return (metrics['candidates'] as List)
        .map(
          (candidate) => Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => _showCandidateDetails(candidate),
              child: ListTile(
                title: Text(candidate['candidateName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate['admissionNumber']),
                    Text(
                      candidate['manifesto'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${candidate['voteCount']} votes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${candidate['votePercentage'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  void _showCandidateDetails(Map<String, dynamic> candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        candidate['candidateName'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Admission Number: ${candidate['admissionNumber']}'),
                      Text('Faculty: ${candidate['facultyCode']}'),
                      Text('Department: ${candidate['departmentCode']}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Manifesto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(candidate['manifesto']),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Implement voting logic here
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Vote for Candidate'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
