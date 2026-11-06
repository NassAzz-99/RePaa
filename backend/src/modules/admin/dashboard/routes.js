import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import prisma from '../../../lib/prisma.js';
import { sendSuccess } from '../../../lib/response.js';

const router = Router();

/** GET /api/admin/dashboard */
router.get('/dashboard', auth, admin, async (_req, res, next) => {
  try {
    const [pending, approved, vehiclesAvailable, totalUsers, statusDistribution, pendingReservations] =
      await Promise.all([
        prisma.reservation.count({ where: { status: 'pending' } }),
        prisma.reservation.count({ where: { status: 'approved' } }),
        prisma.vehicle.count({ where: { deleted_at: null, status: 'available' } }),
        prisma.user.count(),
        prisma.reservation.groupBy({ by: ['status'], _count: { status: true } }),
        prisma.reservation.findMany({
          where: { status: 'pending' },
          take: 10,
          orderBy: { created_at: 'asc' },
          select: {
            id: true,
            work_unit: true,
            reservation_date: true,
            user: { select: { name: true } },
            vehicle: { select: { name: true } },
            batch: { select: { name: true } },
          },
        }),
      ]);

    // Format distribusi status
    const allStatuses = ['pending', 'approved', 'rejected', 'cancelled', 'completed'];
    const dist = Object.fromEntries(allStatuses.map((s) => [s, 0]));
    for (const g of statusDistribution) {
      dist[g.status] = g._count.status;
    }

    return sendSuccess(res, {
      message: 'OK',
      data: {
        summary: { pending, approved, vehicles_available: vehiclesAvailable, total_users: totalUsers },
        status_distribution: dist,
        pending_reservations: pendingReservations.map((r) => ({
          id: r.id,
          work_unit: r.work_unit,
          reservation_date: r.reservation_date instanceof Date
            ? r.reservation_date.toISOString().split('T')[0]
            : r.reservation_date,
          user: r.user,
          vehicle: r.vehicle,
          batch: r.batch,
        })),
        recent_activity: [], // [Rencana] – akan diisi di tahap berikutnya
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
