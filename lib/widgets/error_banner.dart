import 'package:flutter/material.dart';

/// A small red inline banner for form-level errors (e.g. "incorrect
/// password", "email already in use").
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
