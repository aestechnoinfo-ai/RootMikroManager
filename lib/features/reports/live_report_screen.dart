import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'live_report_service.dart';

class LiveReportScreen extends StatefulWidget {
  final RouterOsService service;
  const LiveReportScreen({super.key, required this.service});

  @override
  State<LiveReportScreen> createState() => _LiveReportScreenState();
}

class _LiveReportScreenState extends State<LiveReportScreen> {
  bool loading = true;
  String? error;
  LiveReportSnapshot? snapshot;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      snapshot = await LiveReportService(widget.service).load();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  String money(double value, String currency) =>
      AppCurrencySettings.format(value, currency);

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Report'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : s == null
          ? const Center(child: Text('Aucune donnée.'))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth >= 850
                          ? 4
                          : c.maxWidth >= 500
                          ? 2
                          : 1;
                      final w = (c.maxWidth - (cols - 1) * 8) / cols;
                      final data = [
                        (
                          'Aujourd’hui',
                          s.todayVouchers,
                          s.todayIncome,
                          Icons.today_outlined,
                        ),
                        (
                          'Semaine',
                          s.weekVouchers,
                          s.weekIncome,
                          Icons.date_range_outlined,
                        ),
                        (
                          'Mois',
                          s.monthVouchers,
                          s.monthIncome,
                          Icons.calendar_month_outlined,
                        ),
                        (
                          'Total',
                          s.totalVouchers,
                          s.totalIncome,
                          Icons.payments_outlined,
                        ),
                      ];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in data)
                            SizedBox(
                              width: w,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(d.$4),
                                      const SizedBox(height: 8),
                                      Text(
                                        d.$1,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text('${d.$2} voucher(s)'),
                                      Text(
                                        money(d.$3, s.currency),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CA du mois par profil',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (s.monthByProfile.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Aucune vente ce mois.'),
                      ),
                    ),
                  ...s.monthByProfile.entries.map(
                    (e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.confirmation_number_outlined),
                        title: Text(e.key),
                        trailing: Text(
                          money(e.value, s.currency),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
