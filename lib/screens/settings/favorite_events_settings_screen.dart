// lib/screens/settings/favorite_events_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/settings_provider.dart';
import 'package:baby_tracker/providers/theme_provider.dart';
import 'package:baby_tracker/models/event.dart';

class FavoriteEventsSettingsScreen extends StatefulWidget {
  const FavoriteEventsSettingsScreen({super.key});

  @override
  State<FavoriteEventsSettingsScreen> createState() =>
      _FavoriteEventsSettingsScreenState();
}

class _FavoriteEventsSettingsScreenState
    extends State<FavoriteEventsSettingsScreen> {
  late List<EventType> _selectedTypes;

  final Map<EventType, Map<String, dynamic>> _eventConfigs = {
    EventType.sleep: {
      'icon': Icons.bed,
      'label': 'Сон',
      'color': const Color(0xFF6366F1),
    },
    EventType.feeding: {
      'icon': Icons.child_care,
      'label': 'Кормление',
      'color': const Color(0xFF10B981),
    },
    EventType.bottle: {
      'icon': Icons.local_drink,
      'label': 'Бутылка',
      'color': const Color(0xFFEF4444),
    },
    EventType.diaper: {
      'icon': Icons.auto_awesome,
      'label': 'Подгузник',
      'color': const Color(0xFFF59E0B),
    },
    EventType.medicine: {
      'icon': Icons.medical_services,
      'label': 'Лекарство',
      'color': const Color(0xFFF59E0B),
    },
    EventType.weight: {
      'icon': Icons.monitor_weight,
      'label': 'Вес',
      'color': const Color(0xFF8B5CF6),
    },
    EventType.height: {
      'icon': Icons.height,
      'label': 'Рост',
      'color': const Color(0xFF06B6D4),
    },
    // EventType.headCircumference: {
    //   'icon': Icons.accessibility,
    //   'label': 'Окружность головы',
    //   'color': const Color(0xFFF97316),
    // },
    EventType.walk: {
      'icon': Icons.directions_walk,
      'label': 'Прогулка',
      'color': const Color(0xFF22C55E),
    },
    EventType.bath: {
      'icon': Icons.bathtub,
      'label': 'Купание',
      'color': const Color(0xFF3B82F6),
    },
  };

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    _selectedTypes = List.from(settingsProvider.favoriteEventTypes);
  }

  @override
  Widget build(BuildContext context) {
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
          'Быстрые действия',
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Сохранить',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Выберите события, которые будут отображаться в быстрых действиях на главном экране:',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ..._eventConfigs.entries.map((entry) {
            final eventType = entry.key;
            final config = entry.value;
            final isSelected = _selectedTypes.contains(eventType);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedTypes.add(eventType);
                    } else {
                      _selectedTypes.remove(eventType);
                    }
                  });
                },
                title: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (config['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        config['icon'] as IconData,
                        color: config['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      config['label'] as String,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вы можете выбрать несколько событий. Они будут отображаться в виде кнопок быстрого доступа.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.updateFavoriteEventTypes(_selectedTypes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Настройки сохранены'),
          backgroundColor: context.appColors.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }
}
