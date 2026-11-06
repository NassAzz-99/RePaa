import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { updateProfileSchema, changePasswordSchema } from './schema.js';
import { updateProfile, changePassword } from './controller.js';

const router = Router();

// Semua route profil butuh login
router.use(auth);

// PUT /api/profile
router.put('/', validate(updateProfileSchema), updateProfile);

// PUT /api/profile/password
router.put('/password', validate(changePasswordSchema), changePassword);

export default router;
