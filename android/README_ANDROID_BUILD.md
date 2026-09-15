# RootMikroManager – Préparation Android

## Permissions nécessaires

L'application doit pouvoir communiquer avec les routeurs MikroTik :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

À placer dans `android/app/src/main/AndroidManifest.xml`.

## Commandes de vérification

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Remarque

Cette archive a été consolidée au niveau du code source et des dépendances déclarées.
La compilation Android finale doit être exécutée dans un environnement Flutter installé, car
l'environnement de génération de cette archive ne contient pas le SDK Flutter/Android.
