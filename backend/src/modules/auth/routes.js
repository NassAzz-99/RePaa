import { Router } from 'express';
import { validate } from '../../middleware/validate.js';
import { auth } from '../../middleware/auth.js';
import { registerSchema, loginSchema } from './schema.js';
import { register, login, logout, me } from './controller.js';

const router = Router();

// POST /api/auth/register
router.post('/register', validate(registerSchema), register);

// POST /api/auth/login
router.post('/login', validate(loginSchema), login);

// POST /api/auth/logout  (perlu login)
router.post('/logout', auth, logout);

// GET /api/auth/me  (perlu login)
router.get('/me', auth, me);

export default router;
