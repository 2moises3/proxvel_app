import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/visit_controller.dart';
import 'package:proxvell_app/integration/services/visit_service.dart';
import 'package:proxvell_app/models/visit_model.dart';

class _Visits extends VisitService {
  Future<VisitModel?> response = Future.value(null);

  @override
  Future<VisitModel?> getActiveVisit() => response;
}

void main() {
  test(
    'a network failure preserves the active visit and a late poll cannot restore it after sign-out',
    () async {
      final visit = VisitModel(
        visitId: 'visit-1',
        destinationId: 'destination-1',
        visitStatus: 'in_progress',
      );
      final service = _Visits();
      final controller = VisitController(service);
      addTearDown(controller.dispose);

      service.response = Future.value(visit);
      await controller.checkActiveVisit();
      expect(controller.activeVisit, visit);

      service.response = Future.error(StateError('offline'));
      await controller.checkActiveVisit();
      expect(controller.activeVisit, visit);

      final pending = Completer<VisitModel?>();
      service.response = pending.future;
      final request = controller.checkActiveVisit();
      controller.clearSession();
      pending.complete(visit);
      await request;
      expect(controller.activeVisit, isNull);
    },
  );
}
