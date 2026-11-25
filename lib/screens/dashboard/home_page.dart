import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color background = Color(0xFFF3F5F0);
  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);

  bool isLoading = true;
  String? errorMessage;

  int totalSurvey = 0;
  List<dynamic> surveys = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
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
        Uri.parse('http://sijala.biz.id/api/v1/dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        Map<String, dynamic> data = {};

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            data = Map<String, dynamic>.from(decoded['data']);
          } else {
            data = decoded;
          }
        }

        List<dynamic> surveyData = [];

        if (data['surveys'] is List) {
          surveyData = data['surveys'];
        } else if (data['recent_surveys'] is List) {
          surveyData = data['recent_surveys'];
        } else if (data['latest_surveys'] is List) {
          surveyData = data['latest_surveys'];
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['surveys'] is List) {
            surveyData = decoded['surveys'];
          }
        }

        int jumlahSurvey = 0;

        if (data['total_surveys'] is int) {
          jumlahSurvey = data['total_surveys'];
        } else if (data['total_survey'] is int) {
          jumlahSurvey = data['total_survey'];
        } else if (data['survey_count'] is int) {
          jumlahSurvey = data['survey_count'];
        } else {
          jumlahSurvey = surveyData.length;
        }

        if (!mounted) return;

        setState(() {
          totalSurvey = jumlahSurvey;
          surveys = surveyData;
          isLoading = false;
        });
      } else if (response.statusCode == 401 ||
          response.statusCode == 403) {
        await prefs.remove('token');

        if (!mounted) return;

        context.go('/');
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage =
              'Gagal mengambil data dashboard (${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Tidak dapat terhubung ke server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryDark,
          onRefresh: fetchDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 25),

                if (isLoading)
                  _buildLoading()
                else if (errorMessage != null)
                  _buildError()
                else
                  _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang 👋',
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Dashboard',
              style: TextStyle(
                color: textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            context.go('/profile');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeCard(),

        const SizedBox(height: 28),

        const Text(
          'Jumlah Survey',
          style: TextStyle(
            color: textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        _buildTotalSurveyCard(),

        const SizedBox(height: 28),

        const Text(
          'Menu Utama',
          style: TextStyle(
            color: textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: _menuCard(
                icon: Icons.add_location_alt_outlined,
                title: 'Buat Survey',
                subtitle: 'Tambah laporan',
                onTap: () {
                  context.go('/add-survey');
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _menuCard(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Data akun',
                onTap: () {
                  context.go('/profile');
                },
              ),
            ),
          ],
        ),

        if (surveys.isNotEmpty) ...[
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Survey Terbaru',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/dashboard');
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...surveys.take(5).map(
                (survey) => _surveyCard(survey),
              ),
        ],
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sampaikan Laporan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bantu membuat lingkungan menjadi lebih baik dengan menyampaikan survey.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    context.go('/add-survey');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buat Survey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSurveyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: primaryDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Survey',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jumlah survey yang tersedia',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            totalSurvey.toString(),
            style: const TextStyle(
              color: primaryDark,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _surveyCard(dynamic survey) {
    if (survey is! Map) {
      return const SizedBox.shrink();
    }

    final data = Map<String, dynamic>.from(survey);

    final title = _getString(
      data,
      [
        'title',
        'judul',
        'name',
        'nama',
      ],
    );

    final description = _getString(
      data,
      [
        'description',
        'deskripsi',
        'isi',
      ],
    );

    final id = _getInt(
      data,
      [
        'id',
        'survey_id',
        'id_survey',
      ],
    );

    return InkWell(
      onTap: () {
        if (id > 0) {
          context.go(
            '/survey-detail',
            extra: id,
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: textSecondary,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: primaryDark,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off,
              color: Colors.red,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Gagal Memuat Dashboard',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: fetchDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  int _getInt(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
    }

    return 0;
  }

  String _getString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return '-';
  }
}

