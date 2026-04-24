import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'features/results/results_page.dart';

class ResultsApp extends StatelessWidget {
  const ResultsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4D Results',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/results': (context) => const ResultsPage(),
      },
    );
  }
}
