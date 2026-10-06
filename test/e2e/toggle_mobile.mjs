// The toggle in the mobile flyout menu, where Redmine moves the account menu.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('toggle_mobile', { width: 390, height: 844 });
const state = () => t.page.evaluate(() => document.body.classList.contains('stealth_on') ? 'on' : 'off');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };

await t.login('manager');
await t.go('/projects/e2e-project');
await t.page.click('.js-flyout-menu-toggle-button');
await t.page.waitForSelector('.js-profile-menu #stealth_toggle', { state: 'visible', timeout: 10000 })
  .catch(() => t.problems.push('the toggle is not in the flyout profile menu'));
expect('ids on the page', await t.page.locator('[id=stealth_toggle]').count(), 1);
await t.page.locator('.js-profile-menu #stealth_toggle').scrollIntoViewIfNeeded();
await t.shot('flyout-off', 'Phone width: the toggle sits in the flyout menu under Profile', { full: false });

await t.page.click('.js-profile-menu #stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 }).catch(() => {});
t.check('enable on mobile');
expect('state after the tap', await state(), 'on');
expect('label after the tap', await t.page.textContent('#stealth_toggle'), 'Disable Stealth Mode');
await t.shot('flyout-on', 'After the tap: label switched, stealth mode on', { full: false });

await t.go('/projects/e2e-project');
expect('state after reload', await state(), 'on');
await t.shot('header-on', 'Phone width, stealth on: the header carries the stealth colours', { full: false });

await t.page.click('.js-flyout-menu-toggle-button');
await t.page.click('.js-profile-menu #stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 }).catch(() => {});
t.check('disable on mobile');
expect('state after the second tap', await state(), 'off');
await t.done();
