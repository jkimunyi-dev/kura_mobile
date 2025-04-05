import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/candidate_model.dart';
import 'package:logger/logger.dart';

class VoteService {
  static const String _voteKeyPrefix = 'user_vote_position_';
  static final logger = Logger();

  static Future<void> saveVote(CandidateModel candidate) async {
    final prefs = await SharedPreferences.getInstance();
    final voteKey = _voteKeyPrefix + candidate.position.id.toString();

    final voteData = {
      'candidateId': candidate.id,
      'candidateName': candidate.user.fullName,
      'positionId': candidate.position.id,
      'positionName': candidate.position.positionName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    logger.i('Saving vote locally: $voteData');
    await prefs.setString(voteKey, json.encode(voteData));
  }

  static Future<Map<String, dynamic>?> getVote(int positionId) async {
    final prefs = await SharedPreferences.getInstance();
    final voteKey = _voteKeyPrefix + positionId.toString();
    final voteString = prefs.getString(voteKey);
    if (voteString != null) {
      return json.decode(voteString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final votes = <Map<String, dynamic>>[];

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_voteKeyPrefix)) {
        final voteString = prefs.getString(key);
        if (voteString != null) {
          votes.add(json.decode(voteString) as Map<String, dynamic>);
        }
      }
    }
    return votes;
  }

  static Future<bool> hasVotedForPosition(int positionId) async {
    final prefs = await SharedPreferences.getInstance();
    final voteKey = _voteKeyPrefix + positionId.toString();
    final hasVoted = prefs.containsKey(voteKey);
    logger.i('Checking vote status for position $positionId: $hasVoted');
    return hasVoted;
  }

  static Future<bool> hasVoted() async {
    final votes = await getAllVotes();
    return votes.isNotEmpty;
  }

  static Future<void> clearVoteCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_voteKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    logger.i('Vote cache cleared');
  }
}
