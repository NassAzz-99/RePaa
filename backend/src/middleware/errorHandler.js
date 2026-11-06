import { Prisma } from '@prisma/client';

/**
 * Error handler terpusat Express (4 argumen).
 * Menangani:
 * - Prisma P2002 (unique constraint) -> 409 (khusus untuk slot reservasi) atau 422
 * - Prisma P2025 (record not found) -> 404
 * - Error generik -> 500
 */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  console.error('[ErrorHandler]', err);

  // Prisma unique constraint violation
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      // Cek apakah dari partial index reservasi (target fields mengandung slot fields)
      const target = err.meta?.target;
      const isSlotConflict =
        Array.isArray(target) &&
        ['vehicle_id', 'reservation_date', 'batch_id'].every((f) => target.includes(f));

      if (isSlotConflict) {
        return res.status(409).json({
          success: false,
          message: 'Slot sudah dipesan. Pilih batch atau kendaraan lain.',
        });
      }

      return res.status(422).json({
        success: false,
        message: 'Data sudah ada. Periksa kembali input Anda.',
      });
    }

    if (err.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Data tidak ditemukan.' });
    }
  }

  // Error generik
  const status = err.status || err.statusCode || 500;
  const message = status < 500 ? err.message : 'Terjadi kesalahan server.';
  return res.status(status).json({ success: false, message });
}
