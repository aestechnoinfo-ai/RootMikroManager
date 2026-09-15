import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'sales_cleanup_service.dart';

enum SalesCleanupMode { day, month }

class SalesCleanupPreviewScreen extends StatefulWidget {
  final RouterOsService service;
  const SalesCleanupPreviewScreen({super.key, required this.service});

  @override
  State<SalesCleanupPreviewScreen> createState() => _State();
}

class _State extends State<SalesCleanupPreviewScreen> {
  DateTime date = DateTime.now();
  SalesCleanupMode mode = SalesCleanupMode.day;
  bool loading = false;
  List<SalesCleanupCandidate> rows = [];
  String currency = '';
  String message = '';

  SalesCleanupService get cleanup => SalesCleanupService(widget.service);

  Future<void> load() async {
    setState(() {
      loading = true;
      message = '';
    });
    currency = await AppCurrencySettings.load();
    rows = mode == SalesCleanupMode.day
        ? await cleanup.candidatesForDay(date)
        : await cleanup.candidatesForMonth(date);
    if (mounted) setState(() => loading = false);
  }

  double get total => rows.fold(0, (sum, e) => sum + e.record.numericPrice);

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked == null) return;
    setState(() => date = picked);
    await load();
  }

  Future<void> remove() async {
    if (rows.isEmpty) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer les données affichées ?'),
            content: Text(
              '${rows.length} enregistrement(s) de vente seront supprimés '
              'de /system/script. Cette action ne supprime aucun voucher.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    setState(() => loading = true);
    final result = await cleanup.remove(rows);
    message =
        '${result.removed}/${result.selected} supprimé(s).'
        '${result.failures.isEmpty ? '' : ' ${result.failures.length} échec(s).'}';
    await load();
    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nettoyage des ventes')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SegmentedButton<SalesCleanupMode>(
          segments: const [
            ButtonSegment(value: SalesCleanupMode.day, label: Text('Jour')),
            ButtonSegment(value: SalesCleanupMode.month, label: Text('Mois')),
          ],
          selected: {mode},
          onSelectionChanged: (values) {
            setState(() => mode = values.first);
            load();
          },
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: loading ? null : pickDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}',
          ),
        ),
        Card(
          child: ListTile(
            title: Text('${rows.length} vente(s)'),
            subtitle: Text(AppCurrencySettings.format(total, currency)),
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'La sélection est calculée après lecture et normalisation '
              'des dates. Elle fonctionne avec les anciens formats de '
              'date et les dates ISO de RouterOS récent.',
            ),
          ),
        ),
        for (final row in rows)
          Card(
            child: ListTile(
              title: Text(row.record.username),
              subtitle: Text(
                '${row.record.date} ${row.record.time} • '
                '${row.record.profile}',
              ),
              trailing: Text(
                AppCurrencySettings.format(row.record.numericPrice, currency),
              ),
            ),
          ),
        if (message.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(message),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: loading || rows.isEmpty ? null : remove,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Supprimer les données affichées'),
        ),
      ],
    ),
  );
}
