# Gestionnaire — consolidation 09

Cette passe vise la préparation à la fermeture de la branche gestionnaire.

## Hotspot / profils
- validation centralisée avant création/modification d'un profil ;
- contrôle nom, doublon, shared-users, validité, grace period, prix et rate limit ;
- suppression d'un profil bloquée tant qu'il est référencé par des tickets ou sessions ;
- audit de sécurité des profils et de leurs schedulers ;
- correction d'un en-tête de profils susceptible de provoquer un overflow sur petits écrans.

## Vouchers
- limite de génération uniformisée à 99 tickets par lot ;
- résultat structuré de la dernière génération ;
- en cas d'échec partiel, les tickets déjà créés restent identifiables et ne sont pas recréés.

## PPP
- validation d'un profil avant sauvegarde ;
- contrôle doublon, pool/adresse, rate limit et timeouts.

## Rapports / préparation
- audit non destructif de conservation des ventes ;
- écran global de préparation gestionnaire : Hotspot, moniteurs de validité,
  devise, QR, impression, PPP et registre des ventes.

## Rappels
- tickets et profils Hotspot restent strictement séparés ;
- une réimpression n'est pas une vente ;
- une suppression de ticket nettoie cookie, session active et scheduler avant le ticket.
