# csrf

Run 2026-10-07T16:09:50.317Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](csrf-with-token.png) | manager | `/projects/e2e-project` | POST /stealth/toggle with the page's CSRF token: 200, stealth on |
| ![](csrf-without-token.png) | manager | `/projects/e2e-project` | The same POST without a token is refused (422) and Redmine ends the session; stealth stayed off |
