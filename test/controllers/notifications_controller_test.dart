import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/notifications_controller.dart';
import 'package:proxvell_app/integration/services/notification_service.dart';
import 'package:proxvell_app/models/notification_model.dart';

class MockNotificationService extends NotificationService {
  NotificationFeed feedToReturn = const NotificationFeed([], 0);
  int? unreadCountToReturn = 0;
  bool shouldThrow = false;
  final List<String> markedReadIds = [];
  bool markedAllReadCalled = false;

  @override
  Future<NotificationFeed> getFeed() async {
    if (shouldThrow) throw Exception('Network error');
    return feedToReturn;
  }

  @override
  Future<int?> getUnreadCount() async {
    if (shouldThrow) return null;
    return unreadCountToReturn;
  }

  @override
  Future<void> markRead(String id) async {
    if (shouldThrow) throw Exception('Network error');
    markedReadIds.add(id);
  }

  @override
  Future<void> markAllRead() async {
    if (shouldThrow) throw Exception('Network error');
    markedAllReadCalled = true;
  }
}

void main() {
  late MockNotificationService mockService;
  late NotificationsController controller;

  setUp(() {
    mockService = MockNotificationService();
    controller = NotificationsController(mockService);
  });

  tearDown(() {
    controller.dispose();
  });

  test('Estado inicial está completamente limpio (sin notificaciones de la nada)', () {
    expect(controller.items, isEmpty);
    expect(controller.unreadCount, 0);
    expect(controller.hasUnread, isFalse);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('refreshCount actualiza el conteo solo cuando hay cambios reales', () async {
    mockService.unreadCountToReturn = 2;

    int notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.refreshCount();

    expect(controller.unreadCount, 2);
    expect(controller.hasUnread, isTrue);
    expect(notifyCount, 1);

    // Si el conteo devuelto es idéntico, NO notifica ni emite eventos redundantes
    await controller.refreshCount();
    expect(notifyCount, 1);
  });

  test('load obtiene la lista de avisos y su conteo de no leídos', () async {
    final now = DateTime.now();
    final items = <AppNotification>[
      AppNotification(
        id: 'n-1',
        type: 'personal',
        kind: 'perfil_listo',
        title: 'Tu perfil está listo',
        body: 'Ya puedes ver recomendaciones personalizadas.',
        isRead: false,
        createdAt: now,
      ),
      AppNotification(
        id: 'n-2',
        type: 'personal',
        kind: 'mejor_mes',
        title: 'Buen momento para viajar',
        body: 'Octubre es ideal para visitar Cusco.',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
    mockService.feedToReturn = NotificationFeed(items, 1);

    await controller.load();

    expect(controller.items.length, 2);
    expect(controller.unreadCount, 1);
    expect(controller.hasUnread, isTrue);
    expect(controller.error, isNull);
  });

  test('markRead marca el aviso de forma optimista e invoca al backend', () async {
    final now = DateTime.now();
    final item = AppNotification(
      id: 'n-1',
      type: 'personal',
      kind: 'destino_nuevo',
      title: 'Nuevo destino disponible',
      body: 'Descubre Caral',
      isRead: false,
      createdAt: now,
    );
    mockService.feedToReturn = NotificationFeed([item], 1);
    await controller.load();

    expect(controller.unreadCount, 1);

    await controller.markRead(item);

    expect(controller.items.first.isRead, isTrue);
    expect(controller.unreadCount, 0);
    expect(mockService.markedReadIds, contains('n-1'));
  });

  test('markAllRead limpia el punto de la campana y marca todos leídos', () async {
    final now = DateTime.now();
    final items = <AppNotification>[
      AppNotification(
        id: 'n-1',
        type: 'personal',
        kind: 'perfil_listo',
        title: 'Perfil listo',
        body: 'Detalle',
        isRead: false,
        createdAt: now,
      ),
      AppNotification(
        id: 'n-2',
        type: 'personal',
        kind: 'destino_nuevo',
        title: 'Nuevo destino',
        body: 'Detalle',
        isRead: false,
        createdAt: now,
      ),
    ];
    mockService.feedToReturn = NotificationFeed(items, 2);
    await controller.load();

    expect(controller.unreadCount, 2);

    await controller.markAllRead();

    expect(controller.unreadCount, 0);
    expect(controller.items.every((i) => i.isRead), isTrue);
    expect(mockService.markedAllReadCalled, isTrue);
  });

  test('clearState detiene el sondeo y vacía la memoria al cerrar sesión', () async {
    controller.startPolling();
    mockService.unreadCountToReturn = 5;
    await controller.refreshCount();
    expect(controller.unreadCount, 5);

    controller.clearState();

    expect(controller.unreadCount, 0);
    expect(controller.items, isEmpty);
    expect(controller.hasUnread, isFalse);
  });

  test('Si el servicio falla, maneja el error de forma segura sin romper la UI', () async {
    mockService.shouldThrow = true;
    await controller.load();

    expect(controller.error, isNotNull);
    expect(controller.isLoading, isFalse);
    expect(controller.items, isEmpty);
  });
}
