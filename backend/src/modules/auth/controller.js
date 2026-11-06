import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../../lib/prisma.js';
import { env } from '../../config/env.js';
import { sendSuccess, sendError } from '../../lib/response.js';

/** POST /api/auth/register */
export async function register(req, res, next) {
  try {
    const { name, email, password } = req.validated;

    // Cek email sudah dipakai
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return sendError(res, {
        message: 'Data tidak valid.',
        errors: { email: ['Email sudah terdaftar.'] },
        status: 422,
      });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data: { name, email, password: hashedPassword, role: 'user' },
      select: { id: true, name: true, email: true, role: true, is_active: true, created_at: true },
    });

    return sendSuccess(res, {
      message: 'Registrasi berhasil.',
      data: user,
      status: 201,
    });
  } catch (err) {
    next(err);
  }
}

/** POST /api/auth/login */
export async function login(req, res, next) {
  try {
    const { email, password } = req.validated;

    const user = await prisma.user.findUnique({ where: { email } });

    // Gunakan waktu yang sama untuk mencegah timing attack
    const passwordMatch = user ? await bcrypt.compare(password, user.password) : false;

    if (!user || !passwordMatch) {
      return sendError(res, { message: 'Email atau password salah.', status: 422 });
    }

    if (!user.is_active) {
      return sendError(res, {
        message: 'Akun Anda dinonaktifkan. Hubungi admin.',
        status: 403,
      });
    }

    const token = jwt.sign(
      { sub: user.id, role: user.role },
      env.JWT_SECRET,
      { expiresIn: env.JWT_EXPIRES_IN }
    );

    return sendSuccess(res, {
      message: 'Login berhasil.',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          is_active: user.is_active,
        },
      },
    });
  } catch (err) {
    next(err);
  }
}

/** POST /api/auth/logout */
export async function logout(_req, res) {
  // Stateless JWT: server hanya membalas sukses, klien yang hapus token.
  return sendSuccess(res, { message: 'Logout berhasil.' });
}

/** GET /api/auth/me */
export async function me(req, res) {
  return sendSuccess(res, {
    message: 'OK',
    data: {
      id: req.user.id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      is_active: req.user.is_active,
    },
  });
}
