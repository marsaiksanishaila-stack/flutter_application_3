import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfilePage({
    super.key,
    this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController birthPlaceController;
  late TextEditingController birthDateController;

  String? gender;
  String? apiBirthDate;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  Future<Uint8List?>? oldProfileImageFuture;

  bool isLoading = false;

  // ============================================================
  // API
  // ============================================================

  static const String baseUrl =
      'https://sijala.biz.id/api/v1';

  static const String profileUpdateEndpoint =
      '$baseUrl/profile/update';

  static const String imageEndpoint =
      'https://sijala.biz.id/api/image';

  // ============================================================
  // WARNA TEMA
  // ============================================================

  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color primaryLight = Color(0xFFB7C3B2);

  static const Color background = Color(0xFFF3F5F0);
  static const Color surface = Color(0xFFFFFEFA);

  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);
  static const Color textMuted = Color(0xFF929A91);

  static const Color border = Color(0xFFDCE2D8);
  // static const Color softGreen = Color(0xFFE8EEE5);

  static const Color error = Color(0xFFB85C56);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final profile = widget.profile ?? {};

    nameController = TextEditingController(
      text: profile['name']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: profile['email']?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: profile['phone']?.toString() ?? '',
    );

    birthPlaceController = TextEditingController(
      text: profile['birth_place']?.toString() ?? '',
    );

    if (profile['gender'] != null) {
      final g = profile['gender']
          .toString()
          .toLowerCase();

      if (g.startsWith('u') || g == 'l') {
        gender = 'L';
      } else if (g.startsWith('p')) {
        gender = 'P';
      }
    }

    String displayBirthDate = '';

    final String? rawDate =
        profile['birth_date']?.toString();

    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        DateTime? parsedDate;

        if (rawDate.contains('-')) {
          final parts = rawDate.split('-');

          if (parts.length == 3) {
            if (parts[0].length == 4) {
              parsedDate = DateTime.parse(rawDate);
            } else if (parts[2].length == 4) {
              final int day = int.parse(parts[0]);
              final int month = int.parse(parts[1]);
              final int year = int.parse(parts[2]);

              parsedDate = DateTime(
                year,
                month,
                day,
              );
            }
          }
        }

        if (parsedDate != null) {
          final String dayStr =
              parsedDate.day.toString().padLeft(2, '0');

          final String monthStr =
              parsedDate.month.toString().padLeft(2, '0');

          final String yearStr =
              parsedDate.year.toString();

          displayBirthDate =
              '$dayStr-$monthStr-$yearStr';

          apiBirthDate =
              '$yearStr-$monthStr-$dayStr';
        } else {
          displayBirthDate = rawDate;
          apiBirthDate = rawDate;
        }
      } catch (_) {
        displayBirthDate = rawDate;
        apiBirthDate = rawDate;
      }
    }

    birthDateController =
        TextEditingController(
      text: displayBirthDate,
    );

    final oldPhoto =
        profile['photo']?.toString();

    if (oldPhoto != null && oldPhoto.isNotEmpty) {
      oldProfileImageFuture =
          fetchProfileImage(oldPhoto);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();

    super.dispose();
  }

  // ============================================================
  // JSON
  // ============================================================

  dynamic safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,

      hintStyle: const TextStyle(
        color: textMuted,
      ),

      prefixIcon: Icon(
        icon,
        color: primaryDark,
      ),

      filled: true,
      fillColor: surface,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: primary,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: error,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: error,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile =
          await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes =
            await pickedFile.readAsBytes();

        setState(() {
          selectedImage = pickedFile;
          selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengambil gambar dari galeri.',
          ),
          backgroundColor: error,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // AMBIL FOTO LAMA
  // ============================================================

  Future<Uint8List?> fetchProfileImage(
    String fileName,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          '$imageEndpoint/$fileName',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Accept':
              'application/json',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PILIH TANGGAL LAHIR
  // ============================================================

  Future<void> selectBirthDate() async {
    DateTime initialDate =
        DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );

    if (apiBirthDate != null &&
        apiBirthDate!.isNotEmpty) {
      try {
        initialDate =
            DateTime.parse(apiBirthDate!);
      } catch (_) {}
    }

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(days: 1),
      ),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary: primaryDark,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String day =
          picked.day.toString().padLeft(2, '0');

      final String month =
          picked.month.toString().padLeft(2, '0');

      final String year =
          picked.year.toString();

      setState(() {
        birthDateController.text =
            '$day-$month-$year';

        apiBirthDate =
            '$year-$month-$day';
      });
    }
  }

  // ============================================================
  // SIMPAN PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (gender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih jenis kelamin.',
          ),
          backgroundColor: error,
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          profileUpdateEndpoint,
        ),
      );

      request.headers['Accept'] =
          'application/json';

      request.headers['Authorization'] =
          'Bearer $token';

      request.fields['name'] =
          nameController.text.trim();

      request.fields['email'] =
          emailController.text.trim();

      request.fields['phone'] =
          phoneController.text.trim();

      request.fields['gender'] =
          gender!;

      request.fields['birth_place'] =
          birthPlaceController.text.trim();

      if (apiBirthDate != null) {
        request.fields['birth_date'] =
            apiBirthDate!;
      }

      if (selectedImage != null &&
          selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamedResponse =
          await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      final data =
          safeJsonDecode(response.body);

      if (streamedResponse.statusCode == 200) {
        if (data != null &&
            data['status'] == true) {
          if (data['data'] != null) {
            await prefs.setString(
              'user',
              jsonEncode(data['data']),
            );
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Profil berhasil diperbarui.',
              ),
              backgroundColor: primaryDark,
              behavior:
                  SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(
            context,
            true,
          );
        } else {
          throw Exception(
            data?['message'] ??
                'Gagal memperbarui profil.',
          );
        }
      } else if (streamedResponse.statusCode ==
          422) {
        String validationErrors = '';

        if (data != null &&
            data['errors'] != null &&
            data['errors'] is Map) {
          final errorsMap =
              data['errors'] as Map;

          for (var key in errorsMap.keys) {
            final List messages =
                errorsMap[key];

            for (var msg in messages) {
              validationErrors +=
                  '$msg\n';
            }
          }
        }

        if (validationErrors.isEmpty) {
          validationErrors =
              data?['message'] ??
                  'Validasi gagal.';
        }

        throw Exception(
          validationErrors.trim(),
        );
      } else if (streamedResponse.statusCode ==
          401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        context.go('/');

        throw Exception(
          'Sesi telah berakhir. Silakan login kembali.',
        );
      } else {
        throw Exception(
          'Gagal memperbarui profil. '
          'Error Code: '
          '${streamedResponse.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      String msg = e
          .toString()
          .replaceAll(
            'Exception: ',
            '',
          );

      if (msg
              .toLowerCase()
              .contains('socket') ||
          msg
              .toLowerCase()
              .contains(
                'failed to connect',
              ) ||
          msg
              .toLowerCase()
              .contains(
                'clientexception',
              )) {
        msg =
            'Tidak dapat terhubung ke server. '
            'Periksa koneksi internet Anda.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error,
          behavior:
              SnackBarBehavior.floating,
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

  // ============================================================
  // CARD DECORATION
  // ============================================================

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: surface,

      borderRadius:
          BorderRadius.circular(22),

      border: Border.all(
        color: border,
      ),

      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset:
              const Offset(0, 6),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oldPhoto =
        widget.profile?['photo']
            ?.toString();

    return Scaffold(
      backgroundColor: background,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        centerTitle: true,

        backgroundColor: primary,

        foregroundColor:
            Colors.white,

        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(22),

                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        primary,
                        primaryDark,
                      ],
                    ),

                    borderRadius:
                        BorderRadius.circular(
                            24),

                    boxShadow: [
                      BoxShadow(
                        color: primaryDark
                            .withOpacity(
                                0.15),
                        blurRadius: 18,
                        offset:
                            const Offset(
                                0, 8),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      // FOTO
                      Container(
                        width: 108,
                        height: 108,

                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,

                          color:
                              Colors.white
                                  .withOpacity(
                                      0.18),

                          border:
                              Border.all(
                            color: Colors
                                .white
                                .withOpacity(
                                    0.45),
                            width: 3,
                          ),
                        ),

                        child:
                            ClipOval(
                          child:
                              selectedImageBytes !=
                                      null
                                  ? Image.memory(
                                      selectedImageBytes!,
                                      width:
                                          108,
                                      height:
                                          108,
                                      fit: BoxFit
                                          .cover,
                                    )
                                  : oldPhoto !=
                                              null &&
                                          oldPhoto
                                              .isNotEmpty
                                      ? FutureBuilder<
                                          Uint8List?>(
                                          future:
                                              oldProfileImageFuture,

                                          builder:
                                              (
                                            context,
                                            snapshot,
                                          ) {
                                            if (snapshot
                                                    .connectionState ==
                                                ConnectionState
                                                    .waiting) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2.5,
                                                  color:
                                                      Colors.white,
                                                ),
                                              );
                                            }

                                            if (snapshot
                                                    .hasData &&
                                                snapshot.data !=
                                                    null) {
                                              return Image
                                                  .memory(
                                                snapshot
                                                    .data!,
                                                width:
                                                    108,
                                                height:
                                                    108,
                                                fit: BoxFit
                                                    .cover,
                                              );
                                            }

                                            return const Icon(
                                              Icons
                                                  .person_rounded,
                                              size:
                                                  55,
                                              color:
                                                  Colors.white,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons
                                              .person_rounded,
                                          size:
                                              55,
                                          color:
                                              Colors.white,
                                        ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      const Text(
                        'Edit Profil',
                        style:
                            TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Colors.white,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        'Perbarui informasi akun kamu',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 13,
                          color: Colors
                              .white
                              .withOpacity(
                                  0.85),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // UBAH FOTO
                      TextButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : pickImage,

                        style:
                            TextButton.styleFrom(
                          foregroundColor:
                              Colors.white,

                          backgroundColor:
                              Colors.white
                                  .withOpacity(
                                      0.14),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                        ),

                        icon:
                            const Icon(
                          Icons
                              .photo_library_rounded,
                          size: 19,
                        ),

                        label:
                            const Text(
                          'Ubah Foto Profil',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // FORM CARD
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      cardDecoration(),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      const Text(
                        'Informasi Pribadi',
                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'Periksa dan perbarui data pribadi kamu.',
                        style:
                            TextStyle(
                          fontSize: 13,
                          color:
                              textSecondary,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // NAMA
                      // ==================================================

                      const Text(
                        'Nama',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextFormField(
                        controller:
                            nameController,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Nama Lengkap Anda',
                          icon:
                              Icons.person_outline_rounded,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Nama wajib diisi';
                          }

                          if (value
                                  .trim()
                                  .length >
                              255) {
                            return 'Nama maksimal 255 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      const Text(
                        'Email',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextFormField(
                        controller:
                            emailController,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'alamat@email.com',
                          icon:
                              Icons.email_outlined,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Email wajib diisi';
                          }

                          if (!value
                              .contains(
                                  '@')) {
                            return 'Format email tidak valid';
                          }

                          if (value
                                  .trim()
                                  .length >
                              255) {
                            return 'Email maksimal 255 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // ==================================================
                      // NOMOR HP
                      // ==================================================

                      const Text(
                        'Nomor HP',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextFormField(
                        controller:
                            phoneController,

                        keyboardType:
                            TextInputType.phone,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            inputDecoration(
                          hintText:
                              '08xxxxxxxxxx',
                          icon:
                              Icons.phone_outlined,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }

                          final numStr =
                              value.trim();

                          if (numStr.length <
                              10) {
                            return 'Nomor HP minimal 10 digit';
                          }

                          if (numStr.length >
                              15) {
                            return 'Nomor HP maksimal 15 digit';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // ==================================================
                      // JENIS KELAMIN
                      // ==================================================

                      const Text(
                        'Jenis Kelamin',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value: gender,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Pilih jenis kelamin',
                          icon:
                              Icons.wc_outlined,
                        ),

                        dropdownColor:
                            surface,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    15),

                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text(
                                'Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text(
                                'Perempuan'),
                          ),
                        ],

                        onChanged:
                            isLoading
                                ? null
                                : (value) {
                                    setState(
                                        () {
                                      gender =
                                          value;
                                    });
                                  },

                        validator:
                            (value) {
                          if (value ==
                              null) {
                            return 'Jenis kelamin wajib dipilih';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // ==================================================
                      // TEMPAT LAHIR
                      // ==================================================

                      const Text(
                        'Tempat Lahir',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextFormField(
                        controller:
                            birthPlaceController,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Kota tempat Anda lahir',
                          icon:
                              Icons.location_on_outlined,
                        ),

                        validator:
                            (value) {
                          if (value !=
                                  null &&
                              value
                                      .trim()
                                      .length >
                                  100) {
                            return 'Tempat lahir maksimal 100 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      // ==================================================
                      // TANGGAL LAHIR
                      // ==================================================

                      const Text(
                        'Tanggal Lahir',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      TextFormField(
                        controller:
                            birthDateController,

                        readOnly: true,

                        onTap:
                            isLoading
                                ? null
                                : selectBirthDate,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Pilih tanggal lahir Anda',
                          icon:
                              Icons
                                  .calendar_today_outlined,
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value.isEmpty) {
                            return 'Tanggal lahir wajib dipilih';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // SIMPAN
                      // ==================================================

                      SizedBox(
                        height: 54,
                        width:
                            double.infinity,

                        child:
                            ElevatedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : saveProfile,

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryDark,

                            foregroundColor:
                                Colors.white,

                            disabledBackgroundColor:
                                primaryLight,

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      15),
                            ),
                          ),

                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.5,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      Icons
                                          .save_rounded,
                                      size: 21,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'SIMPAN PERUBAHAN',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // FOOTER
                // ==================================================

                const Text(
                  'FIELD SURVEY',
                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1.2,
                    color:
                        textMuted,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'Survey lapangan lebih mudah dan terorganisir',
                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        textMuted,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}