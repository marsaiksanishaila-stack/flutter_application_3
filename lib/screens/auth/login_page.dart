import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color background = Color(0xFFF3F5F0);

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('https://sijala.biz.id/api/v1/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }

      if (response.statusCode == 200 &&
          (decoded['status'] == true ||
              decoded['status'] == 'success')) {
        final userData = decoded['data'];

        if (userData is! Map<String, dynamic>) {
          throw const FormatException();
        }

        final token = userData['token'];

        if (token is! String || token.isEmpty) {
          throw const FormatException();
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userData));

        if (!mounted) return;

        context.go('/dashboard');
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decoded['message']?.toString() ?? 'Login gagal',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on FormatException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respons server tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: primaryDark,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9F6),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFDCE2D8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFDCE2D8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8EDE4),
              Color(0xFFD5DFD0),
              Color(0xFFF3F5F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 3600,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDark.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 36,
                            color: primaryDark,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'FIELD SURVEY',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF283127),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Silakan masuk ke akun Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF929A91),
                          ),
                        ),

                        const SizedBox(height: 30),

                        fieldLabel('Email'),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Email wajib diisi';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                          decoration: inputDecoration(
                            hint: 'Masukkan email',
                            icon: Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 18),

                        fieldLabel('Password'),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                          onFieldSubmitted: (_) {
                            if (!isLoading) login();
                          },
                          validator: (value) {
                            final password = value ?? '';

                            if (password.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            if (password.length < 6) {
                              return 'Password minimal 6 karakter';
                            }

                            return null;
                          },
                          decoration: inputDecoration(
                            hint: 'Masukkan password',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  primaryDark.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                color: Color(0xFF687168),
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}