import { z } from 'zod';

export const createReservationSchema = z.object({
  vehicle_id: z
    .number({ required_error: 'Kendaraan wajib dipilih.', invalid_type_error: 'vehicle_id harus berupa angka.' })
    .int('vehicle_id harus berupa angka bulat.')
    .positive('vehicle_id tidak valid.'),
  batch_id: z
    .number({ required_error: 'Batch wajib dipilih.', invalid_type_error: 'batch_id harus berupa angka.' })
    .int('batch_id harus berupa angka bulat.')
    .positive('batch_id tidak valid.'),
  reservation_date: z
    .string({ required_error: 'Tanggal reservasi wajib diisi.' })
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD.'),
  work_unit: z
    .string({ required_error: 'Unit kerja wajib diisi.' })
    .min(2, 'Unit kerja minimal 2 karakter.')
    .max(150, 'Unit kerja maksimal 150 karakter.'),
  purpose: z
    .string({ required_error: 'Jenis kebutuhan wajib diisi.' })
    .min(5, 'Jenis kebutuhan minimal 5 karakter.'),
});
