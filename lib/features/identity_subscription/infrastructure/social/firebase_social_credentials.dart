import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/firebase/firebase_runtime.dart';
import '../../application/ports/social_credentials.dart';
import '../../domain/value_objects/social_provider.dart';

/// Exchanges provider credentials for transient Firebase evidence, not Tata access.
/// SDK identities are signed out afterwards; only Tata persists the session.
final class FirebaseSocialCredentials implements SocialCredentials {
  static Future<void>? _googleInitialization;
  bool _busy = false;

  @override
  Future<AppResult<SocialIdentityToken?>> authenticate(
    SocialProvider provider,
  ) async {
    if (_busy) return const AppFailure('SOCIAL_AUTHENTICATION_BUSY');
    _busy = true;
    FirebaseAuth? auth;
    try {
      await FirebaseRuntime.initialize();
      auth = FirebaseAuth.instance;
      await auth.signOut();
      final UserCredential result;
      if (kIsWeb) {
        result = await auth.signInWithPopup(switch (provider) {
          SocialProvider.google => GoogleAuthProvider(),
          SocialProvider.facebook => FacebookAuthProvider()..addScope('email'),
        });
      } else {
        final AuthCredential credential;
        switch (provider) {
          case SocialProvider.google:
            await (_googleInitialization ??= GoogleSignIn.instance
                .initialize());
            final account = await GoogleSignIn.instance.authenticate();
            final idToken = account.authentication.idToken;
            if (idToken == null) {
              return const AppFailure('INVALID_SOCIAL_CREDENTIAL');
            }
            credential = GoogleAuthProvider.credential(idToken: idToken);
          case SocialProvider.facebook:
            final login = await FacebookAuth.instance.login();
            if (login.status == LoginStatus.cancelled) {
              return const AppSuccess(null);
            }
            final accessToken = login.accessToken;
            if (login.status != LoginStatus.success || accessToken == null) {
              return const AppFailure('SOCIAL_AUTHENTICATION_FAILED');
            }
            credential = FacebookAuthProvider.credential(
              accessToken.tokenString,
            );
        }
        result = await auth.signInWithCredential(credential);
      }
      final token = await result.user?.getIdToken(true);
      if (token == null) return const AppFailure('INVALID_SOCIAL_CREDENTIAL');
      return AppSuccess(SocialIdentityToken(token));
    } on GoogleSignInException catch (error) {
      return error.code == GoogleSignInExceptionCode.canceled
          ? const AppSuccess(null)
          : const AppFailure('SOCIAL_AUTHENTICATION_FAILED');
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'popup-closed-by-user' ||
        'cancelled-popup-request' ||
        'web-context-cancelled' => const AppSuccess(null),
        'network-request-failed' => const AppFailure('NETWORK_UNAVAILABLE'),
        'operation-not-allowed' ||
        'invalid-api-key' => const AppFailure('SOCIAL_NOT_CONFIGURED'),
        _ => const AppFailure('SOCIAL_AUTHENTICATION_FAILED'),
      };
    } on FirebaseException {
      return const AppFailure('SOCIAL_NOT_CONFIGURED');
    } on MissingPluginException {
      return const AppFailure('SOCIAL_NOT_CONFIGURED');
    } on PlatformException {
      return const AppFailure('SOCIAL_AUTHENTICATION_FAILED');
    } on Exception {
      return const AppFailure('SOCIAL_AUTHENTICATION_FAILED');
    } finally {
      // Cleanup must not replace the stable authentication result with SDK errors.
      try {
        await auth?.signOut();
      } on Exception {
        /* No Tata session is stored by this adapter. */
      }
      if (!kIsWeb) {
        try {
          if (provider == SocialProvider.facebook) {
            await FacebookAuth.instance.logOut();
          } else if (_googleInitialization != null) {
            await GoogleSignIn.instance.signOut();
          }
        } on Exception {
          /* Provider state never grants access to Tata. */
        }
      }
      _busy = false;
    }
  }
}
