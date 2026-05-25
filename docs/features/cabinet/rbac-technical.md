# Cabinet RBAC Technical Reference

Техническая документация: Система авторизации на основе ролей и прав доступа
Ветка реализации: feature/rbac-system

Этот документ фиксирует техническую схему RBAC после выполнения плана `feature-rbac-system.md`.
Он нужен как рабочая памятка для разработчиков `diaweb`, которые меняют frontend guards, admin UI, `proxy.ts`, `shared/api/*` или контракт с sibling-репозиторием `diaverseapi`.

Скоуп документа:

- ролевая модель кабинета в `diaweb`
- backend-контракт с `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
- RBAC-таблицы, сидирование, JWT `roles[]`
- admin API для управления ролями
- frontend hooks, shared types и route protection

Вне скоупа:

- mobile auth (`x-platform: mobile`)
- Telegram Mini App auth (`x-platform: web`)
- любые backend-модули вне `app/cabinet/{rbac,admin}` и связанных auth-изменений
- расширенная row-level логика поверх `conditions` в `cab_role_permissions`

## Источники

- план реализации: `.ai-factory/plans/feature-rbac-system.md`
- продуктовый контракт: `../../product/master-plan.md`
- краткий RBAC-гайд: `rbac-guide.md`
- пример структуры техдока: `auth-guide.md`
- frontend-реализация в этом репозитории: `frontend/shared/api/`, `frontend/shared/auth/`, `frontend/proxy.ts`, `frontend/modules/admin/`
- backend-реализация в sibling-репозитории: `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\rbac`, `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\admin`, `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\security`

## Ключевые решения

- Backend RBAC живёт не в `diaweb`, а в sibling-репозитории `diaverseapi`.
- Все новые RBAC-таблицы используют префикс `cab_`, чтобы не конфликтовать с существующей схемой.
- Access token теперь содержит `roles[]`, а `GET /v1/auth/me` возвращает роли в `UserRead`.
- Базовая роль `user` назначается при cabinet login, если у пользователя ещё нет ролей.
- Назначать и отзывать роли через API может только `superadmin`; `employee` имеет read-only доступ к admin listing endpoints.
- Frontend использует общие типы из `frontend/shared/api/types.ts` и зеркальную role-permission matrix в `frontend/shared/auth/index.ts`.
- `frontend/proxy.ts` делает role-based redirect для `/staff/*` только как UX guard; источником истины по доступам остаётся backend.

## Где находится логика

### Frontend (`diaweb`)

| Файл                                                     | Роль                                                                          |
| -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `frontend/modules/auth/context.tsx`                      | Zustand store, `fetchUser()`, нормализация cabinet user                       |
| `frontend/shared/api/types.ts`                           | общие типы `Role`, `Permission`, `AuthUser`, `AdminUser`, `CabinetMeResponse` |
| `frontend/shared/api/index.ts`                           | публичный экспорт shared API types и helpers                                  |
| `frontend/shared/api/client.ts`                          | единый fetch wrapper, `x-platform: cabinet`, cookie auth, auto-refresh        |
| `frontend/shared/auth/index.ts`                          | `useAuth`, `usePermission`, `useHasRole`, `useRequireAuth`                    |
| `frontend/proxy.ts`                                      | locale redirect, auth gate, staff role redirect через HS256 JWT verify        |
| `frontend/modules/admin/components/UsersTable.tsx`       | список пользователей admin panel                                              |
| `frontend/modules/admin/components/UserDetail.tsx`       | детальная карточка пользователя, удаление ролей                               |
| `frontend/modules/admin/components/RoleAssignDialog.tsx` | назначение роли через `POST /v1/admin/users/{user_id}/roles`                  |
| `frontend/modules/staff/components/StaffLayout.tsx`      | client-side fallback guard для staff interface                                |

### Backend (`diaverseapi`, отдельный репозиторий)

| Файл                                                          | Роль                                                                                                      |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `app/cabinet/rbac/models.py`                                  | SQLModel tables `cab_roles`, `cab_permissions`, `cab_user_roles`, `cab_role_permissions`, `cab_audit_log` |
| `app/cabinet/rbac/schemas.py`                                 | `RoleRead`, `PermissionRead`, `UserRoleRead`, read-схемы RBAC                                             |
| `app/cabinet/rbac/service.py`                                 | `RbacService` для assign/revoke/check/list логики                                                         |
| `app/cabinet/rbac/dependencies.py`                            | `get_rbac_service`, `require_role`, `require_permission`                                                  |
| `app/cabinet/rbac/seed.py`                                    | системные роли, permissions, матрица, bootstrap superadmin                                                |
| `app/cabinet/admin/service.py`                                | orchestration admin use cases + audit logging                                                             |
| `app/cabinet/admin/api.py`                                    | `/v1/admin/*` endpoints                                                                                   |
| `app/security/backends.py`                                    | `create_access_token(..., roles=...)`                                                                     |
| `app/security/schemas.py`                                     | `UserRead.roles`                                                                                          |
| `app/security/services.py`                                    | подтягивание ролей в `UserRead`                                                                           |
| `app/security/api.py`                                         | cabinet auth flow, refresh/dev-login/merge token issuance с ролями                                        |
| `migrations/versions/cab_rbac_001_add_cabinet_rbac_tables.py` | Alembic-миграция RBAC-схемы                                                                               |
| `tests/test_cabinet_rbac_models.py`                           | model tests                                                                                               |
| `tests/test_cabinet_rbac_service.py`                          | service tests                                                                                             |
| `tests/test_cabinet_admin_api.py`                             | admin API tests                                                                                           |

## Ролевая модель и схема БД

### Системные роли

- `user` — базовый доступ к кабинету
- `partner` — доступ к партнёрскому разделу и аналитике
- `employee` — доступ к staff-интерфейсу и служебным разделам
- `superadmin` — полный доступ и управление ролями

### RBAC-таблицы

Реализованы пять таблиц:

- `cab_roles`
- `cab_permissions`
- `cab_user_roles`
- `cab_role_permissions`
- `cab_audit_log`

Ключевые детали:

- `cab_user_roles` использует composite primary key `(user_id, role_id)`.
- `cab_role_permissions` использует composite primary key `(role_id, permission_id)`.
- `cab_role_permissions.conditions` пока хранит задел под future row-level rules.
- `cab_audit_log.old_value` и `cab_audit_log.new_value` хранятся как JSON и используются admin-слоем при assign/revoke.

### Миграция

RBAC-схема добавлена миграцией `cab_rbac_001_add_cabinet_rbac_tables.py`.
Это additive-изменение: существующие таблицы не переписываются, а новая схема добавляется рядом.

## Seed и bootstrap

`seed_rbac()` вызывается из `app/main.py` при старте backend.

Что он делает:

- создаёт системные роли из `SYSTEM_ROLES`
- создаёт permissions из `PERMISSIONS`
- связывает роли с permissions через `ROLE_PERMISSION_MATRIX`
- выдаёт `superadmin` пользователю с `bot_user_id=80`, если такой пользователь существует

Важные свойства:

- seed идемпотентный: повторный запуск не дублирует записи
- перед сидированием проверяется наличие таблиц `cab_*`
- если миграция ещё не применена, seed логирует skip и не ломает startup

Практический вывод:

- после добавления нового `resource:action` нужно обновлять `PERMISSIONS`
- после добавления новой роли или прав нужно обновлять и backend seed, и frontend `ROLE_PERMISSIONS`

## Поток получения ролей в сессии

### JWT и `/v1/auth/me`

Backend расширяет access token массивом `roles[]`.
Frontend использует эти роли двумя путями:

- backend возвращает их в `GET /v1/auth/me`
- `proxy.ts` при наличии `JWT_SECRET_KEY` валидирует JWT на Edge и читает `roles[]` для `/staff/*`

### Cabinet login

В `telegram_widget_login()` backend:

1. находит или создаёт пользователя
2. вызывает `assign_default_role(user.uuid)`, если ролей ещё нет
3. выпускает access token с актуальными role names
4. выставляет `httpOnly` cookies

Это работает и для новых пользователей, и как graceful migration path для уже существующих пользователей без ролей.

### Другие точки выпуска токена

Роли также прокидываются в access token при:

- `POST /v1/auth/dev-login`
- `POST /v1/auth/refresh`
- `POST /v1/auth/link-telegram/approve`

## Backend-контракт, от которого зависит frontend

### Auth contract

`frontend/modules/auth/context.tsx` не ожидает wrapper вида `{ data: ... }` для `GET /v1/auth/me`.
Сейчас frontend нормализует сырой ответ через `normalizeCabinetUser()`.

Минимальный shape, на который реально опирается frontend:

```ts
{
  uuid: string;
  username: string | null;
  tg_user_id: number | null;
  avatar_url: string | null;
  roles: Array<{
    id: string;
    name: string;
    display_name: string;
    is_system: boolean;
    description: string | null;
  }>;
}
```

Важно:

- backend может возвращать больше полей, чем использует frontend
- ломать поля `uuid`, `username`, `tg_user_id`, `avatar_url`, `roles[]` без синхронного обновления frontend нельзя

### Admin API contract

| Endpoint                                           | Доступ                   | Что ожидает frontend                                          |
| -------------------------------------------------- | ------------------------ | ------------------------------------------------------------- |
| `GET /v1/admin/users?page=1&per_page=20`           | `employee`, `superadmin` | `{ data, meta }`, где `data` — `AdminUser[]`                  |
| `GET /v1/admin/users/{user_id}`                    | `employee`, `superadmin` | `{ data: AdminUser }`                                         |
| `GET /v1/admin/roles`                              | `employee`, `superadmin` | `{ data: Role[] }`                                            |
| `POST /v1/admin/users/{user_id}/roles`             | `superadmin`             | body `{ role_id: string }`, response `{ data: UserRoleRead }` |
| `DELETE /v1/admin/users/{user_id}/roles/{role_id}` | `superadmin`             | response `{ data: { user_id, role_id } }`                     |

Важная деталь:

- self-lock защита запрещает текущему админу снимать у самого себя любую системную роль, а не только `superadmin`

## Frontend flow после загрузки пользователя

### Shared types

`frontend/shared/api/types.ts` теперь является единым источником правды для RBAC-типов.

Ключевые интерфейсы:

- `Role`
- `Permission`
- `UserBase`
- `AuthUser`
- `AdminUser`
- `CabinetMeResponse`

`normalizeCabinetUser()` мапит backend response в `AuthUser`, который хранится в Zustand store.

### Auth store

`frontend/modules/auth/context.tsx` хранит:

- `user`
- `isAuthenticated`
- `isLoading`
- `login()`
- `logout()`
- `fetchUser()`

Нюансы:

- `login()` только переключает локальный флаг; токены живут в `httpOnly` cookies
- `fetchUser()` — единственная точка гидрации user-объекта в кабинете
- `logout()` очищает локальный state после `POST /v1/auth/logout`

### UI hooks и guards

`frontend/shared/auth/index.ts` даёт:

- `useAuth()` для чтения auth state
- `usePermission(resource, action)` для role-based UI gating
- `useHasRole(...roles)` как хелпер для page/layout checks
- `useRequireAuth()` для client-side redirect

Важно:

- `usePermission()` не читает backend permissions напрямую
- он использует зеркальную матрицу `ROLE_PERMISSIONS`, которую нужно держать синхронной с backend seed
- `superadmin` обрабатывается через wildcard `*:*`

### Staff route protection

Сейчас защита staff-раздела двухслойная:

- `frontend/proxy.ts` делает ранний redirect на `/{lang}/offers`, если у пользователя нет `employee` или `superadmin`
- `frontend/modules/staff/components/StaffLayout.tsx` повторно проверяет роли на клиенте и показывает `Access Denied` как fallback

Важная деталь:

- `proxy.ts` не просто base64-декодирует токен, а делает HS256 verification через `JWT_SECRET_KEY`
- если `JWT_SECRET_KEY` отсутствует, role-based redirect для `/staff/*` не работает, остаётся только базовый gate по наличию cookie
- backend-проверки через `require_role()` и `require_permission()` всё равно обязательны

## Admin UI на frontend

В ходе RBAC-интеграции были синхронизированы три ключевых компонента:

- `UsersTable.tsx`
- `UserDetail.tsx`
- `RoleAssignDialog.tsx`

Что важно для поддержки:

- все три компонента используют shared types из `frontend/shared/api/types.ts`
- удаление роли теперь идёт по корректному URL `DELETE /v1/admin/users/{user_id}/roles/{role_id}`
- кнопка `Remove` в `UserDetail.tsx` скрывается для `is_system` ролей
- список ролей для назначения приходит из `GET /v1/admin/roles`

## Local development и отладка

### Минимальная frontend-конфигурация

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
JWT_SECRET_KEY=your_backend_jwt_secret
JWT_ALGORITHM=HS256
```

### Что нужно от backend

- применённая Alembic-миграция RBAC
- корректный `JWT_SECRET_KEY`, совпадающий с frontend env для `proxy.ts`
- CORS с явным origin для кабинета
- debug-режим, если используется `POST /v1/auth/dev-login`

### Быстрый smoke test

1. Открыть `/{lang}/login` и выполнить login.
2. Проверить, что backend выставил `access_token` и `refresh_token`.
3. Проверить, что `GET /v1/auth/me` возвращает пользователя с `roles[]`.
4. Проверить, что обычный пользователь не попадает на `/{lang}/staff/admin`.
5. Проверить, что `employee` или `superadmin` проходят в staff-раздел.
6. Проверить `GET /v1/admin/users` и `GET /v1/admin/roles`.
7. Проверить назначение и отзыв роли из admin UI.

### Проверки для разработчика

- frontend: `npx tsc --noEmit`
- backend: `python -m pytest tests/test_cabinet_rbac_service.py -q`
- backend: `python -m pytest tests/test_cabinet_admin_api.py -q`

Замечание:

- backend pytest требует нормального Python-окружения `diaverseapi`; в голом системном Python пакет `pytest` может отсутствовать

## Известные ограничения и ловушки

- Frontend role matrix дублирует backend seed вручную. Изменили backend permissions — обновите и `ROLE_PERMISSIONS`.
- `proxy.ts` не заменяет backend authorization и не должен считаться security boundary.
- `StaffLayout.tsx` и `proxy.ts` проверяют одно и то же на разных слоях. Если меняется staff-role policy, обновлять нужно оба места.
- Добавляя новый защищённый cabinet route, проверьте `cabinetRoutes` в `frontend/proxy.ts`.
- `normalizeCabinetUser()` сейчас использует только часть backend `UserRead`. Если frontend начнёт опираться на дополнительные поля, их нужно явно отразить в `CabinetMeResponse`.
- Audit trail при assign/revoke живёт в admin service/API слое, а не внутри `RbacService`.

## Когда обновлять этот документ

Обновление обязательно, если меняется хотя бы одно из следующих условий:

- состав системных ролей
- `PERMISSIONS` или `ROLE_PERMISSION_MATRIX` в backend seed
- shape `UserRead.roles` или frontend `CabinetMeResponse`
- набор `/v1/admin/*` endpoints
- способ проверки staff access в `proxy.ts` или `StaffLayout.tsx`
- shared types или auth hooks на frontend
## Staff Module Access Update

This document also covers the 2026-04-22 Staff module access split:

- System roles remain `user`, `partner`, `employee`, and `superadmin`; there is
  no `admin` role.
- The previous Staff Admin users screen moved to `frontend/modules/users` and
  route `/{lang}/staff/users`.
- The new Staff Admin module at `/{lang}/staff/admin` is superadmin-only and
  contains the `Access` tab.
- Per-user module grants live in `diaverseapi` table `cab_staff_module_access`.
  `edit` always implies `view`.
- `GET /v1/staff/access/me` is the current-user access contract used by Staff
  layout and copywriting BFF permissions.
- `GET /v1/admin/access` and
  `PATCH /v1/admin/access/users/{user_id}/modules/{module_key}` are
  superadmin-only matrix endpoints.
- Existing employees are backfilled for active Staff modules, while
  superadmins are displayed as immutable computed full-access rows.
- Placeholder modules (`support`, staff `exchange`, `metrics`) may be listed
  for planning but are only frontend-gated until real staff endpoints exist.
- Legacy `admin:access` must not be treated as access to the new Admin module.
