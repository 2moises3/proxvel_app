import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_layout.dart';
import '../../../models/traveler_types.dart';
import '../../theme/app_colors.dart';

class TravelerTypeSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  const TravelerTypeSelector({super.key, this.value, this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: travelerTypes.containsKey(value) ? value : null,
        isExpanded: true,
        hint: const Text('Elige tu estilo de viaje'),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
        items: [
          for (final type in travelerTypes.entries)
            DropdownMenuItem(
              value: type.key,
              child: Text(
                type.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
      const SizedBox(height: AppSpace.content),
      const Text(
        'Tu elección define qué aspectos prioriza la recomendación. Puedes cambiarla después.',
        style: AppTextStyles.body2,
      ),
    ],
  );
}
