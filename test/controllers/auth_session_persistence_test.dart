import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/auth_controller.dart';
import 'package:proxvell_app/integration/api/api_client.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/local/secure_token_storage.dart';
import 'package:proxvell_app/integration/services/auth_service.dart';
import 'package:proxvell_app/models/auth_response_model.dart';
import 'package:proxvell_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService extends AuthService {
  SessionService() : super(apiClient: ApiClient());

  int? failure;
  final user = UserModel(id: '1', name: 'Ana', email: 'ana@example.com');

  @override
  Future<AuthLoginResponse> login({
    required String email,
    required String password,
  }) async => AuthLoginResponse(
    accessToken: 'test-token',
    tokenType: 'bearer',
    user: user,
  );

  @override
  Future<UserModel> me() async {
    final status = failure;
    if (status != null) throw ApiException(status, 'session check failed');
    return user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorageService local;
  late SecureTokenStorage secure;
  late SessionService service;
  late AuthController auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    local = LocalStorageService();
    await local.init();
    secure = SecureTokenStorage();
    service = SessionService();
    auth = AuthController(local, secure, null, service);
  });

  test(
    'a remembered session can be retried after connectivity returns',
    () async {
      expect(await auth.login(service.user.email, 'test-password'), isNull);
      expect(await SecureTokenStorage().getAccessToken(), 'test-token');

      service.failure = 0;
      await expectLater(auth.restoreSession(), throwsA(isA<ApiException>()));
      expect(await secure.getAccessToken(), 'test-token');
      expect(auth.isAuthenticated, isTrue);

      service.failure = null;
      expect(await auth.restoreSession(), isTrue);

      service.failure = 401;
      expect(await auth.restoreSession(), isFalse);
      expect(await secure.getAccessToken(), isNull);
    },
  );

  test('a temporary session is cleared on the next launch', () async {
    expect(await auth.login(service.user.email, 'test-password'), isNull);
    expect(
      await auth.login(
        service.user.email,
        'test-password',
        rememberSession: false,
      ),
      isNull,
    );
    expect(await secure.getAccessToken(), 'test-token');

    final newStorage = SecureTokenStorage();
    expect(await newStorage.getAccessToken(), isNull);
    final restarted = AuthController(local, newStorage, null, service);
    expect(await restarted.restoreSession(), isFalse);
    expect(restarted.isAuthenticated, isFalse);
    expect(restarted.currentUser, isNull);
  });
}
