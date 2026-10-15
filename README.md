# RESQ-MITRA — Flutter emergency-response starter

**NO LIFE LEFT BEHIND** · HELP | SUPPORT | TOGETHER

This repository is a runnable Flutter starter/prototype for RESQ-MITRA. It includes a branded onboarding flow, local demo sign-in, permission request screen, citizen/responder modes, SOS category selection, emergency-type tiles (including **Blood Needed**), a confirmation form with blood groups and “Do not call” preference, an active SOS status screen, responder queue, and responder map placeholder.

> **Safety / production note:** This is a prototype, not a certified emergency dispatch service. The included SOS queue is local demo state only; it does not transmit alerts to real responders, send SMS, record/upload audio, or provide live maps. Do not rely on it for emergencies. In India, call the appropriate official emergency number directly (112 is the pan-India emergency number). Before public deployment, integrate and test a secure backend, verified responder accounts, push notifications, consent-based location sharing, real map tiles, secure audio storage, abuse prevention, and emergency-service/legal review.

## Run locally
1. Install Flutter stable and Android Studio (Android SDK).
2. Unzip this repository and run:
   ```bash
   flutter pub get
   flutter run
   ```
3. To build an APK:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`.

The archive intentionally does not include generated Android Gradle wrapper/build outputs; Flutter creates those for a normal Flutter project. If your environment says the Android platform folder is missing, run `flutter create . --platforms=android` from this folder, then run `flutter pub get`.

## GitHub Actions
The workflow at `.github/workflows/flutter.yml` checks formatting/analyzes the app and builds a debug APK on pushes and pull requests. Upload the ZIP to a GitHub repository, commit, and push. The APK is available under Actions → workflow run → Artifacts.

## Backend / production architecture
See `docs/PRODUCTION_ARCHITECTURE.md` for a suggested API/data model. Do not put service credentials in source control. Configure Firebase or another backend with strict security rules before enabling live dispatch.

## Local SOS mode
This reverted version does not require Firebase configuration. SOS requests remain local to the running app and are not transmitted to real responders.
