# RootMikroManager — Hotspot Advanced & RouterOS Files

## Hotspot avancé
Une interface dédiée expose maintenant :
- sessions Hotspot actives ;
- déconnexion d'une session ;
- Hosts ;
- conversion Host -> IP Binding ;
- IP Binding create ;
- IP Binding edit ;
- enable / disable ;
- delete ;
- types regular / bypassed / blocked.

## Fichiers RouterOS
La vue `/file` permet :
- liste des fichiers ;
- nom ;
- type ;
- taille ;
- date ;
- identification visuelle des `.backup` ;
- suppression avec confirmation.

RootMikroManager ne prétend pas télécharger un fichier RouterOS avec une
commande API qui ne fournit pas réellement ce transfert. Le téléchargement
sera implémenté avec un transport adapté dans une phase dédiée.

## Backup unifié
La navigation `Backup` pointe maintenant vers l'écran unifié :
- JSON RootMikroManager ;
- restauration JSON ;
- création `.backup` ;
- export `.rsc` ;
- fichiers RouterOS.
