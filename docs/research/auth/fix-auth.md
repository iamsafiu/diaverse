# Auth Fix Research

Историческая заметка по мягкому переходу auth cookies.

## Что Изменилось

- Backend поддерживает настраиваемые cookie names: `CABINET_ACCESS_COOKIE_NAME`, `CABINET_REFRESH_COOKIE_NAME`.
- Legacy-чтение старых `access_token` / `refresh_token` включается только флагом `CABINET_LEGACY_COOKIE_READ_ENABLED=true`.
- При выдаче новых cookie backend также удаляет старые legacy-cookie, если имена отличаются.
- Frontend `proxy.ts`, cabinet layout и staff BFF читают env-specific cookie names.
- Добавлены тесты на два главных сценария: dev игнорирует prod legacy-cookie, prod умеет временно мигрировать legacy refresh-cookie.
- Миграции БД не нужны.

## Проверки

- `npm.cmd test -- __tests__/proxy.test.ts` - 14 passed.
- `npm.cmd run typecheck` - passed.
- `python -m pytest tests/test_cabinet_auth.py -q -k "cabinet_probe or cabinet_refresh or logout"` - 10 passed.
- `ruff check ...` по измененным backend-файлам - passed.
- Knowledge refresh не запускался в рамках этой исторической заметки.

## Как Включать

Dev:

```env
CABINET_ACCESS_COOKIE_NAME=access_token_dev
CABINET_REFRESH_COOKIE_NAME=refresh_token_dev
CABINET_LEGACY_COOKIE_READ_ENABLED=false

NEXT_PUBLIC_CABINET_ACCESS_COOKIE_NAME=access_token_dev
NEXT_PUBLIC_CABINET_REFRESH_COOKIE_NAME=refresh_token_dev
NEXT_PUBLIC_CABINET_LEGACY_COOKIE_READ_ENABLED=false
```

Prod на период мягкой миграции:

```env
CABINET_ACCESS_COOKIE_NAME=access_token_prod
CABINET_REFRESH_COOKIE_NAME=refresh_token_prod
CABINET_LEGACY_COOKIE_READ_ENABLED=true

NEXT_PUBLIC_CABINET_ACCESS_COOKIE_NAME=access_token_prod
NEXT_PUBLIC_CABINET_REFRESH_COOKIE_NAME=refresh_token_prod
NEXT_PUBLIC_CABINET_LEGACY_COOKIE_READ_ENABLED=true
```

Порядок деплоя для prod: сначала frontend с новыми именами и legacy-read `true`, потом backend с теми же именами и legacy-read `true`. После периода миграции можно выключить legacy-read в обоих местах: `false`.
