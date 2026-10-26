import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/controllers/profile_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/profile_service.dart';
import 'package:proxvell_app/integration/services/user_service.dart';
import 'package:proxvell_app/models/traveler_profile_model.dart';
import 'package:proxvell_app/models/user_model.dart';

TravelerProfileModel preference({bool ai = false, int days = 3}) =>
    TravelerProfileModel(
      perfilTuristico: 'cultural',
      presupuesto: 'medio',
      diasViaje: days,
      climaPreferido: 'templado',
      tipoInteres: 'historia',
      intereses: ['historia'],
      toleranciaMultitudes: 'media',
      applyAiGlobally: ai,
    );

class PendingProfiles extends ProfileService {
  PendingProfiles(super.storage);
  final puts = <Completer<TravelerProfileModel>>[];
  final patches = <Completer<TravelerProfileModel>>[];
  int reads = 0;
  @override
  Future<TravelerProfileModel> getTravelerProfile(String userId) async {
    reads++;
    return preference();
  }

  @override
  Future<TravelerProfileModel> putTravelerProfile({
    required String userId,
    required TravelerProfileModel profile,
  }) {
    final request = Completer<TravelerProfileModel>();
    puts.add(request);
    return request.future;
  }

  @override
  Future<TravelerProfileModel> patchTravelerProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) {
    final request = Completer<TravelerProfileModel>();
    patches.add(request);
    return request.future;
  }
}

class PendingUser extends UserService {
  final request = Completer<UserModel>();
  @override
  Future<UserModel> getUserById(String id) => request.future;
}

void main() {
  late LocalStorageService storage;
  late PendingProfiles service;
  late ProfileController controller;
  final ana = UserModel(id: 'a', name: 'Ana', email: 'a@example.test');
  final bea = UserModel(id: 'b', name: 'Bea', email: 'b@example.test');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
    await storage.init();
    await storage.saveUser(ana);
    service = PendingProfiles(storage);
    controller = ProfileController(service, storage)
      ..user = ana
      ..profile = preference();
  });
  tearDown(() => controller.dispose());

  test(
    'PUT uses confirmed backend profile, not the optimistic draft',
    () async {
      final saving = controller.updatePreferences(preference(days: 8));
      expect(controller.profile!.diasViaje, 3);
      service.puts.single.complete(preference(days: 7));
      await saving;
      expect(controller.profile!.diasViaje, 7);
      expect(storage.getProfile()!.diasViaje, 7);
    },
  );

  test('late PUT cannot restore preferences after a session change', () async {
    final saving = controller.updatePreferences(preference(days: 8));
    final rejected = expectLater(saving, throwsStateError);
    controller.clearState();
    await storage.saveUser(bea);
    service.puts.single.complete(preference(days: 8));
    await rejected;
    expect(controller.profile, isNull);
    expect(storage.getProfile(), isNull);
    expect(storage.getUser()!.id, 'b');
  });

  test('old failed PATCH cannot roll back a newer successful choice', () async {
    final first = controller.setApplyAiGlobally(true);
    final failed = expectLater(first, throwsStateError);
    final second = controller.setApplyAiGlobally(false);
    service.patches[1].complete(preference(ai: false, days: 6));
    await second;
    service.patches[0].completeError(StateError('offline'));
    await failed;
    expect(controller.profile!.diasViaje, 6);
    expect(controller.profile!.applyAiGlobally, isFalse);
    expect(storage.getProfile()!.diasViaje, 6);
  });

  test(
    'late user load never replaces the active account or requests its old profile',
    () async {
      final users = PendingUser();
      final loadingController = ProfileController(
        service,
        storage,
        userService: users,
      );
      final loading = loadingController.loadProfileData();
      loadingController.clearState();
      await storage.saveUser(bea);
      users.request.complete(ana);
      await loading;
      expect(storage.getUser()!.id, 'b');
      expect(loadingController.user, isNull);
      expect(service.reads, 0);
      loadingController.dispose();
    },
  );
}
