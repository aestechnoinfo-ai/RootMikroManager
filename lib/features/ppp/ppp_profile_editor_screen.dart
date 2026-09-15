import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';
import 'ppp_profile_validator.dart';

class PppProfileEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;

  const PppProfileEditorScreen({super.key, required this.service, this.row});

  @override
  State<PppProfileEditorScreen> createState() => _PppProfileEditorScreenState();
}

class _PppProfileEditorScreenState extends State<PppProfileEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController localAddress;
  late final TextEditingController remoteAddress;
  late final TextEditingController dnsServer;
  late final TextEditingController rateLimit;
  late final TextEditingController sessionTimeout;
  late final TextEditingController idleTimeout;
  late final TextEditingController comment;
  bool onlyOne = false;
  List<Map<String, String>> existingProfiles = [];
  List<Map<String, String>> pools = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    name = TextEditingController(text: row?['name'] ?? '');
    localAddress = TextEditingController(text: row?['local-address'] ?? '');
    remoteAddress = TextEditingController(text: row?['remote-address'] ?? '');
    dnsServer = TextEditingController(text: row?['dns-server'] ?? '');
    rateLimit = TextEditingController(text: row?['rate-limit'] ?? '');
    sessionTimeout = TextEditingController(text: row?['session-timeout'] ?? '');
    idleTimeout = TextEditingController(text: row?['idle-timeout'] ?? '');
    comment = TextEditingController(text: row?['comment'] ?? '');
    onlyOne = (row?['only-one'] ?? 'no') == 'yes';
    loadReferences();
  }

  Future<void> loadReferences() async {
    try {
      final values = await Future.wait([
        widget.service.pppProfiles(),
        widget.service.ipPools(),
      ]);
      existingProfiles = values[0];
      pools = values[1];
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving) return;
    final issues = const PppProfileValidator().validate(
      name: name.text,
      localAddress: localAddress.text,
      remoteAddress: remoteAddress.text,
      rateLimit: rateLimit.text,
      sessionTimeout: sessionTimeout.text,
      idleTimeout: idleTimeout.text,
      currentId: widget.row?['.id'],
      profiles: existingProfiles,
      pools: pools,
    );
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(issues.join('\n'))));
      return;
    }

    setState(() => saving = true);

    final values = <String, String>{
      'name': name.text.trim(),
      'only-one': onlyOne ? 'yes' : 'no',
      if (localAddress.text.trim().isNotEmpty)
        'local-address': localAddress.text.trim(),
      if (remoteAddress.text.trim().isNotEmpty)
        'remote-address': remoteAddress.text.trim(),
      if (dnsServer.text.trim().isNotEmpty) 'dns-server': dnsServer.text.trim(),
      if (rateLimit.text.trim().isNotEmpty) 'rate-limit': rateLimit.text.trim(),
      if (sessionTimeout.text.trim().isNotEmpty)
        'session-timeout': sessionTimeout.text.trim(),
      if (idleTimeout.text.trim().isNotEmpty)
        'idle-timeout': idleTimeout.text.trim(),
      if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
    };

    try {
      final id = widget.row?['.id'];
      if (id == null) {
        await widget.service.add('/ppp/profile', values);
      } else {
        await widget.service.set('/ppp/profile', id, values);
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
        widget.row == null ? 'Ajouter un profil PPP' : 'Modifier le profil',
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
            controller: localAddress,
            decoration: const InputDecoration(labelText: 'Adresse locale'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: remoteAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse distante / pool',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: dnsServer,
            decoration: const InputDecoration(labelText: 'Serveurs DNS'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: rateLimit,
            decoration: const InputDecoration(
              labelText: 'Rate limit',
              hintText: 'ex: 10M/10M',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: sessionTimeout,
            decoration: const InputDecoration(
              labelText: 'Session timeout',
              hintText: 'ex: 1h',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: idleTimeout,
            decoration: const InputDecoration(
              labelText: 'Idle timeout',
              hintText: 'ex: 5m',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Une seule session par utilisateur'),
            value: onlyOne,
            onChanged: (v) => setState(() => onlyOne = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    name.dispose();
    localAddress.dispose();
    remoteAddress.dispose();
    dnsServer.dispose();
    rateLimit.dispose();
    sessionTimeout.dispose();
    idleTimeout.dispose();
    comment.dispose();
    super.dispose();
  }
}
