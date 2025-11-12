import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'database/db_helper.dart';
import 'screens/edit_profile_screen.dart';
import 'utils/notification_helper.dart';
import 'utils/app_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DBHelper.instance.initDB();

  // Initialize notifications
  await NotificationHelper().initialize();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final loggedIn = prefs.getBool('loggedIn') ?? false;

  runApp(
    MyApp(
      initialRoute: seenOnboarding
          ? (loggedIn ? '/home' : '/login')
          : '/onboarding',
    ),
  );
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    // Setup lifecycle observer untuk mendeteksi kapan app ditutup/dibuka
    _lifecycleObserver = AppLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    print('🚀 App started with lifecycle observer');
  }

  @override
  void dispose() {
    // Cleanup observer
    _lifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnackScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Color(0xFFFFFBFF),
        fontFamily: 'Poppins',
      ),
      initialRoute: widget.initialRoute,
      routes: {
        '/onboarding': (ctx) => OnboardingScreen(),
        '/login': (ctx) => LoginScreen(),
        '/home': (ctx) => HomeScreen(),
        '/edit-profile': (context) => EditProfileScreen(),
      },
    );
  }
}
