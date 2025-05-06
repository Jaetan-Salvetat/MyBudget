import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/presentation/widgets/auth/auth_background.dart';
import 'package:appwrite/models.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = false;
  String _errorText = '';
  String _completePhoneNumber = '';
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_completePhoneNumber.isEmpty) {
      setState(() {
        _errorText = 'Veuillez entrer un numéro de téléphone';
      });
      return;
    }
    
    print('Envoi du SMS au numéro: $_completePhoneNumber');

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      print('Tentative d\'authentification téléphonique');
      final Token? token = await authController.startPhoneAuthentication(
        _completePhoneNumber,
      );
      
      print(token != null ? 'Token obtenu avec succès' : 'Échec d\'obtention du token');
      if (token != null) {
        print('UserId: ${token.userId}');
      }

      if (token != null) {
        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'userId': token.userId,
            'phoneNumber': _completePhoneNumber,
          },
        );
      } else {
        print('Erreur: Token null retourné');
        setState(() {
          _errorText = 'Erreur d\'envoi du SMS. Vérifiez votre numéro.';
        });
      }
    } catch (e) {
      print('Exception lors de l\'envoi: ${e.toString()}');
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        title: 'Connexion',
        onBackPressed: () => Get.back(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Authentification',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Entrez votre numéro de téléphone pour recevoir un code par SMS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 40),
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _errorText.isEmpty ? null : _errorText,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    initialCountryCode: 'FR',
                    showCountryFlag: true,
                    showDropdownIcon: false,
                    invalidNumberMessage: 'Numéro de téléphone invalide',
                    dropdownTextStyle: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onChanged: (phone) {
                      setState(() {
                        _completePhoneNumber = phone.completeNumber;
                        _errorText = '';
                      });
                    },
                  ),
                  if (_errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorText,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator.adaptive()
                              : const Text(
                                'Envoyer le code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
