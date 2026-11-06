import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class DriveAuthService {
  static const _webClientId =
      '659029843560-8aeo5tbi9s9ar06ss0mptbgenhp8u9qi.apps.googleusercontent.com';
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _initialized = true;
  }

  Future<auth.AuthClient> signIn() async {
    await _init();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _scopes,
    );
    final authorization = await account.authorizationClient
        .authorizeScopes(_scopes);
    return authorization.authClient(scopes: _scopes);
  }

  Future<auth.AuthClient?> trySilentClient() async {
    await _init();
    final attempt =
        GoogleSignIn.instance.attemptLightweightAuthentication();
    if (attempt == null) return null;
    final account = await attempt;
    if (account == null) return null;

    final authorization = await account.authorizationClient
        .authorizationForScopes(_scopes);
    if (authorization == null) return null;
    return authorization.authClient(scopes: _scopes);
  }
}
