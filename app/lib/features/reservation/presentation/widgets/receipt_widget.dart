import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/models/reservation_model.dart';

/// Helper untuk menghasilkan dokumen PDF struk reservasi.
/// Ukuran standar A4 / A5 portrait, muat dalam 1 halaman.
Future<Uint8List> generateReceiptPdf(
  ReservationModel reservation, {
  PdfPageFormat format = PdfPageFormat.a4,
  bool showUserEmail = true,
}) async {
  final doc = pw.Document();

  pw.Font baseFont;
  pw.Font boldFont;
  pw.Font italicFont;

  try {
    baseFont = await PdfGoogleFonts.robotoRegular();
    boldFont = await PdfGoogleFonts.robotoBold();
    italicFont = await PdfGoogleFonts.robotoItalic();
  } catch (_) {
    baseFont = pw.Font.helvetica();
    boldFont = pw.Font.helveticaBold();
    italicFont = pw.Font.helveticaOblique();
  }

  final statusLabel = switch (reservation.status) {
    'approved'  => 'Disetujui',
    'completed' => 'Selesai',
    'pending'   => 'Menunggu',
    'rejected'  => 'Ditolak',
    _           => reservation.status,
  };

  final statusColor = switch (reservation.status) {
    'approved'  => PdfColors.green700,
    'completed' => PdfColors.blue700,
    'pending'   => PdfColors.amber700,
    'rejected'  => PdfColors.red700,
    _           => PdfColors.grey700,
  };

  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Struk Reservasi PAA',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColor.fromInt(0xFF1E3A8A),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Peralatan Angkat & Angkut',
                        style: pw.TextStyle(
                          font: baseFont,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: statusColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(16),
                      ),
                    ),
                    child: pw.Text(
                      statusLabel,
                      style: pw.TextStyle(
                        font: boldFont,
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(height: 24, thickness: 1, color: PdfColors.grey300),

              // Rows
              _buildPdfRow('No. Reservasi', '#${reservation.id}', baseFont, boldFont),
              _buildPdfRow('Pemohon', reservation.user.name, baseFont, boldFont),
              if (showUserEmail &&
                  reservation.user.email != null &&
                  reservation.user.email!.isNotEmpty)
                _buildPdfRow('Email', reservation.user.email!, baseFont, boldFont),
              _buildPdfRow('Unit Kerja', reservation.workUnit, baseFont, boldFont),
              _buildPdfRow('Kendaraan', reservation.vehicle.name, baseFont, boldFont),
              _buildPdfRow('Tanggal', reservation.reservationDate, baseFont, boldFont),
              _buildPdfRow(
                'Batch',
                '${reservation.batch.name} (${reservation.batch.startTime}–${reservation.batch.endTime})',
                baseFont,
                boldFont,
              ),
              _buildPdfRow('Jenis Kebutuhan', reservation.purpose, baseFont, boldFont),

              if (reservation.adminNote != null &&
                  reservation.adminNote!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                    border: pw.Border.all(color: PdfColors.amber200, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Catatan Admin',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: PdfColors.amber900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        reservation.adminNote!,
                        style: pw.TextStyle(font: baseFont, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Divider(height: 24, thickness: 1, color: PdfColors.grey300),

              // Keterangan resmi
              pw.Center(
                child: pw.Text(
                  'Struk ini adalah bukti sah reservasi kendaraan PAA.\n'
                  'Tunjukkan struk ini kepada petugas terkait saat pengambilan unit.',
                  style: pw.TextStyle(
                    font: italicFont,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _buildPdfRow(
  String label,
  String value,
  pw.Font baseFont,
  pw.Font boldFont,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: baseFont,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Text(
          ': ',
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 11,
            color: PdfColors.grey700,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Widget Struk Reservasi – reusable, dipakai di halaman user dan admin.
/// Dilengkapi tombol Cetak dan Simpan PDF.
class ReceiptWidget extends StatefulWidget {
  final ReservationModel reservation;
  final bool showUserEmail;

  const ReceiptWidget({
    super.key,
    required this.reservation,
    this.showUserEmail = false,
  });

  /// Helper untuk membuka modal struk yang konsisten pada desktop maupun mobile.
  static Future<void> show(
    BuildContext context,
    ReservationModel reservation, {
    bool showUserEmail = false,
  }) {
    if (!reservation.isApproved && !reservation.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Struk hanya tersedia untuk reservasi yang Disetujui atau Selesai.',
          ),
        ),
      );
      return Future.value();
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  ReceiptWidget(
                    reservation: reservation,
                    showUserEmail: showUserEmail,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<ReceiptWidget> createState() => _ReceiptWidgetState();
}

class _ReceiptWidgetState extends State<ReceiptWidget> {
  bool _isPrinting = false;
  bool _isSaving = false;

  Future<void> _printReceipt() async {
    if (_isPrinting || _isSaving) return;
    setState(() => _isPrinting = true);
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => generateReceiptPdf(
          widget.reservation,
          format: format,
          showUserEmail: widget.showUserEmail || widget.reservation.user.email != null,
        ),
        name: 'struk-${widget.reservation.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak struk: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _savePdf() async {
    if (_isPrinting || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final bytes = await generateReceiptPdf(
        widget.reservation,
        format: PdfPageFormat.a4,
        showUserEmail: widget.showUserEmail || widget.reservation.user.email != null,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'struk-${widget.reservation.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan PDF: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_rounded,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Struk Reservasi PAA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Peralatan Angkat & Angkut',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: r.status),
              ],
            ),

            const Divider(height: 24),

            // ── Detail ────────────────────────────────────
            _Row('No. Reservasi', '#${r.id}'),
            _Row('Pemohon', r.user.name),
            if ((widget.showUserEmail || r.user.email != null) &&
                r.user.email != null &&
                r.user.email!.isNotEmpty)
              _Row('Email', r.user.email!),
            _Row('Unit Kerja', r.workUnit),
            _Row('Kendaraan', r.vehicle.name),
            _Row('Tanggal', r.reservationDate),
            _Row(
              'Batch',
              '${r.batch.name} (${r.batch.startTime}–${r.batch.endTime})',
            ),
            _Row('Jenis Kebutuhan', r.purpose),

            if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.adminNote!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // ── Keterangan resmi ─────────────────────────
            const Center(
              child: Text(
                'Struk ini adalah bukti sah reservasi kendaraan PAA.\n'
                'Tunjukkan struk ini kepada petugas terkait saat pengambilan unit.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Cetak dan Simpan PDF ───────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isPrinting || _isSaving) ? null : _printReceipt,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isPrinting || _isSaving) ? null : _savePdf,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Simpan PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = {
      'pending': (label: 'Menunggu', color: AppTheme.warningColor),
      'approved': (label: 'Disetujui', color: AppTheme.successColor),
      'rejected': (label: 'Ditolak', color: AppTheme.dangerColor),
      'cancelled': (label: 'Dibatalkan', color: Colors.grey),
      'completed': (label: 'Selesai', color: AppTheme.primaryColor),
    };
    final c = config[status] ?? (label: status, color: Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        c.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
