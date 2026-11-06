import jwt from 'jsonwebtoken';
import prisma from '../lib/prisma.js';
import { env } from '../config/env.js';
import { sendError } from '../lib/response.js';

/**
 * Middleware auth: verifikasi JWT + cek is_active ke DB setiap request.
 * Blueprint: "token lama otomatis ditolak" jika akun dinonaktifkan.
 */
export async function auth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(res, { message: 'Token tidak ditemukan. Silakan login.', status: 401 });
  }

  const token = authHeader.split(' ')[1];

  let payload;
  try {
    payload = jwt.verify(token, env.JWT_SECRET);
  } catch {
    return sendError(res, { message: 'Token tidak valid atau sudah kadaluarsa.', status: 401 });
  }

  // Cek ke DB setiap request agar akun nonaktif langsung ditolak
  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
    select: { id: true, name: true, email: true, role: true, is_active: true },
  }).catch(() => null);

  if (!user) {
    return sendError(res, { message: 'Akun tidak ditemukan.', status: 401 });
  }

  if (!user.is_active) {
    return sendError(res, { message: 'Akun Anda dinonaktifkan. Hubungi admin.', status: 403 });
  }

  req.user = user;
  next();
}
