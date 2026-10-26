import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/controllers/auth_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/local/secure_token_storage.dart';
import 'package:proxvell_app/integration/services/user_service.dart';
import 'package:proxvell_app/models/user_model.dart';

class PhotoService extends UserService {
  final result = Completer<String>();
  @override
  Future<String> uploadAvatar({
    required String userId,
    String? filePath,
    List<int>? fileBytes,
    String? filename,
  }) => result.future;
}

void main() {
  late LocalStorageService storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
    await storage.init();
    await storage.saveUser(
      UserModel(id: 'a', name: 'Ana', email: 'a@example.com'),
    );
  });
  test(
    'avatar persists backend URL and preserves latest profile values',
    () async {
      final service = PhotoService();
      final auth = AuthController(storage, SecureTokenStorage(), service);
      final saving = auth.uploadAvatar(fileBytes: [1], filename: 'photo.jpg');
      await storage.saveUser(
        UserModel(
          id: 'a',
          name: 'Ana María',
          email: 'a@example.com',
          acceptedTermsVersion: '1.0',
          residenceCity: 'Lima',
        ),
      );
      service.result.complete('https://example.com/photo.jpg');
      await saving;
      expect(storage.getUser()!.avatarUrl, 'https://example.com/photo.jpg');
      expect(storage.getUser()!.name, 'Ana María');
      expect(storage.getUser()!.acceptedTermsVersion, '1.0');
      auth.dispose();
    },
  );
  test('late avatar never overwrites another account', () async {
    final service = PhotoService();
    final auth = AuthController(storage, SecureTokenStorage(), service);
    final saving = auth.uploadAvatar(fileBytes: [1]);
    final assertion = expectLater(saving, throwsStateError);
    await storage.saveUser(
      UserModel(id: 'b', name: 'Bea', email: 'b@example.com'),
    );
    service.result.complete('https://example.com/photo.jpg');
    await assertion;
    expect(storage.getUser()!.id, 'b');
    expect(storage.getUser()!.avatarUrl, isNull);
    auth.dispose();
  });
  test('missing service does not report successful local-only edits', () async {
    final auth = AuthController(storage, SecureTokenStorage());
    await expectLater(auth.uploadAvatar(fileBytes: [1]), throwsStateError);
    await expectLater(
      auth.updateUserProfile(
        name: 'Different',
        lastName: '',
        email: 'a@example.com',
      ),
      throwsStateError,
    );
    expect(storage.getUser()!.name, 'Ana');
    auth.dispose();
  });
  test('invalid or failed upload preserves original photo', () async {
    final service = PhotoService();
    final auth = AuthController(storage, SecureTokenStorage(), service);
    final saving = auth.uploadAvatar(fileBytes: [1]);
    final assertion = expectLater(saving, throwsStateError);
    service.result.complete('');
    await assertion;
    expect(storage.getUser()!.avatarUrl, isNull);
    auth.dispose();
  });
}
