import 'package:flutter/material.dart';

import '../../core/services/result_service.dart';
import 'lottery_result.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, this.resultService});

  final ResultService? resultService;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<List<LotteryResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _loadResults();
  }

  Future<List<LotteryResult>> _loadResults() async {
    final service = widget.resultService ?? ResultService();
    final response = await service.fetchResults();

    return _parseResults(response);
  }

  void _retry() {
    setState(() {
      _resultsFuture = _loadResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LotteryResult>>(
      future: _resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ResultsLoadingView();
        }

        if (snapshot.hasError) {
          return _ResultsErrorView(onRetry: _retry);
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return _ResultsEmptyView(onRetry: _retry);
        }

        return _ResultsLoadedView(results: results);
      },
    );
  }

  List<LotteryResult> _parseResults(Map<String, dynamic> payload) {
    final resultsPayload =
        payload['results'] ?? payload['data'] ?? payload['lotteryResults'];

    if (resultsPayload is List) {
      return resultsPayload
          .whereType<Map>()
          .map((result) => _resultFromJson(Map<String, dynamic>.from(result)))
          .toList();
    }

    if (resultsPayload is Map) {
      return _resultsFromCompanyMap(resultsPayload);
    }

    return _resultsFromCompanyMap(payload);
  }

  List<LotteryResult> _resultsFromCompanyMap(Map<dynamic, dynamic> payload) {
    final results = <LotteryResult>[];

    for (final company in _companyNames) {
      final companyPayload = _valueForCompany(payload, company);

      if (companyPayload is Map) {
        results.add(
          _resultFromJson(
            Map<String, dynamic>.from(companyPayload),
            companyFallback: company,
          ),
        );
      }
    }

    if (results.isNotEmpty) {
      return results;
    }

    return payload.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) => _resultFromJson(
            Map<String, dynamic>.from(entry.value as Map),
            companyFallback: entry.key.toString(),
          ),
        )
        .toList();
  }

  LotteryResult _resultFromJson(
    Map<String, dynamic> json, {
    String? companyFallback,
  }) {
    return LotteryResult(
      company: _readString(json, const [
        'company',
        'name',
        'operator',
      ], fallback: companyFallback ?? 'Unknown'),
      firstPrize: _readString(json, const [
        'firstPrize',
        'first_prize',
        'first',
        '1st',
        'prize1',
      ]),
      secondPrize: _readString(json, const [
        'secondPrize',
        'second_prize',
        'second',
        '2nd',
        'prize2',
      ]),
      thirdPrize: _readString(json, const [
        'thirdPrize',
        'third_prize',
        'third',
        '3rd',
        'prize3',
      ]),
      specialPrizes: _readStringList(json, const [
        'specialPrizes',
        'special_prizes',
        'special',
        'specials',
      ]),
      consolationPrizes: _readStringList(json, const [
        'consolationPrizes',
        'consolation_prizes',
        'consolation',
        'consolations',
      ]),
      date: _readString(json, const [
        'date',
        'drawDate',
        'draw_date',
      ], fallback: 'Latest Draw'),
    );
  }

  Object? _valueForCompany(Map<dynamic, dynamic> payload, String company) {
    final companyKey = _normalizeKey(company);

    for (final entry in payload.entries) {
      if (_normalizeKey(entry.key.toString()) == companyKey) {
        return entry.value;
      }
    }

    return null;
  }

  String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value != null) {
        return value.toString();
      }
    }

    return fallback;
  }

  List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];

      if (value is List) {
        return value
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }

      if (value is Map) {
        return value.values
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      }
    }

    return const [];
  }

  String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

const List<String> _companyNames = ['Toto', 'Magnum', 'Da Ma Cai'];

class _ResultsLoadedView extends StatelessWidget {
  const _ResultsLoadedView({required this.results});

  final List<LotteryResult> results;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: results.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('4D Results'),
          bottom: TabBar(
            tabs: [for (final result in results) Tab(text: result.company)],
          ),
        ),
        body: TabBarView(
          children: [for (final result in results) _ResultTab(result: result)],
        ),
      ),
    );
  }
}

class _ResultsLoadingView extends StatelessWidget {
  const _ResultsLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ResultsAppBar(),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResultsErrorView extends StatelessWidget {
  const _ResultsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ResultsMessageView(
      title: 'Unable to load results',
      message: 'Please check your connection and try again.',
      buttonLabel: 'Retry',
      onPressed: onRetry,
    );
  }
}

class _ResultsEmptyView extends StatelessWidget {
  const _ResultsEmptyView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ResultsMessageView(
      title: 'No results available',
      message: 'Latest 4D results are not available right now.',
      buttonLabel: 'Refresh',
      onPressed: onRetry,
    );
  }
}

class _ResultsMessageView extends StatelessWidget {
  const _ResultsMessageView({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const _ResultsAppBar(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onPressed,
                      child: Text(buttonLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ResultsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('4D Results'));
  }
}

class _ResultTab extends StatelessWidget {
  const _ResultTab({required this.result});

  final LotteryResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          result.date,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _PrizeCard(label: 'First Prize', number: result.firstPrize),
        const SizedBox(height: 12),
        _PrizeCard(label: 'Second Prize', number: result.secondPrize),
        const SizedBox(height: 12),
        _PrizeCard(label: 'Third Prize', number: result.thirdPrize),
        const SizedBox(height: 16),
        _NumberGridCard(label: 'Special', numbers: result.specialPrizes),
        const SizedBox(height: 16),
        _NumberGridCard(
          label: 'Consolation',
          numbers: result.consolationPrizes,
        ),
      ],
    );
  }
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({required this.label, required this.number});

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              number,
              style: textTheme.displayMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberGridCard extends StatelessWidget {
  const _NumberGridCard({required this.label, required this.numbers});

  final String label;
  final List<String> numbers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visibleNumbers = numbers.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleNumbers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                return _NumberTile(number: visibleNumbers[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              number,
              maxLines: 1,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
