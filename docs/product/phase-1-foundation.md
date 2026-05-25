# Phase 1 — Фундамент

> Надплан над Master Plan. Определяет ЧТО делаем сейчас, на какую глубину,
> и в каком порядке. Каждый пункт ссылается на соответствующий раздел Master Plan.

Версия: 1.0
Дата: 2026-03-24
Статус: в работе

---

## Цель фазы

`docker-compose up` поднимает полностью рабочее окружение:
- Frontend с layout кабинета, навигацией и заглушками всех модулей
- Backend с auth (Telegram), RBAC и скелетом API
- PostgreSQL + Redis
- Авторизованный пользователь видит sidebar, может перемещаться по разделам

---

## Критерий завершения

```
✅ docker-compose up → frontend (:3000) + backend (:8000) + PG + Redis
✅ Telegram Login → JWT → redirect в кабинет
✅ RBAC: роли user/partner/employee/superadmin назначаются, guards работают
✅ Sidebar навигация по всем разделам (заглушки отвечают "Coming soon")
✅ Landing page работает как раньше (без регрессий)
✅ Все линтеры проходят (ESLint + Ruff)
✅ Backend: минимум 5 API тестов (auth + RBAC)
```

---

## Обзор глубины по модулям

| Модуль | Глубина | Что именно | Ссылка на Master Plan |
|--------|---------|------------|-----------------------|
| **Repo structure** | ПОЛНЫЙ | Монорепо миграция, git mv | §2.1 |
| **Docker** | ПОЛНЫЙ | Compose dev (4 сервиса) | §8.1 |
| **Auth** | ПОЛНЫЙ | Telegram OAuth + JWT pair + refresh rotation | §4 |
| **RBAC** | ПОЛНЫЙ | Таблицы + seeds + guards + middleware | §3 |
| **Cabinet layout** | ПОЛНЫЙ | Sidebar, header, responsive shell | §7.1 |
| **Profile** | КАРКАС | GET/PATCH /profile, базовая страница | §5.2 |
| **Admin** | КАРКАС | Список юзеров + назначение ролей | §5.10 |
| **Dashboard** | ЗАГЛУШКА | Страница + "Добро пожаловать, {name}" | §5.1 |
| **Partners** | ЗАГЛУШКА | Страница + роут API | §5.3 |
| **Finance** | ЗАГЛУШКА | Страница + роут API | §5.4 |
| **Offers** | ЗАГЛУШКА | Страница + базовый HTTP-клиент к Mobile | §5.11 |
| **Content** | ЗАГЛУШКА | Страница | §5.5 |
| **Team** | ЗАГЛУШКА | Страница | §5.6 |
| **Tools** | ЗАГЛУШКА | Страница | §5.7 |
| **Education** | ЗАГЛУШКА | Страница | §5.8 |
| **Leaderboard** | ЗАГЛУШКА | Страница | §5.9 |
| **CI/CD** | БАЗОВЫЙ | Lint-only pipeline (без тестов/билда) | §8.2 |

```
ПОЛНЫЙ   = реализуем полностью, production-ready
КАРКАС   = рабочий минимум + структура для расширения в следующих фазах
ЗАГЛУШКА = роут + страница + EmptyState("Coming soon") + пустой API router
БАЗОВЫЙ  = минимальная конфигурация, дорабатывается позже
```

---

## Порядок выполнения

### Step 0 — Подготовка репозитория
> Зависимости: нет

```
Действия:
  1. git mv текущих файлов в frontend/
     - app/ → frontend/app/
     - modules/ → frontend/modules/
     - shared/ → frontend/shared/
     - public/ → frontend/public/
     - package.json, package-lock.json → frontend/
     - tsconfig.json, next.config.ts → frontend/
     - postcss.config.mjs, eslint.config.mjs → frontend/
     - next-env.d.ts → frontend/
  2. Обновить @/* пути в tsconfig.json → относительные к frontend/
  3. Переместить .next/ в .gitignore (если не там)
  4. Создать структуру backend/ (пустую)
  5. Создать корневой .gitignore (объединить)
  6. Проверить: cd frontend && npm run build — должен пройти

Результат: монорепо структура, фронт собирается как раньше
```

---

### Step 1 — Docker Compose (dev)
> Зависимости: Step 0

```
Действия:
  1. Создать frontend/Dockerfile (dev: node:22-alpine, npm ci, next dev)
  2. Создать backend/Dockerfile (dev: python:3.12-slim, pip install, uvicorn --reload)
  3. Создать docker-compose.yml:
     - frontend (:3000) — volume mount для hot reload
     - backend (:8000) — volume mount для hot reload
     - db: postgres:16-alpine (:5432) — persistent volume
     - redis: redis:7-alpine (:6379)
  4. Создать backend/.env.example
  5. Создать frontend/.env.example
  6. Добавить .env в .gitignore
  7. Проверить: docker-compose up — все 4 сервиса стартуют

Результат: docker-compose up поднимает всё окружение
```

---

### Step 2 — Backend скелет
> Зависимости: Step 1

```
Действия:
  1. Инициализировать pyproject.toml:
     - dependencies: fastapi, uvicorn[standard], sqlalchemy[asyncio],
       asyncpg, alembic, pydantic-settings, pyjwt, redis, httpx, structlog
     - dev: pytest, httpx, ruff, mypy
  2. Создать backend/src/:
     - main.py — FastAPI app factory, lifespan, CORS, роутеры
     - config.py — pydantic-settings (DATABASE_URL, REDIS_URL, JWT_*, etc.)
     - database.py — async engine + sessionmaker + get_db dependency
  3. Создать backend/src/common/:
     - exceptions.py — единый формат ошибок {error: {code, message, details}}
     - middleware.py — RequestID, structured logging
     - pagination.py — PaginationParams dependency
     - guards.py — пустой (заполнится в Step 3)
     - audit.py — пустой (заполнится в Step 3)
     - integrations/mobile.py — базовый httpx клиент (конфиг из env, пока без вызовов)
  4. Инициализировать Alembic:
     - alembic init, настроить env.py на async
     - Подключить к DATABASE_URL из config
  5. Создать базовый healthcheck:
     - GET /api/v1/health → {status: "ok", version: "0.1.0"}
  6. Настроить Ruff (pyproject.toml секция [tool.ruff])
  7. Проверить: docker-compose up → curl localhost:8000/api/v1/health → 200

Результат: FastAPI запускается, отвечает на healthcheck, подключён к PG и Redis
```

---

### Step 3 — Auth + RBAC (backend)
> Зависимости: Step 2
> Ссылка: Master Plan §3, §4

```
Действия:

  A. Модели (Alembic миграция):
     - users: id(UUID), tg_id, email, display_name, avatar_url,
       phone, bio, social_links(JSON), settings(JSON),
       is_active, last_login_at, last_login_ip, created_at, updated_at
     - roles: id(UUID), name, display_name, description, is_system, created_at
     - permissions: id(UUID), resource, action, description
     - user_roles: user_id, role_id, granted_at, granted_by
     - role_permissions: role_id, permission_id, conditions(JSON)
     - audit_log: id, user_id, action, resource, resource_id,
       old_value(JSON), new_value(JSON), ip_address, created_at
     - Seed data: 4 системные роли + стартовые permissions (из Master Plan §3.3)

  B. Auth модуль (backend/src/modules/auth/):
     - schemas.py — TelegramAuthData, TokenPair, TokenPayload
     - service.py:
       * validate_telegram_hash(data, bot_token) → HMAC-SHA256
       * find_or_create_user(tg_data) → User
       * create_token_pair(user) → {access_token, refresh_token}
       * refresh_tokens(refresh_token) → new pair + blacklist old
       * blacklist_token(jti) → Redis SET
     - router.py:
       * POST /api/v1/auth/telegram → TokenPair
       * POST /api/v1/auth/refresh → TokenPair
       * POST /api/v1/auth/logout → blacklist tokens
       * GET  /api/v1/auth/me → текущий юзер с ролями
     - dependencies.py:
       * get_current_user(token) → User (из JWT, проверка blacklist)

  C. RBAC guards (backend/src/common/guards.py):
     - require_auth — базовая проверка токена
     - require_role("partner") — проверка роли
     - require_permission("resource", "action") — проверка permission с conditions
     - Кэширование permissions per-request (не per-call)

  D. Audit (backend/src/common/audit.py):
     - log_action(user, action, resource, resource_id, old, new)
     - Автоматический вызов при auth-событиях

  E. Тесты (backend/tests/):
     - conftest.py — test DB, test client, fixtures (user, admin)
     - test_auth.py:
       * test_telegram_login_valid_hash
       * test_telegram_login_invalid_hash → 401
       * test_refresh_token_rotation
       * test_blacklisted_token_rejected
       * test_me_returns_user_with_roles

Результат: полный auth flow + RBAC guards + 5 тестов проходят
```

---

### Step 4 — Stub API роутеры (backend)
> Зависимости: Step 3

```
Действия:
  Для каждого модуля создать минимальный роутер:

  backend/src/modules/{module}/
  ├── router.py    ← 1-2 эндпоинта, возвращают заглушки
  ├── schemas.py   ← минимальные Pydantic-модели
  └── __init__.py

  Модули и их заглушки:
  ┌──────────────┬──────────────────────────────────────────────┐
  │ users/       │ GET /api/v1/users/:id → 501 Not Implemented │
  │ profile/     │ GET /api/v1/profile → текущий юзер (реально)│
  │              │ PATCH /api/v1/profile → обновить (реально)   │
  │ partners/    │ GET /api/v1/partners/tree → 501              │
  │              │ GET /api/v1/partners/stats → 501             │
  │ finance/     │ GET /api/v1/finance/balance → 501            │
  │ offers/      │ GET /api/v1/offers → 501                     │
  │ content/     │ GET /api/v1/content → 501                    │
  │ team/        │ GET /api/v1/team → 501                       │
  │ tools/       │ GET /api/v1/tools → 501                      │
  │ education/   │ GET /api/v1/education/courses → 501          │
  │ leaderboard/ │ GET /api/v1/leaderboard → 501                │
  │ admin/       │ GET /api/v1/admin/users → список (реально)   │
  │              │ POST /api/v1/admin/users/:id/roles → (реально)│
  └──────────────┴──────────────────────────────────────────────┘

  Все роутеры подключить в main.py с prefix /api/v1
  Применить guards:
    - profile/* → require_auth
    - admin/* → require_role("employee") или require_role("superadmin")
    - partners/* → require_role("partner")

Результат: все API endpoints зарегистрированы, OpenAPI docs доступен на /docs
```

---

### Step 5 — Frontend: Cabinet layout + Auth
> Зависимости: Step 3 (backend auth работает)
> Ссылка: Master Plan §7.1

```
Действия:

  A. Установить зависимости:
     cd frontend && npm install zustand @tanstack/react-query zod

  B. Auth (frontend/modules/auth/):
     - context.tsx — AuthProvider (Zustand store)
       * user, isAuthenticated, isLoading
       * login(telegramData) → POST /auth/telegram → set cookies
       * logout() → POST /auth/logout → clear state
       * refresh() → POST /auth/refresh (автоматический)
     - components/TelegramLoginButton.tsx — Telegram Login Widget
     - components/LoginPage.tsx — страница входа

  C. Shared auth hooks (frontend/shared/auth/):
     - useAuth() — текущий юзер, isAuthenticated
     - usePermission(resource, action) → boolean
     - useRequireAuth() — redirect на /login если не авторизован

  D. API client (frontend/shared/api/):
     - client.ts — fetch wrapper с автоматическим refresh token
     - queryClient.ts — TanStack Query config

  E. Cabinet layout (frontend/modules/cabinet/):
     - components/CabinetLayout.tsx — sidebar + header + main area
     - components/Sidebar.tsx — навигация по модулям
       * Dashboard, Profile, Partners, Finance, Offers,
         Content, Team, Tools, Education, Leaderboard
       * Разделитель
       * Admin (видим только employee/superadmin)
       * Responsive: Sheet на мобильных, collapsed на планшетах
     - components/CabinetHeader.tsx — аватар, имя, dropdown (профиль, выход)
     - components/EmptyState.tsx — "Coming soon" компонент для заглушек

  F. Route groups (frontend/app/[lang]/):
     - (landing)/ — существующий лендинг (layout.tsx без sidebar)
       * page.tsx — текущая landing page
       * privacy-policy/page.tsx
       * terms/page.tsx
     - (cabinet)/ — личный кабинет (layout.tsx с CabinetLayout)
       * layout.tsx — CabinetLayout + AuthProvider + QueryProvider
       * dashboard/page.tsx → EmptyState + "Добро пожаловать, {name}"
       * profile/page.tsx → базовая форма (имя, аватар, телефон)
       * partners/page.tsx → EmptyState
       * finance/page.tsx → EmptyState
       * offers/page.tsx → EmptyState
       * content/page.tsx → EmptyState
       * team/page.tsx → EmptyState
       * tools/page.tsx → EmptyState
       * education/page.tsx → EmptyState
       * leaderboard/page.tsx → EmptyState
       * admin/page.tsx → таблица юзеров + кнопка "назначить роль"
     - login/page.tsx — страница входа через Telegram

  G. Next.js middleware (frontend/middleware.ts):
     - /[lang]/(cabinet)/* → проверка auth cookie, redirect на /login
     - /[lang]/login → если уже auth, redirect на /dashboard

Результат: авторизованный юзер видит кабинет с sidebar, заглушки на всех страницах
```

---

### Step 6 — Profile (каркас)
> Зависимости: Step 4 + Step 5

```
Действия:

  Backend (profile/ router уже есть из Step 4, расширяем):
    - GET /api/v1/profile → полные данные юзера
    - PATCH /api/v1/profile → обновить display_name, phone, bio, social_links

  Frontend (frontend/modules/profile/):
    - components/ProfileForm.tsx
      * React Hook Form + Zod validation
      * Поля: имя, телефон, био
      * Кнопка сохранить → PATCH /profile
    - components/ProfilePage.tsx
      * Аватар (пока без загрузки — будет в Phase 2)
      * ProfileForm
      * Секция "Безопасность" → заглушка

Результат: пользователь может редактировать своё имя/телефон/био
```

---

### Step 7 — Admin (каркас)
> Зависимости: Step 4 + Step 5

```
Действия:

  Backend (admin/ router уже есть из Step 4, расширяем):
    - GET /api/v1/admin/users → список юзеров (пагинация, поиск по имени)
    - GET /api/v1/admin/users/:id → детали юзера с ролями
    - POST /api/v1/admin/users/:id/roles → назначить роль
    - DELETE /api/v1/admin/users/:id/roles/:role_id → убрать роль
    - GET /api/v1/admin/roles → список всех ролей

  Frontend (frontend/modules/admin/):
    - components/UsersTable.tsx — таблица юзеров (имя, email, роли, дата)
    - components/UserDetail.tsx — карточка юзера + управление ролями
    - components/RoleAssignDialog.tsx — модалка назначения роли

Результат: superadmin может просматривать юзеров и назначать роли
```

---

### Step 8 — CI/CD (базовый)
> Зависимости: Step 2

```
Действия:

  .github/workflows/frontend.yml:
    trigger: push/PR → frontend/**
    steps:
      - checkout
      - setup node 22
      - npm ci (в frontend/)
      - npm run lint
      - npx tsc --noEmit

  .github/workflows/backend.yml:
    trigger: push/PR → backend/**
    steps:
      - checkout
      - setup python 3.12
      - pip install (из pyproject.toml)
      - ruff check src/
      - ruff format --check src/
      - pytest tests/ (с service PostgreSQL)

Результат: каждый PR проходит lint + typecheck + тесты
```

---

## Что НЕ делаем в Phase 1

Явный список того, что откладываем:

| Что | Почему | Когда |
|-----|--------|-------|
| Загрузка аватара (S3) | Нужен S3-провайдер (Open question #5) | Phase 2 |
| Партнёрское дерево (ltree) | Сложная логика, нужен отдельный фокус | Phase 2 |
| Dashboard метрики | Зависит от Partners + Finance | Phase 2 |
| Finance (транзакции, выплаты) | Требует продуманной схемы | Phase 3 |
| Offers (каталог, покупки) | Зависит от API Mobile Backend (Open question #6) | Phase 3 |
| Content Factory | Rich text editor (Open question #4) | Phase 3 |
| Education, Team, Tools, Leaderboard | Низкий приоритет | Phase 4 |
| Nginx, SSL, prod Dockerfile | Production-readiness | Phase 5 |
| E2E тесты (Playwright) | Нужен стабильный UI | Phase 4 |
| Sentry integration | Production monitoring | Phase 5 |
| Email auth | Дополнительный провайдер | Phase 3+ |
| WebSocket | Open question #3 | Phase 2+ |

---

## Порядок и зависимости (визуально)

```
Step 0: Repo migration
  │
  ▼
Step 1: Docker Compose ──────────────────────▶ Step 8: CI/CD (базовый)
  │
  ▼
Step 2: Backend скелет
  │
  ▼
Step 3: Auth + RBAC (backend)
  │
  ├──────────────────┐
  ▼                  ▼
Step 4: Stub APIs   Step 5: Cabinet layout + Auth (frontend)
  │                  │
  ├──────┬───────────┤
  ▼      ▼           │
Step 6: Profile     Step 7: Admin
```

**Параллельные потоки:**
- Step 4 и Step 5 можно делать параллельно (после Step 3)
- Step 6 и Step 7 можно делать параллельно (после Step 4 + Step 5)
- Step 8 можно делать параллельно с чем угодно (после Step 2)

---

## Оценка объёма

| Step | Компоненты | Новых файлов (примерно) |
|------|-----------|------------------------|
| 0 | git mv + configs | ~5 изменённых |
| 1 | Dockerfiles + compose | ~5 |
| 2 | FastAPI скелет | ~10 |
| 3 | Auth + RBAC + тесты | ~15 |
| 4 | Stub роутеры (11 модулей) | ~25 |
| 5 | Cabinet layout + auth (frontend) | ~20 |
| 6 | Profile каркас | ~5 |
| 7 | Admin каркас | ~5 |
| 8 | GitHub Actions | ~2 |
| **Итого** | | **~90 файлов** |
