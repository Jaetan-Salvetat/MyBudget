import 'package:get/get.dart';

class AuthController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  Future<void> getCurrentUser() async {}

  Future<void> login(String email, String password) async {}

  Future<void> register(String name, String email, String password) async {}

  Future<void> signOut() async {}

  Future<void> logout() async {
    await signOut();
  }

  void reset() {}
}
