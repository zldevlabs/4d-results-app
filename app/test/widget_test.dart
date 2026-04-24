import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/src/core/services/result_service.dart';
import 'package:app/src/app.dart';
import 'package:app/src/features/results/results_page.dart';

void main() {
  testWidgets('home page shows results button', (WidgetTester tester) async {
    await tester.pumpWidget(const ResultsApp());

    expect(find.text('View Results'), findsOneWidget);
  });

  testWidgets('results page shows fetched results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ResultsPage(resultService: _FakeResultService())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toto'), findsOneWidget);
    expect(find.text('Magnum'), findsOneWidget);
    expect(find.text('Da Ma Cai'), findsOneWidget);
    expect(find.text('First Prize'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
  });
}

class _FakeResultService extends ResultService {
  @override
  Future<Map<String, dynamic>> fetchResults() async {
    return {
      'results': [
        {
          'company': 'Toto',
          'firstPrize': '1234',
          'secondPrize': '5678',
          'thirdPrize': '9012',
          'date': 'Latest Draw',
        },
        {
          'company': 'Magnum',
          'firstPrize': '2468',
          'secondPrize': '1357',
          'thirdPrize': '8080',
          'date': 'Latest Draw',
        },
        {
          'company': 'Da Ma Cai',
          'firstPrize': '4321',
          'secondPrize': '8765',
          'thirdPrize': '2109',
          'date': 'Latest Draw',
        },
      ],
    };
  }
}
