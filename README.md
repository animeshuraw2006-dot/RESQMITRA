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

## Firestore live SOS storage
The project now includes `lib/services/sos_repository.dart`, `database.schema.json`, `firestore.rules`, `firestore.indexes.json`, and `firebase.json`. Once Firebase is configured, SOS records are written to the `sosRequests` collection and the responder page listens for active requests. Follow `docs/FIREBASE_SETUP.md` before testing. Firebase must be configured and verified responder records provisioned by an administrator; otherwise the app remains in local demo mode. Anonymous auth is only a starter identity, not production-grade verification.


## Android build scaffold
The source archive may not include generated `android/` Gradle files. The GitHub Actions workflow now generates the Android platform files automatically before `flutter pub get`, analysis, and APK build. If building locally for the first time, run:
```bash
flutter create --platforms=android --org com.resqmitra .
flutter pub get
flutter build apk --debug
```
If you already have a customized Android folder, back it up before running `flutter create`.


## Android build files and GitHub Actions

This source archive does not include generated Android Gradle scaffolding. The GitHub Actions workflow now generates the Android platform files with `flutter create` before dependency installation, analysis, or APK compilation, then explicitly checks that the Gradle build file exists. This fixes the `android/app/build.gradle` PathNotFoundException.

If building locally from the project root, run:

```bash
flutter create --platforms=android --org com.resqmitra --project-name resq_mitra .
flutter pub get
dart format lib
flutter analyze
flutter build apk --debug
```

The workflow can build a debug APK without a Firebase project configured. Live Firebase functionality still requires the setup described in `docs/FIREBASE_SETUP.md`.


## HIGH ALERT SOS (important limitations)

The home screen includes a blood-red HIGH ALERT SOS button. It creates a critical-priority SOS record (when Firebase is configured), opens a 10-second countdown page, and then attempts to open the device camera preview. The camera preview remains on the user's device in this starter. **Live video is not broadcast to responders**: that requires a secured WebRTC/media service, signaling, responder-side viewing, access control, and retention policy. Do not describe this build as streaming video.

Android does not permit apps to force silent/Do Not Disturb mode on all devices without special notification-policy access. This starter explains that limitation rather than changing sound settings without explicit platform setup. The user can enable Silent/Do Not Disturb from Android Quick Settings. The countdown page has a cancel action.

The `camera` package is included for local camera preview. Test camera permission, lifecycle, and behavior on real Android devices before deployment. For production, configure the secure video service and verify responders before sending any media.

## Authentication update

The login screen now supports Firebase SMS OTP sign-in by phone and passwordless email sign-in links. Firebase Phone Authentication does not itself send numeric OTP codes to email; numeric email OTP requires a trusted backend. See `docs/FIREBASE_SETUP.md` for Firebase Console setup, SHA fingerprints, and Android App Links configuration. Replace the email URL placeholder in `lib/main.dart` with your Firebase project's domain before testing email sign-in.

The SOS home button, HIGH ALERT SOS action, emergency-category icons, and emergency-type option tiles have been enlarged for easier use.


## Voice recordings and responder siren

The SOS confirmation screen can record an optional voice note. When Firebase Storage is configured and the user is authenticated, the file is uploaded with the SOS request and responders can play the attached recording. The responder page plays the included siren sound when pending requests appear while that page is open. Deploy both Firestore and Storage rules and configure verified responder accounts before use. See `docs/FIREBASE_SETUP.md`.

Phone OTP has been removed from the login screen; sign-in is by Firebase email link. Firebase project configuration is required: the app intentionally shows a setup message rather than opening Firebase-dependent screens if initialization fails.
