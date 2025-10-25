// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _user;
  String? _familyId;
  bool _isLoading = true;
  String? _error;

  User? get currentUser => _user;
  String? get familyId => _familyId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    // Слушаем изменения авторизации
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();

    if (user != null) {
      // Загружаем или создаём данные пользователя в Firestore
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Пользователь существует - загружаем данные
          _familyId = userDoc.data()?['family_id'];
        } else {
          // Пользователь новый - создаём документ
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email ?? '',
            'name': user.displayName ?? 'Пользователь',
            'photo_url': user.photoURL,
            'created_at': FieldValue.serverTimestamp(),
          });
          // У нового пользователя нет семьи
          _familyId = null;
        }
      } catch (e) {
        _error = 'Ошибка загрузки данных пользователя';
        debugPrint('Error loading user data: $e');
      }
    } else {
      _familyId = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Вход через Google
  Future<bool> signInWithGoogle() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      debugPrint('Начинаем процесс входа через Google...');

      // Инициируем процесс входа через Google
      debugPrint('Вызываем _googleSignIn.authenticate()...');
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();

      if (googleUser == null) {
        // Пользователь отменил вход
        debugPrint('Пользователь отменил вход через Google');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint(
          'Google Sign-In успешен, получен аккаунт: ${googleUser.email}');

      debugPrint('Авторизуемся в Firebase через Google Sign-In...');
      // В новой версии GoogleSignIn мы можем напрямую получать учетные данные для Firebase
      // Используем стандартные scope-ы для Firebase
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'profile', 'openid']);

      if (authorization == null) {
        throw Exception('Не удалось получить авторизацию от Google');
      }

      debugPrint('Токены получены успешно');

      // Создаём учетные данные для Firebase с доступным токеном
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: null, // В новой версии idToken может быть недоступен
      );

      // Входим в Firebase с учетными данными Google
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('Firebase авторизация успешна: ${userCredential.user?.email}');
      return true;
    } catch (e) {
      String errorMessage = 'Ошибка входа через Google';

      debugPrint('Ошибка входа через Google: $e');
      debugPrint('Тип ошибки: ${e.runtimeType}');

      if (e.toString().contains('ClientID not set') ||
          e.toString().contains('No such module \'GoogleSignIn\'')) {
        errorMessage =
            'Google Sign-In не настроен. Проверьте конфигурацию iOS.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Проблемы с сетью. Проверьте подключение к интернету.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Вход отменен пользователем';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Ошибка входа через Google. Попробуйте еще раз.';
      } else {
        errorMessage = 'Ошибка входа через Google: ${e.toString()}';
      }

      _error = errorMessage;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Выход
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Создание семьи
  Future<String?> createFamily(String familyName) async {
    if (_user == null) return null;

    // Проверяем, что пользователь еще не состоит в семье
    if (_familyId != null) {
      _error = 'Вы уже состоите в семье';
      notifyListeners();
      return null;
    }

    try {
      // Генерируем код приглашения
      final inviteCode = _generateInviteCode();

      // Создаём документ семьи
      final familyRef = await _firestore.collection('families').add({
        'name': familyName,
        'created_at': FieldValue.serverTimestamp(),
        'invite_code': inviteCode,
      });

      // Добавляем пользователя как члена семьи
      await familyRef.collection('members').doc(_user!.uid).set({
        'role': 'parent1',
        'name': _user!.displayName ?? 'Родитель 1',
        'email': _user!.email ?? '',
        'photo_url': _user!.photoURL,
        'joined_at': FieldValue.serverTimestamp(),
      });

      // Создаём или обновляем документ пользователя
      await _firestore.collection('users').doc(_user!.uid).set({
        'email': _user!.email ?? '',
        'name': _user!.displayName ?? 'Пользователь',
        'family_id': familyRef.id,
        'photo_url': _user!.photoURL,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _familyId = familyRef.id;
      notifyListeners();

      return inviteCode;
    } catch (e) {
      _error = 'Error creating family: $e';
      debugPrint('Error creating family: $e');
      notifyListeners();
      return null;
    }
  }

  // Присоединение к семье по коду
  Future<bool> joinFamily(String inviteCode) async {
    if (_user == null) return false;

    try {
      // Ищем семью по коду приглашения
      final familyQuery = await _firestore
          .collection('families')
          .where('invite_code', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (familyQuery.docs.isEmpty) {
        _error = 'Неверный код приглашения';
        notifyListeners();
        return false;
      }

      final familyDoc = familyQuery.docs.first;
      final familyId = familyDoc.id;

      // Проверяем, что пользователь еще не состоит в этой семье
      if (_familyId == familyId) {
        _error = 'Вы уже состоите в этой семье';
        notifyListeners();
        return false;
      }

      // Проверяем, что пользователь еще не состоит в другой семье
      if (_familyId != null) {
        _error = 'Вы уже состоите в другой семье';
        notifyListeners();
        return false;
      }

      // Добавляем пользователя как члена семьи
      await familyDoc.reference.collection('members').doc(_user!.uid).set({
        'role': 'parent2',
        'name': _user!.displayName ?? 'Родитель 2',
        'email': _user!.email ?? '',
        'photo_url': _user!.photoURL,
        'joined_at': FieldValue.serverTimestamp(),
      });

      // Создаём или обновляем документ пользователя
      await _firestore.collection('users').doc(_user!.uid).set({
        'email': _user!.email ?? '',
        'name': _user!.displayName ?? 'Пользователь',
        'family_id': familyId,
        'photo_url': _user!.photoURL,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _familyId = familyId;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка при присоединении к семье';
      debugPrint('Error joining family: $e');
      notifyListeners();
      return false;
    }
  }

  // Генерация кода приглашения
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = 'JOIN-';

    // Используем более случайную генерацию
    for (var i = 0; i < 10; i++) {
      final randomIndex =
          (random * (i + 1) + DateTime.now().microsecond) % chars.length;
      code += chars[randomIndex];
    }

    return code;
  }

  // Выход из семьи
  Future<bool> leaveFamily() async {
    if (_user == null || _familyId == null) return false;

    try {
      // Удаляем пользователя из коллекции members
      await _firestore
          .collection('families')
          .doc(_familyId!)
          .collection('members')
          .doc(_user!.uid)
          .delete();

      // Обновляем документ пользователя
      await _firestore.collection('users').doc(_user!.uid).update({
        'family_id': FieldValue.delete(),
      });

      _familyId = null;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка при выходе из семьи';
      debugPrint('Error leaving family: $e');
      notifyListeners();
      return false;
    }
  }

  // Получение информации о семье
  Future<Map<String, dynamic>?> getFamilyInfo() async {
    if (_familyId == null) return null;

    try {
      final familyDoc =
          await _firestore.collection('families').doc(_familyId!).get();

      if (!familyDoc.exists) return null;

      final familyData = familyDoc.data()!;

      // Получаем список участников
      final membersSnapshot = await _firestore
          .collection('families')
          .doc(_familyId!)
          .collection('members')
          .get();

      final members = membersSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      return {
        ...familyData,
        'id': familyDoc.id,
        'members': members,
      };
    } catch (e) {
      debugPrint('Error getting family info: $e');
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
