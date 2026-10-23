import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/models/traveler_profile_model.dart';

void main() {
  test(
    'un perfil anterior necesita elegir estilo y no lo recibe por defecto',
    () {
      final old = TravelerProfileModel.fromApiJson({
        'intereses': ['naturaleza'],
      });
      expect(old.perfilTuristico, isNull);
      expect(old.isRecommendationReady, isFalse);
      final updated = TravelerProfileModel.fromApiJson({
        ...old.toApiJson(),
        'perfil_turistico': 'naturalista',
      });
      expect(updated.isRecommendationReady, isTrue);
      expect(
        TravelerProfileModel.fromJson(updated.toJson()).perfilTuristico,
        'naturalista',
      );
      expect(
        updated.copyWithAi(true).toApiJson()['perfil_turistico'],
        'naturalista',
      );
    },
  );
}
