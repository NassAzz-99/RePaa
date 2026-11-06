import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import prisma from '../../lib/prisma.js';
import { sendSuccess } from '../../lib/response.js';

const router = Router();

/** GET /api/batches – batch aktif saja (untuk form reservasi user) */
router.get('/', auth, async (_req, res, next) => {
  try {
    const batches = await prisma.batch.findMany({
      where: { is_active: true },
      orderBy: { start_time: 'asc' },
      select: { id: true, name: true, start_time: true, end_time: true, is_active: true },
    });
    return sendSuccess(res, { message: 'OK', data: batches });
  } catch (err) {
    next(err);
  }
});

export default router;
