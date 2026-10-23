import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/my_reviews_controller.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/my_review_card.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<MyReviewsController>().loadUserReviews(auth.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyReviewsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mis reseñas',
          style: AppTextStyles.sectionTitle,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(MyReviewsController controller) {
    if (controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: AppSpace.field),
            Text(
              'Cargando tus reseñas...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: AppSpace.field),
              Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.section),
              ElevatedButton(
                onPressed: () {
                  final auth = context.read<AuthController>();
                  context.read<MyReviewsController>().loadUserReviews(
                    auth.currentUser,
                  );
                },
                child: const Text(
                  'Reintentar',
                  style: AppTextStyles.button,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rate_review_outlined,
                color: AppColors.textMuted,
                size: 56,
              ),
              const SizedBox(height: AppSpace.field),
              const Text(
                'Aún no has enviado reseñas.\nCuando comentes un destino, aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: controller.reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpace.field),
      itemBuilder: (context, index) {
        return MyReviewCard(review: controller.reviews[index]);
      },
    );
  }
}
