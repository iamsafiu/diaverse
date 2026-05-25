# Dev Site Deployment On The Dev Backend Server

This runbook documents the dev web deployment shape used on 2026-05-04.
It mirrors production, but points the web app at the dev backend:

```text
dev.diaverse.app      -> Traefik -> diaweb-dev:3000
api.dev.diaverse.app  -> Traefik -> diaverse-api-1:8000

Both application containers are attached to the external Docker network `webproxy`.
Traefik stores ACME certificates in `/home/config/letsencrypt/acme.json`.
```

Do not paste secrets into tickets, docs, or chat logs. Use sanitized commands when
debugging container config.

## Current Hosts

| Purpose | Hostname | Current IP |
| --- | --- | --- |
| Dev web | `dev.diaverse.app` | `5.42.116.157` |
| Dev API | `api.dev.diaverse.app` | `5.42.116.157` |

Verify DNS before deploying:

```bash
dig +short dev.diaverse.app
dig +short api.dev.diaverse.app
```

Both records should point to the same dev backend server.

## Server Prerequisites

On the dev backend server:

```bash
ssh root@5.42.116.157

docker --version
docker compose version
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker network inspect webproxy --format '{{range $id,$c := .Containers}}{{println $c.Name $c.IPv4Address}}{{end}}'
```

Expected shape:

- `diaverse_traefik` publishes `80` and `443`
- `diaverse-api-1` is attached to `webproxy`
- `webproxy` exists as an external Docker network
- `/home/config/.env` contains dev backend values

Check the non-secret backend values:

```bash
grep -E '^(API_URL|DOMAIN_NAME|COOKIE_DOMAIN|CABINET_PUBLIC_BASE_URL|CABINET_ACCESS_COOKIE_NAME|CABINET_REFRESH_COOKIE_NAME|CABINET_LEGACY_COOKIE_READ_ENABLED|ALGORITHM)=' /home/config/.env
```

Expected values:

```text
COOKIE_DOMAIN=.dev.diaverse.app
DOMAIN_NAME=dev.diaverse.app
API_URL=https://api.dev.diaverse.app
CABINET_PUBLIC_BASE_URL=https://dev.diaverse.app/
CABINET_ACCESS_COOKIE_NAME=access_token_dev
CABINET_REFRESH_COOKIE_NAME=refresh_token_dev
CABINET_LEGACY_COOKIE_READ_ENABLED=false
ALGORITHM=HS256
```

## GitHub Deploy Key

Use a repo-specific key so other SSH keys are not affected:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t ed25519 -f ~/.ssh/id_diaweb_github -C "diaweb-dev-server" -N ""
chmod 600 ~/.ssh/id_diaweb_github
chmod 644 ~/.ssh/id_diaweb_github.pub

cat ~/.ssh/id_diaweb_github.pub
```

Add the public key in GitHub:

```text
iamsafiu/diaweb -> Settings -> Deploy keys -> Add deploy key
Allow write access: off
```

Configure a host alias that uses only this key:

```bash
cat >> ~/.ssh/config <<'EOF'

Host github-diaweb
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_diaweb_github
  IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh -T git@github-diaweb
```

## First-Time Clone

```bash
cd /home

if [ ! -d /home/diaweb/.git ]; then
  git clone git@github-diaweb:iamsafiu/diaweb.git /home/diaweb
fi

cd /home/diaweb
git fetch origin dev
git switch dev || git switch -c dev --track origin/dev
git pull --ff-only origin dev
```

If the repo was cloned with HTTPS, switch only this repo to the deploy key:

```bash
cd /home/diaweb
git remote set-url origin git@github-diaweb:iamsafiu/diaweb.git
git config core.sshCommand "ssh -i ~/.ssh/id_diaweb_github -o IdentitiesOnly=yes"
git fetch origin dev
```

## Frontend Environment

Create `/home/diaweb/frontend/.env.production` from the dev backend env.
This command writes secrets into the env file but does not print them:

```bash
cd /home/diaweb

set -a
. /home/config/.env
set +a

install -m 600 /dev/null /home/diaweb/frontend/.env.production

cat > /home/diaweb/frontend/.env.production <<EOF
NEXT_PUBLIC_API_URL=https://api.dev.diaverse.app
NEXT_PUBLIC_AUTH_BOT_LOGIN_ENABLED=true
NEXT_PUBLIC_CABINET_ACCESS_COOKIE_NAME=${CABINET_ACCESS_COOKIE_NAME:-access_token_dev}
NEXT_PUBLIC_CABINET_REFRESH_COOKIE_NAME=${CABINET_REFRESH_COOKIE_NAME:-refresh_token_dev}
NEXT_PUBLIC_CABINET_LEGACY_COOKIE_READ_ENABLED=${CABINET_LEGACY_COOKIE_READ_ENABLED:-false}
NEXT_PUBLIC_TELEGRAM_BOT_NAME=${TELEGRAM_BOT_NAME:-diaverseauth_bot}
NEXT_PUBLIC_TELEGRAM_APP_NAME=diaverseweb

JWT_SECRET_KEY=${JWT_SECRET_KEY}
JWT_ALGORITHM=${ALGORITHM:-HS256}

COPYWRITING_API_URL=${COPYWRITING_API_URL:-http://10.0.0.1:8090/internal/v1}
COPYWRITING_INTERNAL_JWT_SECRET=${COPYWRITING_INTERNAL_JWT_SECRET:-$(openssl rand -hex 32)}
COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api
COPYWRITING_INTERNAL_JWT_TTL_SECONDS=60
COPYWRITING_REQUEST_TIMEOUT_MS=15000

NEXT_DEPLOYMENT_ID=dev-$(date +%Y%m%d%H%M%S)
EOF
```

## Dev Traefik Compose

Create `/home/diaweb/docker-compose.dev-traefik.yml`:

```bash
cat > /home/diaweb/docker-compose.dev-traefik.yml <<'YAML'
name: diaweb-dev

services:
  diaweb:
    container_name: diaweb-dev
    build:
      context: ./frontend
      dockerfile: Dockerfile
    env_file:
      - ./frontend/.env.production
    environment:
      NODE_ENV: production
      HOSTNAME: 0.0.0.0
      PORT: 3000
    expose:
      - "3000"
    restart: unless-stopped
    networks:
      - webproxy
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=webproxy"
      - "traefik.http.routers.diaweb-dev.rule=Host(`dev.diaverse.app`)"
      - "traefik.http.routers.diaweb-dev.entrypoints=https"
      - "traefik.http.routers.diaweb-dev.tls=true"
      - "traefik.http.routers.diaweb-dev.tls.certresolver=proxyresolver"
      - "traefik.http.services.diaweb-dev.loadbalancer.server.port=3000"
      - "traefik.http.routers.diaweb-dev-http.rule=Host(`dev.diaverse.app`)"
      - "traefik.http.routers.diaweb-dev-http.entrypoints=http"
      - "traefik.http.routers.diaweb-dev-http.middlewares=diaweb-dev-https-redirect"
      - "traefik.http.middlewares.diaweb-dev-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.middlewares.diaweb-dev-https-redirect.redirectscheme.permanent=true"
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:3000/api/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s

networks:
  webproxy:
    external: true
YAML
```

Start the app:

```bash
cd /home/diaweb
docker compose -f docker-compose.dev-traefik.yml config
docker compose -f docker-compose.dev-traefik.yml up -d --build
docker compose -f docker-compose.dev-traefik.yml ps
```

## Smoke Checks

Container health:

```bash
docker exec diaweb-dev node -e "fetch('http://127.0.0.1:3000/api/health').then(async r=>{console.log(r.status); console.log(await r.text())}).catch(e=>{console.error(e); process.exit(1)})"
```

HTTP redirect through Traefik:

```bash
curl -I -H 'Host: dev.diaverse.app' http://127.0.0.1/ru/
```

Public checks:

```bash
curl -I https://dev.diaverse.app/ru
curl -fsS https://dev.diaverse.app/api/health
curl -i https://api.dev.diaverse.app/
```

Expected results:

- `https://dev.diaverse.app/ru` returns `HTTP/2 200`
- `https://dev.diaverse.app/api/health` returns `{"status":"ok","service":"diaweb",...}`
- `https://api.dev.diaverse.app/` returns backend metadata JSON

TLS certificate check:

```bash
echo | openssl s_client -servername dev.diaverse.app -connect dev.diaverse.app:443 2>/dev/null \
  | openssl x509 -noout -issuer -subject -dates
```

Expected issuer is Let's Encrypt and subject is `CN = dev.diaverse.app`.

## Updating Dev Web

```bash
cd /home/diaweb
git fetch origin dev
git switch dev
git pull --ff-only origin dev
docker compose -f docker-compose.dev-traefik.yml up -d --build
curl -I https://dev.diaverse.app/ru
```

Do not run `docker compose ... --remove-orphans` from the backend project while
`diaweb-dev` is running. Compose may report `diaweb-dev` as an orphan because it
uses its own compose file in `/home/diaweb`.

## Traefik And ACME Recovery

The canonical Traefik mount should be:

```text
/home/config/letsencrypt -> /letsencrypt
/home/config/traefik.toml -> /traefik.toml
/var/run/docker.sock -> /var/run/docker.sock
```

Verify:

```bash
docker inspect diaverse_traefik --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
ls -la /home/config/letsencrypt
docker exec diaverse_traefik ls -la /letsencrypt
```

`/home/config/letsencrypt/acme.json` must exist and be mode `600`.

```bash
mkdir -p /home/config/letsencrypt
touch /home/config/letsencrypt/acme.json
chmod 600 /home/config/letsencrypt/acme.json
```

If Traefik was started with stale mounts, recreate only Traefik from the backend
compose file:

```bash
cd /home
docker compose -f config/docker-compose.yml up -d traefik
```

Then verify:

```bash
curl -I https://dev.diaverse.app/ru
grep -o 'dev.diaverse.app' /home/config/letsencrypt/acme.json | head
docker logs diaverse_traefik --tail 200 | grep -Ei 'dev\.diaverse\.app|acme|certificate|challenge|letsencrypt|error|unable|failed'
```

If the site returns a self-signed certificate immediately after a Traefik restart,
wait briefly and retry. Traefik may need to re-issue the certificate and append it
to `acme.json`.

## Rollback

Roll back only the dev web container:

```bash
cd /home/diaweb
git log --oneline -5
git checkout <previous-commit>
docker compose -f docker-compose.dev-traefik.yml up -d --build
curl -I https://dev.diaverse.app/ru
```

Return to the dev branch after the incident:

```bash
cd /home/diaweb
git switch dev
git pull --ff-only origin dev
```

If the backend is healthy but the web app is not, do not restart backend services
while investigating the frontend container.

## Sanitized Debug Commands

Use these commands when sharing diagnostics:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker network inspect webproxy --format '{{range $id,$c := .Containers}}{{println $c.Name $c.IPv4Address}}{{end}}'
docker inspect diaweb-dev --format '{{json .Config.Labels}}'
docker inspect diaweb-dev --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | sed -E 's/(SECRET|TOKEN|PASSWORD|KEY|DSN)=.*/\1=<redacted>/g'
```
