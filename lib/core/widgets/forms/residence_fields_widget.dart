import 'package:flutter/material.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_colors.dart';
import '../../../integration/services/peru_location_service.dart';
import '../inputs/glass_select_field.dart';
import '../pickers/proxvel_glass_picker_sheet.dart';

class ResidenceFieldsWidget extends StatefulWidget {
  final String? initialDepartment;
  final String? initialProvince;
  final String? initialCity;
  final bool isDarkTheme;
  final void Function(String? department, String? province, String? city) onChanged;

  const ResidenceFieldsWidget({
    super.key,
    this.initialDepartment,
    this.initialProvince,
    this.initialCity,
    this.isDarkTheme = false,
    required this.onChanged,
  });

  @override
  State<ResidenceFieldsWidget> createState() => _ResidenceFieldsWidgetState();
}

class _ResidenceFieldsWidgetState extends State<ResidenceFieldsWidget> {
  String? _selectedDepartment;
  String? _selectedProvince;
  String? _selectedCity;

  List<String> _departments = [];
  List<String> _provinces = [];
  List<String> _cities = [];
  bool _isLocationsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLocations(widget.initialDepartment, widget.initialProvince, widget.initialCity);
  }

  Future<void> _loadLocations(String? dept, String? prov, String? city) async {
    final service = PeruLocationService();
    await service.init();
    
    if (mounted) {
      setState(() {
        _departments = service.getDepartments();
        _isLocationsLoaded = true;
        
        if (dept != null && _departments.contains(dept)) {
          _selectedDepartment = dept;
          _provinces = service.getProvinces(dept);
          
          if (prov != null && _provinces.contains(prov)) {
            _selectedProvince = prov;
            _cities = service.getDistricts(dept, prov);
            
            if (city != null && _cities.contains(city)) {
              _selectedCity = city;
            }
          }
        }
      });
      // Fire initial callback if values were prefilled
      widget.onChanged(_selectedDepartment, _selectedProvince, _selectedCity);
    }
  }

  void _onDepartmentChanged(String? value) {
    setState(() {
      _selectedDepartment = value;
      _selectedProvince = null;
      _selectedCity = null;
      _provinces = value != null ? PeruLocationService().getProvinces(value) : [];
      _cities = [];
    });
    widget.onChanged(_selectedDepartment, _selectedProvince, _selectedCity);
  }

  void _onProvinceChanged(String? value) {
    setState(() {
      _selectedProvince = value;
      _selectedCity = null;
      _cities = value != null && _selectedDepartment != null 
          ? PeruLocationService().getDistricts(_selectedDepartment!, value) 
          : [];
    });
    widget.onChanged(_selectedDepartment, _selectedProvince, _selectedCity);
  }

  void _onCityChanged(String? value) {
    setState(() {
      _selectedCity = value;
    });
    widget.onChanged(_selectedDepartment, _selectedProvince, _selectedCity);
  }

  void _showPicker({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    ProxvelGlassPickerSheet.show(
      context,
      title: title,
      items: items,
      selectedItem: selectedItem,
      onSelected: onSelected,
    );
  }

  Widget _buildField({
    required String label,
    required String? value,
    required String placeholder,
    required bool enabled,
    required String? errorText,
    required VoidCallback onTap,
  }) {
    if (widget.isDarkTheme) {
      return GlassSelectField(
        label: label,
        value: value,
        placeholder: placeholder,
        enabled: enabled,
        errorText: errorText,
        onTap: onTap,
      );
    } else {
      return GestureDetector(
        onTap: enabled ? onTap : () {
          if (!enabled && errorText != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(errorText),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (value != null && value.isNotEmpty) ? value : placeholder,
                  style: TextStyle(
                    fontSize: 16,
                    color: (value != null && value.isNotEmpty) ? AppColors.textPrimary : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationsLoaded) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildField(
          label: 'Departamento',
          value: _selectedDepartment,
          placeholder: 'Selecciona tu departamento',
          enabled: true,
          errorText: null,
          onTap: () {
            _showPicker(
              title: 'Selecciona tu departamento',
              items: _departments,
              selectedItem: _selectedDepartment,
              onSelected: _onDepartmentChanged,
            );
          },
        ),
        const SizedBox(height: AppSpace.field),
        _buildField(
          label: 'Provincia',
          value: _selectedProvince,
          placeholder: 'Selecciona tu provincia',
          enabled: _selectedDepartment != null,
          errorText: 'Primero selecciona un departamento',
          onTap: () {
            _showPicker(
              title: 'Selecciona tu provincia',
              items: _provinces,
              selectedItem: _selectedProvince,
              onSelected: _onProvinceChanged,
            );
          },
        ),
        const SizedBox(height: AppSpace.field),
        _buildField(
          label: 'Ciudad / Distrito',
          value: _selectedCity,
          placeholder: 'Selecciona tu distrito',
          enabled: _selectedProvince != null,
          errorText: 'Primero selecciona una provincia',
          onTap: () {
            _showPicker(
              title: 'Selecciona tu distrito',
              items: _cities,
              selectedItem: _selectedCity,
              onSelected: _onCityChanged,
            );
          },
        ),
      ],
    );
  }
}
