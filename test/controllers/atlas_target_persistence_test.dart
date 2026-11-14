import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/controllers/visit_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/visit_service.dart';
import 'package:proxvell_app/models/user_model.dart';
import 'package:proxvell_app/models/visit_model.dart';

class _Visits extends VisitService {
  @override
  Future<VisitModel?> getActiveVisit() async => null;
  @override
  Future<AtlasSummaryModel> getAtlas() async =>
      AtlasSummaryModel(totalVerifiedVisits: 0, regionsVisited: 0, visits: []);
}

void main() {
  test('restores a selected Atlas target only for the same user', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.init();
    await storage.saveUser(
      UserModel(id: 'u1', name: 'Ana', email: 'a@example.com'),
    );
    final first = VisitController(_Visits(), storage);
    first.setPendingDestination(
      PendingSealDestination(
        destinationId: 'place',
        destinationName: 'Lugar',
        latitude: -12,
        longitude: -77,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    final restored = VisitController(_Visits(), storage);
    await restored.initVisitState();
    expect(restored.pendingDestination?.destinationId, 'place');
    restored.dispose();

    await storage.saveUser(
      UserModel(id: 'u2', name: 'Luis', email: 'b@example.com'),
    );
    final other = VisitController(_Visits(), storage);
    await other.initVisitState();
    expect(other.pendingDestination, isNull);
    other.dispose();
  });
}
