import 'package:flutter/material.dart';
import '../../core/navigation/router.dart';
import '../../core/navigation/routes.dart';
import '../../core/routeros/routeros_service.dart';

class HotspotExpiryCleanupHubScreen extends StatelessWidget {
  final RouterOsService service;
  const HotspotExpiryCleanupHubScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Expiration & Cookies Hotspot')),
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Règle RootMikroManager : lorsqu’un ticket expire, ses '
              'cookies Hotspot sont supprimés et sa session active est '
              'coupée afin que le client puisse revoir le portail de connexion.',
            ),
          ),
        ),
        _button(
          context,
          'Résumé',
          'Tickets expirés, cookies obsolètes et sessions',
          Icons.dashboard_outlined,
          AppRoutes.hotspotExpirySummary,
        ),
        _button(
          context,
          'Aperçu',
          'Voir ce qui sera nettoyé avant action',
          Icons.preview_outlined,
          AppRoutes.hotspotExpiryPreview,
        ),
        _button(
          context,
          'Nettoyage',
          'Cookies → sessions actives → tickets expirés',
          Icons.cleaning_services_outlined,
          AppRoutes.hotspotExpiryCleanup,
        ),
        _button(
          context,
          'Audit cookies expirés',
          'Cookies encore liés à des tickets expirés',
          Icons.cookie_outlined,
          AppRoutes.hotspotCookieExpiryAudit,
        ),
        _button(
          context,
          'Audit login-by',
          'Profils utilisant la reconnexion par cookie',
          Icons.login_outlined,
          AppRoutes.hotspotCookieLoginAudit,
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String routeName,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FilledButton.tonalIcon(
      onPressed: () => AppRouter.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
