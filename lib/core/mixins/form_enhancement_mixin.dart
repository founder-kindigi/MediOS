import 'package:flutter/material.dart';

mixin FormEnhancementMixin<T extends StatefulWidget> on State<T> {
  final Map<String, FocusNode> _focusNodes = {};

  FocusNode focusNode(String fieldName) {
    return _focusNodes.putIfAbsent(fieldName, () => FocusNode());
  }

  void focusFirstError(GlobalKey<FormState> formKey) {
    if (!formKey.currentState!.validate()) return;
    for (final entry in _focusNodes.entries) {
      if (!entry.value.hasFocus) {
        entry.value.requestFocus();
        break;
      }
    }
  }

  void disposeFocusNodes() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  String? Function(String?)? realtimeValidator(
    String? Function(String?)? originalValidator,
    String fieldName,
  ) {
    return (value) {
      final result = originalValidator?.call(value);
      if (result != null) {
        final node = _focusNodes[fieldName];
        node?.requestFocus();
      }
      return result;
    };
  }
}
