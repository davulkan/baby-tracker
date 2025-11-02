// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.surfaceColor,
    required this.surfaceVariantColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.textHintColor,
    required this.diaperWetColor,
    required this.diaperDirtyColor,
    required this.diaperMixedColor,
    required this.sleepColor,
    required this.feedingColor,
    required this.bottleColor,
    required this.diaperColor,
  });

  final Color primaryAccent; // 0xFFF59E0B - оранжевый
  final Color secondaryAccent; // 0xFF6366F1 - фиолетовый
  final Color successColor; // 0xFF10B981 - зеленый
  final Color errorColor; // 0xFFEF4444 - красный
  final Color warningColor; // 0xFFF59E0B - оранжевый
  final Color
      surfaceColor; // цвет поверхности (серый для темной, белый для светлой)
  final Color surfaceVariantColor; // вариант поверхности
  final Color textPrimaryColor; // основной текст
  final Color textSecondaryColor; // вторичный текст
  final Color textHintColor; // подсказки
  final Color diaperWetColor; // мокрый подгузник
  final Color diaperDirtyColor; // грязный подгузник
  final Color diaperMixedColor; // смешанный подгузник
  final Color sleepColor; // сон
  final Color feedingColor; // кормление
  final Color bottleColor; // бутылка
  final Color diaperColor; // подгузник

  static const AppColors light = AppColors(
    primaryAccent: Color(0xFF8B5CF6), // Основной фиолетовый - мягкий и приятный
    secondaryAccent: Color(0xFF3B82F6), // Мягкий синий
    successColor: Color(0xFF22C55E), // Более мягкий зеленый
    errorColor: Color(0xFFEF4444), // Красный для ошибок
    warningColor: Color(0xFFFB923C), // Оранжевый для предупреждений
    surfaceColor: Color(0xFFF5F5F5),
    surfaceVariantColor: Color(0xFFFFFFFF),
    textPrimaryColor: Color(0xFF1F2937),
    textSecondaryColor: Color(0xFF6B7280),
    textHintColor: Color(0xFF9CA3AF),
    diaperWetColor: Color(0xFF3B82F6), // Синий - вода, влага
    diaperDirtyColor: Color(0xFFFB923C), // Оранжевый - внимание
    diaperMixedColor: Color(0xFFFBBF24), // Желтый - яркость
    sleepColor: Color(0xFF6366F1), // Индиго - спокойствие, глубокий сон
    feedingColor: Color(0xFF10B981), // Изумрудный - здоровье, рост
    bottleColor: Color(0xFFEC4899), // Розовый - нежность, забота
    diaperColor: Color(0xFFFB923C), // Оранжевый - тепло, внимание
  );

  static const AppColors dark = AppColors(
    primaryAccent: Color(0xFFA78BFA), // Светлый фиолетовый для темной темы
    secondaryAccent: Color(0xFF60A5FA), // Светлый синий
    successColor: Color(0xFF4ADE80), // Светлый зеленый
    errorColor: Color(0xFFF87171), // Светлый красный
    warningColor: Color(0xFFFBBF24), // Светлый оранжевый
    surfaceColor: Color(0xFF1F1F1F), // Темно-серый для карточек
    surfaceVariantColor: Color(0xFF2A2A2A), // Вариант поверхности
    textPrimaryColor: Color(0xFFF9FAFB), // Белый текст
    textSecondaryColor: Color(0xFFD1D5DB), // Серый текст
    textHintColor: Color(0xFF6B7280), // Темно-серые подсказки
    diaperWetColor: Color(0xFF60A5FA), // Светлый синий
    diaperDirtyColor: Color(0xFFFBBF24), // Светлый оранжевый
    diaperMixedColor: Color(0xFFFDE047), // Светлый желтый
    sleepColor: Color(0xFF818CF8), // Светлый индиго - спокойствие, глубокий сон
    feedingColor: Color(0xFF34D399), // Светлый изумрудный - здоровье, рост
    bottleColor: Color(0xFFF472B6), // Светлый розовый - нежность, забота
    diaperColor: Color(0xFFFBBF24), // Светлый оранжевый - тепло, внимание
  );

  @override
  AppColors copyWith({
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? surfaceColor,
    Color? surfaceVariantColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    Color? textHintColor,
    Color? diaperWetColor,
    Color? diaperDirtyColor,
    Color? diaperMixedColor,
    Color? sleepColor,
    Color? feedingColor,
    Color? bottleColor,
    Color? diaperColor,
  }) {
    return AppColors(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceVariantColor: surfaceVariantColor ?? this.surfaceVariantColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textHintColor: textHintColor ?? this.textHintColor,
      diaperWetColor: diaperWetColor ?? this.diaperWetColor,
      diaperDirtyColor: diaperDirtyColor ?? this.diaperDirtyColor,
      diaperMixedColor: diaperMixedColor ?? this.diaperMixedColor,
      sleepColor: sleepColor ?? this.sleepColor,
      feedingColor: feedingColor ?? this.feedingColor,
      bottleColor: bottleColor ?? this.bottleColor,
      diaperColor: diaperColor ?? this.diaperColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      surfaceVariantColor:
          Color.lerp(surfaceVariantColor, other.surfaceVariantColor, t)!,
      textPrimaryColor:
          Color.lerp(textPrimaryColor, other.textPrimaryColor, t)!,
      textSecondaryColor:
          Color.lerp(textSecondaryColor, other.textSecondaryColor, t)!,
      textHintColor: Color.lerp(textHintColor, other.textHintColor, t)!,
      diaperWetColor: Color.lerp(diaperWetColor, other.diaperWetColor, t)!,
      diaperDirtyColor:
          Color.lerp(diaperDirtyColor, other.diaperDirtyColor, t)!,
      diaperMixedColor:
          Color.lerp(diaperMixedColor, other.diaperMixedColor, t)!,
      sleepColor: Color.lerp(sleepColor, other.sleepColor, t)!,
      feedingColor: Color.lerp(feedingColor, other.feedingColor, t)!,
      bottleColor: Color.lerp(bottleColor, other.bottleColor, t)!,
      diaperColor: Color.lerp(diaperColor, other.diaperColor, t)!,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Светлая тема';
      case ThemeMode.dark:
        return 'Темная тема';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs?.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.dark,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Получение светлой темы
  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B5CF6), // Основной фиолетовый
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFAFAFA),
        foregroundColor: Color(0xFF1F2937),
      ),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      // Дополнительные цвета для приложения
      extensions: <ThemeExtension<AppColors>>[
        AppColors.light,
      ],
    );
  }

  // Получение темной темы
  ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor:
            const Color(0xFFA78BFA), // Светлый фиолетовый для темной темы
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212), // Истинно черный фон
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF121212),
        foregroundColor: Color(0xFFF9FAFB),
      ),
      cardColor: const Color(0xFF1F1F1F), // Темно-серый для карточек
      dialogBackgroundColor: const Color(0xFF1F1F1F),
      // Дополнительные цвета для приложения
      extensions: <ThemeExtension<AppColors>>[
        AppColors.dark,
      ],
    );
  }

  // Получение текущей темы
  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return _themeMode == ThemeMode.dark ? darkTheme : lightTheme;
  }
}

// Extension для удобного доступа к AppColors
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
