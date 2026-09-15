import 'package:flutter/material.dart';
import '../../core/routeros/routeros_service.dart';

class VpnCapabilityStatusScreen extends StatefulWidget {
  final RouterOsService service;
  const VpnCapabilityStatusScreen({super.key, required this.service});
  @override
  State<VpnCapabilityStatusScreen> createState() => _State();
}

class _State extends State<VpnCapabilityStatusScreen> {
  bool loading = true;
  Map<String, String> resource = {};
  List<Map<String, String>> wg = [], wp = [], zt = [], bth = [];
  Object? wgError, ztError, bthError;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    resource = await widget.service.resource();
    try {
      wg = await widget.service.wireGuardInterfaces();
      wp = await widget.service.wireGuardPeers();
      wgError = null;
    } catch (e) {
      wgError = e;
    }
    try {
      zt = await widget.service.zeroTierInterfaces();
      ztError = null;
    } catch (e) {
      ztError = e;
    }
    try {
      bth = await widget.service.backToHomeUsers();
      bthError = null;
    } catch (e) {
      bthError = e;
    }
    if (mounted) setState(() => loading = false);
  }

  Widget status(String t, bool ok, String d) => Card(
    child: ListTile(
      leading: Icon(ok ? Icons.check_circle_outline : Icons.info_outline),
      title: Text(t),
      subtitle: Text(d),
    ),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Compatibilité VPN'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  title: const Text('RouterOS'),
                  trailing: Text(resource['version'] ?? '—'),
                ),
              ),
              status(
                'WireGuard',
                wgError == null,
                wgError == null
                    ? '${wg.length} interface(s) • ${wp.length} peer(s)'
                    : 'Menu non disponible ou inaccessible.',
              ),
              status(
                'ZeroTier',
                ztError == null,
                ztError == null
                    ? '${zt.length} interface(s) détectée(s)'
                    : 'Package/menu non disponible ou inaccessible.',
              ),
              status(
                'Back To Home',
                bthError == null,
                bthError == null
                    ? '${bth.length} utilisateur(s) visible(s)'
                    : 'Fonction non disponible ou accès insuffisant.',
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'L’absence d’un menu n’est pas traitée comme une erreur fatale : RootMikroManager adapte les fonctions aux capacités du routeur.',
                  ),
                ),
              ),
            ],
          ),
  );
}
