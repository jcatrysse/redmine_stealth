// Redmine 7 webhooks are not silenced by stealth mode (decision recorded in
// docs/REDMINE7-MIGRATION.md): a cloaked user's new issue sends no mail but
// does reach the webhook. The seed (test/e2e/seed.rb) registers a hook owned by
// manager on e2e-project to port 3999 of this machine; this script listens there.
import { e2e } from '../../.codex/e2e/lib.mjs';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const t = await e2e('webhook');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const received = [];
const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', c => { body += c; });
  req.on('end', () => { received.push(body); res.writeHead(204); res.end(); });
}).listen(3999, '0.0.0.0');
const hookUrl = fs.readFileSync(path.join(process.env.REDMINE_DIR || 'redmine', 'tmp', 'e2e-webhook-url.txt'), 'utf8').trim();

await t.login('manager');
await t.go('/webhooks');
expect('webhook listed', await t.page.locator(`text=${hookUrl}`).count() > 0, true);
await t.shot('webhooks', `My webhooks: the seeded hook to ${hookUrl}, issue created/updated on E2E project`);

await t.go('/projects/e2e-project');
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 });
t.check('enable');

const subject = `Webhook while stealthy ${Date.now()}`;
const since = Date.now();
await t.go('/projects/e2e-project/issues/new');
await t.page.fill('#issue_subject', subject);
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('create issue');
for (let i = 0; i < 30 && !received.some(b => b.includes(subject)); i++) await sleep(500);
const hits = received.filter(b => b.includes(subject)).map(b => JSON.parse(b).type);
const mails = t.mails(since).filter(m => m.body.includes(subject)).length;
expect('webhook payloads for the new issue', hits.includes('issue.created'), true);
expect('mails for the new issue', mails, 0);
await t.shot('issue-created', `Stealth on: "${subject}" created; webhook received ${JSON.stringify(hits)}, ${mails} mail(s)`);

await t.go('/projects/e2e-project');
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 });
t.check('disable');
server.close();
await t.done();
