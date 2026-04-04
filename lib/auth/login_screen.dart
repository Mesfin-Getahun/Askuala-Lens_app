import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../student/app/app.dart';
import '../teacher/features/navigation/presentation/main_shell.dart';
import 'data/firestore_login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _loginService = FirestoreLoginService();

  bool _isSigningIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSigningIn = true;
    });

    try {
      final user = await _loginService.signIn(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (user == null) {
        _showMessage('Username or password is incorrect.');
        return;
      }

      final destination = switch (user.role) {
        AppUserRole.teacher => MainShell(teacher: user),
        AppUserRole.student => StudentAppHome(
          studentId: user.id,
          studentName: user.displayName,
          classSection: user.classSection,
          username: user.username,
        ),
      };

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => destination),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Firestore error: ${error.code}');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        'Could not sign in. Check Firestore profile data and your login fields.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6FFFA), Color(0xFFEFF6FF), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF115E59),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Sign in with your school account',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ' use the Askuala School given usernames and passwords',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'Enter your username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a username.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            onFieldSubmitted: (_) => _isSigningIn ? null : _signIn(),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'please use the usernames and passwords ',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSigningIn ? null : _signIn,
                              child: _isSigningIn
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
