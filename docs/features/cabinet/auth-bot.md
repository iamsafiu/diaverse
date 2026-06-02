# Diaverse Auth Bot

[Back to Docs](../../README.md)

## Назначение

`diaverse-auth-bot` - отдельный дочерний репозиторий workspace для Telegram-бота авторизации Diaverse. Локально он лежит в `C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot`.

Бот является тонким transport adapter:

- принимает `/start login_<token>` для browser login flow;
- принимает mobile deep links с префиксами `auth_` и `authdev_`;
- отправляет signed internal requests в `diaverseapi`;
- показывает пользователю короткий success/failure ответ в Telegram;
- не владеет базой данных, Redis, cookies, пользователями или выдачей ролей.

## Ownership

| Область | Владелец |
| --- | --- |
| Telegram polling runtime | `diaverse-auth-bot` |
| Bot token and bot profile separation | `diaverse-auth-bot` runtime config |
| Login-session state, TTL, polling and exchange | `diaverseapi/app/security` |
| User provisioning and Telegram identity persistence | `diaverseapi/app/security` |
| Browser cookies and session exchange | `diaverseapi/app/security` |
| RBAC default role assignment | `diaverseapi/app/cabinet/rbac` through auth flow |
| Broadcast recipient truth | `diaverseapi`, not the auth bot |

## Runtime Contract

```text
Browser / diaweb
    |
    v
diaverseapi creates login session
    |
    v
Telegram deep link: /start login_<token>
    |
    v
diaverse-auth-bot
    |
    v
POST /v1/auth/internal/login-sessions/approve
    |
    v
diaverseapi resolves Telegram identity and approves session
    |
    v
Browser polls status and exchanges approved session for cookies
```

Mobile linking uses the same runtime boundary, but calls `POST /v1/auth/internal/link-mobile/approve` with the mobile deeplink payload.

## Important Source Files

| Repo | Path | Purpose |
| --- | --- | --- |
| `diaverse-auth-bot` | `README.md` | Repo-local overview, env names, quick start |
| `diaverse-auth-bot` | `app/handlers/login.py` | `/start` command routing |
| `diaverse-auth-bot` | `app/services/login_flow.py` | Browser login token flow |
| `diaverse-auth-bot` | `app/services/link_mobile_flow.py` | Mobile Telegram linking flow |
| `diaverse-auth-bot` | `app/clients/backend.py` | Signed internal backend calls |
| `diaverseapi` | `app/security/api.py` | Internal approve endpoints |
| `diaverseapi` | `app/security/login_sessions.py` | Redis-backed login-session state |
| `diaverseapi` | `app/security/cabinet_auth.py` | Telegram identity resolution and user provisioning |
| `diaverseapi` | `app/security/models.py` | `users.tg_user_id` source of truth |
| `diaverseapi` | `app/internal/models.py` | `bot_users.platform_id` and `tg_username` |

## Deployment Notes

The deployed service is expected to run on the foreign bot host as Docker containers. Known deployment directories are:

- `/srv/diaverse-auth-bot`
- `/srv/diaverse-auth-bot-dev`

Known container names are:

- `diaverse-auth-bot`
- `diaverse-auth-bot-dev`

Do not publish or document raw `.env` values. The required environment names are documented in the repo README; token, secret, backend URL, and key material must stay out of public docs and daily public digests.

## Broadcast Implications

Because the auth bot is stateless, it cannot answer "who has authorized before" from its own local state. For notification or broadcast features:

- use durable Telegram identity data in `diaverseapi`;
- treat `users.tg_user_id IS NOT NULL` as the broad linked Telegram audience;
- use account event logs or a new contact/audience table if the exact historical "approved through auth bot" audience is required;
- send through an idempotent campaign/outbox with retry, rate limit handling, and failure tracking;
- keep Bot API tokens in runtime config, not in docs or scripts.

The Telegram Bot API can only message users who have started the bot and have not blocked it. Delivery failures should be persisted so the audience can be cleaned or segmented later.

The current staff copywriting broadcast workflow is documented separately: [Auth Bot Broadcasts In Copywriting](../copywriting/auth-bot-broadcasts.md).

## Local Commands

```powershell
# Inspect the cloned auth bot repo
cd C:\Users\Indigo\Desktop\diaverse\diaverse-auth-bot
git status --short
git branch --show-current

# Run tests if dependencies are installed
python -m pytest
```
