import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/announcement_controller.dart';
import 'package:proxvell_app/integration/local/announcement_seen_store.dart';
import 'package:proxvell_app/integration/services/announcement_service.dart';
import 'package:proxvell_app/models/announcement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio falso: devuelve anuncios por ubicación y guarda los eventos reportados.
class FakeAnnouncementService extends AnnouncementService {
  final Map<String, List<AnnouncementModel>> byPlacement;
  final List<String> events = [];
  int calls = 0;

  FakeAnnouncementService(this.byPlacement);

  @override
  Future<List<AnnouncementModel>> getActive({String placement = 'home_top', String? destinationId}) async {
    calls++;
    return (byPlacement[placement] ?? const [])
        .where((a) => destinationId == null || a.targetDestinationId == null || a.targetDestinationId == destinationId)
        .toList();
  }

  @override
  Future<void> reportEvent(int announcementId, String event) async {
    events.add('$announcementId:$event');
  }
}

AnnouncementModel ann(int id, String placement, {int? cap, String? target}) => AnnouncementModel(
      id: id,
      title: 'Anuncio $id',
      message: 'Mensaje',
      placement: placement,
      templateType: 'gradient_card',
      frequencyCap: cap,
      targetDestinationId: target,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el anuncio de inicio respeta el límite de veces entre sesiones', () async {
    final svc = FakeAnnouncementService({'app_start': [ann(1, 'app_start', cap: 1)]});

    final s1 = AnnouncementController(svc, store: AnnouncementSeenStore());
    final first = await s1.pickStartAnnouncement();
    expect(first?.id, 1);
    s1.markViewed(first!);
    expect(await s1.pickStartAnnouncement(), isNull, reason: 'una ventana por sesión');
    await Future<void>.delayed(Duration.zero);

    // Nueva sesión (app reabierta): ya llegó a su límite.
    final s2 = AnnouncementController(svc, store: AnnouncementSeenStore());
    expect(await s2.pickStartAnnouncement(), isNull);
  });

  test('límite 0 = se muestra en cada sesión', () async {
    final svc = FakeAnnouncementService({'app_start': [ann(2, 'app_start', cap: 0)]});
    for (var i = 0; i < 3; i++) {
      final c = AnnouncementController(svc, store: AnnouncementSeenStore());
      final a = await c.pickStartAnnouncement();
      expect(a?.id, 2);
      c.markViewed(a!);
      await Future<void>.delayed(Duration.zero);
    }
  });

  test('el aviso importante va antes que la promo y vuelve hasta confirmarlo', () async {
    final svc = FakeAnnouncementService({
      'global_modal': [ann(3, 'global_modal')],
      'app_start': [ann(4, 'app_start', cap: 5)],
    });
    final c1 = AnnouncementController(svc, store: AnnouncementSeenStore());
    final a = await c1.pickStartAnnouncement();
    expect(a?.id, 3);
    c1.markViewed(a!);
    await Future<void>.delayed(Duration.zero);

    // No lo confirmó: vuelve en la siguiente sesión.
    final c2 = AnnouncementController(svc, store: AnnouncementSeenStore());
    final again = await c2.pickStartAnnouncement();
    expect(again?.id, 3);
    c2.dismiss(again!); // «Entendido»
    await Future<void>.delayed(Duration.zero);

    final c3 = AnnouncementController(svc, store: AnnouncementSeenStore());
    expect((await c3.pickStartAnnouncement())?.id, 4, reason: 'ya confirmado: sale la promo');
  });

  test('un banner cerrado no vuelve a aparecer', () async {
    final svc = FakeAnnouncementService({'home_top': [ann(5, 'home_top'), ann(6, 'home_top')]});
    final c1 = AnnouncementController(svc, store: AnnouncementSeenStore());
    await c1.load(placement: 'home_top');
    expect(c1.visibleFor('home_top').map((a) => a.id), [5, 6]);
    c1.dismiss(c1.visibleFor('home_top').first);
    expect(c1.visibleFor('home_top').map((a) => a.id), [6]);
    await Future<void>.delayed(Duration.zero);

    final c2 = AnnouncementController(svc, store: AnnouncementSeenStore());
    await c2.load(placement: 'home_top');
    expect(c2.visibleFor('home_top').map((a) => a.id), [6]);
  });

  test('anuncios del detalle se separan por destino', () async {
    final svc = FakeAnnouncementService({
      'destination_detail': [ann(7, 'destination_detail', target: 'chan_chan'), ann(8, 'destination_detail')],
    });
    final c = AnnouncementController(svc, store: AnnouncementSeenStore());
    await c.load(placement: 'destination_detail', destinationId: 'chan_chan');
    await c.load(placement: 'destination_detail', destinationId: 'machu_picchu');
    expect(c.visibleFor('destination_detail', destinationId: 'chan_chan').map((a) => a.id), [7, 8]);
    expect(c.visibleFor('destination_detail', destinationId: 'machu_picchu').map((a) => a.id), [8]);
  });

  test('una vista por sesión, clics y cierres se reportan', () async {
    final svc = FakeAnnouncementService({'home_top': [ann(9, 'home_top')]});
    final c = AnnouncementController(svc, store: AnnouncementSeenStore());
    await c.load(placement: 'home_top');
    final a = c.visibleFor('home_top').first;
    c.markViewed(a);
    c.markViewed(a); // el carrusel vuelve a pasar por él
    c.markClicked(a);
    c.dismiss(a);
    expect(svc.events, ['9:impression', '9:click', '9:dismiss']);
  });

  test('no recarga en cada rebuild, pero sí al refrescar', () async {
    final svc = FakeAnnouncementService({'home_top': [ann(10, 'home_top')]});
    final c = AnnouncementController(svc, store: AnnouncementSeenStore());
    await c.load(placement: 'home_top');
    await c.load(placement: 'home_top');
    expect(svc.calls, 1);
    await c.refresh(placement: 'home_top');
    expect(svc.calls, 2);
  });
}
