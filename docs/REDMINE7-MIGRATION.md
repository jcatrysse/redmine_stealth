# Redmine 7 migration: redmine_stealth

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. That includes the plugin's tests on
> PostgreSQL and MariaDB, every function exercised end to end on a real running Redmine in a
> browser (with and without permissions, failure paths included) with screenshots you looked at,
> and an OpenAI review of the diff when OPENAI_API_KEY is set. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_stealth` |
| GEOxyz runs today | `master` |
| Upstream | omegacodepl/redmine_stealth master @ 661a5a6 (2021-11-12) |
| Runs on Redmine 7 as is | NEE (master); JA on `redmine70-migration` |
| Upstream sync | UPSTREAM DOOD |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 1 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `12239d8` |
| Migration session | done 2026-10-06; result below under "Results" |

## Already on this branch

- `eb09ef5` Remove `unloadable`, gone since Rails 7.0
- Migration session 2026-10-06 (one concern per commit, each fix with a test that fails without it):
  - `442d936`, `0b92b51`, `13cbcc7`, `e3b257e`, `44393a0`, `29b01e5` test scripts: 7.0-stable-GEOxyz from the
    GEOxyz fork, MariaDB (`RMP_DB=mariadb`), minitest, other `REDMINE_DIR`, mail-to-file only for the server
    environment, plugin copy refreshed on (re)start
  - `cef1ed9` escape the menu label in the generated JavaScript (+ unit tests, locale key check)
  - `e8c6fe1` tests for the existing behaviour (the plugin had none)
  - `83c0222` **security**: CSRF protection back on the session toggle (b002092 had skipped it)
  - `e1edaf4` translated failure alert instead of the raw key (work list 3)
  - `223fac9` the link sends `toggle=true|false` again (rails-ujs reads `data-params`, not jQuery `.data()`)
  - `fe4d436` drop the `link_to_remote` menu manager patch (loaded on 7, but unused)
  - `294915e` translate the permission label in all 7 locales
  - `e285b2b` workflows run the minitest suite; new manual workflow for 7.0-stable-GEOxyz
  - `b91fd7d` **combination fix**: `send_notification` patches prepended instead of alias-chained (with
    redmine_checklists every journal save raised `SystemStackError`)
  - `4ec9249` README; `df29b58`, `b412c74`, `8a55c19` e2e scenarios and evidence; `abd8751`, `f344eb8` OpenAI review

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Priority items**

1. Decide whether stealth mode also silences Redmine 7 webhooks; implement if yes.
   **Done: not silenced** (no behaviour change; webhooks are integrations, not mail to people). Proven by
   `test_webhooks_are_still_triggered_when_cloaked` and `test/e2e/webhook.mjs`. Recorded under "Open
   questions for Jan".

**Open items from the analysis** (Dutch; where they conflict with a decision or a priority item above, those win)

2. Decide whether Redmine 7 webhooks (#29664) should also be silenced in stealth mode (currently not)
   **Done**: same as 1.
3. Failure alert shows raw key label_failed_to_toggle_stealth_mode (pre-existing)
   **Fixed** in `e1edaf4`: the layout hook passes `l(:failed_to_toggle_stealth_mode)` in the user's language;
   `test/e2e/failure.mjs` shows the alert "Failed to toggle stealth mode." after the session ended in another tab.
4. Toggle now lives inside the account dropdown (hidden until opened); mobile flyout menu not tested
   **Done**: first item of the account dropdown (core places it, `first: true`), visible after one click;
   that is Redmine 7's design for account items, kept. Mobile: Redmine moves (not copies) the account menu
   into the flyout, one `#stealth_toggle`, toggling works (`test/e2e/toggle_mobile.mjs`). The cue on a
   phone is weaker (no top bar, only the darker header), see open questions.

**Checks**

5. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
   **Done**: PostgreSQL 16 and MariaDB 10.11 36 runs, 132 assertions, 0 failures; 5.1-stable (Ruby 3.2.6,
   PostgreSQL) 35 runs, 113 assertions, 0 failures (the webhook test exists only on 7).
6. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).
   **Done**: ten scenarios, see "Inventory of functions" and "Results".

## GEOxyz changes to review or re-apply

These GEOxyz commits are on the branch GEOxyz runs today and therefore on this branch. Review each one against the code it now sits on (upstream merges and Redmine 7 core): drop it if upstream or core now does the same, rewrite it if it is not up to the quality rules below (tests, I18n, security, portability), keep it otherwise. Record the verdict per commit in this file.

| commit | date | subject | verdict |
|---|---|---|---|
| `3b2ed40` | 2026-01-27 | Defect: correct loading order (I18n issue) | **kept**; its leftover raw key `label_failed_to_toggle_stealth_mode` fixed in `e1edaf4` (translated per request) |
| `e62b421` | 2026-01-27 | Add GitHub actions and rspec testing helpers | **rewritten**: scripts take 7.0-stable-GEOxyz and MariaDB (`442d936` ...); workflows ran rspec on a non-existent `spec/`, now minitest, plus a 7.0 GEOxyz workflow, manual only (`e285b2b`) |
| `9c61ff1` | 2026-01-27 | Resolve permissions | **kept**: global permission, menu only with it; tested (functional, integration, `permissions.mjs`); label translated in `294915e` |
| `6fe21eb` | 2026-01-27 | Redmine 5 | **dropped** in `fe4d436`: it moved the `link_to_remote` menu patch to `lib/redmine/menu_manager.rb`, which Zeitwerk loads on 7 and which alias-chains core's MenuItem and `render_single_menu_node` for an option nobody uses |
| `adf7888` | 2026-01-27 | Make compatible with Redmine 5 | **rewritten** in `b91fd7d`: same behaviour, `prepend` instead of the alias chain (loop with redmine_checklists) |
| `b002092` | 2026-01-27 | Added API toggle with JSON / XML output | **kept, security fix** in `83c0222`: the JSON/XML output stays, the `skip_before_action :verify_authenticity_token` is gone (core already skips CSRF for API formats; the skip only opened the session path to CSRF) |
| `e3fdd5c` | 2026-01-27 | Added API toggle | **kept**: `accept_api_auth :toggle`; tested (API key, basic auth, refusals, REST API off) |

## Inventory of functions

| function | how a user reaches it | scenario | screenshots |
|---|---|---|---|
| Toggle stealth mode (desktop) | account dropdown (avatar) > "Enable/Disable Stealth Mode" | `test/e2e/toggle.mjs` | toggle-off, toggle-menu-off, toggle-menu-on, toggle-persists, toggle-off-again, toggle-admin-menu |
| Toggle on a phone | menu button > Profile > "Enable Stealth Mode" | `test/e2e/toggle_mobile.mjs` | toggle_mobile-flyout-off, -flyout-on, -header-on |
| Visual cue (black top bar, dark header) on every page | `view_layouts_base_html_head` / `_body_bottom` hooks | toggle, toggle_mobile, mail | toggle-menu-on, toggle-persists, mail-on-issue-note |
| Permission "Toggle stealth mode" (global), admins always | Administration > Roles | `test/e2e/permissions.mjs` | permissions-role-permission, -manager-menu, -reporter-menu, -outsider-menu, -anonymous |
| Mail suppression for issues and journals of the cloaked user | any issue create / note / edit | `test/e2e/mail.mjs` | mail-off-issue, mail-on-issue-note, mail-other-user-note, mail-off-again-note |
| Webhooks not silenced (decision) | Redmine 7 webhooks | `test/e2e/webhook.mjs` | webhook-webhooks, webhook-issue-created |
| Stealth off at every sign-in | login | `test/e2e/login_decloak.mjs` | login_decloak-before-logout, -after-login |
| REST API `POST /stealth/toggle.json` or `.xml`, optional `toggle=true` / `false` | API key / basic auth | `test/e2e/api.mjs` (calls listed in docs/e2e/api.md) | api-ui-after-api, api-ui-off |
| CSRF protection of the session toggle | forged POST | `test/e2e/csrf.mjs` | csrf-with-token, csrf-without-token |
| Failure alert, translated | toggle after the session ended | `test/e2e/failure.mjs` | failure-after-failure (alert text in docs/e2e/failure.md) |
| Link sends the shown state | two tabs | `test/e2e/two_tabs.mjs` | two_tabs-stale-tab |
| Core flows with the plugin | issue form, note, context menu, refusals | `.codex/e2e/core.mjs`, `smoke.mjs` | core-*, smoke-* |

No settings page, no project module, no rake tasks, no cron, no migrations, no mail handler.

## Results

Measured 2026-10-06 on Redmine 7.0.1 (7.0-stable-GEOxyz @ 8067e23), Rails 8.1.3.1, Ruby 3.3.6.

- **Baseline before changes**: boot, eager load and `zeitwerk:check` OK; plugin tests: none existed (0 runs);
  e2e smoke 10 / core 6 screenshots, 0 problems.
- **Plugin tests** (`./.codex/test_plugin.sh`, `rake redmine:plugins:test`):
  - PostgreSQL 16: 36 runs, 132 assertions, 0 failures, 0 errors, 0 skips
  - MariaDB 10.11: 36 runs, 132 assertions, 0 failures, 0 errors, 0 skips
  - Redmine 5.1-stable, Ruby 3.2.6, PostgreSQL: 35 runs, 113 assertions, 0 failures (5.1 compatible)
- **E2E** (`./.codex/e2e.sh`, production mode, fresh database each): smoke 10 + core 6 + ten scenarios with
  28 screenshots = 44, 0 problems, on PostgreSQL (docs/e2e/) and on MariaDB (docs/e2e/mariadb/, tables and
  three screenshots). All screenshots looked at.
- **Together** with the redmine70-migration branches of redmine_impersonate, redmine_editauthor,
  redmine_inline_edit_issues: tests 34/122 green, e2e 44 shots 0 problems. With redmine_checklists
  (redmine70-migration): **found** `SystemStackError` on every note with the old alias chain
  (docs/e2e/before-checklists/), fixed in `b91fd7d`; afterwards tests 36/132 and e2e 44 shots, 0 problems.
- **Before evidence**: the stale-tab bug (`two_tabs.mjs` against the old stealth.js: `data-params` null, the
  stale "Enable" switched stealth off) and the checklists 500 were captured on Redmine 7. No separate
  Redmine 5.1 screenshots: the 5.1 header differs and the old behaviour is shown by the failing tests/runs.
- **Migrations up/down**: n.v.t. (no migrations).
- **Review**: own adversarial review of the whole diff (found the checklists loop by checking which GEOxyz
  plugins patch `send_notification`); OpenAI review (gpt-5) of `3b2ed40..HEAD`: round 1 one minor finding
  (seed without `require 'socket'`), fixed in `abd8751`; round 2 no findings
  (docs/reviews/openai-2026-10-06-29b01e5.md, -f344eb8.md).

### Findings outside this plugin (not fixed here)
- The shared `start_server.sh` wrote `email_delivery` under `default:` in `config/configuration.yml`, which
  silently broke every mail-counting test (core's too) in the same checkout; fixed in this repo's copy
  (`0b92b51`), the other plugin repos carry the same script.
- Redmine core refuses loopback webhook targets always (`WebhookEndpointValidator`); the e2e listener uses
  the machine's own non-loopback address.

### Not tested (needs real credentials)
- Sign-in through SSO/LDAP/OAuth plugins (e.g. bless-this-redmine-sso): stealth is switched off by the
  `controller_account_success_authentication_after` hook, which only core's AccountController login calls.
  An SSO plugin that logs users in another way leaves stealth mode as it was.
- Real SMTP delivery (mail went to files).

## Open questions for Jan

1. **Webhooks in stealth mode.** Options: (a) leave them firing (built, no behaviour change); (b) suppress
   webhooks triggered by a cloaked user (patch `Webhook.trigger`); (c) a setting. Recommendation: (a).
   Webhooks feed integrations; silencing them would let external systems drift from Redmine, which is a
   data problem, not a courtesy to colleagues.
2. **Scope of the silence.** Only issue creation and issue journals are silenced; wiki edits, news,
   documents, forum messages and attachments still mail (upstream behaviour; the old README suggested
   wiki pages too, the README now says what it does). Options: keep, or extend to `WikiContent`, `News`,
   `Message`, `Document`, `Comment` with the same prepend. Recommendation: keep unless users ask; each
   extra model is one small patch and test.
3. **Cue on phones.** On a phone only the header gets darker (no top bar). Options: keep, or add a
   stronger mobile cue (e.g. a coloured bottom border on `#header`). Recommendation: keep; low use on phones.
4. **Impersonation** (redmine_impersonate): toggling while impersonating sets the impersonated user's
   preference (from the analysis; unchanged). Recommendation: accept, or hide the item while impersonating
   if that confuses admins.

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- Nothing to migrate: the plugin has no tables; the state is the user preference `stealth_mode` (kept).
- Deploy together with the redmine70-migration branch of redmine_checklists only with this branch
  (`b91fd7d`): the old alias chain plus checklists' prepend breaks every issue note with a 500.
- The permission "Toggle stealth mode" is unchanged; nothing to reassign. Roles now show it translated.
- Users who scripted the toggle without a CSRF token over the session (not the API) now get 422; the
  REST API with a key or basic auth is unchanged.

## How to test

This repo already has its own `.codex/` scripts (older variant). Read their headers and use them; check they accept `7.0-stable-GEOxyz` (clone from https://github.com/jcatrysse/redmine.git) and MariaDB. The shared variant from the other plugin repos may replace them if that is simpler.

Then the real Redmine and the browser checks (shared scripts, they use the checkout in `redmine/` or `REDMINE_DIR`):

```sh
./.codex/start_server.sh       # real Redmine (production mode) with this plugin, seeded users and projects
./.codex/e2e.sh                # browser: smoke over the plugin's pages, core issue flows, test/e2e/*.mjs
./.codex/openai_review.sh      # independent OpenAI review of the diff, only when OPENAI_API_KEY is set
```
Write one scenario per function in `test/e2e/<function>.mjs` (example at the top of
`.codex/e2e/lib.mjs`); screenshots and a table per scenario land in `docs/e2e/`. Users:
`admin`, `manager` (every permission), `reporter` (no plugin permissions), `outsider` (no
membership); password `Redmine7Test!`. Needs Node with Playwright and Chromium
(`npm install -g playwright && npx playwright install --with-deps chromium`).

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline, before you change anything**:
   - the plugin's tests on Redmine 7.0-stable-GEOxyz with PostgreSQL and with MariaDB;
   - a real running Redmine with this plugin (`./.codex/start_server.sh`) and the browser run
     (`./.codex/e2e.sh`: smoke over every page the plugin adds, plus the core issue flows).
   Write the numbers here. Something already broken now is a finding, not your regression.
3. **Inventory of functions**: list every function of the plugin in this file, in a table
   "function | how a user reaches it | scenario | screenshot". Take them from the README,
   `init.rb` (permissions, menus, settings, project modules), routes, hooks and view
   overrides, macros, mail handling, API endpoints, rake tasks and cron jobs. This table is the
   coverage list for step 8; a function that is not in it will not be tested.
4. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
5. **Work list**: then the numbered list, in order. One concern per commit.
6. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **End to end, visually, every function**: on the real Redmine from `start_server.sh`
   (production mode, the way GEOxyz runs it), write one scenario per function in
   `test/e2e/<function>.mjs` with `.codex/e2e/lib.mjs` and run them with `./.codex/e2e.sh`.
   - Each function as the users that matter: `admin`, `manager` (every permission, the
     plugin's included), `reporter` (member without the plugin's permissions), `outsider`
     (no membership, private project must stay invisible).
   - The failure paths too: setting off, permission absent, empty state, invalid input, the
     value that used to raise. A refusal that is shown is evidence as much as a success.
   - One screenshot per function and per path, with a caption saying what it proves. Open
     every screenshot and look at it: a picture nobody looked at proves nothing. Commit them
     in `docs/e2e/` and list them in the inventory table.
   - Functions without a page (mail in and out, REST API, rake tasks, cron, webhooks): exercise
     them against the same running instance (mails land in `redmine/tmp/mails`, `t.mails()`
     reads them; API through `t.page.request`) and record command and result.
   - Before pictures where behaviour or layout changes: the branch GEOxyz runs today, on
     Redmine 5.1, same scenarios, `RMP_E2E_OUT=docs/e2e/before`.
   - Run the whole e2e set once on MariaDB as well (`RMP_DB=mariadb`, then `start_server.sh --reset`).
9. **Independent review**: first your own, adversarial: re-read the whole diff as if someone
   else wrote it and you are paid to reject it. Then, **when `OPENAI_API_KEY` is set in the
   session**, `./.codex/openai_review.sh`: it sends the diff of this branch to an OpenAI model
   and writes `docs/reviews/openai-<date>-<sha>.md`. Every finding gets a `Resolution:` line
   there (fixed in <commit>, with a test, or why not). Fix, re-run the tests and the e2e set,
   and run the review again until it has nothing new that you accept. Without the key: write
   "OpenAI review: skipped, no OPENAI_API_KEY" in the report; never send code anywhere else.
10. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
    settings, cron, files, removed features) goes into the section "After the upgrade".
11. **Finish**: update "Status", the inventory and the work list in this file, push
    `redmine70-migration`, and report: what changed, test numbers on both databases, e2e
    numbers (scenarios, screenshots, problems), the review result, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service (the OpenAI review of the code diff is the
  one exception Jan approved, and only when the key is present);
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint, browser check or review as passed without having seen
  it. Quote the summary lines; list the screenshots. "Should work" is not a result, and a green
  test suite is not proof that a feature works in the browser.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module, sudo mode
  (on by default: `t.sudo()` in a scenario). The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why). Push after every
  commit, together with the updated status in this file: a cloud session can stop at a usage
  limit, and work that is not pushed is lost with its container.
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every function in the inventory exercised end to end on a real running Redmine, with and
  without permissions and on its failure paths; `./.codex/e2e.sh` green; screenshots looked at,
  committed in `docs/e2e/` and listed.
- Review done: your own, and the OpenAI review when the key is present, every finding resolved
  in `docs/reviews/`.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_stealth
- Gebruikte branch: master @ 3b2ed40 (2026-01-27) - plugin id redmine_stealth, versie 0.8.0
- Upstream: omegacodepl/redmine_stealth (geverifieerd via de fork-pagina van jcatrysse/redmine_stealth) - upstream HEAD master @ 661a5a6 (2021-11-12, "v0.7"), enige branch
- Fork t.o.v. upstream: 7 eigen commits (API-toggle JSON/XML, Redmine 5, permissies, rspec-helpers, laadvolgorde), 0 upstream-commits ontbreken
- Andere relevante branches: geen.
- Geen Gemfile, geen migraties, geen tests (wel GitHub-workflows rspec-51/60, maar geen spec/-map).

## 1. Werkt out of the box op Redmine 7?   NEE
- `FAIL boot`: `undefined local variable or method 'unloadable' for module RedmineStealth::IssueStealthPatch` - lib/redmine_stealth/issue_stealth_patch.rb:4 (zelfde in journal_stealth_patch.rb:4 en app/controllers/stealth_controller.rb:3). Redmine start niet.

## 2. Upstream sync?   UPSTREAM DOOD
- Upstream sinds 2021 stil, fork bevat alles.

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 1
- Blokkers:
  - 3x `unloadable` -> verwijderd - gefixt in eb09ef5.
- Header-redesign (#43937 navigatiebalk, #31353 user-menu), live geverifieerd na fix:
  - Het menu-item (`menu :account_menu, first: true`) staat nu als eerste item in de nieuwe account-dropdown (`#account .dropdown-content`), dus pas zichtbaar na openklappen.
  - Klik (rails-ujs, data-remote POST /stealth/toggle) werkt: label wisselt "Enable/Disable Stealth Mode", `body.stealth_on`, `#top-menu` wordt zwart en `#header` #2C4056 = de zichtbare aanwijzing blijft werken; status blijft na herladen.
  - API: POST /stealth/toggle.json en .xml met API-key -> 200 `{"is_cloaked":...}`.
  - Mails: via runner getest - niet gecloakt 2 mails bij nieuw issue + 2 bij journal, gecloakt 0 + 0.
- Stille breuken:
  - Webhooks (nieuw in 7.0, #29664) gaan niet via `send_notification` en worden dus niet onderdrukt; stealth dekt enkel mails van issues/journals (zoals voorheen).
  - `data-failure-message` bevat de ruwe key `label_failed_to_toggle_stealth_mode`; bij een fout toont de alert de key (pre-existing GEOxyz-wijziging).
  - lib/redmine/menu_manager.rb (oude `link_to_remote`-patch) is dode code: Zeitwerk negeert het want `Redmine::MenuManager` bestaat al. Eager load OK.
  - Mobiele flyout-menu (kopie van het account-menu) niet getest.
- Conflicten: met redmine_impersonate zie dat rapport (toggle tijdens impersonatie zet de voorkeur van de geïmpersoneerde gebruiker). Samen geïnstalleerd met impersonate/editauthor/inline_edit: harness groen (results/1006-100854-...).
- Overlap met Redmine 7 core: geen (core kan mails per gebruiker/gebeurtenis beperken, niet tijdelijk alles uitzetten).
- Open werk voor ansif:
  - Beslissen of webhooks ook stil moeten in stealth-modus.
  - Vertaling van de failure-message herstellen (key -> `l(...)` bij render).

## Branch redmine70-migration
- Basis: origin/master @ 3b2ed40
- Commits: eb09ef5 Remove `unloadable`, gone since Rails 7.0
- Eindresultaat harness (results/1006-094052-s3-redmine_stealth_redmine70-migration): OK bundle, OK boot 0.8.0, OK eager load, OK migraties dev+test, OK smoke 60/60
- Rollback migraties: n.v.t.

