
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/auth/login_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  final Map<String, dynamic>? survey;

  const SurveyFormPage({
    super.key,
    this.survey,
  });

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  final MapController mapController = MapController();

  int? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? existingImageBytes;

  bool isSubmitting = false;

  LatLng? selectedLocation;

  final LatLng initialLocation =
      const LatLng(-7.3594671, 108.1072377);

  bool get isEdit => widget.survey != null;

  static const Color primaryColor = Color(0xFF8FA28A);
  static const Color primaryDark = Color(0xFF687864);
  static const Color primaryLight = Color(0xFFB7C3B2);
  static const Color backgroundColor = Color(0xFFF3F5F0);
  static const Color surfaceColor = Color(0xFFFFFEFA);
  static const Color textPrimary = Color(0xFF283127);
  static const Color textSecondary = Color(0xFF687168);
  static const Color borderColor = Color(0xFFDCE2D8);
  static const Color softGreen = Color(0xFFE8EEE5);

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final s = widget.survey!;

      titleController.text = s['title']?.toString() ?? '';

      descriptionController.text =
          s['description']?.toString() == '-'
              ? ''
              : s['description']?.toString() ?? '';

      latitudeController.text =
          s['latitude']?.toString() ?? '';

      longitudeController.text =
          s['longitude']?.toString() ?? '';

      selectedCategoryId =
          int.tryParse(s['category_id']?.toString() ?? '');

      final lat = double.tryParse(latitudeController.text);
      final lng = double.tryParse(longitudeController.text);

      if (lat != null && lng != null) {
        selectedLocation = LatLng(lat, lng);
      }

      final photoName = s['photo']?.toString();

      if (photoName != null &&
          photoName.isNotEmpty &&
          photoName != 'placeholder.jpg') {
        fetchExistingImage(photoName);
      }
    }

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    mapController.dispose();

    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['data'] is List) {
          final List rawList = decoded['data'];

          if (!mounted) return;

          setState(() {
            categories = rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            isLoadingCategories = false;
          });

          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> fetchExistingImage(String photoName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final fileName = photoName.contains('/')
          ? photoName.split('/').last
          : photoName;

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/image/$fileName'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          existingImageBytes = response.bodyBytes;
        });
      }
    } catch (_) {}
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        if (!mounted) return;

        setState(() {
          selectedImage = pickedFile;
          selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      showErrorSnackBar('Gagal memilih foto.');
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      existingImageBytes = null;
    });
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: softGreen,
                leading: const CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: softGreen,
                leading: const CircleAvatar(
                  backgroundColor: primaryDark,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PETA LOKASI SURVEY
  Widget buildLocationMap() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: selectedLocation ?? initialLocation,
          initialZoom: 15,
          onTap: (tapPosition, point) { //mnjlnkn perinth pengguna saat mengetuk peta
            setState(() {
              selectedLocation = point; 

              latitudeController.text =
                  point.latitude.toStringAsFixed(7); //mngmbil kordinat gris lintang

              longitudeController.text =
                  point.longitude.toStringAsFixed(7); //mngmbl kordint grs bjr
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_application_2',
          ),
          if (selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedLocation!,
                  width: 43,
                  height: 43,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.red,
                    size: 43,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> saveSurvey() async {
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lengkapi data yang wajib diisi.');
      return;
    }

    if (selectedCategoryId == null || selectedCategoryId == 0) {
      showErrorSnackBar('Kategori survey wajib dipilih.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      final uri = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/save',
      );

      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['title'] = titleController.text.trim();
      request.fields['category_id'] = selectedCategoryId.toString();
      request.fields['description'] =
          descriptionController.text.trim();

      if (latitudeController.text.trim().isNotEmpty) {
        request.fields['latitude'] = latitudeController.text.trim();
      }

      if (longitudeController.text.trim().isNotEmpty) {
        request.fields['longitude'] = longitudeController.text.trim();
      }

      if (isEdit) {
        request.fields['id'] = widget.survey!['id'].toString();
        request.fields['_method'] = 'PUT';
      }

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil disimpan!',
            ),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body);
        final message =
            decoded['message'] ?? 'Data yang dikirim tidak valid.';

        throw Exception(message);
      }

      throw Exception(
        'Gagal menyimpan (Kode: ${response.statusCode})',
      );
    } catch (e) {
      if (!mounted) return;

      showErrorSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFB85C56),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    String? labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: backgroundColor,
      prefixIcon: Icon(icon, color: primaryDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFB85C56),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFB85C56),
          width: 2,
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryDark),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Survey' : 'Tambah Survey',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionCard(
                title: 'Data Utama Survey',
                icon: Icons.assignment_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Judul Survey *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: titleController,
                      decoration: inputDecoration(
                        hintText: 'Masukkan judul survey',
                        icon: Icons.title_rounded,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Judul wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kategori Survey *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (isLoadingCategories)
                      const LinearProgressIndicator(
                        color: primaryColor,
                        backgroundColor: softGreen,
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: inputDecoration(
                          hintText: 'Pilih Kategori',
                          icon: Icons.category_rounded,
                        ),
                        dropdownColor: surfaceColor,
                        items: categories.map((cat) {
                          final id = int.tryParse(
                                cat['id']?.toString() ?? '',
                              ) ??
                              0;

                          final name = cat['name']?.toString() ?? '-';

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCategoryId = val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val == 0) {
                            return 'Kategori wajib dipilih';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi Survey',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: inputDecoration(
                        hintText: 'Keterangan atau catatan survey...',
                        icon: Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              sectionCard(
                title: 'Foto Survey',
                icon: Icons.photo_camera_rounded,
                child: Column(
                  children: [
                    if (selectedImageBytes != null ||
                        existingImageBytes != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              selectedImageBytes ?? existingImageBytes!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: showImageSourceDialog,
                                  icon: const Icon(
                                    Icons.photo_library_rounded,
                                  ),
                                  label: const Text('Ganti Foto'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryDark,
                                    side: const BorderSide(
                                      color: primaryColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: removeSelectedImage,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                ),
                                label: const Text('Hapus'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFFB85C56),
                                  side: const BorderSide(
                                    color: Color(0xFFB85C56),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: showImageSourceDialog,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: softGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 42,
                                color: primaryDark,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Ketuk untuk memilih foto',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Galeri atau Kamera',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // LOKASI SURVEY: PETA SAJA TANPA TOMBOL TAMBAHAN
              sectionCard(
                title: 'Lokasi Survey',
                icon: Icons.location_on_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih lokasi dengan mengetuk peta',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    buildLocationMap(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latitudeController,
                            readOnly: true,
                            decoration: inputDecoration(
                              labelText: 'Latitude',
                              hintText: 'Pilih lokasi di peta',
                              icon: Icons.my_location_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: longitudeController,
                            readOnly: true,
                            decoration: inputDecoration(
                              labelText: 'Longitude',
                              hintText: 'Pilih lokasi di peta',
                              icon: Icons.explore_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : saveSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_task_rounded,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Simpan Survey',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
