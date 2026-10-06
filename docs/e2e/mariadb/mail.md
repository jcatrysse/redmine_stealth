# mail

Run 2026-10-06T19:51:39.431Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](mail-off-issue.png) | manager | `/issues/8` | Stealth off: new issue "Stealth-off issue 1791316270060", mail sent to reporter@example.net |
| ![](mail-on-issue-note.png) | manager | `/issues/9` | Stealth on: issue "Stealth-on issue 1791316270060" created and a note added, 0 mail(s) written |
| ![](mail-other-user-note.png) | reporter | `/issues/9` | Another user without stealth adds a note to the same issue: mail sent to manager@example.net |
| ![](mail-off-again-note.png) | manager | `/issues/9` | Stealth off again: the next note mails reporter@example.net |
