// A toggle that fails (here: the session ended in another tab) shows the
// translated failure message and leaves the page as it was.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('failure');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };

await t.login('manager');
await t.go('/projects/e2e-project');
const other = await t.page.context().newPage();
await other.goto(t.BASE + '/projects/e2e-project');
await other.click('#account .dropdown-trigger');
await other.click('#account a.logout');
await other.waitForLoadState('load');
await other.close();

let dialog = null;
t.page.once('dialog', async d => { dialog = d.message(); await d.dismiss(); });
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
for (let i = 0; i < 20 && dialog === null; i++) await t.page.waitForTimeout(250);
t.check('toggle after the session ended', { requests: ['401 xhr /stealth/toggle', '422 xhr /stealth/toggle'] });
expect('alert text', dialog, 'Failed to toggle stealth mode.');
expect('state unchanged', await t.page.evaluate(() => document.body.classList.contains('stealth_off')), true);
expect('label unchanged', await t.page.textContent('#stealth_toggle'), 'Enable Stealth Mode');
await t.shot('after-failure', `Toggle after signing out in another tab: alert "${dialog}", page unchanged (still "Enable Stealth Mode")`, { full: false });
await t.done();
