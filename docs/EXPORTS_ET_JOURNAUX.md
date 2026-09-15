# Exports et journaux

## Exports utilisateur

Sur Android, les exports CSV, texte et JSON ouvrent le sélecteur système
« Enregistrer sous ». Le fichier est écrit dans l'emplacement choisi par
l'utilisateur (mémoire interne, carte SD ou fournisseur de documents compatible).
Une annulation ne crée aucun fichier.

Les sauvegardes automatiques gérées par l'application restent volontairement
dans son espace privé : leur catalogue et leur restauration dépendent de cet
emplacement. Une sauvegarde JSON lancée par l'utilisateur utilise le sélecteur.

## Journaux RouterOS

- « Vider » efface le contenu de chaque action ayant `target=memory`.
- « Limiter à 200 lignes » règle durablement `memory-lines=200` sur l'action
  mémoire native nommée `memory`.
- « Retirer la limite de 200 » restaure `memory-lines=1000`. RouterOS ne fournit
  pas de buffer mémoire infini.

Chaque modification demande une confirmation et nécessite les permissions API
RouterOS permettant de modifier `/system/logging/action`.

Les tests automatisés n'ouvrent aucune connexion vers un routeur réel.
