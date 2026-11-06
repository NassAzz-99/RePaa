import { Router } from 'express';
import { auth } from '../../middleware/auth.js';
import { validate } from '../../middleware/validate.js';
import { createReservationSchema } from './schema.js';
import {
  listReservations,
  createReservation,
  getReservation,
  cancelReservation,
} from './controller.js';

const router = Router();

router.use(auth);

// GET  /api/reservations
router.get('/', listReservations);

// POST /api/reservations
router.post('/', validate(createReservationSchema), createReservation);

// GET  /api/reservations/:id  (struk)
router.get('/:id', getReservation);

// POST /api/reservations/:id/cancel
router.post('/:id/cancel', cancelReservation);

export default router;
