import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/screens/home_screen.dart';
import 'package:library_app/screens/login_screen.dart';
import 'package:library_app/screens/register_screen.dart';
import 'package:library_app/screens/user_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Library App',
      theme: AppStyles.lightTheme(
          backgroundColor: AppColors.primary,
          primaryColor: AppColors.secondary,
          secondaryColor: AppColors.accent),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/user': (context) => UserScreen(),
      },
    );
  }
}
