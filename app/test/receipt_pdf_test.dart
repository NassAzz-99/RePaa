import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/reservation/data/models/reservation_model.dart';
import 'package:app/features/reservation/presentation/widgets/receipt_widget.dart';

void main() {
  test('generateReceiptPdf creates valid non-empty PDF bytes', () async {
    const reservation = ReservationModel(
      id: 1,
      status: 'approved',
      reservationDate: '2026-11-16',
      workUnit: 'Divisi Rantai Pasok',
      purpose: 'Angkut barang',
      vehicle: ReservationVehicle(id: 1, name: 'Forklift 10 Ton - Unit 1', type: 'Forklift 10 Ton'),
      batch: ReservationBatch(id: 1, name: 'Batch 1', startTime: '07:30', endTime: '09:30'),
      user: ReservationUser(id: 2, name: 'User Contoh', email: 'user@paa.local'),
      createdAt: '2026-11-12T09:26:06.721Z',
      adminNote: 'Catatan pengujian',
    );

    final bytes = await generateReceiptPdf(reservation);
    expect(bytes, isNotEmpty);
    // PDF magic bytes: %PDF
    expect(bytes[0], 0x25); // %
    expect(bytes[1], 0x50); // P
    expect(bytes[2], 0x44); // D
    expect(bytes[3], 0x46); // F
  });
}
