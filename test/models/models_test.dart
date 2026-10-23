import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/constants/traveler_vocabulary.dart';
import 'package:proxvell_app/models/announcement_model.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/notification_model.dart';
import 'package:proxvell_app/models/seasonality_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';

void main() {
  group('TourismCatalogModel', () {
    test('lee la ficha comercial y limpia textos vacíos', () {
      final m = TourismCatalogModel.fromJson({
        'city': 'Aguas Calientes',
        'category': 'Arqueología',
        'altitude_m': 2430,
        'description': '  ',
        'how_to_get': 'Tren desde Cusco',
        'difficulty': 'moderada',
        'cost_level': 'alto',
        'official_website': 'https://tuboleto.cultura.pe',
        'latitude': -13.16,
        'longitude': -72.54,
        'interest_tags': ['historia', 'cultura', 3],
        'gallery_images': ['https://x/y.jpg', '', 'https://commons.wikimedia.org/wiki/File:a.jpg'],
      });
      expect(m.city, 'Aguas Calientes');
      expect(m.altitudeM, 2430);
      expect(m.description, isNull, reason: 'un texto solo con espacios no se muestra');
      expect(m.difficultyLabel, 'Moderada');
      expect(m.costLabel, 'Costo alto');
      expect(m.interestTags, ['historia', 'cultura']);
      expect(m.galleryImages, ['https://x/y.jpg']);
    });

    test('dificultad y costo desconocidos no se muestran', () {
      final m = TourismCatalogModel.fromJson({'difficulty': 'extrema', 'cost_level': null});
      expect(m.difficultyLabel, isNull);
      expect(m.costLabel, isNull);
      expect(m.interestTags, isEmpty);
    });
  });

  group('AnnouncementModel', () {
    test('acciones válidas e inválidas', () {
      AnnouncementModel make(String? text, String? url) => AnnouncementModel.fromApiJson({
            'id': 1,
            'title': 'T',
            'message': 'M',
            'cta_text': text,
            'cta_url': url,
          });
      expect(make('Ver', '/destination/machu_picchu').hasAction, isTrue);
      expect(make('Abrir', 'https://tuboleto.cultura.pe').hasAction, isTrue);
      expect(make('Abrir', 'http://inseguro.com').hasAction, isFalse);
      expect(make(null, '/search').hasAction, isFalse);
      expect(make('Ver', null).hasAction, isFalse);
    });

    test('lee límite de veces, destino objetivo y valores por defecto', () {
      final a = AnnouncementModel.fromApiJson({
        'id': 7,
        'title': 'Hola',
        'message': 'Mundo',
        'placement': 'destination_detail',
        'target_destination_id': 'chan_chan',
        'frequency_cap': 2,
      });
      expect(a.targetDestinationId, 'chan_chan');
      expect(a.frequencyCap, 2);
      expect(a.templateType, 'gradient_card');
      expect(a.durationSeconds, 6);
      expect(a.hasContent, isTrue);
      expect(AnnouncementModel.fromApiJson({'id': 1, 'title': ' ', 'message': 'x'}).hasContent, isFalse);
    });
  });

  group('DestinationModel', () {
    test('la portada manda y no se repite en la galería', () {
      final d = DestinationModel.fromApiDetail({
        'destination_id': 'machu_picchu',
        'destination': 'Machu Picchu',
        'cover_image_url': 'https://img/portada.jpg',
        'cost_level': 'alto',
        'tourism_info': {
          'description': 'Ciudadela inca',
          'gallery_images': ['https://img/portada.jpg', 'https://img/2.jpg', 'https://es.wikipedia.org/wiki/X'],
        },
      });
      expect(d.imageUrl, 'https://img/portada.jpg');
      expect(d.galleryImages, ['https://img/2.jpg']);
      expect(d.description, 'Ciudadela inca');
      expect(d.costLevel, 'alto');
    });

    test('sin portada usa la primera imagen de la galería', () {
      final d = DestinationModel.fromApiDetail({
        'destination_id': 'x',
        'tourism_info': {'gallery_images': ['https://img/1.jpg']},
      });
      expect(d.imageUrl, 'https://img/1.jpg');
    });

    test('isValidImageUrl rechaza páginas y valores vacíos', () {
      expect(DestinationModel.isValidImageUrl('https://res.cloudinary.com/a.jpg'), isTrue);
      expect(DestinationModel.isValidImageUrl('assets/images/a.png'), isTrue);
      expect(DestinationModel.isValidImageUrl('null'), isFalse);
      expect(DestinationModel.isValidImageUrl(''), isFalse);
      expect(DestinationModel.isValidImageUrl('https://commons.wikimedia.org/wiki/File:a.jpg'), isFalse);
    });
  });

  group('AppNotification', () {
    test('lee la notificación y marca como leída sin perder datos', () {
      final n = AppNotification.fromJson({
        'id': 'a-5',
        'type': 'announcement',
        'kind': 'anuncio',
        'title': 'Nuevo',
        'body': 'Texto',
        'route': '/destination/chan_chan',
        'created_at': '2026-10-18T10:00:00Z',
      });
      expect(n.isRead, isFalse);
      expect(n.createdAt.toUtc(), DateTime.utc(2026, 10, 18, 10));
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.route, '/destination/chan_chan');
    });
  });

  group('Estacionalidad (tesis, Fase 4)', () {
    test('favorable desde 0.70', () {
      final m = MonthContext.fromJson({
        'destination_id': 'x',
        'month': 7,
        'clima_por_preferencia': {'seco': 0.70, 'calido': 0.69, 'frio': 'malo'},
      });
      expect(m.climateFavorable('seco'), isTrue);
      expect(m.climateFavorable('calido'), isFalse);
      expect(m.climateFavorable('frio'), isFalse);
      expect(m.climaPorPreferencia.containsKey('frio'), isFalse);
    });

    test('calendario sin datos', () {
      final c = DestinationCalendar.fromJson({
        'destination_id': 'x',
        'months': [
          {'month': 1, 'has_data': false},
        ],
      });
      expect(c.hasAnyData, isFalse);
      expect(c.preference, 'indiferente');
      expect(c.tolerance, 'media');
    });
  });

  group('Vocabulario del viajero (debe coincidir con el motor)', () {
    test('13 intereses, 5 climas y 3 tolerancias', () {
      expect(TravelerVocabulary.interests.length, 13);
      expect(TravelerVocabulary.interestLabels.toSet().length, 13);
      expect(TravelerVocabulary.climates.length, 5);
      expect(TravelerVocabulary.crowdTolerances, ['Baja', 'Media', 'Alta']);
    });

    test('tolerancia se normaliza a baja/media/alta', () {
      expect(TravelerVocabulary.crowdToleranceValue('Bajo'), 'baja');
      expect(TravelerVocabulary.crowdToleranceValue(' ALTA '), 'alta');
      expect(TravelerVocabulary.crowdToleranceValue('moderado'), 'media');
      expect(TravelerVocabulary.crowdToleranceValue('???'), 'media');
    });
  });
}
