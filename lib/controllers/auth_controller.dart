import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'package:collection/collection.dart';

class AuthController extends GetxController {
  var currentUser = Rxn<UserModel>();
  late Box<UserModel> userBox;
  late Box<String> sessionBox;

  @override
  void onInit() {
    super.onInit();
    userBox = Hive.box<UserModel>('users');
    sessionBox = Hive.box<String>('session');

    final savedEmail = sessionBox.get('currentEmail');
    if (savedEmail != null) {
      final user = userBox.values.firstWhereOrNull(
        (u) => u.email == savedEmail,
      );
      currentUser.value = user;
    }
  }

  void signupUser(String email, String password) {
    final existingUser = userBox.values.firstWhereOrNull(
      (u) => u.email == email,
    );

    if (existingUser != null) {
      Get.snackbar("Error", "User already exists. Please log in.");
      return;
    }

    final newUser = UserModel(email: email, password: password);
    userBox.add(newUser);

    currentUser.value = newUser;
    sessionBox.put('currentEmail', newUser.email);

    Get.snackbar("Success", "Account created. Welcome ${newUser.email}!");
    Get.offAllNamed('/home');
  }

  void loginUser(String email, String password) {
    final user = userBox.values.firstWhereOrNull(
      (u) => u.email == email && u.password == password,
    );

    if (user != null) {
      currentUser.value = user;
      sessionBox.put('currentEmail', user.email);
      Get.snackbar("Success", "Welcome ${user.email}");
      Get.offAllNamed('/home');
    } else {
      Get.snackbar("Error", "Invalid credentials");
    }
  }

  void logoutUser() {
    currentUser.value = null;
    sessionBox.delete('currentEmail');
    Get.snackbar("Logged Out", "You have been logged out.");
    Get.offAllNamed('/login');
  }
}
