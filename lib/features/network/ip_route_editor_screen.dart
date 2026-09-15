import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'network_input_validator.dart';
import 'routing_policy_analyzer.dart';

class IpRouteEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const IpRouteEditorScreen({super.key, required this.service, this.row});

  @override
  State<IpRouteEditorScreen> createState() => _IpRouteEditorScreenState();
}

class _IpRouteEditorScreenState extends State<IpRouteEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController dstAddress;
  late final TextEditingController gateway;
  late final TextEditingController distance;
  late final TextEditingController scope;
  late final TextEditingController targetScope;
  late final TextEditingController prefSrc;
  late final TextEditingController comment;

  String routingTable = 'main';
  String checkGateway = 'none';
  bool suppressHwOffload = false;
  bool enabled = true;
  bool loading = true;
  bool saving = false;
  List<String> routingTables = ['main'];

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    dstAddress = TextEditingController(
      text: (r?['dst-address'] ?? '').isEmpty ? '0.0.0.0/0' : r?['dst-address'],
    );
    gateway = TextEditingController(text: r?['gateway'] ?? '');
    distance = TextEditingController(text: r?['distance'] ?? '1');
    scope = TextEditingController(text: r?['scope'] ?? '30');
    targetScope = TextEditingController(text: r?['target-scope'] ?? '10');
    prefSrc = TextEditingController(text: r?['pref-src'] ?? '');
    comment = TextEditingController(text: r?['comment'] ?? '');
    routingTable = r?['routing-table'] ?? 'main';
    checkGateway = r?['check-gateway'] ?? 'none';
    suppressHwOffload =
        r?['suppress-hw-offload'] == 'yes' ||
        r?['suppress-hw-offload'] == 'true';
    enabled = r?['disabled'] != 'yes' && r?['disabled'] != 'true';
    loadTables();
  }

  Future<void> loadTables() async {
    try {
      final rows = await widget.service.routingTables();
      routingTables = [
        'main',
        ...rows
            .map((e) => (e['name'] ?? '').trim())
            .where((e) => e.isNotEmpty && e != 'main'),
      ];
    } catch (_) {
      routingTables = ['main'];
    }
    if (!routingTables.contains(routingTable)) {
      routingTables.add(routingTable);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving || !(formKey.currentState?.validate() ?? false)) return;
    final d = int.tryParse(distance.text.trim()) ?? 1;
    final sc = int.tryParse(scope.text.trim()) ?? 30;
    final ts = int.tryParse(targetScope.text.trim()) ?? 10;
    final prefError = NetworkInputValidator.ipv4OrEmpty(
      prefSrc.text,
      label: 'Preferred Source',
    );
    if (prefError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(prefError)));
      return;
    }
    final issues = RoutingPolicyAnalyzer.ipv4Route(
      destination: dstAddress.text.trim(),
      gateway: gateway.text.trim(),
      table: routingTable,
      distance: d,
      scope: sc,
      targetScope: ts,
      checkGateway: checkGateway,
    );
    if (issues.isNotEmpty) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Vérification de la route'),
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

    final values = <String, String>{
      'dst-address': dstAddress.text.trim(),
      'gateway': gateway.text.trim(),
      'distance': distance.text.trim().isEmpty ? '1' : distance.text.trim(),
      'scope': scope.text.trim().isEmpty ? '30' : scope.text.trim(),
      'target-scope': targetScope.text.trim().isEmpty
          ? '10'
          : targetScope.text.trim(),
      'routing-table': routingTable,
      'check-gateway': checkGateway,
      'suppress-hw-offload': suppressHwOffload ? 'yes' : 'no',
      'disabled': enabled ? 'no' : 'yes',
      if (prefSrc.text.trim().isNotEmpty) 'pref-src': prefSrc.text.trim(),
      'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ip/route', values);
      } else {
        await widget.service.set('/ip/route', id, values);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null ? 'Ajouter route IPv4' : 'Modifier route IPv4',
      ),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: dstAddress,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: '0.0.0.0/0',
                  ),
                  validator: NetworkInputValidator.routeDestination,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: gateway,
                  decoration: const InputDecoration(
                    labelText: 'Gateway',
                    hintText: '192.168.1.1 ou interface',
                  ),
                  validator: NetworkInputValidator.gateway,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: routingTables.contains(routingTable)
                      ? routingTable
                      : 'main',
                  decoration: const InputDecoration(labelText: 'Routing Table'),
                  items: routingTables
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => routingTable = v ?? 'main'),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    final fields = [
                      _numberField(distance, 'Distance'),
                      _numberField(scope, 'Scope'),
                      _numberField(targetScope, 'Target Scope'),
                    ];
                    if (c.maxWidth < 620) {
                      return Column(
                        children: [
                          for (final f in fields) ...[
                            f,
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 8),
                        Expanded(child: fields[1]),
                        const SizedBox(width: 8),
                        Expanded(child: fields[2]),
                      ],
                    );
                  },
                ),
                DropdownButtonFormField<String>(isExpanded: true, 
                  value: checkGateway,
                  decoration: const InputDecoration(labelText: 'Check Gateway'),
                  items: const ['none', 'ping', 'arp', 'bfd']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => checkGateway = v ?? 'none'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prefSrc,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Source',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: comment,
                  decoration: const InputDecoration(labelText: 'Commentaire'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Suppress HW Offload'),
                  value: suppressHwOffload,
                  onChanged: (v) => setState(() => suppressHwOffload = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activée'),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
  );

  Widget _numberField(TextEditingController c, String label) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (v) =>
        NetworkInputValidator.integerRange(v, label: label, min: 0, max: 255),
  );

  @override
  void dispose() {
    dstAddress.dispose();
    gateway.dispose();
    distance.dispose();
    scope.dispose();
    targetScope.dispose();
    prefSrc.dispose();
    comment.dispose();
    super.dispose();
  }
}
