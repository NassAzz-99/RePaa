import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/admin_vehicle_provider.dart';

class AdminVehicleFormScreen extends ConsumerStatefulWidget {
  final VehicleModel? vehicle;
  const AdminVehicleFormScreen({super.key, this.vehicle});

  @override
  ConsumerState<AdminVehicleFormScreen> createState() =>
      _AdminVehicleFormScreenState();
}

class _AdminVehicleFormScreenState
    extends ConsumerState<AdminVehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _typeCtrl;
  late String _status;
  File? _pickedPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vehicle?.name ?? '');
    _typeCtrl = TextEditingController(text: widget.vehicle?.type ?? '');
    _status = widget.vehicle?.status ?? 'available';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Ambil Foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;

    final picked =
        await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > 3 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto maksimal 3 MB.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    setState(() => _pickedPhoto = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await ref.read(adminVehicleProvider.notifier).save(
          id: widget.vehicle?.id,
          name: _nameCtrl.text.trim(),
          type: _typeCtrl.text.trim(),
          status: _status,
          photoPath: _pickedPhoto?.path,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      final err = ref.read(adminVehicleProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Gagal menyimpan.'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto ─────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _pickedPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(_pickedPhoto!,
                                fit: BoxFit.cover),
                          )
                        : widget.vehicle?.photoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                    widget.vehicle!.photoUrl!,
                                    fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 36,
                                      color: AppTheme.textSecondary),
                                  SizedBox(height: 4),
                                  Text('Pilih Foto',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('JPG/PNG/WEBP, maks 3 MB',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 20),

              // ── Nama ─────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Unit',
                  hintText: 'Forklift 2 Ton - Unit 1',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                validator: (v) => Validators.required(v, 'Nama unit'),
              ),
              const SizedBox(height: 14),

              // ── Jenis ─────────────────────────────────────
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jenis PAA',
                  hintText: 'Forklift 2 Ton',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) => Validators.required(v, 'Jenis PAA'),
              ),
              const SizedBox(height: 14),

              // ── Status ────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'available', child: Text('Tersedia')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Perawatan')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 28),

              // ── Tombol ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
