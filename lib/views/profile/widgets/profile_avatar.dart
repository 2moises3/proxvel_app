import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';

/// Shared photo surface: a failed image never leaves a broken or empty avatar.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 76,
    this.onEdit,
  });
  final String name;
  final String? url;
  final double size;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final fallback = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * .3,
          fontWeight: FontWeight.w600,
          color: AppColors.discovery,
        ),
      ),
    );
    return Semantics(
      button: onEdit != null,
      label: onEdit != null ? 'Cambiar foto de perfil' : 'Foto de perfil',
      child: Tooltip(
        message: onEdit != null ? 'Cambiar foto' : name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: ColoredBox(
                        color: AppColors.discovery.withValues(alpha: .08),
                        child: url?.trim().isNotEmpty == true
                            ? Image.network(
                                url!,
                                fit: BoxFit.cover,
                                cacheWidth: 300,
                                errorBuilder: (_, _, _) => fallback,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null ? child : fallback,
                              )
                            : fallback,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const AppIcon(
                          AppIcons.edit,
                          size: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
