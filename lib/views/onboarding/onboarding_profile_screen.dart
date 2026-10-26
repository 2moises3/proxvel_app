import '../../core/constants/preference_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/preference_choice.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/constants/traveler_vocabulary.dart';
import '../../core/navigation/home_entry_coordinator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/traveler_profile_model.dart';
import '../../models/traveler_types.dart';
import '../auth/widgets/auth_form_page.dart';
import 'widgets/illustrated_preference_option.dart';
import 'widgets/travel_style_option.dart';
import 'widgets/profile_completion_view.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF626870);
const _paper = Color(0xFFFAFAF8);
const _line = Color(0xFFE7E7E4);
const _backpack = 'assets/images/onboarding_backpack_peru.png';
const _climates = 'assets/images/onboarding_climates_peru.png';
const _crowds = 'assets/images/onboarding_crowds_peru.png';
const _interestsArt = 'assets/images/onboarding_interests_peru.png';

/// La introducción y cinco decisiones del perfil viajero.
class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingProfileScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pages = PageController();
  late final AnimationController _float;
  int _page =
      0; // 0=introducción, 1=estilo, 2=presupuesto, 3=clima, 4=multitudes, 5=intereses.

  String? _travelerType;
  String? _budget;
  int _days = 1;
  String? _climate;
  String? _comfort;
  final Set<String> _interests = {};

  bool _saving = false;
  bool _done = false;
  bool _enteringHome = false;

  bool get _canProceed => switch (_page) {
    0 => true,
    1 => _travelerType != null,
    2 => _budget != null,
    3 => _climate != null,
    4 => _comfort != null,
    5 => _interests.isNotEmpty,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  void _moveTo(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _page = index);
  }

  void _next() {
    if (!_canProceed || _saving) return;
    if (_page < 5) {
      _moveTo(_page + 1);
    } else {
      _saveAndComplete();
    }
  }

  void _previous() {
    if (_page > 0 && !_saving) _moveTo(_page - 1);
  }

  Future<void> _saveAndComplete() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No encontramos tu sesión. Vuelve a iniciar sesión.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final selectedInterests = _interests.toList();
    final profile = TravelerProfileModel(
      perfilTuristico: _travelerType,
      presupuesto: _budget?.toLowerCase() ?? 'medio',
      diasViaje: _days,
      climaPreferido: _climate?.toLowerCase() ?? 'templado',
      tipoInteres: selectedInterests.length == 1
          ? selectedInterests.first.toLowerCase()
          : 'mixto',
      intereses: selectedInterests
          .map((interest) => interest.toLowerCase())
          .toList(),
      toleranciaMultitudes: TravelerVocabulary.crowdToleranceValue(
        _comfort ?? 'Media',
      ),
    );

    final saved = await context.read<OnboardingController>().saveProfile(
      profile,
      user.id,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
      final error = context.read<OnboardingController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'No pudimos guardar tus preferencias. Intenta otra vez.',
          ),
        ),
      );
      return;
    }

    final recommendations = context.read<RecommendationController>();
    recommendations.invalidate();
    recommendations.loadRecommendations(forceRefresh: true);
    setState(() => _done = true);
  }

  @override
  void dispose() {
    _pages.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _completionView();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  if (_page > 0) _progressHeader(),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _introView(),
                        _styleView(),
                        _budgetView(),
                        _climateView(),
                        _crowdView(),
                        _interestsView(),
                      ],
                    ),
                  ),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
    child: Row(
      children: [
        IconButton.outlined(
          tooltip: 'Volver',
          onPressed: _previous,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          style: IconButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _line),
            minimumSize: const Size(44, 44),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Row(
            children: List.generate(
              5,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index < _page ? AppColors.accent : _line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$_page de 5',
          style: _text(13, color: _muted, weight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
    child: _page == 0
        ? Row(
            children: [
              Expanded(
                child: AuthSubmitButton(
                  text: 'Comenzar',
                  onPressed: _next,
                  size: AuthSubmitButtonSize.large,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: OutlinedButton(
                    onPressed: () =>
                        HomeEntryCoordinator.goToPreparedHome(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: Color(0xFFB9BDBF)),
                      shape: const StadiumBorder(),
                      textStyle: _text(14, weight: FontWeight.w600),
                    ),
                    child: const Text('Omitir por ahora', maxLines: 1),
                  ),
                ),
              ),
            ],
          )
        : AuthSubmitButton(
            size: AuthSubmitButtonSize.large,
            text: _page == 5 ? 'Guardar preferencias' : 'Continuar',
            onPressed: _canProceed ? _next : null,
            isLoading: _saving,
          ),
  );

  Widget _introView() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tu viaje empieza contigo.',
              textAlign: TextAlign.center,
              style: _text(32, weight: FontWeight.w700, height: 1.12),
            ),
            const SizedBox(height: 12),
            Text(
              'Elige lo que disfrutas y descubre destinos a tu manera.',
              textAlign: TextAlign.center,
              style: _text(16, color: _muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            _art(_backpack, height: 290),
            const SizedBox(height: 20),
            Text(
              'Son cinco pasos breves. Podrás cambiar tus preferencias después.',
              textAlign: TextAlign.center,
              style: _text(14, color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _stepPage({
    required String title,
    required String subtitle,
    required String artwork,
    required Widget body,
  }) => SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: _text(15, color: _muted, height: 1.4)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: _text(32, weight: FontWeight.w600, height: 1.15),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _art(artwork, height: 140)),
          ],
        ),
        const SizedBox(height: 20),
        body,
      ],
    ),
  );

  Widget _art(String asset, {required double height}) {
    final image = Image.asset(
      asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      cacheWidth: 640,
      excludeFromSemantics: true,
    );
    if (MediaQuery.disableAnimationsOf(context)) return image;
    return AnimatedBuilder(
      animation: _float,
      child: image,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value * 8 - 4),
        child: child,
      ),
    );
  }

  Widget _styleView() => _stepPage(
    title: 'Elige tu\nestilo de viaje',
    subtitle: '¿Qué tipo de viajero eres? Elige el estilo que más va contigo.',
    artwork: _backpack,
    body: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: travelerTypes.entries
            .map(
              (entry) => SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: TravelStyleOption(
                  label: entry.value,
                  asset: entry.key == 'economico_mochilero'
                      ? _backpack
                      : 'assets/images/onboarding_${preferenceStyleImages[entry.key]!}_scene.webp',
                  containImage: entry.key == 'economico_mochilero',
                  selected: _travelerType == entry.key,
                  onTap: () => setState(() => _travelerType = entry.key),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );

  Widget _budgetView() => _stepPage(
    title: 'Planea tu\nescapada',
    subtitle:
        '¿Cómo será tu próxima escapada? Define tu presupuesto y los días que tienes.',
    artwork: _backpack,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presupuesto aproximado',
          style: _text(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Bajo', 'Medio', 'Alto', 'Lujo']
                .map(
                  (value) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: _choice(
                      value,
                      illustration:
                          'assets/icons/${switch (value) {
                            'Bajo' => 'budget_low',
                            'Medio' => 'budget_medium',
                            'Alto' => 'budget_high',
                            _ => 'budget_luxury',
                          }}.svg',
                      illustrationLeading: true,
                      selected: _budget == value,
                      onTap: () => setState(() => _budget = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          '¿Cuántos días planeas viajar?',
          style: _text(16, weight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Quitar un día',
                onPressed: _days > 1 ? () => setState(() => _days--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '$_days ${_days == 1 ? 'día' : 'días'}',
                  textAlign: TextAlign.center,
                  style: _text(20, weight: FontWeight.w500),
                ),
              ),
              IconButton(
                tooltip: 'Añadir un día',
                onPressed: _days < 30 ? () => setState(() => _days++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _climateView() => _stepPage(
    title: 'Elige tu\nclima ideal',
    subtitle:
        '¿Con qué clima disfrutas más el viaje? Elige tu favorito o explora cualquiera.',
    artwork: _climates,
    body: Column(
      children: [
        _choice(
          'Frío',
          description: 'Temperaturas bajas y aire fresco',
          illustration: 'assets/icons/weather_ice.svg',
          selected: _climate == 'Frío',
          onTap: () => setState(() => _climate = 'Frío'),
        ),
        _gap(),
        _choice(
          'Templado',
          description: 'Temperaturas suaves',
          illustration: 'assets/icons/sun_behind_small_cloud.svg',
          selected: _climate == 'Templado',
          onTap: () => setState(() => _climate = 'Templado'),
        ),
        _gap(),
        _choice(
          'Cálido',
          description: 'Temperaturas altas',
          illustration: 'assets/icons/weather_sun.svg',
          selected: _climate == 'Cálido',
          onTap: () => setState(() => _climate = 'Cálido'),
        ),
        _gap(),
        _choice(
          'Seco',
          description: 'Poca lluvia',
          illustration: 'assets/icons/weather_dry.svg',
          selected: _climate == 'Seco',
          onTap: () => setState(() => _climate = 'Seco'),
        ),
        _gap(),
        _choice(
          'Indiferente',
          description: 'Estoy abierto a cualquier clima',
          illustration: 'assets/icons/weather_any.svg',
          selected: _climate == 'Indiferente',
          onTap: () => setState(() => _climate = 'Indiferente'),
        ),
      ],
    ),
  );

  Widget _crowdView() => _stepPage(
    title: 'Encuentra\ntu ambiente',
    subtitle:
        '¿Dónde te sientes más a gusto? Elige entre la tranquilidad y los lugares con más gente.',
    artwork: _crowds,
    body: _illustratedGrid([
      IllustratedPreferenceOption(
        label: 'Calma',
        asset: 'assets/images/onboarding_relax_scene.webp',
        description: 'Poca gente',
        selected: _comfort == 'Baja',
        onTap: () => setState(() => _comfort = 'Baja'),
      ),
      IllustratedPreferenceOption(
        label: 'Me adapto',
        asset: 'assets/images/onboarding_urban_scene.webp',
        description: 'Sin preferencia',
        selected: _comfort == 'Media',
        onTap: () => setState(() => _comfort = 'Media'),
      ),
      IllustratedPreferenceOption(
        label: 'Movimiento',
        asset: 'assets/images/onboarding_culture_scene.webp',
        description: 'Más gente',
        selected: _comfort == 'Alta',
        onTap: () => setState(() => _comfort = 'Alta'),
      ),
    ]),
  );

  Widget _interestsView() => _stepPage(
    title: 'Elige tus\nintereses',
    subtitle:
        '¿Qué te gustaría descubrir en Perú? Elige uno o varios intereses para empezar.',
    artwork: _interestsArt,
    body: _illustratedGrid(
      TravelerVocabulary.interests.map((item) {
        final selected = _interests.contains(item.label);
        return IllustratedPreferenceOption(
          label: item.label,
          asset:
              'assets/images/onboarding_${preferenceInterestImages[item.label]!}_scene.webp',
          selected: selected,
          onTap: () => setState(
            () => selected
                ? _interests.remove(item.label)
                : _interests.add(item.label),
          ),
        );
      }).toList(),
    ),
  );

  Widget _illustratedGrid(List<Widget> options) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 340 ? 3 : 2;
      const spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: 22,
        children: options
            .map((option) => SizedBox(width: width, child: option))
            .toList(),
      );
    },
  );

  Widget _gap() => const SizedBox(height: 10);

  Widget _choice(
    String label, {
    String? description,
    String? illustration,
    bool illustrationLeading = false,
    required bool selected,
    required VoidCallback onTap,
  }) => PreferenceChoice(
    label: label,
    description: description,
    illustration: illustration,
    illustrationLeading: illustrationLeading,
    selected: selected,
    onTap: onTap,
  );
  Widget _completionView() => ProfileCompletionView(
    isEntering: _enteringHome,
    onContinue: () async {
      if (_enteringHome) return;
      setState(() => _enteringHome = true);
      try {
        await HomeEntryCoordinator.goToPreparedHome(context);
      } finally {
        if (mounted) setState(() => _enteringHome = false);
      }
    },
  );

  TextStyle _text(
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => AppTypography.style(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );
}
