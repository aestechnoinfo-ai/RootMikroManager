import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import 'package:printing/printing.dart';
import '../../core/routeros/routeros_service.dart';
import 'rootmikromanager_sales_record.dart';
import 'user_log_print_service.dart';
import 'sales_date_utils.dart';

enum UserLogPeriodMode { all, day, month }

class RootMikroManagerUserLogReportScreen extends StatefulWidget {
  final RouterOsService service;
  const RootMikroManagerUserLogReportScreen({super.key, required this.service});

  @override
  State<RootMikroManagerUserLogReportScreen> createState() =>
      _RootMikroManagerUserLogReportScreenState();
}

class _RootMikroManagerUserLogReportScreenState
    extends State<RootMikroManagerUserLogReportScreen> {
  final search = TextEditingController();
  UserLogPeriodMode mode = UserLogPeriodMode.all;
  DateTime date = DateTime.now();
  List<RootMikroManagerSalesRecord> records = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    load();
  }

  String get daySource =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';

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
    return '${months[date.month - 1]}${date.year}';
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final rows = await widget.service.rootmikromanagerSalesScripts();
      records = rows
          .map(RootMikroManagerSalesRecord.fromRouterOs)
          .where((r) => r.username.isNotEmpty)
          .where(
            (r) => switch (mode) {
              UserLogPeriodMode.all => true,
              UserLogPeriodMode.day => SalesDateUtils.sameDay(r.date, date),
              UserLogPeriodMode.month => SalesDateUtils.sameMonth(r.date, date),
            },
          )
          .toList();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<RootMikroManagerSalesRecord> get shown {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records
        .where(
          (r) => [
            r.username,
            r.address,
            r.macAddress,
            r.validity,
            r.date,
            r.time,
          ].any((v) => v.toLowerCase().contains(q)),
        )
        .toList();
  }

  String get periodLabel => switch (mode) {
    UserLogPeriodMode.all => 'Toutes les connexions',
    UserLogPeriodMode.day => daySource,
    UserLogPeriodMode.month => monthOwner,
  };

  Future<void> printReport() async {
    if (shown.isEmpty) {
      _message('Aucune entrée à imprimer.');
      return;
    }
    await Printing.layoutPdf(
      name: 'RootMikroManager-user-log',
      onLayout: (_) => UserLogPrintService.buildPdf(shown, periodLabel),
    );
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDate: date,
    );
    if (value == null) return;
    date = value;
    await load();
  }

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  Future<void> exportCsv() async {
    final out = StringBuffer()
      ..writeln('Date,Time,Username,Address,Mac Address,Validity');
    for (final r in shown) {
      out.writeln(
        [
          r.date,
          r.time,
          r.username,
          r.address,
          r.macAddress,
          r.validity,
        ].map(_csv).join(','),
      );
    }
    final location = await const UserSelectedExportService().saveText(
      suggestedName:
          'user-log-rootmikromanager-${DateTime.now().millisecondsSinceEpoch}.csv',
      mimeType: 'text/csv',
      content: out.toString(),
    );
    _message(
      location == null
          ? 'Export annulé.'
          : 'CSV enregistré dans l’emplacement choisi.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('User Log (${shown.length})'),
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SegmentedButton<UserLogPeriodMode>(
                          segments: const [
                            ButtonSegment(
                              value: UserLogPeriodMode.all,
                              label: Text('Tout'),
                            ),
                            ButtonSegment(
                              value: UserLogPeriodMode.day,
                              label: Text('Jour'),
                            ),
                            ButtonSegment(
                              value: UserLogPeriodMode.month,
                              label: Text('Mois'),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (v) async {
                            mode = v.first;
                            await load();
                          },
                        ),
                        if (mode != UserLogPeriodMode.all) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: pickDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                mode == UserLogPeriodMode.day
                                    ? daySource
                                    : monthOwner,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextField(
                          controller: search,
                          decoration: const InputDecoration(
                            labelText: 'Recherche user / IP / MAC / validité',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Aucune entrée.')),
                  ),
                ...shown.map(
                  (r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: Text(r.username),
                      subtitle: Text(
                        [
                          '${r.date} ${r.time}',
                          if (r.address.isNotEmpty) 'IP: ${r.address}',
                          if (r.macAddress.isNotEmpty) 'MAC: ${r.macAddress}',
                          if (r.validity.isNotEmpty) 'Validité: ${r.validity}',
                        ].join(' • '),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }
}
