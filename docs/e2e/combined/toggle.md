# toggle

Run 2026-10-07T16:11:10.854Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](toggle-off.png) | manager | `/projects/e2e-project` | Stealth mode off: the normal header colours |
| ![](toggle-menu-off.png) | manager | `/projects/e2e-project` | The account dropdown offers "Enable Stealth Mode" as its first item |
| ![](toggle-menu-on.png) | manager | `/projects/e2e-project` | After the click: black top menu, dark header, the item now reads "Disable Stealth Mode" |
| ![](toggle-persists.png) | manager | `/projects/e2e-project/issues` | Stealth mode is stored on the user: still on after loading another page |
| ![](toggle-off-again.png) | manager | `/projects/e2e-project/issues` | Disabled again: normal header after a reload |
| ![](toggle-admin-menu.png) | admin | `/` | An administrator (no membership needed) also gets the toggle |
