import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'ppp_duplicate_secret_guard.dart';
import 'ppp_secret_validator.dart';

class PppSecretEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const PppSecretEditorScreen({super.key, required this.service, this.row});

  @override
  State<PppSecretEditorScreen> createState() => _PppSecretEditorScreenState();
}

class _PppSecretEditorScreenState extends State<PppSecretEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController password;
  late final TextEditingController localAddress;
  late final TextEditingController remoteAddress;
  late final TextEditingController callerId;
  late final TextEditingController routes;
  late final TextEditingController comment;

  String serviceType = 'pppoe';
  String profile = 'default';
  bool enabled = true;
  bool saving = false;
  List<String> profiles = ['default'];
  List<Map<String, String>> profileRows = [];
  List<Map<String, String>> pools = [];

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    name = TextEditingController(text: row?['name'] ?? '');
    password = TextEditingController(text: row?['password'] ?? '');
    localAddress = TextEditingController(text: row?['local-address'] ?? '');
    remoteAddress = TextEditingController(text: row?['remote-address'] ?? '');
    callerId = TextEditingController(text: row?['caller-id'] ?? '');
    routes = TextEditingController(text: row?['routes'] ?? '');
    comment = TextEditingController(text: row?['comment'] ?? '');
    serviceType = row?['service'] ?? 'pppoe';
    profile = row?['profile'] ?? 'default';
    enabled = row?['disabled'] != 'true' && row?['disabled'] != 'yes';
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final loaded = await Future.wait([
        widget.service.pppProfiles(),
        widget.service.ipPools(),
      ]);
      final rows = loaded[0];
      profileRows = rows;
      pools = loaded[1];
      final values =
          rows
              .map((e) => (e['name'] ?? '').trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (profile.isNotEmpty && !values.contains(profile)) {
        values.insert(0, profile);
      }
      if (!mounted) return;
      setState(() => profiles = values.isEmpty ? ['default'] : values);
    } catch (_) {}
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    final issues = const PppSecretValidator().validate(
      name: name.text,
      service: serviceType,
      profile: profile,
      localAddress: localAddress.text,
      remoteAddress: remoteAddress.text,
      profiles: profileRows,
      pools: pools,
    );
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(issues.join('\n'))));
      return;
    }

    setState(() => saving = true);

    final secrets = await widget.service.pppSecrets();
    final duplicate = const PppDuplicateSecretGuard().exists(
      name.text,
      secrets,
      exceptId: widget.row?['.id'],
    );
    if (duplicate) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un secret PPP porte déjà ce nom.')),
        );
      }
      return;
    }

    final values = <String, String>{
      'name': name.text.trim(),
      'service': serviceType,
      'profile': profile,
      'disabled': enabled ? 'no' : 'yes',
      if (password.text.isNotEmpty) 'password': password.text,
      if (localAddress.text.trim().isNotEmpty)
        'local-address': localAddress.text.trim(),
      if (remoteAddress.text.trim().isNotEmpty)
        'remote-address': remoteAddress.text.trim(),
      if (callerId.text.trim().isNotEmpty) 'caller-id': callerId.text.trim(),
      if (routes.text.trim().isNotEmpty) 'routes': routes.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ppp/secret', values);
      } else {
        await widget.service.set('/ppp/secret', id, values);
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
        widget.row == null ? 'Ajouter un secret PPP' : 'Modifier le secret',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nom *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nom obligatoire' : null,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: serviceType,
            decoration: const InputDecoration(labelText: 'Service'),
            items: const [
              'any',
              'async',
              'l2tp',
              'ovpn',
              'pppoe',
              'pptp',
              'sstp',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => serviceType = v ?? 'pppoe'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(isExpanded: true, 
            value: profiles.contains(profile) ? profile : profiles.first,
            decoration: const InputDecoration(labelText: 'Profil'),
            items: profiles
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => profile = v ?? 'default'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: localAddress,
            decoration: const InputDecoration(labelText: 'Adresse locale'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: remoteAddress,
            decoration: const InputDecoration(labelText: 'Adresse distante'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: callerId,
            decoration: const InputDecoration(labelText: 'Caller ID / MAC'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: routes,
            decoration: const InputDecoration(labelText: 'Routes'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activé'),
            value: enabled,
            onChanged: (v) => setState(() => enabled = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    localAddress.dispose();
    remoteAddress.dispose();
    callerId.dispose();
    routes.dispose();
    comment.dispose();
    super.dispose();
  }
}
