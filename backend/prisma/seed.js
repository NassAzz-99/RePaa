/**
 * Prisma Seed – Reservasi PAA
 * Jalankan: npm run seed
 *
 * Isi:
 *  - 4 Batch (Batch 1-4 sesuai blueprint)
 *  - 8 Work Units sesuai blueprint
 *  - Akun admin: admin@paa.local (role admin)
 *  - Akun user: user@paa.local (role user)
 *  - 6 Kendaraan contoh: Forklift 10T, 2T, 7T, Lift Truck, Trailer 22T, Trailer 32T
 */

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

// Jalankan seed.js langsung (bukan via import), jadi perlu load dotenv manual
import { config } from 'dotenv';
config();

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Memulai seed...');

  // ── Batches ──────────────────────────────────────────────────────────────
  // Blueprint: Batch 1 (07:30-09:30, aktif), Batch 2 (09:30-11:30, aktif),
  //            Batch 3 (13:00-15:00, nonaktif), Batch 4 (15:00-17:00, nonaktif)
  const batches = await Promise.all([
    prisma.batch.upsert({
      where: { id: 1 },
      update: {},
      create: { name: 'Batch 1', start_time: '07:30', end_time: '09:30', is_active: true },
    }),
    prisma.batch.upsert({
      where: { id: 2 },
      update: {},
      create: { name: 'Batch 2', start_time: '09:30', end_time: '11:30', is_active: true },
    }),
    prisma.batch.upsert({
      where: { id: 3 },
      update: {},
      create: { name: 'Batch 3', start_time: '13:00', end_time: '15:00', is_active: false },
    }),
    prisma.batch.upsert({
      where: { id: 4 },
      update: {},
      create: { name: 'Batch 4', start_time: '15:00', end_time: '17:00', is_active: false },
    }),
  ]);
  console.log(`  ✓ ${batches.length} batch selesai`);

  // ── Work Units ────────────────────────────────────────────────────────────
  const workUnitNames = [
    'Divisi Permukaan',
    'Divisi Kapal Selam',
    'Divisi Pemeliharaan dan Perbaikan',
    'Divisi Rekayasa Umum',
    'Divisi Pemasaran dan Penjualan',
    'Divisi Rantai Pasok',
    'Divisi Manajemen Aset',
    'Infrastruktur & K3LH',
  ];
  const workUnits = await Promise.all(
    workUnitNames.map((name) =>
      prisma.workUnit.upsert({
        where: { name },
        update: {},
        create: { name },
      })
    )
  );
  console.log(`  ✓ ${workUnits.length} work unit selesai`);

  // ── Users ─────────────────────────────────────────────────────────────────
  const SALT_ROUNDS = 12;

  const adminPassword = await bcrypt.hash('Admin@12345', SALT_ROUNDS);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@paa.local' },
    update: {},
    create: {
      name: 'Administrator PAA',
      email: 'admin@paa.local',
      password: adminPassword,
      role: 'admin',
      is_active: true,
    },
  });
  console.log(`  ✓ Admin: ${admin.email}`);

  const userPassword = await bcrypt.hash('User@12345', SALT_ROUNDS);
  const user = await prisma.user.upsert({
    where: { email: 'user@paa.local' },
    update: {},
    create: {
      name: 'User Contoh',
      email: 'user@paa.local',
      password: userPassword,
      role: 'user',
      is_active: true,
    },
  });
  console.log(`  ✓ User: ${user.email}`);

  // ── Vehicles ──────────────────────────────────────────────────────────────
  // Blueprint seed: Forklift 10 Ton, 2 Ton, 7 Ton, Lift Truck, Trailer 22 Ton, Trailer 32 Ton
  const vehicleData = [
    { name: 'Forklift 10 Ton - Unit 1', type: 'Forklift 10 Ton', status: 'available' },
    { name: 'Forklift 2 Ton - Unit 1',  type: 'Forklift 2 Ton',  status: 'available' },
    { name: 'Forklift 7 Ton - Unit 1',  type: 'Forklift 7 Ton',  status: 'available' },
    { name: 'Lift Truck - Unit 1',       type: 'Lift Truck',       status: 'available' },
    { name: 'Trailer 22 Ton - Unit 1',   type: 'Trailer 22 Ton',   status: 'available' },
    { name: 'Trailer 32 Ton - Unit 1',   type: 'Trailer 32 Ton',   status: 'available' },
  ];

  for (const v of vehicleData) {
    // Prisma tidak mendukung upsert tanpa unique key pada name.
    // USULAN: Tambahkan @@unique([name]) pada model Vehicle jika diperlukan.
    // Saat ini pakai createIfNotExists pattern manual agar seed aman dijalankan berulang.
    const existing = await prisma.vehicle.findFirst({ where: { name: v.name, deleted_at: null } });
    if (!existing) {
      await prisma.vehicle.create({ data: v });
    }
  }

  const vehicleCount = await prisma.vehicle.count();
  console.log(`  ✓ ${vehicleCount} kendaraan selesai`);

  console.log('\n🎉 Seed selesai!');
  console.log('   Admin : admin@paa.local / Admin@12345');
  console.log('   User  : user@paa.local  / User@12345');
  console.log('   ⚠️  Ganti password default sebelum produksi!');
}

main()
  .catch((e) => {
    console.error('❌ Seed gagal:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
