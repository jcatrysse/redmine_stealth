// Who gets the toggle: the permission "Toggle stealth mode" (global), admins.
// Without it the item is absent and a forged request is refused.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('permissions');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
async function postToggle() {
  const token = await t.page.getAttribute('meta[name=csrf-token]', 'content');
  const r = await t.page.request.post(t.BASE + '/stealth/toggle', {
    headers: { 'X-CSRF-Token': token || '', 'X-Requested-With': 'XMLHttpRequest', Accept: 'text/javascript' },
  });
  return r.status();
}

for (const login of ['reporter', 'outsider']) {
  await t.login(login);
  await t.go('/projects/e2e-project');
  await t.page.click('#account .dropdown-trigger');
  await t.page.waitForSelector('#account .dropdown-content:not(.hidden)');
  expect(`${login}: menu items`, await t.page.locator('#stealth_toggle').count(), 0);
  await t.shot(`${login}-menu`, `${login} (${login === 'reporter' ? 'member without the permission' : 'no membership'}): no stealth item in the account menu`, { full: false });
  expect(`${login}: POST with a valid CSRF token`, await postToggle(), 403);
  await t.go('/projects/e2e-project');
  expect(`${login}: state after the refused POST`, await t.page.evaluate(() => document.body.classList.contains('stealth_on')), false);
}

await t.anonymous();
await t.go('/projects/e2e-project');
expect('anonymous: menu items', await t.page.locator('#stealth_toggle').count(), 0);
expect('anonymous: POST', await postToggle(), 401);
await t.shot('anonymous', 'Anonymous: no account menu, no toggle; a POST is answered 401');

await t.login('manager');
await t.go('/projects/e2e-project');
await t.page.click('#account .dropdown-trigger');
expect('manager: menu items', await t.page.locator('#stealth_toggle').count(), 1);
await t.shot('manager-menu', 'manager (role with the permission): the toggle is offered', { full: false });

await t.login('admin');
await t.go('/roles');
await t.page.click('text=E2E full');
await t.settle();
const box = t.page.locator('input[type=checkbox][value=toggle_stealth_mode]');
expect('permission checkbox on the role form', await box.count(), 1);
await box.scrollIntoViewIfNeeded();
await t.shot('role-permission', 'Administration > Roles: the "Toggle stealth mode" permission on a role', { full: false });

await t.done();
