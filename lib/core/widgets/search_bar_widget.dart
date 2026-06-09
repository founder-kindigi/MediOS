import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: hintText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? Semantics(
                  button: true,
                  label: 'Clear search',
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
                )
              : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
    );
  }
}
