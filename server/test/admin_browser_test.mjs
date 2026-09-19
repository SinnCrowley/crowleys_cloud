// Run manually after npm run build:
// node server/test/admin_browser_test.mjs /path/to/playwright/index.mjs [/path/to/chrome]
// Uses an isolated server, database, and browser profile; never the operator's data.
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import { createServer } from 'node:net';
const { chromium } = await import(pathToFileURL(resolve(process.argv[2])).href);
const root = await mkdtemp(join(tmpdir(), 'crowley-admin-browser-'));
const probe = createServer();
await new Promise(resolve => probe.listen(0, '127.0.0.1', resolve));
const port = probe.address().port;
await new Promise(resolve => probe.close(resolve));
const origin = `http://127.0.0.1:${port}`;
await writeFile(join(root, 'config.json'), JSON.stringify({
  host: '127.0.0.1', port, storage_root: join(root, 'storage'), db_path: join(root, 'db.sqlite'),
  public_dir: resolve('server/public'), log_dir: join(root, 'logs'), temp_upload_dir: join(root, 'uploads'),
  jwt_secret: 'browser-test-signing-secret-0123456789', encryption_key: 'browser-test-encryption-key-0123456789',
  hash_files: true, registration_mode: 'approval', rate_limit_per_minute: 10000, video_thumbs_enabled: false,
}));
const env = { ...process.env }; delete env.CROWLEYS_JWT_SECRET; delete env.CROWLEYS_ENCRYPTION_KEY;
let output = '';
const server = spawn(resolve('server/build/crowleys_cloud_server'), [join(root, 'config.json')], { env });
server.stdout.on('data', x => output += x); server.stderr.on('data', x => output += x);
let browser;
try {
  for (let tries = 0; ; tries++) {
    try { await fetch(origin + '/api/account'); break; }
    catch (e) { if (tries > 100 || server.exitCode !== null) throw new Error(output || e.message); await new Promise(r => setTimeout(r, 50)); }
  }
  browser = await chromium.launch({ executablePath: process.argv[3], headless: true });
  const context = await browser.newContext({ locale: 'en-US', viewport: { width: 1365, height: 900 } });
  const page = await context.newPage();
  const errors = []; page.on('pageerror', e => errors.push(e.message));
  await page.goto(origin);
  const auth = page.locator('.card-auth');
  await auth.getByRole('button', { name: 'Register', exact: true }).click();
  await page.locator('#username').fill('administrator');
  await page.locator('#password').fill('admin-test-password');
  await page.locator('#confirmPassword').fill('admin-test-password');
  await auth.locator('button[type=submit]').click();
  await page.getByRole('button', { name: 'Administration', exact: true }).click();
  await page.locator('.administration h2').filter({ hasText: 'administrator' }).waitFor();
  await page.screenshot({ path: '/tmp/crowley-admin-desktop.png', fullPage: true });
  const pendingContext = await browser.newContext({ locale: 'en-US', viewport: { width: 390, height: 844 } });
  const pending = await pendingContext.newPage(); pending.on('pageerror', e => errors.push(e.message));
  await pending.goto(origin);
  await pending.locator('.card-auth').getByRole('button', { name: 'Register', exact: true }).click();
  await pending.locator('#username').fill('applicant'); await pending.locator('#password').fill('initial-password');
  await pending.locator('#confirmPassword').fill('initial-password');
  await pending.locator('.card-auth button[type=submit]').click();
  await pending.getByText('Registration submitted. Await administrator approval.', { exact: true }).waitFor();
  assert.equal(await pending.evaluate(() => localStorage.getItem('cc_access_token')), null);
  await page.locator('.administration header').getByRole('button', { name: 'Refresh' }).click();
  await page.locator('.administration nav').getByRole('button', { name: /Registration requests/ }).click();
  await page.locator('.administration article').getByRole('button', { name: 'Approve', exact: true }).click();
  await page.locator('.administration nav').getByRole('button', { name: 'Users', exact: true }).click();
  const person = page.locator('.administration form').filter({ has: page.getByRole('heading', { name: 'applicant', exact: true }) });
  await person.waitFor();
  page.once('dialog', d => d.accept());
  await person.getByRole('button', { name: 'Reset password', exact: true }).click();
  const code = await page.locator('.recovery code').textContent(); assert.match(code, /^\d{6}$/);
  await pending.getByRole('button', { name: 'Reset Password', exact: true }).click();
  await pending.locator('#password').fill('recovered-password');
  await pending.locator('#confirmPassword').fill('recovered-password');
  await pending.locator('#recoveryCode').fill(code);
  await pending.locator('.card-auth button[type=submit]').click();
  await pending.getByText('Password reset successfully!', { exact: true }).waitFor();
  await pending.locator('#password').fill('recovered-password');
  await pending.locator('.card-auth button[type=submit]').click();
  await pending.locator('.card-auth').waitFor({ state: 'hidden' });
  assert.equal(await pending.getByRole('button', { name: 'Administration', exact: true }).count(), 0);
  await pending.goto(origin + '/admin');
  await pending.getByText('Administrator access is required.', { exact: true }).waitFor();
  await page.locator('.administration nav').getByRole('button', { name: 'Server settings', exact: true }).click();
  const quota = page.locator('label.setting').filter({ hasText: 'Default storage limit' });
  await quota.locator('input').fill('4096');
  await page.locator('.administration form').getByRole('button', { name: 'Save', exact: true }).click();
  await page.getByText('Saved.', { exact: true }).waitFor();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.evaluate(() => document.querySelector('.main-content')?.scrollTo(0, 0));
  await page.screenshot({ path: '/tmp/crowley-admin-mobile.png', fullPage: true, animations: 'disabled' });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth), false);
  await page.locator('.administration nav').getByRole('button', { name: 'Maintenance', exact: true }).click();
  await page.getByRole('heading', { name: 'Encryption key rotation', exact: true }).waitFor();
  assert.deepEqual(errors, []);
  console.log('Browser: bootstrap, pending approval, admin recovery, access control, configuration and mobile layout passed.');
} catch (error) {
  console.error(error);
  for (const ctx of browser?.contexts() || []) for (const tab of ctx.pages()) {
    console.error(await tab.locator('body').innerText());
    console.error(await tab.locator('form input').evaluateAll(inputs => inputs.map(x => ({ id: x.id, valid: x.validity.valid, message: x.validationMessage }))));
  }
  throw error;
} finally {
  await browser?.close();
  server.kill();
  const timeout = setTimeout(() => server.kill('SIGKILL'), 5000);
  await new Promise(resolve => { if (server.exitCode !== null || server.signalCode !== null) resolve(); else server.once('exit', resolve); });
  clearTimeout(timeout);
  await rm(root, { recursive: true, force: true });
}
