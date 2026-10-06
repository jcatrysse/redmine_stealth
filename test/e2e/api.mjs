// REST API: POST /stealth/toggle.json|.xml with an API key or basic auth,
// optional toggle=true|false. The session cookie alone does not authenticate
// an API call.
import { e2e } from '../../.codex/e2e/lib.mjs';
import fs from 'node:fs';

const t = await e2e('api');
const expect = (what, got, want) => { if (JSON.stringify(got) !== JSON.stringify(want)) t.problems.push(`${what}: got ${JSON.stringify(got)}, expected ${JSON.stringify(want)}`); };
const pw = process.env.RMP_USER_PASSWORD || process.env.RMP_ADMIN_PASSWORD || 'Redmine7Test!';
const basic = login => ({ Authorization: 'Basic ' + Buffer.from(`${login}:${pw}`).toString('base64') });
const results = [];
async function call(label, url, headers, form) {
  const r = await t.page.request.post(t.BASE + url, { headers, form, maxRedirects: 0 });
  const body = (await r.text()).trim();
  results.push(`${label}: POST ${url}${form ? ' ' + new URLSearchParams(form) : ''} -> ${r.status()} ${body.slice(0, 80)}`);
  return { status: r.status(), body };
}

// sign in first: signing in switches stealth mode off
await t.login('manager');
await t.go('/projects/e2e-project');
let r = await call('manager, basic auth', '/stealth/toggle.json', basic('manager'), { toggle: 'true' });
expect('JSON enable', [r.status, r.body], [200, '{"is_cloaked":true}']);
await t.go('/projects/e2e-project');
expect('UI after the API enabled stealth', await t.page.evaluate(() => document.body.classList.contains('stealth_on')), true);
await t.shot('ui-after-api', 'After POST /stealth/toggle.json toggle=true the manager\'s pages show stealth on');

await t.go('/my/api_key');
await t.sudo();
const key = (await t.page.locator('#content pre, #content code').first().textContent().catch(() => '')).trim();
expect('API key shown', key.length > 0, true);
await t.anonymous();
r = await call('manager, API key', '/stealth/toggle.xml', { 'X-Redmine-API-Key': key }, { toggle: 'false' });
expect('XML disable', r.status, 200);
expect('XML body', /<is_cloaked[^>]*>false<\/is_cloaked>/.test(r.body), true);
r = await call('manager, API key, no toggle param', '/stealth/toggle.json', { 'X-Redmine-API-Key': key });
expect('JSON flip', [r.status, r.body], [200, '{"is_cloaked":true}']);
r = await call('manager, API key', '/stealth/toggle.json', { 'X-Redmine-API-Key': key }, { toggle: 'false' });
expect('JSON disable', [r.status, r.body], [200, '{"is_cloaked":false}']);

r = await call('reporter (no permission), basic auth', '/stealth/toggle.json', basic('reporter'), { toggle: 'true' });
expect('reporter refused', r.status, 403);
r = await call('outsider, basic auth', '/stealth/toggle.json', basic('outsider'), { toggle: 'true' });
expect('outsider refused', r.status, 403);
r = await call('no credentials', '/stealth/toggle.json', {}, { toggle: 'true' });
expect('anonymous refused', r.status, 401);
r = await call('wrong API key', '/stealth/toggle.json', { 'X-Redmine-API-Key': 'not-a-key' }, { toggle: 'true' });
expect('wrong key refused', r.status, 401);

await t.login('manager');
await t.go('/projects/e2e-project');
r = await call('manager session cookie only (no key)', '/stealth/toggle.json', {}, { toggle: 'true' });
expect('session alone is no API auth', r.status, 401);
await t.go('/projects/e2e-project');
expect('UI still off', await t.page.evaluate(() => document.body.classList.contains('stealth_off')), true);
await t.shot('ui-off', 'After the API calls (last one toggle=false; refused calls changed nothing) stealth is off');

console.log(results.join('\n'));
await t.done();
fs.appendFileSync(`${process.env.RMP_E2E_OUT || 'docs/e2e'}/api.md`, '\n## Calls\n\n```\n' + results.join('\n') + '\n```\n');
