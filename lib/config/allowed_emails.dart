// lib/config/allowed_emails.dart

/// Список разрешенных email адресов для входа в приложение
class AllowedEmails {
  // 👇 ДОБАВЬТЕ СЮДА ВАШИ EMAIL'Ы
  static const List<String> whitelist = [
    'dantsushko@gmail.com', // Замените на ваш первый email
    'your.email2@gmail.com', // Замените на ваш второй email
  ];

  /// Проверяет, разрешен ли данный email
  static bool isAllowed(String email) {
    return whitelist.contains(email.toLowerCase().trim());
  }

  /// Получает сообщение об ошибке для неразрешенного email
  static String getDeniedMessage(String email) {
    return 'Email "$email" не имеет доступа к приложению.\n\n'
        'Свяжитесь с администратором для получения доступа.';
  }
}
