# Конструктор календарей (Staff)

## Цель

Дать staff-интерфейсу возможность вручную собирать и публиковать версии календаря без правок кода:
- выбирать количество дней (`days_count`)
- задавать free/paid ячейки и стоимость
- заполнять награды по дням (multi-reward)
- настраивать run overrides (например для day 31)

Импорт наград намеренно не используется: все значения вводятся вручную.

## Frontend

Маршруты:
- `frontend/app/[lang]/staff/advent-calendars/page.tsx`
- `frontend/app/[lang]/staff/advent-calendars/[id]/page.tsx`
- legacy redirect: `frontend/app/[lang]/staff/admin/advent-calendars/*` → `/{lang}/staff/advent-calendars/*`

Навигация staff:
- `frontend/modules/staff/navigation.tsx` -> пункт `Advent Calendars`

Модуль:
- `frontend/modules/staff-advent/index.ts`

Компоненты:
- `frontend/modules/staff-advent/components/AdventCalendarList.tsx`
- `frontend/modules/staff-advent/components/AdventCalendarEditor.tsx`
- `frontend/modules/staff-advent/components/AdventDayRewardsEditor.tsx`
- `frontend/modules/staff-advent/components/AdventRunOverridesEditor.tsx`

## Backend API (diaverseapi)

CRUD/lifecycle:
- `GET /v1/admin/advent-calendars`
- `POST /v1/admin/advent-calendars`
- `GET /v1/admin/advent-calendars/{id}`
- `PATCH /v1/admin/advent-calendars/{id}`
- `POST /v1/admin/advent-calendars/{id}/clone-draft`
- `POST /v1/admin/advent-calendars/{id}/publish`
- `POST /v1/admin/advent-calendars/{id}/archive`

Редактор наполнения:
- `PUT /v1/admin/advent-calendars/{id}/days`
- `PUT /v1/admin/advent-calendars/{id}/overrides`

## Lifecycle

Поддержаны статусы:
- `draft`
- `published`
- `archived`

Правила:
- редактирование доступно для `draft`
- `publish` валидирует полноту и консистентность конфигурации
- активная опубликованная версия становится источником для игрока
- изменения published-версии делаются через `clone-draft`

## Логирование и reason-codes

Для клиентской диагностики приняты следующие принципы:
- frontend логирует `debug/info/warn/error` события конструктора и player-flow календаря
- claim-ошибки обрабатываются через `reason_code`
- backend возвращает machine-readable payload для `PAYMENT_REQUIRED`
