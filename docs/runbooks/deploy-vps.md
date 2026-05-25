# Deploy VPS Runbook

Да, уже есть основной runbook: [copywriting-production-runtime.md](C:\Users\Indigo\Desktop\diaverse\docs\runbooks\copywriting-production-runtime.md).

Ещё полезны:

- [copywriting-web-architecture.md](C:\Users\Indigo\Desktop\diaverse\docs\architecture\copywriting-web-architecture.md)
- [web-copywriting-service.md](C:\Users\Indigo\Desktop\diaverse\aibot\docs\web-copywriting-service.md)
- [diaweb-copywriting.conf](C:\Users\Indigo\Desktop\diaverse\docs\runbooks\nginx\diaweb-copywriting.conf)
- [frontend/.env.example](C:\Users\Indigo\Desktop\diaverse\diaweb\frontend.env.example)
- [aibot/.env.example](C:\Users\Indigo\Desktop\diaverse\aibot.env.example)

Ниже свожу всё в одну полную инструкцию для VPS.

**Что получится**

- `nginx` снаружи принимает `80/443`
- `diaweb` слушает только `127.0.0.1:3000`
- `copywriting-api`, `copywriting-worker`, `copywriting-userbot`, `copywriting-postgres` живут только во внутренней docker-сети
- браузер ходит только в `diaweb`
- `diaweb` по внутренней сети ходит в `copywriting-api`

**1. Что нужно на VPS**

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin nginx git certbot python3-certbot-nginx
sudo systemctl enable --now docker
sudo systemctl enable --now nginx
```

Если Docker ставишь через Docker CE, тоже ок. Главное, чтобы работали:

```bash
docker --version
docker compose version
nginx -v
```

**2. Куда положить репозитории**
Пример:

```bash
sudo mkdir -p /srv
cd /srv
git clone <repo-diaweb-url> diaweb
git clone <repo-aibot-url> aibot
```

Дальше в примерах буду использовать:

- `/srv/diaweb`
- `/srv/aibot`

**3. Подготовь frontend env**
Создай `/srv/diaweb/frontend/.env.production`.

Минимально нужно:

```env
NEXT_PUBLIC_API_URL=https://<адрес-diaverseapi>
NEXT_PUBLIC_TELEGRAM_BOT_NAME=<bot_name>

JWT_SECRET_KEY=<тот же JWT secret, что использует diaverseapi>
JWT_ALGORITHM=HS256

COPYWRITING_API_URL=http://copywriting-api:8090/internal/v1
COPYWRITING_INTERNAL_JWT_SECRET=<общий секрет между diaweb и aibot>
COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api
COPYWRITING_INTERNAL_JWT_TTL_SECONDS=60
COPYWRITING_REQUEST_TIMEOUT_MS=15000

NEXT_DEPLOYMENT_ID=release-2026-04-07
```

Критично:

- `JWT_SECRET_KEY` должен совпадать с backend `diaverseapi`, иначе staff-cookie не провалидируется.
- `COPYWRITING_INTERNAL_JWT_SECRET` должен совпадать в `diaweb` и `aibot`.

**4. Подготовь aibot env**
Создай `/srv/aibot/.env.production`.

Базовый пример:

```env
COPYWRITING_INTERNAL_JWT_SECRET=<тот же secret что и в diaweb>
COPYWRITING_INTERNAL_JWT_ISSUER=diaweb
COPYWRITING_INTERNAL_JWT_AUDIENCE=copywriting-api

COPYWRITING_PROVIDER=groq
COPYWRITING_FALLBACK_PROVIDER=openai
COPYWRITING_PROVIDER_MAX_ATTEMPTS=2

GROQ_API_KEY=<...>
OPENAI_API_KEY=<...>
OPENAI_MODEL=gpt-4o
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

TELEGRAM_BOT_TOKEN=<...>
TELEGRAM_API_ID=<...>
TELEGRAM_API_HASH=<...>
TELEGRAM_PHONE=<...>

LOG_LEVEL=INFO

COPYWRITING_SOURCE_RETENTION_DAYS=30
COPYWRITING_DEFAULT_EXPORT_FORMAT=md
```

И ещё добавь переменные, которые использует `docker-compose.prod.yml`, хотя их нет в `.env.example`:

```env
COPYWRITING_POSTGRES_DB=copywriting
COPYWRITING_POSTGRES_USER=copywriting
COPYWRITING_POSTGRES_PASSWORD=<сильный-пароль>
```

Важно:

- отдельный migrate-шаг сейчас не нужен: `aibot` на старте сам делает `CREATE EXTENSION vector` и `Base.metadata.create_all()`.
- если нужен ingest идей из Telegram, `TELEGRAM_API_ID/HASH/PHONE` обязательны.
- если нужен publish в Telegram, нужен `TELEGRAM_BOT_TOKEN`.

**5. Подними copywriting stack**
Сначала `aibot`:

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps
```

Это поднимет:

- `copywriting-postgres`
- `copywriting-api`
- `copywriting-worker`
- `copywriting-userbot`

**6. Подними diaweb**
Потом фронт:

```bash
cd /srv/diaweb
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps
```

`diaweb` автоматически использует ту же docker-сеть `copywriting_internal`.

**7. Настрой nginx**

На VPS:

```bash
sudo cp /srv/diaverse/docs/runbooks/nginx/diaweb-copywriting.conf /etc/nginx/sites-available/diaweb-copywriting.conf
sudo ln -s /etc/nginx/sites-available/diaweb-copywriting.conf /etc/nginx/sites-enabled/diaweb-copywriting.conf
```

Перед этим обязательно поправь в конфиге:

- `server_name cabinet.diaverse.app`
- пути к сертификатам
- если домен другой, замени его

Пример получения сертификата:

```bash
sudo certbot --nginx -d cabinet.diaverse.app
```

Потом:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

**8. Что должно быть открыто наружу**
Открыты только:

- `80`
- `443`

Не публикуй наружу:

- `3000`
- `8090`
- postgres-порт

Сейчас compose уже делает правильно:

- `diaweb` на `127.0.0.1:3000`
- `copywriting-api` без host port
- postgres без host port

**9. Smoke-check после деплоя**
Проверь фронт:

```bash
curl -fsS http://127.0.0.1:3000/api/health
```

Проверь внутренний API:

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml exec copywriting-api python scripts/runtime_probe.py api --url http://127.0.0.1:8090/internal/v1/health
```

Проверь BFF:

```bash
curl -i http://127.0.0.1:3000/api/staff/copywriting/briefs
```

Без staff-cookie тут `401`, и это нормально.

Проверь worker:

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml exec copywriting-worker python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-worker-heartbeat.json --max-age 90
docker compose -f docker-compose.prod.yml exec copywriting-worker python scripts/runtime_probe.py queue --database-url "$COPYWRITING_DATABASE_URL" --queue default --max-lag-seconds 300
```

Проверь userbot:

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml exec copywriting-userbot python scripts/runtime_probe.py heartbeat --file /tmp/copywriting-userbot-heartbeat.json --max-age 180
docker compose -f docker-compose.prod.yml exec copywriting-userbot python scripts/runtime_probe.py source-sync --database-url "$COPYWRITING_DATABASE_URL" --max-age-seconds 600
```

**10. Логи**

```bash
cd /srv/diaweb
docker compose -f docker-compose.prod.yml logs -f diaweb
```

```bash
cd /srv/aibot
docker compose -f docker-compose.prod.yml logs -f copywriting-api
docker compose -f docker-compose.prod.yml logs -f copywriting-worker
docker compose -f docker-compose.prod.yml logs -f copywriting-userbot
```

**11. Обновление**
Если выкатываешь новую версию:

```bash
cd /srv/aibot
git pull
docker compose -f docker-compose.prod.yml up -d --build

cd /srv/diaweb
git pull
docker compose -f docker-compose.prod.yml up -d --build

sudo nginx -t
sudo systemctl reload nginx
```

Порядок лучше такой:

1. `aibot`
2. `diaweb`
3. `nginx reload`, если трогал конфиг

**12. Rollback**
Если сломался внутренний copywriting:

```bash
cd /srv/aibot
git checkout <previous-commit-or-tag>
docker compose -f docker-compose.prod.yml up -d --build
```

Если сломался фронт/BFF:

```bash
cd /srv/diaweb
git checkout <previous-commit-or-tag>
docker compose -f docker-compose.prod.yml up -d --build
```

После rollback снова прогони:

- `/api/health`
- `runtime_probe.py api`
- `runtime_probe.py queue`
- `runtime_probe.py heartbeat`
- `runtime_probe.py source-sync`

**Итог**
Да, файл уже есть, основной это [copywriting-production-runtime.md](C:\Users\Indigo\Desktop\diaverse\docs\runbooks\copywriting-production-runtime.md), но он больше как ops-заметка. Для первого реального деплоя удобнее ориентироваться на инструкцию выше.

Если хочешь, я могу следующим сообщением собрать тебе ещё и:

- готовые шаблоны `frontend/.env.production`
- готовый шаблон `aibot/.env.production`
- exact checklist “перед запуском / после запуска” для твоего VPS.
