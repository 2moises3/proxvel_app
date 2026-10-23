import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/search_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/seasonality_model.dart';

DestinationModel d(String id, String name,
        {String region = 'Lima', String category = 'Arqueología', String? cost}) =>
    DestinationModel(
      id: id,
      name: name,
      city: '',
      region: region,
      category: category,
      description: '',
      imageUrl: '',
      averageCost: 0,
      climate: '',
      crowdLevel: '',
      rating: 0,
      aspects: const [],
      costLevel: cost,
    );

class FakeDestinationService extends DestinationService {
  final List<DestinationModel> all;
  final Map<String, MonthContext> context;
  final Map<String, RankingInfo> ranking;
  final Map<String, String> tourismText;
  bool failContext = false;

  FakeDestinationService(this.all, {
    this.context = const {},
    this.ranking = const {},
    this.tourismText = const {},
  });

  @override
  Future<List<DestinationModel>> getDestinations() async => all;

  @override
  Future<Map<String, MonthContext>> getMonthContext(int month) async {
    if (failContext) throw Exception('sin red');
    return context;
  }

  @override
  Future<RankingInfo?> getRankingInfo(String destinationId, {int? month}) async => ranking[destinationId];

  @override
  Future<Map<String, String>> getTourismSearchIndex() async => tourismText;
}

class FakeStorage extends LocalStorageService {
  final List<String> saved = [];
  @override
  Future<void> addRecentSearch(String query) async => saved.add(query);
}

MonthContext ctx(String id, {double seco = 0, String aforo = 'Medio'}) => MonthContext(
      destinationId: id,
      month: 7,
      climaPorPreferencia: {'seco': seco},
      aforoNivel: aforo,
    );

void main() {
  final destinos = [
    d('nazca', 'Líneas de Nasca', region: 'Ica', cost: 'alto'),
    d('chan', 'Chan Chan', region: 'La Libertad', cost: 'bajo'),
    d('colca', 'Valle del Colca', region: 'Arequipa', category: 'Naturaleza', cost: 'medio'),
  ];

  test('la búsqueda ignora tildes y mayúsculas', () {
    expect(normalizeForSearch('  Líneas de NASCA '), 'lineas de nasca');
    expect(normalizeForSearch('Cañón'), 'canon');
  });

  test('busca por texto sin tildes y guarda la búsqueda una sola vez', () async {
    final storage = FakeStorage();
    final c = SearchController(FakeDestinationService(destinos), storage);
    await c.search(newFilters: const SearchFilters(query: 'lineas'));
    expect(c.results.map((r) => r.destination.id), ['nazca']);
    expect(storage.saved, ['lineas']);
  });

  test('encuentra actividades del catálogo turístico sin inventar datos', () async {
    final c = SearchController(
      FakeDestinationService(destinos, tourismText: {
        'colca': 'Caminata y observación de cóndores',
      }),
      FakeStorage(),
    );
    await c.search(newFilters: const SearchFilters(query: 'condores'));
    expect(c.results.map((r) => r.destination.id), ['colca']);
  });

  test('filtros de región, categoría y costo; opciones salen de los datos', () async {
    final c = SearchController(FakeDestinationService(destinos), FakeStorage());
    await c.search(newFilters: const SearchFilters(costLevel: 'bajo'));
    expect(c.results.map((r) => r.destination.id), ['chan']);
    await c.search(newFilters: const SearchFilters(category: 'Naturaleza'));
    expect(c.results.map((r) => r.destination.id), ['colca']);
    expect(c.availableRegions, ['Arequipa', 'Ica', 'La Libertad']);
    expect(c.availableCostLevels, ['bajo', 'medio', 'alto']);
  });

  test('clima favorable (>= 0.70) y afluencia del mes según la tesis', () async {
    final svc = FakeDestinationService(destinos, context: {
      'nazca': ctx('nazca', seco: 0.9, aforo: 'Bajo'),
      'chan': ctx('chan', seco: 0.5, aforo: 'Bajo'),
      // colca sin datos del mes: no se puede afirmar nada, queda fuera
    });
    final c = SearchController(svc, FakeStorage());
    await c.search(newFilters: const SearchFilters(climate: 'seco', month: 7));
    expect(c.results.map((r) => r.destination.id), ['nazca']);
    await c.search(newFilters: const SearchFilters(crowd: 'Bajo', month: 7));
    expect(c.results.map((r) => r.destination.id), ['chan', 'nazca']);
  });

  test('si falla el contexto del mes se avisa', () async {
    final svc = FakeDestinationService(destinos)..failContext = true;
    final c = SearchController(svc, FakeStorage());
    await c.search(newFilters: const SearchFilters(climate: 'seco'));
    expect(c.contextError, isNotNull);
    expect(c.error, isNotNull);
    expect(c.results, isEmpty,
        reason: 'No debe mostrar resultados sin aplicar el filtro solicitado');
  });

  test('orden IA usa contexto aunque la afinidad tenga otro orden; sin perfil avisa', () async {
    final svc = FakeDestinationService(destinos, ranking: {
      'colca': const RankingInfo(percent: 40, score: .9, label: 'Recomendado'),
      'chan': const RankingInfo(percent: 90, score: .4, label: 'Parcialmente recomendado'),
    });
    final c = SearchController(svc, FakeStorage());
    await c.search(aiSort: true, hasProfile: true);
    expect(c.results.map((r) => r.destination.id), ['colca', 'chan', 'nazca']);
    expect(c.results.last.compatibility, isNull, reason: 'fuera del motor: sin porcentaje inventado');

    await c.search(aiSort: true, hasProfile: false);
    expect(c.aiBlockedNoProfile, isTrue);
    expect(c.results.map((r) => r.destination.id), ['chan', 'nazca', 'colca']);
  });

  test('contador de filtros activos', () {
    const f = SearchFilters(region: 'Ica', costLevel: 'bajo', climate: 'seco');
    expect(f.activeFilterCount, 3);
    expect(f.copyWith(clearRegion: true).activeFilterCount, 2);
    expect(const SearchFilters(query: 'x').hasActiveFilters, isFalse);
  });
}
