import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import 'package:printing/printing.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'monthly_resume_print_service.dart';
import 'sales_date_utils.dart';

class RootMikroManagerMonthlyResumeReportScreen extends StatefulWidget {
  final RouterOsService service;
  const RootMikroManagerMonthlyResumeReportScreen({
    super.key,
    required this.service,
  });

  @override
  State<RootMikroManagerMonthlyResumeReportScreen> createState() =>
      _RootMikroManagerMonthlyResumeReportScreenState();
}

class _RootMikroManagerMonthlyResumeReportScreenState
    extends State<RootMikroManagerMonthlyResumeReportScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  List<RootMikroManagerSalesRecord> records = [];
  String currency = '';
  bool loading = true;
  String? error;

  String get monthOwner {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return '${months[month.month - 1]}${month.year}';
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final values = await Future.wait([
        widget.service.rootmikromanagerSalesScripts(),
        AppCurrencySettings.load(),
      ]);
      records = (values[0] as List<Map<String, String>>)
          .map(RootMikroManagerSalesRecord.fromRouterOs)
          .where((r) => r.isValid && SalesDateUtils.sameMonth(r.date, month))
          .toList();
      currency = values[1] as String;
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Map<int, List<RootMikroManagerSalesRecord>> get byDay {
    final out = <int, List<RootMikroManagerSalesRecord>>{};
    for (final r in records) {
      final date = SalesDateUtils.parse(r.date);
      if (date == null) continue;
      out.putIfAbsent(date.day, () => []).add(r);
    }
    return out;
  }

  double get total => records.fold(0, (s, r) => s + r.numericPrice);

  Future<void> printReport() async {
    if (records.isEmpty) return;
    await Printing.layoutPdf(
      name: 'RootMikroManager-resume-$monthOwner',
      onLayout: (_) => MonthlyResumePrintService.buildPdf(
        records,
        currency,
        monthOwner.toUpperCase(),
      ),
    );
  }

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';
  Future<void> exportCsv() async {
    final out = StringBuffer()..writeln('Day,Vouchers,Total,Currency');
    final days = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (final e in days) {
      final amount = e.value.fold<double>(0, (s, r) => s + r.numericPrice);
      out.writeln(
        [
          e.key,
          e.value.length,
          amount.toStringAsFixed(2),
          currency,
        ].map((e) => _csv('$e')).join(','),
      );
    }
    out.writeln(
      'TOTAL,${records.length},${total.toStringAsFixed(2)},${_csv(currency)}',
    );
    final location = await const UserSelectedExportService().saveText(
      suggestedName: 'resume-rootmikromanager-$monthOwner.csv',
      mimeType: 'text/csv',
      content: out.toString(),
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            location == null
                ? 'Export annulé.'
                : 'CSV enregistré dans l’emplacement choisi.',
          ),
        ),
      );
  }

  Future<void> pickMonth() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDate: month,
      helpText: 'Choisir une date du mois',
    );
    if (value == null) return;
    month = DateTime(value.year, value.month);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final days = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxIncome = days.isEmpty
        ? 1.0
        : days
              .map((e) => e.value.fold<double>(0, (s, r) => s + r.numericPrice))
              .reduce((a, b) => a > b ? a : b)
              .clamp(1.0, double.infinity)
              .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Report'),
        actions: [
          IconButton(
            tooltip: 'Imprimer / PDF',
            onPressed: loading ? null : printReport,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Exporter CSV',
            onPressed: loading ? null : exportCsv,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Choisir le mois',
            onPressed: loading ? null : pickMonth,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          Text(
                            monthOwner.toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('${records.length} voucher(s)'),
                          Text(
                            'Total : ${AppCurrencySettings.format(total, currency)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (days.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text('Aucune vente ce mois.')),
                    ),
                  ...days.map((entry) {
                    final income = entry.value.fold<double>(
                      0,
                      (s, r) => s + r.numericPrice,
                    );
                    final ratio = income / maxIncome;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Jour ${entry.key}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text('${entry.value.length} voucher(s)'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppCurrencySettings.format(income, currency),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0).toDouble(),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
