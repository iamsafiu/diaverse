# Fabric Research Notes

Понял. Тогда senior-подход такой: старую diaverseapi/app/factory не лечить, а списать как legacy и
  заменить новым bounded context. По текущей карте зависимостей это реально: frontend сейчас фабрику почти
  не использует, основная связность сидит в backend route include, security deletion/merge logic, миграциях
  и subscription enum.

  Оценка сложности: высокая, но не из-за одного сложного алгоритма. Это большая экономическая система с
  таймерами, инвентарём, баланс-конфигами, подписками, прогресс-гейтами и производственными линиями. Если
  делать весь документ сразу, это 6-10 недель на backend+frontend+QA. Если делать MVP уровней 1-2 и
  архитектуру под 8 уровней, реалистично 3-5 недель.

  Архитектура, которую я бы выбрал:

  diaweb
    factory UI / map / screens
        |
        v
  diaverseapi
    app/factory_v3
      domain/          # чистые правила: уровни, цеха, крафт, требования
      catalog/         # баланс из seed/json/db: цеха, отсеки, рецепты, цены
      application/     # use cases, транзакции, команды
      infrastructure/  # SQLAlchemy/SQLModel repos, scheduler, inventory adapter
      api/             # REST schemas/routes

  Ключевое решение: баланс и правила не хардкодить в usecase-классы. Фабрика должна быть data-driven:
  таблицы/JSON seed для цехов, ресурсных частей, производственных отсеков, уровней, рецептов, раннего
  доступа, требований перехода. Код должен исполнять универсальную механику.

  Я бы не называл новую реализацию factory_v3 навсегда в публичном API. В коде можно временно поднять app/
  factory_new или app/factory_v3, но внешний путь лучше оставить /api/v1/factory только после удаления
  старого route include. Если нужен параллельный запуск, временно /api/v1/factory-new.

  Что удалить/заменить из старого:

  - diaverseapi/app/factory/* как implementation legacy.
  - Старый include в diaverseapi/app/routers/v1/endpoints.py.
  - Старые runtime tables: factories, factory_workshops, factory_compartments, factory_compartment_crafts,
    factory_*_config, если данные не нужны.
  - Старые migrations не переписывать задним числом, а добавить новую migration, которая аккуратно drops/
    replaces legacy schema в актуальной ветке.
  - В security/usecases.py оставить user deletion поддержку, но перепривязать на новые модели.
  - Subscription enum factory_step_pass_pro / factory_trademaster сохранить как продуктовые понятия, не
    удалять.

  Новая доменная модель:

  FactoryAccount
    user_id
    level
    currencies_snapshot/links
    storage_state
    daily_impulses_collected

  FactoryBuilding
    factory_id
    building_key
    resource_level
    production_built
    build_state / upgrade_state

  FactoryCompartment
    building_id
    compartment_key
    level
    unlock_state

  FactoryCraftJob
    compartment_id
    line_no
    recipe_key
    status: running | ready | cooldown | cancelled
    started_at / finishes_at / cooldown_until
    reserved_inputs
    output_payload

  FactoryCatalog*
    buildings
    compartments
    recipes
    level_requirements
    resource_rates
    prices

  Главный риск: инвентарь. Фабрика потребляет и производит много сущностей: импульсы, XDV, игровые доллары,
  кирпичи, детали токена, ЭвоГены, ДНК, фрагменты, пэты, мутагены, обнуляторы, капсулы опыта. Нужен единый
  inventory ledger или хотя бы адаптер к существующим инвентарным таблицам, иначе будут баги с двойным
  списанием, возвратом ресурсов, отменой крафта и истечением подписки.

  Как фазировать:

  1. Backend skeleton новой фабрики: каталог, модели, миграция, route, state endpoint.
  2. Уровни 1-2: карта, ресурсные цеха, кирпичный цех, жизненная сила, склад/хранилище, сбор импульсов.
  3. Производство: craft jobs, линии, ready/collect/cooldown, отмена/возврат.
  4. Подписки: Step Pass Pro и Trademaster как modifiers, не как if-ветки по всему коду.
  5. Frontend: сначала headless API + простая UI-сборка, потом полноценная карта/анимации по дизайнерскому
     ТЗ.
  6. Уровни 3-8: добавление данных в каталог, не новая логика.

  Вывод: реализовать сложно, но нормально, если не пытаться чинить старую фабрику. Правильный путь —
  удалить legacy реализацию, сохранить только полезные продуктовые понятия и построить новый
  конфигурируемый домен вокруг транзакционного инвентаря, craft jobs и balance catalog. Файлы не менял, это
  был только explore-разбор.


Понял. Тогда границу лучше зафиксировать так:

  Фабрика живет в diaweb как web-only игровой модуль. Мобильное приложение не реализует фабрику, не рисует
  карту, не управляет цехами, не запускает крафты. Его будущая задача только поддержать источник импульсов
  и, возможно, вход/переход в web-фабрику.

  Я бы делал так:

  Mobile app
    -> считает/синхронизирует шаги
    -> вызывает существующий/новый backend collect для импульсов
    -> может открыть web factory deep link

  diaweb
    -> весь UI фабрики
    -> карта, склад, цеха, крафт, инвентарь фабрики, подписка, анимации
    -> BFF /api/cabinet/factory/*

  diaverseapi
    -> доменная правда фабрики
    -> баланс, таймеры, ресурсы, крафт jobs, прогресс, транзакции

  Главное решение: не делать фабрику “frontend-only”. На фронтенде должна быть богатая визуальная оболочка,
  но вся экономика, списания, заморозка ресурсов, таймеры, кулдауны, очереди, сбор, автосборщик и проверка
  подписки должны жить в backend. Иначе будут дубли, расхождения времени, баги с повторным сбором и
  возможность накрутки.

  Для diaweb я бы закладывал отдельный модуль:

  frontend/modules/factory/
    api.ts              # BFF client + нормализация payload
    types.ts            # frontend DTO/domain view types
    constants.ts        # query keys, timings, routes
    hooks/              # useFactoryState, mutations, timers
    components/
      FactoryMap
      FactoryHeader
      BuildingInfoBubble
      FactoryWarehouseScreen
      ResourceWorkshopScreen
      ProductionWorkshopScreen
      CompartmentScreen
      FactoryInventoryDrawer
      FactoryUpgradeDialog
      SlotTokenDialog
    assets/
    factory.module.css

  Маршруты:

  /[lang]/factory
  /[lang]/factory/warehouse
  /[lang]/factory/workshops/[workshopKey]
  /[lang]/factory/workshops/[workshopKey]/compartments/[compartmentKey]

  BFF в diaweb:

  app/api/cabinet/factory/state/route.ts
  app/api/cabinet/factory/workshops/[workshopKey]/build/route.ts
  app/api/cabinet/factory/workshops/[workshopKey]/upgrade/route.ts
  app/api/cabinet/factory/warehouse/transfer/route.ts
  app/api/cabinet/factory/craft/start/route.ts
  app/api/cabinet/factory/craft/collect/route.ts
  app/api/cabinet/factory/slot-token/assemble/route.ts

  Для мобильного разработчика потом достаточно будет дать короткое ТЗ:

  1. Не реализовывать фабрику внутри приложения.
  2. Убедиться, что шаги корректно уходят в backend.
  3. Добавить/проверить действие “собрать импульсы” из шагов, если его еще нет.
  4. При необходимости добавить кнопку/баннер “Фабрика” с открытием web URL в diaweb.
  5. Не хранить фабричное состояние локально в mobile app.

  Архитектурно самый senior-вариант: diaweb = визуальный клиент и BFF, diaverseapi = authoritative factory
  domain, mobile app = источник шагов и входная точка. Это даст нормальную масштабируемость под уровни 1-8
  и не привяжет механику к конкретному клиенту.


› окей, что по архитектуре diaverseapi? как лучше сделать? что нельзя упустить? и так далее. senior/lead
  подход


• Продолжаю в режиме aif-explore: это архитектурный разбор без изменений в коде. Сейчас быстро сверю
  backend-опоры через GBrain и исходники, чтобы рекомендации легли на реальные домены diaverseapi, а не на
  абстрактную “чистую архитектуру”.


 Да. Для diaverseapi я бы делал не “набор эндпоинтов фабрики”, а новый bounded context с серверной
  экономикой как источником правды.

  Главное Решение

  diaweb
    UI + BFF + анимации + countdown display
          |
          v
  diaverseapi/app/factory
    server authority: правила, таймеры, транзакции, инвентарь, подписки
          |
          +--> user_resources / characters / shards / subscriptions / payments

  Старый app/factory уже удалён, поэтому нормальное имя можно вернуть: app/factory, без factory_v3 в
  долгую. Публичный путь лучше сделать не старый /factory, а кабинетный: /api/v1/cabinet/factory, потому
  что это authenticated web-cabinet функция. В diaweb потом будет same-origin BFF /api/cabinet/factory/*,
  по аналогии с магазином.

  Структура Модуля

  diaverseapi/app/factory/
    api.py
    dependencies.py
    schemas.py
    models.py
    repositories.py

    catalog/
      data/                  # versioned balance yaml/json
      loader.py              # загрузка + Pydantic validation
      seed.py                # optional DB sync
      types.py

    domain/
      rules.py               # чистые функции: gates, levels, requirements
      modifiers.py           # подписки, бусты, ранний доступ
      timers.py              # расчет finish/cooldown/warehouse accrual
      errors.py
      value_objects.py

    services/
      state_service.py       # собрать snapshot для UI
      building_service.py    # build/upgrade/demolish
      warehouse_service.py   # склад -> хранилище -> инвентарь
      crafting_service.py    # start/collect/cooldown/queue
      slot_token_service.py
      booster_service.py
      subscription_resolver.py
      inventory_gateway.py
      payment_gateway.py

    tasks.py                 # только idempotent background/autocollect/notifications

  Я бы не размазывал правила по usecase-классам. Баланс должен быть data-driven: уровни, здания, ресурсные
  части, отсеки, рецепты, цены, требования перехода, early access, “в разработке”. Код исполняет
  универсальные правила, каталог описывает конкретику.

  Ключевые Таблицы

  factory_profiles
    user_id unique
    level
    tutorial_state
    catalog_version_seen

  factory_buildings
    user_id
    building_key
    resource_level
    production_state
    build_status
    build_finishes_at
    upgrade_finishes_at

  factory_compartments
    user_id
    building_key
    compartment_key
    level
    unlock_status

  factory_craft_jobs
    user_id
    job_id
    building_key
    compartment_key
    line_no
    recipe_key
    status: queued | running | ready | cooldown | collected | cancelled
    started_at
    finishes_at
    cooldown_until
    reserved_inputs_json
    output_snapshot_json
    catalog_version

  factory_warehouse_balances
    user_id
    resource_type
    warehouse_quantity
    storage_quantity
    last_accrual_at
    stopped_at

  factory_command_idempotency
    user_id
    key
    command
    result_json

  Отдельно: нужен ledger. Сейчас есть UserResource с уникальностью user_id/resource_id, и уже есть
  slot_token, token_details, impulse в diaverseapi/app/shards_and_resources/models.py:17. Но для фабрики
  одного баланса мало. Минимум нужен factory_inventory_movements или общий inventory ledger: кто, когда,
  почему списал/заморозил/вернул/начислил. Иначе потом невозможно разбирать дубли, возвраты и спорные
  кейсы.

  Что Нельзя Упустить

  1. Идемпотентность всех POST. Build, upgrade, craft start, collect, warehouse transfer, slot token
     assembly. Повтор запроса не должен списывать второй раз.
  2. Серверное время. Frontend только показывает countdown. Все finishes_at, cooldown_until, ready state
     считает backend. State endpoint всегда возвращает server_time.
  3. Row locks и транзакции. На командах лочить factory_profiles/балансы пользователя. Особенно start
     craft, collect, transfer warehouse, assemble slot token.
  4. Резервация ресурсов. При запуске крафта ресурсы должны стать недоступны сразу. Практически: списать из
     UserResource и сохранить reserved_inputs_json в job. При отмене/истечении подписочной очереди вернуть
     через gateway.
  5. Catalog versioning. Активный craft/job должен хранить snapshot входа/выхода и catalog_version, чтобы
     изменение баланса завтра не ломало вчерашний крафт.
  6. Подписки как modifiers, не if-ветки. В коде уже есть factory_step_pass_pro и factory_trademaster в
     diaverseapi/app/subscriptions/models.py:20, а Trademaster уже используется биржей как feature
     diaverseapi/app/exchange/external/subscription_service.py:48. Фабрике нужен FactoryModifierResolver:
     resource multiplier, build speed, craft speed, queue enabled, lines enabled, cooldown multiplier,
     autocollect.
  7. Склад считать lazy. Не делать cron “каждый час начислить всем ресурсы”. Хранить last_accrual_at, rate
     и 10h cap. На GET state показывать расчет, на transfer фиксировать. Для Trademaster autocollect можно
     добавить idempotent task, но core должен работать и без него.
  8. Платежи не внутри фабрики. Покупки за реальные деньги должны идти через существующий payment/shop
     контур. Фабрика получает факт успешной оплаты или создает checkout request через adapter. Игровые
     ресурсы/кирпичи/XDV списывает сама в транзакции.
  9. Frontend не должен решать allow/deny. State endpoint должен возвращать available_actions, lock_reason,
     requirements, missing_resources. UI только отображает.
  10. Удаление/merge пользователя. Новые таблицы фабрики сразу добавить в cleanup path и тесты, чтобы не
     повторить проблему старой фабрики.

  API Контракт

  GET  /api/v1/cabinet/factory/state
  GET  /api/v1/cabinet/factory/catalog

  POST /api/v1/cabinet/factory/open
  POST /api/v1/cabinet/factory/levels/upgrade
  POST /api/v1/cabinet/factory/buildings/{building_key}/resource/upgrade
  POST /api/v1/cabinet/factory/buildings/{building_key}/production/build
  POST /api/v1/cabinet/factory/buildings/{building_key}/compartments/{compartment_key}/upgrade
  POST /api/v1/cabinet/factory/warehouse/transfer-to-storage
  POST /api/v1/cabinet/factory/warehouse/transfer-to-inventory
  POST /api/v1/cabinet/factory/craft-jobs
  POST /api/v1/cabinet/factory/craft-jobs/{job_id}/collect
  POST /api/v1/cabinet/factory/slot-tokens/assemble

  MVP Порядок

  1. Catalog + validation + state snapshot.
  2. DB models/migration + empty factory open.
  3. Resource buildings + warehouse lazy accrual.
  4. Level 1-2 progression gates.
  5. Brick workshop craft jobs.
  6. Slot token assembly.
  7. Subscription modifiers.
  8. Queues/autocollect.
  9. Levels 3-8 mostly добавлением catalog data.

  Самая важная мысль: фабрика должна быть маленьким экономическим движком внутри diaverseapi, а не “еще
  одним CRUD”. UI можно красиво менять, но серверная модель должна держать инварианты: нельзя списать
  дважды, нельзя собрать раньше времени, нельзя обойти подписку, нельзя сломать активный craft изменением
  баланса.


Да, перечитал research1.md и заново сверил с механикой, дизайнерским ТЗ и кодом. Главный вывод: фабрика
  должна быть новым bounded context в diaverseapi, а не восстановлением старого factory. Сейчас
  diaverseapi/app/factory отсутствует, старые следы остались только как legacy cleanup и отдельные таблицы/
  утилиты, их нельзя брать как архитектурный образец.

  Опорные файлы: docs/tasks/fabric/research1.md:1, docs/tasks/fabric/factory-mechanics-final.md:252, docs/
  tasks/fabric/factory-designer-brief-levels-1-2-8.md:889. По коду важны diaverseapi/app/
  shards_and_resources/models.py:17, diaverseapi/app/subscriptions/models.py:20, diaverseapi/app/routers/
  v1/endpoints.py:69, BFF pattern в diaweb/frontend/app/api/cabinet/shop/_utils.ts:1.

  Правильная Архитектура

  diaweb UI
    -> diaweb BFF /api/cabinet/factory/*
      -> diaverseapi /v1/cabinet/factory/*
        -> FactoryCommandService
          -> Catalog + Domain Policies
          -> InventoryGateway / PaymentGateway / SubscriptionModifierResolver
          -> factory_* tables + ledger + existing UserResource/users/subscriptions/payments

  diaweb отвечает за экран, анимации, React Query, BFF и мобильный web UX. diaverseapi отвечает за всю
  экономику: списания, резервы, таймеры, кулдауны, склад, очередь, автосборщик, подписки, платежи,
  идемпотентность. Мобильное приложение не получает фабричный UI; максимум позже: сбор/синк шагов,
  начисление импульсов, deep link/webview в фабрику.

  Backend-Модуль

  Делать чистый diaverseapi/app/factory, но с новыми таблицами, не factories/factory_workshops из legacy.

  app/factory/
    api.py
    schemas.py
    dependencies.py
    models.py
    catalog/
      loader.py
      schema.py
      factory_catalog.v1.yaml
    domain/
      policies.py
      modifiers.py
      timers.py
      pricing.py
      requirements.py
    application/
      state_service.py
      command_service.py
      warehouse_service.py
      crafting_service.py
      slot_token_service.py
      payment_service.py
    infrastructure/
      repositories.py
      inventory_gateway.py
      payment_gateway.py
      subscription_resolver.py
    tasks.py

  Ключевая идея: фабрика не CRUD, а маленький экономический движок.

  Данные

  Минимальный набор таблиц:

  - factory_profiles: user_id, level, status, catalog_version, onboarding/tutorial flags.
  - factory_buildings: building_key, resource_level, resource_status, production_status, last_accrual_at.
  - factory_compartments: building_key, compartment_key, level, status, repair_until.
  - factory_craft_jobs: queue/running/ready/cooldown/collected/cancelled, line_index, recipe_key,
    catalog_version, inputs_snapshot, outputs_snapshot, modifiers_snapshot.
  - factory_warehouse_balances: warehouse/storage amounts separately from global inventory.
  - factory_ledger_entries: every debit, reserve, refund, grant, warehouse transfer, autocollect.
  - factory_command_idempotency: every POST must replay safely.
  - optional but likely needed: factory_booster_hires, factory_payment_orders, factory_impulse_claims.

  Existing UserResource has slot_token, token_details, impulse, bricks, gears, bullets, galaglue, acorns,
  DNA, biomass/nullifiers. But UserResource is only balance, not audit/reservation. For factory this is
  insufficient without ledger.

  Что Нельзя Упустить

  1. Идемпотентность всех POST: build, upgrade, craft, collect, cancel, transfer, slot-token assemble,
     payment finalizer.
  2. request_hash в idempotency: тот же ключ с другим payload должен быть ошибкой.
  3. Все команды через transaction + row locks по factory_profile и балансам.
  4. Серверное время. UI только рисует countdown от server_time.
  5. Lazy timers: не cron на каждый craft/resource. На read/command делать settle(now).
  6. Warehouse accrual с 10h cap и decimal/scale policy, потому что добыча дробная.
  7. Резерв ресурсов при постановке craft/queue: списать или зарезервировать сразу, вернуть при cancel/
     expiry.
  8. Catalog version + snapshots у активных jobs, иначе баланс-патч сломает старые крафты.
  9. Подписки как FactoryModifierResolver, а не if trademaster по всему коду.
  10. Expiry подписки: вернуть очередь, выключить автосборщик, сбросить extra-lines, пересчитать modifiers.
  11. Slot token drop x5/x10 из сундуков затрагивает chest/loot domain, не только factory API.
  12. Реальные деньги только через существующий cabinet payments/finalizer, не внутри command service.
  13. $ в ТЗ надо нормализовать: real money, game dollars, XDV, brick price должны быть разными price.kind.
  14. Frontend не решает allow/deny. Backend возвращает available_actions, lock_reason,
     missing_requirements.
  15. Merge/delete пользователя: новые factory_* таблицы сразу добавить в cleanup/merge.
  16. Observability: structured logs/metrics по командам, ledger, refunds, idempotency replay, payment
     finalization.
  17. Admin/support visibility: минимум read-only audit по фабрике, иначе спорные списания нечем разбирать.
  18. Catalog validation tests обязательны до UI.

  API

  Базовый backend contract:

  GET  /v1/cabinet/factory/state
  GET  /v1/cabinet/factory/catalog
  POST /v1/cabinet/factory/open
  POST /v1/cabinet/factory/levels/upgrade
  POST /v1/cabinet/factory/buildings/{building}/build
  POST /v1/cabinet/factory/buildings/{building}/resource/upgrade
  POST /v1/cabinet/factory/compartments/{compartment}/upgrade
  POST /v1/cabinet/factory/warehouse/transfer
  POST /v1/cabinet/factory/craft-jobs
  POST /v1/cabinet/factory/craft-jobs/{job_id}/collect
  POST /v1/cabinet/factory/craft-jobs/{job_id}/cancel
  POST /v1/cabinet/factory/slot-tokens/assemble
  POST /v1/cabinet/factory/payments/checkout

  Главные Открытые Вопросы

  До плана надо зафиксировать 4 вещи: что именно значит $ в разных местах ТЗ; где canonical XDV balance и
  как его списывать; при expiry подписки отменяется весь текущий craft или только queue/extra-lines; какие
  factory-сущности уже являются существующими item/resource keys, а какие надо добавить в каталог.

  Файлы не менял: это был explore-разбор.

 а что по дизайну? тебе все понятно? мне, получается, нужно будет залить картинки?


• Да, по UX и состояниям в целом понятно: mobile-first фабрика, карта, здания, склад, отсеки, очереди,
  модалки, repair state, подписки, автосборщик, уведомления. Но для финального вида нужны визуальные
  ассеты. Без картинок можно сделать только рабочий прототип с placeholder-графикой.

  Лучший формат для разработки: не просто “залить картинки”, а дать один из вариантов:

  1. Figma-макет с экранами A1-A18 и экспортируемыми слоями.
  2. Asset pack в папку типа diaweb/frontend/public/factory/....
  3. Ссылка/архив с PNG/WebP/SVG и описанием, что к чему относится.

  Что нужно минимум:

  - карта фабрики для уровней 1, 2 и 8;
  - здания/цеха по состояниям: locked, ruins, building, ready, active, upgrade, repair, disabled;
  - центральный склад/хранилище;
  - иконки ресурсов: импульсы, XDV, патроны, галаклей, жёлуди, шестерёнки, кирпичи, ДНК, токен слота,
    детали токена;
  - иконки production-сущностей: жизненная сила, питомцы/фрагменты, эво/мутагены, nullifiers, biomass и
    т.д.;
  - бейджи подписок: no sub, Step Pass Pro, Trademaster;
  - UI-иконки: очередь, автосборщик, таймер, кулдаун, ремонт, collect, upgrade, demolition;
  - статичные кадры для важных анимаций: строительство, сбор, взрыв/ремонт, сборка токена, финальный 8
    уровень.

  Для senior-подхода я бы не хардкодил картинки в компонентах. В factory catalog у каждого building/
  resource/recipe должен быть visual_key, а фронт мапит visual_key -> asset. Тогда backend управляет
  сущностями и состояниями, а frontend спокойно меняет визуал без переписывания логики.

  Если картинки пока не готовы, можно начинать backend + frontend skeleton с временными ассетами. Но перед
  финальной UI-сборкой нужен нормальный art pack/Figma, иначе фабрика будет выглядеть как технический
  прототип, а не игровая фича.



› что ты имеешь в виду под временными ассетами? и многое из этого уже есть:  карта фабрики для уровней 1,
  2 и 8;
    - здания/цеха по состояниям: locked, ruins, building, ready, active, upgrade, repair, disabled;
    - центральный склад/хранилище;
    - иконки ресурсов: импульсы, XDV, патроны, галаклей, жёлуди, шестерёнки, кирпичи, ДНК, токен слота,
      детали токена;
    - иконки production-сущностей: жизненная сила, питомцы/фрагменты, эво/мутагены, nullifiers, biomass и
      т.д.;
    - бейджи подписок: no sub, Step Pass Pro, Trademaster;
    - UI-иконки: очередь, автосборщик, таймер, кулдаун, ремонт, collect, upgrade, demolition;
    - статичные кадры для важных анимаций: строительство, сбор, взрыв/ремонт, сборка токена, финальный 8
      уровень.


• Под “временными ассетами” я имел в виду dev-заглушки: простые прямоугольники, силуэты зданий,
  placeholder-иконки или rough exports, чтобы фронтендер мог собрать логику, клики, состояния, таймеры и
  layout до финального арта.

  Если многое уже есть, временные ассеты не нужны. Тогда нужна не просто пачка картинок, а
  структурированный asset pack.

  Я бы просил подготовить так:

  public/factory/
    maps/
      level-1.webp
      level-2.webp
      level-8.webp
    buildings/
      gear/
        locked.webp
        ruins.webp
        building.webp
        active.webp
        upgrade.webp
        repair.webp
        disabled.webp
      brick/
        ...
    warehouse/
      level-1.webp
      level-2.webp
      level-8.webp
    resources/
      impulse.svg
      xdv.svg
      gear.svg
      brick.svg
      slot-token.svg
    production/
      life-force.svg
      biomass-rare.svg
      nullifier-base.svg
    subscriptions/
      none.svg
      step-pass-pro.svg
      trademaster.svg
    effects/
      build-frame.webp
      collect-frame.webp
      explosion-frame.webp
      slot-token-assemble.webp

  Самое важное: для карты лучше не только одна цельная картинка. Нужен один из двух вариантов:

  Вариант A, лучший: фон карты отдельно + здания отдельными прозрачными PNG/WebP слоями. Тогда фронт сможет
  менять состояния зданий, подсвечивать, анимировать, показывать repair/building/ready.

  Вариант B, быстрый: цельная карта уровня + невидимые clickable hotspots. Тогда нужны координаты зон клика
  для каждого здания на уровнях 1, 2, 8. Это быстрее, но хуже для анимаций и смены состояний.

  Для разработчика нужен asset manifest, например:

  {
    visualKey: "building.brick",
    state: "repair",
    level: 1,
    src: "/factory/buildings/brick/repair.webp",
    width: 220,
    height: 180,
    x: 128,
    y: 420,
    zIndex: 30
  }

  Тогда backend возвращает не путь к картинке, а visual_key, например brick_workshop, slot_token,
  trademaster. Frontend сам мапит это на ассеты. Это правильно: backend не должен знать файловую структуру
  UI.

  Картинки лучше давать в webp/png для арта, svg для простых UI/resource icons. Названия файлов: латиница,
  kebab-case, без пробелов и кириллицы. Для каждого интерактивного здания желательно иметь прозрачный фон и
  одинаковую “точку посадки”, чтобы при смене active -> repair -> upgrade здание не прыгало.
  Да, это правильный путь.
 
   Закладываем вариант A как целевую архитектуру:
 
   карта = фон уровня
   здания = отдельные прозрачные слои
   эффекты = отдельные overlay-слои
   hotspots = координаты/полигоны поверх зданий
 
   А на первом этапе используем временные ассеты:
 
   - placeholder-фоны уровней 1, 2, 8;
   - простые прозрачные силуэты/карточки зданий по состояниям;
   - базовые SVG/иконки для ресурсов и действий;
   - mock effects для build/collect/repair/slot-token.
 
   Важно сразу сделать так, будто финальные ассеты уже придут:
 
   public/factory/
     maps/
     buildings/
     resources/
     production/
     subscriptions/
     ui/
     effects/
 
   И добавить assetManifest, где у каждого объекта есть:
 
   visualKey
   state
   level
   src
   width
   height
   x
   y
   zIndex
   anchor
   hitArea
 
   Тогда потом финальные картинки просто заменяются в public/factory/... и/или manifest, без переписывания
   компонентов и бизнес-логики.
 
   Для frontend-разработчика формулировка такая: не рисовать фабрику как одну статичную картинку и не
   хардкодить позиции в JSX. Делать scene renderer: фон карты + слои зданий из manifest + backend state.
