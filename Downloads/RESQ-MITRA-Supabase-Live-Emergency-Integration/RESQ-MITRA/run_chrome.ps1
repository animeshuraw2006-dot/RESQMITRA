$ErrorActionPreference = "Stop"
$projectUrl = "https://tgyitcorasmzwnjganmj.supabase.co"
$publishableKey = Read-Host "Enter the publishable key for Supabase project tgyitcorasmzwnjganmj"
if ([string]::IsNullOrWhiteSpace($publishableKey)) { throw "Publishable key is required." }
flutter pub get
flutter create --platforms=web .
flutter run -d chrome --dart-define="SUPABASE_URL=$projectUrl" --dart-define="SUPABASE_PUBLISHABLE_KEY=$publishableKey"
