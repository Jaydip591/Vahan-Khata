import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Light text field with the label above it, big enough to tap and read.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          onChanged: onChanged,
          autofocus: autofocus,
          maxLength: maxLength,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 16),
            suffixIcon: suffixIcon,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            enabledBorder: border(AppColors.fieldLine),
            focusedBorder: border(AppColors.ink, 2),
            errorBorder: border(AppColors.expense),
            focusedErrorBorder: border(AppColors.expense, 2),
            errorStyle: const TextStyle(color: AppColors.expense, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
