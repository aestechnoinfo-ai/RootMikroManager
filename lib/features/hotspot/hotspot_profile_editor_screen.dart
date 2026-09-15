import 'package:flutter/material.dart';

import '../../core/routeros/routeros_service.dart';
import 'hotspot_profile_config.dart';
import 'mikhmon_time_parser.dart';
import 'hotspot_profile_validator.dart';

class HotspotProfileEditorScreen extends StatefulWidget {
  final RouterOsService service;
  final Map<String, String>? profile;

  const HotspotProfileEditorScreen({
    super.key,
    required this.service,
    this.profile,
  });

  @override
  State<HotspotProfileEditorScreen> createState() =>
      _HotspotProfileEditorScreenState();
}

class _HotspotProfileEditorScreenState
    extends State<HotspotProfileEditorScreen> {
  late final TextEditingController name;
  late final TextEditingController sharedUsers;
  late final TextEditingController rateLimit;
  late final TextEditingController validity;
  late final TextEditingController gracePeriod;
  late final TextEditingController price;
  late final TextEditingController sellingPrice;

  List<Map<String, String>> pools = [];
  List<Map<String, String>> queues = [];
  List<Map<String, String>> existingProfiles = [];

  String addressPool = 'none';
  String parentQueue = 'none';
  HotspotExpirationMode expirationMode = HotspotExpirationMode.none;
  bool lockUser = false;
  bool loading = true;
  bool saving = false;
  String? error;

  late final HotspotProfileConfig initial;

  @override
  void initState() {
    super.initState();

    initial = widget.profile == null
        ? const HotspotProfileConfig(name: '')
        : HotspotProfileConfig.fromRouterOs(widget.profile!);

    name = TextEditingController(text: initial.name);
    sharedUsers = TextEditingController(text: initial.sharedUsers.toString());
    rateLimit = TextEditingController(text: initial.rateLimit);
    validity = TextEditingController(text: initial.validity);
    gracePeriod = TextEditingController(text: initial.gracePeriod);
    price = TextEditingController(
      text: initial.price == '0' ? '' : initial.price,
    );
    sellingPrice = TextEditingController(
      text: initial.sellingPrice == '0' ? '' : initial.sellingPrice,
    );

    addressPool = initial.addressPool;
    parentQueue = initial.parentQueue;
    expirationMode = initial.expirationMode;
    lockUser = initial.lockUser;

    loadChoices();
  }

  Future<void> loadChoices() async {
    try {
      final values = await Future.wait([
        widget.service.ipPools(),
        widget.service.staticSimpleQueues(),
        widget.service.hotspotProfiles(),
      ]);
      pools = values[0];
      queues = values[1];
      existingProfiles = values[2];
      error = null;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final normalizedName = name.text.trim().replaceAll(RegExp(r'\s+'), '-');

    if (normalizedName.isEmpty) {
      _message('Le nom du profil est obligatoire.');
      return;
    }

    final shared = int.tryParse(sharedUsers.text.trim());
    if (shared == null || shared < 1) {
      _message('Shared Users doit être supérieur ou égal à 1.');
      return;
    }

    if (expirationMode != HotspotExpirationMode.none &&
        validity.text.trim().isEmpty) {
      _message(
        'Validity est obligatoire quand un mode d’expiration est actif.',
      );
      return;
    }

    String normalizedValidity = validity.text.trim();
    String normalizedGracePeriod = gracePeriod.text.trim();
    try {
      if (expirationMode != HotspotExpirationMode.none) {
        normalizedValidity = MikhmonTimeParser.normalize(normalizedValidity);
      }
      normalizedGracePeriod = MikhmonTimeParser.normalize(
        normalizedGracePeriod.isEmpty ? '5m' : normalizedGracePeriod,
      );
    } on FormatException catch (error) {
      _message(error.message);
      return;
    }

    setState(() => saving = true);

    try {
      final config = HotspotProfileConfig(
        id: initial.id,
        originalName: initial.originalName,
        name: normalizedName,
        addressPool: addressPool,
        sharedUsers: shared,
        rateLimit: rateLimit.text.trim(),
        expirationMode: expirationMode,
        validity: normalizedValidity,
        gracePeriod: normalizedGracePeriod,
        price: price.text.trim().isEmpty ? '0' : price.text.trim(),
        sellingPrice: sellingPrice.text.trim().isEmpty
            ? '0'
            : sellingPrice.text.trim(),
        lockUser: lockUser,
        parentQueue: parentQueue,
      );

      final issues = const HotspotProfileValidator().validate(
        config,
        existingProfiles: existingProfiles,
      );
      if (issues.isNotEmpty) {
        _message(issues.join('\n'));
        if (mounted) setState(() => saving = false);
        return;
      }

      await widget.service.saveRootMikroManagerHotspotProfile(config);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _message('$e');
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.profile == null
            ? 'Nouveau profil Hotspot'
            : 'Modifier le profil',
      ),
      actions: [
        TextButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? _buildError()
        : LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final form = _buildForm();
              final info = _buildInfo();

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: form),
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    )
                  else ...[
                    form,
                    const SizedBox(height: 12),
                    info,
                  ],
                ],
              );
            },
          ),
  );

  Widget _buildForm() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: name,
            enabled: !saving,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nom',
              helperText:
                  'Les espaces sont automatiquement remplacés par des tirets.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _poolValue(),
            decoration: const InputDecoration(labelText: 'Address Pool'),
            items: [
              const DropdownMenuItem(value: 'none', child: Text('none')),
              ...pools.map(
                (row) => DropdownMenuItem(
                  value: row['name'] ?? '',
                  child: Text(row['name'] ?? '—'),
                ),
              ),
            ],
            onChanged: saving
                ? null
                : (value) => setState(() => addressPool = value ?? 'none'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: sharedUsers,
            enabled: !saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Shared Users'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: rateLimit,
            enabled: !saving,
            decoration: const InputDecoration(
              labelText: 'Rate Limit [up/down]',
              hintText: 'Exemple : 512k/1M',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<HotspotExpirationMode>(
            initialValue: expirationMode,
            decoration: const InputDecoration(labelText: 'Expired Mode'),
            items: HotspotExpirationMode.values
                .map(
                  (mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
            onChanged: saving
                ? null
                : (value) => setState(
                    () => expirationMode = value ?? HotspotExpirationMode.none,
                  ),
          ),
          if (expirationMode != HotspotExpirationMode.none) ...[
            const SizedBox(height: 10),
            TextField(
              controller: validity,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Validity',
                hintText: 'Exemple : 1d, 12h, 30d',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gracePeriod,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Grace Period',
                hintText: '5m',
                helperText: 'Format libre : 30min, 24h, 1jour, 4 semaines…',
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: price,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: sellingPrice,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Selling Price'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock User'),
            subtitle: const Text(
              'Verrouille le voucher sur la première adresse MAC '
              'utilisée, comme RootMikroManager.',
            ),
            value: lockUser,
            onChanged: saving
                ? null
                : (value) => setState(() => lockUser = value),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _queueValue(),
            decoration: const InputDecoration(labelText: 'Parent Queue'),
            items: [
              const DropdownMenuItem(value: 'none', child: Text('none')),
              ...queues.map(
                (row) => DropdownMenuItem(
                  value: row['name'] ?? '',
                  child: Text(row['name'] ?? '—'),
                ),
              ),
            ],
            onChanged: saving
                ? null
                : (value) => setState(() => parentQueue = value ?? 'none'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Enregistrement…' : 'Enregistrer le profil'),
          ),
        ],
      ),
    ),
  );

  Widget _buildInfo() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compatibilité RootMikroManager',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            'Le profil RouterOS est créé avec address-pool, rate-limit, '
            'shared-users, status-autorefresh=1m, on-login et '
            'parent-queue.',
          ),
          const SizedBox(height: 10),
          const Text(
            'Remove / Notice génèrent aussi un scheduler de surveillance '
            'du profil. Remove & Record / Notice & Record ajoutent la '
            'journalisation compatible avec la logique RootMikroManager.',
          ),
          const SizedBox(height: 10),
          const Text(
            'Grace Period est affiché pour préserver le formulaire '
            'officiel fourni. Son comportement n’est pas inventé lorsque '
            'la version PHP ne l’utilise pas.',
          ),
        ],
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loadChoices,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );

  String _poolValue() {
    if (addressPool == 'none') return 'none';
    return pools.any((row) => row['name'] == addressPool)
        ? addressPool
        : 'none';
  }

  String _queueValue() {
    if (parentQueue == 'none') return 'none';
    return queues.any((row) => row['name'] == parentQueue)
        ? parentQueue
        : 'none';
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    name.dispose();
    sharedUsers.dispose();
    rateLimit.dispose();
    validity.dispose();
    gracePeriod.dispose();
    price.dispose();
    sellingPrice.dispose();
    super.dispose();
  }
}
