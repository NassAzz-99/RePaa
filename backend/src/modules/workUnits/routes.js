import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import prisma from '../../lib/prisma.js';
import { sendSuccess } from '../../lib/response.js';

const router = Router();

/** GET /api/work-units?q= – autocomplete unit kerja */
router.get('/', auth, async (req, res, next) => {
  try {
    const q = req.query.q?.toString().trim() ?? '';
    const workUnits = await prisma.workUnit.findMany({
      where: q ? { name: { contains: q, mode: 'insensitive' } } : {},
      orderBy: { name: 'asc' },
      take: 20,
      select: { id: true, name: true },
    });
    return sendSuccess(res, { message: 'OK', data: workUnits });
  } catch (err) {
    next(err);
  }
});

export default router;
