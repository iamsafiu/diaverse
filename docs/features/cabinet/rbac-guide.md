# Cabinet RBAC Guide

## Staff Module Access

Current system roles are `user`, `partner`, `employee`, and `superadmin`.
There is no separate `admin` role. The Staff shell is still entered by
`employee` or `superadmin`, but employee access to individual Staff modules is
now controlled by per-user module grants from `diaverseapi`.

The old Staff `Admin` users screen is now the `Users` module at
`/{lang}/staff/users`. The new `Admin` module at `/{lang}/staff/admin` is
superadmin-only and is not grantable through the matrix. If a non-superadmin
staff member reaches the old `/staff/admin` URL and has `users:view`, the
frontend redirects them to `/staff/users`.

Module grants use two levels:

- `view` shows the navigation item and allows read endpoints.
- `edit` implies `view` and allows write endpoints where the module supports
  mutations.

The current employee migration/backfill grants existing employees `view+edit`
for active modules (`users`, `advent-calendars`, `copywriting`, `logging`) and
`view` for `analytics`. Placeholder modules (`support`, staff `exchange`,
`metrics`) can appear in the matrix but do not imply wired backend endpoints.
`superadmin` is computed as immutable full access and cannot be locked out.

Endpoint contract:

- `GET /v1/staff/access/me` returns the current staff user's effective module
  access and permission claims. Frontend Staff layout uses it and fails closed
  for non-superadmins if it cannot load.
- `GET /v1/admin/access` returns the Access matrix for Admin > Access and is
  superadmin-only.
- `PATCH /v1/admin/access/users/{user_id}/modules/{module_key}` updates one
  grant and enforces `edit => view`; it is superadmin-only.

Copywriting BFF mapping is derived from the same current-access endpoint:
`copywriting:view` maps to internal `copywriting:read`, while
`copywriting:edit` maps to read/create/review/publish/source-management
permissions.

## Что уже реализовано

- Backend RBAC живёт в sibling-репозитории `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\rbac`.
- Admin API для управления ролями живёт в `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\admin`.
- Системные роли: `user`, `partner`, `employee`, `superadmin`.
- Access token теперь содержит `roles[]`, а `GET /v1/auth/me` возвращает роли в `UserRead`.
- Frontend использует общие типы из `frontend/shared/api/types.ts` и проверки доступа из `frontend/shared/auth/index.ts`.

## Как добавить новую роль

1. Добавьте роль в `SYSTEM_ROLES` в `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\rbac\seed.py`.
2. Добавьте permissions для роли в `ROLE_PERMISSION_MATRIX` в том же файле.
3. Если роль должна давать доступ на frontend до загрузки детальных permissions, обновите `ROLE_PERMISSIONS` в `frontend/shared/auth/index.ts`.
4. Если роль должна назначаться через UI, ничего дополнительно на frontend делать не нужно: `GET /v1/admin/roles` уже читает актуальный список ролей из backend.
5. Добавьте или обновите backend tests в `tests/test_cabinet_rbac_service.py` и `tests/test_cabinet_admin_api.py`.

## Как добавить новый permission

1. Добавьте `(resource, action, description)` в `PERMISSIONS` в `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\cabinet\rbac\seed.py`.
2. Привяжите permission к нужным ролям через `ROLE_PERMISSION_MATRIX`.
3. Если permission нужен для frontend guard на этапе Phase 1, обновите зеркальную матрицу `ROLE_PERMISSIONS` в `frontend/shared/auth/index.ts`.
4. Для data-only изменения новой Alembic-миграции не требуется: достаточно повторно выполнить seed после деплоя миграции схемы.

## Copywriting permission contract

Для staff-only copywriting модуля в Phase 0 зафиксирован минимальный набор permission-ключей:

- `copywriting:read`
- `copywriting:create`
- `copywriting:review`
- `copywriting:publish`
- `copywriting.sources:manage`

Базовое системное распределение для V1 такое:

- `employee` получает весь минимальный copywriting-набор, чтобы staff workflow не зависел от кастомных ролей на первом релизе
- `superadmin` получает те же права автоматически через полный набор permissions
- `user` и `partner` эти permissions не получают

Frontend зеркалит эти ключи в `frontend/shared/auth/index.ts` только для route/UI guard-логики. Источником истины остаётся `diaverseapi` seed и backend-проверки через `require_permission()`.

## Как защищать новый backend endpoint

Для проверки по роли используйте `require_role()` из `app/cabinet/rbac/dependencies.py`:

```python
from fastapi import APIRouter, Security

from app.cabinet.rbac.dependencies import require_role
from app.security.schemas import UserRead

router = APIRouter()
require_staff_user = require_role("employee", "superadmin")


@router.get("/reports")
async def list_reports(user: UserRead = Security(require_staff_user)):
    return {"ok": True}
```

Для проверки по permission используйте `require_permission()`:

```python
from fastapi import APIRouter, Security

from app.cabinet.rbac.dependencies import require_permission
from app.security.schemas import UserRead

router = APIRouter()
require_content_update = require_permission("content", "update")


@router.patch("/content/{item_id}")
async def update_content(item_id: str, user: UserRead = Security(require_content_update)):
    return {"id": item_id}
```

## Как работает seed

- `seed_rbac()` вызывается из `C:\Users\Indigo\Desktop\diaverse\diaverseapi\app\main.py` при старте приложения.
- Seed идемпотентный: повторный запуск не дублирует роли, permissions и связи.
- Перед сидированием проверяется наличие таблиц `cab_*`; если миграция ещё не применена, seed логирует skip и не ломает startup.
- Первый `superadmin` автоматически назначается пользователю с `bot_user_id=80` (`ADMIN_USER_BOT_ID`), если такой пользователь существует.
- `assign_default_role()` назначает роль `user` при cabinet login, если у пользователя ещё нет ролей.

## Frontend: как использовать RBAC

- `frontend/modules/auth/context.tsx` получает `/v1/auth/me` и нормализует ответ через `normalizeCabinetUser()`.
- `useHasRole("employee", "superadmin")` подходит для route-level и layout-level проверок.
- `usePermission("users", "list")` и `usePermission("content", "update")` подходят для скрытия или показа действий в UI.
- `frontend/proxy.ts` защищает `/staff/*` на уровне Next.js proxy через проверку JWT `roles[]`. Это только UX guard; backend-проверки через `require_role()` и `require_permission()` обязательны.

## Env для proxy guard

Добавьте в `frontend/.env.example` и локальное окружение:

```env
JWT_SECRET_KEY=your_backend_jwt_secret
JWT_ALGORITHM=HS256
```

Без `JWT_SECRET_KEY` proxy продолжит защищать cabinet route только по наличию cookie, а роль-based redirect для staff routes не сработает.
