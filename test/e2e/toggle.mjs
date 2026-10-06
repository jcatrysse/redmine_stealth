// The account-menu toggle on the desktop header: off -> on -> persists -> off.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('toggle');
const state = () => t.page.evaluate(() => document.body.classList.contains('stealth_on') ? 'on' : 'off');
const openMenu = async () => {
  if (await t.page.locator('#account .dropdown-content.hidden').count()) await t.page.click('#account .dropdown-trigger');
  await t.page.waitForSelector('#stealth_toggle', { state: 'visible' });
};
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };

await t.login('manager');
await t.go('/projects/e2e-project');
expect('initial state', await state(), 'off');
await t.shot('off', 'Stealth mode off: the normal header colours');
await openMenu();
expect('label when off', await t.page.textContent('#stealth_toggle'), 'Enable Stealth Mode');
await t.shot('menu-off', 'The account dropdown offers "Enable Stealth Mode" as its first item', { full: false });

await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 }).catch(() => {});
t.check('enable');
expect('state after enabling', await state(), 'on');
await openMenu().catch(() => {});
expect('label when on', await t.page.textContent('#stealth_toggle'), 'Disable Stealth Mode');
await t.shot('menu-on', 'After the click: black top menu, dark header, the item now reads "Disable Stealth Mode"', { full: false });

await t.go('/projects/e2e-project/issues');
expect('state after navigating', await state(), 'on');
await t.shot('persists', 'Stealth mode is stored on the user: still on after loading another page');

await openMenu();
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 }).catch(() => {});
t.check('disable');
await t.go('/projects/e2e-project/issues');
expect('state after disabling and reloading', await state(), 'off');
await t.shot('off-again', 'Disabled again: normal header after a reload');

await t.login('admin');
await t.go('/');
await openMenu();
expect('admin label', await t.page.textContent('#stealth_toggle'), 'Enable Stealth Mode');
await t.shot('admin-menu', 'An administrator (no membership needed) also gets the toggle', { full: false });

await t.done();
