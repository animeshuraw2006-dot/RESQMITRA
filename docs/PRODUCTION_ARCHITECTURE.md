# Production architecture checklist

This starter deliberately keeps dispatch local. Before real emergency use, implement and independently test:

## Suggested services
- **Identity:** Firebase Authentication / OIDC. Phone verification, email verification, account recovery, rate limits, device/session revocation.
- **Database:** Firestore or PostgreSQL/PostGIS. Never trust client-submitted responder verification or role flags.
- **Dispatch:** authenticated callable API / Cloud Run service. Validate SOS type, location precision, user consent, idempotency key, abuse limits and responder eligibility. Fan out to nearby verified responders by geospatial query.
- **Notifications:** FCM/APNs to eligible responders and emergency contacts, with delivery/acknowledgement state and retries.
- **Location:** collect only while SOS is active and consented; restrict to the requester, accepted responder(s), and authorized safety operators. Stop sharing on cancel/safe/expiry.
- **Audio:** explicit consent, visible recording state, encrypted upload, short retention, access audit and deletion. Never upload in the background without clear user action.
- **Maps:** Google Maps or OpenStreetMap-based SDK, API-key restrictions, geofencing and stale-location indicators.
- **Responder verification:** identity/organization checks, training and expiry status, revocation, audit trail, least privilege and admin review.
- **Operational safety:** SOS lifecycle state machine, dispatch acknowledgement, false-alarm handling, rate limiting, offline fallback, privacy policy, incident response, accessibility, localization, load tests and a 24/7 support plan.

## Suggested JSON document
```json
{
  "sosId": "server-generated-uuid",
  "requesterId": "auth-user-id",
  "category": "general|women|child",
  "emergencyType": "medical|accident|fire|flood|rescue|evacuation|missing_person|shelter|food_water|blood_needed|other",
  "urgency": "critical|high|normal",
  "location": {
    "latitude": 0.0,
    "longitude": 0.0,
    "accuracyMeters": 0,
    "capturedAt": "ISO-8601 timestamp"
  },
  "instructions": "user-entered text",
  "doNotCall": false,
  "bloodGroup": "A+|A-|B+|B-|AB+|AB-|O+|O-|any",
  "audioObjectPath": null,
  "status": "pending|accepted|en_route|arrived|cancelled|safe|expired",
  "acceptedResponderIds": [],
  "createdAt": "server timestamp",
  "expiresAt": "server timestamp"
}
```

## Security rules (principles, not copy-paste rules)
- Requesters can create only for themselves and read their own SOS.
- Only verified, active responders can discover a minimum-necessary set of nearby active SOS requests.
- A responder can accept only if eligible and the request is still pending; perform acceptance atomically on the server.
- Exact location and sensitive categories are revealed only after authorized acceptance, with explicit requester policy.
- Do not allow clients to set `verified`, `role`, `acceptedResponderIds`, or authoritative status fields.
- Audit privileged access and every location/audio read.
- Apply automatic expiry and deletion/retention limits.

## Android permissions
Review `android/app/src/main/AndroidManifest.xml` after generating the Android platform. Add only permissions that match implemented features. Calling can use a `tel:` intent; it usually does not require direct call permission. Do not request microphone/camera merely for a future feature that is not active.
