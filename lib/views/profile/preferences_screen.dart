import '../onboarding/widgets/preference_choice.dart';
import 'widgets/profile_page_bar.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../core/constants/preference_art.dart';
import '../../models/traveler_types.dart';
import '../onboarding/widgets/travel_style_option.dart';
import '../onboarding/widgets/illustrated_preference_option.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../core/constants/traveler_vocabulary.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/recommendation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/traveler_profile_model.dart';
import '../../core/widgets/buttons/proxvel_button.dart';
import '../../integration/api/api_client.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isEditing = false;
  bool _ready = false;
  String _savedDraft = '';
  bool _allowExit = false;
  bool _askingToLeave = false;

  String get _draft => jsonEncode([
    _travelerType,
    _budget,
    _climate,
    _crowdTolerance,
    [..._interests]..sort(),
    _days,
    _applyAi,
  ]);
  bool get _hasChanges => _ready && _isEditing && _draft != _savedDraft;

  Future<void> _requestLeave() async {
    if (_isSaving || _askingToLeave) return;
    if (_hasChanges) {
      _askingToLeave = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Salir sin guardar?'),
          content: const Text(
            'Tus preferencias anteriores seguirán activas. Puedes quedarte para guardar los cambios.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salir sin guardar'),
            ),
          ],
        ),
      );
      _askingToLeave = false;
      if (!mounted || discard != true) return;
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }

  String? _travelerType;
  String _budget = '';
  String _climate = '';
  String _crowdTolerance = '';
  List<String> _interests = [];
  String _days = '';
  bool _applyAi = false;

  final List<String> _budgetOptions = ['Bajo', 'Medio', 'Alto', 'Lujo'];
  final List<String> _climateOptions = TravelerVocabulary.climates;
  final List<String> _crowdOptions = TravelerVocabulary.crowdTolerances;
  final List<String> _allInterests = TravelerVocabulary.interestLabels;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Si se llega aquí sin el perfil en memoria (recarga o enlace directo), se trae del
      // backend antes de mostrarlo: así nunca se edita ni se guarda sobre datos vacíos.
      if (!mounted) return;
      final ctrl = context.read<ProfileController>();
      if (ctrl.user == null || ctrl.profile == null) {
        await ctrl.loadProfileData();
      }
      if (mounted) _loadCurrentPreferences();
    });
  }

  void _loadCurrentPreferences() {
    _ready = true;
    final profile = context.read<ProfileController>().profile;
    if (profile == null) {
      setState(() {
        _travelerType = null;
        _budget = _climate = _crowdTolerance = '';
        _interests = [];
        _days = '1';
        _applyAi = false;
        _isEditing = true;
      });
    }
    if (profile != null) {
      setState(() {
        _budget = _matchOption(_budgetOptions, profile.presupuesto) ?? '';
        _climate = _matchOption(_climateOptions, profile.climaPreferido) ?? '';
        _crowdTolerance =
            _matchOption(
              _crowdOptions,
              TravelerVocabulary.crowdToleranceValue(
                profile.toleranciaMultitudes,
              ),
            ) ??
            '';

        final days = profile.diasViaje;
        _days = days.toString();

        // Intereses
        _interests = profile.intereses
            .map((i) => _matchOption(_allInterests, i))
            .where((i) => i != null)
            .cast<String>()
            .toList();

        _applyAi = profile.applyAiGlobally;
        _travelerType = profile.perfilTuristico;
        if (!profile.isRecommendationReady) _isEditing = true;
      });
    }
    _savedDraft = _draft;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  String? _matchOption(List<String> options, String backendValue) {
    final normalized = _normalize(backendValue);
    for (final opt in options) {
      final optNorm = _normalize(opt);
      if (optNorm == normalized) {
        return opt;
      }
      // Especial caso: alto/alta, bajo/baja, medio/media
      if ((optNorm == 'alta' && normalized == 'alto') ||
          (optNorm == 'baja' && normalized == 'bajo') ||
          (optNorm == 'media' && normalized == 'medio')) {
        return opt;
      }
    }
    return null;
  }

  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final existing = context.read<ProfileController>().profile;
    if (_travelerType == null ||
        _budget.isEmpty ||
        _interests.isEmpty ||
        _climate.isEmpty ||
        _crowdTolerance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa tu estilo, presupuesto, intereses, clima y tolerancia a multitudes.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tipoInteres = _interests.isEmpty
          ? 'mixto'
          : (_interests.length == 1 ? _normalize(_interests.first) : 'mixto');

      final validInterests = _interests
          .where((i) => _allInterests.contains(i))
          .map((e) => _normalize(e))
          .toList();

      final updated = TravelerProfileModel(
        perfilTuristico: _travelerType,
        presupuesto: _budget.isEmpty
            ? (existing?.presupuesto ?? '')
            : _normalize(_budget),
        diasViaje: int.tryParse(_days) ?? (existing?.diasViaje ?? 1),
        climaPreferido: _climate.isEmpty
            ? (existing?.climaPreferido ?? '')
            : _normalize(_climate),
        tipoInteres: validInterests.isEmpty
            ? (existing?.tipoInteres ?? 'mixto')
            : tipoInteres,
        intereses: validInterests,
        toleranciaMultitudes: TravelerVocabulary.crowdToleranceValue(
          _crowdTolerance.isEmpty
              ? (existing?.toleranciaMultitudes ?? '')
              : _crowdTolerance,
        ),
        // Preservar la preferencia de IA en el PUT (si no, el backend la limpiaría).
        applyAiGlobally: _applyAi,
      );

      await context.read<ProfileController>().updatePreferences(updated);

      if (mounted) {
        _loadCurrentPreferences();
        // Invalidar y recargar recomendaciones con el perfil actualizado.
        final recCtrl = context.read<RecommendationController>();
        recCtrl.invalidate();
        recCtrl.loadRecommendations(forceRefresh: true);

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preferencias actualizadas · Recalculando recomendaciones…',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String msg =
            'Hubo un problema al guardar tus preferencias. Inténtalo nuevamente.';
        if (e is ApiException && e.statusCode == 0) {
          msg =
              'No pudimos guardar tus preferencias por un problema de conexión.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else {
        _interests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowExit || (!_isSaving && !_hasChanges),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: profilePageBar(
          context,
          'Tu forma de viajar',
          busy: _isSaving,
          onBack: _requestLeave,
          actions: [
            if (_ready && !_isEditing)
              IconButton(
                tooltip: 'Editar preferencias',
                icon: const Icon(Icons.edit_rounded, color: AppColors.accent),
                onPressed: () {
                  setState(() => _isEditing = true);
                },
              ),
          ],
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : context.watch<ProfileController>().isShowingCachedProfile ||
                  context.watch<ProfileController>().error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Conéctate para cargar y editar tus preferencias actuales.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(() => _ready = false);
                          await context
                              .read<ProfileController>()
                              .loadProfileData();
                          if (mounted) _loadCurrentPreferences();
                        },
                        child: const Text('Volver a intentar'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elige lo que disfrutas. Tus preferencias nos ayudan a ordenar los destinos para ti.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),

                    _prefCard(
                      title: 'Tu estilo de viajero',
                      icon: Icons.explore_outlined,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final entry in travelerTypes.entries)
                              SizedBox(
                                width: (constraints.maxWidth - 10) / 2,
                                child: TravelStyleOption(
                                  label: entry.value,
                                  asset:
                                      preferenceStyleImages.containsKey(
                                        entry.key,
                                      )
                                      ? 'assets/images/onboarding_${preferenceStyleImages[entry.key]}_scene.webp'
                                      : 'assets/images/onboarding_backpack_peru.png',
                                  containImage: !preferenceStyleImages
                                      .containsKey(entry.key),
                                  selected: _travelerType == entry.key,
                                  onTap: _isEditing && !_isSaving
                                      ? () => setState(
                                          () => _travelerType = entry.key,
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.related),
                    // ── Switch maestro de IA ──
                    _buildAiSwitch(),
                    const SizedBox(height: AppSpace.section),

                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Presupuesto y días se guardan para planificar; no cambian el orden de las recomendaciones.',
                        style: AppTextStyles.body2,
                      ),
                    ),
                    _prefCard(
                      title: 'Presupuesto de viaje',
                      icon: Icons.account_balance_wallet_rounded,
                      child: _buildSelectionGrid(
                        _budgetOptions,
                        _budget,
                        (val) => setState(() => _budget = val),
                      ),
                    ),
                    _prefCard(
                      title: 'Días de viaje',
                      icon: Icons.calendar_month_rounded,
                      child: _buildDaysSelector(),
                    ),
                    _prefCard(
                      title: 'Clima preferido',
                      icon: Icons.thermostat_rounded,
                      child: _buildSelectionGrid(
                        _climateOptions,
                        _climate,
                        (val) => setState(() => _climate = val),
                      ),
                    ),
                    _prefCard(
                      title: 'Tolerancia a multitudes',
                      icon: Icons.groups_rounded,
                      child: _buildSelectionGrid(
                        _crowdOptions,
                        _crowdTolerance,
                        (val) => setState(() => _crowdTolerance = val),
                      ),
                    ),
                    _prefCard(
                      title: 'Tus intereses',
                      icon: Icons.favorite_rounded,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            for (final interest in _allInterests)
                              SizedBox(
                                width: (constraints.maxWidth - 12) / 2,
                                child: IllustratedPreferenceOption(
                                  label: interest,
                                  asset:
                                      'assets/images/onboarding_${preferenceInterestImages[interest]}_scene.webp',
                                  selected: _interests.contains(interest),
                                  onTap: _isEditing && !_isSaving
                                      ? () => _toggleInterest(interest)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpace.section),
                    if (_isEditing) ...[
                      ProxvelButton(
                        text: _isSaving
                            ? 'Guardando...'
                            : 'Guardar preferencias',
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: AppSpace.field),
                      ProxvelButton(
                        text: 'Cancelar',
                        isSecondary: true,
                        onPressed: _isSaving
                            ? null
                            : () {
                                _loadCurrentPreferences();
                                setState(
                                  () => _isEditing =
                                      context
                                          .read<ProfileController>()
                                          .profile ==
                                      null,
                                );
                              },
                      ),
                      const SizedBox(height: AppSpace.section),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// Tarjeta contenedora de cada sección de preferencias (diseño más cuidado).
  Widget _prefCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final summary = switch (title) {
      'Tu estilo de viajero' =>
        travelerTypes[_travelerType] ?? 'Elige tu estilo',
      'Presupuesto de viaje' => _budget.isEmpty ? 'Sin definir' : _budget,
      'Días de viaje' => '$_days días',
      'Clima preferido' => _climate.isEmpty ? 'Sin definir' : _climate,
      'Tolerancia a multitudes' =>
        _crowdTolerance.isEmpty ? 'Sin definir' : _crowdTolerance,
      _ =>
        _interests.isEmpty ? 'Elige lo que disfrutas' : _interests.join(' · '),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey('preferences/$title'),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          leading: Icon(icon, color: AppColors.discovery),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildAiSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Personalizar Explorar y búsqueda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _applyAi,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.discovery,
                onChanged: _isEditing && !_isSaving
                    ? (val) => setState(() => _applyAi = val)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Usa el orden del motor para el mes elegido. «Para ti» siempre es personalizado.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionGrid(
    List<String> options,
    String currentValue,
    Function(String) onSelect,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.asMap().entries.map((entry) {
          final opt = entry.value;
          final isSelected = opt == currentValue;
          return SizedBox(
            width: options.length.isOdd && entry.key == options.length - 1
                ? constraints.maxWidth
                : (constraints.maxWidth - 8) / 2,
            child: PreferenceChoice(
              label: opt,
              selected: isSelected,
              illustration: _choiceIllustration(opt, options),
              illustrationLeading: true,
              onTap: _isEditing && !_isSaving ? () => onSelect(opt) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  String? _choiceIllustration(String label, List<String> options) {
    final name = identical(options, _budgetOptions)
        ? const {
            'Bajo': 'budget_low',
            'Medio': 'budget_medium',
            'Alto': 'budget_high',
            'Lujo': 'budget_luxury',
          }[label]
        : const {
            'Frío': 'weather_ice',
            'Templado': 'sun_behind_small_cloud',
            'Cálido': 'weather_sun',
            'Seco': 'weather_dry',
            'Indiferente': 'weather_any',
          }[label];
    return name == null ? null : 'assets/icons/$name.svg';
  }

  Widget _buildDaysSelector() {
    final days = int.tryParse(_days) ?? 1;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: 'Un día menos',
          onPressed: _isEditing && !_isSaving && days > 1
              ? () => setState(() => _days = (days - 1).toString())
              : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Text(
            '$days ${days == 1 ? 'día' : 'días'}',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Un día más',
          onPressed: _isEditing && !_isSaving
              ? () => setState(() => _days = (days + 1).toString())
              : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
