import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/navigation/navigation_payloads.dart';

import '../../core/database/app_database.dart';
import '../../core/routeros/router_session.dart';
import '../../core/routeros/routeros_service.dart';
import '../../core/settings/app_currency_settings.dart';
import 'rootmikromanager_profile_metadata.dart';
import 'rootmikromanager_voucher_generator.dart';
import 'voucher_generation_validator.dart';
import 'voucher_generation_batch_result.dart';
import 'voucher_batch_validator.dart';
import 'voucher_print_layout.dart';
import 'voucher_template_settings.dart';
import 'hotspot_name_resolver.dart';

class VoucherGeneratorScreen extends StatefulWidget {
  final RouterOsService service;
  final int? routerId;

  const VoucherGeneratorScreen({
    super.key,
    required this.service,
    this.routerId,
  });

  @override
  State<VoucherGeneratorScreen> createState() => _VoucherGeneratorScreenState();
}

class _VoucherGeneratorScreenState extends State<VoucherGeneratorScreen> {
  final quantity = TextEditingController(text: '1');
  final prefix = TextEditingController();
  final suffix = TextEditingController();
  final timeLimit = TextEditingController();
  final dataLimit = TextEditingController();
  final comment = TextEditingController();
  final hotspotName = TextEditingController();
  final generator = RootMikroManagerVoucherGenerator();
  final validator = const VoucherBatchValidator();

  List<Map<String, String>> profiles = [];
  List<Map<String, String>> servers = [];
  Set<String> existingUsers = {};

  String selectedServer = 'all';
  String? selectedProfile;
  String userMode = 'up';
  int userLength = 4;
  String characterMode = 'lower';
  int dataMultiplier = 1048576;
  String _currency = '';
  bool hotspotNameDetected = false;

  bool busy = false;
  bool loadingProfiles = true;
  int generatedCount = 0;
  List<Map<String, String>> generated = [];
  String? error;
  VoucherGenerationBatchResult? lastBatchResult;

  Map<String, String>? get profileRow {
    final name = selectedProfile;
    if (name == null) return null;
    for (final row in profiles) {
      if (row['name'] == name) return row;
    }
    return null;
  }

  RootMikroManagerProfileMetadata get metadata =>
      RootMikroManagerProfileMetadata.fromProfile(profileRow ?? const {});

  @override
  void initState() {
    super.initState();
    loadReferences();
  }

  bool get _belongsToActiveRouter =>
      widget.routerId == null ||
      widget.routerId == RouterSession.instance.activeRouter?.id;

  Future<void> loadReferences() async {
    if (mounted) setState(() => loadingProfiles = true);
    try {
      final rows = await widget.service.hotspotProfiles();
      if (!_belongsToActiveRouter) return;
      final byName = <String, Map<String, String>>{};
      for (final row in rows) {
        final name = (row['name'] ?? '').trim();
        if (name.isNotEmpty) byName[name] = {...row, 'name': name};
      }
      profiles = byName.values.toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
      final current = selectedProfile;
      selectedProfile = current != null && byName.containsKey(current)
          ? current
          : (profiles.isEmpty ? null : profiles.first['name']);
      error = profiles.isEmpty
          ? 'Aucun profil Hotspot retourné par le routeur.'
          : null;
    } catch (e) {
      profiles = [];
      selectedProfile = null;
      error = 'Impossible de charger les profils Hotspot : $e';
    } finally {
      loadingProfiles = false;
      if (mounted) setState(() {});
    }

    // Ces références ne doivent jamais bloquer l'activation du sélecteur de
    // profil : elles peuvent être lentes ou indisponibles indépendamment.
    try {
      final rows = await widget.service.hotspotServers();
      if (!_belongsToActiveRouter) return;
      servers = rows;
      if (mounted) setState(() {});
    } catch (_) {}
    try {
      final rows = await widget.service.hotspotUsers();
      if (!_belongsToActiveRouter) return;
      existingUsers = rows
          .map((row) => row['name'] ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
    } catch (_) {}
    try {
      _currency = await AppCurrencySettings.load();
    } catch (_) {}
    await _loadHotspotName();
    if (mounted) setState(() {});
  }

  Future<void> _loadHotspotName() async {
    final settings = await VoucherTemplateSettings.load();
    List<Map<String, String>> interfaces = const [];
    List<Map<String, String>> configurations = const [];
    try {
      interfaces = await widget.service.wirelessInterfacesAll();
    } catch (_) {}
    try {
      configurations = await widget.service.wifiConfigurations();
    } catch (_) {}
    final resolved = const HotspotNameResolver().resolve(
      interfaces,
      configurations: configurations,
      fallback: settings.hotspotName,
    );
    hotspotName.text = resolved;
    hotspotNameDetected = [...interfaces, ...configurations].any(
      (row) => [
        row['ssid'],
        row['configuration.ssid'],
        row['actual-configuration.ssid'],
      ].any((value) => (value ?? '').trim() == resolved),
    );
  }

  Future<void> generate() async {
    if (widget.routerId == null ||
        widget.routerId != RouterSession.instance.activeRouter?.id) {
      _message('Session routeur changée. Rouvrez la page Vouchers.');
      return;
    }
    final profile = selectedProfile;
    if (profile == null || profile.isEmpty) {
      _message('Sélectionnez un profil Hotspot.');
      return;
    }
    final issues = validator.validate(
      quantityRaw: quantity.text,
      prefix: prefix.text,
      suffix: suffix.text,
      timeLimit: timeLimit.text,
      dataLimit: dataLimit.text,
      profile: profile,
    );
    if (issues.isNotEmpty) {
      _message(issues.first);
      return;
    }

    // Rafraîchit les usernames avant chaque génération afin de réduire le risque
    // de collision si des tickets ont été créés par une autre session.
    existingUsers = (await widget.service.hotspotUsers())
        .map((row) => row['name'] ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    final qty = (int.tryParse(quantity.text) ?? 1).clamp(1, 560).toInt();
    final safePrefix = prefix.text.trim();
    final safeSuffix = suffix.text.trim();
    if (safePrefix.length > 6) {
      _message('Le préfixe est limité à 6 caractères.');
      return;
    }
    if (safeSuffix.length > 6) {
      _message('Le suffixe est limité à 6 caractères.');
      return;
    }

    final validation = VoucherGenerationValidator.validate(
      quantity: qty,
      length: userLength,
      characterMode: characterMode,
      prefix: safePrefix,
      suffix: safeSuffix,
      profile: profile,
      server: selectedServer,
      timeLimit: timeLimit.text,
      dataLimit: dataLimit.text,
    );
    if (validation.isNotEmpty) {
      _message(validation.join('\n'));
      return;
    }

    final limitUptime = timeLimit.text.trim().isEmpty
        ? '0'
        : timeLimit.text.trim();
    final numericData = int.tryParse(dataLimit.text.trim()) ?? 0;
    final limitBytes = numericData <= 0 ? 0 : numericData * dataMultiplier;
    final generatedComment = _rootmikromanagerComment(comment.text.trim());
    final meta = metadata;

    setState(() {
      busy = true;
      generated = [];
      generatedCount = 0;
      error = null;
    });

    try {
      for (var i = 0; i < qty; i++) {
        final credential = _nextUniqueCredential(safePrefix, safeSuffix);

        await widget.service.add('/ip/hotspot/user', {
          'server': selectedServer,
          'name': credential.username,
          'password': credential.password,
          'profile': profile,
          'limit-uptime': limitUptime,
          'limit-bytes-total': '$limitBytes',
          'comment': generatedComment,
        });

        existingUsers.add(credential.username);

        final db = await AppDatabase.instance.db;
        await db.insert('voucher_history', {
          'router_id': widget.routerId,
          'username': credential.username,
          'password': credential.password,
          'profile': profile,
          'selling_price': metadata.sellingPrice,
          'validity': metadata.validity,
          'comment': generatedComment,
          'hotspot_name': hotspotName.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });

        generated.add({
          'username': credential.username,
          'password': credential.password,
          'profile': profile,
          'server': selectedServer,
          'mode': userMode,
          'validity': meta.validity,
          'price': meta.price,
          'selling-price': meta.sellingPrice,
          'lock-user': meta.lockUser,
          'limit-uptime': limitUptime,
          'limit-bytes-total': '$limitBytes',
          'comment': generatedComment,
          'hotspot-name': hotspotName.text.trim(),
        });
        generatedCount++;
        if (mounted) setState(() {});
      }

      lastBatchResult = VoucherGenerationBatchResult(
        requested: qty,
        generated: generatedCount,
      );

      await AppDatabase.instance.log(
        'voucher.batch.generated',
        routerId: widget.routerId,
        data: {
          'count': generatedCount,
          'profile': profile,
          'server': selectedServer,
          'mode': userMode,
          'character': characterMode,
        },
      );
    } catch (e) {
      error = '$e';
      lastBatchResult = VoucherGenerationBatchResult(
        requested: qty,
        generated: generatedCount,
        error: '$e',
      );
      _message('Arrêt après $generatedCount voucher(s) : $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  ({String username, String password}) _nextUniqueCredential(
    String prefixValue,
    String suffixValue,
  ) {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (userMode == 'vc') {
        final value = generator.voucher(
          prefix: prefixValue,
          suffix: suffixValue,
          length: userLength,
          characterMode: characterMode,
        );
        if (!existingUsers.contains(value)) {
          return (username: value, password: value);
        }
      } else {
        final value = generator.userPassword(
          prefix: prefixValue,
          suffix: suffixValue,
          length: userLength,
          characterMode: characterMode,
        );
        if (!existingUsers.contains(value.username)) return value;
      }
    }
    throw StateError(
      'Impossible de générer un identifiant unique après 50 essais.',
    );
  }

  String _rootmikromanagerComment(String additional) {
    final now = DateTime.now();
    final code = 100 + (now.microsecondsSinceEpoch % 900);
    String two(int value) => value.toString().padLeft(2, '0');
    final date = '${two(now.month)}.${two(now.day)}.${two(now.year % 100)}';
    final suffix = additional.isEmpty ? '' : '-$additional';
    return '$userMode-$code-$date$suffix';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final meta = metadata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer des vouchers'),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            onPressed: busy ? null : loadReferences,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Gestion avancée',
            onPressed: busy
                ? null
                : () =>
                      AppRouter.pushNamed(context, AppRoutes.voucherOperations),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: 'Historique',
            onPressed: () =>
                AppRouter.pushNamed(context, AppRoutes.voucherHistory),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(error!),
              ),
            ),
          _section('Génération', [
            TextField(
              controller: quantity,
              enabled: !busy,
              keyboardType: TextInputType.number,
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantité',
                helperText: 'De 1 à 560 tickets par lot',
                counterText: '',
              ),
            ),
            DropdownButtonFormField<String>(isExpanded: true, 
              value: selectedServer,
              decoration: const InputDecoration(labelText: 'Server'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('all')),
                ...servers
                    .map((row) => row['name'] ?? '')
                    .where((name) => name.isNotEmpty && name != 'all')
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    ),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() => selectedServer = v ?? 'all'),
            ),
            DropdownButtonFormField<String>(isExpanded: true, 
              value: userMode,
              decoration: const InputDecoration(labelText: 'User Mode'),
              items: const [
                DropdownMenuItem(
                  value: 'up',
                  child: Text('Username & Password'),
                ),
                DropdownMenuItem(
                  value: 'vc',
                  child: Text('Username = Password (Voucher)'),
                ),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      userMode = v ?? 'up';
                      if (userMode == 'up' && characterMode == 'num') {
                        characterMode = 'lower';
                      }
                    }),
            ),
            DropdownButtonFormField<int>(isExpanded: true, 
              value: userLength,
              decoration: const InputDecoration(labelText: 'User Length'),
              items: [
                for (var i = 3; i <= 8; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() => userLength = v ?? 4),
            ),
            TextField(
              controller: prefix,
              enabled: !busy,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Préfixe'),
            ),
            TextField(
              controller: suffix,
              enabled: !busy,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Suffixe',
                helperText:
                    'Concaténé directement après le code, sans séparateur automatique.',
              ),
            ),
            Text(
              'Format : préfixe + code + suffixe (aucun séparateur automatique)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            DropdownButtonFormField<String>(isExpanded: true, 
              value: characterMode,
              decoration: const InputDecoration(labelText: 'Character'),
              items: [
                const DropdownMenuItem(
                  value: 'lower',
                  child: Text('Random abcd'),
                ),
                const DropdownMenuItem(
                  value: 'upper',
                  child: Text('Random ABCD'),
                ),
                const DropdownMenuItem(
                  value: 'upplow',
                  child: Text('Random aBcD'),
                ),
                const DropdownMenuItem(
                  value: 'mix',
                  child: Text('Random 5ab2c34d'),
                ),
                const DropdownMenuItem(
                  value: 'mix1',
                  child: Text('Random 5AB2C34D'),
                ),
                const DropdownMenuItem(
                  value: 'mix2',
                  child: Text('Random 5aB2c34D'),
                ),
                if (userMode == 'vc')
                  const DropdownMenuItem(
                    value: 'num',
                    child: Text('Random 1234'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() => characterMode = v ?? 'lower'),
            ),
            DropdownButtonFormField<String>(isExpanded: true, 
              value: profiles.any((row) => row['name'] == selectedProfile)
                  ? selectedProfile
                  : null,
              decoration: InputDecoration(
                labelText: 'Profil Hotspot',
                helperText: loadingProfiles
                    ? 'Chargement des profils…'
                    : profiles.isEmpty
                    ? 'Aucun profil disponible — touchez Recharger.'
                    : '${profiles.length} profil(s) disponible(s)',
                suffixIcon: loadingProfiles
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Recharger les profils',
                        onPressed: busy ? null : loadReferences,
                        icon: const Icon(Icons.refresh),
                      ),
              ),
              items: profiles
                  .map(
                    (row) => DropdownMenuItem(
                      value: row['name'],
                      child: Text(row['name'] ?? '—'),
                    ),
                  )
                  .toList(),
              onChanged: busy || loadingProfiles || profiles.isEmpty
                  ? null
                  : (v) => setState(() => selectedProfile = v),
            ),
            TextField(
              controller: timeLimit,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Time Limit',
                hintText: 'Ex. 1h, 30m',
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _numberField(dataLimit, 'Data Limit')),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<int>(isExpanded: true, 
                    value: dataMultiplier,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    items: const [
                      DropdownMenuItem(value: 1048576, child: Text('MB')),
                      DropdownMenuItem(value: 1073741824, child: Text('GB')),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() => dataMultiplier = v ?? 1048576),
                  ),
                ),
              ],
            ),
            TextField(
              controller: comment,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Commentaire additionnel',
              ),
            ),
            TextField(
              controller: hotspotName,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: 'Nom du hotspot sur le ticket',
                helperText: hotspotNameDetected
                    ? 'SSID détecté automatiquement — modifiable pour ce lot.'
                    : 'Aucun SSID détecté — nom de secours modifiable.',
                suffixIcon: IconButton(
                  tooltip: 'Redétecter le SSID',
                  onPressed: busy ? null : _loadHotspotName,
                  icon: const Icon(Icons.wifi_find_outlined),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _profileInfo(meta),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : generate,
            icon: const Icon(Icons.confirmation_number_outlined),
            label: Text(busy ? 'Génération $generatedCount...' : 'Générer'),
          ),
          if (busy) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value:
                  generatedCount /
                  ((int.tryParse(quantity.text) ?? 1).clamp(1, 560).toInt()),
            ),
          ],
          if (generated.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Dernière génération : ${generated.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openPrint(VoucherPrintLayout.standard),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Default'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openPrint(VoucherPrintLayout.qr),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Print QR'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openPrint(VoucherPrintLayout.small),
                  icon: const Icon(Icons.view_compact_outlined),
                  label: const Text('Print Small'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openPrint(VoucherPrintLayout.mikhmonCode),
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Compact Code'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openPrint(VoucherPrintLayout.mikhmonCredentials),
                  icon: const Icon(Icons.password_outlined),
                  label: const Text('Compact ID + Pass'),
                ),
                if (lastBatchResult != null)
                  OutlinedButton.icon(
                    onPressed: () => AppRouter.pushNamed(
                      context,
                      AppRoutes.voucherGenerationResult,
                      extra: VoucherGenerationResultPayload(lastBatchResult!),
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Résultat du lot'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in generated)
              Card(
                child: ListTile(
                  title: Text(item['username'] ?? '—'),
                  subtitle: Text(
                    '${item['password'] ?? '—'} • ${item['profile'] ?? '—'} • ${item['server'] ?? 'all'}',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );

  Widget _profileInfo(RootMikroManagerProfileMetadata meta) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          Text('Validity: ${meta.validity.isEmpty ? '—' : meta.validity}'),
          Text(
            'Price: ${meta.price == '0' ? '—' : AppCurrencySettings.formatRaw(meta.price, _currency)}',
          ),
          Text(
            'Selling Price: ${meta.sellingPrice == '0' ? '—' : AppCurrencySettings.formatRaw(meta.sellingPrice, _currency)}',
          ),
          Text(
            'Lock User: ${meta.lockUser.isEmpty ? 'Disable' : meta.lockUser}',
          ),
        ],
      ),
    ),
  );

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        enabled: !busy,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      );

  Future<void> _openPrint(VoucherPrintLayout layout) async {
    final settings = await VoucherTemplateSettings.load();
    if (!mounted) return;
    await AppRouter.pushNamed(
      context,
      AppRoutes.voucherPrint,
      extra: VoucherPrintPayload(
        vouchers: generated,
        layout: layout,
        templateSettings: settings,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      quantity,
      prefix,
      suffix,
      timeLimit,
      dataLimit,
      comment,
      hotspotName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
