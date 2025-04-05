import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/candidates_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CandidatesProvider()),
        // ... other providers
      ],
      child: const VotingApp(),
    ),
  );
}
