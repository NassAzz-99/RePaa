import prisma from '../../lib/prisma.js';
import { env } from '../../config/env.js';
import { buildPhotoUrl } from '../../lib/date.js';

/**
 * Format objek reservasi sesuai blueprint response.
 * Dipakai oleh GET /reservations, GET /reservations/:id, dan admin.
 */
export function formatReservation(r, { includeUserEmail = false } = {}) {
  return {
    id: r.id,
    status: r.status,
    reservation_date: r.reservation_date instanceof Date
      ? r.reservation_date.toISOString().split('T')[0]
      : r.reservation_date,
    work_unit: r.work_unit,
    purpose: r.purpose,
    admin_note: r.admin_note,
    vehicle: {
      id: r.vehicle.id,
      name: r.vehicle.name,
      type: r.vehicle.type,
      photo_url: buildPhotoUrl(r.vehicle.photo_path, env.PUBLIC_URL),
    },
    batch: {
      id: r.batch.id,
      name: r.batch.name,
      start_time: r.batch.start_time,
      end_time: r.batch.end_time,
    },
    user: {
      id: r.user.id,
      name: r.user.name,
      ...(includeUserEmail ? { email: r.user.email } : {}),
    },
    created_at: r.created_at,
    processed_by: r.processed_by,
    processed_at: r.processed_at,
  };
}

/**
 * Buat notifikasi otomatis sesuai blueprint.
 * @param {'reservation_created'|'reservation_approved'|'reservation_rejected'|'reservation_completed'} type
 * @param {object} reservation - objek reservasi dengan relasi user, vehicle, batch
 * @param {number[]} recipientIds - array user ID penerima notifikasi
 */
export async function createNotification(type, reservation, recipientIds) {
  const templates = {
    reservation_created: {
      title: 'Reservasi Baru Masuk',
      message: `${reservation.user.name} mengajukan reservasi ${reservation.vehicle.name} pada ${
        reservation.reservation_date instanceof Date
          ? reservation.reservation_date.toISOString().split('T')[0]
          : reservation.reservation_date
      } (${reservation.batch.name}).`,
    },
    reservation_approved: {
      title: 'Reservasi Disetujui',
      message: `Reservasi Anda untuk ${reservation.vehicle.name} pada ${
        reservation.reservation_date instanceof Date
          ? reservation.reservation_date.toISOString().split('T')[0]
          : reservation.reservation_date
      } (${reservation.batch.name}) telah disetujui.`,
    },
    reservation_rejected: {
      title: 'Reservasi Ditolak',
      message: `Reservasi Anda untuk ${reservation.vehicle.name} pada ${
        reservation.reservation_date instanceof Date
          ? reservation.reservation_date.toISOString().split('T')[0]
          : reservation.reservation_date
      } (${reservation.batch.name}) ditolak.${reservation.admin_note ? ` Catatan: ${reservation.admin_note}` : ''}`,
    },
    reservation_completed: {
      title: 'Reservasi Selesai',
      message: `Reservasi Anda untuk ${reservation.vehicle.name} pada ${
        reservation.reservation_date instanceof Date
          ? reservation.reservation_date.toISOString().split('T')[0]
          : reservation.reservation_date
      } (${reservation.batch.name}) telah selesai.`,
    },
  };

  const tmpl = templates[type];
  if (!tmpl) return;

  await prisma.notification.createMany({
    data: recipientIds.map((userId) => ({
      user_id: userId,
      type,
      title: tmpl.title,
      message: tmpl.message,
      reservation_id: reservation.id,
    })),
  });
}
