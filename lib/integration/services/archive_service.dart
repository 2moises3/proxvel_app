import '../../models/archive_model.dart';
import '../api/api_client.dart';

class ArchiveService {
  final ApiClient _apiClient;

  ArchiveService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<ArchiveModel>> getArchives() async {
    try {
      final response = await _apiClient.get('/archives');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ArchiveModel.fromJson(json)).toList();
      }
      throw StateError('El servidor no confirmó la lista de archivados.');
    } catch (e) {
      throw Exception('Error al cargar archivados: $e');
    }
  }

  Future<bool> addArchive(String destinationId) async {
    try {
      final response = await _apiClient.post('/archives/$destinationId');
      if (response['success'] == true) {
        return response['data']['is_archived'] == true;
      }
      throw Exception(response['message'] ?? 'Error desconocido');
    } catch (e) {
      throw Exception('Error al archivar destino: $e');
    }
  }

  Future<bool> removeArchive(String destinationId) async {
    try {
      final response = await _apiClient.delete('/archives/$destinationId');
      if (response['success'] == true) {
        return true;
      }
      throw Exception(response['message'] ?? 'Error desconocido');
    } catch (e) {
      throw Exception('Error al desarchivar destino: $e');
    }
  }

  Future<bool> checkArchive(String destinationId) async {
    try {
      final response = await _apiClient.get('/archives/check/$destinationId');
      if (response['success'] == true) {
        return response['data']['is_archived'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class FavoriteModel {
  final String destinationId;
  final String name;
  final String? city;
  final String? region;
  final String? category;
  final String? coverImageUrl;
  final double? rating;
  final bool isFavorite;
  final DateTime? createdAt;

  FavoriteModel({
    required this.destinationId,
    required this.name,
    this.city,
    this.region,
    this.category,
    this.coverImageUrl,
    this.rating,
    this.isFavorite = true,
    this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      destinationId: json['destination_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      region: json['region'],
      category: json['category'],
      coverImageUrl: json['cover_image_url'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      isFavorite: json['is_favorite'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination_id': destinationId,
      'name': name,
      'city': city,
      'region': region,
      'category': category,
      'cover_image_url': coverImageUrl,
      'rating': rating,
      'is_favorite': isFavorite,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
