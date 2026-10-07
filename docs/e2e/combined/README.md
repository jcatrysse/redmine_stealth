# Run with 21 other GEOxyz plugins (2026-10-07, PostgreSQL 16)

redmine_stealth plus the `redmine70-migration` branches of redmine_impersonate, editauthor,
inline_edit_issues, custom_workflows, issue_templates, mail_digest, issue_view_columns,
view_customize, depending_custom_fields, parent_child_filters, issue_field_visibility,
extended_api, subtask, itil_priority, tint_issues, description_macros, wiki_extensions, drawio,
project_workflows, reporter_dashboards and checklists, on Redmine 7.0-stable-GEOxyz.

All twelve stealth scenarios and core: 0 problems (tables here; the impersonation screenshots,
which only exist with redmine_impersonate installed, are kept). smoke: Project > Settings answers
500, caused by redmine_mail_digest, redmine_itil_priority and redmine_depending_custom_fields,
which still alias_method-chain ProjectsHelper#project_settings_tabs under checklists' prepend.
Without those three, Settings, the issue list and an issue page answer 200 as admin and manager.
