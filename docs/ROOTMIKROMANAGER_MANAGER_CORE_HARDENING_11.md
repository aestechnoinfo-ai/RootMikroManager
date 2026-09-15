# Gestionnaire — consolidation 11

Passe transversale de pré-gel fonctionnel.

## Impression et QR
- politique centralisée de densité : A4 jusqu'à 50, thermique jusqu'à 2 ;
- QR recommandé jusqu'à 30 et automatiquement masqué à partir de 40 ;
- construction de l'URL QR via Uri et validation du portail.

## Hotspot
- audit transversal tickets / actifs / cookies / schedulers ;
- détection des sessions et cookies orphelins ;
- règle de cycle de vie maintenue : cookie, actif, scheduler, ticket.

## Rapports
- Live Report réutilise le parseur de dates central ;
- audit qualité des ventes : dates, lignes invalides, prix, profils, doublons ;
- matrice explicite entre validation statique et validation matérielle.

## PPP
- synthèse sécurité sans exposition des mots de passe.

## Statut
La branche gestionnaire est proche du gel fonctionnel, mais les tests réels
RouterOS, portail captif, QR, impression et compilation restent nécessaires
avant toute déclaration de compatibilité finale.
