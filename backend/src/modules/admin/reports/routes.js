import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import prisma from '../../../lib/prisma.js';
import { sendSuccess } from '../../../lib/response.js';
import { todayJakarta } from '../../../lib/date.js';

const router = Router();

/**
 * GET /api/admin/reports?period=daily|weekly&date=YYYY-MM-DD
 * [Rencana] – implementasi dasar sesuai blueprint response example.
 */
router.get('/reports', auth, admin, async (req, res, next) => {
  try {
    const period = req.query.period === 'weekly' ? 'weekly' : 'daily';
    const baseDate = req.query.date?.toString() ?? todayJakarta();

    let from, to;
    if (period === 'weekly') {
      // Minggu yang mengandung baseDate (Senin - Minggu)
      const d = new Date(baseDate);
      const day = d.getDay(); // 0=Sun
      const diffToMonday = (day === 0 ? -6 : 1 - day);
      const monday = new Date(d);
      monday.setDate(d.getDate() + diffToMonday);
      const sunday = new Date(monday);
      sunday.setDate(monday.getDate() + 6);
      from = monday.toISOString().split('T')[0];
      to = sunday.toISOString().split('T')[0];
    } else {
      from = baseDate;
      to = baseDate;
    }

    const where = {
      reservation_date: {
        gte: new Date(from),
        lte: new Date(to),
      },
    };

    const [statusGroups, vehicleGroups, workUnitGroups, vehicleStatusCounts] = await Promise.all([
      prisma.reservation.groupBy({ by: ['status'], where, _count: { status: true } }),
      prisma.reservation.groupBy({
        by: ['vehicle_id'],
        where,
        _count: { vehicle_id: true },
        orderBy: { _count: { vehicle_id: 'desc' } },
        take: 10,
      }),
      prisma.reservation.groupBy({
        by: ['work_unit'],
        where,
        _count: { work_unit: true },
        orderBy: { _count: { work_unit: 'desc' } },
        take: 10,
      }),
      prisma.vehicle.groupBy({
        by: ['status'],
        where: { deleted_at: null },
        _count: { status: true },
      }),
    ]);

    // Vehicle names untuk groupBy vehicle_id
    const vehicleIds = vehicleGroups.map((v) => v.vehicle_id);
    const vehicles = vehicleIds.length
      ? await prisma.vehicle.findMany({ where: { id: { in: vehicleIds } }, select: { id: true, name: true } })
      : [];
    const vehicleMap = Object.fromEntries(vehicles.map((v) => [v.id, v.name]));

    const allStatuses = ['pending', 'approved', 'rejected', 'cancelled', 'completed'];
    const statusSummary = Object.fromEntries(allStatuses.map((s) => [s, 0]));
    for (const g of statusGroups) statusSummary[g.status] = g._count.status;

    const vStatusMap = { available: 0, maintenance: 0, inactive: 0 };
    for (const g of vehicleStatusCounts) vStatusMap[g.status] = g._count.status;

    return sendSuccess(res, {
      message: 'OK',
      data: {
        period,
        range: { from, to },
        status_summary: statusSummary,
        trend: [], // [Rencana] – per-hari/batch breakdown
        vehicle_utilization: vehicleGroups.map((g) => ({
          vehicle: vehicleMap[g.vehicle_id] ?? `ID ${g.vehicle_id}`,
          reservations: g._count.vehicle_id,
        })),
        by_work_unit: workUnitGroups.map((g) => ({
          work_unit: g.work_unit,
          total: g._count.work_unit,
        })),
        vehicle_status: vStatusMap,
      },
    });
  } catch (err) { next(err); }
});

export default router;
