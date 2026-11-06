/**
 * Helper untuk format response seragam sesuai blueprint.
 * Field JSON response: snake_case, format { success, message, data } / { success, message, data, meta }
 */

/**
 * @param {import('express').Response} res
 * @param {object} opts
 * @param {boolean} [opts.success=true]
 * @param {string} [opts.message='OK']
 * @param {*} [opts.data]
 * @param {object} [opts.meta]  - untuk paginasi
 * @param {number} [opts.status=200]
 */
export function sendSuccess(res, { message = 'OK', data = null, meta = null, status = 200 } = {}) {
  const body = { success: true, message, data };
  if (meta) body.meta = meta;
  return res.status(status).json(body);
}

/**
 * @param {import('express').Response} res
 * @param {object} opts
 * @param {string} [opts.message='Terjadi kesalahan.']
 * @param {object} [opts.errors]  - untuk error validasi (422)
 * @param {number} [opts.status=500]
 */
export function sendError(res, { message = 'Terjadi kesalahan.', errors = null, status = 500 } = {}) {
  const body = { success: false, message };
  if (errors) body.errors = errors;
  return res.status(status).json(body);
}

/**
 * Hitung meta paginasi.
 * @param {number} total - total record
 * @param {number} page  - halaman saat ini (1-based)
 * @param {number} perPage - record per halaman
 */
export function buildMeta(total, page, perPage = 15) {
  return {
    current_page: page,
    last_page: Math.ceil(total / perPage) || 1,
    per_page: perPage,
    total,
  };
}
