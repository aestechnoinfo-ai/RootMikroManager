import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import 'package:printing/printing.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/routeros/router_session.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_sales_record.dart';
import 'sales_report_print_service.dart';
import 'sales_date_utils.dart';
import 'sales_cleanup_service.dart';
import 'sales_cache_repository.dart';
import 'sales_sync_coordinator.dart';

enum SalesPeriodMode { all, day, month }

class RootMikroManagerSalesReportScreen extends StatefulWidget {
  final RouterOsService service;
  const RootMikroManagerSalesReportScreen({super.key, required this.service});

  @override
  State<RootMikroManagerSalesReportScreen> createState() =>
      _RootMikroManagerSalesReportScreenState();
}

class _RootMikroManagerSalesReportScreenState
    extends State<RootMikroManagerSalesReportScreen>
    with WidgetsBindingObserver {
  final search = TextEditingController();
  SalesPeriodMode mode = SalesPeriodMode.all;
  DateTime date = DateTime.now();
  List<RootMikroManagerSalesRecord> records = [];
  bool loading = true;
  String? error;
  String currency = '';
  String profileFilter = 'all';
  String commentFilter = 'all';
  DateTime? cacheUpdatedAt;
  bool syncing = false;
  bool offline = false;
  int page = 0;
  static const pageSize = 100;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      final routerId = RouterSession.instance.activeRouter?.id;
      currency = await AppCurrencySettings.load();
      final cache = routerId == null
          ? const SalesCacheSnapshot([], null)
          : await const SalesCacheRepository().read(routerId);
      cacheUpdatedAt = cache.updatedAt;
      records = cache.rows
          .map(RootMikroManagerSalesRecord.fromRouterOs)
          .where((r) => r.isValid)
          .toList(growable: false);
      error = null;
      offline = false;
      if (routerId != null &&
          !cache.isFresh(DateTime.now().toUtc(), SalesSyncCoordinator.ttl)) {
        unawaited(_sync(routerId));
      }
      _startTimer();
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  List<String> get profiles {
    final values =
        records
            .map((r) => r.profile)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<String> get comments {
    final values =
        records
            .map((r) => r.comment)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<RootMikroManagerSalesRecord> get shown {
    final q = search.text.trim().toLowerCase();
    return records.where((r) {
      final periodOk = switch (mode) {
        SalesPeriodMode.all => true,
        SalesPeriodMode.day => SalesDateUtils.sameDay(r.date, date),
        SalesPeriodMode.month => SalesDateUtils.sameMonth(r.date, date),
      };
      final searchOk =
          q.isEmpty ||
          [
            r.username,
            r.profile,
            r.comment,
            r.date,
            r.time,
          ].any((v) => v.toLowerCase().contains(q));
      final profileOk = profileFilter == 'all' || r.profile == profileFilter;
      final commentOk = commentFilter == 'all' || r.comment == commentFilter;
      return periodOk && searchOk && profileOk && commentOk;
    }).toList();
  }

  List<RootMikroManagerSalesRecord> get visiblePage {
    final source = shown;
    final start = (page * pageSize).clamp(0, source.length);
    final end = (start + pageSize).clamp(0, source.length);
    return source.sublist(start, end);
  }

  int get pageCount => shown.isEmpty ? 1 : (shown.length / pageSize).ceil();

  double get total => shown.fold(0, (sum, r) => sum + r.numericPrice);

  Map<String, double> get totalsByProfile {
    final map = <String, double>{};
    for (final r in shown) {
      map.update(
        r.profile,
        (v) => v + r.numericPrice,
        ifAbsent: () => r.numericPrice,
      );
    }
    return map;
  }

  String get periodLabel => switch (mode) {
    SalesPeriodMode.all => 'Toutes les ventes',
    SalesPeriodMode.day => daySource,
    SalesPeriodMode.month => monthOwner,
  };

  Future<void> printReport() async {
    final snapshot = List<RootMikroManagerSalesRecord>.unmodifiable(
      List<RootMikroManagerSalesRecord>.from(shown, growable: false),
    );
    if (snapshot.isEmpty) {
      _message('Aucune vente à imprimer.');
      return;
    }
    await Printing.layoutPdf(
      name: 'RootMikroManager-selling-report',
      onLayout: (_) => SalesReportPrintService.buildPdf(
        records: snapshot,
        currency: currency,
        periodLabel: periodLabel,
      ),
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
    setState(() => page = 0);
  }

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  Future<void> exportCsv() async {
    final out = StringBuffer()
      ..writeln('Date,Time,Username,Profile,Comment,Price,Currency');
    for (final r in shown) {
      out.writeln(
        [
          r.date,
          r.time,
          r.username,
          r.profile,
          r.comment,
          r.price,
          currency,
        ].map(_csv).join(','),
      );
    }
    out.writeln(',,,,TOTAL,${total.toStringAsFixed(2)},${_csv(currency)}');

    final suffix = mode == SalesPeriodMode.all
        ? 'all'
        : mode == SalesPeriodMode.day
        ? '${date.year}-${date.month}-${date.day}'
        : '${date.year}-${date.month}';
    final location = await const UserSelectedExportService().saveText(
      suggestedName: 'report-rootmikromanager-$suffix.csv',
      mimeType: 'text/csv',
      content: out.toString(),
    );
    _message(
      location == null
          ? 'Export annulé.'
          : 'CSV enregistré dans l’emplacement choisi.',
    );
  }

  Future<void> removeData() async {
    if (mode == SalesPeriodMode.all) {
      _message('Sélectionne un jour ou un mois avant Remove Data.');
      return;
    }

    final cleanup = SalesCleanupService(widget.service);
    final candidates = mode == SalesPeriodMode.day
        ? await cleanup.candidatesForDay(date)
        : await cleanup.candidatesForMonth(date);

    if (candidates.isEmpty) {
      _message('Aucun enregistrement correspondant à la période.');
      return;
    }

    final amount = candidates.fold<double>(
      0,
      (sum, e) => sum + e.record.numericPrice,
    );

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Remove Data'),
            content: Text(
              '${candidates.length} vente(s) correspondant réellement à '
              '$periodLabel seront supprimées de /system/script.\n\n'
              'Montant concerné : '
              '${AppCurrencySettings.format(amount, currency)}.\n\n'
              'Les vouchers eux-mêmes ne seront pas supprimés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final result = await cleanup.remove(candidates);
    await load();
    _message(
      '${result.removed}/${result.selected} enregistrement(s) supprimé(s)'
      '${result.failures.isEmpty ? '.' : ' • ${result.failures.length} échec(s).'}',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Selling Report'),
      actions: [
        if (offline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Center(child: Chip(label: Text('Hors ligne'))),
          ),
        IconButton(
          tooltip: 'Synchroniser',
          onPressed: syncing
              ? null
              : () {
                  final id = RouterSession.instance.activeRouter?.id;
                  if (id != null) _sync(id, force: true);
                },
          icon: syncing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
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
        PopupMenuButton<String>(
          onSelected: (_) => removeData(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'remove', child: Text('Remove Data')),
          ],
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: FilledButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: Text(error!),
            ),
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _filters(),
                const SizedBox(height: 10),
                _summary(),
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Aucune vente.')),
                  ),
                ...visiblePage.map(
                  (r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(r.username),
                      subtitle: Text(
                        [
                          '${r.date} ${r.time}',
                          'Profil: ${r.profile}',
                          if (r.validity.isNotEmpty) 'Validity: ${r.validity}',
                          if (r.comment.isNotEmpty) 'Comment: ${r.comment}',
                        ].join(' • '),
                      ),
                      trailing: Text(
                        AppCurrencySettings.formatRaw(r.price, currency),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                if (shown.length > pageSize) _pagination(),
              ],
            ),
          ),
  );

  Widget _filters() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SegmentedButton<SalesPeriodMode>(
            segments: const [
              ButtonSegment(value: SalesPeriodMode.all, label: Text('Tout')),
              ButtonSegment(value: SalesPeriodMode.day, label: Text('Jour')),
              ButtonSegment(value: SalesPeriodMode.month, label: Text('Mois')),
            ],
            selected: {mode},
            onSelectionChanged: (v) async {
              setState(() {
                mode = v.first;
                page = 0;
              });
            },
          ),
          if (mode != SalesPeriodMode.all) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  mode == SalesPeriodMode.day ? daySource : monthOwner,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: search,
            decoration: const InputDecoration(
              labelText: 'Recherche user / profil / commentaire',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final profile = DropdownButtonFormField<String>(isExpanded: true, 
                value: profiles.contains(profileFilter) ? profileFilter : 'all',
                decoration: const InputDecoration(labelText: 'Profil'),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tous les profils'),
                  ),
                  ...profiles.map(
                    (v) => DropdownMenuItem(value: v, child: Text(v)),
                  ),
                ],
                onChanged: (v) => setState(() {
                  profileFilter = v ?? 'all';
                  page = 0;
                }),
              );
              final comment = DropdownButtonFormField<String>(isExpanded: true, 
                value: comments.contains(commentFilter) ? commentFilter : 'all',
                decoration: const InputDecoration(
                  labelText: 'Commentaire / batch',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tous les commentaires'),
                  ),
                  ...comments.map(
                    (v) => DropdownMenuItem(value: v, child: Text(v)),
                  ),
                ],
                onChanged: (v) => setState(() {
                  commentFilter = v ?? 'all';
                  page = 0;
                }),
              );
              return compact
                  ? Column(
                      children: [profile, const SizedBox(height: 10), comment],
                    )
                  : Row(
                      children: [
                        Expanded(child: profile),
                        const SizedBox(width: 10),
                        Expanded(child: comment),
                      ],
                    );
            },
          ),
        ],
      ),
    ),
  );

  Widget _summary() {
    final entries = totalsByProfile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shown.length} vente(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Total : ${AppCurrencySettings.format(total, currency)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (cacheUpdatedAt != null)
              Text(
                'Cache : ${cacheUpdatedAt!.toLocal()}'
                '${offline ? ' • mode hors ligne' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Résumé par profil',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final e in entries.take(8))
                Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Text(AppCurrencySettings.format(e.value, currency)),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pagination() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: 'Page précédente',
        onPressed: page == 0 ? null : () => setState(() => page--),
        icon: const Icon(Icons.chevron_left),
      ),
      Text('Page ${page + 1} / $pageCount'),
      IconButton(
        tooltip: 'Page suivante',
        onPressed: page + 1 >= pageCount ? null : () => setState(() => page++),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Future<void> _sync(int routerId, {bool force = false}) async {
    if (syncing) return;
    if (mounted) setState(() => syncing = true);
    try {
      await SalesSyncCoordinator.instance.sync(
        routerId: routerId,
        force: force,
        fetch: () => RouterSession.instance.readIsolated(
          (reader) => reader.rootmikromanagerSalesScripts(),
        ),
      );
      final cache = await const SalesCacheRepository().read(routerId);
      if (!mounted) return;
      setState(() {
        records = cache.rows
            .map(RootMikroManagerSalesRecord.fromRouterOs)
            .where((record) => record.isValid)
            .toList(growable: false);
        cacheUpdatedAt = cache.updatedAt;
        offline = false;
        error = null;
        page = page.clamp(0, pageCount - 1);
      });
    } catch (_) {
      if (mounted) setState(() => offline = true);
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  void _startTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(SalesSyncCoordinator.ttl, (_) {
      final id = RouterSession.instance.activeRouter?.id;
      if (id != null) unawaited(_sync(id));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      final id = RouterSession.instance.activeRouter?.id;
      if (id != null) unawaited(_sync(id));
    } else {
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refreshTimer?.cancel();
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }
}
