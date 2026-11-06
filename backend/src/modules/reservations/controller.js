import prisma from '../../lib/prisma.js';
import { sendSuccess, sendError, buildMeta } from '../../lib/response.js';
import { isPastDate } from '../../lib/date.js';
import { formatReservation, createNotification } from './service.js';

const INCLUDE_FULL = {
  user: { select: { id: true, name: true, email: true } },
  vehicle: { select: { id: true, name: true, type: true, photo_path: true } },
  batch: { select: { id: true, name: true, start_time: true, end_time: true } },
};

/** GET /api/reservations */
export async function listReservations(req, res, next) {
  try {
    const userId = req.user.id;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const perPage = 15;
    const skip = (page - 1) * perPage;

    const where = { user_id: userId };

    const [total, reservations] = await Promise.all([
      prisma.reservation.count({ where }),
      prisma.reservation.findMany({
        where,
        include: INCLUDE_FULL,
        orderBy: { created_at: 'desc' },
        skip,
        take: perPage,
      }),
    ]);

    return sendSuccess(res, {
      message: 'OK',
      data: reservations.map((r) => formatReservation(r)),
      meta: buildMeta(total, page, perPage),
    });
  } catch (err) {
    next(err);
  }
}

/** POST /api/reservations */
export async function createReservation(req, res, next) {
  try {
    const { vehicle_id, batch_id, reservation_date, work_unit, purpose } = req.validated;
    const userId = req.user.id;

    // Validasi tanggal tidak di masa lalu
    if (isPastDate(reservation_date)) {
      return sendError(res, {
        message: 'Data tidak valid.',
        errors: { reservation_date: ['Tanggal reservasi tidak boleh di masa lalu.'] },
        status: 422,
      });
    }

    // Cek kendaraan tersedia dan tidak terhapus
    const vehicle = await prisma.vehicle.findFirst({
      where: { id: vehicle_id, deleted_at: null },
    });
    if (!vehicle) {
      return sendError(res, { message: 'Kendaraan tidak ditemukan.', status: 404 });
    }
    if (vehicle.status !== 'available') {
      return sendError(res, {
        message: 'Kendaraan tidak tersedia untuk direservasi.',
        status: 422,
      });
    }

    // Cek batch aktif
    const batch = await prisma.batch.findFirst({ where: { id: batch_id, is_active: true } });
    if (!batch) {
      return sendError(res, { message: 'Batch tidak tersedia.', status: 422 });
    }

    // Buat reservasi dalam transaksi (double booking dicegah oleh partial unique index)
    const reservation = await prisma.$transaction(async (tx) => {
      const created = await tx.reservation.create({
        data: {
          user_id: userId,
          vehicle_id,
          batch_id,
          reservation_date: new Date(reservation_date),
          work_unit,
          purpose,
          status: 'pending',
        },
        include: INCLUDE_FULL,
      });
      return created;
    });

    // Notifikasi ke semua admin (reservation_created)
    const admins = await prisma.user.findMany({
      where: { role: 'admin', is_active: true },
      select: { id: true },
    });
    await createNotification('reservation_created', reservation, admins.map((a) => a.id));

    return sendSuccess(res, {
      message: 'Reservasi berhasil diajukan.',
      data: formatReservation(reservation),
      status: 201,
    });
  } catch (err) {
    // Partial unique index violation (double booking)
    if (err?.code === 'P2002' || err?.code === '23505') {
      return sendError(res, {
        message: 'Slot sudah dipesan. Pilih batch atau kendaraan lain.',
        status: 409,
      });
    }
    next(err);
  }
}

/** GET /api/reservations/:id */
export async function getReservation(req, res, next) {
  try {
    const id = parseInt(req.params.id);
    const reservation = await prisma.reservation.findUnique({
      where: { id },
      include: INCLUDE_FULL,
    });

    if (!reservation) {
      return sendError(res, { message: 'Reservasi tidak ditemukan.', status: 404 });
    }

    // Hanya pemilik atau admin yang boleh melihat struk
    if (reservation.user_id !== req.user.id && req.user.role !== 'admin') {
      return sendError(res, { message: 'Akses ditolak.', status: 403 });
    }

    return sendSuccess(res, { message: 'OK', data: formatReservation(reservation, { includeUserEmail: req.user.role === 'admin' }) });
  } catch (err) {
    next(err);
  }
}

/** POST /api/reservations/:id/cancel */
export async function cancelReservation(req, res, next) {
  try {
    const id = parseInt(req.params.id);
    const userId = req.user.id;

    const reservation = await prisma.reservation.findUnique({
      where: { id },
      include: INCLUDE_FULL,
    });

    if (!reservation) {
      return sendError(res, { message: 'Reservasi tidak ditemukan.', status: 404 });
    }

    // Hanya pemilik yang bisa membatalkan
    if (reservation.user_id !== userId) {
      return sendError(res, { message: 'Akses ditolak.', status: 403 });
    }

    // Hanya dari status pending
    if (reservation.status !== 'pending') {
      return sendError(res, {
        message: 'Hanya reservasi dengan status "menunggu" yang dapat dibatalkan.',
        status: 422,
      });
    }

    const updated = await prisma.reservation.update({
      where: { id },
      data: { status: 'cancelled' },
      include: INCLUDE_FULL,
    });

    return sendSuccess(res, { message: 'Reservasi berhasil dibatalkan.', data: formatReservation(updated) });
  } catch (err) {
    next(err);
  }
}
