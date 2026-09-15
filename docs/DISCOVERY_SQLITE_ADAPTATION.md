# Adaptation du cahier des charges — SQLite et routes conservés

Décision utilisateur : conserver SQLite, RouterModel, les identifiants locaux
et toutes les routes existantes. Ne pas migrer vers Hive ni rétrograder GoRouter.

## Première passe de fiabilisation

- Socket fermé après timeout : une réponse tardive ne peut pas contaminer la
  commande suivante. Les erreurs `!trap` sont drainées jusqu'à `!done`.
- Une commande en attente est annulée si le transport a changé entre-temps.
- Session active : contrôle de lecture toutes les 30 secondes, puis reconnexion
  avec délais 0/2/4/8 secondes, quatre essais maximum. Aucune écriture n'est rejouée.
- Refus d'authentification : arrêt des essais et état dédié.
- Conservation du choix de validation de certificat pendant la reconnexion.
- Test TCP interactif limité à 3 secondes et une tentative.
- Vérification des routeurs sauvegardés : vert uniquement après login et lecture
  de l'identité ; orange pour identifiants refusés ; rouge sinon.
- Enregistrement depuis la découverte : validation port/mot de passe et test API
  réussi requis. Toute édition invalide le test. Le test utilise sa propre session.
- Nouvelle sauvegarde SQLite : garde transactionnelle MAC/RoMON insensible à la
  casse. Les doublons existants ne sont ni fusionnés ni supprimés automatiquement.

## Limites restantes du cahier des charges

- Dépendances intégrées : mikrotik_mndp 0.0.4 (décodeur MNDP réel sur les
  paquets natifs Android), network_info_plus 4.1.0+1 (IPv4 Wi-Fi),
  router_os_client 2.0.1 (monitoring/streaming, TLS configurable).
  Le client API principal reste interne ; son remplacement global reste à faire.
  La version network_info_plus 5.x est incompatible avec mikrotik_mndp 0.0.4.
- Les statuts des routeurs sont encore temporaires dans l'écran : persistance et
  rafraîchissement configurable des 60 secondes restent à implémenter.
- Redécouverte : actualisation automatique de l'IP/lastSeen sans écraser les
  identifiants, ainsi que normalisation/migration des anciennes MAC restent à faire.
- Migration des noms d'utilisateur vers le stockage sécurisé, délai d'inactivité
  de 15 minutes et gestion complète du cycle de vie de l'application restent à faire.
- Le catalogue complet WebP, le plafond de cache 50 Mo et la maintenance mensuelle
  ne sont pas encore implémentés. Ne pas construire des URL CDN supposées.
- MNDP exige un domaine L2 effectivement accessible au téléphone ; WireGuard/BTH
  ne suffisent pas seuls. Ne pas déduire le VPN d'un préfixe IP.

## Validation

Les tests de protocole utilisent uniquement un serveur simulé sur 127.0.0.1,
jamais un routeur réel. Les essais Wi-Fi/VPN/coupure réseau et les mesures de
performance sur matériel nécessitent la validation préalable de l'utilisateur.
