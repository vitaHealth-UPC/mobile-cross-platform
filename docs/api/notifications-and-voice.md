# Notifications and voice

## Push contract

The device registry uses authenticated `PUT` and `DELETE /api/v1/push-devices/{installationId}` operations. The installation identifier is a persisted opaque UUID. The current Tata credential determines its owner; SDK addresses do not authorize clinical access.

Version-1 data messages carry `schemaVersion`, `kind`, `olderAdultId`, `deliveryId`, `intakeId`, `medicationName` and `scheduledAt`. Supported kinds are `REINFORCED_REMINDER` and `CAREGIVER_ALERT`. The mapper rejects incomplete or unknown versioned messages instead of inferring an event from localized text.

## Native display

`LocalOmissionNotifier` uses the shared plugin initialization and the existing ES/EN resources. Omission reminders and caregiver alerts own separate channels. Their negative notification identifiers do not overlap the nonnegative scheduled-dose identifiers. Repeated delivery references replace the same notice.

The visible body is generic and the Android notice has private lock-screen visibility. The monochrome status-bar icon is shared with the Android client. Tap payloads retain the intake reference, and opening a destination requires recipient authorization again.

Display and cleanup operations are serialized. Recipient access is checked around asynchronous work; a session change during display removes omission notices while retaining scheduled-dose notices. Clearing a notice does not acknowledge or close an alert on the server.

## Transport and application lifecycle

`FirebaseOmissionMessageSource` maps foreground messages, remote taps and the initial remote message through the versioned data mapper. It rejects unsupported versions and nonstring fields. Visible notification text never substitutes for the data contract.

`OmissionDeliveryCoordinator` connects that source, token rotations and native taps to the facade. It holds a valid launch payload until access restoration permits navigation, emits authorized destination read models and discards pending navigation on owner change or sign-out. SDK availability gates device synchronization. Native launch evidence remains usable when the remote SDK is unavailable.

The host calls `sessionChanged` after access changes, `beforeSignOut` while the credential still exists, and `dispose` when the lifecycle ends. Stream subscriptions and registration retries are released together. Permission is rechecked for each SDK token rotation without prompting again.

## Host integration

`OmissionMessagingHost` observes `AccessBloc`, foreground resume and authorized destination events. It waits until a frame is mounted before invoking its route callback, then releases subscriptions and the delivery coordinator when unmounted. `TataApp.applicationObserver` places lifecycle observers below the access provider; its navigator key supports the composition-owned route dispatcher.

`SignOut.beforeSignOut` runs authenticated device removal before the repository discards the credential. A failed device cleanup does not prevent local invalidation and account revocation. `AppDependencies.createAccessBloc` accepts this callback from the composition root rather than importing messaging into Identity.

Main wires the host and the sign-out hook. Caregiver taps reload confirmed profiles before opening Alerts. The detail opens only when one alert matches the exact intake reference. Adult taps use the existing dose route after local PIN enrollment. Android registers a background receiver when built with `--dart-define=TATA_ENABLE_OMISSION_PUSH=true`.

## Delivery boundary

The SDK token source and native notifier are composed in production. Device registration is opt-in for Android builds with Firebase configured. iOS requires APNs provisioning and remains disabled. Local adapter tests do not establish background delivery or a successful remote push. The integration also requires Firebase configuration for the target platform, permission, message reception, token rotation, authenticated cleanup and authorized tap handling.

Firebase initialization is shared with social access. The current backend registry accepts FCM tokens; changing to the newer SDK installation-ID protocol requires a corresponding sender migration.

## Spoken confirmation

The voice flow captures audio through its platform port and sends it through the Intake Execution contract. A recognized phrase does not itself confirm a dose: the server response supplies the outcome. Cancellation, lost permission and session changes discard pending clinical UI results. Audio and provider credentials do not enter presentation diagnostics.

See the [Firebase messaging lifecycle](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) and the [offline synchronization boundary](../architecture/offline-sync.md).
