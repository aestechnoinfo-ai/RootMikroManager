import 'package:flutter/material.dart';

class InternetSharingHelpScreen extends StatelessWidget {
  const InternetSharingHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Anti-partage Internet')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Cette fonction crée une règle IPv4 Mangle '
              'chain=postrouting, action=change-ttl, '
              'new-ttl=set:1 sur l’interface choisie. '
              'Le TTL reste modifiable dans RootMikroManager.',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'RootMikroManager identifie ses propres règles grâce '
              'à un commentaire interne. Les autres règles Mangle '
              'du routeur ne sont donc pas activées, désactivées ou '
              'supprimées par cette liste.',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Le comportement dépend du chemin réseau et du client. '
              'Cette fonction agit sur IPv4 TTL et ne constitue pas '
              'à elle seule une politique universelle pour IPv6.',
            ),
          ),
        ),
      ],
    ),
  );
}
