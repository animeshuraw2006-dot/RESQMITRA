# RESQ-MITRA — Supabase integration starter

**NO LIFE LEFT BEHIND** · HELP | SUPPORT | TOGETHER

This update replaces Firebase Auth/Firestore client usage with Supabase Auth, a Supabase-backed SOS repository, database schema/RLS, Realtime responder assignments, and Edge Function endpoints for dispatch, cancellation, and acceptance. The existing branded UI, SOS categories, countdown flow, siren asset and intro video are retained.

## Configure Flutter

1. Use your selected RESQ-MITRA Supabase project `tgyitcorasmzwnjganmj` (Project URL: `https://tgyitcorasmzwnjganmj.supabase.co`) and open **Project Settings → API**. Copy the Project URL and the **publishable** client key (legacy `anon` key also works if your project still uses it).
2. In this folder run:

   ```bash
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

3. Configure email/password authentication in Supabase Auth. If email confirmation is enabled, a new user must confirm email and then log in.

## Configure the database and server functions

1. Run `supabase/schema.sql` in Supabase SQL Editor.
2. Install Supabase CLI, run `supabase login` and `supabase link --project-ref YOUR_PROJECT_REF`.
3. Set Edge Function secrets (never put service role keys in Flutter):

   ```bash
   supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co SUPABASE_ANON_KEY=YOUR_ANON_KEY SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
   ```

4. Deploy functions:

   ```bash
   supabase functions deploy dispatch-sos
   supabase functions deploy cancel-sos
   supabase functions deploy accept-sos
   ```

5. In **Database → Publications**, enable `responder_assignments` for `supabase_realtime`.
6. Have an administrator verify responder identities and set `responder_profiles.verified = true` and `available = true` for test responder accounts. Ordinary sign-up only creates citizen profiles.

## Important limitations before real deployment

- Dispatch currently assigns to all verified/available responders; it does **not** implement proximity ranking, FCM push delivery, or emergency-contact alerts. Realtime works while the responder app is connected; it is not a background push replacement.
- The Edge Function endpoints and SQL are integration scaffolding and require testing in your actual Supabase project. The acceptance endpoint should receive a final concurrency/security review before production; test simultaneous accepts and enforce a single winning responder in a single database transaction.
- No live emergency system can be guaranteed available. Test using dedicated test accounts/devices and keep India's official emergency number **112** accessible. Do not claim help has been contacted until a backend dispatch and responder acknowledgement are confirmed.
- Private voice/video upload, FCM delivery, responder last-known location, audit logs, rate limits, expiry jobs, and retention policies are not included in this update.

## Android build

```bash
flutter pub get
flutter build apk --debug --dart-define=SUPABASE_URL=https://tgyitcorasmzwnjganmj.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```


## Siren and emergency voice recordings

- The responder screen plays `assets/high_alert_siren.ogg` when a new assignment arrives while the screen is open. The responder can silence it. This is an in-app realtime listener, not a background push notification; configure and test FCM/APNs for alerts while the app is closed or suspended.
- The Emergency Confirmation page now supports microphone recording. After the SOS is confirmed, the recording is uploaded to the private `emergency-audio` Storage bucket and its metadata is saved in `emergency_audio_recordings`. Run the updated `supabase/schema.sql` in the selected project SQL Editor to create the table, private bucket, and RLS policies. Audio access is limited to the SOS requester and the responder who accepted it.
- After accepting an SOS, the responder can use the AUDIO action on that assignment to play the latest uploaded recording. If the recording is still uploading, try again shortly.
- **This is recorded audio uploaded after capture, not a continuous live microphone stream.** Supabase Database/Storage is not a low-latency media transport. True live two-way/one-way audio requires WebRTC with a media/signalling service (for example, a properly secured LiveKit deployment) and additional call lifecycle, permission, consent, and disconnect handling. Do not describe this current recording feature as live streaming.
- Test only with consenting test accounts/devices and sample incidents before any real deployment. Do not rely on the app as the only emergency channel; in India call **112** when immediate assistance is needed.
