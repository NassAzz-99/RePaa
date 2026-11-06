import bcrypt from 'bcryptjs';
import prisma from '../../lib/prisma.js';
import { sendSuccess, sendError } from '../../lib/response.js';

/** PUT /api/profile */
export async function updateProfile(req, res, next) {
  try {
    const { name, email } = req.validated;
    const userId = req.user.id;

    // Cek email tidak dipakai user lain
    if (email !== req.user.email) {
      const existing = await prisma.user.findFirst({
        where: { email, NOT: { id: userId } },
      });
      if (existing) {
        return sendError(res, {
          message: 'Data tidak valid.',
          errors: { email: ['Email sudah digunakan akun lain.'] },
          status: 422,
        });
      }
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { name, email },
      select: { id: true, name: true, email: true, role: true, is_active: true, updated_at: true },
    });

    return sendSuccess(res, { message: 'Profil berhasil diperbarui.', data: updated });
  } catch (err) {
    next(err);
  }
}

/** PUT /api/profile/password */
export async function changePassword(req, res, next) {
  try {
    const { current_password, password } = req.validated;
    const userId = req.user.id;

    const user = await prisma.user.findUnique({ where: { id: userId } });
    const match = await bcrypt.compare(current_password, user.password);
    if (!match) {
      return sendError(res, {
        message: 'Data tidak valid.',
        errors: { current_password: ['Password saat ini salah.'] },
        status: 422,
      });
    }

    const hashed = await bcrypt.hash(password, 12);
    await prisma.user.update({ where: { id: userId }, data: { password: hashed } });

    return sendSuccess(res, { message: 'Password berhasil diubah.' });
  } catch (err) {
    next(err);
  }
}
