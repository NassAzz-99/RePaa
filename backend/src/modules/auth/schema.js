import { z } from 'zod';

export const registerSchema = z
  .object({
    name: z
      .string({ required_error: 'Nama wajib diisi.' })
      .min(2, 'Nama minimal 2 karakter.')
      .max(100, 'Nama maksimal 100 karakter.'),
    email: z
      .string({ required_error: 'Email wajib diisi.' })
      .email('Format email tidak valid.'),
    password: z
      .string({ required_error: 'Password wajib diisi.' })
      .min(8, 'Password minimal 8 karakter.'),
    password_confirmation: z.string({ required_error: 'Konfirmasi password wajib diisi.' }),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: 'Konfirmasi password tidak cocok.',
    path: ['password_confirmation'],
  });

export const loginSchema = z.object({
  email: z
    .string({ required_error: 'Email wajib diisi.' })
    .email('Format email tidak valid.'),
  password: z
    .string({ required_error: 'Password wajib diisi.' })
    .min(1, 'Password wajib diisi.'),
});
