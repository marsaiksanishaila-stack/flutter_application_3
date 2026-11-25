
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSurveyPage extends StatefulWidget {
  const AddSurveyPage({super.key});

  @override
  State<AddSurveyPage> createState() => _AddSurveyPageState();
}

class _AddSurveyPageState extends State<AddSurveyPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final MapController _mapController = MapController();

  final Color primary = const Color(0xFF8FA28A);
  final Color background = const Color(0xFFF3F5F0);
  final Color textPrimary = const Color(0xFF283127);
  final Color textSecondary = const Color(0xFF687168);
  final Color border = const Color(0xFFDCE2D8);
  final Color error = const Color(0xFFB85C56);

  final String apiUrl =
      'https://sijala.biz.id/api/v1/surveys';

  bool _isLoading = false;

  LatLng? _selectedLocation;

  final LatLng _initialLocation =
      const LatLng(-7.3594671, 108.1072377);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // PETA LOKASI SURVEY
  Widget _buildLocationMap() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
              _selectedLocation ?? _initialLocation,
          initialZoom: 15,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;

              _latitudeController.text =
                  point.latitude.toStringAsFixed(7);

              _longitudeController.text =
                  point.longitude.toStringAsFixed(7);
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.flutter_application_2',
          ),

          if (_selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation!,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSecondary),
            filled: true,
            fillColor: const Color(0xFFFFFEFA),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEE5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Lokasi Survey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Pilih lokasi dengan mengetuk peta',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // HANYA PETA, TANPA TOMBOL TAMBAHAN
          _buildLocationMap(),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Latitude',
                  controller: _latitudeController,
                  hint: 'Latitude',
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih lokasi pada peta';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Longitude',
                  controller: _longitudeController,
                  hint: 'Longitude',
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih lokasi pada peta';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      _showMessage('Silakan pilih lokasi pada peta.');
      return;
    }

    final categoryId =
        int.tryParse(_categoryController.text.trim());

    if (categoryId == null) {
      _showMessage('ID kategori harus berupa angka.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showMessage('Silakan login kembali.');
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category_id': categoryId,
          'latitude': _latitudeController.text,
          'longitude': _longitudeController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showMessage('Survey berhasil disimpan.');
        Navigator.pop(context, true);
      } else if (response.statusCode == 401) {
        _showMessage('Sesi login berakhir. Silakan login kembali.');
      } else {
        String message = 'Gagal menyimpan survey.';

        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}

        _showMessage(message);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Terjadi kesalahan koneksi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Tambah Survey'),
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                label: 'Judul Survey',
                controller: _titleController,
                hint: 'Masukkan judul survey',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul survey wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _buildTextField(
                label: 'Deskripsi',
                controller: _descriptionController,
                hint: 'Masukkan deskripsi survey',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _buildTextField(
                label: 'ID Kategori',
                controller: _categoryController,
                hint: 'Masukkan ID kategori',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ID kategori wajib diisi';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'ID kategori harus berupa angka';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              _buildLocationSection(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : _saveSurvey,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_task_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoading
                        ? 'Menyimpan...'
                        : 'Simpan Survey',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
