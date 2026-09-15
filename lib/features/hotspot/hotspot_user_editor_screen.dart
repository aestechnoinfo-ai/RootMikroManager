import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/navigation_payloads.dart';
import '../../core/navigation/routes.dart';

import '../../core/routeros/routeros_service.dart';
import '../vouchers/voucher_print_layout.dart';
import '../vouchers/voucher_template_settings.dart';
import 'hotspot_profile_config.dart';

class HotspotUserEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String> user;

  const HotspotUserEditorScreen({
    super.key,
    required this.service,
    required this.user,
  });

  @override
  State<HotspotUserEditorScreen> createState() =>
      _HotspotUserEditorScreenState();
}

class _HotspotUserEditorScreenState extends State<HotspotUserEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController password;
  late final TextEditingController timeLimit;
  late final TextEditingController dataLimit;
  late final TextEditingController comment;

  Map<String, String> current = {};
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
  HotspotProfileConfig? profileConfig;

  bool get expired => current['limit-uptime'] == '1s';

  @override
  void initState() {
    super.initState();
    current = Map<String, String>.from(widget.user);
    name = TextEditingController(text: current['name'] ?? '');
    password = TextEditingController(text: current['password'] ?? '');
    timeLimit = TextEditingController(
      text: expired ? '' : (current['limit-uptime'] ?? ''),
    );
    comment = TextEditingController(text: current['comment'] ?? '');

    profile = current['profile'] ?? '';
    server = (current['server'] ?? '').isEmpty ? 'all' : current['server']!;
    enabled = current['disabled'] != 'true' && current['disabled'] != 'yes';

    final bytes = int.tryParse(current['limit-bytes-total'] ?? '') ?? 0;
    if (bytes > 0 && bytes % 1073741824 == 0) {
      unit = 'GB';
      dataLimit = TextEditingController(text: '${bytes ~/ 1073741824}');
    } else if (bytes > 0) {
      unit = 'MB';
      dataLimit = TextEditingController(
        text: (bytes / 1048576).toStringAsFixed(bytes % 1048576 == 0 ? 0 : 2),
      );
    } else {
      dataLimit = TextEditingController();
    }

    load();
  }

  Future<void> load() async {
    try {
      final values = await Future.wait([
        widget.service.hotspotProfiles(),
        widget.service.hotspotServers(),
      ]);
      profiles = values[0];
      servers = values[1];
      _resolveProfile();
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  void _resolveProfile() {
    Map<String, String>? row;
    for (final item in profiles) {
      if (item['name'] == profile) {
        row = item;
        break;
      }
    }
    profileConfig = row == null ? null : HotspotProfileConfig.fromRouterOs(row);
  }

  int _bytes() {
    final value =
        double.tryParse(dataLimit.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0) return 0;
    return (value * (unit == 'GB' ? 1073741824 : 1048576)).round();
  }

  String _comment() {
    final value = comment.text.trim();
    if (value.isEmpty ||
        value.startsWith('vc-') ||
        value.startsWith('up-') ||
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) {
      return value;
    }
    final mode = name.text.trim() == password.text ? 'vc-' : 'up-';
    return '$mode$value';
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      _msg('Le username est obligatoire.');
      return;
    }

    setState(() => saving = true);
    try {
      await widget.service.updateHotspotUser(
        id: current['.id']!,
        server: server,
        name: name.text.trim(),
        password: password.text,
        profile: profile,
        enabled: enabled,
        timeLimit: timeLimit.text,
        dataLimitBytes: _bytes(),
        comment: _comment(),
      );
      current = await widget.service.hotspotUserById(current['.id']!);
      _resolveProfile();
      if (mounted) {
        setState(() => saving = false);
        _msg('Utilisateur enregistré.');
      }
    } catch (e) {
      if (mounted) setState(() => saving = false);
      _msg('$e');
    }
  }

  Future<void> reset() async {
    if (!await _confirm(
      'Reset RootMikroManager',
      'Remettre limit-uptime à 0, effacer le commentaire, '
          'réinitialiser les compteurs et supprimer le scheduler '
          'individuel ?',
    ))
      return;

    try {
      await widget.service.resetRootMikroManagerHotspotUser(current);
      current = await widget.service.hotspotUserById(current['.id']!);
      timeLimit.text = '';
      comment.text = '';
      if (mounted) setState(() {});
      _msg('Utilisateur réinitialisé.');
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> remove() async {
    if (!await _confirm(
      'Supprimer utilisateur',
      'Supprimer ${current['name'] ?? 'cet utilisateur'} et '
          'son scheduler individuel éventuel ?',
    ))
      return;

    try {
      await widget.service.removeHotspotUserAndScheduler(current);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _msg('$e');
    }
  }

  Future<void> printVoucher(VoucherPrintLayout layout) async {
    final meta = profileConfig;
    final settings = await VoucherTemplateSettings.load();
    if (!mounted) return;
    AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: [
          {
            'username': name.text.trim(),
            'password': password.text,
            'profile': profile,
            'validity': meta?.validity ?? '',
            'price': meta?.price ?? '0',
            'selling-price': meta?.sellingPrice ?? '0',
          },
        ],
        layout: layout,
        templateSettings: settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(expired ? 'Utilisateur expiré' : 'Modifier utilisateur'),
      actions: [
        IconButton(
          tooltip: 'Enregistrer',
          onPressed: saving ? null : save,
          icon: const Icon(Icons.save_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'print') {
              printVoucher(VoucherPrintLayout.standard);
            } else if (value == 'qr') {
              printVoucher(VoucherPrintLayout.qr);
            } else if (value == 'small') {
              printVoucher(VoucherPrintLayout.small);
            } else if (value == 'reset') {
              reset();
            } else if (value == 'delete') {
              remove();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'print', child: Text('Print Default')),
            const PopupMenuItem(value: 'qr', child: Text('Print QR')),
            const PopupMenuItem(value: 'small', child: Text('Print Small')),
            if (expired)
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset RootMikroManager'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 820;
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _form()),
                        const SizedBox(width: 12),
                        Expanded(child: _infoCard()),
                      ],
                    )
                  else ...[
                    _form(),
                    const SizedBox(height: 12),
                    _infoCard(),
                  ],
                ],
              );
            },
          ),
  );

  Widget _form() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enabled'),
            value: enabled,
            onChanged: saving ? null : (v) => setState(() => enabled = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _serverValue(),
            decoration: const InputDecoration(labelText: 'Server'),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('all')),
              ...servers.map(
                (r) => DropdownMenuItem(
                  value: r['name'] ?? '',
                  child: Text(r['name'] ?? '—'),
                ),
              ),
            ],
            onChanged: saving
                ? null
                : (v) => setState(() => server = v ?? 'all'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: name,
            enabled: !saving,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            enabled: !saving,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPassword = !showPassword),
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _profileValue(),
            decoration: const InputDecoration(labelText: 'Profile'),
            items: profiles
                .map(
                  (r) => DropdownMenuItem(
                    value: r['name'] ?? '',
                    child: Text(r['name'] ?? '—'),
                  ),
                )
                .toList(),
            onChanged: saving
                ? null
                : (v) => setState(() {
                    profile = v ?? profile;
                    _resolveProfile();
                  }),
          ),
          const SizedBox(height: 10),
          _readOnly('MAC Address', current['mac-address']),
          const SizedBox(height: 10),
          _readOnly('Uptime', current['uptime']),
          const SizedBox(height: 10),
          _readOnly(
            'Bytes In / Out',
            '${_formatBytes(current['bytes-in'])} / '
                '${_formatBytes(current['bytes-out'])}',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: timeLimit,
            enabled: !saving,
            decoration: const InputDecoration(labelText: 'Time Limit'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dataLimit,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Data Limit'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(value: 'MB', child: Text('MB')),
                    DropdownMenuItem(value: 'GB', child: Text('GB')),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => setState(() => unit = v ?? 'MB'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: comment,
            enabled: !saving,
            decoration: const InputDecoration(labelText: 'Commentaire'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
    ),
  );

  Widget _infoCard() {
    final meta = profileConfig;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations voucher',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _info('Mode', name.text == password.text ? 'vc' : 'up'),
            _info('Validity', meta?.validity ?? '—'),
            _info('Price', meta?.price ?? '0'),
            _info('Selling Price', meta?.sellingPrice ?? '0'),
            _info('Lock User', meta?.lockUser == true ? 'Enable' : 'Disable'),
            _info(
              'État',
              expired
                  ? 'Expired'
                  : enabled
                  ? 'Enabled'
                  : 'Disabled',
            ),
            if (expired) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset RootMikroManager'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => printVoucher(VoucherPrintLayout.standard),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Default'),
            ),
            OutlinedButton.icon(
              onPressed: () => printVoucher(VoucherPrintLayout.qr),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Print QR'),
            ),
            OutlinedButton.icon(
              onPressed: () => printVoucher(VoucherPrintLayout.small),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Print Small'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnly(String label, String? value) => TextFormField(
    initialValue: value ?? '',
    enabled: false,
    decoration: InputDecoration(labelText: label),
  );

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ],
    ),
  );

  String _profileValue() {
    if (profiles.any((r) => r['name'] == profile)) return profile;
    return profiles.isEmpty ? '' : profiles.first['name'] ?? '';
  }

  String _serverValue() {
    if (server == 'all') return 'all';
    return servers.any((r) => r['name'] == server) ? server : 'all';
  }

  String _formatBytes(String? raw) {
    var value = (int.tryParse(raw ?? '') ?? 0).toDouble();
    if (value <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} '
        '${units[index]}';
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    timeLimit.dispose();
    dataLimit.dispose();
    comment.dispose();
    super.dispose();
  }
}
