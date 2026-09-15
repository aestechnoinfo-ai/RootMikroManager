import 'package:flutter/material.dart';
import '../../core/export/user_selected_export_service.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotUsersExportScreen extends StatefulWidget {
  final RouterOsService service;
  const HotspotUsersExportScreen({super.key, required this.service});

  @override
  State<HotspotUsersExportScreen> createState() =>
      _HotspotUsersExportScreenState();
}

class _HotspotUsersExportScreenState extends State<HotspotUsersExportScreen> {
  bool busy = false;
  String message = '';

  String csv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> export() async {
    setState(() {
      busy = true;
      message = '';
    });
    try {
      final rows = await widget.service.hotspotUsers();
      final buffer = StringBuffer()
        ..writeln(
          'name,password,profile,server,disabled,limit-uptime,'
          'limit-bytes-total,uptime,bytes-in,bytes-out,comment',
        );
      for (final r in rows) {
        buffer.writeln(
          [
            'name',
            'password',
            'profile',
            'server',
            'disabled',
            'limit-uptime',
            'limit-bytes-total',
            'uptime',
            'bytes-in',
            'bytes-out',
            'comment',
          ].map((k) => csv(r[k] ?? '')).join(','),
        );
      }
      final location = await const UserSelectedExportService().saveText(
        suggestedName:
            'hotspot_users_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
        content: buffer.toString(),
      );
      message = location == null
          ? 'Export annulé.'
          : 'CSV enregistré dans l’emplacement choisi.';
    } catch (e) {
      message = 'Erreur : $e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exporter Hotspot Users')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Export CSV local des comptes Hotspot actuellement '
              'présents sur le routeur.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : export,
          icon: const Icon(Icons.file_download_outlined),
          label: Text(busy ? 'Export…' : 'Créer le CSV'),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          SelectableText(message),
        ],
      ],
    ),
  );
}
