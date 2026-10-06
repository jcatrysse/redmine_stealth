// Signing in always switches stealth mode off, so nobody stays silent by accident.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('login_decloak');
const state = () => t.page.evaluate(() => document.body.classList.contains('stealth_on') ? 'on' : 'off');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };

await t.login('manager');
await t.go('/projects/e2e-project');
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 }).catch(() => {});
t.check('enable');
expect('state before sign-out', await state(), 'on');
await t.shot('before-logout', 'Stealth mode switched on before signing out');

if (await t.page.locator('#account .dropdown-content.hidden').count()) await t.page.click('#account .dropdown-trigger');
await t.page.click('#account a.logout');
await t.settle();
t.check('sign out');

await t.login('manager');
await t.go('/projects/e2e-project');
expect('state after signing in again', await state(), 'off');
await t.page.click('#account .dropdown-trigger');
expect('label after signing in again', await t.page.textContent('#stealth_toggle'), 'Enable Stealth Mode');
await t.shot('after-login', 'After signing in again stealth mode is off: normal header, "Enable Stealth Mode"', { full: false });
await t.done();
