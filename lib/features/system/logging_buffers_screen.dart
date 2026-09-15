import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

class LoggingBuffersScreen extends StatefulWidget {
  final RouterOsService service;
  const LoggingBuffersScreen({super.key, required this.service});
  @override
  State<LoggingBuffersScreen> createState() => _S();
}

class _S extends State<LoggingBuffersScreen> {
  bool loading = true;
  List<Map<String, String>> actions = [];
  List<Map<String, String>> logs = [];
  String buffer = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    actions = (await widget.service.loggingActions())
        .where((e) => e['target'] == 'memory')
        .toList();
    if (actions.isNotEmpty) {
      buffer = buffer.isEmpty ? actions.first['name'] ?? '' : buffer;
      logs = await widget.service.logsForBuffer(buffer);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> change(String? v) async {
    buffer = v ?? '';
    logs = buffer.isEmpty ? [] : await widget.service.logsForBuffer(buffer);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Buffers mémoire'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: buffer.isEmpty ? null : buffer,
                  decoration: const InputDecoration(labelText: 'Buffer'),
                  items: actions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e['name'],
                          child: Text(
                            '${e['name']} • ${e['memory-lines'] ?? '?'} lignes',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: change,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final r in logs.reversed)
                      Card(
                        child: ListTile(
                          onTap: () => AppRouter.pushNamed(
                            context,
                            AppRoutes.logDetail,
                            extra: RequiredRowPayload(r),
                          ),
                          title: Text(
                            r['message'] ?? '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${r['time'] ?? ''} • ${r['topics'] ?? ''}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}
