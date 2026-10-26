import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxvell_app/core/theme/app_typography.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_colors.dart';

class GlassTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool isPassword;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const GlassTextField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    this.isPassword = false,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // A restrained translucent field; its label stays visible while typing.
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: AppMotion.duration(context),
              curve: AppMotion.curve,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: _isFocused ? 0.48 : 0.36),
                border: Border.all(
                  color: widget.errorText != null
                      ? AppColors.error.withValues(alpha: 0.8)
                      : _isFocused
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.field,
                vertical: AppSpace.micro,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.isPassword ? _obscureText : false,
                      onChanged: widget.onChanged,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      textCapitalization: widget.textCapitalization,
                      style: AppTypography.style(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      cursorColor: AppColors.accent,
                      autocorrect: !widget.isPassword,
                      enableSuggestions: !widget.isPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        filled: false,
                        hintText:
                            widget.hintText ??
                            (widget.isPassword
                                ? 'Ingresa tu contraseña'
                                : null),
                        hintStyle: AppTypography.style(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpace.field,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isPassword)
                    IconButton(
                      tooltip: _obscureText
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpace.related),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.errorText!,
              style: AppTypography.style(
                color: const Color(0xFFFF6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
