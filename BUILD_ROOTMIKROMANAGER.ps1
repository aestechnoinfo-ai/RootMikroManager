$ErrorActionPreference = "Stop"
Write-Host "RootMikroManager - Validation Flutter" -ForegroundColor Cyan
flutter --version
flutter doctor -v
flutter clean
flutter pub get
dart format lib
flutter analyze
if ($LASTEXITCODE -ne 0) {
  Write-Host "Copiez toute la sortie de flutter analyze et envoyez-la dans ChatGPT." -ForegroundColor Yellow
  exit $LASTEXITCODE
}
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter run
