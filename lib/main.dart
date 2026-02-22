import 'package:cafeshop/screens/customer/homepage_customer.dart';
import 'package:cafeshop/screens/auth/login_screen.dart';
import 'package:cafeshop/screens/auth/register_screen.dart';
import 'package:cafeshop/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // file sinh ra khi chạy flutterfire configure

// Import màn hình FirebaseConnect từ folder connect
// import 'connect/firebase_connect_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CafeShopApp());
}

class CafeShopApp extends StatelessWidget {
  const CafeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Shop Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(), // thêm dòng này
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePage(
          userId: '',
          userData: <String, dynamic>{'fullname': 'Người dùng'},
        ),
      },
    );
  }
}
