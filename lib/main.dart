import 'package:flutter/material.dart';
import 'ui/pages/Homepages.dart';
import "package:hive/hive.dart";
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import "models/user_model.dart";
import 'ui/pages/signupscree.dart';
import 'ui/pages/loginscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<String>('session');

  final authController = Get.put(AuthController());
  await Future.delayed(Duration(milliseconds: 500)); // Allow onInit to complete
  runApp(
    NeuroTrainerApp(
      initialRoute:
          authController.currentUser.value != null ? '/home' : '/login',
    ),
  );
}

class NeuroTrainerApp extends StatelessWidget {
  final String initialRoute;
  const NeuroTrainerApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Ai interview app",
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/signup', page: () => SignupPage()),
        GetPage(name: '/home', page: () => InterviewHomePage()),
      ],
    );
  }
}
