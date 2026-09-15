# Compilation réelle

Depuis PowerShell :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\BUILD_ROOTMIKROMANAGER.ps1
```

Après un `flutter analyze` sans erreur bloquante :

```powershell
.\BUILD_APK_RELEASE.ps1
```

En cas d'erreur, envoyer la sortie complète de `flutter analyze` ou `flutter run`
pour effectuer la correction à partir du diagnostic réel du compilateur.
