# Copywriting Production Runtime

## Artifact map

- `C:\Users\Indigo\Desktop\diaverse\diaweb\docker-compose.prod.yml` runs the public `diaweb` container on `127.0.0.1:3000`
- `C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml` runs `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, and `copywriting-postgres`
- `C:\Users\Indigo\Desktop\diaverse\docs\runbooks\nginx\diaweb-copywriting.conf` is the repo copy of the host nginx site that should be installed as `/etc/nginx/sites-available/diaweb-copywriting.conf`

## Runtime topology

- Host nginx terminates TLS and proxies to `diaweb` on `127.0.0.1:3000`
- `diaweb` reaches `copywriting-api` over the shared Docker network `copywriting_internal`
- `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, and Postgres publish no host ports
- Persistent volumes:
  - `copywriting_postgres_data` for Postgres
  - `copywriting_userbot_session` for the Pyrogram session store
  - `copywriting_exports` for exported draft artifacts
  - `copywriting_generated_images` for generated draft images; mounted read-only into `copywriting-userbot` for Telegram publishing

## Bring-up order

1. Create production env files from the existing examples:
   - `C:\Users\Indigo\Desktop\diaverse\diaweb\frontend\.env.production`
   - `C:\Users\Indigo\Desktop\diaverse\aibot\.env.production`
2. Start copywriting first:
   - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml up -d --build`
3. Start diaweb:
   - `docker compose -f C:\Users\Indigo\Desktop\diaverse\diaweb\docker-compose.prod.yml up -d --build`
4. Install and enable nginx config:
   - copy `C:\Users\Indigo\Desktop\diaverse\docs\runbooks\nginx\diaweb-copywriting.conf` to `/etc/nginx/sites-available/diaweb-copywriting.conf`
   - create the symlink in `/etc/nginx/sites-enabled/`
   - run `nginx -t` and `systemctl reload nginx`

## Smoke checks

- Public app health:
  - `curl -fsS http://127.0.0.1:3000/api/health`
- Internal copywriting API health from its own container:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-api python scripts/runtime_probe.py api --url http://127.0.0.1:8090/internal/v1/health`
- BFF reachability through diaweb:
  - `curl -i http://127.0.0.1:3000/api/staff/copywriting/briefs`
  - expected result without a staff cookie: `401 Unauthorized`
- Worker heartbeat freshness:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-worker python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-worker-heartbeat.json --max-age 90`
- Queue lag / stale processing jobs:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-worker python scripts/runtime_probe.py queue --database-url "$COPYWRITING_DATABASE_URL" --queue default --max-lag-seconds 300`
- Userbot heartbeat freshness:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-userbot python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-userbot-heartbeat.json --max-age 180`
- Userbot publish queue lag:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-userbot python scripts/runtime_probe.py queue --database-url "$COPYWRITING_DATABASE_URL" --queue userbot-publish --max-lag-seconds 300`
- Userbot source-sync lag:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-userbot python scripts/runtime_probe.py source-sync --database-url "$COPYWRITING_DATABASE_URL" --max-age-seconds 600`
- Userbot Telegram publish smoke:
  - `docker compose -f C:\Users\Indigo\Desktop\diaverse\aibot\docker-compose.prod.yml exec copywriting-userbot python scripts/telegram_userbot_publish_probe.py --target-chat "$COPYWRITING_USERBOT_PROBE_CHAT_ID" --caption-chars 2000 --custom-emoji-id "$COPYWRITING_USERBOT_PROBE_CUSTOM_EMOJI_ID" --require-premium`

## Userbot publishing configuration

Production Telegram publish targets should use `config_json.publish_transport = "userbot"`. The legacy Bot API path remains available only for explicit `publish_transport = "bot"`.
Use `config_json.caption_limit = 2000` for userbot targets. This is the observed safe Premium userbot channel photo-caption limit; longer media posts are published as a photo followed by regular text chunks.

Required runtime settings:

- `COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot`
- `COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images`
- `COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish`
- `COPYWRITING_USERBOT_PUBLISH_POLL_INTERVAL_SECONDS=2`
- `COPYWRITING_USERBOT_REQUIRE_PREMIUM=true`

The `copywriting-api` request path only creates or reuses the publish event and job. The `copywriting-userbot` container owns Pyrogram delivery and marks the draft published after Telegram accepts the messages.

## Correlation and logging notes

- nginx forwards `X-Request-ID` from `$request_id`
- `diaweb` now prefers the incoming `X-Request-ID` and forwards it to `copywriting-api`
- `copywriting-api` already logs request lifecycle with `request_id`, `user_id`, and route metadata
- `copywriting-worker` and `copywriting-userbot` update dedicated heartbeat files so container health checks can detect stalled loops
- userbot publish logs should include `publish_event_id`, `job_id`, `publish_target_id`, queue, status, and Telegram message ids; they must not include raw post text, Telegram auth codes, API hash, bot tokens, or session file contents
