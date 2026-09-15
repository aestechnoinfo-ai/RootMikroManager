# RootMikroManager – BUILD READY Checklist

## 1. Dépendances
- [x] Suppression des dépendances inutilisées de la base actuelle.
- [x] Conservation de SQLite.
- [x] Conservation de flutter_secure_storage.
- [x] SDK Dart compatible avec Flutter récent.

## 2. Architecture
- [x] Point d'entrée `main.dart`.
- [x] Application `RootMikroManagerApp`.
- [x] SQLite pour les routeurs.
- [x] Secure Storage pour les mots de passe.
- [x] Session RouterOS partagée.
- [x] Navigation protégée lorsqu'aucun routeur n'est connecté.

## 3. RouterOS
- [x] Connexion TCP API.
- [x] Authentification.
- [x] Lecture de ressources.
- [x] Hotspot.
- [x] DHCP.
- [x] DNS.
- [x] Interfaces.
- [x] Firewall/NAT.
- [x] Queues.
- [x] PPP.
- [x] Scripts.
- [x] Scheduler.
- [x] Logs.
- [x] Ping.
- [x] Traceroute.
- [x] Backup et export RouterOS.

## 4. Vérification obligatoire sur votre PC

Exécuter :

```powershell
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run
```

Si une erreur apparaît, corriger l'erreur indiquée avant de générer l'APK.

## 5. APK

Après validation :

```powershell
flutter build apk --debug
```

Puis pour une version de production :

```powershell
flutter build apk --release
```
