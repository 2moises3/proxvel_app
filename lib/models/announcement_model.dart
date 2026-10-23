/// Anuncio interno publicado desde el dashboard admin.
/// Mapea la vista pública del backend (GET /announcements/active),
/// que NO expone campos internos (audience, métricas, autor).
class AnnouncementModel {
  final int id;
  final String title;
  final String message;

  /// app_start | home_top | destination_detail | global_modal
  final String placement;

  /// image_banner | gradient_card | minimal_notice | tourism_highlight | maintenance_notice
  final String templateType;
  final String? backgroundImageUrl;
  final String? ctaText;

  /// Ruta interna ("/destination/machu_picchu", "/search", ...) o enlace https.
  final String? ctaUrl;

  /// Solo para destination_detail: destino al que apunta (null = todos).
  final String? targetDestinationId;

  /// Segundos antes de pasar al siguiente en el carrusel.
  final int durationSeconds;
  final int priority;

  /// Máximo de veces que este dispositivo ve el anuncio de inicio. null o 0 = sin límite.
  final int? frequencyCap;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.placement,
    required this.templateType,
    this.backgroundImageUrl,
    this.ctaText,
    this.ctaUrl,
    this.targetDestinationId,
    this.durationSeconds = 6,
    this.priority = 0,
    this.frequencyCap,
  });

  factory AnnouncementModel.fromApiJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      placement: (json['placement'] ?? 'home_top') as String,
      templateType: (json['template_type'] ?? 'gradient_card') as String,
      backgroundImageUrl: json['background_image_url'] as String?,
      ctaText: json['cta_text'] as String?,
      ctaUrl: json['cta_url'] as String?,
      targetDestinationId: json['target_destination_id'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 6,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      frequencyCap: (json['frequency_cap'] as num?)?.toInt(),
    );
  }

  /// Un anuncio solo es presentable si tiene contenido textual real.
  bool get hasContent => title.trim().isNotEmpty && message.trim().isNotEmpty;

  /// Tiene botón con una acción que la app sabe abrir.
  bool get hasAction {
    final url = (ctaUrl ?? '').trim();
    return (ctaText ?? '').trim().isNotEmpty &&
        (url.startsWith('/') || url.startsWith('https://'));
  }

  bool get hasImage => (backgroundImageUrl ?? '').startsWith('http');
}
