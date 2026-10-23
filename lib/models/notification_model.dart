class AppNotification {
  final String id; // 'n-12' (personal) o 'a-5' (anuncio)
  final String type; // 'personal' | 'announcement'
  final String kind; // perfil_listo | mejor_mes | destino_nuevo | seguridad | anuncio
  final String title;
  final String body;
  final String? imageUrl;

  /// Ruta interna de la app a la que lleva (null = no navega).
  final String? route;
  final String? ctaText;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imageUrl,
    this.route,
    this.ctaText,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? 'personal') as String,
      kind: (json['kind'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      route: json['route'] as String?,
      ctaText: json['cta_text'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '') as String)?.toLocal() ??
              DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        kind: kind,
        title: title,
        body: body,
        imageUrl: imageUrl,
        route: route,
        ctaText: ctaText,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  /// «ahora», «hace 5 min», «hace 3 h», «ayer», «hace 4 días», «12 oct».
  String timeAgo([DateTime? now]) {
    final diff = (now ?? DateTime.now()).difference(createdAt);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }
}
