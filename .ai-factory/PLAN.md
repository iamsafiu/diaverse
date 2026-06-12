# AIF Fast Plan: Библиотека товаров магазина

Дата: 2026-06-11  
Режим: `fast`  
Тип: multi-repo plan из workspace root  
Статус: готов к реализации  

## Цель

Добавить в staff shop отдельный слой "Библиотека" между общим item catalog и витриной магазина.

Администратор сначала добавляет товар в библиотеку, задает базовую цену и базовое количество. В библиотеке цена может быть меньше `1 USDT`, но должна быть строго положительной. Для питомцев библиотека должна поддерживать выбор эволюции: цена первой эволюции задается вручную, последующие эволюции по умолчанию считаются как `+50%` к предыдущей, при этом каждая цена может быть переопределена вручную.

В витрине магазина администратор добавляет товары только из своей библиотеки. В витрине цена не вводится вручную: указывается только количество, а цена считается автоматически из библиотечной цены и количества. Для витринной цены действует защита: итоговая цена не может быть ниже `1 USDT`.

## Репозитории

| Repo | Затрагиваем | Назначение |
| --- | --- | --- |
| `diaverseapi` | да | backend shop domain, admin API, migration, checkout guards, tests |
| `diaweb` | да | staff UI, shop admin API client, frontend tests |
| `aibot` | нет | не участвует |
| `club10000-bot` | нет | не участвует |
| `diaverse-auth-bot` | нет | не участвует |

Ветка в `fast` режиме не создается. Если переводить план в full implementation, использовать один slug в затронутых repo, например `feature/shop-library`.

## Проверенный контекст

GBrain был использован первым, но по новым запросам `shop catalog library offer evolution price` готовых страниц не нашлось. Решение основано на проверке raw source.

Ключевые точки backend:

- `diaverseapi/app/cabinet/shop/models.py`
  - `CabShopItem` сейчас является витринной позицией.
  - `CabShopItemFulfillmentLine` хранит configured reward lines.
  - `CabShopItemOffer` хранит external offer price.
- `diaverseapi/app/cabinet/shop/admin_service.py`
  - `create_item`, `bulk_add`, `_build_fulfillment_line_rows`, `_normalize_usdt_price`.
- `diaverseapi/app/cabinet/shop/service.py`
  - checkout читает цену из offer.
  - `_resolve_offer_usdt_pricing` принимает положительный USDT, но не задает min `1`.
- `diaverseapi/app/cabinet/item_catalog/providers.py`
  - character catalog уже содержит evolution metadata/options.
- `diaverseapi/app/cabinet/fulfillment/handlers.py`
  - character grant уже читает `options_json.evolution`.
- `diaverseapi/app/evolutions/config.py`
  - лимиты эволюций зависят от rarity.
- `diaverseapi/app/cabinet/shop/bundle_savings.py`
  - есть старые pet evolution multipliers, их нужно согласовать с новой моделью цены.

Ключевые точки frontend:

- `diaweb/frontend/modules/staff-shop/components/ShopAdminPage.tsx`
  - сейчас workspace tabs: `general`, `offers`, `crypton`.
- `diaweb/frontend/modules/staff-shop/components/ShopListingEditor.tsx`
  - сейчас редактор листинга содержит price input и character evolution input.
- `diaweb/frontend/modules/staff-shop/components/ShopBulkAddDialog.tsx`
  - bulk add принимает default price и fulfillment quantity.
- `diaweb/frontend/modules/staff-shop/shop-admin-api.ts`
  - staff client for admin shop endpoints.
- `diaweb/frontend/modules/staff-item-catalog/*`
  - уже есть UI/picker patterns для общего item catalog.

## Архитектурные решения

1. Библиотека - это product/SKU price-book слой, а не новая публичная витрина.
2. Текущий `CabShopItem` остается витринной позицией, чтобы не ломать public shop, checkout и аналитику.
3. Для первого релиза не делать runtime dynamic pricing в checkout. Надежнее материализовать derived price в `CabShopItemOffer` и дополнительно валидировать drift.
4. Новые витринные позиции должны ссылаться на library item. Legacy позиции без library link временно поддерживаются для безопасного rollout/backfill.
5. Библиотечная цена: `base_price_amount > 0`, currency `USDT`, без min `1`.
6. Витринная цена:
   - `raw = library_base_price * storefront_quantity / library_base_quantity`
   - `effective = max(raw, 1 USDT)`
   - округление фиксировать в одном helper, предпочтительно до `0.01 USDT`, если существующий money policy не требует другого шага.
7. Pet evolution:
   - для character library item хранить variant key, например `evolution:1`, `evolution:2`;
   - fulfillment line должен получать `options_json.evolution`;
   - цены evolution rows по умолчанию: `evo_n = evo_(n-1) * 1.5`;
   - manual override хранить явно и не перетирать автопересчетом без действия администратора.
8. Specials/category deals/bundle savings должны работать от materialized storefront offer price. Старые hardcoded pet multipliers нельзя оставлять как основной source of truth.
9. Staff UX:
   - новый tab: `Библиотека`;
   - текущий `Общий раздел` лучше переименовать в `Магазин`;
   - визуально библиотеку строить на тех же table/editor patterns, что текущий shop catalog.
10. Legacy `price_xdv` остается compatibility-полем на период миграции:
   - для library-backed витринных позиций хранить `0.000`, если бизнес-значения XDV больше нет;
   - не использовать `price_xdv` как source of truth для новой цены;
   - не ломать старые tests/serializers, которые ожидают поле.
11. Default duplicate policy для первого релиза: один активный storefront listing на один library item. Если позже понадобится размещать один SKU в нескольких категориях или с разными quantities одновременно, добавлять явный `listing_variant_key` и отдельное решение по purchase limits.
12. Purchase limits в первом релизе остаются на уровне `CabShopItem`, чтобы не менять buyer-facing поведение без отдельного product decision. Backend должен логировать и блокировать accidental duplicate active listings по одному library item.
13. Pending checkout/payment sessions не пересчитываются задним числом. Уже созданный `CabShopOrder.quoted_amount` остается snapshot. Изменение library price влияет только на новые checkout sessions и на еще не созданные materialized offers.

## Out Of Scope

- Редизайн публичной страницы магазина.
- Новые платежные провайдеры.
- Изменения Telegram bots.
- Полная очистка исторических данных руками вне migration/backfill.
- Отказ от materialized offers в пользу полностью dynamic checkout.
- Глобальный purchase-limit по library SKU вместо текущего per-listing поведения.

## План работ

### 1. Backend: модель библиотеки и миграция

- [ ] В `diaverseapi` добавить модели библиотеки:
  - `CabShopLibraryItem`;
  - при необходимости `CabShopLibraryFulfillmentLine`, если reuse текущих fulfillment lines делает связь неочевидной;
  - nullable `library_item_id` на `CabShopItem` для rollout/backfill.
- [ ] Поля library item:
  - source/catalog identity: `source_type`, `source_ref`, `variant_key`;
  - `base_quantity`;
  - `base_price_amount`, `base_price_currency`;
  - active/visibility flags for admin selection;
  - sort/order metadata;
  - metadata JSON for catalog snapshot and UI hints.
- [ ] Для `CabShopItem` сохранить legacy compatibility:
  - `price_xdv` остается обязательным и получает `0.000` для library-backed rows;
  - `price_xdv` не участвует в новом USDT pricing;
  - API responses продолжают отдавать поле, пока старые UI/tests его ожидают.
- [ ] Для pets хранить evolution в variant/fulfillment options так, чтобы grant path использовал существующий `options_json.evolution`.
- [ ] Добавить Alembic migration с короткими именами constraints/indexes, чтобы не упереться в PostgreSQL limit `63` bytes.
- [ ] Если library models вынесены в новый файл, добавить явный import в `diaverseapi/migrations/env.py`, иначе `SQLModel.metadata` не увидит новые таблицы при autogenerate/checks.
- [ ] Добавить индексы:
  - lookup по `source_type/source_ref/variant_key`;
  - lookup по `is_active`;
  - lookup по `CabShopItem.library_item_id`;
  - уникальность library natural key, учитывая `variant_key`.
- [ ] Backfill:
  - создать library rows из существующих shop items и их offer prices;
  - связать существующие `CabShopItem` с созданными library rows;
  - проставить `price_source=library_backfill` в metadata linked offers/items;
  - оставить legacy fallback для строк, где backfill невозможен;
  - сделать backfill идемпотентным по natural key.
- [ ] Добавить единый helper price policy:
  - validate library price `> 0`;
  - derive storefront price;
  - apply min floor `1 USDT`;
  - return reason/flags, например `floor_applied`.
- [ ] Обновить Alembic tests:
  - `tests/test_alembic_graph.py` current head;
  - identifier length check для новой migration;
  - `alembic upgrade <down_revision>:<new_revision> --sql`.
- [ ] Логирование:
  - `INFO` для admin mutations/backfill counts;
  - `DEBUG` для derived price formula inputs/outputs;
  - `WARNING` для catalog mismatch, invalid evolution, legacy fallback.

Ожидаемый результат: база умеет хранить библиотечные SKU отдельно от витринных позиций, старые товары не ломаются, pricing rule изолирован в одном месте.

### 2. Backend: admin API библиотеки

- [ ] Добавить schemas для library list/create/update:
  - library item response с catalog metadata;
  - price/quantity fields;
  - pet evolution fields;
  - derived storefront preview fields.
- [ ] Добавить service layer, предпочтительно отдельный `library_admin_service.py`, если `admin_service.py` уже слишком разросся.
- [ ] Добавить endpoints под `/v1/admin/shop/library`:
  - list/search;
  - create from common catalog item;
  - update price/quantity/active metadata;
  - delete или soft-disable;
  - optional bulk generate pet evolution rows.
- [ ] Подключить endpoints через существующий staff shop router и RBAC:
  - read operations используют `require_staff_module_access("shop", "view")`;
  - write operations используют `require_staff_module_access("shop", "edit")`.
- [ ] Ошибки API сделать стабильными:
  - not found -> `404`;
  - duplicate active library/listing -> `409`;
  - invalid evolution/price/quantity -> `422` или согласованный `400` с reason code;
  - linked item cannot be deleted -> `409`.
- [ ] Validation:
  - source item должен существовать в item catalog;
  - character evolution должен попадать в allowed range for rarity;
  - non-character items не должны принимать evolution;
  - library price допускает `< 1`, но не допускает `0`/negative.
- [ ] При изменении library price/quantity пересчитывать linked storefront offers.
- [ ] Логирование:
  - `INFO` для create/update/disable;
  - `DEBUG` для catalog resolution и price preview;
  - `WARNING` для отказов validation и попыток обновить linked/deleted entries.

Ожидаемый результат: staff backend может управлять библиотекой независимо от витрины.

### 3. Backend: витрина только из библиотеки

- [ ] Изменить create/update storefront item flow:
  - новые позиции создаются из `library_item_id`;
  - в request для новой витринной позиции больше нет ручной цены;
  - quantity остается editable;
  - section/category, sort, visibility остаются на уровне витрины.
- [ ] Duplicate policy:
  - по умолчанию блокировать второй активный storefront listing для того же `library_item_id`;
  - для legacy rows без `library_item_id` оставить существующий unique key;
  - если понадобится duplicate listing, вводить явный `listing_variant_key`, а не обходить guard.
- [ ] Purchase-limit policy:
  - оставить текущий per-`shop_item_id` учет покупок;
  - в metadata response отдать `library_item_id`, чтобы позже можно было перейти на per-library limit без разрыва контракта;
  - добавить warning при попытке создать duplicate active listing, потому что per-listing limits позволили бы повторную покупку.
- [ ] Materialize default offer:
  - при создании/обновлении витринной позиции рассчитать effective price;
  - сохранить ее в `CabShopItemOffer`;
  - пометить metadata source, например `price_source=library`.
- [ ] Checkout guard:
  - если item связан с library, перед checkout проверить, что offer price не расходится с derived price;
  - при drift либо безопасно refresh до checkout, либо блокировать с понятным admin-facing log, но не silently продавать по stale price.
- [ ] Сохранить backward compatibility:
  - legacy item без `library_item_id` обслуживать старым путем;
  - UI/API response должен явно показывать legacy flag.
- [ ] Адаптировать `bulk_add`:
  - либо перевести в bulk add to library;
  - либо оставить только для legacy/internal path, скрыв из нового UI.
- [ ] Логирование:
  - `INFO` при создании витринной позиции из library;
  - `DEBUG` для пересчета offer;
  - `WARNING` при drift, missing library link, stale offer.

Ожидаемый результат: магазин больше не вводит цену вручную для новых позиций, но checkout продолжает работать через проверенный offer pipeline.

### 4. Backend: bootstrap/sync, payment sessions и legacy guards

- [ ] Защитить library-backed rows от `sync_cabinet_shop_storefront` cleanup:
  - library-backed `CabShopItem` и materialized default offers должны иметь metadata marker, совместимый с `ADMIN_MANAGED_METADATA_KEY`;
  - stale cleanup не должен деактивировать admin/library-managed rows как non-canonical seed rows;
  - `rebuild_all=True` должен иметь явно описанное поведение для library-backed rows.
- [ ] Обновить `sync-preview`:
  - не предлагать как "missing" item, если он уже есть в библиотеке или витрине через library;
  - показать отдельный library preview, если это остается полезным для staff UX.
- [ ] Pending checkout policy:
  - `CabShopOrder.quoted_amount` и `CabinetPaymentSession` остаются snapshot;
  - library price updates не меняют уже созданные awaiting/paid sessions;
  - checkout drift guard применяется перед созданием нового order/session;
  - при изменении library price логировать количество linked active listings/offers, которые пересчитаны.
- [ ] Provider/default offer compatibility:
  - не перетирать `special` и `category_deal` offer rows при library recalculation;
  - обновлять только default/catalog provider offer или explicitly library-sourced offer.
- [ ] Tests:
  - `tests/test_cabinet_shop_bootstrap.py` на сохранение library/admin-managed rows;
  - service test на pending order quoted snapshot;
  - service test на duplicate active library listing guard.
- [ ] Логирование:
  - `INFO` для recalculation count;
  - `WARNING` для skipped pending orders, duplicate listing attempts, sync cleanup conflicts.

Ожидаемый результат: seed/sync процессы, pending payments и legacy compatibility не ломают новую библиотеку.

### 5. Backend: зависимые shop systems и price snapshots

- [ ] Проверить и адаптировать:
  - category deals;
  - specials;
  - bundle savings;
  - promo offer selection;
  - shop analytics/facts;
  - Crypton/admin offer summaries, если они показывают base price.
- [ ] Price snapshot policy:
  - `normal/base price` для category deals и specials берется из materialized storefront price;
  - discounted/special price применяется поверх storefront effective price, а не поверх raw library price;
  - min `1 USDT` витрины нельзя обойти через deal/special offer;
  - existing active deal/special snapshots не переписываются задним числом без explicit regenerate/update action.
- [ ] Specials legacy fields:
  - `normal_price_xdv` и `offer_price_xdv` остаются compatibility-полями;
  - новые USDT fields (`normal_price_amount`, `offer_price_amount`) являются source of truth для оплаты;
  - frontend/admin payloads не должны заставлять staff вводить XDV для library-backed offers.
- [ ] Убрать `bundle_savings.py` как primary source для pet evolution standalone prices:
  - брать library-derived или materialized storefront price;
  - оставить fallback только с явным warning и тестом.
- [ ] Убедиться, что discounts применяются поверх effective storefront price, а не поверх raw library price ниже `1 USDT`.
- [ ] Логирование:
  - `DEBUG` для selected price source;
  - `WARNING` для fallback на legacy price.

Ожидаемый результат: все магазинные расчеты согласованы с новым source of truth и не обходят min-floor витрины.

### 6. Frontend: staff API client и типы

- [ ] В `diaweb` расширить `staff-shop` types:
  - `ShopLibraryItem`;
  - create/update payloads;
  - pet evolution price row;
  - derived price preview;
  - legacy/storefront link fields.
- [ ] Добавить frontend fields для backend compatibility:
  - `library_item_id`;
  - `price_source`;
  - `floor_applied`;
  - `legacy_price_xdv` только как deprecated/read-only field.
- [ ] Добавить methods в `shop-admin-api.ts`:
  - list library;
  - create/update/disable library item;
  - generate/update evolution rows;
  - create storefront item from library.
- [ ] Добавить cache keys/invalidation:
  - `["staff-shop", "library"]`;
  - `["staff-shop", "items"]`;
  - public `[SHOP_QUERY_KEY]`;
  - `[SHOP_SPECIALS_QUERY_KEY]`;
  - staff specials shop-items cache.
- [ ] Обновить error mapping:
  - invalid evolution;
  - price must be positive;
  - storefront price floor applied;
  - linked item cannot be deleted.
- [ ] Логирование:
  - только safe dev logging для unexpected API shape/errors, без tokens/user secrets.

Ожидаемый результат: frontend получает typed contract для библиотеки и не протаскивает manual price в новый store flow.

### 7. Frontend: tab "Библиотека"

- [ ] В `ShopAdminPage.tsx` добавить workspace tab `library`.
- [ ] Переименовать текущий `Общий раздел` в `Магазин`, если это не ломает локализацию/тесты.
- [ ] Создать `ShopLibraryTable`/`ShopLibraryEditor` или аналогичные компоненты в существующем стиле staff shop.
- [ ] UI behavior:
  - добавление из общего item catalog;
  - ввод base quantity;
  - ввод base price, допускающий `< 1`;
  - active/disabled state;
  - для character item - выбор evolution и/или генерация evolution rows.
- [ ] Для item catalog picker:
  - reuse existing `ItemCatalogPicker`/`StaffItemCatalogPicker`;
  - не фильтровать только `is_sellable`, если item `is_grantable` и staff задает цену вручную;
  - показывать sellability/grantability warning вместо скрытия подходящих для библиотеки items.
- [ ] Pet evolution UI:
  - показать allowed evolution range из catalog metadata;
  - default prices считать `* 1.5`;
  - дать ручной override каждой evolution price;
  - не перетирать overridden rows при повторном автосчете без подтвержденного действия.
- [ ] Visual:
  - использовать текущие таблицы, dialogs, controls из `staff-shop`;
  - не делать отдельную "лендинг" страницу;
  - price/quantity controls должны быть плотными и рабочими.

Ожидаемый результат: администратор может управлять библиотекой как каталогом товаров, визуально близким к текущему магазину.

### 8. Frontend: магазин из библиотеки

- [ ] Переделать `ShopListingEditor` для нового flow:
  - выбрать library item;
  - выбрать category/section;
  - указать quantity;
  - price input убрать для library-backed items;
  - derived price показать read-only.
- [ ] Разрезать legacy/new editor path:
  - legacy rows без `library_item_id` могут открываться старым editor;
  - library-backed rows используют новый read-only price flow;
  - table inline `BasePriceEditor` скрыть или сделать read-only для library-backed rows.
- [ ] Для price floor:
  - если применен min `1 USDT`, показать короткий read-only hint;
  - не давать администратору сохранить цену ниже floor через UI.
- [ ] Для legacy rows:
  - либо оставить старый editor с explicit legacy marker;
  - либо сделать read-only price + migration prompt, если backend поддерживает только просмотр.
- [ ] Обновить `ShopBulkAddDialog`:
  - новый bulk add должен работать через library;
  - старый `default_price_amount` не должен использоваться в новом path.
- [ ] Обновить `ShopBulkEditDialog`:
  - для library-backed rows убрать массовое редактирование цены;
  - quantity/visibility/sort остаются доступными;
  - если выбран смешанный набор legacy + library-backed, явно отключить price field или разделить operation.
- [ ] Добавить loading/empty/error states:
  - empty library;
  - disabled library item;
  - no eligible category;
  - backend validation error.

Ожидаемый результат: витрина становится выборкой из библиотеки, а цена вычисляется и показывается без ручного ввода.

### 9. Frontend: публичный shop compatibility

- [ ] Проверить user-facing shop types и cards:
  - existing offer price должен продолжить отображаться без изменений;
  - optional library metadata не должен ломать старые responses;
  - pet evolution badge/metadata не должны конфликтовать с текущими bundle badges.
- [ ] Не менять публичный UX без необходимости.
- [ ] Если response получает `floor_applied`/`price_source`, использовать это только в staff/admin view, не показывать покупателю внутренние детали.
- [ ] Проверить BFF routes под `diaweb/frontend/app/api/cabinet/shop/*`:
  - public storefront и checkout должны продолжить проксировать существующие responses;
  - internal library metadata не должна утекать в buyer-facing UI, если она не нужна карточкам.

Ожидаемый результат: покупатели видят тот же магазин, но цены приходят из нового управляемого источника.

### 10. Тесты

- [ ] Backend unit/service tests:
  - library price `< 1` accepted;
  - library price `0`/negative rejected;
  - storefront derived price floors to `1 USDT`;
  - quantity formula works;
  - pet evolution default `+50%` chain works;
  - manual evolution override survives recalculation;
  - invalid evolution rejected by rarity limit;
  - materialized offer recalculates after library update;
  - checkout detects stale price drift;
  - pending checkout/order keeps quoted snapshot after library price update;
  - duplicate active listing for one library item is rejected;
  - bootstrap sync does not deactivate library/admin-managed rows;
  - Alembic graph has one head and identifiers fit PostgreSQL limit;
  - legacy item remains supported.
- [ ] Backend integration/API tests:
  - create/list/update/disable library item;
  - create storefront listing from library;
  - stable HTTP status/reason codes for duplicate, invalid price, invalid evolution and linked delete;
  - existing shop catalog endpoint still returns compatible payload.
- [ ] Frontend tests:
  - library tab renders;
  - adding catalog item to library;
  - pet evolution rows and manual override;
  - store listing editor has no manual price field for library-backed item;
  - derived/floored price displayed read-only;
  - table inline price edit is hidden/read-only for library-backed rows;
  - bulk edit cannot change price for library-backed rows;
  - library mutations invalidate library/items/public shop caches;
  - legacy item handling.
- [ ] Add test names close to behavior, not implementation detail.

Ожидаемый результат: риск изменения checkout/pricing закрыт focused regression tests.

### 11. Verification commands

Backend:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaverseapi
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_shop_library.py tests/test_cabinet_shop_admin.py tests/test_cabinet_shop_service.py tests/test_cabinet_shop_api.py -q
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_shop_category_deals.py tests/test_cabinet_shop_specials.py tests/test_cabinet_shop_bundle_savings.py -q
.\.venv\Scripts\python.exe -m pytest tests/test_cabinet_shop_bootstrap.py tests/test_alembic_graph.py -q
.\.venv\Scripts\python.exe -m alembic heads
.\.venv\Scripts\python.exe -m alembic upgrade <down_revision>:<new_revision> --sql
.\.venv\Scripts\python.exe -m ruff check app/cabinet/shop tests
```

Frontend:

```powershell
cd C:\Users\Indigo\Desktop\diaverse\diaweb\frontend
npm test -- __tests__/modules/staff-shop/ShopAdminPage.test.tsx __tests__/modules/staff-shop/ShopListingEditor.test.tsx __tests__/modules/staff-shop/ShopLibraryEditor.test.tsx __tests__/modules/staff-shop/ShopBulkEditDialog.test.tsx __tests__/modules/staff-shop/shop-admin-api.test.ts
npm run typecheck
```

Browser smoke after frontend implementation:

```text
Open http://localhost:3000/ru/staff/shop
Check tabs: Магазин, Библиотека, Офферы, Crypton
Create library item with price < 1 USDT
Create storefront listing from that library item
Verify displayed storefront price is floored to 1 USDT
Create/edit character library evolution rows and verify manual override survives
```

Workspace knowledge sync after meaningful code/docs changes:

```powershell
cd C:\Users\Indigo\Desktop\diaverse
powershell -ExecutionPolicy Bypass -File .\scripts\gbrain-sync.ps1
```

## Suggested Commit Plan

1. `diaverseapi`: library schema, migration, Alembic env registration, price policy, backfill.
2. `diaverseapi`: library admin API, RBAC/error contract, storefront linking, duplicate guard.
3. `diaverseapi`: materialized offer recalculation, checkout drift guard, pending order snapshot policy, bootstrap/sync protection.
4. `diaverseapi`: specials/category deals/bundle savings/promo/finance compatibility and backend tests.
5. `diaweb`: staff shop API types/client, cache invalidation, library tab.
6. `diaweb`: library-backed storefront editor, bulk add/edit compatibility, frontend tests.
7. `diaverse`: docs/plan/daily updates and GBrain sync if documentation changed.

## Риски и как снизить

- Checkout price drift: materialized offer плюс guard перед checkout.
- Pending payment sessions: не пересчитывать уже созданный `quoted_amount`, применять новую library price только к новым checkout sessions.
- Старые товары: nullable `library_item_id` и legacy fallback на период rollout.
- `sync_cabinet_shop_storefront` cleanup: library/admin-managed rows должны быть защищены metadata marker и bootstrap tests.
- Alembic/autogenerate: если вынести library models в новый файл, обязательно импортировать их в `migrations/env.py` и обновить graph tests.
- Duplicate storefront rows: default guard на один active listing per library item, иначе per-listing purchase limits позволят повторную покупку.
- Legacy `price_xdv`: оставить compatibility value, но не использовать для новой USDT-цены.
- Pet evolution pricing conflict: убрать hardcoded multipliers как основной source of truth.
- Миграция данных: backfill должен быть идемпотентным по natural key и покрыт dry SQL через Alembic.
- UI путаница "каталог vs магазин": назвать staff tabs явно `Библиотека` и `Магазин`.
- Цена ниже `1 USDT`: разрешена только в библиотеке, витрина всегда floor `1 USDT`.

## Senior Recommendation

Браться стоит, если магазин будет регулярно пополняться и ротироваться. Это правильное разделение: библиотека становится источником цены и конфигурации товара, а витрина - только местом размещения с количеством, категорией и видимостью.

Не стоит делать это как мелкую правку текущего `ShopListingEditor`: цена, fulfillment, pets evolution, offers, discounts и checkout уже связаны. Быстрый путь через "просто скрыть price input" создаст скрытые расхождения. Нужен отдельный library layer, migration/backfill и materialized offer guard.
