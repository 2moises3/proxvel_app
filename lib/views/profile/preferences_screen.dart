import '../../core/widgets/forms/traveler_type_selector.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../core/constants/traveler_vocabulary.dart';
import 'package:go_router/go_router.dart';
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
      final ctrl = context.read<ProfileController>();
      if (ctrl.user == null || ctrl.profile == null) {
        await ctrl.loadProfileData();
      }
      if (mounted) _loadCurrentPreferences();
    });
  }

  void _loadCurrentPreferences() {
    final profile = context.read<ProfileController>().profile;
    if (profile == null) {
      setState(() => _isEditing = true);
    }
    if (profile != null) {
      setState(() {
        _budget = _matchOption(_budgetOptions, profile.presupuesto) ?? '';
        _climate = _matchOption(_climateOptions, profile.climaPreferido) ?? '';
        _crowdTolerance =
            _matchOption(_crowdOptions, profile.toleranciaMultitudes) ?? '';

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
        _interests.isEmpty ||
        _climate.isEmpty ||
        _crowdTolerance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige tu estilo, intereses, clima y tolerancia a multitudes.',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tu forma de viajar',
          style: AppTextStyles.sectionTitle,
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.accent),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
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
              child: TravelerTypeSelector(
                value: _travelerType,
                onChanged: _isEditing
                    ? (value) => setState(() => _travelerType = value)
                    : null,
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
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _allInterests
                    .map((i) => _buildInterestChip(i))
                    .toList(),
              ),
            ),

            const SizedBox(height: AppSpace.section),
            if (_isEditing) ...[
              ProxvelButton(
                text: _isSaving ? 'Guardando...' : 'Guardar Preferencias',
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
                        setState(() => _isEditing = false);
                      },
              ),
              const SizedBox(height: AppSpace.section),
            ],
          ],
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, icon),
          const SizedBox(height: 14),
          child,
        ],
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
                  'Orden IA en Explorar y búsqueda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _applyAi,
                activeThumbColor: AppColors.accent,
                onChanged: (val) async {
                  setState(() => _applyAi = val);
                  try {
                    await context.read<ProfileController>().setApplyAiGlobally(
                      val,
                    );
                  } catch (e) {
                    if (mounted) {
                      setState(() => _applyAi = !val); // revertir
                      String msg =
                          'Hubo un problema al guardar tus preferencias. Inténtalo nuevamente.';
                      if (e is ApiException && e.statusCode == 0) {
                        msg =
                            'No pudimos guardar tus preferencias por un problema de conexión.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        const SizedBox(width: AppSpace.related),
        Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
      ],
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
            child: GestureDetector(
              onTap: _isEditing ? () => onSelect(opt) : null,
              child: AnimatedContainer(
                duration: AppMotion.duration(context),
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textOnDark
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaysSelector() {
    final days = int.tryParse(_days) ?? 1;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: 'Un día menos',
          onPressed: _isEditing && days > 1
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
          onPressed: _isEditing
              ? () => setState(() => _days = (days + 1).toString())
              : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  Widget _buildInterestChip(String interest) {
    final isSelected = _interests.contains(interest);
    return GestureDetector(
      onTap: _isEditing ? () => _toggleInterest(interest) : null,
      child: AnimatedContainer(
        duration: AppMotion.duration(context),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              interest,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
