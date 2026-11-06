import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import prisma from '../../../lib/prisma.js';
import { sendSuccess, sendError, buildMeta } from '../../../lib/response.js';
import { formatReservation, createNotification } from '../../reservations/service.js';

const router = Router();

const INCLUDE_FULL = {
  user: { select: { id: true, name: true, email: true } },
  vehicle: { select: { id: true, name: true, type: true, photo_path: true } },
  batch: { select: { id: true, name: true, start_time: true, end_time: true } },
};

/** GET /api/admin/reservations?status=&date=&work_unit=&page= */
router.get('/reservations', auth, admin, async (req, res, next) => {
  try {
    const { status, date, work_unit, page: pageParam } = req.query;
    const page = Math.max(1, parseInt(pageParam) || 1);
    const perPage = 15;
    const skip = (page - 1) * perPage;

    const where = {};
    if (status) where.status = status;
    if (date) where.reservation_date = new Date(date);
    if (work_unit) where.work_unit = { contains: work_unit.toString(), mode: 'insensitive' };

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
      data: reservations.map((r) => formatReservation(r, { includeUserEmail: true })),
      meta: buildMeta(total, page, perPage),
    });
  } catch (err) {
    next(err);
  }
});

/** Helper: ambil reservasi + validasi */
async function findReservation(id) {
  return prisma.reservation.findUnique({ where: { id }, include: INCLUDE_FULL });
}

/** POST /api/admin/reservations/:id/approve */
router.post('/reservations/:id/approve', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const r = await findReservation(id);
    if (!r) return sendError(res, { message: 'Reservasi tidak ditemukan.', status: 404 });
    if (r.status !== 'pending') {
      return sendError(res, { message: 'Hanya reservasi berstatus "menunggu" yang dapat disetujui.', status: 422 });
    }
    const updated = await prisma.reservation.update({
      where: { id },
      data: { status: 'approved', processed_by: req.user.id, processed_at: new Date() },
      include: INCLUDE_FULL,
    });
    await createNotification('reservation_approved', updated, [updated.user_id]);
    return sendSuccess(res, { message: 'Reservasi berhasil disetujui.', data: formatReservation(updated, { includeUserEmail: true }) });
  } catch (err) { next(err); }
});

/** POST /api/admin/reservations/:id/reject */
router.post('/reservations/:id/reject', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const r = await findReservation(id);
    if (!r) return sendError(res, { message: 'Reservasi tidak ditemukan.', status: 404 });
    if (r.status !== 'pending') {
      return sendError(res, { message: 'Hanya reservasi berstatus "menunggu" yang dapat ditolak.', status: 422 });
    }
    const admin_note = req.body.admin_note ?? null;
    const updated = await prisma.reservation.update({
      where: { id },
      data: { status: 'rejected', admin_note, processed_by: req.user.id, processed_at: new Date() },
      include: INCLUDE_FULL,
    });
    await createNotification('reservation_rejected', updated, [updated.user_id]);
    return sendSuccess(res, { message: 'Reservasi berhasil ditolak.', data: formatReservation(updated, { includeUserEmail: true }) });
  } catch (err) { next(err); }
});

/** POST /api/admin/reservations/:id/complete */
router.post('/reservations/:id/complete', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const r = await findReservation(id);
    if (!r) return sendError(res, { message: 'Reservasi tidak ditemukan.', status: 404 });
    if (r.status !== 'approved') {
      return sendError(res, { message: 'Hanya reservasi berstatus "disetujui" yang dapat diselesaikan.', status: 422 });
    }
    const updated = await prisma.reservation.update({
      where: { id },
      data: { status: 'completed', processed_by: req.user.id, processed_at: new Date() },
      include: INCLUDE_FULL,
    });
    await createNotification('reservation_completed', updated, [updated.user_id]);
    return sendSuccess(res, { message: 'Reservasi berhasil diselesaikan.', data: formatReservation(updated, { includeUserEmail: true }) });
  } catch (err) { next(err); }
});

export default router;
