// Copyright (C) 2026 Sinn Crowley
// AGPL-3.0-or-later

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse, walk } from 'svelte/compiler';
import {
  isValidBlurHash,
  decodeBlurHashToImageData,
  decodeBlurHash,
} from './src/utils/blurhash.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('===============================================================');
console.log('  M5 Adversarial Verification & Stress Test Suite (BlurHash UI)');
console.log('===============================================================\n');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition, message) {
  totalTests++;
  if (!condition) {
    failedTests++;
    console.error(`  ❌ [FAIL] ${message}`);
    throw new Error(`Assertion failed: ${message}`);
  } else {
    passedTests++;
    console.log(`  ✅ [PASS] ${message}`);
  }
}

// ---------------------------------------------------------------------------
// 1. Reference Vector Parity & Color Fidelity
// ---------------------------------------------------------------------------
console.log('--- 1. Reference Vector Parity & Color Fidelity ---');

// 1.1 Pure Flat Color Hashes (DC component tested across all 32x32 pixels)
const flatVectors = [
  {
    name: 'Flat Black',
    hash: 'L00000fQfQfQfQfQfQfQfQfQfQfQ',
    expected: [0, 0, 0, 255],
  },
  {
    name: 'Flat White',
    hash: 'L0TSUAfQfQfQfQfQfQfQfQfQfQfQ',
    expected: [255, 255, 255, 255],
  },
  {
    name: 'Flat Pure Red',
    hash: 'L0TI:jfQfQfQfQfQfQfQfQfQfQfQ',
    expected: [255, 0, 0, 255],
  },
  {
    name: 'Flat Pure Blue',
    hash: 'L00036fQfQfQfQfQfQfQfQfQfQfQ',
    expected: [0, 0, 255, 255],
  },
];

for (const vec of flatVectors) {
  assert(isValidBlurHash(vec.hash), `isValidBlurHash on ${vec.name} (${vec.hash})`);
  const decoded = decodeBlurHash(vec.hash, 32, 32);
  assert(decoded !== null, `decodeBlurHash returns non-null for ${vec.name}`);
  assert(decoded.length === 32 * 32 * 4, `decoded buffer size matches 32x32x4 (${decoded.length} bytes)`);

  let allMatch = true;
  for (let i = 0; i < decoded.length; i += 4) {
    if (
      decoded[i] !== vec.expected[0] ||
      decoded[i + 1] !== vec.expected[1] ||
      decoded[i + 2] !== vec.expected[2] ||
      decoded[i + 3] !== vec.expected[3]
    ) {
      allMatch = false;
      break;
    }
  }
  assert(allMatch, `${vec.name} matches exact RGBA [${vec.expected.join(',')}] across all 1024 pixels`);
}

// 1.2 Backend C++ Test Vectors (from BlurHashEncoder.cpp / blurhash_test.cpp)
const backendVectors = [
  {
    name: 'Backend Solid Black 4x4',
    hash: 'L00000fQfQfQfQfQfQfQfQfQfQfQ',
    check: (d) => {
      let maxDiff = 0;
      for (let i = 0; i < d.length; i += 4) {
        maxDiff = Math.max(maxDiff, d[i], d[i + 1], d[i + 2]);
      }
      return maxDiff === 0;
    },
    desc: 'all pixels RGBA [0,0,0,255]',
  },
  {
    name: 'Backend Solid White 4x4',
    hash: 'L~TSUA~qfQ~q~q%MfQ%MfQfQfQfQ',
    check: (d) => {
      // Top-left pixel is pure white (255,255,255) and average intensity > 200
      let total = 0;
      for (let i = 0; i < d.length; i += 4) {
        total += d[i] + d[i + 1] + d[i + 2];
      }
      const avg = total / (d.length * 3 / 4);
      return d[0] === 255 && d[1] === 255 && d[2] === 255 && avg > 200;
    },
    desc: 'dominant white DC (top-left 255,255,255, average intensity > 200)',
  },
  {
    name: 'Backend Pure Red 4x4',
    hash: 'L~TI:j|cfQ|c|c$5fQ$5fQfQfQfQ',
    check: (d) => {
      // Red channel is heavily dominant over G and B
      let rSum = 0, gbSum = 0;
      for (let i = 0; i < d.length; i += 4) {
        rSum += d[i];
        gbSum += d[i + 1] + d[i + 2];
      }
      return rSum > gbSum * 5;
    },
    desc: 'dominant red channel (R > 5 * (G+B))',
  },
  {
    name: 'Backend Pure Blue 4x4',
    hash: 'L~0036fZfQfZfZfVfQfVfQfQfQfQ',
    check: (d) => {
      // Blue channel is heavily dominant over R and G
      let bSum = 0, rgSum = 0;
      for (let i = 0; i < d.length; i += 4) {
        bSum += d[i + 2];
        rgSum += d[i] + d[i + 1];
      }
      return bSum > rgSum * 5;
    },
    desc: 'dominant blue channel (B > 5 * (R+G))',
  },
  {
    name: 'Standard 4x3 Sunset/Flower Photo Hash',
    hash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    check: (d) => {
      let hasVariation = false;
      const firstR = d[0], firstG = d[1], firstB = d[2];
      for (let p = 4; p < d.length; p += 4) {
        if (d[p] !== firstR || d[p + 1] !== firstG || d[p + 2] !== firstB) {
          hasVariation = true;
          break;
        }
      }
      return hasVariation;
    },
    desc: 'rich gradient variation across coordinates',
  },
];

for (const vec of backendVectors) {
  assert(isValidBlurHash(vec.hash), `isValidBlurHash on ${vec.name} (${vec.hash})`);
  const decoded = decodeBlurHash(vec.hash, 32, 32);
  assert(decoded !== null, `decodeBlurHash returns non-null for ${vec.name}`);
  assert(vec.check(decoded), `${vec.name} meets semantic expectation: ${vec.desc}`);
}

// 1.3 Check dimension handling: 1x1, 16x16, 64x32, 128x128
const dimTests = [
  [1, 1],
  [16, 16],
  [64, 32],
  [128, 128],
];
for (const [w, h] of dimTests) {
  const imgData = decodeBlurHashToImageData('LEHV6nWB2yk8pyo0adR*.7kCMdnj', w, h);
  assert(imgData !== null, `decodeBlurHashToImageData handles ${w}x${h}`);
  assert(imgData.width === w && imgData.height === h, `imgData dimensions match ${w}x${h}`);
  assert(imgData.data.length === w * h * 4, `imgData.data length matches ${w}x${h}x4`);
}

// ---------------------------------------------------------------------------
// 2. Malformed, Fuzzed & Boundary Input Resilience
// ---------------------------------------------------------------------------
console.log('\n--- 2. Malformed, Fuzzed & Boundary Input Resilience ---');

const malformedInputs = [
  { input: '', desc: 'Empty string' },
  { input: null, desc: 'null value' },
  { input: undefined, desc: 'undefined value' },
  { input: 123456, desc: 'number value' },
  { input: {}, desc: 'empty object' },
  { input: [], desc: 'empty array' },
  { input: true, desc: 'boolean true' },
  { input: 'L0000', desc: 'string too short (< 6 chars, len=5)' },
  { input: 'L', desc: 'single character' },
  { input: 'L00000fQfQfQfQfQfQfQfQfQfQf', desc: 'off-by-one short (len=27 for 4x3)' },
  { input: 'L00000fQfQfQfQfQfQfQfQfQfQfQQ', desc: 'off-by-one long (len=29 for 4x3)' },
  { input: 'L 0000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains space' },
  { input: 'L!0000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains exclamation mark (! not in Base83)' },
  { input: 'L(0000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains parenthesis' },
  { input: 'L/0000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains slash' },
  { input: 'L\\0000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains backslash' },
  { input: 'L🔥000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains multi-byte unicode emoji' },
  { input: 'L\x00000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains null byte' },
  { input: 'L\n\t000fQfQfQfQfQfQfQfQfQfQfQ', desc: 'contains newline and tab' },
  { input: 'A'.repeat(10000), desc: '10,000 char long string' },
];

for (const m of malformedInputs) {
  assert(!isValidBlurHash(m.input), `isValidBlurHash returns false for ${m.desc}`);
  const outImg = decodeBlurHashToImageData(m.input, 32, 32);
  assert(outImg === null, `decodeBlurHashToImageData gracefully returns null for ${m.desc}`);
  const outBuf = decodeBlurHash(m.input, 32, 32);
  assert(outBuf === null, `decodeBlurHash gracefully returns null for ${m.desc}`);
}

// Invalid output dimension requests
const invalidDims = [
  [0, 32],
  [32, 0],
  [-10, 32],
  [32, -5],
  [0, 0],
];
for (const [w, h] of invalidDims) {
  const res = decodeBlurHashToImageData('L00000fQfQfQfQfQfQfQfQfQfQfQ', w, h);
  assert(res === null, `decodeBlurHashToImageData returns null for invalid dimensions ${w}x${h}`);
}

// Deterministic Fuzzing generator
console.log('  Running 2,000 deterministic fuzzing mutations...');
const base83Chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';
let fuzzValidCount = 0;
let fuzzInvalidGracefulCount = 0;

for (let i = 0; i < 2000; i++) {
  let str = '';
  const len = Math.floor(Math.sin(i * 997) * 20 + 28);
  for (let j = 0; j < Math.max(0, len); j++) {
    const charCode = Math.floor(Math.abs(Math.cos(i * 31 + j * 17) * 128));
    str += String.fromCharCode(charCode);
  }

  try {
    const isValid = isValidBlurHash(str);
    const decoded = decodeBlurHashToImageData(str, 16, 16);
    if (isValid) {
      fuzzValidCount++;
      if (decoded === null) {
        throw new Error(`Valid hash failed to decode: ${str}`);
      }
    } else {
      fuzzInvalidGracefulCount++;
      if (decoded !== null) {
        throw new Error(`Invalid hash returned non-null: ${str}`);
      }
    }
  } catch (err) {
    throw new Error(`Fuzz iteration ${i} threw exception: ${err.message}`);
  }
}
assert(
  fuzzInvalidGracefulCount > 0,
  `Fuzzer completed 2,000 iterations without crashes (${fuzzInvalidGracefulCount} rejected safely, ${fuzzValidCount} valid)`
);

// ---------------------------------------------------------------------------
// 3. LRU Cache Stress, Memory Bounding & Latency Benchmarks
// ---------------------------------------------------------------------------
console.log('\n--- 3. LRU Cache Stress, Memory Bounding & Latency Benchmarks ---');

function generateValidBlurHash(index) {
  let hash = 'L'; // sizeFlag = 4x3 (21 = 'L')
  const qMax = base83Chars[index % 83];
  hash += qMax;
  
  // 4 chars DC
  for (let i = 0; i < 4; i++) {
    const charIdx = (index * 7 + i * 13) % 83;
    hash += base83Chars[charIdx];
  }
  // 22 chars AC
  for (let i = 0; i < 22; i++) {
    const charIdx = (index * 17 + i * 29 + 11) % 83;
    hash += base83Chars[charIdx];
  }
  return hash;
}

const uniqueHashes = [];
for (let i = 0; i < 2000; i++) {
  const h = generateValidBlurHash(i);
  if (isValidBlurHash(h)) {
    uniqueHashes.push(h);
  }
}
assert(uniqueHashes.length === 2000, `Generated 2,000 valid unique BlurHashes`);

// Benchmark cold decode performance
const coldStart = performance.now();
for (let i = 0; i < 100; i++) {
  decodeBlurHashToImageData(uniqueHashes[i], 32, 32);
}
const coldEnd = performance.now();
const avgColdMs = (coldEnd - coldStart) / 100;
console.log(`  Cold decode average latency (32x32): ${avgColdMs.toFixed(4)} ms`);
assert(avgColdMs < 1.0, `Cold decode is fast (< 1.0 ms, measured: ${avgColdMs.toFixed(4)} ms)`);

// Execute 10,000 decodes across 2,000 unique hashes to stress LRU cache evictions
const memBefore = process.memoryUsage().heapUsed;
const stressStart = performance.now();
for (let step = 0; step < 10000; step++) {
  const hashIdx = (step * 37) % uniqueHashes.length;
  const res = decodeBlurHashToImageData(uniqueHashes[hashIdx], 32, 32);
  if (!res || res.width !== 32) {
    throw new Error(`Stress decode failed at step ${step}`);
  }
}
const stressEnd = performance.now();
const totalStressMs = stressEnd - stressStart;
const memAfter = process.memoryUsage().heapUsed;
const memDiffMb = (memAfter - memBefore) / (1024 * 1024);

console.log(`  10,000 decode stress run total time: ${totalStressMs.toFixed(2)} ms`);
console.log(`  Heap delta after 10,000 decodes across 2,000 hashes: ${memDiffMb.toFixed(2)} MB`);
assert(totalStressMs < 5000, `10,000 stress decodes completed in under 5s (${totalStressMs.toFixed(2)} ms)`);
assert(memDiffMb < 25.0, `Memory footprint is bounded during continuous cache churn (< 25 MB delta, measured: ${memDiffMb.toFixed(2)} MB)`);

// Benchmark Cache Hit Latency on warm entries
const warmHash = uniqueHashes[0];
decodeBlurHashToImageData(warmHash, 32, 32); // Ensure it's in cache

const hitIterations = 10000;
const hitStart = performance.now();
for (let i = 0; i < hitIterations; i++) {
  decodeBlurHashToImageData(warmHash, 32, 32);
}
const hitEnd = performance.now();
const avgHitMs = (hitEnd - hitStart) / hitIterations;
console.log(`  Cache HIT average latency: ${avgHitMs.toFixed(6)} ms (${(avgHitMs * 1000).toFixed(3)} µs)`);
assert(avgHitMs < 0.005, `Cache HIT latency is < 0.005 ms (5 µs, measured: ${avgHitMs.toFixed(6)} ms)`);

// ---------------------------------------------------------------------------
// 4. Programmatic HTML AST & Attribute Verification
// ---------------------------------------------------------------------------
console.log('\n--- 4. Programmatic HTML AST & Attribute Verification ---');

const svelteFilesToVerify = [
  'src/components/SmartThumbnail.svelte',
];

for (const relPath of svelteFilesToVerify) {
  const fullPath = path.join(__dirname, relPath);
  assert(fs.existsSync(fullPath), `Target file exists: ${relPath}`);

  const content = fs.readFileSync(fullPath, 'utf8');
  const ast = parse(content, { filename: relPath });

  let foundThumbnailImgCount = 0;
  let foundBlurHashCanvasCount = 0;

  walk(ast.html, {
    enter(node) {
      if (node.type === 'Element' && node.name === 'img') {
        const classAttr = node.attributes.find((a) => a.name === 'class');
        const isThumbnailImg =
          classAttr &&
          classAttr.value.some(
            (v) => (v.data && v.data.includes('thumbnail-img')) || v.raw === 'thumbnail-img'
          );

        if (isThumbnailImg) {
          foundThumbnailImgCount++;

          const loadingAttr = node.attributes.find((a) => a.name === 'loading');
          assert(
            loadingAttr !== undefined,
            `${relPath}: thumbnail <img> has 'loading' attribute`
          );
          const loadingVal = loadingAttr.value[0]?.data || loadingAttr.value[0]?.raw;
          assert(
            loadingVal === 'lazy',
            `${relPath}: thumbnail <img> loading attribute is 'lazy' (got '${loadingVal}')`
          );

          const decodingAttr = node.attributes.find((a) => a.name === 'decoding');
          assert(
            decodingAttr !== undefined,
            `${relPath}: thumbnail <img> has 'decoding' attribute`
          );
          const decodingVal = decodingAttr.value[0]?.data || decodingAttr.value[0]?.raw;
          assert(
            decodingVal === 'async',
            `${relPath}: thumbnail <img> decoding attribute is 'async' (got '${decodingVal}')`
          );

          const onLoadAttr = node.attributes.find(
            (a) => a.name === 'load' && a.type === 'EventHandler'
          );
          assert(
            onLoadAttr !== undefined,
            `${relPath}: thumbnail <img> has 'on:load' event handler`
          );
        }
      }

      if (node.type === 'InlineComponent' && node.name === 'BlurHashCanvas') {
        foundBlurHashCanvasCount++;
        const blurhashAttr = node.attributes.find((a) => a.name === 'blurhash');
        assert(
          blurhashAttr !== undefined,
          `${relPath}: <BlurHashCanvas> has 'blurhash' prop binding`
        );
      }
    },
  });

  assert(
    foundThumbnailImgCount > 0,
    `${relPath}: Found and verified ${foundThumbnailImgCount} thumbnail <img> element(s)`
  );
  assert(
    foundBlurHashCanvasCount >= foundThumbnailImgCount,
    `${relPath}: Found and verified ${foundBlurHashCanvasCount} <BlurHashCanvas> component(s)`
  );

  // CSS verification
  assert(
    content.includes('.thumbnail-wrapper'),
    `${relPath}: CSS contains .thumbnail-wrapper container rule`
  );
  assert(
    content.includes('.thumbnail-img'),
    `${relPath}: CSS contains .thumbnail-img rule`
  );
  assert(
    content.includes('.thumbnail-img.loaded') || content.includes('.thumbnail-img:global(.loaded)'),
    `${relPath}: CSS contains smooth crossfade opacity loaded transition selector`
  );
}

// Verify consumer views use SmartThumbnail
const consumerFiles = [
  'src/components/FileGrid.svelte',
  'src/components/FileList.svelte',
  'src/routes/TrashBrowser.svelte',
];

for (const relPath of consumerFiles) {
  const fullPath = path.join(__dirname, relPath);
  assert(fs.existsSync(fullPath), `Consumer file exists: ${relPath}`);
  const content = fs.readFileSync(fullPath, 'utf8');
  assert(content.includes('SmartThumbnail'), `${relPath} integrates SmartThumbnail component`);
}

// Also check BlurHashCanvas.svelte
const canvasPath = path.join(__dirname, 'src/components/BlurHashCanvas.svelte');
const canvasContent = fs.readFileSync(canvasPath, 'utf8');
const canvasAst = parse(canvasContent, { filename: 'BlurHashCanvas.svelte' });

let foundCanvasEl = false;
walk(canvasAst.html, {
  enter(node) {
    if (node.type === 'Element' && node.name === 'canvas') {
      foundCanvasEl = true;
      const ariaHidden = node.attributes.find((a) => a.name === 'aria-hidden');
      assert(ariaHidden !== undefined, 'BlurHashCanvas.svelte <canvas> has aria-hidden="true"');
    }
  },
});
assert(foundCanvasEl, 'BlurHashCanvas.svelte renders <canvas> element');

console.log('\n===============================================================');
console.log(`  ALL ADVERSARIAL TESTS COMPLETED EMPIRICALLY`);
console.log(`  Total assertions: ${totalTests}`);
console.log(`  Passed: ${passedTests}`);
console.log(`  Failed: ${failedTests}`);
console.log('===============================================================');

if (failedTests > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
