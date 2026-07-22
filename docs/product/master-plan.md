# Diaverse — Master Plan

# Личный кабинет (Web)

> Полное техническое задание senior/lead уровня.
> Каждая фаза реализации ссылается на этот документ как на источник истины.

Версия: 1.3
Дата: 2026-07-21
Статус: утверждён (архитектура обновлена)

---

> **Исторические архитектурные изменения v1.2 (2026-03-26; referral-пункты ниже заменены v1.3):**
> - Backend НЕ строится с нуля — расширяем существующий **diaverseapi** (отдельный репозиторий)
> - Единая база данных с мобильным приложением (PostgreSQL, SQLModel)
> - Новые модули для веб-кабинета живут в `diaverseapi/app/cabinet/`
> - Партнёрское дерево: прежнее решение о 5-уровневой структуре BotUser отменено в v1.3
> - Auth: существующий JWT + Telegram WebApp + httpOnly cookies для веба
> - Финансовый модуль отложен

> **Архитектурные изменения v1.3 (2026-07-21):**
> - Канонические правила Referral Structure V1 вынесены в [feature contract](../features/referral-structure.md) и [architecture decision](../architecture/referral-structure.md)
> - Единственный граф связей — `team_referral_chains`; отдельное пятиуровневое дерево по `BotUser` не создаётся
> - Referral Structure добавляется вокруг существующего графа без переписывания Teams/Fives, их команд и наград
> - Web входит в V1, mobile исключён и будет проектироваться отдельно
> - Referral economics больше не считается «отложенным» целиком: включение XDV/resource/DCR выполняется независимыми flags после verification gates

---

## 1. Продукт

**Diaverse Personal Cabinet** — веб-приложение личного кабинета с модульной архитектурой,
системой ролей (RBAC), партнёрской MLM-сетью и админ-панелью.
Веб-кабинет расширяет игровые возможности: управление игрой для сотрудников и администраторов.

Целевая аудитория:

- Пользователи мобильного приложения Diaverse (личный кабинет)
- Авторизованные пользователи веб-кабинета (реферальная структура без фиксированного ограничения в 2 линии)
- Сотрудники (управление системой)

---

## 2. Архитектура

### 2.1 Репозитории — два отдельных репо

Проект состоит из двух независимых репозиториев:

**1. diaweb** (фронтенд) — Next.js веб-приложение:

```
diaweb/
├── frontend/
│   ├── app/
│   │   └── [lang]/
│   │       ├── (landing)/   ← публичный лендинг
│   │       └── (cabinet)/   ← личный кабинет (guest-enabled public routes + auth-only sections)
│   │           ├── dashboard/
│   │           ├── profile/
│   │           ├── partners/
│   │           ├── content/
│   │           ├── team/
│   │           ├── tools/
│   │           ├── education/
│   │           ├── leaderboard/
│   │           ├── offers/
│   │           └── admin/
│   ├── modules/
│   │   ├── auth/            ← авторизация (frontend)
│   │   ├── cabinet/         ← layout кабинета (sidebar, nav)
│   │   ├── profile/
│   │   ├── partners/
│   │   ├── dashboard/
│   │   ├── content/
│   │   ├── team/
│   │   ├── tools/
│   │   ├── education/
│   │   ├── leaderboard/
│   │   ├── offers/
│   │   ├── admin/
│   │   ├── landing/         ← существующий лендинг
│   │   ├── layout/          ← header/footer лендинга
│   │   ├── modal/
│   │   ├── i18n/
│   │   └── policy/
│   ├── shared/
│   │   ├── api/             ← API client (fetch + httpOnly cookies)
│   │   ├── auth/            ← useAuth, usePermission hooks
│   │   ├── ui/              ← UI kit (Radix-based)
│   │   ├── animations/      ← GSAP утилиты
│   │   └── hooks/           ← общие хуки
│   ├── public/
│   ├── package.json
│   └── .env.example
├── docs/
│   ├── MASTER_PLAN.md       ← этот файл
│   └── PHASE_*.md           ← планы фаз
├── .ai-factory/
├── .github/workflows/
│   └── frontend.yml
├── CLAUDE.md
└── .gitignore
```

**2. diaverseapi** (бэкенд, отдельный репозиторий) — существующий FastAPI:

```
diaverseapi/                     ← ОТДЕЛЬНЫЙ РЕПОЗИТОРИЙ
├── app/
│   ├── main.py                  ← точка входа
│   ├── core/
│   │   ├── settings.py          ← конфигурация (Pydantic BaseSettings)
│   │   ├── database.py          ← SQLModel engine, async sessions
│   │   └── middleware.py        ← CORS, logging, rate limit
│   ├── security/                ← существующая аутентификация
│   │   ├── models.py            ← User, PrivilegedUser, UserAccounts
│   │   ├── backends.py          ← JWT creation/validation
│   │   ├── api.py               ← auth endpoints
│   │   └── dependecies.py       ← get_current_user dependency
│   ├── internal/                ← BotUser, Referral (партнёрская сеть)
│   ├── characters/              ← питомцы, эволюции
│   ├── clans/                   ← кланы
│   ├── activities/              ← шаги, фитнес
│   ├── ... (40+ существующих модулей)
│   │
│   └── cabinet/                 ← НОВЫЕ модули для веб-кабинета
│       ├── rbac/                ← система ролей (roles, permissions, user_roles)
│       ├── admin/               ← управление пользователями, ролями, игрой
│       ├── employee/            ← инструменты сотрудников
│       ├── content/             ← контент-менеджмент
│       ├── education/           ← обучающие модули
│       ├── leaderboard/         ← рейтинг
│       └── tools/               ← инструменты для партнёров
├── migrations/                  ← Alembic (247+ версий)
├── pyproject.toml
└── .env.example
```

> **Принцип:** diaweb отвечает только за фронтенд. Вся бизнес-логика, БД и API — в diaverseapi.
> Backend-разработка координируется с бэкенд-разработчиком.

### 2.2 Технологический стэк

| Слой         | Технология            | Версия | Назначение                    |
| ------------ | --------------------- | ------ | ----------------------------- |
| **Frontend** | Next.js (App Router)  | 16.x   | SSR/SSG, роутинг, middleware  |
| *(diaweb)*   | React                 | 19.x   | UI                            |
|              | TypeScript            | 5.x    | Типизация                     |
|              | Tailwind CSS          | 4.x    | Стилизация (CSS-first config) |
|              | GSAP                  | 3.x    | Анимации                      |
|              | Zustand               | latest | Client state (auth, UI)       |
|              | TanStack Query        | 5.x    | Server state, кэш, ретрай     |
|              | React Hook Form + Zod | latest | Формы + валидация             |
|              | Radix UI              | latest | Accessible UI primitives      |
| **Backend**  | Python                | 3.12+  | Runtime                       |
| *(diaverseapi,* | FastAPI            | 0.111+ | HTTP framework                |
| *отд. репо)* | SQLModel              | 0.x    | ORM (Pydantic + SQLAlchemy)   |
|              | Alembic               | latest | Миграции БД (247+ версий)     |
|              | Pydantic              | 2.x    | Валидация, сериализация       |
|              | Celery + FastStream   | latest | Background tasks, очереди     |
|              | Sentry                | latest | Error monitoring              |
| **Data**     | PostgreSQL            | 16     | Единая БД (общая с мобилкой)  |
|              | Redis                 | 7      | Кэш, очереди, rate limiting   |
| **Infra**    | Docker + Compose      | —      | Контейнеризация               |
|              | GitHub Actions        | —      | CI/CD (отдельные для FE и BE) |
|              | Nginx                 | —      | Reverse proxy (prod)          |
| **Quality**  | ESLint + Prettier     | —      | Frontend lint/format          |
|              | Vitest                | —      | Frontend unit tests           |
|              | Playwright            | —      | E2E tests                     |

> **Примечание:** Backend-стэк (Python, FastAPI, SQLModel) управляется в отдельном репозитории diaverseapi.
> Качество бэкенда (Ruff, pytest) — ответственность команды diaverseapi.

---

## 3. Система ролей (RBAC)

> **RBAC — новое расширение существующего diaverseapi.**
> В текущем бэке роли минимальны: `PrivilegedUser` (захардкоженные ID) + `ClanRole` (boss, soldier...).
> Новая RBAC-система реализуется в `diaverseapi/app/cabinet/rbac/` как отдельный модуль,
> не ломая существующую логику. Фактические таблицы используют префикс `cab_`, а административные
> эндпоинты вынесены в `diaverseapi/app/cabinet/admin/`.

### 3.1 Стартовые роли

| Роль         | Код          | Системная | Описание                                                 |
| ------------ | ------------ | --------- | -------------------------------------------------------- |
| Пользователь | `user`       | да        | Базовый доступ после регистрации                         |
| Партнёр      | `partner`    | да        | Реферальная программа, расширенная аналитика             |
| Сотрудник    | `employee`   | да        | Доступ к модулям, которые назначи суперадмин, управление |
| Суперадмин   | `superadmin` | да        | Полный доступ, назначение ролей, системные настройки     |

> Системные роли нельзя удалить через админку. Можно создавать кастомные роли.

### 3.2 Схема БД (RBAC)

> Таблица `users` уже существует в diaverseapi (UUID PK, tg_id, level, grade, coins, XDV и др.).
> RBAC-таблицы (`cab_roles`, `cab_permissions`, `cab_user_roles`, `cab_role_permissions`, `cab_audit_log`) — **новые**,
> добавляются через Alembic-миграции. `cab_user_roles.user_id` ссылается на существующую `users.uuid`.

```
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│    users     │     │   user_roles     │     │     roles      │
│ (EXISTING)   │     │   (NEW)          │     │   (NEW)        │
│──────────────│     │──────────────────│     │────────────────│
│ uuid (UUID)  │◄────│ user_id          │────▶│ id (UUID)      │
│ tg_user_id   │     │ role_id          │     │ name           │
│ username     │     │ granted_at       │     │ display_name   │
│ avatar_url   │     │ granted_by       │     │ description    │
│ level, grade │     └──────────────────┘     │ is_system      │
│ coins, xdv   │                              │ created_at     │
│ created_at   │                              └───────┬────────┘
│ updated_at   │                                      │
└──────────────┘                                      │
                                              ┌───────┴────────┐
┌──────────────┐     ┌──────────────────┐     │role_permissions│
│ permissions  │◄────│ permission_id    │─────│────────────────│
│──────────────│     │ role_id          │     │ role_id        │
│ id (UUID)    │     │ conditions (JSON)│     │ permission_id  │
│ resource     │     └──────────────────┘     │ conditions     │
│ action       │                              └────────────────┘
│ description  │
└──────────────┘

┌──────────────────┐
│   audit_log      │
│──────────────────│
│ id               │
│ user_id          │
│ action           │
│ resource         │
│ resource_id      │
│ old_value (JSON) │
│ new_value (JSON) │
│ ip_address       │
│ created_at       │
└──────────────────┘
```

### 3.3 Permissions (ресурс + действие)

| Resource          | Actions                                         | Пример                                                 |
| ----------------- | ----------------------------------------------- | ------------------------------------------------------ |
| `profile`         | `read`, `update`                                | Пользователь может читать и редактировать свой профиль |
| `users`           | `read`, `create`, `update`, `delete`, `list`    | Employee/Admin управляет пользователями                |
| `roles`           | `read`, `create`, `update`, `delete`, `assign`  | Admin назначает роли                                   |
| `referrals`       | `read`, `invite`, `claim`                       | Авторизованный пользователь видит свою структуру и награды |
| `referrals.review` | `read`, `decide`                               | Staff рассматривает отдельные review cases             |
| `referrals.risk`  | `read`, `manage`                                | Staff управляет risk holds по отдельному разрешению     |
| `finance`         | `read`, `list`, `export`                        | Просмотр начислений                                    |
| `finance.payouts` | `read`, `create`, `approve`                     | Управление выплатами                                   |
| `content`         | `read`, `create`, `update`, `delete`, `publish` | Контент-менеджмент                                     |
| `team`            | `read`, `list`                                  | Просмотр команды                                       |
| `tools`           | `read`, `use`                                   | Инструменты                                            |
| `education`       | `read`, `list`, `complete`                      | Обучающие модули                                       |
| `leaderboard`     | `read`                                          | Рейтинг                                                |
| `offers`          | `read`, `list`                                  | Просмотр каталога офферов                              |
| `offers.purchase` | `create`, `read`, `list`                        | Покупка и история покупок                              |
| `admin`           | `access`                                        | Доступ к админ-панели                                  |
| `admin.modules`   | `toggle`                                        | Включение/выключение модулей                           |
| `admin.settings`  | `read`, `update`                                | Системные настройки                                    |

### 3.4 Conditions (row-level access)

```json
// Пример: партнёр видит только СВОЮ структуру
{
  "role": "partner",
  "permission": "partners:read",
  "conditions": { "owner_only": true }
}

// Пример: employee видит ВСЮ структуру
{
  "role": "employee",
  "permission": "partners:read_all",
  "conditions": {}
}
```

### 3.5 Матрица доступа к модулям (стартовая)

| Модуль      | User    | Partner        | Employee      | Superadmin |
| ----------- | ------- | -------------- | ------------- | ---------- |
| Dashboard   | базовый | полный         | полный        | полный     |
| Profile     | своё    | своё           | своё + чужие  | всё        |
| Partners    | своя структура | своя структура | по granular referral permissions | всё |
| Finance     | -       | просмотр       | управление    | всё        |
| Content     | чтение  | чтение         | CRUD          | всё        |
| Team        | -       | -              | чтение        | всё        |
| Tools       | базовые | расширенные    | все           | все        |
| Leaderboard | чтение  | чтение         | чтение        | всё        |
| Offers      | каталог + покупка | каталог + покупка + бонусы за покупки рефералов | управление каталогом (через Mobile API) | всё |
| Admin       | -       | -              | ограниченный  | полный     |

### 3.6 Реализация Phase 1 (2026-04-01)

- Backend RBAC реализован в sibling-репозитории `diaverseapi` в модулях `app/cabinet/rbac/` и `app/cabinet/admin/`.
- Alembic-миграция `cab_rbac_001_add_cabinet_rbac_tables` создаёт таблицы `cab_roles`, `cab_permissions`, `cab_user_roles`, `cab_role_permissions`, `cab_audit_log`.
- `seed_rbac()` идемпотентно создаёт системные роли и permissions, связывает их матрицей доступа, назначает первого `superadmin` по `bot_user_id=80` и пропускает сидирование, если миграция ещё не применена.
- Cabinet auth flow добавляет `roles[]` в JWT access token и возвращает `roles: RoleRead[]` в `GET /v1/auth/me`.
- Реализованы административные эндпоинты `GET /v1/admin/users`, `GET /v1/admin/users/{user_id}`, `GET /v1/admin/roles`, `POST /v1/admin/users/{user_id}/roles`, `DELETE /v1/admin/users/{user_id}/roles/{role_id}`.
- Frontend зеркалит стартовую матрицу ролей в `frontend/shared/auth/index.ts`, а `frontend/proxy.ts` делает оптимистичную HS256-проверку JWT для `/staff/*`. Источник истины по доступам остаётся на backend.

---

## 4. Авторизация

### 4.1 Провайдеры (по приоритету)

| #   | Провайдер             | Фаза    | Описание                        |
| --- | --------------------- | ------- | ------------------------------- |
| 1   | Telegram Login Widget | Фаза 1  | Основной способ входа           |
| 2   | Email + password      | Фаза 3+ | Классическая авторизация        |
| 3   | Guest mode            | Фаза 1  | Ограниченный просмотр без входа + pending transfer после логина |

### 4.2 Auth Flow (Telegram)

> **Для веб-кабинета** используем Telegram Login Widget + httpOnly cookies через diaverseapi.
> В diaverseapi `x-platform` header определяет тип клиента:
>
> | x-platform | Метод авторизации | Клиент |
> |---|---|---|
> | `mobile` | Bearer token в Authorization header | Мобильное приложение |
> | `web` | Telegram WebApp init_data в Bearer | Telegram Mini App |
> | `cabinet` | httpOnly cookie `access_token` | Веб-браузер (этот кабинет) |
>
> **Важно:** `x-platform: web` — это Telegram Mini App, не веб-браузер. Для браузерного кабинета используется `x-platform: cabinet`.

```
Browser                    Frontend (Next.js)              Backend (diaverseapi)       DB
  │                              │                              │                      │
  │  1. Click "Войти через TG"  │                              │                      │
  │─────────────────────────────▶│                              │                      │
  │                              │                              │                      │
  │  2. Telegram Login Widget    │                              │                      │
  │◀─────────────────────────────│                              │                      │
  │                              │                              │                      │
  │  3. TG callback (hash+data) │                              │                      │
  │─────────────────────────────▶│                              │                      │
  │                              │  4. POST /v1/auth/telegram   │                      │
  │                              │     (x-platform: cabinet)    │                      │
  │                              │─────────────────────────────▶│                      │
  │                              │                              │  5. Validate hash    │
  │                              │                              │     (HMAC-SHA256)    │
  │                              │                              │                      │
  │                              │                              │  6. Find or create   │
  │                              │                              │     user             │
  │                              │                              │─────────────────────▶│
  │                              │                              │◀─────────────────────│
  │                              │                              │                      │
  │                              │                              │  7. Assign default   │
  │                              │                              │     role (user)      │
  │                              │                              │                      │
  │                              │  8. { access_token,          │                      │
  │                              │     refresh_token }          │                      │
  │                              │◀─────────────────────────────│                      │
  │                              │                              │                      │
  │  9. Set-Cookie: httpOnly,     │                              │                      │
  │     secure, samesite=lax     │                              │                      │
  │◀─────────────────────────────│                              │                      │
```

> **Примечание:** Backend (diaverseapi) устанавливает `Set-Cookie` header в ответе.
> Browser автоматически отправляет cookies при каждом запросе (`credentials: 'include'`).
> JavaScript не имеет доступа к токенам (защита от XSS).

#### Авто-регистрация через Telegram Login Widget

`POST /v1/auth/telegram` поддерживает три сценария:

1. **BotUser + User существуют** — стандартный логин (без изменений)
2. **BotUser есть, User нет** — создаёт User через `CreateUserUseCase`, привязывает через `LinkUserUseCase`, создаёт `UserDevice(device_id="cabinet:{tg_id}")`
3. **Ни BotUser, ни User** — создаёт BotUser, User, привязывает, создаёт UserDevice

Race condition при создании BotUser защищён UNIQUE constraint на `bot_users."Platform ID"` + retry SELECT при IntegrityError.

### 4.3 JWT-стратегия

| Параметр    | Access Token                    | Refresh Token                            |
| ----------- | ------------------------------- | ---------------------------------------- |
| Время жизни | 15 минут                        | 30 дней                                  |
| Хранение    | httpOnly cookie                 | httpOnly cookie                          |
| Payload     | user_id, roles[], permissions[] | user_id, token_family                    |
| Rotation    | —                               | при каждом refresh старый инвалидируется |
| Blacklist   | Redis SET                       | Redis SET                                |

### 4.4 Безопасность

- CORS: whitelist доменов (frontend origin only)
- CSP headers через Next.js middleware
- Rate limiting: 5 req/s на auth endpoints, 30 req/s общий
- HMAC-SHA256 валидация Telegram hash
- Refresh token rotation (защита от утечки)
- Audit log всех auth-событий (login, logout, token refresh, role change)
- Brute-force protection: блокировка после 10 неудачных попыток (15 мин)

---

## 5. Модули

### 5.1 Dashboard

Главная страница кабинета. Агрегированная статистика.

**UI-референс:** (см. docs/screenshot_dashboard.png)

- Приветствие: "Добро пожаловать, {name}"
- Обзор активности
- Карточки метрик: баланс ($), партнёры (кол-во), продукты
- Быстрые действия

**Backend API (в diaverseapi):**

```
GET /v1/cabinet/dashboard/summary
  → { balance, partners_count, products_count, recent_activity[] }
```

**Зависимости:** auth, partners (агрегат), существующие данные users/bot_users

---

### 5.2 Profile

Личные данные пользователя.

**Разделы:**

- Основные данные: имя, фото, email, телефон, Telegram
- Контакты: мессенджеры, соцсети
- Безопасность: смена пароля (когда будет email auth), активные сессии, 2FA (будущее)

**Backend API (в diaverseapi):**

> Частично уже реализовано: `GET /v1/auth/me`, `PATCH /v1/auth/me`.
> Cabinet расширяет профиль дополнительными полями и эндпоинтами.

```
GET    /v1/auth/me                       → существующий (профиль текущего юзера)
PATCH  /v1/auth/me                       → существующий (обновить данные)
POST   /v1/cabinet/profile/avatar        → загрузить аватар (S3)
GET    /v1/cabinet/profile/sessions      → активные сессии
DELETE /v1/cabinet/profile/sessions/:id  → завершить сессию
```

**Схема БД (существующая в diaverseapi):**

```
users (EXISTING — расширяем через миграции при необходимости)
  + phone (NEW)
  + bio (NEW)
  + social_links (JSON) (NEW)
  + settings (JSON)
  + last_login_at
  + last_login_ip
```

---

### 5.3 Partners (MLM)

Ключевой модуль для всех авторизованных non-guest пользователей, а не только для роли `partner`.

Канонические документы:

- [Referral Structure V1](../features/referral-structure.md) — продуктовые состояния, точные UTC-границы, активность, Mentor, rewards, risk и staff permissions;
- [Referral Structure Architecture](../architecture/referral-structure.md) — единый граф, additive schema, API/BFF и совместимость;
- [Referral Structure Rollout And Rollback](../runbooks/referral-structure-rollout.md) — независимые flags, canary gates, DCR/legacy порядок и non-destructive rollback.

**Зафиксированные решения:**

- `team_referral_chains` — единственный граф текущих и исторических связей; второго дерева по `BotUser`/полям `partner_id_level_*` не создаём.
- Referral-owned таблицы хранят rulesets, ссылки/claims, evidence, projections, entitlements, payment facts, risk/review и outbox, но не дублируют parent-child graph.
- Existing Teams/Fives остаётся защищённой границей: команды, reward logic, admin UI и team-rulesets в этой фазе не переписываются.
- Ссылка резервируется на семь дней, но связь создаётся только после явного согласия; server-side first-wins после auth.
- Активность требует Bronze I и не менее 2,500 server-accepted steps на трёх отдельных UTC-днях.
- V1 web включает “Моя структура” и отдельную staff console; mobile является явным non-goal.
- Legacy/team-compatible связи не получают ретроактивные V1/V2 rewards.
- XDV/resource/DCR economics включается независимыми flags только после migration, concurrency, reconciliation и regression gates.

---

### 5.4 Finance

> **СТАТУС: ОТЛОЖЕНО** — финансовый модуль не входит в текущую фазу разработки.
> В diaverseapi уже есть coins/XDV балансы в таблицах `users` и `bot_users`.
> Полноценный wallet/transactions/payouts модуль будет реализован позднее.

Финансовый модуль: доходы, выплаты, баланс.

**Функционал:**

- Баланс (текущий, доступный для вывода)
- История транзакций (начисления, выплаты, бонусы)
- Запрос на выплату
- Статус выплаты (pending → approved → paid / rejected)

**Backend API:**

```
GET  /api/v1/finance/balance          → текущий баланс
GET  /api/v1/finance/transactions     → история (пагинация, фильтры)
POST /api/v1/finance/payouts          → запрос на выплату
GET  /api/v1/finance/payouts          → список выплат
GET  /api/v1/finance/payouts/:id      → статус конкретной выплаты

# Employee/Admin:
PATCH /api/v1/finance/payouts/:id     → approve/reject выплату
GET   /api/v1/finance/reports         → отчёты
```

**Схема БД:**

```
wallets
├── id (UUID)
├── user_id (FK → users) UNIQUE
├── balance (decimal)
├── available (decimal)
├── frozen (decimal)
├── currency (varchar, default "USD")
└── updated_at

transactions
├── id (UUID)
├── wallet_id (FK → wallets)
├── type (enum: accrual, payout, bonus, referral, adjustment)
├── amount (decimal)
├── balance_after (decimal)
├── description (text)
├── metadata (JSON)
├── created_at

payouts
├── id (UUID)
├── user_id (FK → users)
├── amount (decimal)
├── method (enum: card, crypto, bank_transfer)
├── status (enum: pending, approved, processing, paid, rejected)
├── reviewed_by (FK → users, nullable)
├── reviewed_at
├── created_at
```

---

### 5.5 Content Factory

Управление контентом: статьи, материалы, задания.

**Функционал:**

- Лента контента (по категориям)
- Создание/редактирование (employee+)
- Публикация/черновики
- Медиа-файлы (S3)
- Задания для партнёров (выполнение → бонус)

**Backend API:**

```
GET    /api/v1/content                → лента (пагинация, фильтры по категории)
GET    /api/v1/content/:id            → конкретный контент
POST   /api/v1/content                → создать (employee+)
PATCH  /api/v1/content/:id            → редактировать
DELETE /api/v1/content/:id            → удалить
POST   /api/v1/content/:id/publish    → опубликовать

GET    /api/v1/tasks                  → список заданий
POST   /api/v1/tasks/:id/complete     → отметить выполнение
```

**Схема БД:**

```
content
├── id (UUID)
├── title (varchar)
├── slug (varchar) UNIQUE
├── body (text)                  ← markdown или JSON (rich text)
├── category (varchar)
├── status (enum: draft, published, archived)
├── author_id (FK → users)
├── media (JSON[])               ← [{url, type, alt}]
├── published_at
├── created_at
├── updated_at

tasks
├── id (UUID)
├── content_id (FK → content, nullable)
├── title (varchar)
├── description (text)
├── reward_amount (decimal)
├── status (enum: active, completed, expired)
├── deadline
├── created_at

task_completions
├── id (UUID)
├── task_id (FK → tasks)
├── user_id (FK → users)
├── proof (JSON)                 ← скриншот, ссылка и т.д.
├── status (enum: pending, approved, rejected)
├── reviewed_by (FK → users, nullable)
├── completed_at
```

---

### 5.6 Team

Просмотр команды / сотрудников.

**Backend API:**

```
GET /api/v1/team                     → список членов команды
GET /api/v1/team/:id                 → профиль члена команды
```

**Схема БД:** Использует `users` + `user_roles` с фильтрацией по role = employee.

---

### 5.7 Tools

Инструменты для партнёров (утилиты, калькуляторы, генераторы).

**Backend API:**

```
GET /api/v1/tools                    → список доступных инструментов
GET /api/v1/tools/:slug              → конкретный инструмент
```

**Схема БД:**

```
tools
├── id (UUID)
├── name (varchar)
├── slug (varchar) UNIQUE
├── description (text)
├── type (enum: calculator, generator, widget)
├── config (JSON)                ← параметры инструмента
├── min_role (varchar)           ← минимальная роль для доступа
├── is_active (bool)
├── sort_order (int)
├── created_at
```

---

### 5.8 Education

Обучающие модули: курсы, уроки, прогресс.

**Backend API:**

```
GET  /api/v1/education/courses           → список курсов
GET  /api/v1/education/courses/:id       → курс с уроками
GET  /api/v1/education/lessons/:id       → конкретный урок
POST /api/v1/education/lessons/:id/complete → отметить пройденным
GET  /api/v1/education/progress          → прогресс текущего юзера
```

**Схема БД:**

```
courses
├── id (UUID)
├── title (varchar)
├── description (text)
├── cover_url (varchar)
├── min_role (varchar)
├── sort_order (int)
├── is_published (bool)
├── created_at

lessons
├── id (UUID)
├── course_id (FK → courses)
├── title (varchar)
├── body (text)
├── media (JSON[])
├── sort_order (int)
├── duration_min (int)

user_progress
├── id (UUID)
├── user_id (FK → users)
├── lesson_id (FK → lessons)
├── completed_at
├── UNIQUE(user_id, lesson_id)
```

---

### 5.9 Leaderboard

Рейтинг партнёров по метрикам.

**Backend API:**

```
GET /api/v1/leaderboard                  → топ (пагинация)
GET /api/v1/leaderboard?period=month     → за период
GET /api/v1/leaderboard/my-position      → позиция текущего юзера
```

**Схема БД:**

```
leaderboard_snapshots
├── id (UUID)
├── user_id (FK → users)
├── period (enum: week, month, all_time)
├── period_start (date)
├── score (decimal)
├── rank (int)
├── metrics (JSON)              ← { referrals, revenue, tasks_completed }
├── created_at

Index: (period, period_start, rank)
```

> Пересчёт через background job (ежедневно / еженедельно).

---

### 5.10 Admin Panel

Централизованное управление системой. Доступ: employee (ограниченный), superadmin (полный).

**Функционал:**

- Управление пользователями (список, поиск, блокировка, назначение ролей)
- Управление ролями (CRUD, назначение permissions)
- Управление модулями (включение/выключение)
- Управление контентом (модерация)
- Управление выплатами (approve/reject)
- Системные настройки
- Audit log (просмотр)

**Backend API:**

```
# Users
GET    /api/v1/admin/users              → список (пагинация, поиск, фильтры)
GET    /api/v1/admin/users/:id          → детальный профиль
PATCH  /api/v1/admin/users/:id          → редактировать
POST   /api/v1/admin/users/:id/block    → заблокировать
POST   /api/v1/admin/users/:id/unblock  → разблокировать
POST   /api/v1/admin/users/:id/roles    → назначить роль

# Roles
GET    /api/v1/admin/roles              → список ролей
POST   /api/v1/admin/roles              → создать роль
PATCH  /api/v1/admin/roles/:id          → редактировать
DELETE /api/v1/admin/roles/:id          → удалить (не системные)
GET    /api/v1/admin/roles/:id/permissions → permissions роли
PUT    /api/v1/admin/roles/:id/permissions → обновить permissions

# Modules
GET    /api/v1/admin/modules            → список модулей и статусов
PATCH  /api/v1/admin/modules/:slug      → включить/выключить

# Audit
GET    /api/v1/admin/audit              → audit log (пагинация, фильтры)

# Settings
GET    /api/v1/admin/settings           → системные настройки
PATCH  /api/v1/admin/settings           → обновить настройки
```

**Схема БД:**

```
module_registry
├── id (UUID)
├── slug (varchar) UNIQUE         ← "partners", "finance", etc.
├── name (varchar)
├── is_enabled (bool)
├── config (JSON)
├── updated_at

system_settings
├── key (varchar) PRIMARY KEY
├── value (JSON)
├── description (text)
├── updated_at
├── updated_by (FK → users)
```

---

### 5.11 Offers (Shop)

> Implementation note (2026-04-12):
> Current web shop delivery uses `diaverseapi/app/cabinet/shop` as the backend
> facade and same-origin Next.js BFF routes at `frontend/app/api/cabinet/shop/*`.
> The live web shop now uses a multi-offer storefront model with:
> - sections for `pets`, `pet_skins`, `pilot_skins`, and `passes`
> - Step Pass Basic/Pro surfaced in the same catalog
> - new v2 endpoints: `GET /storefront` and `POST /checkout`
> - legacy `/catalog` and `/purchase` kept as compatibility adapters
> - guest-mode storefront access for `/{lang}/shop` with backend guest session support
> Authenticated users keep the `XDV` checkout rail.
> Guest users do not see `XDV` as purchasable and can initiate only external offers.
> Guest external checkout now creates pending entitlements that are imported after Telegram login.
> See `../features/cabinet/shop-web.md` for the implementation-facing summary.

Каталог офферов (товаров/услуг) с возможностью покупки. Данные и процессинг оплаты живут на стороне Mobile Backend. Diaweb выступает витриной и прокси.

**Архитектура интеграции (Вариант A):**

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Browser    │────────▶│ Diaweb       │────────▶│   Mobile     │
│   (Next.js)  │  API    │ Backend      │  HTTP   │   Backend    │
│              │◀────────│ (FastAPI)    │◀────────│   (source    │
│              │         │  прокси +    │         │    of truth) │
│              │         │  кэш + RBAC  │         │              │
└──────────────┘         └──────┬───────┘         └──────────────┘
                               │
                          Redis кэш
                         (каталог TTL 5m)
```

> **Принцип:** Mobile Backend — источник истины для товаров и оплаты.
> Diaweb Backend — прокси с кэшированием, RBAC и собственной бизнес-логикой (бонусы партнёрам за покупки рефералов).

**Функционал:**
- Каталог офферов (карточки, фильтры, категории)
- Страница оффера (описание, цена, медиа, CTA "Купить")
- Инициация покупки (перенаправление на оплату через Mobile Backend)
- История покупок пользователя
- Статус покупки / доставки / активации
- Партнёрские бонусы: начисление при покупке реферала (связь с Finance)

**Backend API (Diaweb → клиент):**

```
GET  /api/v1/offers                    → каталог (пагинация, фильтры, категории)
GET  /api/v1/offers/:id                → детали оффера
POST /api/v1/offers/:id/purchase       → инициировать покупку
GET  /api/v1/purchases                 → история покупок текущего юзера
GET  /api/v1/purchases/:id             → статус конкретной покупки
```

**Internal API (Diaweb Backend → Mobile Backend):**

```
GET  {MOBILE_API_URL}/offers              → каталог (проксируется + кэшируется в Redis)
GET  {MOBILE_API_URL}/offers/:id          → детали оффера
POST {MOBILE_API_URL}/offers/:id/purchase → инициировать покупку
GET  {MOBILE_API_URL}/purchases           → история покупок юзера
GET  {MOBILE_API_URL}/purchases/:id       → статус покупки

Headers:
  Authorization: Bearer {MOBILE_API_KEY}    ← service-to-service auth
  X-User-Id: {user_uuid}                    ← контекст пользователя
  X-Request-Id: {uuid}                      ← трассировка запросов
```

**Webhook (Mobile Backend → Diaweb):**

```
POST /api/v1/webhooks/mobile

Events:
  purchase.completed   → обновить статус, начислить бонус партнёру
  purchase.failed      → обновить статус, уведомить пользователя
  offer.updated        → инвалидировать Redis-кэш
  offer.deleted        → инвалидировать Redis-кэш

Validation: HMAC-SHA256 подпись в заголовке X-Webhook-Signature
Body: { event, payload, timestamp }
```

**Схема БД (локальная — только для кэша и бонусов):**

```
purchase_events
├── id (UUID)
├── user_id (FK → users)
├── external_purchase_id (varchar)   ← ID из Mobile Backend
├── offer_id (varchar)               ← ID оффера из Mobile Backend
├── offer_title (varchar)            ← снэпшот на момент покупки
├── amount (decimal)
├── status (enum: pending, completed, failed, refunded)
├── referral_bonus_paid (bool)       ← начислен ли бонус партнёру
├── webhook_data (JSON)              ← сырые данные последнего webhook
├── created_at
├── updated_at

Indexes:
  - btree ON user_id
  - btree ON external_purchase_id UNIQUE
  - btree ON status
```

**Что НЕ делает Diaweb:**
- Не хранит каталог товаров (только Redis-кэш, TTL 5 мин)
- Не процессит оплату (это Mobile Backend)
- Не управляет наличием / складом

**Ключевые решения:**
- Кэш каталога в Redis (TTL 5 мин), инвалидация по webhook
- Локальная таблица `purchase_events` для аудита и начисления партнёрских бонусов
- При покупке реферала → транзакция в `wallets` родительского партнёра (связь с модулем Finance)
- Graceful degradation: если Mobile Backend недоступен → показываем кэш + "оплата временно недоступна"
- Circuit breaker паттерн для HTTP-клиента к Mobile Backend

---

## 6. Интеграции

### 6.1 diaverseapi — единый бэкенд

> **Изменение v1.2:** diaverseapi — это и есть "Mobile Backend". Веб-кабинет подключается
> к тому же бэкенду напрямую, а не через прокси. Новые cabinet-эндпоинты добавляются
> в diaverseapi рядом с существующими.

diaverseapi обслуживает и мобильное приложение, и веб-кабинет. Разделение по `x-platform` header:
`mobile` (мобильное приложение), `web` (Telegram Mini App), `cabinet` (веб-браузер).

**Конфигурация:**

```
# backend/.env.example (дополнение)
MOBILE_API_URL=https://api.diaverse.app/internal/v1
MOBILE_API_KEY=<service-to-service token>
MOBILE_WEBHOOK_SECRET=<HMAC secret для валидации webhook>
```

**HTTP-клиент (`common/integrations/mobile.py`):**

```
Responsibilities:
  - Базовый httpx.AsyncClient с таймаутами (connect=5s, read=10s)
  - Автоматическое добавление auth headers
  - Retry logic (3 попытки, exponential backoff)
  - Circuit breaker (после 5 ошибок → fallback на кэш, cooldown 30s)
  - Structured logging всех запросов/ответов
  - Прокидывание X-User-Id и X-Request-Id
```

**Webhook-приёмник:**

```
Endpoint: POST /api/v1/webhooks/mobile
Security:
  - HMAC-SHA256 валидация (X-Webhook-Signature header)
  - IP whitelist (опционально, для prod)
  - Idempotency: по external_purchase_id (дублирующие events игнорируются)
Processing:
  - Async обработка (background task)
  - Retry при ошибке обработки (dead letter после 3 попыток)
```

### 6.2 Контракт между фронтендом и бэкендом

| Кто → Кому | Метод | Зачем |
|-------------|-------|-------|
| diaweb (Next.js) → diaverseapi | REST (fetch + httpOnly cookies) | Все данные через единый бэкенд |
| diaverseapi → diaweb | **—** | Бэкенд не вызывает фронтенд |
| Мобилка → diaverseapi | REST (Bearer JWT) | Мобильное приложение (существующие эндпоинты) |
| diaweb → БД напрямую | **НИКОГДА** | Фронт не общается с БД напрямую |

---

## 7. UI/UX

### 7.1 Layout кабинета

```
┌────────────────────────────────────────────────────────┐
│  Logo    [Diaverse]                    [Avatar] [▼]   │
├──────────┬─────────────────────────────────────────────┤
│          │                                             │
│ Sidebar  │  Page Header                               │
│          │  ─────────────────────                      │
│ Dashboard│                                             │
│ Profile  │  Tab Navigation (внутри раздела)            │
│ Partners │  ┌─────┬──────┬──────────┐                 │
│ Finance  │  │ Tab │ Tab  │   Tab    │                 │
│ Offers   │  └─────┴──────┴──────────┘                 │
│ Content  │                                             │
│ Team     │  ┌───────────┐  ┌───────────┐              │
│ Tools    │  │  Card     │  │  Card     │              │
│ Education│  │           │  │           │              │
│ Rating   │  └───────────┘  └───────────┘              │
│          │                                             │
│ ──────── │  ┌───────────────────────────┐              │
│ Admin    │  │  Data Table / Content     │              │
│          │  │                           │              │
│          │  └───────────────────────────┘              │
│          │                                             │
├──────────┴─────────────────────────────────────────────┤
│  Footer (minimal)                                      │
└────────────────────────────────────────────────────────┘
```

### 7.2 Дизайн-система

Основана на существующем лендинге:

| Token             | Значение                 | Использование     |
| ----------------- | ------------------------ | ----------------- |
| `--color-bg`      | `#0E001A`                | Основной фон      |
| `--color-white2`  | `#F2F2F2`                | Текст             |
| `--color-blue2`   | `#05A5C7`                | Акцент (cyan)     |
| `--color-pink2`   | `#FF5CF8`                | Акцент вторичный  |
| `--color-purple2` | `#C379F0`                | Акцент третичный  |
| `--color-surface` | `rgba(255,255,255,0.05)` | Карточки, sidebar |
| `--color-border`  | `rgba(5,165,199,0.2)`    | Границы           |

Шрифты: Jura (основной), Orbitron (заголовки/акценты)

### 7.3 Компоненты (UI Kit)

На базе Radix UI + кастомная стилизация:

- Button (primary, secondary, ghost, danger)
- Input, Textarea, Select, Checkbox, Radio
- Card, DataCard (с метрикой)
- Table (sortable, filterable, pagination)
- Modal, Dialog, Sheet (мобильное меню)
- Tabs, Accordion
- Badge, Tag, Status
- Avatar, AvatarGroup
- Toast (уведомления)
- Skeleton (loading states)
- EmptyState ("Coming soon" для заглушек)

### 7.4 Responsive

| Breakpoint | Layout                                              |
| ---------- | --------------------------------------------------- |
| < 768px    | Sidebar → Sheet (hamburger), single column          |
| 768-1024px | Collapsed sidebar (icons only), адаптивные карточки |
| > 1024px   | Full sidebar, multi-column grid                     |

---

## 8. Инфраструктура

### 8.1 Локальная разработка

> Backend (diaverseapi) запускается отдельно, со своим Docker Compose.
> Frontend (diaweb) работает как Next.js dev server и подключается к API.

```
Frontend (diaweb):
  next dev (:3000)  → подключается к diaverseapi по NEXT_PUBLIC_API_URL

Backend (diaverseapi, отдельный репо):
  uvicorn (:8000) + PostgreSQL (:5432) + Redis (:6379)
  → запускается локально (uvicorn) или через docker-compose в репо diaverseapi
```

### 8.2 CI/CD (GitHub Actions)

```
diaweb/frontend.yml:
  trigger: push/PR
  steps: install → lint (eslint) → typecheck (tsc) → test (vitest) → build

diaverseapi (отдельный репо):
  → свой CI/CD pipeline, управляется бэкенд-разработчиком
```

### 8.3 Environment

```
# diaweb/.env.example (frontend)
NEXT_PUBLIC_API_URL=http://localhost:8000/v1
NEXT_PUBLIC_TG_BOT_NAME=<bot_username>

# diaverseapi управляется отдельно — см. diaverseapi/.env.example
```

---

## 9. API-контракт

### 9.1 Общий формат ответов

```json
// Success
{
  "data": { ... },
  "meta": { "page": 1, "per_page": 20, "total": 150 }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Описание ошибки для пользователя",
    "details": [
      { "field": "email", "message": "Invalid format" }
    ]
  }
}
```

### 9.2 Пагинация

```
GET /api/v1/resource?page=1&per_page=20&sort=-created_at&filter[status]=active
```

### 9.3 Версионирование

Все эндпоинты под `/api/v1/`. При breaking changes — `/api/v2/`, старая версия живёт минимум 6 месяцев.

### 9.4 Cabinet RBAC API (реализовано)

> Для текущей интеграции с `diaverseapi` cabinet-роуты смонтированы под `/v1/*` без дополнительного префикса `/api`.

- `GET /v1/auth/me` возвращает `UserRead`, включая `roles[]`.
- `GET /v1/admin/users?page=1&per_page=20` возвращает `{ data, meta }` с ролями пользователя.
- `GET /v1/admin/users/{user_id}` возвращает детальную карточку пользователя с ролями.
- `GET /v1/admin/roles` возвращает список доступных ролей.
- `POST /v1/admin/users/{user_id}/roles` принимает `{ "role_id": "<uuid>" }`.
- `DELETE /v1/admin/users/{user_id}/roles/{role_id}` снимает роль и защищает от self-lock для системной роли текущего суперадмина.

---

## 10. Тестовая стратегия

| Уровень         | Инструмент               | Покрытие                 | Цель                        |
| --------------- | ------------------------ | ------------------------ | --------------------------- |
| Unit (backend)  | pytest                   | models, services, utils  | Бизнес-логика               |
| API (backend)   | pytest + httpx           | all endpoints            | Контракты                   |
| Unit (frontend) | Vitest + Testing Library | hooks, utils, components | UI-логика                   |
| E2E             | Playwright               | critical paths           | Auth → Dashboard → Partners |
| Contract        | openapi-typescript       | types                    | Фронт-бэк синхронизация     |

Минимальное покрытие: 70% backend, 50% frontend (на старте).

---

## 11. Фазы реализации (обзор)

| Фаза  | Название        | Что делаем                                                                                    | Результат                                                         |
| ----- | --------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| **1** | **Фундамент**   | Frontend setup, auth интеграция с diaverseapi, RBAC, layout кабинета, заглушки всех модулей   | Рабочий кабинет с авторизацией и навигацией                       |
| **2** | **Core модули** | Profile (полный), Partners (полный), Dashboard (полный)                                       | Рабочая партнёрская система с аналитикой                          |
| **3** | **Расширение**  | Finance, Offers (интеграция с Mobile Backend), Content Factory, Education                      | Контент, магазин и финансы                                         |
| **4** | **Polish**      | Team, Tools, Leaderboard, Admin (полный), E2E tests                                           | Все модули работают                                               |
| **5** | **Production**  | CI/CD prod, Nginx, Sentry, SSL, оптимизация, security audit                                   | Готов к деплою                                                    |

> Детальный план каждой фазы — в отдельном документе `docs/PHASE_N_*.md`

---

## 12. Открытые вопросы

| #   | Вопрос                                                 | Влияет на       | Дедлайн решения |
| --- | ------------------------------------------------------ | --------------- | --------------- |
| 1   | Celery vs ARQ для background tasks                     | backend infra   | до Фазы 2       |
| 2   | VPS vs managed cloud (деплой)                          | infra, CI/CD    | до Фазы 5       |
| 3   | WebSocket для real-time обновлений партнёрского дерева | partners module | до Фазы 2       |
| 4   | Rich text editor для Content Factory (Tiptap? Plate?)  | content module  | до Фазы 3       |
| 5   | S3-провайдер (Yandex Object Storage / MinIO / AWS)     | file upload     | до Фазы 2       |
| 6   | Формат API Mobile Backend (REST? GraphQL? Документация?) | offers module  | до Фазы 3       |
| 7   | Механизм оплаты: redirect на платёжку Mobile или встроенный iframe? | offers UX | до Фазы 3 |
| 8   | Процент партнёрского бонуса за покупку реферала        | finance + offers | до Фазы 3      |
---

## Appendix: Advent USD Paid Pricing (2026-04-16)

- Paid Advent cell price is canonical in `USD`.
- `CabAdventItem.price_amount` + `price_currency` remains the single business price for the cell.
- New payment rails must consume that canonical USD price instead of introducing rail-specific prices into Advent content.

Current rail policy:

- Active web payment rail: `pay1time`
- Provider charge currency: `RUB`
- Quote authority: backend only
- FX source: official Bank of Russia daily XML feed

Checkout quote policy:

```text
usd_price = canonical Advent paid price
usd_rub_rate = CBR USD/RUB rate
base_rub = usd_price * usd_rub_rate
gross_rub = base_rub / (1 - fee_rate)
provider_amount_minor = ceil(gross_rub * 100)
provider_amount = provider_amount_minor / 100
```

- Default `fee_rate`: `0.055`
- `payment_quote` snapshot is stored in checkout payload JSON and restored on status reads so users see the exact amount they were quoted before redirect.
- If FX quote creation fails, checkout init must stop before provider invoice creation and return a retryable error.

Live Advent update rule:

- Update the same published calendar line; do not replace the calendar for this pricing migration.
- Progress and claimed rewards remain valid because Advent ownership is keyed by `line_id + run_number + day_number`.
- Preferred production path is the dedicated backend updater command, not manual unpublish/edit/publish.
