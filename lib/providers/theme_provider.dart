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
    primaryAccent: Color(0xFFF59E0B),
    secondaryAccent: Color(0xFF6366F1),
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    surfaceColor: Color(0xFFEEEEEE),
    surfaceVariantColor: Color(0xFFFFFFFF),
    textPrimaryColor: Color(0xFF000000),
    textSecondaryColor: Color(0xFF666666),
    textHintColor: Color(0xFF999999),
    diaperWetColor: Color(0xFF3B82F6),
    diaperDirtyColor: Color(0xFF8B5CF6),
    diaperMixedColor: Color(0xFFF59E0B),
    sleepColor: Color(0xFF3B82F6),
    feedingColor: Color(0xFF10B981),
    bottleColor: Color(0xFFF59E0B),
    diaperColor: Color(0xFF6366F1),
  );

  static const AppColors dark = AppColors(
    primaryAccent: Color(0xFFF59E0B),
    secondaryAccent: Color(0xFF6366F1),
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    surfaceColor: Color(0xFF1F1F1F),
    surfaceVariantColor: Color(0xFF2A2A2A),
    textPrimaryColor: Color(0xFFFFFFFF),
    textSecondaryColor: Color(0xFFCCCCCC),
    textHintColor: Color(0xFF666666),
    diaperWetColor: Color(0xFF3B82F6),
    diaperDirtyColor: Color(0xFF8B5CF6),
    diaperMixedColor: Color(0xFFF59E0B),
    sleepColor: Color(0xFF3B82F6),
    feedingColor: Color(0xFF10B981),
    bottleColor: Color(0xFFF59E0B),
    diaperColor: Color(0xFF6366F1),
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
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black87,
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
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      cardColor: const Color(0xFF1F1F1F),
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
