# MariaDB run

The same e2e set (smoke, core, the ten scenarios in test/e2e) on MariaDB 10.11
(`RMP_DB=mariadb ./.codex/test_setup.sh`, `./.codex/start_server.sh --reset`):
44 screenshots, 0 problems. The tables are the run's own; to keep the repository
small only three screenshots are kept here (toggle-menu-on, mail-on-issue-note,
webhook-issue-created), the full PostgreSQL set is in docs/e2e/.
