// Mail suppression: issues and notes of a cloaked user send no mail; the same
// actions without stealth, or by another user, do. Mail is written to
// redmine/tmp/mails by the e2e server (one file per recipient).
import { e2e } from '../../.codex/e2e/lib.mjs';

const t = await e2e('mail');
const expect = (what, got, want) => { if (got !== want) t.problems.push(`${what}: got ${got}, expected ${want}`); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const mailsAbout = async (since, text) => { await sleep(4000); return t.mails(since).filter(m => m.body.includes(text)).map(m => m.to); };
const run = Date.now();

async function setStealth(on) {
  await t.go('/projects/e2e-project');
  const now = await t.page.evaluate(() => document.body.classList.contains('stealth_on'));
  if (now === on) return;
  await t.page.click('#account .dropdown-trigger');
  await t.page.click('#stealth_toggle');
  await t.page.waitForFunction(want => document.body.classList.contains(want), on ? 'stealth_on' : 'stealth_off', { timeout: 10000 });
  t.check('toggle');
}
async function createIssue(subject) {
  await t.go('/projects/e2e-project/issues/new');
  await t.page.fill('#issue_subject', subject);
  await t.page.click('#issue-form input[name=commit]');
  await t.settle();
  t.check('create issue');
  return new URL(t.page.url()).pathname;
}
async function addNote(path, note) {
  await t.go(`${path}/edit`);
  await t.page.fill('#issue_notes', note);
  await t.page.click('#issue-form input[name=commit]');
  await t.settle();
  t.check('add note');
}

await t.login('manager');
await setStealth(false);
let since = Date.now();
const s1 = `Stealth-off issue ${run}`;
await createIssue(s1);
let to = await mailsAbout(since, s1);
expect('stealth off, new issue: mail to reporter', to.some(f => f.startsWith('reporter@')), true);
await t.shot('off-issue', `Stealth off: new issue "${s1}", mail sent to ${to.join(', ') || 'nobody'}`);

await setStealth(true);
since = Date.now();
const s2 = `Stealth-on issue ${run}`;
const p2 = await createIssue(s2);
await addNote(p2, `Silent note ${run}`);
to = await mailsAbout(since, s2);
expect('stealth on, new issue and note: mails', to.length, 0);
await t.shot('on-issue-note', `Stealth on: issue "${s2}" created and a note added, ${to.length} mail(s) written`);

await t.login('reporter');
since = Date.now();
await addNote(p2, `Reporter note ${run}`);
to = await mailsAbout(since, s2);
expect('reporter (not cloaked) adds a note: mail to manager', to.some(f => f.startsWith('manager@')), true);
await t.shot('other-user-note', `Another user without stealth adds a note to the same issue: mail sent to ${to.join(', ') || 'nobody'}`);

await t.login('manager');
await setStealth(false);
since = Date.now();
await addNote(p2, `Audible note ${run}`);
to = await mailsAbout(since, `Audible note ${run}`);
expect('stealth off again, note: mail to reporter', to.some(f => f.startsWith('reporter@')), true);
await t.shot('off-again-note', `Stealth off again: the next note mails ${to.join(', ') || 'nobody'}`);
await t.done();
