/**
 * Profil fotoğrafı işleme — TAMAMEN istemci tarafı (canvas), sunucu görsel ucu YOK.
 * Seçilen görsel: merkez kare kırpma → 256×256 yeniden boyut → sıkıştırma ile küçük
 * bir data URL'e (webp, desteklenmezse jpeg) çevrilir. Sonuç `ea:avatar:v1` altında
 * `syncSet` ile localStorage'a yazılır + /api/state ile senkronlanır. 256px webp ~10-30KB,
 * kayıt başına 512KB sunucu sınırının çok altında.
 */

/** userState anahtarı — SYNC_KEYS + USER_SCOPED_KEYS + /api/state ALLOWED_KEYS içinde. */
export const AVATAR_KEY = 'ea:avatar:v1';
/** Çıktı kenar uzunluğu (kare). */
export const AVATAR_SIZE = 256;
/** İşlemeden ÖNCE reddedilen ham dosya üst sınırı (~8MB). */
const MAX_UPLOAD_BYTES = 8 * 1024 * 1024;
/** WebP kalitesi (0–1). 256px'de 0.8 keskin ama küçüktür. */
const QUALITY = 0.8;

/** Dosya bir görsel mi? (accept="image/*" istemci tarafında zorunlu değildir.) */
export function isImageFile(file: File): boolean {
  return typeof file.type === 'string' && file.type.startsWith('image/');
}

/** localStorage'daki mevcut avatar data URL'ini oku (yoksa boş dize). */
export function loadAvatar(): string {
  try {
    const raw = localStorage.getItem(AVATAR_KEY);
    if (!raw) return '';
    const val: unknown = JSON.parse(raw);
    return typeof val === 'string' ? val : '';
  } catch {
    return '';
  }
}

/**
 * Seçilen dosyayı doğrula, yükle, merkez-kare kırp + yeniden boyutla + sıkıştır.
 * Döner: küçük bir `data:image/webp` (veya jpeg) URL. Hata durumunda Türkçe mesajla fırlatır.
 */
export async function processAvatarFile(file: File): Promise<string> {
  if (!isImageFile(file)) {
    throw new Error('Lütfen bir görsel dosyası seç (JPG, PNG veya WebP).');
  }
  if (file.size > MAX_UPLOAD_BYTES) {
    throw new Error('Dosya çok büyük — en fazla 8 MB bir görsel seç.');
  }
  const img = await loadImage(file);
  return drawSquare(img, AVATAR_SIZE);
}

/** Dosyayı bir HTMLImageElement'e yükle (object URL, sonra serbest bırakılır). */
function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Görsel okunamadı — dosya bozuk olabilir.'));
    };
    img.src = url;
  });
}

/** Görseli merkezden kare kırpıp `size×size` canvas'a çiz ve sıkıştırılmış data URL döndür. */
function drawSquare(img: HTMLImageElement, size: number): string {
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Tarayıcı görsel işlemeyi desteklemiyor.');

  const side = Math.min(img.naturalWidth, img.naturalHeight);
  if (!side) throw new Error('Görsel boyutu okunamadı.');
  const sx = (img.naturalWidth - side) / 2;
  const sy = (img.naturalHeight - side) / 2;

  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(img, sx, sy, side, side, 0, 0, size, size);

  // WebP dene; desteklenmeyen tarayıcı `data:image/png` döndürür → jpeg'e düş.
  const webp = canvas.toDataURL('image/webp', QUALITY);
  if (webp.startsWith('data:image/webp')) return webp;
  return canvas.toDataURL('image/jpeg', QUALITY);
}
