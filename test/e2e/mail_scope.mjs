// Decided by Jan 2026-10-07 (q2): stealth mode silences issue mails only. A wiki
// edit by a cloaked user still sends mail; an issue note in the same state does not.
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('mail_scope');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const mailsAbout = async (since, text) => { await sleep(4000); return t.mails(since).filter(m => m.body.includes(text)).map(m => m.to); };
const run = Date.now();
const SUBJECT = "Subject: [E2E project] 'Wiki' wiki page has been updated";
const wikiMailsTo = async login => { await sleep(4000); return t.mails(0).filter(m => m.to.startsWith(login + '@')).reduce((n, m) => n + m.body.split(SUBJECT).length - 1, 0); };

await t.login('manager');
await t.go('/projects/e2e-project');
if (!(await t.page.evaluate(() => document.body.classList.contains('stealth_on')))) {
  await t.page.click('#account .dropdown-trigger');
  await t.page.click('#stealth_toggle');
  await t.page.waitForFunction(() => document.body.classList.contains('stealth_on'), null, { timeout: 10000 });
  t.check('enable');
}

const before = await wikiMailsTo('reporter');
let since = Date.now();
const wikiText = `Wiki edit while stealthy ${run}`;
await t.go('/projects/e2e-project/wiki/Wiki/edit');
await t.page.fill('#content_text', `# Wiki\n\n${wikiText}`);
await t.page.click('#wiki_form input[name=commit]');
await t.settle();
t.check('save wiki');
const added = (await wikiMailsTo('reporter')) - before;
expect('cloaked wiki edit: new wiki mails to reporter', added, 1);
await t.shot('wiki-mails', `Stealth on, wiki page edited: ${added} new "'Wiki' wiki page has been updated" mail(s) to reporter (decided: wiki stays audible)`);

since = Date.now();
const note = `Issue note while stealthy ${run}`;
await t.go('/issues/1/edit');
await t.page.fill('#issue_notes', note);
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('add note');
let to = await mailsAbout(since, note);
expect('cloaked issue note: mails', to.length, 0);
await t.shot('issue-silent', `Same session, stealth on, issue note added: ${to.length} mail(s)`);

await t.go('/projects/e2e-project');
await t.page.click('#account .dropdown-trigger');
await t.page.click('#stealth_toggle');
await t.page.waitForFunction(() => document.body.classList.contains('stealth_off'), null, { timeout: 10000 });
t.check('disable');
await t.done();
