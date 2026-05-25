# Cabinet Auth

## Техническая документация: Аутентификация веб-кабинета (Telegram Widget + httpOnly Cookies)

Ветка реализации: feature/cabinet-auth

Скоуп документа:

- браузерный кабинет в `diaweb`
- контракт с внешним backend-репозиторием `C:\Users\Indigo\Desktop\diaverse\diaverseapi`
- Telegram Login Widget
- `httpOnly` cookies и `x-platform: cabinet`

Вне скоупа:

- mobile auth (`x-platform: mobile`)
- Telegram Mini App auth (`x-platform: web`)
- backend-реализация вне перечисленных auth-endpoint'ов

## Ключевые решения

- Для браузерного кабинета используется отдельная платформа `cabinet`.
- `x-platform: web` зарезервирован за Telegram Mini App и не должен использоваться браузерным кабинетом.
- Frontend не читает и не пишет JWT вручную. Любая логика через `document.cookie` для auth считается регрессией.
- Backend выставляет `access_token` и `refresh_token` как `httpOnly` cookies.
- Все запросы из кабинета идут через `credentials: "include"`.
- Главный источник прав на frontend сейчас это `roles[]` в `/v1/auth/me`.
- UI может скрывать разделы по ролям, но реальная авторизация остается обязанностью backend.

## Где находится логика

### Frontend (`diaweb`)

| Файл                                                       | Роль                                                        |
| ---------------------------------------------------------- | ----------------------------------------------------------- |
| `frontend/app/[lang]/login/page.tsx`                       | entrypoint страницы логина                                  |
| `frontend/modules/auth/components/LoginPage.tsx`           | orchestration login/dev-login и redirect                    |
| `frontend/modules/auth/components/TelegramLoginButton.tsx` | подключение Telegram Login Widget                           |
| `frontend/modules/auth/context.tsx`                        | Zustand store с `login`, `logout`, `fetchUser`              |
| `frontend/shared/api/client.ts`                            | единый fetch wrapper, `x-platform: cabinet`, auto-refresh   |
| `frontend/shared/auth/index.ts`                            | `useAuth`, `usePermission`, `useRequireAuth`                |
| `frontend/proxy.ts`                                        | locale redirect и coarse auth gate по `access_token` cookie |
| `frontend/modules/cabinet/components/CabinetLayout.tsx`    | стартовая загрузка текущего пользователя                    |
| `frontend/modules/cabinet/components/Sidebar.tsx`          | role-based видимость пунктов меню                           |

### Backend (`diaverseapi`, отдельный репозиторий)

| Файл                                      | Роль                                                                             |
| ----------------------------------------- | -------------------------------------------------------------------------------- |
| `diaverseapi/app/security/schemas.py`     | `TelegramWidgetAuth` schema                                                      |
| `diaverseapi/app/security/api.py`         | `/v1/auth/telegram`, `/v1/auth/dev-login`, `/v1/auth/refresh`, `/v1/auth/logout` |
| `diaverseapi/app/security/dependecies.py` | cabinet-ветка в `get_current_user`                                               |
| `diaverseapi/tests/test_cabinet_auth.py`  | pytest для cabinet auth flow                                                     |

## x-platform матрица

| x-platform | Метод auth                           | Клиент               |
| ---------- | ------------------------------------ | -------------------- |
| `mobile`   | Bearer token в `Authorization`       | мобильное приложение |
| `web`      | Telegram WebApp `init_data` в Bearer | Telegram Mini App    |
| `cabinet`  | `httpOnly` cookie `access_token`     | браузерный кабинет   |

Главное правило: если код пишется для обычного браузера и route-group `(cabinet)`, он должен отправлять `x-platform: cabinet`.

## Поток логина

1. Пользователь открывает `/{lang}/login`.
2. `LoginPage` рендерит `TelegramLoginButton`.
3. `TelegramLoginButton` вставляет внешний скрипт `https://telegram.org/js/telegram-widget.js?22` и регистрирует `window.onTelegramAuth`.
4. После подтверждения Telegram возвращает payload `id`, `first_name`, `last_name?`, `username?`, `photo_url?`, `auth_date`, `hash`.
5. `LoginPage.handleAuth()` отправляет этот payload в `POST /v1/auth/telegram`.
6. `apiClient` автоматически добавляет `x-platform: cabinet`, `Content-Type: application/json`, `credentials: "include"` и, если доступен браузерный timezone, `X-TimeZone`.
7. Backend валидирует `hash`, ищет пользователя по Telegram ID, выставляет `Set-Cookie` для `access_token` и `refresh_token`.
8. Frontend не читает тело ответа для токена. После успешного ответа он вызывает `useAuthStore.login()` и затем `fetchUser()`.
9. `fetchUser()` делает `GET /v1/auth/me`, получает пользователя с ролями и кладет его в Zustand store.
10. После гидрации пользователя выполняется redirect на `redirect` query param или `/{lang}/dashboard`.

### Важная деталь

Для frontend успешный login определяется не JSON-телом `POST /v1/auth/telegram`, а сочетанием двух фактов:

- backend поставил cookies
- `GET /v1/auth/me` вернул актуального пользователя

Из этого следует, что любые будущие изменения login response не должны ломать клиент, пока сохраняется этот контракт.

## Frontend flow после логина

### Auth store

`frontend/modules/auth/context.tsx` хранит:

- `user`
- `isAuthenticated`
- `isLoading`
- `login()`
- `logout()`
- `fetchUser()`

Нюансы:

- `login()` только переключает флаг авторизации, но не работает с cookies.
- `logout()` вызывает `POST /v1/auth/logout`, после чего очищает локальный Zustand state.
- `fetchUser()` делает `GET /v1/auth/me` и является единственной точкой гидрации user-объекта.

### API client

`frontend/shared/api/client.ts` является обязательной точкой доступа к backend из кабинета.

Что он делает:

- добавляет `x-platform: cabinet`
- отправляет `credentials: "include"` на каждый запрос
- добавляет `X-TimeZone`, если код выполняется в браузере
- при `401` на не-auth endpoint'ах вызывает `POST /v1/auth/refresh`
- повторяет исходный запрос после успешного refresh

Если разработчик добавляет новый auth endpoint, нужно проверить `AUTH_PATHS`.
Иначе client может попасть в лишний refresh loop на `401`.

### Route protection

`frontend/proxy.ts` выполняет две задачи:

- добавляет locale prefix, если пользователь пришел без `/ru` или `/en`
- не пускает на cabinet routes без cookie `access_token`

Это coarse-защита, а не полная валидация сессии:

- `proxy.ts` проверяет только наличие cookie
- валидность токена проверяется backend'ом на `/v1/auth/me` и на защищенных API

Поэтому возможен сценарий, когда пользователь проходит через `proxy.ts`, но потом получает `401` на реальном API из-за истекшей сессии.
Это штатное поведение.

### Role-based UI

`frontend/modules/cabinet/components/Sidebar.tsx` скрывает пункты меню по ролям:

- `partners` виден только `partner`
- `admin` виден `employee` и `superadmin`
- `superadmin` проходит все role-фильтры

Это только UX-слой.
Нельзя считать скрытие пункта меню достаточной авторизацией.

### Shared auth hooks

`frontend/shared/auth/index.ts` сейчас дает:

- `useAuth()` для чтения user/auth/loading
- `usePermission(resource, action)` как временную role-based заглушку
- `useRequireAuth()` для client-side redirect

Ограничение текущей реализации:

- `usePermission()` пока не работает с настоящими permissions, а лишь проверяет наличие роли
- для `superadmin` возвращается `true`
- для остальных пользователей детализация `resource/action` еще не реализована

Если frontend начнет опираться на granular permissions, сначала нужно расширить контракт `/v1/auth/me`.

## Backend контракт, от которого зависит frontend

| Endpoint                  | Что ожидает frontend                                                                                      |
| ------------------------- | --------------------------------------------------------------------------------------------------------- |
| `POST /v1/auth/telegram`  | принимает payload Telegram Widget, валидирует `hash`, выставляет `access_token` и `refresh_token` cookies |
| `POST /v1/auth/dev-login` | доступен только в debug-режиме, выставляет те же cookies                                                  |
| `GET /v1/auth/me`         | читает `access_token` cookie для `x-platform: cabinet`, возвращает текущего пользователя с `roles[]`      |
| `POST /v1/auth/refresh`   | читает `refresh_token` cookie, ротирует токены и выставляет новые cookies                                 |
| `POST /v1/auth/logout`    | инвалидирует сессию и очищает auth cookies                                                                |

### Cookie expectations

- `access_token`: короткоживущий токен для обычных запросов
- `refresh_token`: длинноживущий токен для восстановления сессии
- `HttpOnly`: `true`
- `SameSite`: `Lax`
- `Secure`: `true` в production, `false` в локальной отладке

### Payload Telegram Widget

Frontend уже ожидает именно эти поля:

```ts
{
  id: number
  first_name: string
  last_name?: string
  username?: string
  photo_url?: string
  auth_date: number
  hash: string
}
```

Backend-ветка из плана использует HMAC-SHA256 верификацию через `bot_token`.
Если верификация или поиск пользователя меняются, надо обновлять и этот документ, и `.ai-factory/plans/feature-cabinet-auth.md`.

## User model, который нужен frontend

`fetchUser()` ожидает ответ вида:

```ts
{
  data: {
    id: string;
    tg_id: number;
    display_name: string;
    avatar_url: string | null;
    email: string | null;
    phone: string | null;
    bio: string | null;
    social_links: Record<string, string> | null;
    roles: Array<{
      id: string;
      name: string;
      display_name: string;
    }>;
  }
}
```

Практический вывод:

- если backend меняет shape `UserRead`, нужно проверить `modules/auth/context.tsx`
- `roles[]` обязательны для sidebar-фильтрации и `usePermission()`
- login response может меняться свободнее, чем `/auth/me`

## Local development и отладка

### Минимальная frontend-конфигурация

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_TELEGRAM_BOT_NAME=<bot_username>
```

### Что нужно от backend

- origin кабинета должен быть явно разрешен в CORS
- wildcard `allow_origins=["*"]` несовместим с `credentials: "include"`
- debug-режим нужен, если используется `POST /v1/auth/dev-login`
- BotFather должен знать домен кабинета для Telegram Login Widget

### Быстрый smoke test

1. Открыть `/{lang}/login`
2. Выполнить Telegram login или `Dev Login (superadmin)` в dev-режиме
3. Проверить, что backend отвечает `Set-Cookie`
4. Проверить, что `GET /v1/auth/me` возвращает пользователя
5. Проверить redirect на `/{lang}/dashboard`
6. Проверить, что после hard refresh cabinet routes остаются доступными

## Известные ограничения и ловушки

- План `feature-cabinet-auth.md` фиксировал MVP для существующих пользователей. Если backend включает авто-регистрацию через Telegram Widget, это нужно отдельно синхронизировать с этой документацией.
- `proxy.ts` защищает только список `cabinetRoutes`. Добавляя новый cabinet route, обновляйте и route-group, и этот список.
- `Sidebar` и `proxy.ts` решают разные задачи: первый отвечает за UX-навигацию, второй за базовый gate по cookie.
- `useRequireAuth()` выполняет client-side redirect и не заменяет `proxy.ts`.
- Любой новый запрос в backend должен идти через `apiClient`, иначе легко потерять `x-platform`, `credentials` или refresh logic.
- Любое чтение auth cookies на клиенте через `document.cookie` ломает `httpOnly` модель.

## Когда обновлять этот документ

Обновление обязательно, если меняется хотя бы одно из следующих условий:

- `x-platform` матрица
- набор auth-endpoint'ов кабинета
- shape `/v1/auth/me`
- cookie policy
- login flow на frontend
- способ route protection в `proxy.ts`
