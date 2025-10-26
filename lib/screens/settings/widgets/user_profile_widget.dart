import 'package:flutter/material.dart';
import 'package:baby_tracker/providers/auth_provider.dart';

class UserProfileWidget extends StatelessWidget {
  final AuthProvider authProvider;

  const UserProfileWidget({
    super.key,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: authProvider.currentUser?.photoURL != null
                ? NetworkImage(authProvider.currentUser!.photoURL!)
                : null,
            child: authProvider.currentUser?.photoURL == null
                ? const Icon(Icons.person, size: 30, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.currentUser?.displayName ?? 'Пользователь',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUser?.email ?? '',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
         
        ],
      ),
    );
  }
}
