# AI Cofounder Foreign Server Runbook

## Scope

This runbook covers the private Diaverse AI Cofounder deployment on a foreign
server. It must stay an ops/content orchestrator:

- read approved aggregate APIs only
- create content drafts only
- report to Telegram with human approval
- keep bridge/admin surfaces on localhost or a reviewed private network
- never mount SSH keys, Docker socket, production database write DSNs, or payment
  provider credentials

## Server Layout

```text
/srv/diaverse-ai-cofounder/
|-- current -> releases/<git-sha>
|-- releases/
|   `-- <git-sha>/
|       |-- compose.yml
|       |-- .env.production -> ../../shared/.env.production
|       |-- config/
|       |   |-- allowlist.md -> ../../../shared/config/allowlist.md
|       |   `-- support-source.md -> ../../../shared/config/support-source.md
|       `-- secrets -> ../../shared/secrets
`-- shared/
    |-- .env.production
    |-- config/
    |   |-- allowlist.md
    |   `-- support-source.md
    `-- secrets/
        |-- ai_cofounder_tg_bot__default
        |-- diaverse_api__internal_token
        `-- diaverse_content__internal_jwt_secret
```

Runtime state is stored in Docker named volumes:

- `ai-cofounder-data` for SQLite and bridge sessions
- `ai-cofounder-outputs` for generated pipeline artifacts

Each release is immutable after unpacking. Only `shared/` is edited in place.

## Required Environment

Use `diaverse-ai-cofounder/infrastructure/foreign-server/ai-cofounder.env.example`
as the template. Required names:

```text
AI_COFUNDER_IMAGE
AI_COFUNDER_BRIDGE_PORT
AI_COFUNDER_TELEGRAM_DRY_RUN
LOG_LEVEL
DATABASE_URL
AI_COFUNDER_SECRET_PROVIDER
DIAVERSE_API_BASE_URL
DIAVERSE_CONTENT_API_URL
DIAVERSE_CONTENT_INTERNAL_JWT_ISSUER
DIAVERSE_CONTENT_INTERNAL_JWT_AUDIENCE
DIAVERSE_CONTENT_INTERNAL_JWT_SUBJECT
AIBOT_API_URL
```

Required secret files:

```text
shared/secrets/ai_cofounder_tg_bot__default
shared/secrets/diaverse_api__internal_token
shared/secrets/diaverse_content__internal_jwt_secret
```

Secret values must be files under `shared/secrets/`, not inline in the runbook,
shell history, docs, GitLab variables visible to broad roles, or Telegram.

## First-Time Setup

Run on the server as the deploy operator:

```bash
APP=/srv/diaverse-ai-cofounder
mkdir -p "$APP/releases" "$APP/shared/config" "$APP/shared/secrets"
chmod 700 "$APP/shared" "$APP/shared/secrets"
touch "$APP/shared/.env.production"
touch "$APP/shared/config/allowlist.md" "$APP/shared/config/support-source.md"
chmod 600 "$APP/shared/.env.production"
```

Populate `.env.production` from the repo example and create secret files with
the exact names above. `allowlist.md` must include only approved Telegram chats
for the founder bot. `support-source.md` can stay empty unless that ingestion
path is explicitly enabled.

## Deploy A Release

Create an archive from a reviewed commit and copy it to the server. Use
placeholders for the host and operator:

```bash
COMMIT=<reviewed-git-sha>
git -C diaverse-ai-cofounder archive --format=tar.gz -o "/tmp/diaverse-ai-cofounder-$COMMIT.tar.gz" "$COMMIT"
scp "/tmp/diaverse-ai-cofounder-$COMMIT.tar.gz" <operator>@<host>:/tmp/
```

On the server:

```bash
APP=/srv/diaverse-ai-cofounder
COMMIT=<reviewed-git-sha>
RELEASE="$APP/releases/$COMMIT"

mkdir -p "$RELEASE"
tar -xzf "/tmp/diaverse-ai-cofounder-$COMMIT.tar.gz" -C "$RELEASE"

ln -sfn "$APP/shared/.env.production" "$RELEASE/.env.production"
ln -sfn "$APP/shared/secrets" "$RELEASE/secrets"
mkdir -p "$RELEASE/config"
ln -sfn "$APP/shared/config/allowlist.md" "$RELEASE/config/allowlist.md"
ln -sfn "$APP/shared/config/support-source.md" "$RELEASE/config/support-source.md"

cd "$RELEASE"
docker compose --env-file .env.production config >/dev/null
docker compose --env-file .env.production build bridge migrate

if [ -L "$APP/current" ]; then
  cd "$APP/current"
  docker compose --env-file .env.production --profile telegram stop bot
  docker compose --env-file .env.production stop bridge
fi

cd "$RELEASE"
docker compose --env-file .env.production --profile ops run --rm migrate

ln -sfn "$RELEASE" "$APP/current"
cd "$APP/current"
docker compose --env-file .env.production up -d bridge
```

Start Telegram only after bridge health, secret loading, and allowlist checks:

```bash
docker compose --env-file .env.production --profile telegram up -d bot
```

The bridge port is published to host loopback only:

```text
127.0.0.1:${AI_COFUNDER_BRIDGE_PORT:-3737}
```

Use SSH tunneling or a private VPN for browser access. Do not publish the bridge
on a public interface.

## Smoke Checks

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production ps
curl -fsS http://127.0.0.1:${AI_COFUNDER_BRIDGE_PORT:-3737}/healthz
docker compose --env-file .env.production logs --tail=100 bridge
docker compose --env-file .env.production --profile telegram logs --tail=100 bot
```

Run one manual routine only after secrets and Telegram allowlist are confirmed:

```bash
AI_COFUNDER_ROUTINE_ID=diaverse-content-strategist \
  docker compose --env-file .env.production --profile ops run --rm routine
```

Generated content must appear as drafts in the content review surface. Telegram
approval is an internal gate and does not publish content.

## Disable Schedules

For Docker Compose runtime:

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production --profile telegram stop bot
```

For systemd timers, use the repo-local `docs/server-scheduling.md` instructions
and disable the specific `ai-cofounder-routine-<id>.timer`.

Stopping the bridge is a stronger pause that also disables the browser control
surface:

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production stop bridge
```

## Rotate Secrets

Prefer rotating the upstream service credential first, then replacing the file
used by AI Cofounder. For JWT secrets, keep a dual-acceptance window on the
receiving service when possible.

```bash
cd /srv/diaverse-ai-cofounder
install -m 600 /dev/null shared/secrets/<logical_secret_name>.next
vi shared/secrets/<logical_secret_name>.next
mv shared/secrets/<logical_secret_name>.next shared/secrets/<logical_secret_name>
```

Restart only the affected containers:

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production up -d bridge
docker compose --env-file .env.production --profile telegram up -d bot
```

Run smoke checks and verify logs mention only logical secret names, never values.

## Backup Journal DB

The SQLite journal lives in the `ai-cofounder-data` Docker volume at
`/data/ai-cofounder.db`. Quiesce writers before a filesystem backup:

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production --profile telegram stop bot
docker compose --env-file .env.production stop bridge

mkdir -p /srv/diaverse-ai-cofounder/backups
docker run --rm \
  -v diaverse-ai-cofounder_ai-cofounder-data:/data:ro \
  -v /srv/diaverse-ai-cofounder/backups:/backup \
  alpine sh -lc 'cp /data/ai-cofounder.db /backup/ai-cofounder-$(date -u +%Y%m%dT%H%M%SZ).db'

docker compose --env-file .env.production up -d bridge
```

Keep backups outside git and outside the public web root.

## Restore Journal DB

Restore only from a reviewed backup and only while containers are stopped:

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production --profile telegram stop bot
docker compose --env-file .env.production stop bridge

docker run --rm \
  -v diaverse-ai-cofounder_ai-cofounder-data:/data \
  -v /srv/diaverse-ai-cofounder/backups:/backup:ro \
  alpine sh -lc 'cp /backup/<backup-file>.db /data/ai-cofounder.db && chown 10001:10001 /data/ai-cofounder.db'

docker compose --env-file .env.production --profile ops run --rm migrate
docker compose --env-file .env.production up -d bridge
```

Do not restore a database backup across an incompatible code rollback unless the
rollback was explicitly tested with that backup.

## Rollback Code

```bash
APP=/srv/diaverse-ai-cofounder
PREVIOUS=<previous-reviewed-git-sha>

cd "$APP/current"
docker compose --env-file .env.production --profile telegram stop bot
docker compose --env-file .env.production stop bridge

ln -sfn "$APP/releases/$PREVIOUS" "$APP/current"
cd "$APP/current"
docker compose --env-file .env.production config >/dev/null
docker compose --env-file .env.production build bridge migrate
docker compose --env-file .env.production --profile ops run --rm migrate
docker compose --env-file .env.production up -d bridge
```

Start Telegram only after the health check passes:

```bash
docker compose --env-file .env.production --profile telegram up -d bot
```

The SQLite volume is preserved by default. If rollback requires old state too,
restore the journal DB from backup as a separate, explicit operation.

## Emergency Stop

```bash
cd /srv/diaverse-ai-cofounder/current
docker compose --env-file .env.production --profile telegram down
docker compose --env-file .env.production down
```

This stops containers but keeps named volumes. Remove volumes only after a
separate backup and explicit operator confirmation.
