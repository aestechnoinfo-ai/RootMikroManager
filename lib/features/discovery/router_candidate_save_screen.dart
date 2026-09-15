import 'package:flutter/material.dart';

import '../../core/security/secure_store.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/routeros/routeros_client.dart';
import '../../data/models/router_model.dart';
import '../../data/repositories/router_repository.dart';
import 'discovery_candidate.dart';

class RouterCandidateSaveScreen extends StatefulWidget {
  final DiscoveryCandidate candidate;

  const RouterCandidateSaveScreen({super.key, required this.candidate});

  @override
  State<RouterCandidateSaveScreen> createState() =>
      _RouterCandidateSaveScreenState();
}

class _RouterCandidateSaveScreenState extends State<RouterCandidateSaveScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController host;
  late final TextEditingController port;
  late final TextEditingController username;
  late final TextEditingController password;
  late final TextEditingController group;
  late final TextEditingController tags;
  bool saving = false;
  bool testing = false;
  bool verified = false;
  bool useTls = false;
  int revision = 0;
  String? testResult;

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;
    useTls = c.useTls || c.preferredPort == 8729;
    name = TextEditingController(text: c.bestName);
    host = TextEditingController(text: c.preferredHost);
    port = TextEditingController(text: '${c.preferredPort}');
    username = TextEditingController(text: 'admin');
    password = TextEditingController();
    group = TextEditingController(text: 'Découverts');
    tags = TextEditingController(
      text: [
        c.source.toLowerCase().replaceAll(' ', '-'),
        if (c.interfaceName.isNotEmpty)
          c.interfaceName.toLowerCase().replaceAll(' ', '-'),
      ].join(','),
    );
  }

  RouterModel get candidateRouter => RouterModel(
    name: name.text.trim(),
    host: host.text.trim(),
    port: int.tryParse(port.text.trim()) ?? 8728,
    username: username.text.trim(),
    groupName: group.text.trim().isEmpty ? 'Découverts' : group.text.trim(),
    tags: tags.text.trim(),
    macAddress: widget.candidate.macAddress,
    romonId: widget.candidate.romonId,
    useTls: useTls,
    protocols: widget.candidate.protocols.join(','),
    boardName: widget.candidate.board,
  );

  void invalidateTest() {
    revision++;
    setState(() {
      verified = false;
      testResult = null;
    });
  }

  Future<void> testConnection() async {
    if (!(formKey.currentState?.validate() ?? false) || testing || saving) {
      return;
    }
    final version = revision;
    final probe = RouterOsService();
    setState(() {
      testing = true;
      verified = false;
      testResult = null;
    });
    try {
      await probe.connect(
        candidateRouter,
        password.text,
        allowSelfSignedCertificate: false,
      );
      await probe.identity();
      if (mounted && version == revision) {
        setState(() {
          verified = true;
          testResult =
              'Authentification réussie. Vous pouvez enregistrer ce routeur.';
        });
      }
    } on RouterOsAuthenticationException {
      if (mounted && version == revision) {
        setState(
          () => testResult =
              'Identifiants refusés. Vérifiez utilisateur et mot de passe.',
        );
      }
    } catch (_) {
      if (mounted && version == revision) {
        setState(
          () => testResult =
              'Connexion impossible. Vérifiez IP, port, TLS, certificat et VPN.',
        );
      }
    } finally {
      await probe.client.close();
      if (mounted) setState(() => testing = false);
    }
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false) || saving || !verified) {
      return;
    }
    setState(() => saving = true);
    final router = candidateRouter;
    final secret = password.text;

    try {
      final id = await RouterRepository().save(router);
      await SecureStore().saveRouterPassword(id, secret);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Enregistrer le routeur')),
    body: Form(
      key: formKey,
      onChanged: invalidateTest,
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
          TextFormField(
            controller: host,
            decoration: const InputDecoration(labelText: 'IP / Domaine *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Adresse obligatoire' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: port,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Port API'),
            validator: (v) {
              final number = int.tryParse(v?.trim() ?? '');
              return number == null || number < 1 || number > 65535
                  ? 'Port compris entre 1 et 65535 requis'
                  : null;
            },
          ),
          SwitchListTile(
            title: const Text('API-SSL / TLS'),
            subtitle: const Text(
              'Indépendant du numéro de port. Certificat valide requis.',
            ),
            value: useTls,
            onChanged: testing || saving
                ? null
                : (value) {
                    useTls = value;
                    invalidateTest();
                  },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: username,
            decoration: const InputDecoration(
              labelText: 'Utilisateur RouterOS *',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Utilisateur obligatoire' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            validator: (v) =>
                (v ?? '').isEmpty ? 'Mot de passe obligatoire' : null,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: group,
            decoration: const InputDecoration(labelText: 'Groupe'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: tags,
            decoration: const InputDecoration(labelText: 'Tags'),
          ),
          const SizedBox(height: 16),
          if (testResult != null) Text(testResult!),
          OutlinedButton.icon(
            onPressed: testing || saving ? null : testConnection,
            icon: const Icon(Icons.network_check),
            label: Text(testing ? 'Vérification…' : 'Tester la connexion'),
          ),
          FilledButton.icon(
            onPressed: saving || testing || !verified ? null : save,
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
    host.dispose();
    port.dispose();
    username.dispose();
    password.dispose();
    group.dispose();
    tags.dispose();
    super.dispose();
  }
}
