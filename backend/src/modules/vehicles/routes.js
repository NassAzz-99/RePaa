import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import prisma from '../../lib/prisma.js';
import { env } from '../../config/env.js';
import { sendSuccess, sendError } from '../../lib/response.js';
import { buildPhotoUrl, todayJakarta } from '../../lib/date.js';

const router = Router();

/**
 * GET /api/vehicles/availability?date=YYYY-MM-DD
 * Kartu dashboard: semua kendaraan available + status slot per batch aktif.
 * Blueprint response: { date, vehicles: [ { id, name, type, status, photo_url, slots: [] } ] }
 */
router.get('/availability', auth, async (req, res, next) => {
  try {
    const date = req.query.date?.toString() ?? todayJakarta();

    // Ambil semua kendaraan available (tidak soft-deleted, tidak maintenance/inactive)
    const vehicles = await prisma.vehicle.findMany({
      where: { deleted_at: null, status: 'available' },
      orderBy: { name: 'asc' },
    });

    // Ambil batch aktif
    const batches = await prisma.batch.findMany({
      where: { is_active: true },
      orderBy: { start_time: 'asc' },
    });

    // Ambil reservasi aktif (pending/approved) untuk tanggal tersebut
    const reservations = await prisma.reservation.findMany({
      where: {
        reservation_date: new Date(date),
        status: { in: ['pending', 'approved'] },
      },
      select: { vehicle_id: true, batch_id: true, status: true },
    });

    // Buat map: "vehicleId-batchId" -> status
    const slotMap = new Map();
    for (const r of reservations) {
      slotMap.set(`${r.vehicle_id}-${r.batch_id}`, r.status);
    }

    const data = vehicles.map((v) => ({
      id: v.id,
      name: v.name,
      type: v.type,
      status: v.status,
      photo_url: buildPhotoUrl(v.photo_path, env.PUBLIC_URL),
      slots: batches.map((b) => {
        const key = `${v.id}-${b.id}`;
        const reservationStatus = slotMap.get(key);
        let slotStatus = 'empty';
        if (reservationStatus === 'pending') slotStatus = 'pending';
        else if (reservationStatus === 'approved') slotStatus = 'booked';
        return {
          batch_id: b.id,
          batch_name: b.name,
          start_time: b.start_time,
          end_time: b.end_time,
          status: slotStatus,
        };
      }),
    }));

    return sendSuccess(res, { message: 'OK', data: { date, vehicles: data } });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/vehicles/available?date=YYYY-MM-DD&batch_id=N
 * Kendaraan available yang slotnya kosong, untuk dropdown form reservasi.
 */
router.get('/available', auth, async (req, res, next) => {
  try {
    const date = req.query.date?.toString() ?? todayJakarta();
    const batchId = parseInt(req.query.batch_id);

    if (!batchId || isNaN(batchId)) {
      return sendError(res, { message: 'Parameter batch_id wajib diisi.', status: 422 });
    }

    // Cari vehicle_id yang sudah ada reservasi aktif di slot ini
    const bookedVehicleIds = (
      await prisma.reservation.findMany({
        where: {
          reservation_date: new Date(date),
          batch_id: batchId,
          status: { in: ['pending', 'approved'] },
        },
        select: { vehicle_id: true },
      })
    ).map((r) => r.vehicle_id);

    const vehicles = await prisma.vehicle.findMany({
      where: {
        deleted_at: null,
        status: 'available',
        id: { notIn: bookedVehicleIds.length ? bookedVehicleIds : [0] },
      },
      orderBy: { name: 'asc' },
      select: { id: true, name: true, type: true, photo_path: true },
    });

    return sendSuccess(res, {
      message: 'OK',
      data: vehicles.map((v) => ({
        ...v,
        photo_url: buildPhotoUrl(v.photo_path, env.PUBLIC_URL),
        photo_path: undefined,
      })),
    });
  } catch (err) {
    next(err);
  }
});

export default router;
