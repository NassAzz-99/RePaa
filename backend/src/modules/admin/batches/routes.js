import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import prisma from '../../../lib/prisma.js';
import { sendSuccess, sendError } from '../../../lib/response.js';
import { z } from 'zod';

const router = Router();

const batchSchema = z.object({
  name: z.string().min(1, 'Nama batch wajib diisi.').max(50),
  start_time: z
    .string()
    .regex(/^\d{2}:\d{2}$/, 'Format waktu mulai harus HH:mm.'),
  end_time: z
    .string()
    .regex(/^\d{2}:\d{2}$/, 'Format waktu selesai harus HH:mm.'),
  is_active: z.boolean(),
}).refine((d) => d.end_time > d.start_time, {
  message: 'Waktu selesai harus lebih besar dari waktu mulai.',
  path: ['end_time'],
});

/** GET /api/admin/batches – semua batch termasuk nonaktif */
router.get('/batches', auth, admin, async (_req, res, next) => {
  try {
    const batches = await prisma.batch.findMany({ orderBy: { start_time: 'asc' } });
    return sendSuccess(res, { message: 'OK', data: batches });
  } catch (err) { next(err); }
});

/** PUT /api/admin/batches/:id */
router.put('/batches/:id', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const parsed = batchSchema.safeParse(req.body);
    if (!parsed.success) {
      const errors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path.join('.') || '_root';
        if (!errors[key]) errors[key] = [];
        errors[key].push(issue.message);
      }
      return sendError(res, { message: 'Data tidak valid.', errors, status: 422 });
    }
    const batch = await prisma.batch.update({ where: { id }, data: parsed.data });
    return sendSuccess(res, { message: 'Batch berhasil diperbarui.', data: batch });
  } catch (err) { next(err); }
});

export default router;
