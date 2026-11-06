import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import prisma from '../../lib/prisma.js';
import { sendSuccess, buildMeta } from '../../lib/response.js';

const router = Router();

router.use(auth);

/** GET /api/notifications?page=1 */
router.get('/', async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const perPage = 15;
    const skip = (page - 1) * perPage;
    const userId = req.user.id;

    const [total, notifications] = await Promise.all([
      prisma.notification.count({ where: { user_id: userId } }),
      prisma.notification.findMany({
        where: { user_id: userId },
        orderBy: { created_at: 'desc' },
        skip,
        take: perPage,
        select: {
          id: true, type: true, title: true, message: true,
          reservation_id: true, read_at: true, created_at: true,
        },
      }),
    ]);

    return sendSuccess(res, {
      message: 'OK',
      data: notifications,
      meta: buildMeta(total, page, perPage),
    });
  } catch (err) {
    next(err);
  }
});

/** GET /api/notifications/unread-count */
router.get('/unread-count', async (req, res, next) => {
  try {
    const unread = await prisma.notification.count({
      where: { user_id: req.user.id, read_at: null },
    });
    return sendSuccess(res, { message: 'OK', data: { unread } });
  } catch (err) {
    next(err);
  }
});

/** POST /api/notifications/:id/read */
router.post('/:id/read', async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const notification = await prisma.notification.findFirst({
      where: { id, user_id: req.user.id },
    });
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notifikasi tidak ditemukan.' });
    }
    if (!notification.read_at) {
      await prisma.notification.update({
        where: { id },
        data: { read_at: new Date() },
      });
    }
    return sendSuccess(res, { message: 'Notifikasi ditandai sudah dibaca.' });
  } catch (err) {
    next(err);
  }
});

/** POST /api/notifications/read-all */
router.post('/read-all', async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { user_id: req.user.id, read_at: null },
      data: { read_at: new Date() },
    });
    return sendSuccess(res, { message: 'Semua notifikasi ditandai sudah dibaca.' });
  } catch (err) {
    next(err);
  }
});

export default router;
