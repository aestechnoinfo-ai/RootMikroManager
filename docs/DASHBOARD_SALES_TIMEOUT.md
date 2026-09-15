# Timeout des ventes du dashboard

## Constat

Le retour utilisateur identifie `sales` comme première requête en timeout.
Le client ferme volontairement un socket ayant expiré : sans tags, une réponse
tardive risquerait d'être attribuée à la commande suivante. Ce garde-fou reste.
L'ancienne lecture `/system/script/print` transférait tous les champs, dont
`source`, avant de filtrer les rapports localement. Le volume exact sur le
routeur réel n'a pas été mesuré ; la cause précise de sa lenteur reste à vérifier.

## Décision

- Ne pas augmenter globalement les délais.
- Lecture dédiée `salesSummaryRows`, projection `.id,name,comment` uniquement.
  Le calcul des recettes utilise les données encodées dans `name`.
  Les rapports historiques restent reconnus par leur structure `-|-`.
- Pas de modification de la lecture complète des rapports ni des suppressions.
- Le dashboard demande les ventes en dernier sur un socket authentifié distinct,
  fermé dans `finally`, avec les mêmes paramètres TLS que la session active.
  Une réponse d'une ancienne session est rejetée après changement de routeur.
- Au plus une tentative de ventes par minute lors des actualisations automatiques,
  y compris après échec. Le bouton Actualiser permet un nouvel essai explicite.
- Les valeurs précédentes restent marquées anciennes en cas d'erreur ; une
  lecture échouée n'est pas assimilée à un chiffre d'affaires nul.

## Risques résiduels et validation

La projection réduit le transfert mais parcourt encore le catalogue de scripts
pour préserver les anciens rapports sans marqueur. Un très grand historique ou
des limites de sessions API peuvent encore faire échouer les ventes, sans fermer
la session interactive. Aucune donnée RouterOS n'est modifiée et aucune commande
métier n'est rejouée. SQLite et go_router sont inchangés.

Tests : timeout simulé des ventes sans perte des sections essentielles, délai
entre tentatives et actualisation forcée ; serveur loopback vérifiant la projection
exacte et la survie de la connexion principale après perte du socket isolé.
La validation sur un MikroTik réel nécessite l'accord de l'utilisateur.

Vérification locale : suite complète `flutter test --no-pub` — 60 tests réussis.
Analyse statique ciblée du dashboard, de la session et des tests — aucun problème.

## Lecture longue : suivi de progression

Après isolation, un nouveau retour utilisateur montre encore le timeout des
ventes seules. Le client imposait 15 secondes à toute la réponse, y compris
lorsque des lignes continuaient d'arriver. Le symptôme seul ne permet pas de
conclure que c'est la cause sur l'appareil.

La lecture de synthèse dispose maintenant de deux bornes : 15 secondes sans
octets reçus et 60 secondes au total. Les autres commandes, y compris le login,
conservent leur limite de 15 secondes. Un échec précise le chemin de commande,
la nature de la limite et les compteurs de lignes/octets, jamais les arguments
ou identifiants. Pas de total validé sur une réponse partielle sans `!done`.
Les tests simulent silence, transfert progressif et transfert sans fin.

Le projet de référence utilise `rapportVente/*.json`, et non les mêmes scripts
historiques. Une migration vers ce format ne fait pas partie de cette correction.
