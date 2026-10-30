import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/visit_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/widgets/maps/destination_location.dart';
import 'widgets/atlas_passport_section.dart';
import 'widgets/profile_page_bar.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitController>().initVisitState();
      DestinationLocation.shared.locate(requestPermission: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visit = context.watch<VisitController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, 'Atlas de visitas'),
      body: RefreshIndicator(
        onRefresh: visit.initVisitState,
        child: ListView(
          padding: EdgeInsets.only(
            top: AppSpace.section,
            bottom: 32 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (visit.isLoading)
              const LinearProgressIndicator(color: AppColors.accent),
            if (visit.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.section,
                ),
                child: Text(
                  visit.error!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const AtlasPassportSection(),
          ],
        ),
      ),
    );
  }
}
