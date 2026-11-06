import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import prisma from '../../../lib/prisma.js';
import { sendSuccess, sendError } from '../../../lib/response.js';

const router = Router();

/** GET /api/admin/users – daftar user + reservations_count */
router.get('/users', auth, admin, async (_req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { created_at: 'desc' },
      select: {
        id: true, name: true, email: true, role: true, is_active: true, created_at: true,
        _count: { select: { reservations: true } },
      },
    });
    return sendSuccess(res, {
      message: 'OK',
      data: users.map((u) => ({
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role,
        is_active: u.is_active,
        created_at: u.created_at,
        reservations_count: u._count.reservations,
      })),
    });
  } catch (err) { next(err); }
});

/** PATCH /api/admin/users/:id/role */
router.patch('/users/:id/role', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    if (id === req.user.id) {
      return sendError(res, { message: 'Admin tidak dapat mengubah role dirinya sendiri.', status: 403 });
    }
    const { role } = req.body;
    if (!['admin', 'user'].includes(role)) {
      return sendError(res, { message: 'Role tidak valid. Gunakan "admin" atau "user".', status: 422 });
    }
    const user = await prisma.user.update({
      where: { id },
      data: { role },
      select: { id: true, name: true, email: true, role: true, is_active: true },
    });
    return sendSuccess(res, { message: 'Role berhasil diperbarui.', data: user });
  } catch (err) { next(err); }
});

/** PATCH /api/admin/users/:id/active */
router.patch('/users/:id/active', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    if (id === req.user.id) {
      return sendError(res, { message: 'Admin tidak dapat menonaktifkan dirinya sendiri.', status: 403 });
    }
    const is_active = req.body.is_active;
    if (typeof is_active !== 'boolean') {
      return sendError(res, { message: 'is_active harus berupa boolean (true/false).', status: 422 });
    }
    const user = await prisma.user.update({
      where: { id },
      data: { is_active },
      select: { id: true, name: true, email: true, role: true, is_active: true },
    });
    return sendSuccess(res, { message: `Akun berhasil ${is_active ? 'diaktifkan' : 'dinonaktifkan'}.`, data: user });
  } catch (err) { next(err); }
});

export default router;
