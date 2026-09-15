import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';
import '../logs/router_log_actions_menu.dart';

class LogsManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const LogsManagementScreen({super.key, required this.service});
  @override
  State<LogsManagementScreen> createState() => _S();
}

class _S extends State<LogsManagementScreen> {
  final search = TextEditingController();
  String topic = 'all', severity = 'all', buffer = 'all';
  bool loading = true, auto = false;
  Timer? timer;
  List<Map<String, String>> rows = [];
  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  Future<void> load() async {
    if (mounted && rows.isEmpty) setState(() => loading = true);
    rows = await widget.service.logs();
    if (mounted) setState(() => loading = false);
  }

  void setAuto(bool v) {
    timer?.cancel();
    auto = v;
    if (v) timer = Timer.periodic(const Duration(seconds: 5), (_) => load());
    setState(() {});
  }

  List<String> values(String key) {
    final s = <String>{};
    for (final r in rows) {
      for (final x in (r[key] ?? '').split(',')) {
        if (x.trim().isNotEmpty) s.add(x.trim());
      }
    }
    final a = s.toList()..sort();
    return ['all', ...a];
  }

  List<Map<String, String>> get visible {
    final q = search.text.trim().toLowerCase();
    return rows
        .where((r) {
          final ts = (r['topics'] ?? '').split(',');
          if (topic != 'all' && !ts.contains(topic)) return false;
          if (buffer != 'all' && (r['buffer'] ?? '') != buffer) return false;
          if (severity != 'all' && !ts.contains(severity)) return false;
          if (q.isNotEmpty && !r.values.any((v) => v.toLowerCase().contains(q)))
            return false;
          return true;
        })
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Logs (${rows.length})'),
      actions: [
        RouterLogActionsMenu(service: widget.service, onChanged: load),
        IconButton(
          onPressed: () => setAuto(!auto),
          icon: Icon(auto ? Icons.sync : Icons.sync_disabled),
        ),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (c, k) {
              final fs = <Widget>[
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Recherche',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: values('topics').contains(topic) ? topic : 'all',
                  decoration: const InputDecoration(labelText: 'Topic'),
                  items: values('topics')
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => topic = v ?? 'all'),
                ),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Sévérité'),
                  items:
                      const [
                            'all',
                            'critical',
                            'error',
                            'warning',
                            'debug',
                            'info',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => severity = v ?? 'all'),
                ),
                DropdownButtonFormField<String>(
                  value: values('buffer').contains(buffer) ? buffer : 'all',
                  decoration: const InputDecoration(labelText: 'Buffer'),
                  items: values('buffer')
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => buffer = v ?? 'all'),
                ),
              ];
              return k.maxWidth < 720
                  ? Column(
                      children: [
                        for (final f in fs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: f,
                          ),
                      ],
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in fs)
                          SizedBox(width: (k.maxWidth - 8) / 2, child: f),
                      ],
                    );
            },
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final r = visible[i], t = r['topics'] ?? '';
                    final icon = t.contains('critical')
                        ? Icons.dangerous_outlined
                        : t.contains('error')
                        ? Icons.error_outline
                        : t.contains('warning')
                        ? Icons.warning_amber_outlined
                        : t.contains('debug')
                        ? Icons.bug_report_outlined
                        : Icons.info_outline;
                    return Card(
                      child: ListTile(
                        onTap: () => AppRouter.pushNamed(
                          context,
                          AppRoutes.logDetail,
                          extra: RequiredRowPayload(r),
                        ),
                        leading: Icon(icon),
                        title: Text(
                          r['message'] ?? '—',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            r['time'] ?? '',
                            t,
                            if ((r['buffer'] ?? '').isNotEmpty)
                              'Buffer ${r['buffer']}',
                          ].where((e) => e.isNotEmpty).join(' • '),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }
}
