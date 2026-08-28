import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const flatten = (value, prefix = '') => Object.entries(value).flatMap(([key, child]) => {
  if (key === '@@locale' || key.startsWith('@')) return [];
  const full = prefix ? `${prefix}.${key}` : key;
  return child && typeof child === 'object' && !Array.isArray(child) ? flatten(child, full) : [full];
});
const compare = (files, read, label) => {
  const base = new Set(flatten(read(files[0])));
  let failed = false;
  for (const file of files.slice(1)) {
    const keys = new Set(flatten(read(file)));
    const missing = [...base].filter((key) => !keys.has(key));
    const extra = [...keys].filter((key) => !base.has(key));
    if (missing.length || extra.length) {
      console.error(`${label}: ${file}\n  missing: ${missing.join(', ') || 'none'}\n  extra: ${extra.join(', ') || 'none'}`);
      failed = true;
    }
  }
  return failed;
};

const arbDir = path.join(root, 'lib/l10n');
const webDir = path.join(root, 'server/web/src/i18n');
const arbFiles = fs.readdirSync(arbDir).filter((f) => f.endsWith('.arb')).sort().map((f) => path.join(arbDir, f));
const webFiles = fs.readdirSync(webDir).filter((f) => f.endsWith('.json')).sort().map((f) => path.join(webDir, f));
const failed = compare(arbFiles, (file) => JSON.parse(fs.readFileSync(file, 'utf8')), 'Flutter ARB') ||
  compare(webFiles, (file) => JSON.parse(fs.readFileSync(file, 'utf8')), 'Web JSON');
if (failed) process.exit(1);
console.log(`Localization keys are equal: ${arbFiles.length} ARB files, ${webFiles.length} JSON files.`);
