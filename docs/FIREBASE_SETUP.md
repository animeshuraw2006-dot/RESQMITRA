# Connect RESQ-MITRA to a live Firestore database

This starter now has a Firestore repository and a responder queue that listens to active records. Live sharing is enabled only after Firebase is configured. Do not use permissive test rules for an emergency app.

## 1. Create Firebase project
1. Create a project at https://console.firebase.google.com/.
2. Add an Android app using the package name `com.example.resq_mitra` only if that matches the Android app created by `flutter create . --platforms=android`. Check `android/app/build.gradle` for `applicationId` and use that exact value.
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
