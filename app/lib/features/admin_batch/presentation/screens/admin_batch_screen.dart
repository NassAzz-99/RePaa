import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../reservation/data/models/batch_model.dart';
import '../providers/admin_batch_provider.dart';

class AdminBatchScreen extends ConsumerWidget {
  const AdminBatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminBatchProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Kelola Batch')),
      body: Builder(builder: (context) {
        if (state.isLoading && state.batches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info banner
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Batch berlaku setiap hari. Nonaktifkan batch agar tidak muncul di form reservasi.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.accentColor),
                  ),
                ),
              ]),
            ),

            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.errorMessage!,
                    style: const TextStyle(color: AppTheme.dangerColor)),
              ),

            ...state.batches.map((b) => _BatchCard(
                  batch: b,
                  isSaving: state.savingId == b.id,
                  onSave: (name, start, end, active) => ref
                      .read(adminBatchProvider.notifier)
                      .updateBatch(
                        id: b.id,
                        name: name,
                        startTime: start,
                        endTime: end,
                        isActive: active,
                      ),
                )),
          ],
        );
      }),
    );
  }
}

class _BatchCard extends StatefulWidget {
  final BatchModel batch;
  final bool isSaving;
  final Future<bool> Function(
      String name, String start, String end, bool active) onSave;

  const _BatchCard(
      {required this.batch, required this.isSaving, required this.onSave});

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> {
  late final TextEditingController _nameCtrl;
  late String _startTime;
  late String _endTime;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.batch.name);
    _startTime = widget.batch.startTime;
    _endTime = widget.batch.endTime;
    _isActive = widget.batch.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 7,
        minute: int.tryParse(parts[1]) ?? 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = formatted;
      } else {
        _endTime = formatted;
      }
    });
  }

  bool _validate() {
    final startParts = _startTime.split(':');
    final endParts = _endTime.split(':');
    final startMin =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jam selesai harus setelah jam mulai.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Nama + switch aktif
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Batch',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(children: [
              const Text('Aktif',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Switch(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              activeThumbColor: AppTheme.successColor,
              ),
            ]),
          ]),
          const SizedBox(height: 12),

          // Jam
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Mulai',
                    isDense: true,
                    prefixIcon: Icon(Icons.access_time, size: 18),
                  ),
                  child: Text(_startTime),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Selesai',
                    isDense: true,
                    prefixIcon: Icon(Icons.access_time_filled, size: 18),
                  ),
                  child: Text(_endTime),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isSaving
                  ? null
                  : () async {
                      if (!_validate()) return;
                      final ok = await widget.onSave(
                        _nameCtrl.text.trim(),
                        _startTime,
                        _endTime,
                        _isActive,
                      );
                      if (!mounted) return;
                      if (ok) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Batch berhasil disimpan.'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
              child: widget.isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ),
        ]),
      ),
    );
  }
}
