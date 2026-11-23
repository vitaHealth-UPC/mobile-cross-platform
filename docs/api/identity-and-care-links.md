# Identity and care-link contracts

`identity_subscription` owns account access and subscription presentation. `care_link` owns adult profiles, invitations and consent. The backend validates the actor and the relationship for every protected request.

## Account access

| Action | Method and path | Evidence |
| --- | --- | --- |
| Register caregiver | `POST /api/v1/accounts` | Name, email and password |
| Verify email | `POST /api/v1/accounts/verification` | Email and verification code |
| Request verification | `POST /api/v1/email-verification-requests` | Email |
| Password sign-in | `POST /api/v1/sessions` | Email and password |
| Social sign-in | `POST /api/v1/social-sessions` | `firebaseIdToken` |
| Current session | `GET /api/v1/sessions/current` | Tata bearer |
| Sign out | `DELETE /api/v1/sessions` | Captured Tata bearer |
| Register adult PIN | `POST /api/v1/pin-credentials` | Adult bearer, adult ID and PIN |
| PIN sign-in | `POST /api/v1/pin-sessions` | Adult ID and PIN |

Access stores only a valid, unexpired Tata session with an unambiguous actor. A generation captured before asynchronous work prevents a late response from restoring an invalidated session. PIN access clears entered digits after an attempt and disables input when the backend returns `PIN_LOCKED`.

## Google and Facebook

`FirebaseSocialCredentials` opens the provider SDK and exchanges its credential through Firebase Authentication. `RemoteSocialSessionRepository` sends only the Firebase ID token to Tata; Google and Facebook access tokens are not used as Tata bearers. The adapter signs out its SDK identities after obtaining the transient evidence.

`SignInWithSocial` is consumed by `AccessBloc`. Cancellation returns to anonymous access without an error. Repeated requests while busy are ignored, and sign-out supersedes an in-flight result. Social responses must identify a caregiver; an adult or setup response is rejected without persistence.

| Backend response | Client behavior |
| --- | --- |
| `SOCIAL_LINK_REQUIRED` / `SOCIAL_LINK_CONFLICT` | No automatic binding by matching email |
| `INVALID_SOCIAL_CREDENTIAL` | No session is adopted |
| `SOCIAL_EMAIL_REQUIRED` | A verified provider email is required |
| `SOCIAL_PROVIDER_UNAVAILABLE` | The access method is unavailable |

An existing Tata account is not taken over by a provider asserting the same email. Explicit binding uses the backend's protected `PUT /api/v1/me/social-identities` contract and requires an authenticated caregiver. Password access remains available when social sign-in requires binding.

### Native configuration

The Android package is `com.vitahealth.tata`, matching the native client. Local configuration consists of `android/app/google-services.json` and `TATA_FACEBOOK_APP_ID` / `TATA_FACEBOOK_CLIENT_TOKEN` in `android/local.properties`. These files are ignored by Git. The Facebook Client Token is not the App Secret; App Secrets and service-account keys do not belong in either mobile client.

The Google services plugin is applied only when the client configuration exists. Facebook resources and its redirect scheme are generated from local properties. Android signing fingerprints must match the provider consoles. iOS uses its own registered bundle, client file and URL schemes; Android client configuration does not configure iOS.

SDK configuration follows the [Firebase Flutter federated-authentication guide](https://firebase.google.com/docs/auth/flutter/federated-auth). Unit tests and an APK build validate the exchange and compilation; a real provider account requires a separate installed-device test.

## Care relationships

| Action | Method and path |
| --- | --- |
| Register adult profile | `POST /api/v1/older-adults` |
| Read/update profile | `GET` / `PUT /api/v1/older-adults/{olderAdultId}` |
| Read confirmed relationships | `GET /api/v1/care-links?caregiverId=...` |
| Generate linking code | `POST /api/v1/care-links/linking-codes` |
| Accept invitation | `POST /api/v1/care-links/acceptances` |
| Read relationship | `GET /api/v1/care-links/{careLinkId}` |
| Decide consent | `POST /api/v1/care-links/{careLinkId}/consent` |
| Withdraw consent | `DELETE /api/v1/care-links/{careLinkId}/consent` |

Invitation acceptance does not inherit a caregiver bearer. It establishes the adult's setup scope; only the adult decides consent. A caregiver generates or copies the invitation and reads its status, without approving the relationship on the adult's behalf. Consent withdrawal invalidates protected local access and cached health data.
