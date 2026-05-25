# Userbot Settings

• Да. Порядок такой.

  1. Обновить код на сервере

  cd /path/to/aibot
  git switch dev
  git pull --ff-only origin dev

  cd /path/to/diaweb
  git switch dev
  git pull --ff-only origin dev

  2. Обновить env aibot/.env.production

  Добавь/проверь:

  COPYWRITING_GENERATED_IMAGES_DIR=/var/lib/copywriting/generated_images
  COPYWRITING_USERBOT_SESSION_DIR=/var/lib/copywriting/userbot
  COPYWRITING_USERBOT_PUBLISH_QUEUE=userbot-publish
  COPYWRITING_USERBOT_PUBLISH_POLL_INTERVAL_SECONDS=2
  COPYWRITING_USERBOT_REQUIRE_PREMIUM=true

  TELEGRAM_API_ID=...
  TELEGRAM_API_HASH=...
  TELEGRAM_PHONE=+...

  Аккаунт TELEGRAM_PHONE должен быть Premium и админом канала с правом публиковать посты.

  3. Применить DB migration

  В aibot:

  docker compose -f docker-compose.prod.yml exec -T copywriting-postgres \
    psql -U copywriting -d copywriting \
    < migrations/20260514_0001_copywriting_publish_idempotency.sql

  Если у тебя другие POSTGRES_USER/DB, подставь их. Без этой миграции новая публикация упадет, потому что
  API ожидает copywriting_publish_events.idempotency_key.

  4. Пересобрать и поднять сервисы

  cd /path/to/aibot
  docker compose -f docker-compose.prod.yml up -d --build copywriting-api copywriting-worker copywriting-
  userbot

  cd /path/to/diaweb
  docker compose -f docker-compose.prod.yml up -d --build

  5. Первый login userbot-сессии

  Если session еще не авторизована, останови userbot и запусти probe интерактивно:

  cd /path/to/aibot
  docker compose -f docker-compose.prod.yml stop copywriting-userbot

  docker compose -f docker-compose.prod.yml run --rm --entrypoint python copywriting-userbot \
    scripts/telegram_userbot_publish_probe.py \
    --target-chat "-100TEST_CHANNEL_ID" \
    --caption-chars 3500 \
    --require-premium

  Pyrogram попросит код Telegram. После успешного probe:

  docker compose -f docker-compose.prod.yml up -d copywriting-userbot

  6. Настроить цель публикации

  В staff UI: Копирайтинг -> Настройки -> Цели публикации.

  Для новой цели:

  - type: telegram
  - destination: -100... или @channel
  - transport: userbot
  - caption limit: 4096
  - custom emoji: по необходимости

  Если цель уже существует с тем же destination_ref, UI может не создать дубль из-за unique constraint.
  Тогда обнови config в БД:

  UPDATE copywriting_publish_targets
  SET config_json = jsonb_build_object(
    'publish_transport', 'userbot',
    'caption_limit', 4096
  )
  WHERE target_type = 'telegram'
    AND destination_ref = '-100YOUR_CHANNEL_ID';

  Для premium emoji:

  UPDATE copywriting_publish_targets
  SET config_json = jsonb_build_object(
    'publish_transport', 'userbot',
    'caption_limit', 4096,
    'custom_emoji_map', jsonb_build_object(
      'crystal', jsonb_build_object(
        'alt', '💎',
        'custom_emoji_id', '1234567890123456789'
      )
    )
  )
  WHERE target_type = 'telegram'
    AND destination_ref = '-100YOUR_CHANNEL_ID';

  В тексте поста потом используешь {{emoji:crystal}}.

  7. Проверить работу

  Health:

  docker compose -f docker-compose.prod.yml exec copywriting-userbot \
    python scripts/runtime_probe.py heartbeat \
    --file /tmp/copywriting-userbot-heartbeat.json \
    --max-age 180

  docker compose -f docker-compose.prod.yml exec copywriting-userbot \
    python scripts/runtime_probe.py queue \
    --database-url "$COPYWRITING_DATABASE_URL" \
    --queue userbot-publish \
    --max-lag-seconds 300

  Потом в UI публикуешь approved draft. Ожидаемое поведение: сначала статус queued/processing, потом
  published, draft станет published только после фактической отправки userbot’ом.

─ Worked for 1m 08s ───────────────────────────────────────────────────────────────────────────────────────


› где взять id hash phone


• TELEGRAM_API_ID и TELEGRAM_API_HASH берутся в Telegram Developer Portal:

  1. Открой: https://my.telegram.org
  2. Войди по номеру телефона того аккаунта, который будет userbot’ом.
  3. Перейди в API development tools.
  4. Создай app, если еще нет:
      - App title: любое, например Diaverse Copywriting
      - Short name: любое латиницей, например diaverse_copywriting
      - Platform: можно Desktop или Other
  5. После создания увидишь:
      - api_id -> это TELEGRAM_API_ID
      - api_hash -> это TELEGRAM_API_HASH

  TELEGRAM_PHONE это номер этого же аккаунта в международном формате:

  TELEGRAM_API_ID=12345678
  TELEGRAM_API_HASH=abcdef1234567890abcdef1234567890
  TELEGRAM_PHONE=+79991234567

  Важно: это должен быть именно Premium аккаунт, который добавлен админом в канал. Код авторизации Pyrogram
  придет в Telegram на этот аккаунт при первом запуске probe/login.
