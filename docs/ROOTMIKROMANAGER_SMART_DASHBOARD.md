# Tableau de bord intelligent RootMikroManager

L'accueil principal devient un tableau de bord temps réel.

## Informations routeur
- Identity / nom ;
- IP du routeur actif ;
- board-name ;
- modèle RouterBOARD ;
- version RouterOS ;
- architecture ;
- date et heure système ;
- fuseau ;
- uptime ;
- CPU.

## Santé système
CPU, RAM et stockage utilisent des jauges avec seuils configurables :
- vert : état normal ;
- orange : avertissement ;
- rouge : critique.

Valeurs par défaut :
- orange à 70 % ;
- rouge à 90 %.

## Chiffre d'affaires
Les enregistrements de vente RootMikroManager sont agrégés en :
- aujourd'hui ;
- semaine courante ;
- mois courant ;
- total historique.

La devise globale est toujours affichée.

## Sessions
- Hotspot actifs ;
- PPP actifs.

## Tickets restants
Un ticket restant est un utilisateur Hotspot généré comme voucher
(signature de lot `up/vc-NNN-MM.DD.YY-...`), non désactivé, non expiré et
dont l'uptime est encore nul. Les comptes Hotspot ordinaires ne sont pas
comptés comme tickets. Le tableau affiche :
- stock par profil ;
- stock total ;
- vert/orange/rouge selon des seuils configurables.

## Trafic
Le dashboard mesure `rx-bits-per-second` et `tx-bits-per-second` via
`/interface/monitor-traffic once`.

Les paramètres permettent de régler :
- interface à surveiller ou sélection automatique ;
- intervalle d'échantillonnage ;
- durée de la fenêtre graphique.

## Logs
Le nombre de logs visibles est réglable de 1 à 50.

## Rafraîchissement
L'actualisation automatique est activable/désactivable.
La fréquence générale est réglable de 3 à 300 secondes.
Le trafic possède son propre intervalle afin de rester fluide sans
recharger en permanence toutes les données RouterOS.
