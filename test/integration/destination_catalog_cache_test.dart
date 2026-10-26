import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/integration/api/api_client.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';

class CatalogApi extends ApiClient {
  int calls = 0;
  final first = Completer<dynamic>();
  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) {
    expect(endpoint, '/destinations');
    calls++;
    if (calls == 1) return first.future;
    return Future.value({
      'data': [
        {'destination_id': 'nuevo', 'destination': 'Destino nuevo'},
      ],
    });
  }
}

void main() {
  test(
    'catalog requests share the pending fetch and refresh gets new data',
    () async {
      final api = CatalogApi();
      final service = DestinationService(apiClient: api);
      final first = service.getDestinations();
      final second = service.getDestinations();
      expect(api.calls, 1);
      api.first.complete({
        'data': [
          {'destination_id': 'anterior', 'destination': 'Destino anterior'},
        ],
      });
      expect((await first).single.id, 'anterior');
      expect((await second).single.id, 'anterior');
      expect((await service.getDestinations()).single.id, 'anterior');
      expect(api.calls, 1);
      service.invalidateDestinationCatalog();
      expect((await service.getDestinations()).single.id, 'nuevo');
      expect(api.calls, 2);
    },
  );
}
