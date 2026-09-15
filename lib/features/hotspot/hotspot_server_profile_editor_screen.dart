import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotServerProfileEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? row;
  const HotspotServerProfileEditorScreen({
    super.key,
    required this.service,
    this.row,
  });
  @override
  State<HotspotServerProfileEditorScreen> createState() =>
      _HotspotServerProfileEditorScreenState();
}

class _HotspotServerProfileEditorScreenState
    extends State<HotspotServerProfileEditorScreen> {
  late final TextEditingController name,
      hotspotAddress,
      dnsName,
      htmlDirectory,
      rateLimit,
      httpCookieLifetime,
      sslCertificate;
  bool useRadius = false, saving = false;
  String loginBy = 'cookie,http-chap';
  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name'] ?? '');
    hotspotAddress = TextEditingController(
      text: r?['hotspot-address'] ?? '0.0.0.0',
    );
    dnsName = TextEditingController(text: r?['dns-name'] ?? '');
    htmlDirectory = TextEditingController(
      text: r?['html-directory'] ?? 'hotspot',
    );
    rateLimit = TextEditingController(text: r?['rate-limit'] ?? '');
    httpCookieLifetime = TextEditingController(
      text: r?['http-cookie-lifetime'] ?? '3d',
    );
    sslCertificate = TextEditingController(
      text: r?['ssl-certificate'] ?? 'none',
    );
    loginBy = r?['login-by'] ?? 'cookie,http-chap';
    useRadius = r?['use-radius'] == 'yes' || r?['use-radius'] == 'true';
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final v = <String, String>{
        'name': name.text.trim(),
        'hotspot-address': hotspotAddress.text.trim(),
        'dns-name': dnsName.text.trim(),
        'html-directory': htmlDirectory.text.trim(),
        'login-by': loginBy,
        'http-cookie-lifetime': httpCookieLifetime.text.trim(),
        'use-radius': useRadius ? 'yes' : 'no',
        'ssl-certificate': sslCertificate.text.trim(),
        if (rateLimit.text.trim().isNotEmpty)
          'rate-limit': rateLimit.text.trim(),
      };
      final id = widget.row?['.id'];
      if (id == null)
        await widget.service.add('/ip/hotspot/profile', v);
      else
        await widget.service.set('/ip/hotspot/profile', id, v);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.row == null
            ? 'Ajouter Server Profile'
            : 'Modifier Server Profile',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: hotspotAddress,
          decoration: const InputDecoration(labelText: 'Hotspot Address'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: dnsName,
          decoration: const InputDecoration(labelText: 'DNS Name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: htmlDirectory,
          decoration: const InputDecoration(labelText: 'HTML Directory'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: rateLimit,
          decoration: const InputDecoration(labelText: 'Rate Limit'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: loginBy,
          onChanged: (value) => loginBy = value,
          decoration: const InputDecoration(
            labelText: 'Login By',
            helperText: 'Ex: cookie,http-chap',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: httpCookieLifetime,
          decoration: const InputDecoration(labelText: 'HTTP Cookie Lifetime'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: sslCertificate,
          decoration: const InputDecoration(labelText: 'SSL Certificate'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use RADIUS'),
          value: useRadius,
          onChanged: (v) => setState(() => useRadius = v),
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
    name.dispose();
    hotspotAddress.dispose();
    dnsName.dispose();
    htmlDirectory.dispose();
    rateLimit.dispose();
    httpCookieLifetime.dispose();
    sslCertificate.dispose();
    super.dispose();
  }
}
