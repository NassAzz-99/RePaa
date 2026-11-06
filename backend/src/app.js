import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { env } from './config/env.js';

// Middleware
import { errorHandler } from './middleware/errorHandler.js';

// Routes
import authRoutes from './modules/auth/routes.js';
import profileRoutes from './modules/profile/routes.js';
import batchRoutes from './modules/batches/routes.js';
import workUnitRoutes from './modules/workUnits/routes.js';
import vehicleRoutes from './modules/vehicles/routes.js';
import reservationRoutes from './modules/reservations/routes.js';
import notificationRoutes from './modules/notifications/routes.js';

// Admin Routes
import adminDashboardRoutes from './modules/admin/dashboard/routes.js';
import adminReservationRoutes from './modules/admin/reservations/routes.js';
import adminVehicleRoutes from './modules/admin/vehicles/routes.js';
import adminUserRoutes from './modules/admin/users/routes.js';
import adminBatchRoutes from './modules/admin/batches/routes.js';
import adminReportRoutes from './modules/admin/reports/routes.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();

// CORS
app.use(cors());

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static files untuk foto kendaraan
// Akses via: GET /uploads/vehicles/filename.jpg
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/batches', batchRoutes);
app.use('/api/work-units', workUnitRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/reservations', reservationRoutes);
app.use('/api/notifications', notificationRoutes);

// Admin routes
app.use('/api/admin', adminDashboardRoutes);
app.use('/api/admin', adminReservationRoutes);
app.use('/api/admin', adminVehicleRoutes);
app.use('/api/admin', adminUserRoutes);
app.use('/api/admin', adminBatchRoutes);
app.use('/api/admin', adminReportRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan.' });
});

// Error handler terpusat (harus di paling akhir)
app.use(errorHandler);

export default app;
