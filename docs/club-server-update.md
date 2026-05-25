# РћР±РЅРѕРІР»РµРЅРёРµ СЃРµСЂРІРµСЂРѕРІ РґР»СЏ РєР»СѓР±РЅРѕР№ С„РёС‡Рё

Р”РѕРєСѓРјРµРЅС‚ РѕРїРёСЃС‹РІР°РµС‚ deploy РЅРѕРІРѕР№ РєР»СѓР±РЅРѕР№ С„РёС‡Рё РЅР° С‚РµРєСѓС‰РёРµ СЃРµСЂРІРµСЂС‹ Diaverse: РєР»СѓР±РЅР°СЏ Р°РґРјРёРЅРєР°, `clubbot`, РіРµРЅРµСЂР°С†РёСЏ AI-РєР°СЂС‚РёРЅРѕРє Р»РёРґРµСЂР±РѕСЂРґР° РІ `aibot` Рё РїСѓР±Р»РёРєР°С†РёСЏ Р»РёРґРµСЂР±РѕСЂРґР° С‡РµСЂРµР· СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ Premium `copywriting-userbot` РІ Telegram topic.

Р‘Р°Р·РѕРІС‹Р№ РїСЂРѕРґСѓРєС‚РѕРІС‹Р№ runbook: [club.md](club.md).

## Р§С‚Рѕ Р Р°Р·РІРѕСЂР°С‡РёРІР°РµРј

РќРѕРІР°СЏ СЃС…РµРјР°:

```text
diaweb /staff/club
  -> diaverseapi /v1/admin/club
  -> ClubLeaderboardSnapshot РёР· Р‘Р”
  -> signed HMAC request
  -> aibot /internal/club/leaderboards/*
  -> copywriting-worker РіРµРЅРµСЂРёСЂСѓРµС‚ image asset
  -> copywriting-userbot РїСѓР±Р»РёРєСѓРµС‚ РІ Telegram topic
```

`clubbot` РѕСЃС‚Р°РµС‚СЃСЏ РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РґРµР№СЃС‚РІРёР№: join requests, invite links, verification events, outbox-РєРѕРјР°РЅРґС‹, Р±СѓРґСѓС‰РёРµ removals. РљРѕРЅС‚РµРЅС‚ Р»РёРґРµСЂР±РѕСЂРґР° РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РїСѓР±Р»РёРєСѓРµС‚ userbot, РЅРµ club bot.

Р’Р°Р¶РЅРѕ: РІСЃРµ Telegram runtimes РґРѕР»Р¶РЅС‹ СЂР°Р±РѕС‚Р°С‚СЊ РЅР° Р·Р°СЂСѓР±РµР¶РЅРѕРј bot-СЃРµСЂРІРµСЂРµ. `5.42.116.157` С…СЂР°РЅРёС‚ backend state Рё internal API, РЅРѕ РЅРµ Р·Р°РїСѓСЃРєР°РµС‚ `clubbot` polling/webhook Рё РЅРµ СЏРІР»СЏРµС‚СЃСЏ РјРµСЃС‚РѕРј РІС‹РїРѕР»РЅРµРЅРёСЏ Telegram-Р±РѕС‚РѕРІ.

РЎС‚Р°С‚СѓСЃС‹ СЂР°Р·РґРµР»РµРЅС‹:

```text
image_status: pending | generating | ready | failed
publish_status: not_requested | queued | publishing | published | failed
```

## РўРµРєСѓС‰Р°СЏ РљР°СЂС‚Р° РЎРµСЂРІРµСЂРѕРІ

РџСЂРѕРІРµСЂРµРЅРѕ С‡РµСЂРµР· SSH 2026-05-19.

| IP | Hostname | РћРЎ | Р РѕР»СЊ | РћСЃРЅРѕРІРЅС‹Рµ РїСѓС‚Рё |
| --- | --- | --- | --- | --- |
| `5.42.116.157` | `msk-1-vm-r93x` | Debian 12 | `diaverseapi`, `diaweb`, Postgres, Redis, Traefik, GitLab | `/home/config`, `/home/diaverse`, `/home/diaweb` |
| `72.56.108.222` | `discontent` | Ubuntu 24.04 | `aibot` copywriting API/worker/userbot/Postgres, С†РµР»РµРІРѕР№ bot-СЃРµСЂРІРµСЂ РґР»СЏ `clubbot` runtime | `/srv/aibot` |

РљРѕРЅС‚РµР№РЅРµСЂС‹ РЅР° `5.42.116.157`:

```text
diaverse-api-1
diaverse-worker-1
diaverse-scheduler-1
diaverse-postgresql-1
diaverse-redis-1
diaverse_traefik
diaweb-dev
gitlab
```

РљРѕРЅС‚РµР№РЅРµСЂС‹ РЅР° `72.56.108.222`:

```text
copywriting-api
copywriting-worker
copywriting-userbot
copywriting-clubbot
copywriting-postgres
```

## Р’Р°Р¶РЅС‹Рµ Р‘Р»РѕРєРµСЂС‹ РџРµСЂРµРґ РћР±РЅРѕРІР»РµРЅРёРµРј

РќР° `5.42.116.157` backend source РЅР°С…РѕРґРёС‚СЃСЏ РІ `/home/diaverse`, РЅРѕ РѕРЅ РЅРµ С‡РёСЃС‚С‹Р№:

```text
/home/diaverse
branch: fix/pets-skins
state: very large dirty worktree
```

РќРµР»СЊР·СЏ РїСЂРѕСЃС‚Рѕ РІС‹РїРѕР»РЅРёС‚СЊ `git checkout dev` РёР»Рё `git pull`: СЌС‚Рѕ СЃРјРµС€Р°РµС‚ РєР»СѓР±РЅСѓСЋ С„РёС‡Сѓ СЃ С‡СѓР¶РѕР№ РЅРµР·Р°РєРѕРјРјРёС‡РµРЅРЅРѕР№ СЂР°Р±РѕС‚РѕР№ Рё РјРѕР¶РµС‚ СѓРґР°Р»РёС‚СЊ/РёСЃРїРѕСЂС‚РёС‚СЊ Р»РѕРєР°Р»СЊРЅС‹Рµ РёР·РјРµРЅРµРЅРёСЏ.

РџРµСЂРµРґ backend deploy РЅСѓР¶РЅРѕ РІС‹Р±СЂР°С‚СЊ РѕРґРёРЅ РёР· РІР°СЂРёР°РЅС‚РѕРІ:

1. Р’Р»Р°РґРµР»РµС† С‚РµРєСѓС‰РёС… РёР·РјРµРЅРµРЅРёР№ РІ `/home/diaverse` РєРѕРјРјРёС‚РёС‚/СЃС‚РµС€РёС‚/РІС‹РЅРѕСЃРёС‚ РёС…, РїРѕСЃР»Рµ С‡РµРіРѕ repo РјРѕР¶РЅРѕ РїРµСЂРµРєР»СЋС‡РёС‚СЊ РЅР° `dev`.
2. РџРѕРґРЅСЏС‚СЊ РѕС‚РґРµР»СЊРЅС‹Р№ clean checkout РґР»СЏ deploy Рё Р°РєРєСѓСЂР°С‚РЅРѕ РїРµСЂРµРІРµСЃС‚Рё volume paths РІ `/home/config/docker-compose.yml` РЅР° РЅРѕРІС‹Р№ РїСѓС‚СЊ.
3. РќРµ РѕР±РЅРѕРІР»СЏС‚СЊ backend РґРѕ СЂСѓС‡РЅРѕРіРѕ СЂРµС€РµРЅРёСЏ РїРѕ dirty worktree.

Р РµРєРѕРјРµРЅРґСѓРµРјС‹Р№ РІР°СЂРёР°РЅС‚: СЃРЅР°С‡Р°Р»Р° РїСЂРёРІРµСЃС‚Рё `/home/diaverse` Рє С‡РёСЃС‚РѕРјСѓ СЃРѕСЃС‚РѕСЏРЅРёСЋ Рё С‚РѕР»СЊРєРѕ РїРѕС‚РѕРј РѕР±РЅРѕРІР»СЏС‚СЊ `dev`.

РќР° `72.56.108.222` `/srv/aibot` Р±С‹Р» РЅР° СЃС‚Р°СЂРѕРј `dev` Рё РЅРµ СЃРѕРґРµСЂР¶Р°Р» РЅРѕРІС‹С… club asset С„Р°Р№Р»РѕРІ. РўР°Рј РµСЃС‚СЊ untracked `.env.production`; СЌС‚Рѕ РЅРѕСЂРјР°Р»СЊРЅРѕ, РЅРµ СѓРґР°Р»СЏС‚СЊ.

РќР° `5.42.116.157` `/home/diaweb` Р±С‹Р» РЅР° СЃС‚Р°СЂРѕРј `dev` Рё РёРјРµР» untracked `docker-compose.dev-traefik.yml`; СЌС‚Рѕ Р»РѕРєР°Р»СЊРЅС‹Р№ deploy-compose, РЅРµ СѓРґР°Р»СЏС‚СЊ.

## Р¦РµР»РµРІС‹Рµ РљРѕРјРјРёС‚С‹

РќР° РјРѕРјРµРЅС‚ РїРѕРґРіРѕС‚РѕРІРєРё РґРѕРєСѓРјРµРЅС‚Р° Р°РєС‚СѓР°Р»СЊРЅС‹Рµ `dev` head РїРѕСЃР»Рµ merge:

```text
aibot:       d8da659 Merge branch 'feature/club-subscription-marathon' into dev
diaverseapi: 32ab740c Merge branch 'feature/club-subscription-marathon' into dev
diaweb:      3a2a6f2 Merge branch 'feature/club-subscription-marathon' into dev
```

РџРѕСЃР»Рµ РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРµСЂРІРµСЂС‹ РґРѕР»Р¶РЅС‹ Р±С‹С‚СЊ РЅРµ РЅРёР¶Рµ СЌС‚РёС… РєРѕРјРјРёС‚РѕРІ.

## Env: diaverseapi РќР° `5.42.116.157`

Р¤Р°Р№Р»: `/home/config/.env`.

Р”РѕР±Р°РІРёС‚СЊ/РїСЂРѕРІРµСЂРёС‚СЊ:

```env
CLUB_ACTIVE_PROGRAM_CODE=main

CLUBBOT_INTERNAL_SECRET=<same-as-clubbot-CLUBBOT_BACKEND_SECRET>
CLUBBOT_SIGNATURE_TOLERANCE_SECONDS=300

CLUB_TG_OUTBOX_BATCH_SIZE=50
CLUB_TG_OUTBOX_MAX_ATTEMPTS=5
CLUB_TG_OUTBOX_RETRY_BASE_SECONDS=30
CLUB_TG_OUTBOX_STALE_LEASE_SECONDS=300

CLUB_SILENCE_THRESHOLD_DAYS=2
CLUB_SILENCE_SCAN_BATCH_SIZE=500

CLUB_AIBOT_BASE_URL=http://10.0.0.1:8090
CLUB_AIBOT_SIGNING_SECRET=<same-as-aibot-CLUB_AIBOT_SIGNING_SECRET>
CLUB_AIBOT_TIMEOUT_SECONDS=10

CLUB_AIBOT_LEADERBOARD_IMAGE_PATH=/internal/club/leaderboards/image
CLUB_AIBOT_LEADERBOARD_PUBLISH_PATH=/internal/club/leaderboards/publish
CLUB_AIBOT_LEADERBOARD_STATUS_PATH=/internal/club/leaderboards/assets/{asset_id}
CLUB_AIBOT_LEADERBOARD_PREFLIGHT_PATH=/internal/club/leaderboards/preflight
```

`CLUB_AIBOT_BASE_URL` РґРѕР»Р¶РµРЅ СЃРјРѕС‚СЂРµС‚СЊ РЅР° `copywriting-api`. РЎРµР№С‡Р°СЃ `copywriting-api` РЅР° РІС‚РѕСЂРѕРј СЃРµСЂРІРµСЂРµ РїСЂРѕР±СЂРѕС€РµРЅ РєР°Рє `10.0.0.1:8090->8090`, РїРѕСЌС‚РѕРјСѓ РґР»СЏ backend-СЃРµСЂРІРµСЂР° С†РµР»РµРІРѕР№ URL РѕР¶РёРґР°РµРјРѕ:

```text
http://10.0.0.1:8090
```

Р•СЃР»Рё СЃРµС‚СЊ РјРµР¶РґСѓ СЃРµСЂРІРµСЂР°РјРё СѓСЃС‚СЂРѕРµРЅР° РёРЅР°С‡Рµ, РїСЂРѕРІРµСЂРёС‚СЊ curl СЃ `5.42.116.157`:

```bash
curl -fsS http://10.0.0.1:8090/internal/v1/health
```

## Env: copywriting-clubbot РќР° Р·Р°СЂСѓР±РµР¶РЅРѕРј bot-СЃРµСЂРІРµСЂРµ

`clubbot` Р·Р°РїСѓСЃРєР°РµС‚СЃСЏ РєР°Рє `copywriting-clubbot` РёР· РєРѕРґР° `aibot` РЅР° Р·Р°СЂСѓР±РµР¶РЅРѕРј bot-СЃРµСЂРІРµСЂРµ, РЅР°РїСЂРёРјРµСЂ `72.56.108.222`, Р° РЅРµ РЅР° `5.42.116.157`. РљРѕРїРёСЂРѕРІР°С‚СЊ `diaverseapi` РЅР° Р·Р°СЂСѓР±РµР¶РЅС‹Р№ СЃРµСЂРІРµСЂ Р±РѕР»СЊС€Рµ РЅРµ РЅСѓР¶РЅРѕ: `diaverseapi` РѕСЃС‚Р°РµС‚СЃСЏ backend API/state, Р° Telegram runtime Р¶РёРІРµС‚ РІ `aibot`.

РќСѓР¶РЅС‹:

```env
COPYWRITING_RUNTIME_ROLE=copywriting-clubbot
COPYWRITING_RUNTIME_HEARTBEAT_FILE=/tmp/copywriting-clubbot-heartbeat.json
COPYWRITING_RUNTIME_HEARTBEAT_STALE_SECONDS=180

CLUBBOT_TOKEN=<club-bot-token>
CLUBBOT_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
CLUBBOT_BACKEND_SECRET=<same-as-diaverseapi-CLUBBOT_INTERNAL_SECRET>
CLUBBOT_CHAT_ID=-100...

CLUBBOT_WEBHOOK_URL=https://<public-host>/clubbot/webhook
CLUBBOT_WEBHOOK_SECRET_TOKEN=<random-secret>
CLUBBOT_WEBHOOK_LISTEN=0.0.0.0
CLUBBOT_WEBHOOK_PORT=8080
CLUBBOT_WEBHOOK_PATH=clubbot/webhook
CLUBBOT_ALLOWED_UPDATES=chat_join_request,chat_member,my_chat_member,message

CLUBBOT_WELCOME_MESSAGE_THREAD_ID=
CLUBBOT_REPORTS_MESSAGE_THREAD_ID=
CLUBBOT_LEADERBOARD_MESSAGE_THREAD_ID=

CLUBBOT_OUTBOX_WORKER_ID=clubbot-default
CLUBBOT_OUTBOX_POLL_SECONDS=3
CLUBBOT_OUTBOX_BATCH_SIZE=10
CLUBBOT_OUTBOX_LEASE_SECONDS=60
```

## Addendum: Telegram roster sync через userbot (2026-05-19)

Что изменилось:

- `diaverseapi` остается владельцем club domain: memberships, links, roster sync runs, leaderboards.
- `copywriting-userbot` на зарубежном bot-сервере может периодически читать список участников Telegram-группы через MTProto/Pyrogram.
- Userbot отправляет signed batches в `diaverseapi` на `/v1/internal/club/telegram/roster-snapshot`.
- `diaverseapi` создает/обновляет только `ClubMembership`. Полноценный игровой `User` из Telegram-присутствия не создается.
- `user_id` линкуется только если в игре уже есть пользователь с этим Telegram identity.

Env на `/srv/aibot/.env.production`:

```env
CLUB_ROSTER_SYNC_ENABLED=false
CLUB_ROSTER_CHAT_ID=-1003759564801
CLUB_ROSTER_SYNC_INTERVAL_SECONDS=21600
CLUB_ROSTER_BATCH_SIZE=500
CLUB_ROSTER_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
CLUB_ROSTER_BACKEND_SECRET=<same-as-CLUBBOT_BACKEND_SECRET-and-diaverseapi-CLUBBOT_INTERNAL_SECRET>
CLUB_ROSTER_INCLUDE_BOTS=false
CLUB_ROSTER_INCLUDE_DELETED=false
```

`CLUB_ROSTER_SYNC_ENABLED=false` оставить на первый рестарт. Включать `true` только после проверки, что userbot аккаунт находится в клубной группе и может читать участников. Если `CLUB_ROSTER_BACKEND_BASE_URL`, `CLUB_ROSTER_BACKEND_SECRET` или `CLUB_ROSTER_CHAT_ID` пустые, runtime попробует fallback на `CLUBBOT_BACKEND_BASE_URL`, `CLUBBOT_BACKEND_SECRET`, `CLUBBOT_CHAT_ID`, но на сервере лучше указать явные `CLUB_ROSTER_*`.

Порядок обновления:

1. На backend-сервере `/home/diaverseapi`: подтянуть `dev`, применить Alembic migration, рестартовать `diaverse-api-1`.
2. На bot-сервере `/srv/aibot`: подтянуть `dev`, добавить env выше, пересобрать и поднять `copywriting-userbot`.
3. Проверить, что обычные publish/source loops живы при `CLUB_ROSTER_SYNC_ENABLED=false`.
4. Поставить `CLUB_ROSTER_SYNC_ENABLED=true`, рестартовать только `copywriting-userbot`.
5. Смотреть логи:
   - `copywriting.userbot.club_roster.loop_started`
   - `copywriting.userbot.club_roster.preflight.*`
   - `copywriting.userbot.club_roster.scan.done`
   - `copywriting.userbot.club_roster.sync.done`
6. В `/staff/club/settings` проверить карточку roster sync: last run, counts, status, error.
7. В `/staff/club/members` использовать фильтры `Unlinked`, `Roster scan`, `Telegram presence`.
8. Для непривязанных участников нажать `Link TG` или указать `Link UUID`.
9. Собрать daily step snapshot/leaderboard и проверить, что linked участники получают шаги из `user_activities`, а unlinked не ломают рейтинг.

Если roster sync падает:

- `peer_id_invalid` / `channel_private`: userbot не резолвит чат или не состоит в группе; сначала открыть группу этим аккаунтом и проверить доступ.
- `chat_admin_required`: группе нужны права, позволяющие читать участников.
- `flood_wait`: временно увеличить `CLUB_ROSTER_SYNC_INTERVAL_SECONDS` и не дергать рестарты часто.
- `403` от backend: не совпадает `CLUB_ROSTER_BACKEND_SECRET` с `CLUBBOT_INTERNAL_SECRET`.
- `502` от backend: проверить `diaverse-api-1` и reverse proxy, затем `docker logs --tail=200 diaverse-api-1`.

`CLUBBOT_BACKEND_SECRET` РґРѕР»Р¶РµРЅ СЃРѕРІРїР°РґР°С‚СЊ СЃ `CLUBBOT_INTERNAL_SECRET`.

## Env: aibot РќР° `72.56.108.222`

Р¤Р°Р№Р»: `/srv/aibot/.env.production`.

Р”РѕР±Р°РІРёС‚СЊ/РїСЂРѕРІРµСЂРёС‚СЊ:

```env
CLUB_AIBOT_SIGNING_SECRET=<same-as-diaverseapi-CLUB_AIBOT_SIGNING_SECRET>
CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS=300

COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images

COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
COPYWRITING_USERBOT_PUBLISH_POLL_INTERVAL_SECONDS=2
COPYWRITING_USERBOT_REQUIRE_PREMIUM=true
COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot

TELEGRAM_API_ID=<api-id>
TELEGRAM_API_HASH=<api-hash>
TELEGRAM_PHONE=<premium-userbot-phone>

OPENAI_API_KEY=<key>
OPENAI_IMAGE_MODEL=gpt-image-2
OPENAI_IMAGE_SIZE=1024x1024
OPENAI_IMAGE_QUALITY=high

# РўРѕР»СЊРєРѕ fallback РґР»СЏ publish target С‡РµСЂРµР· Bot API, РЅРµ РѕСЃРЅРѕРІРЅРѕР№ РїСѓС‚СЊ РєР»СѓР±РЅРѕРіРѕ runtime.
# РўРѕРєРµРЅ clubbot РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РґРµР№СЃС‚РІРёР№ С…СЂР°РЅРёС‚СЃСЏ РІ CLUBBOT_TOKEN.
TELEGRAM_BOT_TOKEN_CLUB=
```

РќР° СЃРµСЂРІРµСЂРµ СѓР¶Рµ Р±С‹Р»Рё `COPYWRITING_GENERATED_IMAGES_DIR`, `COPYWRITING_USERBOT_*`, `TELEGRAM_API_*`, РЅРѕ РЅРµ Р±С‹Р»Рѕ `CLUB_AIBOT_SIGNING_SECRET`, `CLUBBOT_*`, `OPENAI_IMAGE_MODEL`.

`CLUBBOT_TOKEN` РЅСѓР¶РµРЅ `copywriting-clubbot` РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РґРµР№СЃС‚РІРёР№ РІ РіСЂСѓРїРїРµ. `TELEGRAM_BOT_TOKEN_CLUB` РЅСѓР¶РµРЅ С‚РѕР»СЊРєРѕ РґР»СЏ explicit Bot API fallback target. РћСЃРЅРѕРІРЅРѕР№ publish target РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ `publish_transport=userbot`.

## Env: diaweb РќР° `5.42.116.157`

Р¤Р°Р№Р»: `/home/diaweb/frontend/.env.production`.

РџСЂРѕРІРµСЂРёС‚СЊ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРµ copywriting BFF РїРµСЂРµРјРµРЅРЅС‹Рµ:

```env
COPYWRITING_API_URL=http://10.0.0.1:8090/internal/v1
COPYWRITING_INTERNAL_JWT_SECRET=<same-as-aibot-COPYWRITING_INTERNAL_JWT_SECRET>
COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api
COPYWRITING_INTERNAL_JWT_TTL_SECONDS=300
COPYWRITING_REQUEST_TIMEOUT_MS=...
```

РљР»СѓР±РЅР°СЏ Р°РґРјРёРЅРєР° С…РѕРґРёС‚ РІ `diaverseapi` С‡РµСЂРµР· СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ frontend API client. РќРѕРІС‹Рµ env РґР»СЏ `/staff/club` РѕС‚РґРµР»СЊРЅРѕ РЅРµ РЅСѓР¶РЅС‹.

## Telegram РќР°СЃС‚СЂРѕР№РєР°

Р’ РєР»СѓР±РЅРѕР№ supergroup РґРѕР»Р¶РЅС‹ Р±С‹С‚СЊ:

1. `clubbot` РєР°Рє bot account.
2. Premium userbot account РёР· `copywriting-userbot`.

`clubbot`:

- СЃРѕСЃС‚РѕРёС‚ РІ supergroup;
- РёРјРµРµС‚ admin-РїСЂР°РІР° РґР»СЏ join requests, invite links, Р±СѓРґСѓС‰РµРіРѕ removal flow;
- РїРѕР»СѓС‡Р°РµС‚ updates С‚РѕР»СЊРєРѕ С‡РµСЂРµР· `clubbot`, РЅРµ С‡РµСЂРµР· `aibot`.

Premium userbot:

- Р·Р°Р»РѕРіРёРЅРµРЅ РІ Pyrogram session, volume `copywriting_userbot_session`;
- СЃРѕСЃС‚РѕРёС‚ РІ supergroup;
- РјРѕР¶РµС‚ РїРёСЃР°С‚СЊ РІ РЅСѓР¶РЅС‹Р№ forum topic;
- РЅСѓР¶РµРЅ РґР»СЏ premium emoji.

Topic id:

- Р’ `/staff/club/settings` РїРѕР»Рµ `Leaderboard thread` РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ root message id РЅСѓР¶РЅРѕРіРѕ Telegram topic.
- Р”Р»СЏ userbot С‚РµРєСѓС‰Р°СЏ СЂРµР°Р»РёР·Р°С†РёСЏ РїРµСЂРµРґР°РµС‚ СЌС‚РѕС‚ id РєР°Рє `reply_to_message_id`.
- Р”Р»СЏ Bot API fallback СЌС‚Рѕ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РєР°Рє `message_thread_id`.

## Aibot Publish Target Р”Р»СЏ РљР»СѓР±Р°

РќСѓР¶РЅР° Р·Р°РїРёСЃСЊ РІ `copywriting_publish_targets` РЅР° aibot DB.

Р РµРєРѕРјРµРЅРґСѓРµРјС‹Р№ JSON:

```json
{
  "name": "Club leaderboard",
  "target_type": "telegram",
  "destination_ref": "-1001234567890",
  "config_json": {
    "publish_transport": "userbot",
    "club_profile": "club",
    "message_thread_id": 12345,
    "caption_limit": 1024
  }
}
```

Premium emoji РґР»СЏ leaderboard caption Р±РѕР»СЊС€Рµ РЅРµ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹: РєРѕРґ РѕС‚РїСЂР°РІР»СЏРµС‚ РѕР±С‹С‡РЅС‹Р№ Р·Р°РіРѕР»РѕРІРѕРє `Club leaderboard`.
`custom_emoji_map` РЅСѓР¶РµРЅ С‚РѕР»СЊРєРѕ РµСЃР»Рё РїРѕР·Р¶Рµ РІ С‚РµРєСЃС‚Рµ СЃРЅРѕРІР° РїРѕСЏРІСЏС‚СЃСЏ `{{emoji:key}}` РїР»РµР№СЃС…РѕР»РґРµСЂС‹.

SQL-С€Р°Р±Р»РѕРЅ С‡РµСЂРµР· РєРѕРЅС‚РµР№РЅРµСЂ:

```bash
cd /srv/aibot

docker compose -f docker-compose.prod.yml exec -T copywriting-postgres psql \
  -U "$COPYWRITING_POSTGRES_USER" \
  -d "$COPYWRITING_POSTGRES_DB" <<'SQL'
INSERT INTO copywriting_publish_targets (
  id,
  name,
  target_type,
  destination_ref,
  status,
  is_enabled,
  config_json,
  created_by_user_id,
  updated_by_user_id
)
VALUES (
  gen_random_uuid(),
  'Club leaderboard',
  'telegram',
  '-1001234567890',
  'active',
  true,
  '{
    "publish_transport": "userbot",
    "club_profile": "club",
    "message_thread_id": 12345,
    "caption_limit": 1024
  }'::jsonb,
  'deploy',
  'deploy'
)
ON CONFLICT (target_type, destination_ref)
DO UPDATE SET
  name = EXCLUDED.name,
  status = 'active',
  is_enabled = true,
  config_json = EXCLUDED.config_json,
  updated_by_user_id = 'deploy',
  updated_at = now();
SQL
```

Р•СЃР»Рё shell РЅРµ СЌРєСЃРїРѕСЂС‚РёСЂСѓРµС‚ `COPYWRITING_POSTGRES_USER/DB`, РїРѕРґСЃС‚Р°РІРёС‚СЊ Р·РЅР°С‡РµРЅРёСЏ РёР· `/srv/aibot/.env.production` РёР»Рё РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ РґРµС„РѕР»С‚С‹ РёР· compose:

```bash
-U copywriting -d copywriting
```

## РџРѕСЂСЏРґРѕРє Deploy

### 1. Backup РџРµСЂРµРґ Р Р°Р±РѕС‚РѕР№

РќР° `5.42.116.157`:

```bash
mkdir -p /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)
cd /home/config
cp .env /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)/diaverseapi.env
docker compose -f docker-compose.yml ps
```

РќР° `72.56.108.222`:

```bash
mkdir -p /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)
cd /srv/aibot
cp .env.production /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)/aibot.env.production
docker compose -f docker-compose.prod.yml ps
```

### 2. РћР±РЅРѕРІРёС‚СЊ aibot РќР° `72.56.108.222`

```bash
ssh -i ~/.ssh/id_server_diaverse root@72.56.108.222

cd /srv/aibot
git status -sb
git fetch origin
git pull --ff-only origin dev
```

Р•СЃР»Рё `git pull --ff-only` РЅРµ РїСЂРѕС…РѕРґРёС‚ РёР·-Р·Р° Р»РѕРєР°Р»СЊРЅС‹С… РёР·РјРµРЅРµРЅРёР№, РѕСЃС‚Р°РЅРѕРІРёС‚СЊСЃСЏ Рё РЅРµ РґРµР»Р°С‚СЊ `reset --hard`.

Р”РѕР±Р°РІРёС‚СЊ РЅРµРґРѕСЃС‚Р°СЋС‰РёРµ env РІ `/srv/aibot/.env.production`.

РЎРѕР±СЂР°С‚СЊ РЅРѕРІС‹Рµ РѕР±СЂР°Р·С‹:

```bash
docker compose -f docker-compose.prod.yml build copywriting-api copywriting-worker copywriting-userbot copywriting-clubbot
```

РџСЂРёРјРµРЅРёС‚СЊ SQL migrations:

```bash
docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
  sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < migrations/20260519_0001_copywriting_club_benefits.sql

docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
  sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < migrations/20260519_0002_copywriting_club_leaderboard_assets.sql
```

РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ:

```bash
docker compose -f docker-compose.prod.yml up -d copywriting-api
docker compose -f docker-compose.prod.yml up -d copywriting-worker copywriting-userbot copywriting-clubbot
```

РџСЂРѕРІРµСЂРёС‚СЊ:

```bash
docker compose -f docker-compose.prod.yml ps
docker logs --tail=120 copywriting-api
docker logs --tail=120 copywriting-worker
docker logs --tail=120 copywriting-userbot
docker logs --tail=120 copywriting-clubbot
docker compose -f docker-compose.prod.yml exec -T copywriting-clubbot \
  python scripts/runtime_probe.py heartbeat \
  --file /tmp/copywriting-clubbot-heartbeat.json \
  --max-age 180
curl -fsS http://127.0.0.1:8090/internal/v1/health
```

### 3. РћР±РЅРѕРІРёС‚СЊ diaverseapi РќР° `5.42.116.157`

РЎРЅР°С‡Р°Р»Р° СЂРµС€РёС‚СЊ Р±Р»РѕРєРµСЂ `/home/diaverse` dirty worktree.

РљРѕРіРґР° `/home/diaverse` С‡РёСЃС‚С‹Р№ Рё РіРѕС‚РѕРІ Рє `dev`:

```bash
ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157

cd /home/diaverse
git status -sb
git fetch origin
git checkout dev
git pull --ff-only origin dev
```

РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ РЅРѕРІС‹Рµ С„Р°Р№Р»С‹ РµСЃС‚СЊ:

```bash
test -f app/club/admin_api.py
test -f app/club/aibot_client.py
test -f app/club/leaderboards.py
test -f migrations/versions/20260519_club_domain.py
```

Р”РѕР±Р°РІРёС‚СЊ env РІ `/home/config/.env`.

РџСЂРёРјРµРЅРёС‚СЊ Alembic С‡РµСЂРµР· СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ compose:

```bash
cd /home/config
docker compose -f docker-compose.yml run --rm migrate
```

РџРµСЂРµСЃРѕР±СЂР°С‚СЊ image, РµСЃР»Рё РјРµРЅСЏР»РёСЃСЊ dependencies/config image layer:

```bash
docker compose -f docker-compose.yml --profile build build app-image
```

РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ backend:

```bash
docker compose -f docker-compose.yml up -d api worker scheduler
docker compose -f docker-compose.yml ps
docker logs --tail=120 diaverse-api-1
docker logs --tail=200 diaverse-api-1 | grep -E 'club\.security|club internal|clubbot|tg outbox' || true
```

РџСЂРѕРІРµСЂРёС‚СЊ backend health:

```bash
curl -fsS https://api.dev.diaverse.app/v1/health || true
curl -fsS https://api2.dev.diaverse.app/v1/health || true
```

### 4. РћР±РЅРѕРІРёС‚СЊ diaweb РќР° `5.42.116.157`

```bash
ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157

cd /home/diaweb
git status -sb
git fetch origin
git pull --ff-only origin dev
```

Untracked `docker-compose.dev-traefik.yml` РЅРµ СѓРґР°Р»СЏС‚СЊ.

РџСЂРѕРІРµСЂРёС‚СЊ env:

```bash
grep -E '^(COPYWRITING_API_URL|COPYWRITING_INTERNAL_JWT_SECRET|COPYWRITING_INTERNAL_JWT_ISSUER|COPYWRITING_INTERNAL_JWT_AUDIENCE)=' frontend/.env.production
```

РЎРѕР±СЂР°С‚СЊ Рё РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ:

```bash
docker compose -f docker-compose.dev-traefik.yml build diaweb
docker compose -f docker-compose.dev-traefik.yml up -d diaweb
docker logs --tail=120 diaweb-dev
```

РџСЂРѕРІРµСЂРёС‚СЊ СЃС‚СЂР°РЅРёС†Сѓ:

```text
https://dev.diaverse.app/ru/staff/club
```

## РќР°СЃС‚СЂРѕР№РєР° Р’ РђРґРјРёРЅРєРµ

РћС‚РєСЂС‹С‚СЊ:

```text
/staff/club/settings
```

Р—Р°РїРѕР»РЅРёС‚СЊ:

- `Telegram chat id`: `-100...`
- `Leaderboard thread`: root message id РЅСѓР¶РЅРѕРіРѕ topic
- `Aibot target profile`: `club`
- `Leaderboard image style`: `club_leaderboard`
- `Leaderboard image enabled`: enabled
- invite/join settings РїРѕ С‚РµРєСѓС‰РµРјСѓ РєР»СѓР±Сѓ

РќР°Р¶Р°С‚СЊ validation.

РћР¶РёРґР°РµРјС‹Рµ РїСЂРёР·РЅР°РєРё:

```text
aibot_configured=true
aibot preflight ok=true
destination_ref_configured=true
publish_transport=userbot
topic_strategy=reply_to_message_id
```

## Smoke Test

1. РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, `copywriting-clubbot`, `diaverse-api-1`, `diaweb-dev` healthy/running.
2. Р’ `/staff/club/settings` РІС‹РїРѕР»РЅРёС‚СЊ validation.
3. Р’ `/staff/club/members` РґРѕР±Р°РІРёС‚СЊ С‚РµСЃС‚РѕРІРѕРіРѕ manual member РёР»Рё РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РµРіРѕ.
4. РЈР±РµРґРёС‚СЊСЃСЏ, С‡С‚Рѕ РЅР° РґР°С‚Сѓ РµСЃС‚СЊ step rows/user activities.
5. Р’ `/staff/club/leaderboards` РЅР°Р¶Р°С‚СЊ build.
6. Р—Р°РїСЂРѕСЃРёС‚СЊ AI image.
7. Р”РѕР¶РґР°С‚СЊСЃСЏ `image_status=ready`.
8. РќР°Р¶Р°С‚СЊ publish.
9. РЈРІРёРґРµС‚СЊ `publish_status=queued` РёР»Рё `publishing`.
10. РџСЂРѕРІРµСЂРёС‚СЊ logs `copywriting-userbot`.
11. РќР°Р¶Р°С‚СЊ `Refresh status`.
12. РћР¶РёРґР°С‚СЊ `publish_status=published` Рё Telegram message ids.
13. РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ РїРѕСЃС‚ РїРѕСЏРІРёР»СЃСЏ РІ РїСЂР°РІРёР»СЊРЅРѕРј Telegram topic РѕС‚ userbot account.

## Troubleshooting

`aibot_configured=false`:

- РїСЂРѕРІРµСЂРёС‚СЊ `CLUB_AIBOT_BASE_URL` РІ `/home/config/.env`;
- РїСЂРѕРІРµСЂРёС‚СЊ РѕРґРёРЅР°РєРѕРІС‹Р№ `CLUB_AIBOT_SIGNING_SECRET` РЅР° РѕР±РѕРёС… СЃРµСЂРІРµСЂР°С….

`Invalid service auth` РІ `copywriting-api`:

- СЂР°Р·РЅС‹Рµ HMAC secrets;
- clock skew Р±РѕР»СЊС€Рµ `CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS`;
- proxy/network СЃСЂРµР·Р°РµС‚ headers `X-Diaverse-*`.

РќРµС‚ signed event delivery РѕС‚ `copywriting-clubbot` РІ backend:

- РїСЂРѕРІРµСЂРёС‚СЊ `CLUBBOT_BACKEND_BASE_URL` РЅР° foreign bot-СЃРµСЂРІРµСЂРµ;
- РїСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ `CLUBBOT_BACKEND_SECRET` СЂР°РІРµРЅ `CLUBBOT_INTERNAL_SECRET`;
- СЃРјРѕС‚СЂРµС‚СЊ `docker logs --tail=200 copywriting-clubbot` РїРѕ `update_id`, `command_id`, `worker_id`, `request_id`;
- СЃРјРѕС‚СЂРµС‚СЊ backend logs РїРѕ `[club.security]` Рё С‚РѕРјСѓ Р¶Рµ `request_id`.

`publish_target_missing`:

- РЅРµС‚ enabled row РІ `copywriting_publish_targets`;
- `club_profile` РЅРµ `club`;
- target РЅРµ `telegram`;
- target РІС‹РєР»СЋС‡РµРЅ.

`publish_status=queued` РґРѕР»РіРѕ РІРёСЃРёС‚:

- РЅРµ СЂР°Р±РѕС‚Р°РµС‚ `copywriting-userbot`;
- queue mismatch: РїСЂРѕРІРµСЂРёС‚СЊ `COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish`;
- userbot session РЅРµ Р°РІС‚РѕСЂРёР·РѕРІР°РЅР°;
- userbot РЅРµ СЃРѕСЃС‚РѕРёС‚ РІ РЅСѓР¶РЅРѕР№ РіСЂСѓРїРїРµ/topic.

`image_status=generating` РґРѕР»РіРѕ РІРёСЃРёС‚:

- РЅРµ СЂР°Р±РѕС‚Р°РµС‚ `copywriting-worker`;
- РЅРµС‚ `OPENAI_API_KEY`;
- РЅРµС‚ `OPENAI_IMAGE_MODEL`;
- РЅРµС‚ РїСЂР°РІ РЅР° volume `copywriting_generated_images`.

РџРѕСЃС‚ РЅРµ РІ С‚РѕР№ С‚РµРјРµ:

- РЅРµРїСЂР°РІРёР»СЊРЅС‹Р№ `Leaderboard thread`;
- РЅСѓР¶РµРЅ root message id topic;
- userbot РЅРµ РІРёРґРёС‚ topic;
- publish target РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚ `reply_to_message_id`.

## Rollback

РћС‚РєР°С‚ Р»СѓС‡С€Рµ РґРµР»Р°С‚СЊ С‡Р°СЃС‚СЏРјРё:

1. Р•СЃР»Рё СЃР»РѕРјР°Р»Р°СЃСЊ РіРµРЅРµСЂР°С†РёСЏ/РѕС‡РµСЂРµРґСЊ РІ `aibot`, РѕС‚РєР°С‚РёС‚СЊ `copywriting-worker` Рё `copywriting-userbot`.
2. Р•СЃР»Рё СЃР»РѕРјР°Р»Р°СЃСЊ service auth/API С„РѕСЂРјР°, РѕС‚РєР°С‚РёС‚СЊ `copywriting-api`.
3. Р•СЃР»Рё СЃР»РѕРјР°Р»Р°СЃСЊ club admin UI, РѕС‚РєР°С‚РёС‚СЊ `diaweb`.
4. Р•СЃР»Рё СЃР»РѕРјР°Р»СЃСЏ club backend, РѕС‚РєР°С‚РёС‚СЊ `diaverseapi` РЅР° РїСЂРµРґС‹РґСѓС‰РёР№ РєРѕРґ Рё РЅРµ РѕС‚РєР°С‚С‹РІР°С‚СЊ РјРёРіСЂР°С†РёРё Р±РµР· РѕС‚РґРµР»СЊРЅРѕРіРѕ РїР»Р°РЅР°.

РљРѕРјР°РЅРґС‹ РґР»СЏ С‡Р°СЃС‚РёС‡РЅРѕРіРѕ rollback Р·Р°РІРёСЃСЏС‚ РѕС‚ РІС‹Р±СЂР°РЅРЅРѕРіРѕ РїСЂРµРґС‹РґСѓС‰РµРіРѕ commit/tag. РќРµ РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ `git reset --hard`, РїРѕРєР° РЅРµ СЃРѕС…СЂР°РЅРµРЅС‹ Р»РѕРєР°Р»СЊРЅС‹Рµ server-only С„Р°Р№Р»С‹ Рё dirty worktree.

## Р§С‚Рѕ РќРµ Р РµР°Р»РёР·РѕРІР°РЅРѕ

Р­С‚Р° С„РёС‡Р° РЅРµ РІРєР»СЋС‡Р°РµС‚:

- РїСѓР±Р»РёС‡РЅС‹Р№ checkout/join flow;
- Prodamus recurring failed-payment automation;
- Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРѕРµ СѓРґР°Р»РµРЅРёРµ РёР· Telegram РїСЂРё РЅРµРѕРїР»Р°С‚Рµ;
- scraping РїРѕР»РЅРѕРіРѕ СЃРїРёСЃРєР° СѓС‡Р°СЃС‚РЅРёРєРѕРІ Telegram-РіСЂСѓРїРїС‹;
- РѕР±СЏР·Р°С‚РµР»СЊРЅСѓСЋ РІРµСЂРёС„РёРєР°С†РёСЋ С‡РµСЂРµР· `/start`.

Р­С‚Рё СЃС†РµРЅР°СЂРёРё Р·Р°Р»РѕР¶РµРЅС‹ Р°СЂС…РёС‚РµРєС‚СѓСЂРЅРѕ С‡РµСЂРµР· club domain, payment contracts Рё outbox, РЅРѕ С‚СЂРµР±СѓСЋС‚ РѕС‚РґРµР»СЊРЅРѕР№ СЂРµР°Р»РёР·Р°С†РёРё.


РџРѕСЂСЏРґРѕРє С‚Р°РєРѕР№.

  1. РЎРЅР°С‡Р°Р»Р° РЅРµ С‚СЂРѕРіР°С‚СЊ backend
  РќР° СЃРµСЂРІРµСЂРµ 5.42.116.157 repo /home/diaverse СЃРµР№С‡Р°СЃ РіСЂСЏР·РЅС‹Р№ Рё РЅР° РІРµС‚РєРµ fix/pets-skins. РўР°Рј РјРЅРѕРіРѕ С‡СѓР¶РёС…
  РёР·РјРµРЅРµРЅРёР№. РџРѕСЌС‚РѕРјСѓ РЅРµР»СЊР·СЏ РґРµР»Р°С‚СЊ:

  cd /home/diaverse
  git checkout dev
  git pull

  РЎРЅР°С‡Р°Р»Р° РЅР°РґРѕ СЂРµС€РёС‚СЊ, С‡С‚Рѕ РґРµР»Р°С‚СЊ СЃ СЌС‚РёРјРё РёР·РјРµРЅРµРЅРёСЏРјРё:

  - Р»РёР±Рѕ РІР»Р°РґРµР»РµС† РєРѕРјРјРёС‚РёС‚ РёС…;
  - Р»РёР±Рѕ stash/backup;
  - Р»РёР±Рѕ РґРµР»Р°РµРј РѕС‚РґРµР»СЊРЅС‹Р№ clean clone РґР»СЏ deploy.

  Р‘РµР· СЌС‚РѕРіРѕ backend-РєР»СѓР± Р»СѓС‡С€Рµ РЅРµ РІС‹РєР°С‚С‹РІР°С‚СЊ.

  2. РћР±РЅРѕРІРёС‚СЊ aibot РЅР° 72.56.108.222

  ssh -i ~/.ssh/id_server_diaverse root@72.56.108.222
  cd /srv/aibot

  git status -sb
  git fetch origin
  git pull --ff-only origin dev

  РџРѕС‚РѕРј РІ /srv/aibot/.env.production РґРѕР±Р°РІРёС‚СЊ/РїСЂРѕРІРµСЂРёС‚СЊ:

  COPYWRITING_RUNTIME_ROLE=copywriting-clubbot
  COPYWRITING_RUNTIME_HEARTBEAT_FILE=/tmp/copywriting-clubbot-heartbeat.json
  COPYWRITING_RUNTIME_HEARTBEAT_STALE_SECONDS=180
  CLUBBOT_TOKEN=<club-bot-token>
  CLUBBOT_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
  CLUBBOT_BACKEND_SECRET=<С‚РѕС‚ Р¶Рµ СЃРµРєСЂРµС‚ С‡С‚Рѕ CLUBBOT_INTERNAL_SECRET РІ diaverseapi>
  CLUBBOT_CHAT_ID=-100...
  CLUB_AIBOT_SIGNING_SECRET=<РѕР±С‰РёР№ СЃРµРєСЂРµС‚ СЃ diaverseapi>
  CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS=300
  OPENAI_IMAGE_MODEL=gpt-image-2
  OPENAI_IMAGE_SIZE=1024x1024
  OPENAI_IMAGE_QUALITY=high
  COPYWRITING_USERBOT_REQUIRE_PREMIUM=true

  РЎРѕР±СЂР°С‚СЊ Рё РїСЂРёРјРµРЅРёС‚СЊ РјРёРіСЂР°С†РёРё:

  docker compose -f docker-compose.prod.yml build copywriting-api copywriting-worker copywriting-userbot copywriting-clubbot

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
    psql -U copywriting -d copywriting \
    < migrations/20260519_0001_copywriting_club_benefits.sql

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
    psql -U copywriting -d copywriting \
    < migrations/20260519_0002_copywriting_club_leaderboard_assets.sql

  РџРµСЂРµР·Р°РїСѓСЃРє:

  docker compose -f docker-compose.prod.yml up -d copywriting-api copywriting-worker copywriting-userbot copywriting-clubbot
  docker compose -f docker-compose.prod.yml ps
  docker logs --tail=120 copywriting-clubbot
  docker compose -f docker-compose.prod.yml exec -T copywriting-clubbot \
    python scripts/runtime_probe.py heartbeat \
    --file /tmp/copywriting-clubbot-heartbeat.json \
    --max-age 180

  3. РќР°СЃС‚СЂРѕРёС‚СЊ publish target РІ aibot
  Р’ Р‘Р” copywriting РЅСѓР¶РЅР° Р·Р°РїРёСЃСЊ copywriting_publish_targets РґР»СЏ РєР»СѓР±Р°:

  {
    "publish_transport": "userbot",
    "club_profile": "club",
    "message_thread_id": 12345,
    "caption_limit": 1024
  }

  message_thread_id Р·Р°РјРµРЅРёС‚СЊ РЅР° root message id РЅСѓР¶РЅРѕРіРѕ Telegram topic.

  custom_emoji_map РґР»СЏ leaderboard Р±РѕР»СЊС€Рµ РЅРµ РЅСѓР¶РµРЅ, РїРѕРєР° РІ caption РЅРµС‚ {{emoji:key}} РїР»РµР№СЃС…РѕР»РґРµСЂРѕРІ.

  4. РџРѕС‚РѕРј РѕР±РЅРѕРІРёС‚СЊ backend РЅР° 5.42.116.157
  РўРѕР»СЊРєРѕ РїРѕСЃР»Рµ СЂРµС€РµРЅРёСЏ dirty worktree.

  ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157
  cd /home/diaverse

  git status -sb
  git fetch origin
  git checkout dev
  git pull --ff-only origin dev

  Р’ /home/config/.env РґРѕР±Р°РІРёС‚СЊ/РїСЂРѕРІРµСЂРёС‚СЊ:

  CLUB_ACTIVE_PROGRAM_CODE=main
  CLUB_AIBOT_BASE_URL=http://10.0.0.1:8090
  CLUB_AIBOT_SIGNING_SECRET=<С‚РѕС‚ Р¶Рµ СЃРµРєСЂРµС‚ С‡С‚Рѕ РІ aibot>
  CLUB_AIBOT_LEADERBOARD_IMAGE_PATH=/internal/club/leaderboards/image
  CLUB_AIBOT_LEADERBOARD_PUBLISH_PATH=/internal/club/leaderboards/publish
  CLUB_AIBOT_LEADERBOARD_STATUS_PATH=/internal/club/leaderboards/assets/{asset_id}
  CLUB_AIBOT_LEADERBOARD_PREFLIGHT_PATH=/internal/club/leaderboards/preflight

  РџСЂРёРјРµРЅРёС‚СЊ РјРёРіСЂР°С†РёРё:

  cd /home/config
  docker compose -f docker-compose.yml run --rm migrate

  РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ backend:

  docker compose -f docker-compose.yml --profile build build app-image
  docker compose -f docker-compose.yml up -d api worker scheduler
  docker compose -f docker-compose.yml ps

  5. РћР±РЅРѕРІРёС‚СЊ diaweb РЅР° 5.42.116.157

  cd /home/diaweb

  git status -sb
  git fetch origin
  git pull --ff-only origin dev

  РџСЂРѕРІРµСЂРёС‚СЊ /home/diaweb/frontend/.env.production:

  COPYWRITING_API_URL=http://10.0.0.1:8090/internal/v1
  COPYWRITING_INTERNAL_JWT_SECRET=<РєР°Рє РІ aibot>
  COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
  COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api

  РЎРѕР±СЂР°С‚СЊ Рё РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ:

  docker compose -f docker-compose.dev-traefik.yml build diaweb
  docker compose -f docker-compose.dev-traefik.yml up -d diaweb

  6. Telegram
  Р’ РєР»СѓР±РЅРѕР№ РіСЂСѓРїРїРµ РґРѕР»Р¶РЅС‹ Р±С‹С‚СЊ:

  - clubbot РєР°Рє Р±РѕС‚ РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РґРµР№СЃС‚РІРёР№;
  - Premium userbot РєР°Рє РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РґР»СЏ РїСѓР±Р»РёРєР°С†РёР№.

  Userbot РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІ РіСЂСѓРїРїРµ Рё РёРјРµС‚СЊ РІРѕР·РјРѕР¶РЅРѕСЃС‚СЊ РїРёСЃР°С‚СЊ РІ РЅСѓР¶РЅС‹Р№ topic.

  7. РџСЂРѕРІРµСЂРєР° РІ Р°РґРјРёРЅРєРµ
  РћС‚РєСЂС‹С‚СЊ:

  /staff/club/settings

  Р—Р°РїРѕР»РЅРёС‚СЊ:

  - Telegram chat id;
  - Leaderboard thread;
  - Aibot target profile = club;
  - Leaderboard image enabled.

  РќР°Р¶Р°С‚СЊ validation. РќСѓР¶РЅРѕ СѓРІРёРґРµС‚СЊ РїСЂРёРјРµСЂРЅРѕ:

  - aibot_configured=true;
  - aibot preflight ok=true;
  - publish_transport=userbot;
  - topic_strategy=reply_to_message_id.

  8. Smoke test
  Р’ /staff/club/leaderboards:

  1. Build leaderboard.
  2. Request AI image.
  3. Р”РѕР¶РґР°С‚СЊСЃСЏ image_status=ready.
  4. Publish.
  5. РЈРІРёРґРµС‚СЊ publish_status=queued РёР»Рё publishing.
  6. РџСЂРѕРІРµСЂРёС‚СЊ copywriting-userbot logs.
  7. РќР°Р¶Р°С‚СЊ Refresh status.
  8. Р”РѕР»Р¶РЅРѕ СЃС‚Р°С‚СЊ publish_status=published.
  9. Р’ Telegram РїРѕСЃС‚ РґРѕР»Р¶РµРЅ РїРѕСЏРІРёС‚СЊСЃСЏ РІ РЅСѓР¶РЅРѕРј topic РѕС‚ userbot.

  Р“Р»Р°РІРЅРѕРµ: СЃРЅР°С‡Р°Р»Р° СЂРµС€РёС‚СЊ РіСЂСЏР·РЅС‹Р№ /home/diaverse, РїРѕС‚РѕРј РІС‹РєР°С‚С‹РІР°С‚СЊ backend. aibot Рё diaweb РјРѕР¶РЅРѕ РѕР±РЅРѕРІР»СЏС‚СЊ
  РѕС‚РґРµР»СЊРЅРѕ, РЅРѕ РІСЃСЏ С„РёС‡Р° Р·Р°СЂР°Р±РѕС‚Р°РµС‚ С‚РѕР»СЊРєРѕ РєРѕРіРґР° РѕР±РЅРѕРІР»РµРЅС‹ РІСЃРµ С‚СЂРё С‡Р°СЃС‚Рё.


вЂє РєР°Рє СЃРѕР·РґР°С‚СЊ СЌС‚РѕС‚ СЃРµРєСЂРµС‚ CLUB_AIBOT_SIGNING_SECRET=<РѕР±С‰РёР№ СЃРµРєСЂРµС‚ СЃ diaverseapi>


вЂў Р­С‚Рѕ РѕР±С‹С‡РЅС‹Р№ РґР»РёРЅРЅС‹Р№ СЃР»СѓС‡Р°Р№РЅС‹Р№ HMAC-СЃРµРєСЂРµС‚. Р•РіРѕ РЅСѓР¶РЅРѕ СЃРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕРґРёРЅ СЂР°Р· Рё РїРѕСЃС‚Р°РІРёС‚СЊ РѕРґРёРЅР°РєРѕРІРѕРµ
  Р·РЅР°С‡РµРЅРёРµ:

  - РІ diaverseapi: /home/config/.env
  - РІ aibot: /srv/aibot/.env.production

  РЎРѕР·РґР°С‚СЊ РјРѕР¶РЅРѕ С‚Р°Рє:

  openssl rand -hex 32

  РџРѕР»СѓС‡РёС‚СЃСЏ СЃС‚СЂРѕРєР° РїСЂРёРјРµСЂРЅРѕ 64 hex-СЃРёРјРІРѕР»Р°. РќР°РїСЂРёРјРµСЂ:

  CLUB_AIBOT_SIGNING_SECRET=РїРѕР»СѓС‡РµРЅРЅР°СЏ_СЃС‚СЂРѕРєР°




РќРёР¶Рµ РїРѕСЂСЏРґРѕРє deploy РїРѕ /C:/Users/Indigo/Desktop/diaverse/docs/club-server-update.md. Р’Р°Р¶РЅРѕ: РїРѕСЃР»Рµ
  РїРѕСЃР»РµРґРЅРёС… РєРѕРјРјРёС‚РѕРІ dev РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµ РЅРёР¶Рµ:

  aibot:       3cc76ec
  diaverseapi: 573bb490
  diaweb:      3a2a6f2

  0. Р“Р»Р°РІРЅР°СЏ СЃС…РµРјР°

  clubbot С‚РµРїРµСЂСЊ Р·Р°РїСѓСЃРєР°РµС‚СЃСЏ РёР· СЂРµРїРѕР·РёС‚РѕСЂРёСЏ aibot РєР°Рє РєРѕРЅС‚РµР№РЅРµСЂ copywriting-clubbot РЅР° Р·Р°СЂСѓР±РµР¶РЅРѕРј СЃРµСЂРІРµСЂРµ
  72.56.108.222.

  diaverseapi РЅР° 5.42.116.157 РЅРµ Р·Р°РїСѓСЃРєР°РµС‚ Telegram-Р±РѕС‚РѕРІ. РћРЅ С…СЂР°РЅРёС‚ СЃРѕСЃС‚РѕСЏРЅРёРµ РєР»СѓР±Р°, API, outbox Рё
  РїСЂРёРЅРёРјР°РµС‚ signed-Р·Р°РїСЂРѕСЃС‹ РѕС‚ copywriting-clubbot.

  1. РЎРЅР°С‡Р°Р»Р° СЂРµС€РёС‚СЊ blocker backend

  РќР° 5.42.116.157 СЂР°РЅСЊС€Рµ Р±С‹Р» dirty worktree:

  ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157
  cd /home/diaverse
  git status -sb

  Р•СЃР»Рё С‚Р°Рј РІСЃС‘ РµС‰С‘ РІРµС‚РєР° fix/pets-skins Рё РјРЅРѕРіРѕ РЅРµР·Р°РєРѕРјРјРёС‡РµРЅРЅС‹С… РёР·РјРµРЅРµРЅРёР№, РЅРµР»СЊР·СЏ РґРµР»Р°С‚СЊ git checkout dev /
  git pull. РќСѓР¶РЅРѕ СЃРЅР°С‡Р°Р»Р°: Р·Р°РєРѕРјРјРёС‚РёС‚СЊ, stash/backup, Р»РёР±Рѕ СЃРґРµР»Р°С‚СЊ clean checkout. Р‘РµР· СЌС‚РѕРіРѕ backend Р»СѓС‡С€Рµ
  РЅРµ РІС‹РєР°С‚С‹РІР°С‚СЊ.

  2. РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СЃРµРєСЂРµС‚С‹

  РќСѓР¶РЅРѕ РґРІР° СЂР°Р·РЅС‹С… HMAC-СЃРµРєСЂРµС‚Р°:

  openssl rand -hex 32

  1. CLUB_AIBOT_SIGNING_SECRET: РѕРґРёРЅР°РєРѕРІС‹Р№ РІ diaverseapi Рё aibot.
  2. CLUBBOT_INTERNAL_SECRET: РІ diaverseapi; С‚Р°РєРѕРµ Р¶Рµ Р·РЅР°С‡РµРЅРёРµ РїРѕСЃС‚Р°РІРёС‚СЊ РІ aibot РєР°Рє
     CLUBBOT_BACKEND_SECRET.

  Р”Р»СЏ webhook token С‚РѕР¶Рµ РјРѕР¶РЅРѕ:

  openssl rand -hex 32

  3. Env diaverseapi РЅР° 5.42.116.157

  Р¤Р°Р№Р»: /home/config/.env.

  CLUB_ACTIVE_PROGRAM_CODE=main

  CLUBBOT_INTERNAL_SECRET=<secret-1>
  CLUBBOT_SIGNATURE_TOLERANCE_SECONDS=300

  CLUB_TG_OUTBOX_BATCH_SIZE=50
  CLUB_TG_OUTBOX_MAX_ATTEMPTS=5
  CLUB_TG_OUTBOX_RETRY_BASE_SECONDS=30
  CLUB_TG_OUTBOX_STALE_LEASE_SECONDS=300

  CLUB_SILENCE_THRESHOLD_DAYS=2
  CLUB_SILENCE_SCAN_BATCH_SIZE=500

  CLUB_AIBOT_BASE_URL=http://10.0.0.1:8090
  CLUB_AIBOT_SIGNING_SECRET=<secret-2>
  CLUB_AIBOT_TIMEOUT_SECONDS=10

  CLUB_AIBOT_LEADERBOARD_IMAGE_PATH=/internal/club/leaderboards/image
  CLUB_AIBOT_LEADERBOARD_PUBLISH_PATH=/internal/club/leaderboards/publish
  CLUB_AIBOT_LEADERBOARD_STATUS_PATH=/internal/club/leaderboards/assets/{asset_id}
  CLUB_AIBOT_LEADERBOARD_PREFLIGHT_PATH=/internal/club/leaderboards/preflight

  РџСЂРѕРІРµСЂРєР° СЃРІСЏР·Рё СЃ aibot СЃ backend-СЃРµСЂРІРµСЂР°:

  curl -fsS http://10.0.0.1:8090/internal/v1/health

  4. Env aibot / clubbot РЅР° 72.56.108.222

  Р¤Р°Р№Р»: /srv/aibot/.env.production.

  CLUB_AIBOT_SIGNING_SECRET=<same-as-diaverseapi-CLUB_AIBOT_SIGNING_SECRET>
  CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS=300

  COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images

  COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
  COPYWRITING_USERBOT_PUBLISH_POLL_INTERVAL_SECONDS=2
  COPYWRITING_USERBOT_REQUIRE_PREMIUM=true
  COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot

  TELEGRAM_API_ID=<api-id>
  TELEGRAM_API_HASH=<api-hash>
  TELEGRAM_PHONE=<premium-userbot-phone>

  OPENAI_API_KEY=<key>
  OPENAI_IMAGE_MODEL=gpt-image-2
  OPENAI_IMAGE_SIZE=1024x1024
  OPENAI_IMAGE_QUALITY=high

  COPYWRITING_RUNTIME_ROLE=copywriting-clubbot
  COPYWRITING_RUNTIME_HEARTBEAT_FILE=/tmp/copywriting-clubbot-heartbeat.json
  COPYWRITING_RUNTIME_HEARTBEAT_STALE_SECONDS=180

  CLUBBOT_TOKEN=<club-bot-token>
  CLUBBOT_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
  CLUBBOT_BACKEND_SECRET=<same-as-diaverseapi-CLUBBOT_INTERNAL_SECRET>
  CLUBBOT_CHAT_ID=-100...

  CLUBBOT_WEBHOOK_URL=https://<public-host>/clubbot/webhook
  CLUBBOT_WEBHOOK_SECRET_TOKEN=<random-secret>
  CLUBBOT_WEBHOOK_LISTEN=0.0.0.0
  CLUBBOT_WEBHOOK_PORT=8080
  CLUBBOT_WEBHOOK_PATH=clubbot/webhook
  CLUBBOT_ALLOWED_UPDATES=chat_join_request,chat_member,my_chat_member,message

  CLUBBOT_WELCOME_MESSAGE_THREAD_ID=
  CLUBBOT_REPORTS_MESSAGE_THREAD_ID=
  CLUBBOT_LEADERBOARD_MESSAGE_THREAD_ID=

  CLUBBOT_OUTBOX_WORKER_ID=clubbot-default
  CLUBBOT_OUTBOX_POLL_SECONDS=3
  CLUBBOT_OUTBOX_BATCH_SIZE=10
  CLUBBOT_OUTBOX_LEASE_SECONDS=60

  TELEGRAM_BOT_TOKEN_CLUB=

  TELEGRAM_BOT_TOKEN_CLUB РѕСЃС‚Р°РІР»СЏРµРј РїСѓСЃС‚С‹Рј, РµСЃР»Рё РЅРµ РЅСѓР¶РµРЅ fallback С‡РµСЂРµР· Bot API. РћСЃРЅРѕРІРЅР°СЏ РїСѓР±Р»РёРєР°С†РёСЏ
  Р»РёРґРµСЂР±РѕСЂРґР° РёРґС‘С‚ С‡РµСЂРµР· copywriting-userbot.

  5. Telegram

  Р’ РєР»СѓР±РЅРѕР№ supergroup РґРѕР»Р¶РЅС‹ Р±С‹С‚СЊ:

  - clubbot РєР°Рє bot account РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РґРµР№СЃС‚РІРёР№;
  - Premium userbot account РґР»СЏ РїСѓР±Р»РёРєР°С†РёРё РїРѕСЃС‚РѕРІ/РєР°СЂС‚РёРЅРѕРє;
  - clubbot РґРѕР»Р¶РµРЅ РёРјРµС‚СЊ admin-РїСЂР°РІР° РЅР° join requests, invite links Рё Р±СѓРґСѓС‰РёР№ removal flow;
  - userbot РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ СѓС‡Р°СЃС‚РЅРёРєРѕРј РіСЂСѓРїРїС‹ Рё СѓРјРµС‚СЊ РїРёСЃР°С‚СЊ РІ РЅСѓР¶РЅС‹Р№ topic;
  - Leaderboard thread РІ Р°РґРјРёРЅРєРµ = root message id РЅСѓР¶РЅРѕРіРѕ Telegram topic.

  6. Backup РїРµСЂРµРґ deploy

  РќР° 5.42.116.157:

  mkdir -p /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)
  cd /home/config
  cp .env /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)/diaverseapi.env
  docker compose -f docker-compose.yml ps

  РќР° 72.56.108.222:

  mkdir -p /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)
  cd /srv/aibot
  cp .env.production /root/deploy-backups/club-$(date +%Y%m%d-%H%M%S)/aibot.env.production
  docker compose -f docker-compose.prod.yml ps

  7. РћР±РЅРѕРІРёС‚СЊ aibot РЅР° 72.56.108.222

  ssh -i ~/.ssh/id_server_diaverse root@72.56.108.222
  cd /srv/aibot

  git status -sb
  git fetch origin
  git pull --ff-only origin dev

  Р•СЃР»Рё pull РЅРµ РїСЂРѕС…РѕРґРёС‚ РёР·-Р·Р° Р»РѕРєР°Р»СЊРЅС‹С… РёР·РјРµРЅРµРЅРёР№, РѕСЃС‚Р°РЅРѕРІРёС‚СЊСЃСЏ.

  РЎР±РѕСЂРєР°:

  docker compose -f docker-compose.prod.yml build copywriting-api copywriting-worker copywriting-userbot
  copywriting-clubbot

  РњРёРіСЂР°С†РёРё:

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
    sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    < migrations/20260519_0001_copywriting_club_benefits.sql

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
    sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    < migrations/20260519_0002_copywriting_club_leaderboard_assets.sql

  РџРµСЂРµР·Р°РїСѓСЃРє:

  docker compose -f docker-compose.prod.yml up -d copywriting-api
  docker compose -f docker-compose.prod.yml up -d copywriting-worker copywriting-userbot copywriting-
  clubbot

  РџСЂРѕРІРµСЂРєР°:

  docker compose -f docker-compose.prod.yml ps
  docker logs --tail=120 copywriting-api
  docker logs --tail=120 copywriting-worker
  docker logs --tail=120 copywriting-userbot
  docker logs --tail=120 copywriting-clubbot

  docker compose -f docker-compose.prod.yml exec -T copywriting-clubbot \
    python scripts/runtime_probe.py heartbeat \
    --file /tmp/copywriting-clubbot-heartbeat.json \
    --max-age 180

  curl -fsS http://127.0.0.1:8090/internal/v1/health

  8. РЎРѕР·РґР°С‚СЊ publish target РІ aibot DB

  Р—Р°РјРµРЅРёС‚СЊ -1001234567890 РЅР° club chat id, 12345 РЅР° root message id РЅСѓР¶РЅРѕРіРѕ topic.

  cd /srv/aibot

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres psql \
    -U copywriting \
    -d copywriting <<'SQL'
  INSERT INTO copywriting_publish_targets (
    id,
    name,
    target_type,
    destination_ref,
    status,
    is_enabled,
    config_json,
    created_by_user_id,
    updated_by_user_id
  )
  VALUES (
    gen_random_uuid(),
    'Club leaderboard',
    'telegram',
    '-1001234567890',
    'active',
    true,
    '{
      "publish_transport": "userbot",
      "club_profile": "club",
      "message_thread_id": 12345,
      "caption_limit": 1024
    }'::jsonb,
    'deploy',
    'deploy'
  )
  ON CONFLICT (target_type, destination_ref)
  DO UPDATE SET
    name = EXCLUDED.name,
    status = 'active',
    is_enabled = true,
    config_json = EXCLUDED.config_json,
    updated_by_user_id = 'deploy',
    updated_at = now();
  SQL

  9. РћР±РЅРѕРІРёС‚СЊ diaverseapi РЅР° 5.42.116.157

  РўРѕР»СЊРєРѕ РїРѕСЃР»Рµ СЂРµС€РµРЅРёСЏ dirty worktree.

  ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157
  cd /home/diaverse

  git status -sb
  git fetch origin
  git checkout dev
  git pull --ff-only origin dev

  РџСЂРѕРІРµСЂРёС‚СЊ С„Р°Р№Р»С‹:

  test -f app/club/admin_api.py
  test -f app/club/aibot_client.py
  test -f app/club/leaderboards.py
  test -f migrations/versions/20260519_club_domain.py

  РњРёРіСЂР°С†РёРё Рё СЂРµСЃС‚Р°СЂС‚:

  cd /home/config
  docker compose -f docker-compose.yml run --rm migrate
  docker compose -f docker-compose.yml --profile build build app-image
  docker compose -f docker-compose.yml up -d api worker scheduler
  docker compose -f docker-compose.yml ps
  docker logs --tail=120 diaverse-api-1
  docker logs --tail=200 diaverse-api-1 | grep -E 'club\.security|club internal|clubbot|tg outbox' || true

  Health:

  curl -fsS https://api.dev.diaverse.app/v1/health || true
  curl -fsS https://api2.dev.diaverse.app/v1/health || true

  10. РћР±РЅРѕРІРёС‚СЊ diaweb РЅР° 5.42.116.157

  ssh -i ~/.ssh/id_server_diaverse root@5.42.116.157
  cd /home/diaweb

  git status -sb
  git fetch origin
  git pull --ff-only origin dev

  docker-compose.dev-traefik.yml РЅРµ СѓРґР°Р»СЏС‚СЊ.

  РџСЂРѕРІРµСЂРёС‚СЊ env:

  grep -E '^(COPYWRITING_API_URL|COPYWRITING_INTERNAL_JWT_SECRET|COPYWRITING_INTERNAL_JWT_ISSUER|
  COPYWRITING_INTERNAL_JWT_AUDIENCE)=' frontend/.env.production

  Р”РѕР»Р¶РЅРѕ Р±С‹С‚СЊ:

  COPYWRITING_API_URL=http://10.0.0.1:8090/internal/v1
  COPYWRITING_INTERNAL_JWT_SECRET=<same-as-aibot-COPYWRITING_INTERNAL_JWT_SECRET>
  COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
  COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api
  COPYWRITING_INTERNAL_JWT_TTL_SECONDS=300

  РЎР±РѕСЂРєР° Рё СЂРµСЃС‚Р°СЂС‚:

  docker compose -f docker-compose.dev-traefik.yml build diaweb
  docker compose -f docker-compose.dev-traefik.yml up -d diaweb
  docker logs --tail=120 diaweb-dev

  РћС‚РєСЂС‹С‚СЊ:

  https://dev.diaverse.app/ru/staff/club

  11. РќР°СЃС‚СЂРѕР№РєР° РІ Р°РґРјРёРЅРєРµ

  РћС‚РєСЂС‹С‚СЊ:

  /staff/club/settings

  Р—Р°РїРѕР»РЅРёС‚СЊ:

  Telegram chat id = -100...
  Leaderboard thread = root message id РЅСѓР¶РЅРѕРіРѕ topic
  Aibot target profile = club
  Leaderboard image style = club_leaderboard
  Leaderboard image enabled = enabled

  РџРѕС‚РѕРј РЅР°Р¶Р°С‚СЊ validation. РћР¶РёРґР°РµРјРѕ:

  aibot_configured=true
  aibot preflight ok=true
  destination_ref_configured=true
  publish_transport=userbot
  topic_strategy=reply_to_message_id

  12. Smoke test

  1. РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ СЂР°Р±РѕС‚Р°СЋС‚ copywriting-api, copywriting-worker, copywriting-userbot, copywriting-clubbot,
     diaverse-api-1, diaweb-dev.
  2. Р’ /staff/club/settings РІС‹РїРѕР»РЅРёС‚СЊ validation.
  3. Р’ /staff/club/members РґРѕР±Р°РІРёС‚СЊ С‚РµСЃС‚РѕРІРѕРіРѕ manual member РёР»Рё РІР·СЏС‚СЊ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РµРіРѕ.
  4. РЈР±РµРґРёС‚СЊСЃСЏ, С‡С‚Рѕ РµСЃС‚СЊ step rows / user activities.
  5. Р’ /staff/club/leaderboards РЅР°Р¶Р°С‚СЊ build.
  6. Р—Р°РїСЂРѕСЃРёС‚СЊ AI image.
  7. Р”РѕР¶РґР°С‚СЊСЃСЏ image_status=ready.
  8. РќР°Р¶Р°С‚СЊ publish.
  9. РЈРІРёРґРµС‚СЊ publish_status=queued РёР»Рё publishing.
  10. РџСЂРѕРІРµСЂРёС‚СЊ docker logs --tail=120 copywriting-userbot.
  11. РќР°Р¶Р°С‚СЊ Refresh status.
  12. Р”РѕР¶РґР°С‚СЊСЃСЏ publish_status=published Рё Telegram message ids.
  13. РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ РїРѕСЃС‚ РїРѕСЏРІРёР»СЃСЏ РІ РїСЂР°РІРёР»СЊРЅРѕРј Telegram topic РѕС‚ userbot account.

  13. Р•СЃР»Рё С‡С‚Рѕ-С‚Рѕ РЅРµ СЂР°Р±РѕС‚Р°РµС‚

  aibot_configured=false: РїСЂРѕРІРµСЂРёС‚СЊ CLUB_AIBOT_BASE_URL Рё РѕРґРёРЅР°РєРѕРІС‹Р№ CLUB_AIBOT_SIGNING_SECRET.

  Invalid service auth: СЂР°Р·РЅС‹Рµ HMAC secrets, clock skew, proxy СЂРµР¶РµС‚ X-Diaverse-*.

  РќРµС‚ СЃРѕР±С‹С‚РёР№ РѕС‚ copywriting-clubbot: РїСЂРѕРІРµСЂРёС‚СЊ CLUBBOT_BACKEND_BASE_URL, СЂР°РІРµРЅСЃС‚РІРѕ CLUBBOT_BACKEND_SECRET
  Рё CLUBBOT_INTERNAL_SECRET, СЃРјРѕС‚СЂРµС‚СЊ copywriting-clubbot logs РїРѕ update_id, command_id, worker_id,
  request_id, Рё backend logs РїРѕ [club.security].

  publish_target_missing: РЅРµС‚ enabled row РІ copywriting_publish_targets, РЅРµРїСЂР°РІРёР»СЊРЅС‹Р№ club_profile, target
  РЅРµ telegram РёР»Рё РІС‹РєР»СЋС‡РµРЅ.

  publish_status=queued РІРёСЃРёС‚: РЅРµ СЂР°Р±РѕС‚Р°РµС‚ copywriting-userbot, РЅРµРІРµСЂРЅС‹Р№ queue, userbot session РЅРµ
  Р°РІС‚РѕСЂРёР·РѕРІР°РЅР°, userbot РЅРµ РІ РіСЂСѓРїРїРµ/topic.

  image_status=generating РІРёСЃРёС‚: РЅРµ СЂР°Р±РѕС‚Р°РµС‚ copywriting-worker, РЅРµС‚ OPENAI_API_KEY, РЅРµС‚
  OPENAI_IMAGE_MODEL, РЅРµС‚ РїСЂР°РІ РЅР° copywriting_generated_images.

  РџРѕСЃС‚ РЅРµ РІ С‚РѕР№ С‚РµРјРµ: РЅРµРїСЂР°РІРёР»СЊРЅС‹Р№ Leaderboard thread; РЅСѓР¶РµРЅ root message id topic.



CLUB_AIBOT_SIGNING_SECRET <secret-aibot-diaverseapi>
CLUBBOT_INTERNAL_SECRET <secret-clubbot-diaverseapi>

Р”Р»СЏ webhook token <secret-webhook-token>

# diaverseapi
CLUB_ACTIVE_PROGRAM_CODE=main
CLUBBOT_INTERNAL_SECRET=<secret-clubbot-diaverseapi>
CLUBBOT_SIGNATURE_TOLERANCE_SECONDS=300

CLUB_TG_OUTBOX_BATCH_SIZE=50
CLUB_TG_OUTBOX_MAX_ATTEMPTS=5
CLUB_TG_OUTBOX_RETRY_BASE_SECONDS=30
CLUB_TG_OUTBOX_STALE_LEASE_SECONDS=300

CLUB_SILENCE_THRESHOLD_DAYS=2
CLUB_SILENCE_SCAN_BATCH_SIZE=500

CLUB_AIBOT_BASE_URL=http://10.0.0.1:8090
CLUB_AIBOT_SIGNING_SECRET=<secret-aibot-diaverseapi>
CLUB_AIBOT_TIMEOUT_SECONDS=10

CLUB_AIBOT_LEADERBOARD_IMAGE_PATH=/internal/club/leaderboards/image
CLUB_AIBOT_LEADERBOARD_PUBLISH_PATH=/internal/club/leaderboards/publish
CLUB_AIBOT_LEADERBOARD_STATUS_PATH=/internal/club/leaderboards/assets/{asset_id}
CLUB_AIBOT_LEADERBOARD_PREFLIGHT_PATH=/internal/club/leaderboards/preflight





# aibot
CLUB_AIBOT_SIGNING_SECRET=<secret-aibot-diaverseapi>
CLUB_AIBOT_SIGNATURE_MAX_SKEW_SECONDS=300

COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images

COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
COPYWRITING_USERBOT_PUBLISH_POLL_INTERVAL_SECONDS=2
COPYWRITING_USERBOT_REQUIRE_PREMIUM=true
COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot


COPYWRITING_RUNTIME_ROLE=copywriting-clubbot
COPYWRITING_RUNTIME_HEARTBEAT_FILE=/tmp/copywriting-clubbot-heartbeat.json
COPYWRITING_RUNTIME_HEARTBEAT_STALE_SECONDS=180

CLUBBOT_TOKEN=<club-bot-token>
CLUBBOT_BACKEND_BASE_URL=https://api.dev.diaverse.app/v1
CLUBBOT_BACKEND_SECRET=<secret-clubbot-diaverseapi>
CLUBBOT_CHAT_ID=-1003759564801

CLUBBOT_WEBHOOK_URL=https://<public-host>/clubbot/webhook
CLUBBOT_WEBHOOK_SECRET_TOKEN=<secret-webhook-token>
CLUBBOT_WEBHOOK_LISTEN=0.0.0.0
CLUBBOT_WEBHOOK_PORT=8080
CLUBBOT_WEBHOOK_PATH=clubbot/webhook
CLUBBOT_ALLOWED_UPDATES=chat_join_request,chat_member,my_chat_member,message

CLUBBOT_WELCOME_MESSAGE_THREAD_ID=
CLUBBOT_REPORTS_MESSAGE_THREAD_ID=
CLUBBOT_LEADERBOARD_MESSAGE_THREAD_ID=

CLUBBOT_OUTBOX_WORKER_ID=clubbot-default
CLUBBOT_OUTBOX_POLL_SECONDS=3
CLUBBOT_OUTBOX_BATCH_SIZE=10
CLUBBOT_OUTBOX_LEASE_SECONDS=60
