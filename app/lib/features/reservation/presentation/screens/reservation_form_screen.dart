import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/validators.dart';
import '../providers/reservation_form_provider.dart';
import '../widgets/receipt_widget.dart';

/// Form Reservasi.
/// Spesifikasi (03_reservasi.md):
/// - Tanggal, Batch (dropdown aktif), Kendaraan (dropdown, aktif setelah tanggal+batch dipilih)
/// - Unit Kerja (autocomplete), Jenis Kebutuhan (multiline)
/// - Jika dibuka dari dashboard dengan vehicleId, kendaraan sudah terisi
class ReservationFormScreen extends ConsumerStatefulWidget {
  final int? preSelectedVehicleId;

  const ReservationFormScreen({super.key, this.preSelectedVehicleId});

  @override
  ConsumerState<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
}

class _ReservationFormScreenState
    extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workUnitCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedVehicleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(reservationFormProvider.notifier)
            .setPreSelectedVehicleId(widget.preSelectedVehicleId);
      });
    }
  }

  @override
  void dispose() {
    _workUnitCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Pilih Tanggal Reservasi',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      ref.read(reservationFormProvider.notifier).setDate(_formatDate(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final formState = ref.read(reservationFormProvider);
    if (formState.selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih batch terlebih dahulu.')),
      );
      return;
    }
    if (formState.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan terlebih dahulu.')),
      );
      return;
    }
    await ref.read(reservationFormProvider.notifier).submit(
          workUnit: _workUnitCtrl.text.trim(),
          purpose: _purposeCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(reservationFormProvider);

    // Jika sukses, tampilkan struk pengajuan
    if (formState.isSuccess && formState.createdReservation != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permohonan Diajukan')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppTheme.warningColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Permohonan Berhasil Diajukan!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: const Text(
                  'STATUS: MENUNGGU PERSETUJUAN (PENDING)',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Permohonan reservasi Anda telah terkirim ke Administrator.\nAdmin akan memeriksa dan menyetujui atau menolak permohonan ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ReceiptWidget(reservation: formState.createdReservation!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(reservationFormProvider.notifier).reset();
                  context.go('/riwayat');
                },
                child: const Text('Lihat Status di Riwayat'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Form Reservasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info kendaraan pre-selected dari dashboard
              if (widget.preSelectedVehicleId != null)
                _InfoBanner(
                  message:
                      'Kendaraan dari dashboard sudah dipilih. Cukup pilih tanggal dan batch.',
                ),

              // Error banner
              if (formState.errorMessage != null)
                _ErrorBanner(message: formState.errorMessage!),

              // ── Tanggal ───────────────────────────────
              const _SectionLabel('Tanggal Reservasi'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDate != null
                            ? _displayDate(_selectedDate!)
                            : 'Pilih tanggal',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Batch ─────────────────────────────────
              const _SectionLabel('Batch / Waktu'),
              DropdownButtonFormField<int>(
                initialValue: formState.selectedBatch?.id,
                hint: const Text('Pilih batch'),
                items: formState.batches
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.displayLabel),
                      ),
                    )
                    .toList(),
                onChanged: _selectedDate == null
                    ? null
                    : (id) {
                        final batch = formState.batches
                            .firstWhere((b) => b.id == id);
                        ref
                            .read(reservationFormProvider.notifier)
                            .setBatch(batch);
                      },
                decoration: InputDecoration(
                  hintText: _selectedDate == null
                      ? 'Pilih tanggal dulu'
                      : 'Pilih batch',
                ),
                validator: (v) =>
                    v == null ? 'Batch wajib dipilih.' : null,
              ),
              const SizedBox(height: 16),

              // ── Kendaraan ─────────────────────────────
              const _SectionLabel('Kendaraan'),
              DropdownButtonFormField<int>(
                initialValue: formState.selectedVehicle?.id,
                hint: const Text('Pilih kendaraan'),
                items: formState.availableVehicles
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.name),
                      ),
                    )
                    .toList(),
                onChanged: formState.selectedBatch == null
                    ? null
                    : (id) {
                        final vehicle = formState.availableVehicles
                            .firstWhere((v) => v.id == id);
                        ref
                            .read(reservationFormProvider.notifier)
                            .setVehicle(vehicle);
                      },
                decoration: InputDecoration(
                  hintText: formState.selectedBatch == null
                      ? 'Pilih batch dulu'
                      : formState.availableVehicles.isEmpty
                          ? 'Tidak ada kendaraan tersedia'
                          : 'Pilih kendaraan',
                ),
                validator: (v) =>
                    v == null ? 'Kendaraan wajib dipilih.' : null,
              ),
              const SizedBox(height: 16),

              // ── Unit Kerja (autocomplete) ─────────────
              const _SectionLabel('Unit Kerja'),
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) async {
                  if (textEditingValue.text.length < 2) return [];
                  await ref
                      .read(reservationFormProvider.notifier)
                      .searchWorkUnits(textEditingValue.text);
                  return ref.read(reservationFormProvider).workUnitSuggestions;
                },
                onSelected: (value) {
                  _workUnitCtrl.text = value;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  _workUnitCtrl.addListener(() {});
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Ketik unit kerja...',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) => Validators.required(v, 'Unit kerja'),
                    onChanged: (val) => _workUnitCtrl.text = val,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Jenis Kebutuhan ───────────────────────
              const _SectionLabel('Jenis Kebutuhan'),
              TextFormField(
                controller: _purposeCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Deskripsikan jenis kebutuhan...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    Validators.minLength(v, 5, 'Jenis kebutuhan'),
              ),
              const SizedBox(height: 24),

              // ── Tombol ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          formState.isSubmitting ? null : _submit,
                      child: formState.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ajukan Reservasi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.accentColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.accentColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.dangerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.dangerColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.dangerColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
