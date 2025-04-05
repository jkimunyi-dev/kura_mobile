import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kuraa/constants/api_constants.dart';
import '../../services/vote_service.dart';
import '../../services/user_service.dart';
import '../../services/voting_service.dart';
import '../../data/models/candidate_model.dart';
import '../../core/constants/app_colors.dart';
import 'package:logger/logger.dart';

class CandidateCard extends StatefulWidget {
  final CandidateModel candidate;
  final VoidCallback? onVoteComplete;

  const CandidateCard({
    super.key,
    required this.candidate,
    this.onVoteComplete,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  bool _hasVotedForPosition = false;
  bool _isVoting = false;
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkVoteStatus();
  }

  Future<void> _checkVoteStatus() async {
    final hasVotedForPosition = await VoteService.hasVotedForPosition(
      widget.candidate.position.id,
    );
    if (mounted) {
      setState(() {
        _hasVotedForPosition = hasVotedForPosition;
      });
    }
  }

  Future<void> _handleVote(BuildContext context) async {
    if (_isVoting) return;

    setState(() => _isVoting = true);

    try {
      final voterAdmissionNumber = await UserService.getAdmissionNumber();

      if (voterAdmissionNumber == null) {
        throw Exception('Voter admission number not found');
      }

      logger.i('Fetching voting code for: $voterAdmissionNumber');

      final votingCodeResponse = await http.get(
        Uri.parse(
          '$baseUrl/api/voting-code?admissionNumber=$voterAdmissionNumber',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      logger.i('Voting code response: ${votingCodeResponse.body}');

      final votingCodeData = json.decode(votingCodeResponse.body);

      if (votingCodeData['isExpired'] == true) {
        throw Exception('Voting code has expired');
      }

      if (votingCodeData['isUsed'] == true) {
        throw Exception('Voting code has already been used');
      }

      final votingCode = votingCodeData['code'];

      if (votingCode == null) {
        throw Exception('No valid voting code found');
      }

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Vote'),
              content: Text(
                'Are you sure you want to vote for ${widget.candidate.user.fullName}?\n\n'
                'Note: You can only vote once for ${widget.candidate.position.positionName}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('CONFIRM'),
                ),
              ],
            ),
      );

      if (confirm != true) {
        setState(() => _isVoting = false);
        return;
      }

      logger.i(
        'Casting vote for candidate: ${widget.candidate.user.admissionNumber}',
      );

      // Cast the vote through the API
      final result = await VotingService.castVote(
        voterAdmissionNumber: voterAdmissionNumber,
        candidateAdmissionNumber: widget.candidate.user.admissionNumber,
        votingCode: votingCode,
      );

      if (!mounted) return;

      if (result['success']) {
        // Save vote locally only after successful API call
        await VoteService.saveVote(widget.candidate);

        setState(() {
          _hasVotedForPosition = true;
          _isVoting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onVoteComplete != null) {
          widget.onVoteComplete!();
        }

        Navigator.of(context).pop();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      logger.e('Error in _handleVote: $e');

      if (!mounted) return;

      setState(() => _isVoting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildVoteButton(Color positionColor) {
    if (_hasVotedForPosition) {
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.check_circle),
        label: Text('Already Voted'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showCandidateDetails(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: positionColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: const Icon(Icons.how_to_vote),
      label: const Text('Vote'),
    );
  }

  void _showCandidateDetails(BuildContext context) {
    final positionColor = AppColors.getPositionColor(
      widget.candidate.position.id,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with position color
                      Container(
                        decoration: BoxDecoration(
                          color: positionColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Drag handle
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: positionColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Candidate image/avatar
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: positionColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: positionColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Candidate name
                            Text(
                              widget.candidate.user.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Position name
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: positionColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.candidate.position.positionName,
                                style: TextStyle(
                                  color: positionColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Admission Number',
                                widget.candidate.user.admissionNumber,
                                Icons.badge,
                                positionColor,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Faculty',
                                widget.candidate.user.facultyCode,
                                Icons.school,
                                positionColor,
                              ),
                              const Divider(),
                              _buildDetailRow(
                                'Department',
                                widget.candidate.user.departmentCode,
                                Icons.business,
                                positionColor,
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                'Manifesto',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: positionColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.candidate.manifesto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Vote button
                              SizedBox(
                                width: double.infinity,
                                child:
                                    _hasVotedForPosition
                                        ? ElevatedButton.icon(
                                          onPressed: null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            foregroundColor: Colors.grey[600],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_circle),
                                          label: Text(
                                            'Voted for ${widget.candidate.position.positionName}',
                                          ),
                                        )
                                        : ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirm = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Confirm Vote',
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to vote for ${widget.candidate.user.fullName}?\n\n'
                                                      'Note: You can only vote once for ${widget.candidate.position.positionName}.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'CANCEL',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'CONFIRM',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (confirm == true) {
                                              await VoteService.saveVote(
                                                widget.candidate,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Vote recorded successfully',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                Navigator.pop(context);
                                                setState(() {
                                                  _hasVotedForPosition = true;
                                                });
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: positionColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(Icons.how_to_vote),
                                          label: Text(
                                            'Vote for ${widget.candidate.user.fullName}',
                                            style: const TextStyle(
                                              fontSize:
                                                  20, // 2x the original size
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positionColor = AppColors.getPositionColor(
      widget.candidate.position.id,
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: positionColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _showCandidateDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: positionColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: positionColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: positionColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.candidate.user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.candidate.position.positionName,
                          style: TextStyle(
                            fontSize: 14,
                            color: positionColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.candidate.manifesto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCandidateDetails(context),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                  ),
                  _buildVoteButton(positionColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
