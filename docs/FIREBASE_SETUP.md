# Connect RESQ-MITRA to a live Firestore database

This starter now has a Firestore repository and a responder queue that listens to active records. Live sharing is enabled only after Firebase is configured. Do not use permissive test rules for an emergency app.

## 1. Create Firebase project
1. Create a project at https://console.firebase.google.com/.
2. This repository's GitHub workflow generates Android scaffolding with `flutter create --platforms=android --org com.resqmitra .` if it is missing. The resulting Android application ID is usually `com.resqmitra.resq_mitra`; verify it in `android/app/build.gradle` or `android/app/build.gradle.kts`, and register that exact ID in Firebase.
3. Enable **Cloud Firestore** in production mode.
4. Enable **Authentication → Sign-in method → Anonymous**. This starter uses anonymous auth to identify a device session; it is not a verified identity or a production account system.
5. Download `google-services.json` into `android/app/`.
6. Apply the Google Services Gradle plugin using the current Firebase Android setup instructions if FlutterFire setup has not already done so. Follow the official Firebase Flutter guide: https://firebase.google.com/docs/flutter/setup
7. From the project directory, run `flutter pub get` and `flutter run`.

If `Firebase.initializeApp()` fails, the app deliberately falls back to local demo mode. Confirm Firebase setup in the Android build logs.

## 2. Deploy rules and indexes
Install Firebase CLI, log in, and from this folder run:
```bash
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
```
Create `firebase.json` if needed:
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```
Or paste `firestore.rules` into Firebase Console → Firestore Database → Rules and deploy `firestore.indexes.json` via CLI.

## 3. Verify responders securely
The app does **not** let a user self-assign a responder role. A trusted administrator/backend must create `/responders/{firebaseAuthUid}` with:
```json
{
  "verified": true,
  "active": true,
  "displayName": "Verified responder",
  "organization": "Approved organization"
}
```
Never create this document from the client app. Production systems should use a server-side acceptance transaction so two responders cannot accept the same request simultaneously, plus proper identity verification, audit logs, rate limits and dispatch acknowledgements.

## 4. Stored SOS fields
See `database.schema.json`. Each `sosRequests/{id}` record includes category, emergency type, urgency, written instructions, Do Not Call preference, blood group, location and accuracy, timestamps, status and responder IDs.

## 5. Important limitations
- The responder page can stream active Firestore records after setup, and accepts a request by updating status. Full acceptance locking and requester notification need a trusted backend/Cloud Function.
- Location is stored only if the device grants location access and a position can be obtained.
- The recording control is still a UI demo. `audioRequested` is a boolean, not an audio file. Do not imply that audio has been captured or sent.
- This sample uses anonymous authentication; implement real phone/email authentication and verified responder onboarding before launch.
- Add the exact Firestore composite index if the console prompts for it. The included index covers status + createdAt; Firestore may ask for another index depending on query planning.

## 6. Phone OTP and email one-time sign-in

The login screen now uses Firebase Authentication instead of the old local-only prototype sign-in:

- **Phone OTP:** uses Firebase Phone Authentication (`verifyPhoneNumber`, then `PhoneAuthProvider.credential`). Enter the number in international format, e.g. `+91...`.
- **Email:** uses Firebase's passwordless email sign-in link. Firebase Phone Authentication only sends numeric OTPs by SMS; Firebase Auth does not provide a built-in numeric OTP delivered to email. A numeric email OTP would require a trusted backend or an appropriate authentication extension. The email link is a one-time sign-in method, not a numeric email code.

Before testing phone OTP:
1. In Firebase Console → Authentication → Sign-in method, enable **Phone**.
2. In Firebase Console → Authentication → Settings, allow the SMS regions you intend to serve.
3. Register the Android app with the exact application ID and add its SHA-1 and SHA-256 signing certificate fingerprints.
4. Use a real device or a Firebase-configured test phone number. SMS quota and regional restrictions apply.

Before testing email sign-in links:
1. Enable the email-link/passwordless sign-in method in Firebase Authentication.
2. Replace `YOUR_FIREBASE_PROJECT_ID` in `lib/main.dart`'s `emailContinueUrl` with your Firebase project's actual Hosting/auth domain.
3. Add that domain to Firebase Authentication's authorized domains.
4. Configure Android App Links for that same host in the generated `android/app/src/main/AndroidManifest.xml` `MainActivity` intent filters, using `android:autoVerify="true"`, scheme `https`, and host equal to your Firebase project domain. Keep the existing Flutter activity configuration. The `app_links` package handles incoming links once Android routes them to the app.
5. Ensure the email address used to request the link is entered on the login screen when opening the link on the same device. This starter keeps the email in the login form; it does not persist it across a process restart.

The source uses the package ID `com.resqmitra.resq_mitra` by default; if you change the Android application ID, update `androidPackageName` in `lib/main.dart` to match. Review current platform requirements in the official guides:
- https://firebase.google.com/docs/auth/flutter/phone-auth
- https://firebase.google.com/docs/auth/flutter/email-link-auth
