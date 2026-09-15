# Lot Backup / Restore / Export / Diagnostics

## RootMikroManager
Les données locales peuvent être sauvegardées dans un fichier JSON stocké
dans le dossier applicatif `backups`. L'écran permet de créer, lister,
restaurer et supprimer ces sauvegardes.

Le JSON contient :
- routeurs enregistrés ;
- historique vouchers ;
- logs d'audit ;
- paramètres de l'application.

Les mots de passe RouterOS restent gérés par le stockage sécurisé et ne sont
pas exportés dans le JSON SQLite.

## RouterOS
Deux formats distincts :
- `.backup` : sauvegarde binaire RouterOS ;
- `.rsc` : export texte de configuration.

Le backup peut recevoir un mot de passe. La restauration d'un `.backup`
demande explicitement de saisir `RESTAURER`.

## Fichiers
Recherche et filtres Tous / Backups / RSC. Les fichiers peuvent être supprimés.
Le téléchargement binaire vers le téléphone n'est pas simulé tant qu'un
transport de fichier dédié n'est pas intégré.

## Diagnostics
Tests non destructifs :
- port TCP du routeur ;
- session API RouterOS ;
- `/system resource` ;
- `/system clock` ;
- accès `/file`.

Ce lot n'ajoute volontairement pas `file_picker`.
