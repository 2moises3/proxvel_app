import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proxvell_app/controllers/auth_controller.dart';
import 'package:proxvell_app/controllers/feedback_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/local/secure_token_storage.dart';
import 'package:proxvell_app/integration/services/feedback_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/feedback_model.dart';
import 'package:proxvell_app/models/user_model.dart';
import 'package:proxvell_app/views/feedback/feedback_screen.dart';
import 'package:proxvell_app/views/onboarding/onboarding_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReviewService extends FeedbackService {
  _ReviewService(super.storage);
  bool fail = true;

  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {
    if (fail) throw StateError('offline');
  }
}

void main() {
  late LocalStorageService storage;
  late AuthController auth;
  late _ReviewService reviews;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
    await storage.init();
    await storage.saveUser(
      UserModel(id: 'a', name: 'Ana', email: 'ana@example.test'),
    );
    auth = AuthController(storage, SecureTokenStorage());
    reviews = _ReviewService(storage);
    addTearDown(auth.dispose);
  });

  Widget host(Widget child) => MultiProvider(
    providers: [
      Provider.value(value: storage),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => FeedbackController(reviews)),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets(
    'reviews resume by destination, survive a failed send and clear after publishing',
    (tester) async {
      await storage.writeDraft('review_draft:a:place', {
        'rating': 4,
        'comment': 'Beautiful site',
      });
      final place = DestinationModel(
        id: 'place',
        name: 'Place',
        city: '',
        region: '',
        category: '',
        description: '',
        imageUrl: '',
        averageCost: 0,
        climate: '',
        crowdLevel: '',
        rating: 0,
        aspects: const [],
      );
      await tester.pumpWidget(
        host(FeedbackScreen(destinationId: 'place', openingDestination: place)),
      );
      await tester.pump();
      expect(find.text('Recuperamos tu borrador'), findsOneWidget);
      expect(find.text('Beautiful site'), findsOneWidget);
      final publish = find.text('Publicar reseña');
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(storage.readDraft('review_draft:a:place')?['rating'], 4);
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .clearSnackBars();
      await tester.pumpAndSettle();
      reviews.fail = false;
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(storage.readDraft('review_draft:a:place'), isNull);
    },
  );

  testWidgets('traveler onboarding resumes the saved step and its answers', (
    tester,
  ) async {
    await storage.writeDraft('onboarding_draft:a', {
      'page': 2,
      'style': 'aventurero',
      'budget': 'Medio',
      'days': 4,
    });
    await tester.pumpWidget(host(const OnboardingProfileScreen()));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('2 de 5'), findsOneWidget);
    expect(find.text('4 días'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 de 5'), findsOneWidget);
    expect(storage.readDraft('onboarding_draft:a')?['page'], 1);
    expect(storage.readDraft('onboarding_draft:a')?['days'], 4);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
