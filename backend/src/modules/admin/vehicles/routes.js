import { Router } from 'express';
import { auth } from '../../../middleware/auth.js';
import { admin } from '../../../middleware/admin.js';
import { handleUpload } from '../../../middleware/upload.js';
import prisma from '../../../lib/prisma.js';
import { env } from '../../../config/env.js';
import { buildPhotoUrl } from '../../../lib/date.js';
import { sendSuccess, sendError } from '../../../lib/response.js';
import { z } from 'zod';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const router = Router();

function formatVehicle(v) {
  return {
    id: v.id,
    name: v.name,
    type: v.type,
    status: v.status,
    photo_url: buildPhotoUrl(v.photo_path, env.PUBLIC_URL),
    created_at: v.created_at,
    updated_at: v.updated_at,
  };
}

const vehicleSchema = z.object({
  name: z.string().min(2, 'Nama minimal 2 karakter.').max(100),
  type: z.string().min(2, 'Tipe minimal 2 karakter.').max(100),
  status: z.enum(['available', 'maintenance', 'inactive'], {
    errorMap: () => ({ message: 'Status tidak valid.' }),
  }),
});

/** GET /api/admin/vehicles */
router.get('/vehicles', auth, admin, async (_req, res, next) => {
  try {
    const vehicles = await prisma.vehicle.findMany({
      where: { deleted_at: null },
      orderBy: { created_at: 'desc' },
    });
    return sendSuccess(res, { message: 'OK', data: vehicles.map(formatVehicle) });
  } catch (err) { next(err); }
});

/** POST /api/admin/vehicles */
router.post('/vehicles', auth, admin, handleUpload, async (req, res, next) => {
  try {
    const parsed = vehicleSchema.safeParse(req.body);
    if (!parsed.success) {
      if (req.file) fs.unlinkSync(req.file.path);
      const errors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path.join('.') || '_root';
        if (!errors[key]) errors[key] = [];
        errors[key].push(issue.message);
      }
      return sendError(res, { message: 'Data tidak valid.', errors, status: 422 });
    }

    const photo_path = req.file
      ? `uploads/vehicles/${req.file.filename}`
      : null;

    const vehicle = await prisma.vehicle.create({
      data: { ...parsed.data, photo_path },
    });
    return sendSuccess(res, { message: 'Kendaraan berhasil ditambahkan.', data: formatVehicle(vehicle), status: 201 });
  } catch (err) { next(err); }
});

/** GET /api/admin/vehicles/:id */
router.get('/vehicles/:id', auth, admin, async (req, res, next) => {
  try {
    const vehicle = await prisma.vehicle.findFirst({
      where: { id: parseInt(req.params.id), deleted_at: null },
    });
    if (!vehicle) return sendError(res, { message: 'Kendaraan tidak ditemukan.', status: 404 });
    return sendSuccess(res, { message: 'OK', data: formatVehicle(vehicle) });
  } catch (err) { next(err); }
});

/** PUT /api/admin/vehicles/:id */
router.put('/vehicles/:id', auth, admin, handleUpload, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const existing = await prisma.vehicle.findFirst({ where: { id, deleted_at: null } });
    if (!existing) {
      if (req.file) fs.unlinkSync(req.file.path);
      return sendError(res, { message: 'Kendaraan tidak ditemukan.', status: 404 });
    }

    const parsed = vehicleSchema.safeParse(req.body);
    if (!parsed.success) {
      if (req.file) fs.unlinkSync(req.file.path);
      const errors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path.join('.') || '_root';
        if (!errors[key]) errors[key] = [];
        errors[key].push(issue.message);
      }
      return sendError(res, { message: 'Data tidak valid.', errors, status: 422 });
    }

    let photo_path = existing.photo_path;
    if (req.file) {
      // Hapus foto lama jika ada
      if (existing.photo_path) {
        const oldPath = path.join(__dirname, '../../../../', existing.photo_path);
        if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      }
      photo_path = `uploads/vehicles/${req.file.filename}`;
    }

    const updated = await prisma.vehicle.update({
      where: { id },
      data: { ...parsed.data, photo_path },
    });
    return sendSuccess(res, { message: 'Kendaraan berhasil diperbarui.', data: formatVehicle(updated) });
  } catch (err) { next(err); }
});

/** DELETE /api/admin/vehicles/:id – soft delete */
router.delete('/vehicles/:id', auth, admin, async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const vehicle = await prisma.vehicle.findFirst({ where: { id, deleted_at: null } });
    if (!vehicle) return sendError(res, { message: 'Kendaraan tidak ditemukan.', status: 404 });

    await prisma.vehicle.update({ where: { id }, data: { deleted_at: new Date() } });
    return sendSuccess(res, { message: 'Kendaraan berhasil dihapus.' });
  } catch (err) { next(err); }
});

export default router;
