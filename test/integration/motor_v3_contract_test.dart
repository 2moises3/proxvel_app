import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/integration/api/api_client.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/services/profile_service.dart';
import 'package:proxvell_app/models/explanation_model.dart';
import 'package:proxvell_app/models/traveler_profile_model.dart';
import 'package:proxvell_app/models/user_model.dart';

class MemoryStorage extends LocalStorageService {
  String userId = 'viajero-a';
  TravelerProfileModel profile = TravelerProfileModel.fromApiJson({
    'perfil_turistico': 'naturalista',
    'intereses': ['naturaleza'],
    'clima_preferido': 'seco',
    'tolerancia_multitudes': 'baja',
  });
  @override
  UserModel getUser() =>
      UserModel(id: userId, name: 'Prueba', email: 'qa@example.test');
  @override
  TravelerProfileModel getProfile() => profile;
}

class ContractApi extends ApiClient {
  final queries = <Map<String, String>>[];
  Map<String, dynamic>? savedProfile;
  @override
  Future<dynamic> put(String endpoint, [Map<String, dynamic>? body]) async {
    savedProfile = body;
    return {'data': body};
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    expect(endpoint, '/recommendations/me');
    queries.add(Map.of(queryParams!));
    return {
      'data': [
        {
          'destination_id': 'ollantaytambo',
          'compatibility_percent': 80,
          'compatibility_score': 1.02,
          'ranking_position': 1,
          'explanation': {
            'summary': 'Referencia de prueba',
            'shap_base': 0.5,
            'shap_values': {'afinidad': 0.4, 'clima': 0.15, 'afluencia': -0.03},
            'top_aspects': [],
          },
        },
      ],
    };
  }
}

void main() {
  test('guardar preferencias envía y recupera el tipo de viajero', () async {
    final api = ContractApi();
    final storage = MemoryStorage();
    final result = await ProfileService(
      storage,
      apiClient: api,
    ).putTravelerProfile(userId: storage.userId, profile: storage.profile);
    expect(api.savedProfile!['perfil_turistico'], 'naturalista');
    expect(api.savedProfile!['clima_preferido'], 'seco');
    expect(result.perfilTuristico, 'naturalista');
  });

  test('el ranking separa la caché por perfil, usuario y mes', () async {
    final api = ContractApi();
    final storage = MemoryStorage();
    final service = DestinationService(apiClient: api, storage: storage);
    await service.getRankingInfo('ollantaytambo', month: 1);
    await service.getRankingInfo('ollantaytambo', month: 1);
    expect(api.queries.length, 1);
    storage.profile = TravelerProfileModel.fromApiJson({
      ...storage.profile.toApiJson(),
      'perfil_turistico': 'cultural',
    });
    await service.getRankingInfo('ollantaytambo', month: 1);
    expect(api.queries.length, 2);
    storage.userId = 'viajero-b';
    await service.getRankingInfo('ollantaytambo', month: 1);
    expect(api.queries.length, 3);
    await service.getRankingInfo('ollantaytambo', month: 7);
    expect(api.queries.length, 4);
    service.clearPersonalizedCache();
    await service.getRankingInfo('ollantaytambo', month: 7);
    expect(api.queries.length, 5);
    expect(api.queries.every((q) => int.parse(q['limit']!) <= 100), isTrue);
  });

  test(
    'la explicación del detalle conserva Shapley sin perder el signo',
    () async {
      final ranking = await DestinationService(
        apiClient: ContractApi(),
      ).getRankingInfo('ollantaytambo', month: 1);
      final explanation = ExplanationModel.fromJson(
        ranking!.explanation!.toJson(),
      );
      expect(explanation.shapValues['afluencia'], -0.03);
      expect(
        explanation.shapValues.keys,
        containsAll(['afinidad', 'clima', 'afluencia']),
      );
      final reconstructed = explanation.shapValues.values.fold(
        explanation.shapBase!,
        (sum, value) => sum + value,
      );
      expect(reconstructed, closeTo(ranking.score, 1e-12));
    },
  );
}
