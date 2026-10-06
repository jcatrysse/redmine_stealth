// The link sends the state it shows (toggle=true for "Enable", false for
// "Disable"), so a stale tab cannot switch stealth off while it says "Enable".
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('two_tabs');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };

await t.login('manager');
await t.go('/projects/e2e-project');
expect('data-params when off', await t.page.getAttribute('#stealth_toggle', 'data-params'), 'toggle=true');
const second = await t.page.context().newPage();
await second.goto(t.BASE + '/projects/e2e-project');
await second.click('#account .dropdown-trigger');
await second.click('#stealth_toggle');
await second.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 });
await second.close();

// the first tab still says "Enable"
await t.page.click('#account .dropdown-trigger');
expect('stale label', await t.page.textContent('#stealth_toggle'), 'Enable Stealth Mode');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 }).catch(() => {});
t.check('click in the stale tab');
await t.go('/projects/e2e-project');
expect('state after the stale "Enable"', await t.page.evaluate(() => document.body.classList.contains('stealth_on')), true);
expect('data-params when on', await t.page.getAttribute('#stealth_toggle', 'data-params'), 'toggle=false');
await t.shot('stale-tab', 'Enabled in a second tab, then "Enable" in the stale first tab: stealth stays on (it used to flip off)');

await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 });
t.check('disable');
await t.done();
