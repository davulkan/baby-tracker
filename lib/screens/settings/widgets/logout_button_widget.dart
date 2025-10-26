import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/theme_provider.dart';

class LogoutButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.appColors.errorColor,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: context.appColors.textPrimaryColor),
          const SizedBox(width: 8),
          Text(
            'Выйти из аккаунта',
            style: TextStyle(
              color: context.appColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
