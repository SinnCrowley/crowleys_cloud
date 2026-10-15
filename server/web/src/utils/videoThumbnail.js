// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const VIDEO_EXT_REGEX = /\.(mp4|mkv|avi|mov|webm|flv|wmv|m4v|3gp|ts|ogg)$/i;

/**
 * Clamps width and height to fit within maxDimension while preserving aspect ratio.
 * Does not upscale images smaller than maxDimension.
 *
 * @param {number} width
 * @param {number} height
 * @param {number} [maxDimension=512]
 * @returns {{ width: number, height: number }}
 */
export function clampDimensions(width, height, maxDimension = 512) {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
    return { width: 0, height: 0 };
  }

  const maxDim = Number.isFinite(maxDimension) && maxDimension > 0 ? maxDimension : 512;

  if (width <= maxDim && height <= maxDim) {
    return { width, height };
  }

  if (width >= height) {
    const targetW = maxDim;
    const targetH = Math.max(1, Math.round(maxDim * (height / width)));
    return { width: targetW, height: targetH };
  } else {
    const targetH = maxDim;
    const targetW = Math.max(1, Math.round(maxDim * (width / height)));
    return { width: targetW, height: targetH };
  }
}

/**
 * Checks whether a File, Blob, or filename represents a video file.
 *
 * @param {File|Blob|string|object} file
 * @returns {boolean}
 */
export function isVideoFile(file) {
  if (!file) return false;
  if (typeof file === 'string') {
    return VIDEO_EXT_REGEX.test(file.trim());
  }
  if (typeof file === 'object') {
    if (typeof file.type === 'string' && file.type.startsWith('video/')) {
      return true;
    }
    if (typeof file.name === 'string' && file.name.trim() && VIDEO_EXT_REGEX.test(file.name.trim())) {
      return true;
    }
  }
  return false;
}

/**
 * Converts a Blob or File to a Base64 string (without Data URI prefix).
 * Supported in both Browser (FileReader / arrayBuffer) and Node.js (arrayBuffer / Buffer).
 *
 * @param {Blob|File|string} blob
 * @returns {Promise<string|null>}
 */
export async function blobToBase64(blob) {
  if (!blob) return null;
  if (typeof blob === 'string') {
    const comma = blob.indexOf(',');
    return comma !== -1 ? blob.slice(comma + 1) : blob;
  }

  if (typeof FileReader !== 'undefined') {
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        const res = reader.result;
        if (typeof res === 'string') {
          const comma = res.indexOf(',');
          resolve(comma !== -1 ? res.slice(comma + 1) : res);
        } else {
          resolve(null);
        }
      };
      reader.onerror = () => resolve(null);
      reader.readAsDataURL(blob);
    });
  }

  if (typeof blob.arrayBuffer === 'function') {
    try {
      const buf = await blob.arrayBuffer();
      if (typeof Buffer !== 'undefined') {
        return Buffer.from(buf).toString('base64');
      }
      const bytes = new Uint8Array(buf);
      let binary = '';
      const len = bytes.byteLength;
      for (let i = 0; i < len; i += 8192) {
        binary += String.fromCharCode.apply(null, bytes.subarray(i, i + 8192));
      }
      return btoa(binary);
    } catch (_) {
      return null;
    }
  }

  return null;
}

/**
 * Extracts a WebP poster thumbnail from a video File using HTML5 <video> and offscreen <canvas>.
 * Clamps maximum dimension to maxDimension (default 512px) preserving aspect ratio.
 * Enforces strict timeout (default 4000ms) and cleans up all resources.
 * Returns null gracefully if format unsupported, decoding fails, or operation times out.
 *
 * @param {File|Blob} file
 * @param {Object} [options]
 * @param {number} [options.maxDimension=512]
 * @param {number} [options.maxSize] Alias for maxDimension
 * @param {number} [options.quality=0.8]
 * @param {number} [options.timeout=4000]
 * @param {number} [options.timeoutMs] Alias for timeout
 * @param {AbortSignal} [options.signal]
 * @param {Document} [options.document] Dependency injection for testing
 * @param {Object} [options.urlApi] Dependency injection for testing
 * @returns {Promise<Blob|null>}
 */
export async function extractVideoPoster(file, {
  maxDimension = 512,
  maxSize,
  quality = 0.8,
  timeout = 4000,
  timeoutMs,
  signal,
  document: customDoc,
  urlApi: customUrl
} = {}) {
  if (!file || !isVideoFile(file)) return null;
  if (signal?.aborted) return null;

  const targetMaxDim = maxSize ?? maxDimension ?? 512;
  const targetTimeout = timeoutMs ?? timeout ?? 4000;

  const doc = customDoc || (typeof document !== 'undefined' ? document : (typeof window !== 'undefined' ? window.document : null));
  const urlApi = customUrl || (typeof URL !== 'undefined' ? URL : (typeof window !== 'undefined' ? window.URL : null));
  if (!doc || !urlApi?.createObjectURL) return null;

  let objectUrl = null;
  let video = null;
  let canvas = null;
  let timerId = null;

  const cleanup = () => {
    if (timerId) {
      clearTimeout(timerId);
      timerId = null;
    }
    if (video) {
      video.onerror = null;
      video.onloadedmetadata = null;
      video.onseeked = null;
      try { video.pause?.(); } catch (_) {}
      try { video.removeAttribute?.('src'); } catch (_) {}
      try { video.load?.(); } catch (_) {}
      video = null;
    }
    if (canvas) {
      try {
        canvas.width = 0;
        canvas.height = 0;
      } catch (_) {}
      canvas = null;
    }
    if (objectUrl && urlApi?.revokeObjectURL) {
      try { urlApi.revokeObjectURL(objectUrl); } catch (_) {}
      objectUrl = null;
    }
  };

  try {
    const extractionPromise = new Promise((resolve) => {
      try {
        objectUrl = urlApi.createObjectURL(file);
        video = doc.createElement('video');
        video.muted = true;
        video.playsInline = true;
        video.preload = 'metadata';

        video.onerror = () => resolve(null);

        video.onloadedmetadata = () => {
          try {
            const duration = video.duration;
            const seekTime = Math.min(1.0, Number.isFinite(duration) && duration > 0 ? duration * 0.1 : 0.5);
            video.currentTime = seekTime;
          } catch (_) {
            resolve(null);
          }
        };

        video.onseeked = () => {
          try {
            const vw = video.videoWidth;
            const vh = video.videoHeight;
            if (!vw || !vh) {
              resolve(null);
              return;
            }

            const { width: targetW, height: targetH } = clampDimensions(vw, vh, targetMaxDim);
            if (targetW <= 0 || targetH <= 0) {
              resolve(null);
              return;
            }

            canvas = doc.createElement('canvas');
            canvas.width = targetW;
            canvas.height = targetH;
            const ctx = canvas.getContext('2d');
            if (!ctx) {
              resolve(null);
              return;
            }

            ctx.drawImage(video, 0, 0, targetW, targetH);
            if (typeof canvas.toBlob !== 'function') {
              resolve(null);
              return;
            }

            canvas.toBlob((blob) => {
              // Ensure exported format is WebP and not a degraded PNG fallback
              if (!blob || (blob.type && blob.type !== 'image/webp')) {
                resolve(null);
              } else {
                resolve(blob);
              }
            }, 'image/webp', quality);
          } catch (_) {
            resolve(null);
          }
        };

        video.src = objectUrl;
      } catch (_) {
        resolve(null);
      }
    });

    const timeoutPromise = new Promise((resolve) => {
      timerId = setTimeout(() => resolve(null), targetTimeout);
    });

    const abortPromise = signal ? new Promise((resolve) => {
      if (signal.aborted) {
        resolve(null);
      } else {
        signal.addEventListener('abort', () => resolve(null), { once: true });
      }
    }) : null;

    const racers = [extractionPromise, timeoutPromise];
    if (abortPromise) racers.push(abortPromise);

    const result = await Promise.race(racers);
    return result || null;
  } catch (_) {
    return null;
  } finally {
    cleanup();
  }
}
