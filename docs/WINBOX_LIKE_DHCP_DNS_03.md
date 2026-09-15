# WinBox-like — DHCP + DNS, lot 03

## DHCP

Durcissements apportés :

- validation IPv4/MAC des baux statiques ;
- validation du Lease Time RouterOS ;
- validation réseau CIDR, gateway, DNS/NTP/WINS ;
- détection d’un second serveur DHCP actif sur la même interface ;
- avertissement `static-only` et DHCP Relay ;
- confirmation avant suppression des serveurs, réseaux et baux statiques ;
- les baux dynamiques restent protégés de l’édition/suppression directe.

## DNS

Durcissements apportés :

- validation des serveurs DNS IPv4/IPv6 et suffixe `@vrf` ;
- validation DoH HTTP/HTTPS ;
- validation des limites de requêtes et de la taille UDP ;
- avertissement de sécurité lorsque `allow-remote-requests=yes` ;
- avertissement DoH si la vérification du certificat est désactivée ;
- validation des URLs DNS Adlist et confirmation avant suppression ;
- confirmation avant suppression des entrées DNS statiques.

## DNS statique

L’éditeur couvre maintenant explicitement :

- A ;
- AAAA ;
- CNAME ;
- FWD ;
- MX ;
- NS ;
- NXDOMAIN ;
- SRV ;
- TXT.

Les champs spécifiques (`cname`, `forward-to`, `mx-exchange`,
`mx-preference`, `ns`, `srv-target`, `srv-port`, `text`) sont envoyés selon
le type choisi au lieu de réutiliser incorrectement le champ `address`.

Les FWD acceptent une adresse de serveur DNS ou le nom d’un forwarder
RouterOS.

## Sécurité

Lorsque le routeur devient résolveur DNS pour les clients,
RootMikroManager rappelle explicitement que TCP/UDP 53 doit être limité aux
réseaux de confiance par le firewall.

## Tests ajoutés

- `test/dhcp_dns_validator_test.dart`
- `test/dhcp_dns_safety_analyzer_test.dart`

## Audit statique

- imports relatifs manquants : 0 ;
- `MaterialPageRoute` : 0 ;
- `pushPage()` : 0 ;
- `pushModule()` : 0 ;
- ancienne marque : 0 ;
- `FloatingActionButton` : 0 ;
- délimiteurs des fichiers modifiés : OK.

Le SDK Flutter/Dart n’est pas disponible dans l’environnement d’exécution ;
les tests et `flutter analyze` ne sont donc pas revendiqués comme exécutés.
