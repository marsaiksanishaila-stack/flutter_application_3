
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String baseUrl = 'https://sijala.biz.id/api/v1';
  static const String profileEndpoint = '$baseUrl/profile';
  static const String imageEndpoint = 'https://sijala.biz.id/api/image';

  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color primaryLight = Color(0xFFB7C3B2);
  static const Color background = Color(0xFFF3F5F0);
  static const Color surface = Color(0xFFFFFEFA);
  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);
  static const Color textMuted = Color(0xFF929A91);
  static const Color border = Color(0xFFDCE2D8);
  static const Color softGreen = Color(0xFFE8EEE5);
  static const Color error = Color(0xFFB85C56);

  Map<String, dynamic>? profile;
  Future<Uint8List?>? profileImageFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        context.go('/');
        return;
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 &&
          data is Map &&
          data['status'] == true &&
          data['data'] is Map) {
        final profileData =
            Map<String, dynamic>.from(data['data']);

        final photo = profileData['photo']?.toString();

        if (!mounted) return;

        setState(() {
          profile = profileData;
          profileImageFuture =
              photo != null && photo.isNotEmpty
                  ? fetchProfileImage(photo)
                  : null;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;
        context.go('/');
      } else {
        throw Exception(
          data is Map
              ? data['message'] ?? 'Gagal mengambil data profil.'
              : 'Gagal mengambil data profil.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Uint8List?> fetchProfileImage(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$imageEndpoint/$fileName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      debugPrint('IMAGE ERROR: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.logout_rounded,
          color: error,
          size: 35,
        ),
        title: const Text(
          'Keluar dari Akun?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun sekarang?',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;
        context.go('/');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go('/');
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout gagal. Silakan coba lagi.'),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server.'),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> handleRefresh() async {
    await getProfile();
  }

  Widget profileAvatar({double size = 92}) {
    final photo = profile?['photo']?.toString();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photo != null &&
                photo.isNotEmpty &&
                profileImageFuture != null
            ? FutureBuilder<Uint8List?>(
                future: profileImageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryDark,
                      ),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  }

                  return const ColoredBox(
                    color: softGreen,
                    child: Icon(
                      Icons.person_rounded,
                      size: 46,
                      color: primaryDark,
                    ),
                  );
                },
              )
            : const ColoredBox(
                color: softGreen,
                child: Icon(
                  Icons.person_rounded,
                  size: 46,
                  color: primaryDark,
                ),
              ),
      ),
    );
  }

  Widget profileHeader() {
    final name = profile?['name']?.toString() ?? 'Pengguna';
    final username = profile?['username']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 25, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'PROFIL PENGGUNA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.verified_user_outlined,
                color: Colors.white,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 25),
          profileAvatar(size: 100),
          const SizedBox(height: 15),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.17),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@$username',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.25),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'FIELD SURVEY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 20,
              color: primaryDark,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget profileInformation() {
    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: cardDecoration(),
        child: const Text(
          'Data profil tidak ditemukan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    String gender = profile!['gender']?.toString() ?? '-';

    if (gender.toUpperCase() == 'L') {
      gender = 'Laki-laki';
    } else if (gender.toUpperCase() == 'P') {
      gender = 'Perempuan';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(
            'Informasi Pribadi',
            subtitle: 'Informasi akun yang terdaftar',
          ),
          const SizedBox(height: 12),
          infoItem(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: profile!['username']?.toString() ?? '-',
          ),
          Divider(color: border, height: 1),
          infoItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile!['email']?.toString() ?? '-',
          ),
          Divider(color: border, height: 1),
          infoItem(
            icon: Icons.phone_outlined,
            label: 'Nomor HP',
            value: profile!['phone']?.toString() ?? '-',
          ),
          Divider(color: border, height: 1),
          infoItem(
            icon: Icons.wc_rounded,
            label: 'Jenis Kelamin',
            value: gender,
          ),
          Divider(color: border, height: 1),
          infoItem(
            icon: Icons.place_outlined,
            label: 'Tempat Lahir',
            value: profile!['birth_place']?.toString() ?? '-',
          ),
          Divider(color: border, height: 1),
          infoItem(
            icon: Icons.calendar_month_outlined,
            label: 'Tanggal Lahir',
            value: profile!['birth_date']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? error : primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLogout
                        ? error.withOpacity(0.09)
                        : softGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isLogout ? error : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLogout ? error : textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 28,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              'Profil Saya',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: isLoading ? null : getProfile,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryDark,
          backgroundColor: surface,
          onRefresh: handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    decoration: cardDecoration(),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          color: primaryDark,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Memuat profil...',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  )
                else ...[
                  profileHeader(),
                  const SizedBox(height: 25),
                  profileInformation(),
                  const SizedBox(height: 25),
                  sectionTitle(
                    'Pengaturan Akun',
                    subtitle: 'Kelola informasi dan akses akunmu',
                  ),
                  const SizedBox(height: 14),
                  actionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Profil',
                    subtitle: 'Perbarui informasi pribadi kamu',
                    onTap: () async {
                      final result = await context.push(
                        '/edit-profile',
                        extra: profile,
                      );

                      if (result == true) {
                        await getProfile();
                      }
                    },
                  ),
                  actionCard(
                    icon: Icons.logout_rounded,
                    title: 'Keluar dari Akun',
                    subtitle: 'Keluar dari aplikasi FIELD SURVEY',
                    isLogout: true,
                    onTap: logout,
                  ),
                ],
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'FIELD SURVEY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: primaryDark,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Survey lapangan lebih mudah dan terorganisir',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
