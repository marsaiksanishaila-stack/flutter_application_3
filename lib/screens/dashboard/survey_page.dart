
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/survey.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class _SurveyTheme {
  static const Color primary = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color background = Color(0xFFF3F5F0);
  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);
  static const Color textMuted = Color(0xFF929A91);
  static const Color border = Color(0xFFDCE2D8);
  static const Color softGreen = Color(0xFFE8EEE5);

  static const Color success = Color(0xFF71866C);
  static const Color error = Color(0xFFB85C56);
}

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  static const String _surveyEndpoint =
      'https://sijala.biz.id/api/v1/surveys';

  List<Survey> _surveys = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  Future<void> fetchSurveys({bool isRefresh = false}) async {
    if (!isRefresh && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        _showSnackBar(
          'Sesi telah berakhir. Silakan login kembali.',
          false,
        );

        context.go('/');
        return;
      }

      final response = await http
          .get(
            Uri.parse(_surveyEndpoint),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('GET SURVEY STATUS: ${response.statusCode}');
      debugPrint('GET SURVEY RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        _showSnackBar(
          'Sesi telah berakhir. Silakan login kembali.',
          false,
        );

        context.go('/');
        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> data = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['surveys'] is List) {
            data = decoded['surveys'];
          }
        } else if (decoded is List) {
          data = decoded;
        }

        final List<Survey> loadedSurveys = [];

        for (final item in data) {
          if (item is Map<String, dynamic>) {
            try {
              loadedSurveys.add(Survey.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing survey: $e');
            }
          }
        }

        if (!mounted) return;

        setState(() {
          _surveys = loadedSurveys;
          _isLoading = false;
          _errorMessage = null;
        });

        return;
      }

      throw Exception(
        'Gagal memuat survey (Kode: ${response.statusCode})',
      );
    } on SocketException {
      if (!mounted) return;

      _handleError(
        'Tidak dapat terhubung ke server.',
        isRefresh,
      );
    } on TimeoutException {
      if (!mounted) return;

      _handleError(
        'Koneksi terlalu lama. Silakan coba lagi.',
        isRefresh,
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      _handleError(message, isRefresh);
    } finally {
      if (mounted && !isRefresh) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleError(String message, bool isRefresh) {
    if (!mounted) return;

    setState(() {
      if (!isRefresh || _surveys.isEmpty) {
        _errorMessage = message;
      }

      _isLoading = false;
    });

    if (isRefresh) {
      _showSnackBar(message, false);
    }
  }

  Future<void> _handleCardTap(Survey survey) async {
    try {
      final result = await context.push(
        '/survey-detail',
        extra: survey.id,
      );

      if (result == true && mounted) {
        await fetchSurveys(isRefresh: true);
      }
    } catch (e) {
      debugPrint('Error membuka detail survey: $e');

      if (!mounted) return;

      _showSnackBar(
        'Tidak dapat membuka detail survey.',
        false,
      );
    }
  }

  Future<void> _handleAddSurvey() async {
    try {
      final result = await context.push('/add-survey');

      if (result == true && mounted) {
        await fetchSurveys(isRefresh: true);
      }
    } catch (e) {
      debugPrint('Error membuka tambah survey: $e');

      if (!mounted) return;

      _showSnackBar(
        'Tidak dapat membuka halaman tambah survey.',
        false,
      );
    }
  }

  Future<void> _openGoogleMaps(Survey survey) async {
    if (!survey.hasValidCoordinates) {
      _showSnackBar('Lokasi survey tidak tersedia.', false);
      return;
    }

    final latitude = survey.latitude!;
    final longitude = survey.longitude!;

    final Uri mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );

    try {
      final launched = await launchUrl(
        mapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showSnackBar(
          'Tidak dapat membuka Google Maps.',
          false,
        );
      }
    } catch (e) {
      debugPrint('Error membuka Google Maps: $e');

      if (!mounted) return;

      _showSnackBar('Gagal membuka Google Maps.', false);
    }
  }

  void _showSnackBar(String message, bool success) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            success ? _SurveyTheme.success : _SurveyTheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SurveyTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _SurveyTheme.primaryDark,
          backgroundColor: Colors.white,
          onRefresh: () => fetchSurveys(isRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildSummary(),
              ),
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildLoadingState(),
                )
              else if (_errorMessage != null && _surveys.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (_surveys.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                _buildSurveyList(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_isLoading ||
        _errorMessage != null ||
        _surveys.isEmpty) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _handleAddSurvey,
      backgroundColor: _SurveyTheme.primaryDark,
      foregroundColor: Colors.white,
      elevation: 5,
      icon: const Icon(Icons.add_location_alt_rounded),
      label: const Text(
        'Tambah Survey',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF687864),
            Color(0xFF8FA28A),
            Color(0xFFAEBCA9),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.location_searching_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Survey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pantau hasil survey masyarakat',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  fetchSurveys(isRefresh: true);
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Temukan laporan survey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih salah satu data untuk melihat '
            'detail lokasi dan informasi survey.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalLokasi = _surveys
        .where((survey) => survey.hasValidCoordinates)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.assignment_rounded,
              title: 'Total Survey',
              value: _surveys.length.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.location_on_rounded,
              title: 'Dengan Lokasi',
              value: totalLokasi.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _SurveyTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _SurveyTheme.softGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: _SurveyTheme.primaryDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _SurveyTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    color: _SurveyTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildSurveyItem(
                _surveys[index],
                index,
              ),
            );
          },
          childCount: _surveys.length,
        ),
      ),
    );
  }

  Widget _buildSurveyItem(Survey survey, int index) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _handleCardTap(survey),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _SurveyTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _SurveyTheme.softGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: _SurveyTheme.primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _SurveyTheme.softGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            survey.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _SurveyTheme.primaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          survey.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _SurveyTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _SurveyTheme.textMuted,
                    size: 25,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _SurveyTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  survey.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SurveyTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: _SurveyTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      survey.formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SurveyTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (survey.hasValidCoordinates)
                    GestureDetector(
                      onTap: () => _openGoogleMaps(survey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _SurveyTheme.softGreen,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: _SurveyTheme.primaryDark,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Lokasi',
                              style: TextStyle(
                                color: _SurveyTheme.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCardTap(survey),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                  ),
                  label: const Text('Lihat Detail Survey'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _SurveyTheme.primaryDark,
                    side: const BorderSide(
                      color: _SurveyTheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                _SurveyTheme.primary,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat data survey...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _SurveyTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E3E1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: _SurveyTheme.error,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Data Tidak Dapat Dimuat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _SurveyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _errorMessage ??
                  'Terjadi kesalahan saat mengambil data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _SurveyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                fetchSurveys();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _SurveyTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFDDE6D9),
                    Color(0xFFF0F4ED),
                  ],
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(26),
                ),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: _SurveyTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Data Survey',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _SurveyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum ada hasil survey yang tersedia. '
              'Silakan tambahkan survey baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _SurveyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _handleAddSurvey,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Survey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _SurveyTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
