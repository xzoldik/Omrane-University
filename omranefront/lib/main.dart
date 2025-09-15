import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/config.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/courses/courses_screen.dart';
import 'features/students/students_screen.dart';
import 'features/enrollments/enrollments_screen.dart';
import 'features/enrollments/my_courses_screen.dart';
import 'features/payments/payments_screen.dart';
import 'features/auth/register_screen.dart';
import 'core/navigation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize date symbols/data for Arabic (Algeria)
  await initializeDateFormatting('ar_DZ', null);
  Intl.defaultLocale = 'ar_DZ';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'Omrane University',
        theme: buildTheme(),
        navigatorObservers: [routeObserver],
        routes: {
          '/': (_) => _InitialGate(),
          '/home': (_) => const HomeScreen(),
          // placeholders for later
          '/students': (_) => const StudentsScreen(),
          '/courses': (_) => const CoursesScreen(),
          '/enrollments': (_) => const EnrollmentsScreen(),
          '/payments': (_) => const PaymentsScreen(),
          '/my-courses': (_) => const MyCoursesScreen(),
          '/my-payments': (_) => const MyPaymentsScreen(),
          '/my-fees': (_) => const MyFeesScreen(),
          '/register': (_) => const RegisterScreen(),
        },
      ),
    );
  }
}

// Removed WIP screen; all routes implemented.

class _InitialGate extends StatefulWidget {
  @override
  State<_InitialGate> createState() => _InitialGateState();
}

class _InitialGateState extends State<_InitialGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    try {
      if (AppConfig.autoLogin) {
        final ok = await auth.login(
          AppConfig.autoLoginEmail,
          AppConfig.autoLoginPassword,
        );
        if (!mounted) return;
        if (ok) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
          return;
        }
      } else {
        // Try to reuse existing session if any
        await auth.loadMe();
        if (!mounted) return;
        if (auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
          return;
        }
      }
    } catch (_) {
      // Ignore and fall back to login screen
    }
    // fallback to login screen
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
