import { sendError } from '../lib/response.js';

/**
 * Middleware admin: harus dipasang setelah middleware auth.
 * Memastikan user yang login punya role 'admin'.
 */
export function admin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return sendError(res, { message: 'Akses ditolak. Hanya admin yang diizinkan.', status: 403 });
  }
  next();
}
