import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';

PreferredSizeWidget profilePageBar(
  BuildContext context,
  String title, {
  bool busy = false,
  VoidCallback? onBack,
  List<Widget>? actions,
}) => AppBar(
  backgroundColor: AppColors.background,
  foregroundColor: AppColors.textPrimary,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: true,
  toolbarHeight: 68,
  leadingWidth: 64,
  leading: Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Center(
      child: IconButton.filledTonal(
        tooltip: 'Volver',
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
        ),
        onPressed: busy
            ? null
            : onBack ??
                  () => context.canPop() ? context.pop() : context.go('/main'),
        icon: const RotatedBox(
          quarterTurns: 2,
          child: AppIcon(
            AppIcons.chevronRight,
            size: 21,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ),
  ),
  title: Text(
    title,
    style: const TextStyle(
      fontFamily: 'Outfit',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  ),
  actions: actions,
);
