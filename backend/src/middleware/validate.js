import { sendError } from '../lib/response.js';

/**
 * Middleware validasi berbasis Zod schema.
 * Mengambil nilai dari req.body, req.params, req.query sesuai kebutuhan.
 *
 * @param {import('zod').ZodSchema} schema - Zod schema untuk req.body
 * @param {'body'|'query'|'params'} [source='body']
 */
export function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      // Format errors: { field: ["pesan error 1", "pesan error 2"] }
      const errors = {};
      for (const issue of result.error.issues) {
        const key = issue.path.join('.') || '_root';
        if (!errors[key]) errors[key] = [];
        errors[key].push(issue.message);
      }
      return sendError(res, {
        message: 'Data tidak valid.',
        errors,
        status: 422,
      });
    }
    req.validated = result.data;
    next();
  };
}
