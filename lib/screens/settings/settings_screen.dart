// lib/screens/settings_screen.dart
import 'package:baby_tracker/screens/settings/widgets/migration.dart';
import 'package:baby_tracker/screens/settings/favorite_events_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart' as theme;
import 'package:baby_tracker/screens/settings/widgets/baby_profile_screen.dart';
import 'package:baby_tracker/screens/settings/widgets/family_management_screen.dart';
import 'package:baby_tracker/screens/settings/widgets/user_profile_widget.dart';
import 'package:baby_tracker/screens/settings/widgets/settings_section_widget.dart';
import 'package:baby_tracker/screens/settings/widgets/setting_item_widget.dart';
import 'package:baby_tracker/screens/settings/widgets/logout_button_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<theme.ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Настройки',
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Профиль пользователя
          UserProfileWidget(
            authProvider: authProvider,
          ),

          const SizedBox(height: 32),

          // Секция "Ребенок"
          SettingsSectionWidget(title: 'Ребенок'),
          Consumer<BabyProvider>(
            builder: (context, babyProvider, child) {
              final baby = babyProvider.currentBaby;
              return SettingItemWidget(
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
          SettingsSectionWidget(title: 'Семья'),
          FutureBuilder<Map<String, dynamic>?>(
            future: authProvider.getFamilyInfo(),
            builder: (context, snapshot) {
              final familyName = snapshot.data?['name'];
              return SettingItemWidget(
                icon: Icons.family_restroom,
                title: 'Управление семьёй',
                subtitle: familyName != null
                    ? 'Семья: $familyName'
                    : 'Не состоите в семье',
                onTap: () => _navigateToFamilyManagement(context),
              );
            },
          ),
          SettingItemWidget(
            icon: Icons.vpn_key,
            title: 'Контроль доступа',
            subtitle: 'Права доступа и разрешения',
            onTap: () => _showAccessControl(context),
          ),

          const SizedBox(height: 24),

          // Секция "Приложение"
          SettingsSectionWidget(title: 'Приложение'),
          SettingItemWidget(
            icon: Icons.notifications,
            title: 'Уведомления',
            subtitle: 'Настройка оповещений',
            onTap: () => _showNotificationSettings(context),
          ),
          SettingItemWidget(
            icon: Icons.palette,
            title: 'Тема приложения',
            subtitle: _getThemeModeName(themeProvider.themeMode),
            onTap: () => _showThemeSettings(context, themeProvider),
          ),
          SettingItemWidget(
            icon: Icons.flash_on,
            title: 'Быстрые действия',
            subtitle: 'Выберите события для быстрого доступа',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoriteEventsSettingsScreen(),
                ),
              );
            },
          ),
          SettingItemWidget(
            icon: Icons.language,
            title: 'Язык',
            subtitle: 'Русский',
            onTap: () => _showLanguageSettings(context),
          ),

          const SizedBox(height: 24),

          // Секция "Данные"
          SettingsSectionWidget(title: 'Данные'),
          SettingItemWidget(
            icon: Icons.sync,
            title: 'Залить данные из бэкапа',
            subtitle: 'Миграция ваших данных из бэкапа My baby',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MigrationScreen(),
                ),
              );
            },
          ),
          SettingItemWidget(
            icon: Icons.backup,
            title: 'Экспорт данных',
            subtitle: 'Скачать все данные',
            onTap: () {
              _exportData(context);
            },
          ),
          SettingItemWidget(
            icon: Icons.delete_forever,
            title: 'Удалить все данные',
            subtitle: 'Безвозвратное удаление',
            textColor: context.appColors.errorColor,
            onTap: () {
              _showDeleteDataDialog(context, authProvider);
            },
          ),

          const SizedBox(height: 24),

          // Секция "О приложении"
          SettingsSectionWidget(title: 'О приложении'),
          SettingItemWidget(
            icon: Icons.info,
            title: 'Версия',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          SettingItemWidget(
            icon: Icons.privacy_tip,
            title: 'Политика конфиденциальности',
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),
          SettingItemWidget(
            icon: Icons.description,
            title: 'Условия использования',
            onTap: () {
              _showTermsOfService(context);
            },
          ),

          const SizedBox(height: 32),

          // Кнопка выхода
          LogoutButtonWidget(
            onPressed: () => _handleLogout(context, authProvider),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Выход',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Вы уверены, что хотите выйти?',
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Выйти',
              style: TextStyle(color: context.appColors.errorColor),
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
  }

  void _showDeleteDataDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Удалить все данные?',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Это действие невозможно отменить. Все данные о ребенке будут удалены навсегда.',
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData(context, authProvider);
            },
            child: Text(
              'Удалить',
              style: TextStyle(color: context.appColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // Новые методы для настроек
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Настройки уведомлений',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSwitchTile(
              context,
              title: 'Уведомления о кормлении',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              title: 'Уведомления о сне',
              value: true,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              title: 'Уведомления о подгузниках',
              value: false,
              onChanged: (value) {},
            ),
            _buildSwitchTile(
              context,
              title: 'Напоминания',
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings(
      BuildContext context, theme.ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Внешний вид',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              icon: Icons.light_mode,
              title: 'Светлая тема',
              mode: theme.ThemeMode.light,
              currentMode: themeProvider.themeMode,
              onChanged: (mode) {
                themeProvider.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.dark_mode,
              title: 'Темная тема',
              mode: theme.ThemeMode.dark,
              currentMode: themeProvider.themeMode,
              onChanged: (mode) {
                themeProvider.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context: context,
              icon: Icons.auto_mode,
              title: 'Системная',
              mode: theme.ThemeMode.system,
              currentMode: themeProvider.themeMode,
              onChanged: (mode) {
                themeProvider.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required theme.ThemeMode mode,
    required theme.ThemeMode currentMode,
    required Function(theme.ThemeMode) onChanged,
  }) {
    final isSelected = mode == currentMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : textColor?.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : textColor,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Radio<theme.ThemeMode>(
        value: mode,
        groupValue: currentMode,
        onChanged: (value) => value != null ? onChanged(value) : null,
      ),
      onTap: () => onChanged(mode),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Выбор языка',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Русский',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: Radio<String>(
                value: 'ru',
                groupValue: 'ru',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: Text('English',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: Radio<String>(
                value: 'en',
                groupValue: 'ru',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Экспорт данных',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Функция экспорта данных будет доступна в следующем обновлении. '
          'Все данные хранятся в облаке и синхронизируются между устройствами.',
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(
      BuildContext context, AuthProvider authProvider) async {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.transparent,
        content: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      // Здесь можно добавить логику удаления всех данных
      await Future.delayed(const Duration(seconds: 2)); // Имитация загрузки

      if (context.mounted) {
        Navigator.pop(context); // Закрываем индикатор
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Функция будет доступна в следующем обновлении'),
            backgroundColor: context.appColors.warningColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка при удалении данных'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Политика конфиденциальности',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: SingleChildScrollView(
          child: Text(
            'BabySync уважает вашу конфиденциальность.\n\n'
            'Мы собираем только необходимую информацию для работы приложения:\n'
            '• Данные профиля Google для авторизации\n'
            '• Информацию о детях для отслеживания\n'
            '• События и записи для синхронизации\n\n'
            'Все данные шифруются и хранятся в Firebase.\n'
            'Мы не передаем данные третьим лицам.',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Условия использования',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Условия использования BabySync:\n\n'
            '1. Приложение предназначено для личного использования\n'
            '2. Вы несете ответственность за достоверность данных\n'
            '3. Запрещается использовать приложение в коммерческих целях\n'
            '4. Мы не несем ответственности за медицинские решения\n'
            '5. Данные могут быть удалены при нарушении условий\n\n'
            'Используя приложение, вы соглашаетесь с условиями.',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title,
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  // Недостающие методы
  String _getThemeModeName(theme.ThemeMode themeMode) {
    switch (themeMode) {
      case theme.ThemeMode.light:
        return 'Светлая';
      case theme.ThemeMode.dark:
        return 'Темная';
      case theme.ThemeMode.system:
        return 'Системная';
    }
  }

  void _navigateToFamilyManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyManagementScreen(),
      ),
    );
  }

  void _showAccessControl(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Функция будет доступна в следующем обновлении'),
        backgroundColor: context.appColors.warningColor,
      ),
    );
  }
}
