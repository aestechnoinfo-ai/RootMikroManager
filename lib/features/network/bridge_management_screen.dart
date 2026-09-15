import 'package:flutter/material.dart';

import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';
import 'bridge_vlan_validator.dart';

class BridgeManagementScreen extends StatefulWidget {
  final RouterOsService service;
  const BridgeManagementScreen({super.key, required this.service});

  @override
  State<BridgeManagementScreen> createState() => _BridgeManagementScreenState();
}

class _BridgeManagementScreenState extends State<BridgeManagementScreen> {
  bool loading = true;
  List<Map<String, String>> bridges = [];
  List<Map<String, String>> ports = [];
  List<Map<String, String>> vlans = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    final result = await Future.wait([
      widget.service.bridges(),
      widget.service.bridgePortsAdvanced(),
      widget.service.bridgeVlans(),
    ]);
    bridges = result[0];
    ports = result[1];
    vlans = result[2];
    if (mounted) setState(() => loading = false);
  }

  Future<void> editBridge([Map<String, String>? bridge]) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.bridgeEdit,
      extra: OptionalRowPayload(bridge),
    );
    if (changed == true) await load();
  }

  Future<void> configureFiltering(Map<String, String> bridge) async {
    final changed = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.bridgeVlanActivation,
      extra: RequiredRowPayload(bridge),
    );
    if (changed == true) await load();
  }

  Future<void> addPort() async {
    final interfaces = await widget.service.interfaces();
    final used = ports.map((e) => e['interface']).whereType<String>().toSet();
    final interfaceNames =
        interfaces
            .map((e) => e['name'] ?? '')
            .where((e) => e.isNotEmpty && !used.contains(e))
            .toList()
          ..sort();
    final bridgeNames =
        bridges.map((e) => e['name'] ?? '').where((e) => e.isNotEmpty).toList()
          ..sort();

    if (interfaceNames.isEmpty || bridgeNames.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune interface libre ou aucun bridge disponible.'),
          ),
        );
      }
      return;
    }

    var interfaceName = interfaceNames.first;
    var bridgeName = bridgeNames.first;
    var frameTypes = 'admit-all';
    var ingressFiltering = false;
    final pvid = TextEditingController(text: '1');

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, local) => AlertDialog(
              title: const Text('Ajouter port Bridge'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: bridgeName,
                      decoration: const InputDecoration(labelText: 'Bridge'),
                      items: bridgeNames
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          local(() => bridgeName = v ?? bridgeName),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: interfaceName,
                      decoration: const InputDecoration(labelText: 'Interface'),
                      items: interfaceNames
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          local(() => interfaceName = v ?? interfaceName),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pvid,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PVID',
                        helperText: '1 à 4094',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: frameTypes,
                      decoration: const InputDecoration(
                        labelText: 'Frame types',
                      ),
                      items:
                          const [
                                'admit-all',
                                'admit-only-vlan-tagged',
                                'admit-only-untagged-and-priority-tagged',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) =>
                          local(() => frameTypes = v ?? frameTypes),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ingress filtering'),
                      value: ingressFiltering,
                      onChanged: (v) => local(() => ingressFiltering = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ajouter'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (ok) {
      if (!BridgeVlanValidator.validVlanId(pvid.text)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PVID invalide.')));
        }
      } else {
        await widget.service.add('/interface/bridge/port', {
          'bridge': bridgeName,
          'interface': interfaceName,
          'pvid': pvid.text.trim(),
          'frame-types': frameTypes,
          'ingress-filtering': ingressFiltering ? 'yes' : 'no',
        });
        await load();
      }
    }
    pvid.dispose();
  }

  Future<void> removePort(Map<String, String> row) async {
    final id = row['.id'];
    if (id == null) return;
    final iface = row['interface'] ?? 'ce port';
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Retirer ce port du bridge ?'),
            content: Text(
              '$iface sera retiré de ${row['bridge'] ?? 'ce bridge'}. '
              'Si ce port transporte le management ou un trunk, la connexion peut être interrompue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retirer'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await widget.service.remove('/interface/bridge/port', id);
    await load();
  }

  Future<void> removeBridge(Map<String, String> bridge) async {
    final id = bridge['.id'];
    final name = bridge['name'] ?? '';
    if (id == null || name.isEmpty) return;
    final portCount = ports.where((e) => e['bridge'] == name).length;
    final vlanCount = vlans.where((e) => e['bridge'] == name).length;
    if (portCount > 0 || vlanCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Suppression bloquée : $portCount port(s) et $vlanCount entrée(s) VLAN utilisent $name.',
          ),
        ),
      );
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer $name ?'),
            content: const Text(
              'Cette opération supprime l’interface bridge. Elle est irréversible.',
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
    await widget.service.remove('/interface/bridge', id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bridges & ports'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => editBridge(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter Bridge'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: addPort,
                  icon: const Icon(Icons.add_link),
                  label: const Text('Ajouter port au Bridge'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Bridges', style: Theme.of(context).textTheme.titleMedium),
              for (final bridge in bridges)
                Card(
                  child: ListTile(
                    onTap: () => editBridge(bridge),
                    leading: Icon(
                      bridge['vlan-filtering'] == 'yes'
                          ? Icons.verified_user_outlined
                          : Icons.device_hub_outlined,
                    ),
                    title: Text(bridge['name'] ?? '—'),
                    subtitle: Text(
                      [
                        'Protocol ${bridge['protocol-mode'] ?? '—'}',
                        'VLAN filtering ${bridge['vlan-filtering'] ?? 'no'}',
                        '${ports.where((e) => e['bridge'] == bridge['name']).length} port(s)',
                        if ((bridge['comment'] ?? '').isNotEmpty)
                          bridge['comment']!,
                      ].join(' • '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') editBridge(bridge);
                        if (value == 'vlan') configureFiltering(bridge);
                        if (value == 'delete') removeBridge(bridge);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'vlan',
                          child: Text('VLAN Filtering sécurisé'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Ports Bridge',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final port in ports)
                Card(
                  child: ListTile(
                    leading: Icon(
                      port['hw'] == 'yes' ? Icons.memory : Icons.cable_outlined,
                    ),
                    title: Text(port['interface'] ?? '—'),
                    subtitle: Text(
                      'Bridge ${port['bridge'] ?? '—'} • PVID ${port['pvid'] ?? '1'} • '
                      '${port['frame-types'] ?? 'admit-all'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Retirer du Bridge',
                      onPressed: () => removePort(port),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            ],
          ),
  );
}
