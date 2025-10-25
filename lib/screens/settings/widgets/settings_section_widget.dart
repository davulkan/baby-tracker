import 'package:flutter/material.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;

  const SettingsSectionWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
