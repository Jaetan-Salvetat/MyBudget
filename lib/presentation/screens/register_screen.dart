import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/presentation/providers/auth_provider.dart';
import 'package:mybudget/presentation/providers/privacy_provider.dart';
import 'package:mybudget/presentation/screens/privacy_policy_screen.dart';
import 'package:mybudget/presentation/widgets/auth/auth_background.dart';
import 'package:mybudget/presentation/widgets/auth/auth_button.dart';
import 'package:mybudget/presentation/widgets/auth/auth_text_field.dart';
import 'package:mybudget/presentation/widgets/auth/consent_checkbox.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _privacyPolicyConsent = false;
  bool _privacyPolicyError = false;
  String? _errorMessage;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    bool isValid = true;
    
    // Valider tous les champs
    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'Veuillez saisir votre nom';
      });
      isValid = false;
    } else {
      setState(() {
        _nameError = null;
      });
    }
    
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Veuillez saisir votre email';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Veuillez saisir un mot de passe';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }
    
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Veuillez confirmer votre mot de passe';
      });
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Les mots de passe ne correspondent pas';
      });
      isValid = false;
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }
    
    // Vérifier le consentement obligatoire
    if (!_privacyPolicyConsent) {
      setState(() {
        _privacyPolicyError = true;
      });
      isValid = false;
    } else {
      setState(() {
        _privacyPolicyError = false;
      });
    }

    if (!isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final privacyNotifier = ref.read(privacySettingsProvider.notifier);
      
      // Enregistrer l'utilisateur
      await authNotifier.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // Enregistrer les consentements RGPD
      await privacyNotifier.savePrivacySettings(
        privacyPolicyAccepted: _privacyPolicyConsent,
        marketingConsent: false,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      title: 'Inscription',
      onBackPressed: () => Navigator.pop(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _nameController,
                    label: 'Nom',
                    icon: Icons.person,
                    keyboardType: TextInputType.name,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    icon: Icons.lock,
                    obscureText: true,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    errorText: _confirmPasswordError,
                  ),
                  const SizedBox(height: 24),
                  ConsentCheckbox(
                    value: _privacyPolicyConsent,
                    onChanged: (value) {
                      setState(() {
                        _privacyPolicyConsent = value ?? false;
                        if (_privacyPolicyConsent) {
                          _privacyPolicyError = false;
                        }
                      });
                    },
                    text: 'J\'ai lu et j\'accepte la',
                    linkText: 'politique de confidentialité',
                    onLinkTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                    isError: _privacyPolicyError,
                  ),
                  const SizedBox(height: 32),
                  AuthButton(
                    label: 'S\'inscrire',
                    onPressed: _register,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
