import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z
    .string({ required_error: 'Nama wajib diisi.' })
    .min(2, 'Nama minimal 2 karakter.')
    .max(100, 'Nama maksimal 100 karakter.'),
  email: z
    .string({ required_error: 'Email wajib diisi.' })
    .email('Format email tidak valid.'),
});

export const changePasswordSchema = z
  .object({
    current_password: z.string({ required_error: 'Password saat ini wajib diisi.' }).min(1),
    password: z
      .string({ required_error: 'Password baru wajib diisi.' })
      .min(8, 'Password baru minimal 8 karakter.'),
    password_confirmation: z.string({ required_error: 'Konfirmasi password wajib diisi.' }),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: 'Konfirmasi password tidak cocok.',
    path: ['password_confirmation'],
  });
