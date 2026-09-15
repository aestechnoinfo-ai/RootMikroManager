import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';

class HotspotAddUserScreen extends StatefulWidget {
  final RouterOsService service;
  final String? initialProfile;

  const HotspotAddUserScreen({
    super.key,
    required this.service,
    this.initialProfile,
  });

  @override
  State<HotspotAddUserScreen> createState() => _HotspotAddUserScreenState();
}

class _HotspotAddUserScreenState extends State<HotspotAddUserScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  final timeLimit = TextEditingController();
  final dataLimit = TextEditingController();
  final comment = TextEditingController();

  List<Map<String, String>> profiles = [];
  List<Map<String, String>> servers = [];
  String profile = '';
  String server = 'all';
  String unit = 'MB';
  bool enabled = true;
  bool showPassword = false;
  bool loading = true;
  bool saving = false;
  String? error;

  bool get voucherMode =>
      username.text.trim().isNotEmpty && username.text.trim() == password.text;

  @override
  void initState() {
    super.initState();
    username.addListener(_refreshMode);
    password.addListener(_refreshMode);
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        widget.service.hotspotProfiles(),
        widget.service.hotspotServers(),
      ]);
      profiles = values[0];
      servers = values[1];
      final requested = widget.initialProfile ?? '';
      if (requested.isNotEmpty &&
          profiles.any((row) => row['name'] == requested)) {
        profile = requested;
      } else if (profiles.isNotEmpty) {
        profile = profiles.first['name'] ?? '';
      }
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  int _bytes() {
    final value =
        double.tryParse(dataLimit.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0) return 0;
    return (value * (unit == 'GB' ? 1073741824 : 1048576)).round();
  }

  String _routerComment() {
    final raw = comment.text.trim();
    if (raw.startsWith('vc-') || raw.startsWith('up-')) return raw;
    final prefix = voucherMode ? 'vc-' : 'up-';
    return '$prefix$raw';
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (profile.isEmpty) {
      _message('Sélectionne un profil Hotspot.');
      return;
    }

    setState(() => saving = true);
    try {
      await widget.service.addHotspotUser(
        server: server,
        name: username.text.trim(),
        password: password.text,
        profile: profile,
        comment: _routerComment(),
        timeLimit: timeLimit.text,
        dataLimitBytes: _bytes(),
        enabled: enabled,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => saving = false);
      _message('$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ajouter utilisateur Hotspot'),
      actions: [
        IconButton(
          tooltip: 'Enregistrer',
          onPressed: saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(error!),
            ),
          )
        : Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          voucherMode
                              ? Icons.confirmation_number_outlined
                              : Icons.person_outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            voucherMode
                                ? 'Mode voucher : username = password'
                                : 'Mode utilisateur : username et password distincts',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final fields = [
                      DropdownButtonFormField<String>(
                        value: server,
                        decoration: const InputDecoration(
                          labelText: 'Serveur Hotspot',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('all'),
                          ),
                          ...servers.map(
                            (row) => DropdownMenuItem(
                              value: row['name'] ?? '',
                              child: Text(row['name'] ?? '—'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => server = v ?? 'all'),
                      ),
                      DropdownButtonFormField<String>(
                        value: profile.isEmpty ? null : profile,
                        decoration: const InputDecoration(labelText: 'Profil'),
                        items: profiles
                            .map(
                              (row) => DropdownMenuItem(
                                value: row['name'] ?? '',
                                child: Text(row['name'] ?? '—'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => profile = v ?? ''),
                      ),
                    ];
                    if (c.maxWidth < 680) {
                      return Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 10),
                          fields[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 10),
                        Expanded(child: fields[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: username,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Username obligatoire.' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: password,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    final time = TextFormField(
                      controller: timeLimit,
                      decoration: const InputDecoration(
                        labelText: 'Time Limit',
                        hintText: 'Ex. 1h, 30m, 1d',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    );
                    final data = Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dataLimit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Data Limit',
                              hintText: '0 = illimité',
                              prefixIcon: Icon(Icons.data_usage_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 92,
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: const InputDecoration(
                              labelText: 'Unité',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'MB', child: Text('MB')),
                              DropdownMenuItem(value: 'GB', child: Text('GB')),
                            ],
                            onChanged: (v) => setState(() => unit = v ?? 'MB'),
                          ),
                        ),
                      ],
                    );
                    if (c.maxWidth < 680) {
                      return Column(
                        children: [time, const SizedBox(height: 10), data],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: time),
                        const SizedBox(width: 10),
                        Expanded(child: data),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: comment,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Commentaire',
                    helperText: voucherMode
                        ? 'Préfixe RouterOS automatique : vc-'
                        : 'Préfixe RouterOS automatique : up-',
                    prefixIcon: const Icon(Icons.comment_outlined),
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Utilisateur activé'),
                  subtitle: const Text(
                    'Désactive ce commutateur pour créer le compte en état disabled.',
                  ),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: const Text('Ajouter utilisateur'),
                ),
              ],
            ),
          ),
  );

  void _refreshMode() {
    if (mounted) setState(() {});
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    username.removeListener(_refreshMode);
    password.removeListener(_refreshMode);
    username.dispose();
    password.dispose();
    timeLimit.dispose();
    dataLimit.dispose();
    comment.dispose();
    super.dispose();
  }
}
