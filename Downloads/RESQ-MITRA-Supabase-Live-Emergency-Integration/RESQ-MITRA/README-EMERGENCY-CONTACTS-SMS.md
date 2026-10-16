# RESQ-MITRA — Emergency Contacts and SOS SMS update

## Changes in this update
- Added a professional Emergency Contacts card on the home screen.
- Added an Emergency Contacts page with add (+), edit and remove actions.
- Contact fields: name, relation and phone number.
- Contacts are saved locally on the device using SharedPreferences.
- Added a full-name field during account creation and saves it as Supabase Auth `full_name` metadata.
- When standard SOS or High Alert SOS starts, the app attempts to send a formatted SMS to each saved contact with user name, SOS type, date/time, coordinates and a Google Maps link when a GPS fix is available.
- Added Android native SMS sending via `SmsManager`, including multipart message support.
- Added SMS permission to the permissions page and Android manifest.
- Retries once after a submission exception and displays the submission status.

## Important delivery limitations
SMS cannot be guaranteed to arrive immediately or at all. `SmsManager` returning successfully means Android accepted the send request; it does not prove carrier delivery or that the recipient read it. Delivery depends on SIM availability, the default SMS subscription, carrier/network coverage, account balance/plan and recipient network. A send exception can also be ambiguous, so retries may occasionally create duplicate messages. The app currently does not implement carrier delivery receipts or a durable SMS retry queue.

This automatic SMS implementation is Android-only. On web/desktop it will not send native SMS. Ensure the user grants SMS permission before an emergency and test with real devices/SIMs and consenting test recipients. For life-threatening emergencies in India, call 112 as well.

## Build
From the project folder:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run` (Android device with SIM for SMS testing)

Build tools were not available in the editing environment, so this modified source has not been compiled or live-tested here. Review build output on your machine before relying on it in an emergency.
