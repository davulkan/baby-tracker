// lib/main.dart
import 'package:baby_tracker/providers/events_provider.dart';
import 'package:baby_tracker/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:baby_tracker/providers/auth_provider.dart';
import 'package:baby_tracker/providers/baby_provider.dart';
import 'package:baby_tracker/screens/splash_screen.dart';
import 'package:baby_tracker/screens/auth_screen.dart';
import 'package:baby_tracker/screens/family_setup_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider должен быть первым
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // BabyProvider и EventsProvider зависят от AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, BabyProvider>(
          create: (_) => BabyProvider(),
          update: (context, auth, previous) {
            final babyProvider = previous ?? BabyProvider();
            // Загружаем детей когда есть familyId
            if (auth.familyId != null) {
              babyProvider.loadBabies(auth.familyId!);
            }
            return babyProvider;
          },
        ),

        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: MaterialApp(
        title: 'Baby Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.black,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BabyProvider>(
      builder: (context, authProvider, babyProvider, child) {
        // Показываем загрузку пока проверяем auth статус
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // Если не авторизован - показываем экран авторизации
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // Если авторизован но нет семьи - настройка семьи
        if (authProvider.familyId == null) {
          return const FamilySetupScreen();
        }

        // Если авторизован и есть семья - главный экран
        return const HomeScreenFull();
      },
    );
  }
}
