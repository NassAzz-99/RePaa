/**
 * Helper tanggal dengan timezone Asia/Jakarta.
 * Blueprint: "tanggal hari ini" harus dihitung dari zona Asia/Jakarta, bukan UTC server.
 */

const TZ = 'Asia/Jakarta';

/**
 * Kembalikan string tanggal hari ini dalam format YYYY-MM-DD (Asia/Jakarta).
 * @returns {string}
 */
export function todayJakarta() {
  return new Date()
    .toLocaleDateString('en-CA', { timeZone: TZ }); // en-CA menghasilkan YYYY-MM-DD
}

/**
 * Periksa apakah string tanggal (YYYY-MM-DD) berada di masa lalu dibanding hari ini Jakarta.
 * @param {string} dateStr - format YYYY-MM-DD
 * @returns {boolean}
 */
export function isPastDate(dateStr) {
  return dateStr < todayJakarta();
}

/**
 * Bentuk photo_url lengkap dari path relatif dan PUBLIC_URL.
 * @param {string|null} photoPath
 * @param {string} publicUrl
 * @returns {string|null}
 */
export function buildPhotoUrl(photoPath, publicUrl) {
  if (!photoPath) return null;
  return `${publicUrl}/${photoPath.replace(/^\//, '')}`;
}
