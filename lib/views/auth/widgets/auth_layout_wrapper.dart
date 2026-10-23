import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/images/proxvel_enhanced_image.dart';

class AuthLayoutWrapper extends StatelessWidget {
  final Widget? topBadge;
  final Widget titleWidget;
  final String? subtitle;
  final Widget content;
  final bool showBackButton;
  final bool expandContent;
  final bool cropImageToTop;
  final String backgroundImagePath;

  const AuthLayoutWrapper({
    super.key,
    this.topBadge,
    required this.titleWidget,
    this.subtitle,
    required this.content,
    this.showBackButton = true,
    this.expandContent = false,
    this.cropImageToTop = false,
    this.backgroundImagePath = 'assets/images/background_machu_picchu.png',
  });

  @override
  Widget build(BuildContext context) {
    // Ensure status bar is transparent with light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Build the white card widget
    final whiteCard = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 28.0, 24.0, 16.0),
          child: content,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          if (cropImageToTop)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.50,
              child: ProxvelEnhancedImage(
                imagePath: backgroundImagePath,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            )
          else
            Positioned.fill(
              child: ProxvelEnhancedImage(
                imagePath: backgroundImagePath,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),

          // Main Content Layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: showBackButton
                        ? InkWell(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        : topBadge,
                  ),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpace.related),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.section),
                  ],
                ),
              ),

              // Bottom White Sheet
              if (expandContent)
                Expanded(flex: 5, child: whiteCard)
              else
                whiteCard,
            ],
          ),
        ],
      ),
    );
  }
}
