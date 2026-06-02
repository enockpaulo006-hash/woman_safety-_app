import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/google_auth_config.dart';

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.idToken,
    required this.email,
    required this.displayName,
  });

  final String idToken;
  final String email;
  final String? displayName;
}

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  bool _isInitialized = false;

  Future<GoogleAuthResult> authenticate() async {
    try {
      await _ensureInitialized();

      GoogleSignInAccount? account;
      if (_signIn.supportsAuthenticate()) {
        account = await _signIn.authenticate();
      } else {
        final pendingAuthentication = _signIn.attemptLightweightAuthentication(
          reportAllExceptions: true,
        );
        account = pendingAuthentication == null ? null : await pendingAuthentication;
      }

      if (account == null) {
        throw const GoogleAuthCancelledException();
      }

      final authentication = account.authentication;
      final idToken = authentication.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthFailedException(
          'Google did not return an ID token.',
        );
      }

      return GoogleAuthResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw const GoogleAuthCancelledException();
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw GoogleAuthNotConfiguredException(error.description);
        default:
          throw GoogleAuthFailedException(error.description);
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    final serverClientId = GoogleAuthConfig.serverClientId;
    if (serverClientId == null) {
      throw const GoogleAuthNotConfiguredException();
    }

    await _signIn.initialize(serverClientId: serverClientId);
    _isInitialized = true;
  }
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthNotConfiguredException extends GoogleAuthException {
  const GoogleAuthNotConfiguredException([String? message])
    : super(message ?? 'Google sign-in is not configured yet.');
}

class GoogleAuthCancelledException extends GoogleAuthException {
  const GoogleAuthCancelledException()
    : super('Google sign-in was canceled.');
}

class GoogleAuthFailedException extends GoogleAuthException {
  const GoogleAuthFailedException([String? message])
    : super(message ?? 'Google sign-in failed.');
}
