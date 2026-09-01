// Copyright (C) 2026 Sinn Crowley
// AGPL-3.0-or-later

import { decodeBlurHash } from '../server/web/src/utils/blurhash.js';

const testVectors = [
  { name: 'Solid Black', hash: 'L00000fQfQfQfQfQfQfQfQfQfQfQ' },
  { name: 'Solid White', hash: 'L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ' },
  { name: 'Pure Red', hash: 'L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ' },
  { name: 'Pure Blue', hash: 'L~0036fZfQfZfZfVfQfVfQfQfQfQ' },
  { name: 'Sunset Flower', hash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj' },
  { name: 'Encrypted Photo Hash', hash: 'LeHVA2B92F]Ti6a|a|jtdLfQfQfQ' },
];

const results = {};
for (const v of testVectors) {
  const decoded = decodeBlurHash(v.hash, 32, 32);
  if (!decoded) throw new Error(`Failed to decode ${v.name}`);
  // Store summary checksum / samples
  let sumR = 0, sumG = 0, sumB = 0;
  for (let i = 0; i < decoded.length; i += 4) {
    sumR += decoded[i];
    sumG += decoded[i + 1];
    sumB += decoded[i + 2];
  }
  results[v.name] = {
    firstPixel: [decoded[0], decoded[1], decoded[2], decoded[3]],
    midPixel: [decoded[512 * 4], decoded[512 * 4 + 1], decoded[512 * 4 + 2], decoded[512 * 4 + 3]],
    lastPixel: [decoded[1023 * 4], decoded[1023 * 4 + 1], decoded[1023 * 4 + 2], decoded[1023 * 4 + 3]],
    sums: [sumR, sumG, sumB],
    allBytes: Array.from(decoded),
  };
}

console.log(JSON.stringify(results));
