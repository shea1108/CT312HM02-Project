import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'models/auth_service.dart';
import 'models/theme_manager.dart';
import 'models/video_player.dart';
import 'screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getString('authToken')?.isNotEmpty ?? false;
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => VideoPlayerModel()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Movie App',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFE50914),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 20),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 16),
          titleLarge: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFE50914),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 20),
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 16),
          titleLarge: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: isLoggedIn ? HomeScreen() : Loginscreen(),
      routes: {
        '/login': (ctx) => Loginscreen(),
        '/signup': (ctx) => SignupScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/settings') {
          return _customPageRoute(const SettingsPage());
        }
        if (settings.name == '/editprofile') {
          return _customPageRoute(const EditProfileScreen());
        }
        if (settings.name == '/changepass') {
          return _customPageRoute(const ChangePasswordScreen());
        }
        if (settings.name == '/favorites' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (ctx) =>
                FavoriteScreen(userId: settings.arguments as String),
          );
        } else if (settings.name == '/detail' &&
            settings.arguments is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (ctx) =>
                DetailScreen(movie: settings.arguments as Map<String, dynamic>),
          );
        } else if (settings.name == '/video_player' &&
            settings.arguments is String) {
          return MaterialPageRoute(
            builder: (ctx) =>
                VideoPlayerScreen(movieId: settings.arguments as String),
          );
        }
        return null;
      },
    );
  }

  PageRouteBuilder _customPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
