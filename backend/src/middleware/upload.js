import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Pastikan folder uploads/vehicles ada
const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'vehicles');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination(_req, _file, cb) {
    cb(null, UPLOAD_DIR);
  },
  filename(_req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase();
    const unique = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    cb(null, `${unique}${ext}`);
  },
});

function fileFilter(_req, file, cb) {
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format file tidak didukung. Hanya jpg, png, webp yang diizinkan.'));
  }
}

// Maks 3 MB sesuai blueprint
export const uploadVehiclePhoto = multer({
  storage,
  fileFilter,
  limits: { fileSize: 3 * 1024 * 1024 },
}).single('photo');

/**
 * Wrapper agar multer error bisa diteruskan ke error handler Express.
 */
export function handleUpload(req, res, next) {
  uploadVehiclePhoto(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(422).json({
          success: false,
          message: 'Ukuran file terlalu besar. Maksimal 3 MB.',
        });
      }
      return res.status(422).json({ success: false, message: err.message });
    }
    if (err) {
      return res.status(422).json({ success: false, message: err.message });
    }
    next();
  });
}
