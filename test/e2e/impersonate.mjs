// Decided by Jan 2026-10-07 (q4): an admin who toggles stealth mode while
// impersonating (redmine_impersonate) changes the impersonated user's setting;
// the admin's own setting is untouched. Records "not installed" without that plugin.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('impersonate');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
const on = () => t.page.evaluate(() => document.body.classList.contains('stealth_on'));
const BAR = '#impersonation-bar';

async function impersonate(login) {
  await t.go('/users?set_filter=1&f[]=status&op[status]=*&f[]=name&op[name]=~&v[name][]=' + login);
  const href = await t.page.locator('td.login a', { hasText: new RegExp(`^${login}$`) }).first().getAttribute('href');
  await t.go(href);
  await t.page.click('#impersonate');
  await t.settle();
  await t.sudo();
  await t.settle();
  t.check(`impersonate ${login}`);
}

await t.login('admin');
await t.go('/admin/plugins');
const installed = (await t.page.content()).includes('Impersonat');
if (!installed) {
  await t.shot('not-installed', 'redmine_impersonate is not installed here: nothing to check (run with the GEOxyz plugins)');
  await t.done();
  process.exit();
}

await impersonate('manager');
expect('impersonation bar', await t.page.locator(BAR).count(), 1);
await t.go('/projects/e2e-project');
expect('manager starts with stealth off', await on(), false);
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 }).catch(() => {});
t.check('toggle while impersonating');
expect('stealth on while impersonating manager', await on(), true);
await t.shot('toggled-as-manager', 'Admin impersonating manager switches stealth on: the bar shows the impersonation, the header the stealth state');

await t.page.click(`${BAR} a`);
await t.settle();
t.check('cancel');
await t.go('/projects/e2e-project');
expect('admin\'s own stealth state after Cancel', await on(), false);
await t.shot('admin-own-state', 'After Cancel the admin\'s own stealth state is unchanged (off)');

await impersonate('manager');
await t.go('/projects/e2e-project');
expect('manager\'s stored setting', await on(), true);
await t.shot('manager-setting-kept', 'Impersonating manager again: the setting changed earlier is stored on manager (decided: accepted)');
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 });
t.check('reset');
await t.page.click(`${BAR} a`);
await t.settle();
await t.done();
