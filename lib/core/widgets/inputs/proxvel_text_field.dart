import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_text_styles.dart';

class ProxvelTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final bool isPassword;
  final Function(String)? onChanged;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final String? helperText;
  final Widget? prefixIcon;
  final Color? fillColor;
  final TextInputType? keyboardType;

  const ProxvelTextField({
    super.key,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.onChanged,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.readOnly = false,
    this.helperText,
    this.prefixIcon,
    this.fillColor,
    this.keyboardType,
  });

  @override
  State<ProxvelTextField> createState() => _ProxvelTextFieldState();
}

class _ProxvelTextFieldState extends State<ProxvelTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: AppTextStyles.body1,
      controller: widget.controller,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      onChanged: widget.onChanged,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: widget.errorText != null
              ? AppColors.error
              : AppColors.textMuted,
        ), // Gray-400 or Red
        errorText: widget.errorText,
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon,
        filled: true,
        fillColor: widget.fillColor ?? AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(
            color: widget.errorText != null
                ? AppColors.error
                : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(
            color: widget.errorText != null
                ? AppColors.error
                : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(
            color: widget.errorText != null
                ? AppColors.error
                : AppColors.accent,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(AppSpace.field),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
