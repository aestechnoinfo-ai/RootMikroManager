import 'package:flutter/material.dart';
import 'routing_policy_analyzer.dart';
import 'network_input_validator.dart';
import '../../core/routeros/routeros_service.dart';

class RoutingRuleEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const RoutingRuleEditorScreen({super.key, required this.service, this.row});
  @override
  State<RoutingRuleEditorScreen> createState() => _State();
}

class _State extends State<RoutingRuleEditorScreen> {
  late final TextEditingController src, dst, comment;
  String table = 'main', action = 'lookup', interface = '';
  bool enabled = true, loading = true, saving = false;
  List<String> tables = ['main'], interfaces = [];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    src = TextEditingController(text: r?['src-address'] ?? '');
    dst = TextEditingController(text: r?['dst-address'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    table = r?['table'] ?? 'main';
    action = r?['action'] ?? 'lookup';
    interface = r?['interface'] ?? '';
    enabled = r?['disabled'] != 'yes';
    load();
  }

  Future<void> load() async {
    final x = await Future.wait([
      widget.service.routingTablesAdvanced(),
      widget.service.interfaces(),
    ]);
    tables =
        x[0]
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (!tables.contains('main')) tables.insert(0, 'main');
    if (!tables.contains(table)) tables.add(table);
    interfaces =
        x[1]
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (interface.isNotEmpty && !interfaces.contains(interface))
      interfaces.add(interface);
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    final error =
        NetworkInputValidator.ipOrCidr(src.text, label: 'Source') ??
        NetworkInputValidator.ipOrCidr(dst.text, label: 'Destination');
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (action.startsWith('lookup') && !tables.contains(table)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La table sélectionnée n’existe pas.')),
      );
      return;
    }
    final issues = RoutingPolicyAnalyzer.rule(
      action: action,
      source: src.text,
      destination: dst.text,
      table: table,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification Routing Rule'),
              content: Text(issues.map((e) => '• ${e.message}').join('\n\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Revoir'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }
    setState(() => saving = true);
    final v = <String, String>{
      if (src.text.trim().isNotEmpty) 'src-address': src.text.trim(),
      if (dst.text.trim().isNotEmpty) 'dst-address': dst.text.trim(),
      if (interface.isNotEmpty) 'interface': interface,
      'action': action,
      if (action.startsWith('lookup')) 'table': table,
      'disabled': enabled ? 'no' : 'yes',
      'comment': comment.text.trim(),
    };
    try {
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/routing/rule', v);
      else
        await widget.service.set('/routing/rule', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Ajouter une Routing Rule'
            : 'Modifier la Routing Rule',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: src,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  hintText: '192.168.10.0/24 ou 2001:db8::/64',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dst,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: '0.0.0.0/0 ou ::/0',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: interface.isEmpty ? null : interface,
                decoration: const InputDecoration(
                  labelText: 'Interface d’entrée',
                  hintText: 'Optionnel',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Toutes')),
                  ...interfaces.map(
                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) => setState(() => interface = v ?? ''),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(isExpanded: true, 
                value: action,
                decoration: const InputDecoration(labelText: 'Action'),
                items:
                    const [
                          'lookup',
                          'lookup-only-in-table',
                          'drop',
                          'unreachable',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => action = v ?? 'lookup'),
              ),
              if (action.startsWith('lookup')) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: table,
                  decoration: const InputDecoration(labelText: 'Table'),
                  items: tables
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => table = v ?? 'main'),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activée'),
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
              if (action == 'lookup-only-in-table')
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Attention : lookup-only-in-table ne retombe pas vers main si la route est introuvable dans cette table.',
                    ),
                  ),
                ),
              if (action == 'drop' || action == 'unreachable')
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Cette règle peut bloquer du trafic, y compris du trafic de management si son périmètre est trop large.',
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    src.dispose();
    dst.dispose();
    comment.dispose();
    super.dispose();
  }
}
