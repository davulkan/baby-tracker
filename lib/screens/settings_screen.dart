// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/screens/baby_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Настройки',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Профиль пользователя
          _buildUserProfile(authProvider),

          const SizedBox(height: 32),

          // Секция "Ребенок"
          _buildSectionHeader('Ребенок'),
          Consumer<BabyProvider>(
            builder: (context, babyProvider, child) {
              final baby = babyProvider.currentBaby;
              return _buildSettingItem(
                icon: Icons.child_care,
                title: 'Профиль ребенка',
                subtitle: baby != null
                    ? '${baby.name}, ${baby.ageText}'
                    : 'Добавить ребенка',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BabyProfileScreen(baby: baby),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Секция "Семья"
          _buildSectionHeader('Семья'),
          _buildSettingItem(
            icon: Icons.family_restroom,
            title: 'Члены семьи',
            subtitle: '2 родителя',
            onTap: () {
              // TODO: Открыть список членов семьи
            },
          ),
          _buildSettingItem(
            icon: Icons.vpn_key,
            title: 'Код приглашения',
            subtitle: 'Пригласить партнера',
            onTap: () {
              _showInviteCodeDialog(context, authProvider);
            },
          ),

          const SizedBox(height: 24),

          // Секция "Приложение"
          _buildSectionHeader('Приложение'),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Уведомления',
            subtitle: 'Настройки уведомлений',
            onTap: () {
              // TODO: Открыть настройки уведомлений
            },
          ),
          _buildSettingItem(
            icon: Icons.palette,
            title: 'Внешний вид',
            subtitle: 'Темная тема',
            onTap: () {
              // TODO: Открыть настройки темы
            },
          ),
          _buildSettingItem(
            icon: Icons.language,
            title: 'Язык',
            subtitle: 'Русский',
            onTap: () {
              // TODO: Открыть выбор языка
            },
          ),

          const SizedBox(height: 24),

          // Секция "Данные"
          _buildSectionHeader('Данные'),
          _buildSettingItem(
            icon: Icons.backup,
            title: 'Экспорт данных',
            subtitle: 'Скачать все данные',
            onTap: () {
              // TODO: Экспорт данных
            },
          ),
          _buildSettingItem(
            icon: Icons.delete_forever,
            title: 'Удалить все данные',
            subtitle: 'Безвозвратное удаление',
            textColor: Colors.red,
            onTap: () {
              _showDeleteDataDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // Секция "О приложении"
          _buildSectionHeader('О приложении'),
          _buildSettingItem(
            icon: Icons.info,
            title: 'Версия',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip,
            title: 'Политика конфиденциальности',
            onTap: () {
              // TODO: Открыть политику
            },
          ),
          _buildSettingItem(
            icon: Icons.description,
            title: 'Условия использования',
            onTap: () {
              // TODO: Открыть условия
            },
          ),

          const SizedBox(height: 32),

          // Кнопка выхода
          _buildLogoutButton(context, authProvider),
        ],
      ),
    );
  }

  Widget _buildUserProfile(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white60),
            onPressed: () {
              // TODO: Редактировать профиль
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white60,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return ElevatedButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Выход',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Вы уверены, что хотите выйти?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Выйти',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await authProvider.signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Выйти из аккаунта',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Код приглашения',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Отправьте этот код партнеру для присоединения к семье:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: const Text(
                'JOIN-ABC123', // TODO: Загрузить реальный код
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Копировать в буфер
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Код скопирован'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Копировать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Удалить все данные?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Это действие невозможно отменить. Все данные о ребенке будут удалены навсегда.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Удалить все данные
              Navigator.pop(context);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
