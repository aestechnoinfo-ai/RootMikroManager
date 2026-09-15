$ErrorActionPreference = "Stop"
flutter clean
flutter pub get
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build apk --release
Write-Host "APK : build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
