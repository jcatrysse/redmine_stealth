// The session toggle needs Redmine's CSRF token: a cross-site POST cannot
// switch a user's stealth mode on (the API, with its key, needs none).
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('csrf');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
const post = headers => t.page.request.post(t.BASE + '/stealth/toggle',
  { headers: { 'X-Requested-With': 'XMLHttpRequest', Accept: 'text/javascript', ...headers }, form: { toggle: 'true' } });

await t.login('manager');
await t.go('/projects/e2e-project');
const token = await t.page.getAttribute('meta[name=csrf-token]', 'content');
let r = await post({ 'X-CSRF-Token': token });
expect('with the page token', r.status(), 200);
await t.go('/projects/e2e-project');
expect('state after the valid request', await t.page.evaluate(() => document.body.classList.contains('stealth_on')), true);
await t.shot('with-token', 'POST /stealth/toggle with the page\'s CSRF token: 200, stealth on');
r = await t.page.request.post(t.BASE + '/stealth/toggle', { headers: { 'X-CSRF-Token': token, 'X-Requested-With': 'XMLHttpRequest', Accept: 'text/javascript' }, form: { toggle: 'false' } });
expect('switch off again', r.status(), 200);

r = await post({ Origin: 'https://evil.example', Referer: 'https://evil.example/' });
expect('without a token (cross-site form)', r.status(), 422);
await t.go('/projects/e2e-project');
await t.shot('without-token', 'The same POST without a token is refused (422) and Redmine ends the session; stealth stayed off');
await t.login('manager');
await t.go('/projects/e2e-project');
expect('state after the forged request', await t.page.evaluate(() => document.body.classList.contains('stealth_off')), true);
await t.done();
