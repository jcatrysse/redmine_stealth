# Before: redmine_stealth (alias chain) + redmine_checklists (redmine70-migration)

`core-note-added.png`: adding a note to an issue on Redmine 7.0-stable-GEOxyz with both
plugins installed, before the prepend fix. Every journal save by a user without stealth
mode ended in `SystemStackError (stack level too deep)`:

```
plugins/redmine_stealth/lib/redmine_stealth/journal_stealth_patch.rb:11:in `send_notification_with_stealth'
plugins/redmine_checklists/lib/redmine_checklists/patches/compatibility/journal_patch.rb:39:in `send_notification'
plugins/redmine_stealth/lib/redmine_stealth/journal_stealth_patch.rb:12:in `send_notification_with_stealth'
...
```

After the fix the whole e2e set (smoke, core, ten scenarios) runs with both plugins
installed: 44 screenshots, 0 problems.
