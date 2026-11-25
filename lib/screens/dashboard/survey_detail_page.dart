import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/screens/auth/login_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  static const Color primary = Color(0xFF8FA28A);

  static const Color primaryDark = Color(0xFF657761);

  // static const Color primaryLight =
  // Color(0xFFB8C5B3);

  static const Color background = Color(0xFFF5F7F3);

  static const Color textDark = Color(0xFF273128);

  static const Color textGrey = Color(0xFF6B756C);

  static const Color border = Color(0xFFDDE4DA);

  static const Color danger = Color(0xFFB94A48);

  Map<String, dynamic>? survey;

  bool isLoading = true;

  String? errorMessage;

  Uint8List? imageBytes;

  bool isLoadingImage = false;

  @override
  void initState() {
    super.initState();

    fetchDetail();
  }

  Future<void> fetchDetail() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        imageBytes = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      final url = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('DETAIL STATUS: ${response.statusCode}');

      debugPrint('DETAIL RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );

        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result is Map && result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);

          if (!mounted) return;

          setState(() {
            survey = data;
            isLoading = false;
          });

          final photoName = data['photo']?.toString();

          if (photoName != null &&
              photoName.isNotEmpty &&
              photoName != 'null' &&
              photoName != 'placeholder.jpg') {
            fetchImage(photoName, token);
          }

          return;
        }
      }

      throw Exception('Survey tidak ditemukan');
    } catch (e) {
      debugPrint('Error detail survey: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Gagal memuat detail survey.\n'
            'Periksa koneksi internet Anda.';
      });
    }
  }

  Future<void> fetchImage(String photoName, String token) async {
    if (!mounted) return;

    setState(() {
      isLoadingImage = true;
    });

    try {
      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final url = Uri.parse('https://sijala.biz.id/api/image/$fileName');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          imageBytes = response.bodyBytes;

          isLoadingImage = false;
        });

        return;
      }
    } catch (e) {
      debugPrint('Error mengambil gambar: $e');
    }

    if (!mounted) return;

    setState(() {
      isLoadingImage = false;
    });
  }

  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hapus Survey?',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          content: const Text(
            'Data survey ini akan dihapus '
            'dan tidak dapat dikembalikan.',
            style: TextStyle(color: textGrey, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: textGrey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(
          'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}/delete',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey berhasil dihapus'),
            backgroundColor: Color(0xFF6F8F72),
          ),
        );

        Navigator.pop(context, true);
      } else {
        _showMessage(
          'Gagal menghapus survey '
          '(Kode: ${response.statusCode})',
          false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Terjadi kesalahan saat menghapus survey.', false);
    }
  }

  Future<void> editSurvey() async {
    if (survey == null) return;

    final result = await context.push('/edit-survey', extra: survey);

    if (result == true && mounted) {
      fetchDetail();
    }
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$lat,$lng',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Tidak dapat membuka Google Maps', false);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal membuka Google Maps', false);
    }
  }

  void copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));

    _showMessage('Koordinat berhasil disalin!', true);
  }

  void showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: .8,
                  maxScale: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, bool success) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF6F8F72) : danger,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
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
      backgroundColor: background,

      body: SafeArea(child: buildBody()),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return _buildLoading();
    }

    if (errorMessage != null || survey == null) {
      return _buildError();
    }

    return _buildContent();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 3, color: primary),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat detail survey...',
            style: TextStyle(color: textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFE5E2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: danger,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Tidak dapat memuat survey',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              errorMessage ?? 'Survey tidak ditemukan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: fetchDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
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

  Widget _buildContent() {
    final title = survey!['title']?.toString() ?? '-';

    final description = survey!['description']?.toString() ?? '-';

    final category =
        survey!['category_name']?.toString() ??
        survey!['category']?['name']?.toString() ??
        'Tanpa Kategori';

    final date = survey!['created_at']?.toString() ?? '-';

    final lat = double.tryParse(survey!['latitude']?.toString() ?? '');

    final lng = double.tryParse(survey!['longitude']?.toString() ?? '');

    final hasLocation = lat != null && lng != null;

    return RefreshIndicator(
      color: primary,
      onRefresh: fetchDetail,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(title, category, date)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 35),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPhotoSection(),

                const SizedBox(height: 18),

                _buildInfoSection(title, category, date),

                const SizedBox(height: 18),

                _buildDescription(description),

                const SizedBox(height: 18),

                _buildLocation(lat, lng, hasLocation),

                const SizedBox(height: 25),

                _buildBottomActions(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String category, String date) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Detail Survey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              _headerButton(
                icon: Icons.more_horiz_rounded,
                onTap: _showMoreMenu,
              ),
            ],
          ),

          const SizedBox(height: 25),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: _menuIcon(Icons.edit_outlined),
                  title: const Text('Edit Survey'),
                  onTap: () {
                    Navigator.pop(context);
                    editSurvey();
                  },
                ),

                ListTile(
                  leading: _menuIcon(Icons.delete_outline, danger),
                  title: const Text(
                    'Hapus Survey',
                    style: TextStyle(color: danger),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    deleteSurvey();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuIcon(IconData icon, [Color color = primary]) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoadingImage
          ? const Center(child: CircularProgressIndicator(color: primary))
          : imageBytes != null
          ? GestureDetector(
              onTap: () => showFullImageDialog(imageBytes!),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),

                  Positioned(
                    left: 15,
                    bottom: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ketuk untuk melihat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _emptyPhoto(),
    );
  }

  Widget _emptyPhoto() {
    return Container(
      color: const Color(0xFFEEF2EC),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 45, color: primary),
          SizedBox(height: 10),
          Text(
            'Tidak ada foto survey',
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String category, String date) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.info_outline_rounded, 'Informasi Survey'),

          const SizedBox(height: 18),

          _infoRow(icon: Icons.title_rounded, label: 'Judul', value: title),

          const SizedBox(height: 14),

          _infoRow(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: category,
          ),

          const SizedBox(height: 14),

          _infoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Dibuat',
            value: date,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryDark, size: 18),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: textGrey, fontSize: 10),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.notes_rounded, 'Deskripsi'),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              description,
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(double? lat, double? lng, bool hasLocation) {
    return _sectionContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 13),
            child: _sectionTitle(Icons.location_on_rounded, 'Lokasi Survey'),
          ),

          if (hasLocation)
            _buildMap(lat!, lng!)
          else
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3EF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, color: textGrey, size: 30),
                  SizedBox(height: 8),
                  Text(
                    'Koordinat tidak tersedia',
                    style: TextStyle(color: textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(double lat, double lng) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_2',
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFB94A48),
                        size: 43,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: primaryDark,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        '$lat, $lng',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => copyCoordinates(lat, lng),
                      icon: const Icon(Icons.content_copy_rounded, size: 16),
                      label: const Text('Salin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryDark,
                        side: const BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => openGoogleMaps(lat, lng),
                      icon: const Icon(Icons.near_me_rounded, size: 16),
                      label: const Text('Buka Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: editSurvey,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Survey'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryDark,
              side: const BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: deleteSurvey,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE1DE),
              foregroundColor: danger,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: primary.withOpacity(.11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryDark, size: 19),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
