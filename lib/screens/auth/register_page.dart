import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String? gender;

  bool isLoading = false;
  bool hasSubmitted = false;

  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color background = Color(0xFFF3F5F0);
  static const Color surface = Color(0xFFFFFEFA);
  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);
  static const Color border = Color(0xFFDCE2D8);
  static const Color error = Color(0xFFB85C56);

  static const String registerUrl =
      'https://sijala.biz.id/api/v1/register';

  @override
  void initState() {
    super.initState();

    // Error hanya dihapus saat user mengedit field.
    nameController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!hasSubmitted) return;

    // Jangan validasi ulang saat mengetik.
    // Cukup hilangkan pesan error yang sudah tampil.
    _formKey.currentState?.reset();

    setState(() {
      hasSubmitted = false;
    });
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    // Validasi hanya ketika tombol Daftar ditekan.
    setState(() {
      hasSubmitted = true;
    });

    final isValid = _formKey.currentState!.validate();

    if (!isValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'gender': gender,
        }),
      );

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      debugPrint('REGISTER CODE: ${response.statusCode}');
      debugPrint('REGISTER RESPONSE: ${response.body}');

      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      final success =
          (response.statusCode == 200 ||
              response.statusCode == 201) &&
          data['status'] == true;

      if (success) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pendaftaran berhasil! Silakan login.',
            ),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (mounted) {
          context.go('/');
        }
      } else {
        String message = data['message']?.toString() ??
            'Pendaftaran gagal. Periksa kembali data kamu.';

        final errors = data['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          } else if (firstError != null) {
            message = firstError.toString();
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal terhubung ke server. Periksa koneksi internet.',
          ),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.removeListener(_onFieldChanged);
    emailController.removeListener(_onFieldChanged);
    phoneController.removeListener(_onFieldChanged);

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF929A91),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryDark,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9F6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: border),
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
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: error,
          width: 1.5,
        ),
      ),
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.disabled,
        textInputAction: TextInputAction.next,
        decoration: inputDecoration(
          hint: label,
          icon: icon,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) {
            return '$label wajib diisi';
          }

          if (label == 'Nama Lengkap' && text.length < 3) {
            return 'Nama minimal 3 karakter';
          }

          if (label == 'Email' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(text)) {
            return 'Format email tidak valid';
          }

          if (label == 'Nomor HP' &&
              !RegExp(r'^[0-9]{10,15}$').hasMatch(text)) {
            return 'Nomor HP harus 10–15 digit';
          }

          return null;
        },
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
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 3600,
                ),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: surface,
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
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 35,
                              color: primaryDark,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'FIELD SURVEY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: textPrimary,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Daftar untuk mulai menggunakan aplikasi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF929A91),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          'Buat Akun Baru',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        buildField(
                          label: 'Nama Lengkap',
                          controller: nameController,
                          icon: Icons.person_outline_rounded,
                        ),

                        buildField(
                          label: 'Email',
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        buildField(
                          label: 'Nomor HP',
                          controller: phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<String>(
                            value: gender,
                            isExpanded: true,
                            autovalidateMode: AutovalidateMode.disabled,
                            decoration: inputDecoration(
                              hint: 'Jenis Kelamin',
                              icon: Icons.wc_rounded,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'L',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'P',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                gender = value;
                              });

                              if (hasSubmitted) {
                                _formKey.currentState?.reset();

                                setState(() {
                                  hasSubmitted = false;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Pilih jenis kelamin';
                              }

                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 5),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: primary,
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1,
                                        size: 20,
                                      ),
                                      SizedBox(width: 9),
                                      Text(
                                        'Daftar',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => context.go('/'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryDark,
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
