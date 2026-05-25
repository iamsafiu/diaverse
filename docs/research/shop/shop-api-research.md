# Shop API Research

❯ /aif-explore оказывается, магазина в бэкенде нет и вовсе. запросы, который делает сейчас фронтенд на питомцев(это
/v1/characters/character_market - это была раньше аренда - сейчас это неактуальный код вовсе. Все питомцы находятся в модуле characters. Как  
быть?) Что делать? мы хотели сделать Вариант С @shop(research).md. Магазина и вовсе нет(только для steppass), а для скинов, бустов, петов,  
шкатулок, ваучеров - нет. Это реализовано тоьлко в чатботе телеграма

● Это важное открытие. Давай разберёмся в реальной ситуации. Сначала посмотрю текущий код и исследования.

Searched for 2 patterns, read 4 files (ctrl+o to expand)

● Теперь посмотрю, что реально есть в бэкенде — какие эндпоинты для characters и market.

Searched for 3 patterns, read 2 files, listed 3 directories (ctrl+o to expand)

● Есть shops модуль! Посмотрю что в нём.

Read 2 files, listed 1 directory (ctrl+o to expand)

● Картина вырисовывается. Вот что я нашёл:

---

Реальное положение дел в бэкенде

╔════════════════════════════════════════════════════════════════════════════╗
║ ЧТО РЕАЛЬНО ЕСТЬ В БЭКЕНДЕ ║
╠════════════════════════════════════════════════════════════════════════════╣
║ ║
║ GET /v1/market?category=grade ✅ Грейды 1-4 (USD) ║
║ GET /v1/market?category=fitness_pass ✅ StepPass Basic/Pro (USD) ║
║ ║
║ GET /v1/characters/store ✅ Каталог всех питомцев ║
║ (это НЕ магазин, это справочник Character — без покупки!) ║
║ ║
║ GET /v1/characters/character_market ⚠️ Аренда (P2P маркет, ║
║ send_to_marker / receive / rent) НЕАКТУАЛЬНО) ║
║ ║
║ GET /v1/loot_boxes ✅ Справочник шкатулок ║
║ GET /v1/subscriptions/user ✅ Активные подписки юзера ║
║ GET /v1/vouchers ❓ Ваучеры ║
║ ║
║ GET /v1/shops ✅ Ивентовый магазин ТОЛЬКО ║
║ GET /v1/shops/{id}/items ✅ Товары ивент-магазина ║
║ POST /v1/shops/{id}/items/{id}/purchase ✅ Покупка ивент-товара ║
║ ║
╠════════════════════════════════════════════════════════════════════════════╣
║ ЧЕГО НЕТ В БЭКЕНДЕ ║
╠════════════════════════════════════════════════════════════════════════════╣
║ ║
║ ❌ Покупка питомцев за XDV/USD (только через чатбот Telegram) ║
║ ❌ Покупка скинов ║
║ ❌ Покупка бустов ║
║ ❌ Покупка шкатулок за XDV/USD ║
║ ❌ Покупка ваучеров ║
║ ❌ Основной магазин (shops: main = TODO) ║
║ ❌ Клановый магазин (shops: clan = TODO) ║
║ ❌ VIP магазин (shops: vip = TODO) ║
║ ❌ Ежедневные предложения (ShopType.daily = TODO) ║
║ ║
╚════════════════════════════════════════════════════════════════════════════╝

Ключевой вывод

Вариант C из research.md оказался построен на ложных предпосылках. Он предполагал, что бэкенд-эндпоинты для покупок уже существуют и фронт  
 просто агрегирует данные из них. Реальность:

    ПРЕДПОЛАГАЛИ (Вариант C)              РЕАЛЬНОСТЬ
    ────────────────────────              ──────────
    GET /characters/store → покупка   →  Только каталог, нет purchase
    GET /loot_boxes → покупка         →  Только каталог, нет purchase
    GET /market → покупка             →  Грейды/пассы — покупка через
                                         Telegram бот, а не API

    Единственная РЕАЛЬНАЯ покупка     →  /v1/shops/{id}/items/{id}/purchase
    через API:                            (только ивентовый магазин)

Три варианта, как быть

╔══════════════════════════════════════════════════════════════════╗
║ ВАРИАНТ 1: "Витрина без покупки" (только каталог) ║
╠══════════════════════════════════════════════════════════════════╣
║ ║
║ Фронт показывает товары, кнопка → редирект в Telegram бот ║
║ ║
║ ┌──────────────┐ ┌──────────────┐ ┌────────────┐ ║
║ │ ShopPage │──────>│ Каталог из │─────>│ "Купить │ ║
║ │ (веб) │ │ /store, │ │ в боте" │ ║
║ │ │ │ /market, │ │ [ссылка] │ ║
║ │ │ │ /loot_boxes │ └────────────┘ ║
║ └──────────────┘ └──────────────┘ ║
║ ║
║ Backend: НЕ ТРОГАЕМ ║
║ Покупка: через существующий Telegram бот ║
║ ║
║ ✅ Ноль бэкенд-работы ║
║ ✅ Можно сделать сейчас ║
║ ❌ UX: "зачем магазин если купить нельзя" ║
║ ❌ Бессмысленно долгосрочно ║
╚══════════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════════════════════════════╗
║ ВАРИАНТ 2: "Бэкенд-фасад с покупками" ║
║ (= изначальный Вариант B, но теперь единственный рабочий) ║
╠══════════════════════════════════════════════════════════════════╣
║ ║
║ Создаём app/cabinet/shop/ в diaverseapi ║
║ ║
║ GET /v1/cabinet/shop/catalog ║
║ └── агрегирует: market + characters + loot_boxes ║
║ ║
║ POST /v1/cabinet/shop/purchase ║
║ └── вызывает СУЩЕСТВУЮЩИЕ use case: ║
║ ├── AddUserCharacterUseCase (для петов) ║
║ ├── ... (для грейдов — что сейчас?) ║
║ └── ... (для шкатулок — что сейчас?) ║
║ ║
║ ✅ Полноценный магазин в вебе ║
║ ✅ Переиспользует существующие use case ║
║ ❌ Нужна бэкенд-работа (но она неизбежна) ║
║ ❌ Нужно разобраться: КАК сейчас бот делает покупку? ║
╚══════════════════════════════════════════════════════════════════╝

╔══════════════════════════════════════════════════════════════════╗
║ ВАРИАНТ 3: "Только то, что реально продаётся через API" ║
║ (минимальный MVP) ║
╠══════════════════════════════════════════════════════════════════╣
║ ║
║ Phase 1: только Грейды + StepPass (уже есть в /market) ║
║ + Ивентовый магазин (уже есть в /shops) ║
║ ║
║ Покупка грейдов/пассов: ║
║ → Если бот делает это через Telegram Payment API, ║
║ для веба нужен свой payment flow (крипта? RUB?) ║
║ → Или кнопка "Оплатить" → deeplink в Telegram ║
║ ║
║ Phase 2: бэкендер добавляет purchase endpoints ║
║ Phase 3: расширяем каталог (петы, шкатулки, бусты) ║
║ ║
║ ✅ Минимум бэкенд-работы на старте ║
║ ✅ Инкрементальное расширение ║
║ ⚠️ Ограниченный магазин на старте ║
╚══════════════════════════════════════════════════════════════════╝

Критический вопрос

Прежде чем выбирать — нужно ответить на один ключевой вопрос:

▎ Как Telegram бот сейчас обрабатывает покупку питомцев, грейдов, шкатулок?

▎ - Через Telegram Payments API (Stars)?
▎ - Через внутреннюю валюту (XDV)?
▎ - Через внешний payment provider?

Если покупка идёт через XDV — то создать POST /v1/cabinet/shop/purchase относительно просто: списываем XDV, вызываем существующий use case.  
 Это Вариант 2 без payment provider.

Если через Telegram Payments / Stars — то для веба нужен отдельный payment flow (Stripe, крипта, банковские карты), и это совсем другой  
 масштаб работы.

---

Что касается фронтенда: текущий код в modules/shop/api.ts — это ~900 строк нормализации данных из эндпоинтов, которые не поддерживают  
 покупку. Этот код не бесполезен (каталог показывать можно), но кнопка "Купить" в нём — это заглушка (PurchaseIntent определён, но нигде не  
 вызывается).

Как видишь ситуацию? Бэкендер готов пилить purchase endpoint, или пока витрина + deeplink?

✻ Crunched for 1m 34s

❯ вот что пишет бэкендер: Мы начинали делать для приложения,shops, но по факту реализован только ивентовый

● Ясно. Значит ситуация подтверждается: shops модуль — это только ивентовый магазин, а основной (main, clan, vip) — TODO-заглушки.

Давай уточню ещё один момент — как бот продаёт петов и грейды сейчас.

Searched for 2 patterns (ctrl+o to expand)

● Есть payment модуль со stars и mobile. Это и есть ответ на вопрос "как бот продаёт".

Read 3 files, listed 1 directory (ctrl+o to expand)

● Теперь картина полная. Вот итог:

---

Полная карта оплат в diaverseapi

╔═══════════════════════════════════════════════════════════════════════════╗
║ PAYMENT FLOW (как есть) ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ║
║ POST /v1/payment/telegram-stars ║
║ → product_id (UUID из market_products) ║
║ → возвращает invoice_link (Telegram Stars) ║
║ → webhook подтверждает → PaymentRewardContext.apply() ║
║ ║
║ POST /v1/payment/mobile/purchase ║
║ → product_id (UUID из market_products) ║
║ → Apple/Google Pay через RevenueCat ║
║ → webhook подтверждает → те же reward strategies ║
║ ║
║ PaymentRewardContext.apply(user_id) ║
║ ├── FitnessPassRewardStrategy (category=fitness_pass) ║
║ └── GradeRewardStrategy (category=grade) ║
║ ║
║ ❗ Только 2 категории поддерживают покупку: ║
║ fitness_pass и grade ║
║ ║
║ ❗ Питомцы покупаются через бот (НЕ через payment API): ║
║ POST /v1/characters { character_id } ║
║ → AddUserCharacterUseCase (списывает XDV напрямую?) ║
║ ║
║ ❗ Ивентовые товары — отдельная система: ║
║ POST /v1/shops/{id}/items/{id}/purchase ║
║ → списывает event_token, не Stars/USD ║
║ ║
╚═══════════════════════════════════════════════════════════════════════════╝

Что это значит для веб-магазина

╔═══════════════════════════════════════════════════════════════════════════╗
║ МАТРИЦА: ЧТО МОЖНО ПРОДАВАТЬ В ВЕБЕ ║
╠══════════════════════════╦════════════╦═══════════╦═══════════════════════╣
║ Товар ║ Каталог ║ Покупка ║ Что нужно для веба ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Грейды (1-4) ║ /market ║ payment/_ ║ Нужен web payment ║
║ ║ ✅ ║ Stars/ ║ provider (не Stars!) ║
║ ║ ║ Mobile ║ ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ StepPass Basic/Pro ║ /market ║ payment/_ ║ Нужен web payment ║
║ ║ ✅ ║ Stars/ ║ provider ║
║ ║ ║ Mobile ║ ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Питомцы ║ /characters║ POST / ║ Уже за XDV? ║
║ ║ /store ✅ ║ characters║ Если да — можно! ║
║ ║ ║ (XDV?) ║ ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Шкатулки ║ /loot*boxes║ ❌ НЕТ ║ Нужен purchase API ║
║ ║ ✅ ║ ║ ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Скины ║ ❌ нет API ║ ❌ НЕТ ║ Нужно всё с нуля ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Бусты/ваучеры ║ /vouchers? ║ ❌ НЕТ ║ Нужен purchase API ║
╠══════════════════════════╬════════════╬═══════════╬═══════════════════════╣
║ Ивентовые товары ║ /shops ✅ ║ ✅ ║ Уже работает! ║
║ ║ ║ event* ║ (за event_token) ║
║ ║ ║ token ║ ║
╚══════════════════════════╩════════════╩═══════════╩═══════════════════════╝

Моя обновлённая рекомендация

Учитывая что магазина нет, а payment flow завязан на Telegram Stars и Mobile — вот реалистичный план:

╔═══════════════════════════════════════════════════════════════════════════╗
║ ФАЗА 1: "Каталог + то, что уже покупается" ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ║
║ 1. Ивентовый магазин (ПОЛНОСТЬЮ РАБОЧИЙ) ║
║ └── /v1/shops — каталог, покупка за event_token ║
║ Фронт подключается напрямую, всё есть ║
║ ║
║ 2. Питомцы за XDV (ПРОВЕРИТЬ с бэкендером) ║
║ └── POST /v1/characters — списывает XDV? ║
║ Если да → можно покупать из веба прямо сейчас ║
║ Если нет → витрина + "Доступно в боте" ║
║ ║
║ 3. Грейды + StepPass (ВИТРИНА) ║
║ └── Каталог из /market, кнопка → "Оплатить" ║
║ → Для веба нужен payment provider (Stripe? Крипта? YooKassa?) ║
║ → Reward strategies уже есть, нужна только оплата ║
║ ║
║ 4. Шкатулки (ВИТРИНА, coming soon) ║
║ └── Каталог из /loot_boxes, без покупки пока ║
║ ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ФАЗА 2: Web Payment Provider (бэкенд-работа) ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ║
║ POST /v1/payment/web/purchase ← НОВЫЙ endpoint ║
║ → product_id ║
║ → payment_method: "crypto" | "card" | "rub" ║
║ → Реюзает PaymentRewardContext.apply() ║
║ → Нужен web payment provider ║
║ ║
║ После этого: Грейды и StepPass покупаются из веба ║
║ ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ФАЗА 3: Расширение каталога (бэкенд-работа) ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ║
║ - Добавить шкатулки, скины, бусты как market_products ║
║ - Расшить RewardStrategy для новых категорий ║
║ - shops: main/clan/vip ║
║ ║
╚═══════════════════════════════════════════════════════════════════════════╝

Ключевые вопросы к бэкендеру

1. POST /v1/characters — списывает XDV при добавлении? Если да — петов уже можно покупать из веба. Если нет — откуда бот списывает XDV?
2. Какой payment provider планируется для веба? Telegram Stars не работает в обычном браузере. Варианты: YooKassa (RUB), Stripe,
   крипто-gateway.
3. Готов ли он добавить POST /v1/payment/web/purchase? Логика наград (PaymentRewardContext) уже есть — нужна только новая точка входа с  
   другим payment flow.

---

Хочешь сохранить эти результаты в .ai-factory/RESEARCH.md?

✻ Cooked for 1m 4s

❯ окей, что делать в итоге? пилить новый модуль? если да, то где? в /cabinet или еще гдето?

● Конкретный ответ: да, app/cabinet/shop/ — по тому же паттерну, что cabinet/offers/advent/ и cabinet/rbac/.

Но давай определим что именно этот модуль делает, потому что он НЕ дублирует shops или market:

╔═══════════════════════════════════════════════════════════════════╗
║ Что уже есть и где ║
╠═══════════════════════════════════════════════════════════════════╣
║ ║
║ app/market/ → таблица market_products (grade, pass) ║
║ app/payment/ → Stars, Mobile payment + reward strategies ║
║ app/shops/ → ивентовый магазин (event_token) ║
║ app/characters/ → каталог петов, POST добавление ║
║ app/loot_boxes/ → каталог шкатулок ║
║ ║
║ Все эти модули ОСТАЮТСЯ КАК ЕСТЬ. Не трогаем. ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║ app/cabinet/shop/ — НОВЫЙ модуль ║
║ Роль: READ-ONLY фасад-агрегатор для веб-кабинета ║
╠═══════════════════════════════════════════════════════════════════╣
║ ║
║ GET /v1/cabinet/shop/catalog ║
║ └── Внутри читает из: ║
║ ├── market (grades, passes) ║
║ ├── characters (pets) ║
║ ├── loot_boxes (crates) ║
║ └── subscriptions (active subs) ║
║ └── Возвращает ЕДИНЫЙ ShopCatalog ║
║ ║
║ Этот модуль НЕ: ║
║ ❌ Создаёт свои таблицы ║
║ ❌ Дублирует данные ║
║ ❌ Трогает существующие модули ║
║ ║
║ Этот модуль ДЕЛАЕТ: ║
║ ✅ Один endpoint = весь каталог (вместо 5 запросов) ║
║ ✅ Нормализация на бэке (а не 900 строк в api.ts) ║
║ ✅ Web-специфичная логика (без наценки 30% Apple/Google) ║
║ ✅ Фильтрация по доступности для веб-платформы ║
║ ║
╚═══════════════════════════════════════════════════════════════════╝

Почему именно cabinet/shop/, а не расширять shops/

    app/shops/                         app/cabinet/shop/
    ──────────                         ─────────────────
    Ивентовый магазин                  Витрина веб-кабинета
    Своя БД (event_shop_items)         Без своих таблиц
    Своя валюта (event_token)          Агрегирует чужие данные
    Полный purchase flow               Пока read-only
    Используется и ботом               Только для веба

Это разные вещи. Мешать их в одном модуле — нарушить single responsibility.

Что делать прямо сейчас

╔═══════════════════════════════════════════════════════════════════╗
║ ПЛАН ДЕЙСТВИЙ ║
╠═══════════════════════════════════════════════════════════════════╣
║ ║
║ ШАГ 1 — Бэкенд: app/cabinet/shop/ (минимальный) ║
║ ║
║ cabinet/shop/ ║
║ ├── **init**.py ║
║ ├── api.py GET /v1/cabinet/shop/catalog ║
║ ├── schemas.py CabinetShopCatalog response schema ║
║ ├── service.py агрегирует из market, characters, ║
║ │ loot_boxes, subscriptions ║
║ └── dependencies.py DI ║
║ ║
║ Без миграций. Без новых таблиц. Только SELECT из чужих. ║
║ ║
║ ШАГ 2 — Фронтенд: упрощаем api.ts ║
║ ║
║ api.ts: 900 строк нормализации → ~30 строк ║
║ fetchShopCatalog() { ║
║ return apiClient.get("/v1/cabinet/shop/catalog"); ║
║ } ║
║ Вся нормализация переезжает на бэк. ║
║ ║
║ ШАГ 3 — (позже) Покупки ║
║ ║
║ POST /v1/cabinet/shop/purchase ║
║ Когда решите payment provider для веба — ║
║ добавляете в тот же модуль. ║
║ PaymentRewardContext уже есть, реюзаете. ║
║ ║
╚═══════════════════════════════════════════════════════════════════╝

Резюме

┌──────────────────────────────┬───────────────────────────────────────────┐
│ Вопрос │ Ответ │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Пилить новый модуль? │ Да │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Где? │ app/cabinet/shop/ │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Таблицы? │ Нет, только агрегация │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Трогаем существующие модули? │ Нет │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Что он даёт? │ 1 endpoint вместо 5, нормализация на бэке │
├──────────────────────────────┼───────────────────────────────────────────┤
│ Покупки? │ Позже, когда будет web payment provider │
└──────────────────────────────┴───────────────────────────────────────────┘

Единственное что нужно уточнить у бэкендера: готов ли он взять cabinet/shop/service.py — это его работа (он знает внутренности
market/characters/loot_boxes лучше). Фронтовую часть (переключение api.ts на один endpoint) мы можем подготовить параллельно.

Сохранить в RESEARCH.md?

✻ Brewed for 41s

❯ окей, в итоге что можно будет купить в веб магазине? оплата атм будет через эквайринг(юкасса) + крипта. То есть магазин ьудет реализован  
так: пользователь покупает, бэк начисляет в его профиль элемент оплаты(например пета) - через уже существующие эндпоинты. верно понял? а что  
можно будет купить в магазине? скины, бусты и все прочее убдет?
Питомцы

Редкий / Эпический / Легендарный зародыш

Скины

Пилотов, Петов

Бусты

Разные бустеры из раздела - инвентарь - Бусты
Этовсе будет?

● Давай проверю, что из этого реально существует в бэкенде как сущности.

Searched for 2 patterns, read 5 files, listed 3 directories (ctrl+o to expand)

● Отлично. Теперь полная картина. Вот реальность по каждой категории:

╔══════════════════════════════════════════════════════════════════════════════╗
║ АУДИТ: ЧТО ЕСТЬ В БЭКЕНДЕ ДЛЯ МАГАЗИНА ║
╠══════════════╦═══════════════════╦════════════════╦══════════════════════════╣
║ Категория ║ Каталог (GET) ║ Выдача юзеру ║ Покупка (оплата) ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Питомцы ║ GET /characters/ ║ POST ║ ❌ Нет purchase API ║
║ (зародыши) ║ store ✅ ║ /characters ✅ ║ Бот списывает XDV ║
║ ║ Character модель ║ AddUserChar ║ напрямую? ║
║ ║ ║ UseCase ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Скины петов ║ GET /pet-skins/ ║ POST /pet- ║ ❌ Нет purchase API ║
║ ║ character/{id} ✅ ║ skins/items/ ║ GrantSkinUseCase ║
║ ║ PetSkinDef модель ║ grant ✅ ║ = внутренний endpoint ║
║ ║ inventory ✅ ║ ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Скины ║ GET /pilot-skins ║ UserPilotSkin ║ ❌ Нет purchase API ║
║ пилотов ║ (нужно проверить) ║ модель ✅ ║ PilotSkin.cost ║
║ ║ PilotSkin модель ║ ║ существует (XDV?) ║
║ ║ ║ ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Бусты ║ GET /inventories/ ║ POST ║ ❌ Нет purchase API ║
║ ║ my-boosts ✅ ║ /inventories/ ║ add-boost = "админ/ ║
║ ║ ║ add-boost ✅ ║ магазин" (внутренний) ║
║ ║ ║ activate- ║ ║
║ ║ ║ boost ✅ ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Грейды ║ GET /market ║ Payment ║ ✅ Stars / Mobile ║
║ ║ ?category= ║ RewardContext ║ ❌ Нет web payment ║
║ ║ grade ✅ ║ → GradeReward ║ ║
║ ║ ║ Strategy ✅ ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ StepPass ║ GET /market ║ Payment ║ ✅ Stars / Mobile ║
║ ║ ?category= ║ RewardContext ║ ❌ Нет web payment ║
║ ║ fitness_pass ✅ ║ → FitnessPass ║ ║
║ ║ ║ Strategy ✅ ║ ║
╠══════════════╬═══════════════════╬════════════════╬══════════════════════════╣
║ ║ ║ ║ ║
║ Шкатулки ║ GET /loot_boxes ║ UseCase ✅ ║ ❌ Нет purchase API ║
║ ║ ✅ ║ (открытие) ║ ║
║ ║ ║ ║ ║
╚══════════════╩═══════════════════╩════════════════╩══════════════════════════╝

Паттерн

Видишь? Все категории имеют одинаковую дыру:

    Каталог ✅  →  Выдача юзеру ✅  →  Оплата ❌ (для веба)
                                           │
                         Бот делает это через Telegram Stars
                         или напрямую (внутренние endpoints)

Use case-ы для выдачи товара юзеру уже есть:

- AddUserCharacterUseCase — пет
- GrantSkinUseCase — скин пета
- add_boost_to_user — бусты
- PaymentRewardContext.apply() — грейды, пассы

Не хватает ровно одного слоя: "проверить оплату → вызвать use case".

Ответ на твой вопрос: что будет в магазине

╔══════════════════════════════════════════════════════════════════╗
║ ВЕБ-МАГАЗИН: ИТОГОВЫЙ НАБОР ║
╠══════════════════════════════════════════════════════════════════╣
║ ║
║ ПИТОМЦЫ (зародыши) ║
║ ├── Каталог: GET /characters/store ║
║ ├── Покупка: cabinet/shop → AddUserCharacterUseCase ║
║ └── Оплата: ЮKassa / крипта → списание → выдача ║
║ ║
║ СКИНЫ ПЕТОВ ║
║ ├── Каталог: GET /pet-skins/character/{id} ║
║ ├── Покупка: cabinet/shop → GrantSkinUseCase ║
║ └── Оплата: ЮKassa / крипта ║
║ ║
║ СКИНЫ ПИЛОТОВ ║
║ ├── Каталог: pilot_skins (модель есть, cost есть) ║
║ ├── Покупка: cabinet/shop → создать UserPilotSkin ║
║ └── Оплата: ЮKassa / крипта ║
║ ║
║ БУСТЫ ║
║ ├── Каталог: GET /inventories/my-boosts (типы бустов) ║
║ ├── Покупка: cabinet/shop → add_boost_to_user ║
║ └── Оплата: ЮKassa / крипта ║
║ ║
║ ГРЕЙДЫ + STEPPASS ║
║ ├── Каталог: GET /market ║
║ ├── Покупка: cabinet/shop → PaymentRewardContext.apply() ║
║ └── Оплата: ЮKassa / крипта (вместо Stars/Mobile) ║
║ ║
║ ШКАТУЛКИ (если нужно) ║
║ ├── Каталог: GET /loot_boxes ║
║ ├── Покупка: cabinet/shop → LootBox use case ║
║ └── Оплата: ЮKassa / крипта ║
║ ║
╚══════════════════════════════════════════════════════════════════╝

Архитектура cabinet/shop/ — что пилит бэкендер

    app/cabinet/shop/
    ├── api.py              ← 2 endpoint-а
    ├── schemas.py          ← response models
    ├── service.py          ← агрегация + purchase orchestration
    └── dependencies.py     ← DI

    GET  /v1/cabinet/shop/catalog
      → service читает из market, characters, loot_boxes,
        pet_skins, pilot_skins, inventories
      → возвращает единый CabinetShopCatalog

    POST /v1/cabinet/shop/purchase
      → принимает { product_type, product_id, payment_method }
      → проверяет оплату (ЮKassa callback / крипта confirm)
      → вызывает СУЩЕСТВУЮЩИЙ use case:
          switch(product_type):
            "pet"        → AddUserCharacterUseCase
            "pet_skin"   → GrantSkinUseCase
            "pilot_skin" → создать UserPilotSkin
            "boost"      → add_boost_to_user
            "grade"      → PaymentRewardContext.apply()
            "pass"       → PaymentRewardContext.apply()
            "crate"      → LootBox usecase

Что это значит

Да, всё перечисленное будет. Питомцы, скины (петов и пилотов), бусты — всё, потому что:

1. Модели в БД уже есть (Character, PetSkinDef, PilotSkin, boosts)
2. Use case-ы для выдачи уже есть
3. Каталоги (GET endpoints) уже есть
4. Не хватает только cabinet/shop/ фасада + web payment integration

Бэкендеру нужно написать по сути один сервис, который маршрутизирует purchase в правильный use case. Грейды/пассы вообще бесплатно —
PaymentRewardContext уже умеет их применять.

Сохранить в RESEARCH.md?

✻ Churned for 1m 10s

❯ обновление питомцев, скинов и так далее будет автоматически отображаться и в магазине? они подхватятся?

● Да, именно так. Поскольку cabinet/shop/ — это фасад-агрегатор без своих таблиц, он читает напрямую из источников:

    Бэкендер добавил нового пета         Автоматически в магазине?
    в таблицу characters
    ─────────────────────────             ─────────────────────────

    INSERT INTO characters (...)          GET /v1/cabinet/shop/catalog
                                            └── SELECT * FROM characters
                                                → новый пет уже в каталоге ✅

    INSERT INTO pet_skin_defs (...)       GET /v1/cabinet/shop/catalog
                                            └── SELECT * FROM pet_skin_defs
                                                → новый скин уже в каталоге ✅

    INSERT INTO pilot_skins (...)         То же самое ✅

    Новый тип буста                       То же самое ✅

У магазина нет своей копии данных. Он делает SELECT из чужих таблиц при каждом запросе. Добавили пета / скин / буст в БД → следующий GET  
 /catalog его покажет.

Это ключевое преимущество фасада перед отдельным каталогом — ноль синхронизации, единый источник правды.

Единственный нюанс: нужен флаг "продаётся ли это в вебе". Не всё из characters должно быть в магазине (например, ивентовые петы, которые  
 нельзя купить). Это решается одним из двух способов:

    Вариант A: фильтр в service.py
    ────────────────────────────────
    SELECT FROM characters
    WHERE cost_xdv > 0        ← если есть цена, значит продаётся
      AND subkind IS NULL      ← исключаем ивентовых

    Вариант B: флаг в таблице (бэкендер добавляет колонку)
    ────────────────────────────────
    ALTER TABLE characters ADD COLUMN is_web_purchasable BOOLEAN DEFAULT false;

    SELECT FROM characters WHERE is_web_purchasable = true

Вариант A — без миграций, можно начинать сразу. Вариант B — чище, но нужна миграция. Это вопрос к бэкендеру — какой предпочитает.

{
"id": "1",
"subject": "Backend: создать структуру модуля cabinet/shop/",
"description": "Создать модуль `app/cabinet/shop/` в diaverseapi по паттерну cabinet/admin и cabinet/offers/advent:\n\n`\napp/cabinet/shop/\n├── __init__.py\n├── api.py\n├── schemas.py\n├── service.py\n├── dependencies.py\n└── exceptions.py\n`\n\nЗарегистрировать роутер в `app/routers/v1/endpoints.py`:\n`python\nfrom app.cabinet.shop.api import router as cabinet_shop_router\n# ...\n(cabinet_shop_router, \"cabinet/shop\", \"cabinet_shop\"),\n`\n\nFiles: \n- diaverseapi/app/cabinet/shop/**init**.py\n- diaverseapi/app/cabinet/shop/api.py (заглушка router)\n- diaverseapi/app/cabinet/shop/schemas.py (заглушка)\n- diaverseapi/app/cabinet/shop/service.py (заглушка)\n- diaverseapi/app/cabinet/shop/dependencies.py (заглушка)\n- diaverseapi/app/cabinet/shop/exceptions.py (заглушка)\n- diaverseapi/app/routers/v1/endpoints.py (добавить роутер)\n\nLOGGING: DEBUG при инициализации модуля",
"activeForm": "Creating cabinet/shop module structure",
"status": "pending",
"blocks": [
"2"
],
"blockedBy": []
}
{
"id": "2",
"subject": "Backend: schemas.py — типы каталога и покупки",
"description": "Создать Pydantic-схемы для каталога и покупки в `app/cabinet/shop/schemas.py`:\n\n**Каталог:**\n- `CabinetShopCatalog` — корневой ответ (sections + user context)\n- `ShopSection` — id, title, items[]\n- `ShopItem` — uuid, title, description, image, icon, price (ShopPrice), item_type, rarity?, metadata?\n- `ShopPrice` — xdv: int | None, usd: float | None\n- `ShopUserContext` — grade, xdv_balance\n\n**Покупка:**\n- `PurchaseRequest` — item_type (enum), item_id (UUID), payment_method (enum: xdv | yukassa | crypto)\n- `PurchaseResponse` — success, item_granted (dict), new_balance?\n\n**Enums:**\n- `ShopItemType` — pet, pet_skin, pilot_skin, boost, grade, pass, crate\n- `PaymentMethod` — xdv, yukassa, crypto\n\nИспользовать чистый Pydantic BaseModel (не SQLModel).\n\nFiles: diaverseapi/app/cabinet/shop/schemas.py\n\nLOGGING: N/A (чистые типы)",
"activeForm": "Writing shop schemas",
"status": "pending",
"blocks": [
"3",
"4",
"8"
],
"blockedBy": [
"1"
]
}
{
"id": "3",
"subject": "Backend: service.py — CabinetShopService.get_catalog()",
"description": "Реализовать метод `get_catalog(user_id, user_grade)` в `CabinetShopService`:\n\nАгрегирует данные из существующих таблиц (только SELECT, без своих таблиц):\n\n1. **Питомцы**: `SELECT FROM characters WHERE cost > 0 AND subkind IS NULL` — исключаем ивентовых (subkind: halloween, christmas, etc.). Маппим в ShopItem.\n2. **Скины петов**: `SELECT FROM pet_skin_defs WHERE is_default = false AND is_soulbound = false` — только предметные, не привязанные. Маппим в ShopItem.\n3. **Скины пилотов**: `SELECT FROM pilot_skins WHERE cost > 0` — только с ценой. Маппим в ShopItem.\n4. **Бусты**: Подготовить список доступных типов бустов (hardcoded из InventoryService boost_type_map). Маппим в ShopItem.\n5. **Грейды**: `SELECT FROM market_products WHERE category = 'grade'` с фильтрацией по платформе (isTMA=True или без платформенного фильтра). Маппим в ShopItem.\n6. **StepPass**: `SELECT FROM market_products WHERE category = 'fitness_pass'`. Маппим в ShopItem.\n7. **Шкатулки**: `SELECT FROM loot_boxes` (каталог типов). Маппим в ShopItem.\n\nСобирает в `CabinetShopCatalog` с секциями по ShopItemType.\n\nТакже получает user context: `user.grade`, XDV balance из `user.xdv` или аналогичного поля.\n\nМаркирует owned items: для грейдов (targetGrade <= user.grade), для пассов (активная подписка), для петов (user_characters).\n\nFiles: diaverseapi/app/cabinet/shop/service.py\n\nLOGGING:\n- DEBUG: начало сборки каталога, кол-во items из каждого источника\n- DEBUG: финальные counts по секциям\n- WARN: если какой-то источник вернул пустой результат (неожиданно)",
"activeForm": "Implementing catalog service",
"status": "pending",
"blocks": [
"4",
"5"
],
"blockedBy": [
"2"
]
}
{
"id": "4",
"subject": "Backend: service.py — CabinetShopService.purchase()",
"description": "Реализовать метод `purchase(user_id, item_type, item_id, payment_method)` в `CabinetShopService`:\n\n**Общий flow:**\n1. Валидировать item_type + item_id (существует ли товар)\n2. Определить цену товара\n3. Проверить payment_method:\n - `xdv` → проверить баланс юзера, списать XDV, вызвать grant use case\n - `yukassa` / `crypto` → **пока заглушка** (raise NotImplementedError или специальное исключение ShopPaymentNotAvailable)\n4. Вызвать соответствующий grant use case:\n - `pet` → `AddUserCharacterUseCase(session).execute(user_id, item_id)`\n - `pet_skin` → `GrantSkinUseCase(session).execute(user_id, skin_def_id)`\n - `pilot_skin` → создать `UserPilotSkin(user_id=user_id, skin_id=item_id, status=SkinStatus.inactive)`\n - `boost` → `InventoryService(session).add_boost_to_user(user, boost_type, quantity=1)`\n - `grade` → `PaymentRewardContext(session, product_id).apply(user_id)`\n - `pass` → `PaymentRewardContext(session, product_id).apply(user_id)`\n - `crate` → создать `UserBox(user_id=user_id, box_id=item_id)`\n5. Вернуть PurchaseResponse\n\n**XDV deduction:**\n- `UPDATE users SET xdv = xdv - :cost WHERE uuid = :user_id AND xdv >= :cost`\n- Если rowcount == 0 → raise InsufficientBalance\n- Использовать SELECT ... FOR UPDATE для race condition protection\n\n**Exceptions (в exceptions.py):**\n- `ShopItemNotFound`\n- `InsufficientBalance`\n- `ItemAlreadyOwned`\n- `ShopPaymentNotAvailable` (для yukassa/crypto пока)\n\nFiles: \n- diaverseapi/app/cabinet/shop/service.py\n- diaverseapi/app/cabinet/shop/exceptions.py\n\nLOGGING:\n- INFO: purchase attempt (user_id, item_type, item_id, payment_method)\n- INFO: purchase success (user_id, item_type, item_id, cost)\n- WARN: insufficient balance (user_id, required, actual)\n- ERROR: grant use case failure (с full context)",
"activeForm": "Implementing purchase service",
"status": "pending",
"blocks": [
"5"
],
"blockedBy": [
"2",
"3"
]
}

{
"id": "5",
"subject": "Backend: api.py + dependencies.py — эндпоинты каталога и покупки",
"description": "Реализовать API endpoints в `app/cabinet/shop/api.py`:\n\n**GET /v1/cabinet/shop/catalog**\n- Auth: `Security(get_current_user)`\n- Вызывает `CabinetShopService.get_catalog(user.uuid, user.grade)`\n- Response: `CabinetShopCatalog`\n\n**POST /v1/cabinet/shop/purchase**\n- Auth: `Security(get_current_user)`\n- Rate limit: `RateLimiter(times=1, seconds=3)` (защита от двойных кликов)\n- Body: `PurchaseRequest`\n- Вызывает `CabinetShopService.purchase(...)`\n- Response: `PurchaseResponse`\n- Error handling: ловим domain exceptions → HTTPException:\n - `ShopItemNotFound` → 404\n - `InsufficientBalance` → 402\n - `ItemAlreadyOwned` → 409\n - `ShopPaymentNotAvailable` → 501\n\n**dependencies.py:**\n`python\nasync def get_cabinet_shop_service(\n    session: AsyncSession = Depends(get_session),\n) -> CabinetShopService:\n    return CabinetShopService(session)\n`\n\nFiles:\n- diaverseapi/app/cabinet/shop/api.py\n- diaverseapi/app/cabinet/shop/dependencies.py\n\nLOGGING:\n- DEBUG: request received (endpoint, user_id)\n- DEBUG: response sent (status, duration)",
"activeForm": "Writing API endpoints",
"status": "pending",
"blocks": [
"6",
"7"
],
"blockedBy": [
"3",
"4"
]
}
{
"id": "6",
"subject": "Backend: тесты для cabinet/shop",
"description": "Написать тесты в `diaverseapi/tests/test_cabinet_shop.py`:\n\n**Каталог:**\n1. `test_catalog_returns_all_sections` — GET /catalog возвращает секции (grades, passes, pets, pet_skins, pilot_skins, boosts, crates)\n2. `test_catalog_excludes_event_pets` — питомцы с subkind не попадают в каталог\n3. `test_catalog_marks_owned_grades` — грейды ниже текущего помечены owned=true\n4. `test_catalog_requires_auth` — 401 без токена\n\n**Покупка (XDV flow):**\n5. `test_purchase_pet_xdv_success` — покупка пета за XDV: баланс уменьшается, UserCharacter создаётся\n6. `test_purchase_insufficient_balance` — 402 при недостаточном балансе\n7. `test_purchase_already_owned` — 409 при повторной покупке (если применимо)\n8. `test_purchase_invalid_item` — 404 при несуществующем item_id\n9. `test_purchase_yukassa_not_implemented` — 501 при payment_method=yukassa\n10. `test_purchase_rate_limited` — повторный запрос в пределах 3 секунд блокируется\n\nИспользовать pytest + httpx AsyncClient, паттерн из tests/test_cabinet_advent.py.\n\nFiles: diaverseapi/tests/test_cabinet_shop.py\n\nLOGGING: тесты проверяют что логи пишутся через caplog fixture",
"activeForm": "Writing backend tests",
"status": "pending",
"blocks": [],
"blockedBy": [
"5"
]
}
{
"id": "7",
"subject": "Frontend: упростить api.ts — переключить на /v1/cabinet/shop/catalog",
"description": "Заменить 900 строк нормализации в `frontend/modules/shop/api.ts` на один вызов backend:\n\n**Было:**\n`ts\nfetchShopCatalog() → Promise.all([5 endpoints]) → 900 строк normalize*()\n`\n\n**Стало:**\n`ts\nexport async function fetchShopCatalog(): Promise<ShopCatalog> {\n  return apiClient.get<ShopCatalog>(\"/v1/cabinet/shop/catalog\");\n}\n`\n\nУдалить:\n- Все normalize* функции (normalizeGrades, normalizePasses, normalizePets, normalizeCrates)\n- Все extract* функции\n- Все resolve\* функции\n- Все helper functions (unwrapPayload, asRecord, asArray, etc.)\n- SHOP_ENDPOINTS массив\n- SHOP_PETS_PROXY_PATH\n- SettledEndpointResult, NumericCarrier interfaces\n\nОставить:\n- `fetchShopCatalog()` (переписать на один вызов)\n- `logShopClientError()` (утилита для компонентов)\n- `getShopErrorMessage()` (утилита для компонентов)\n\nFiles: frontend/modules/shop/api.ts\n\nLOGGING: DEBUG при вызове fetchShopCatalog (endpoint, duration)",
"activeForm": "Simplifying shop api.ts",
"status": "pending",
"blocks": [
"10"
],
"blockedBy": [
"5"
]
}
{
"id": "8",
"subject": "Frontend: обновить types.ts под ответ бэкенда",
"description": "Обновить `frontend/modules/shop/types.ts` чтобы типы совпадали со схемой бэкенда:\n\n**Обновить:**\n- `ShopCatalog` — добавить секции pet_skins, pilot_skins, boosts (сейчас только grades, passes, pets, crates)\n- `ShopTab` / `ShopSectionId` — расширить enum: добавить \"pet_skins\" | \"pilot_skins\" | \"boosts\"\n- Добавить типы: `PetSkinProduct`, `PilotSkinProduct`, `BoostProduct`\n\n**Удалить backend payload типы** (больше не нужны — нормализация на бэке):\n- `MarketProductPayload`\n- `CharacterStorePayload`\n- `LootBoxPayload`\n- `UserSubscriptionPayload`\n\n**Оставить/обновить:**\n- `GradeProduct`, `StepPassProduct`, `PetProduct`, `CrateProduct` — привести в соответствие с бэкенд-схемой\n- `PurchaseIntent` — обновить: добавить payment_method, убрать paymentMethod optional\n- `ShopUserBalance` — возможно расширить (xdv + dia)\n\nFiles: frontend/modules/shop/types.ts\n\nLOGGING: N/A",
"activeForm": "Updating shop types",
"status": "pending",
"blocks": [
"9"
],
"blockedBy": [
"2"
]
}
{
"id": "9",
"subject": "Frontend: добавить секции PetSkins, PilotSkins, Boosts",
"description": "Создать новые UI-секции для расширенного каталога:\n\n**Новые компоненты:**\n1. `components/pet-skins/PetSkinCard.tsx` — карточка скина пета (image, rarity, title, price)\n2. `components/pet-skins/PetSkinSection.tsx` — секция скинов петов (грид карточек)\n3. `components/pilot-skins/PilotSkinCard.tsx` — карточка скина пилота (image, rarity, gender, role, price)\n4. `components/pilot-skins/PilotSkinSection.tsx` — секция скинов пилотов\n5. `components/boosts/BoostCard.tsx` — карточка буста (icon, title, effect description, price)\n6. `components/boosts/BoostSection.tsx` — секция бустов\n\n**Обновить:**\n- `constants.ts` — добавить табы в SHOP_TABS и SECTION_ORDER\n- `ShopPage.tsx` — добавить рендеринг новых секций в sectionIds map\n- `ShopMenu.tsx` — новые табы автоматически подхватятся из SHOP_TABS\n\n**Следовать паттернам** существующих секций (GradeSection, PetSection):\n- SectionHeader + грид карточек\n- PriceTag для цены\n- PurchaseButton (пока disabled)\n- Responsive grid (1-2-3 колонки)\n\nFiles: \n- frontend/modules/shop/components/pet-skins/PetSkinCard.tsx\n- frontend/modules/shop/components/pet-skins/PetSkinSection.tsx\n- frontend/modules/shop/components/pilot-skins/PilotSkinCard.tsx\n- frontend/modules/shop/components/pilot-skins/PilotSkinSection.tsx\n- frontend/modules/shop/components/boosts/BoostCard.tsx\n- frontend/modules/shop/components/boosts/BoostSection.tsx\n- frontend/modules/shop/constants.ts\n- frontend/modules/shop/components/ShopPage.tsx\n\nLOGGING: DEBUG при рендере каждой секции (item count)",
"activeForm": "Creating new shop sections",
"status": "pending",
"blocks": [
"10"
],
"blockedBy": [
"8"
]
}{
"id": "10",
"subject": "Frontend: реализовать purchase flow (XDV)",
"description": "Оживить PurchaseButton и добавить purchase flow для оплаты XDV:\n\n**Новый хук `hooks/usePurchase.ts`:**\n`ts\nusePurchase() → {\n  purchase: (intent: PurchaseIntent) => void,\n  isPending: boolean,\n  error: string | null,\n  lastResult: PurchaseResponse | null,\n}\n`\n- useMutation с POST /v1/cabinet/shop/purchase\n- Инвалидирует [\"shop-catalog\"] query при успехе\n- Обрабатывает ошибки: 402 (недостаточно средств), 409 (уже куплено), 501 (метод недоступен)\n\n**Confirmation модал:**\n- Новый компонент `components/shared/PurchaseConfirmModal.tsx`\n- Показывает: товар, цену, текущий баланс, баланс после покупки\n- Кнопки: \"Подтвердить\" / \"Отмена\"\n- Для yukassa/crypto — показывать \"Скоро\" (disabled)\n\n**Обновить PurchaseButton:**\n- Убрать hardcoded `disabled=true`\n- Для XDV-товаров: enabled, onClick → открыть PurchaseConfirmModal\n- Для USD-товаров (grades, passes): показывать \"Оплата скоро\" (disabled)\n- Для товаров без цены: скрыть кнопку\n\n**Обновить карточки:**\n- GradeCard, PetCard, StepPassCard, CrateCard, + новые секции\n- Передавать onPurchase callback вместо disabled PurchaseButton\n\n**Success/Error toast:**\n- При успехе: показать toast \"Товар получен!\" + анимация\n- При ошибке: показать сообщение из бэкенда\n\nFiles:\n- frontend/modules/shop/hooks/usePurchase.ts (новый)\n- frontend/modules/shop/components/shared/PurchaseConfirmModal.tsx (новый)\n- frontend/modules/shop/components/shared/PurchaseButton.tsx (обновить)\n- frontend/modules/shop/components/grades/GradeCard.tsx (обновить)\n- frontend/modules/shop/components/pets/PetCard.tsx (обновить)\n- frontend/modules/shop/components/passes/StepPassCard.tsx (обновить)\n- frontend/modules/shop/components/crates/CrateCard.tsx (обновить)\n- frontend/modules/shop/api.ts (добавить purchaseItem function)\n\nLOGGING:\n- INFO: purchase initiated (item_type, item_id, payment_method)\n- INFO: purchase success / failure\n- DEBUG: modal open/close events",
"activeForm": "Implementing purchase flow",
"status": "pending",
"blocks": [
"11",
"12"
],
"blockedBy": [
"7",
"9"
]
}{
"id": "11",
"subject": "Frontend: тесты для shop модуля",
"description": "Написать тесты для обновлённого shop модуля:\n\n**Unit тесты (Vitest):**\n1. `api.test.ts` — fetchShopCatalog вызывает правильный endpoint, обрабатывает ошибки\n2. `usePurchase.test.ts` — хук: success flow, error handling, query invalidation\n3. `useShopTab.test.ts` — переключение табов\n\n**Component тесты (Vitest + Testing Library):**\n4. `ShopPage.test.tsx` — рендерит все секции, loading state, error state, empty state\n5. `PurchaseButton.test.tsx` — enabled для XDV, disabled для USD, disabled для owned\n6. `PurchaseConfirmModal.test.tsx` — показывает цену и баланс, confirm/cancel callbacks\n7. `PetSkinSection.test.tsx` — рендерит карточки скинов\n8. `BoostSection.test.tsx` — рендерит карточки бустов\n\nИспользовать MSW (Mock Service Worker) для мока API.\nСледовать паттерну тестов проекта (если есть).\n\nFiles: frontend/modules/shop/**tests**/\*.test.ts(x)\n\nLOGGING: N/A",
"activeForm": "Writing frontend tests",
"status": "pending",
"blocks": [],
"blockedBy": [
"10"
]
}{
"id": "12",
"subject": "Docs: обновить документацию и AGENTS.md",
"description": "Обновить проектную документацию:\n\n1. **AGENTS.md** — добавить cabinet/shop в project structure\n2. **docs/product/master-plan.md** — обновить секцию Shop (если есть)\n3. **docs/research/shop/shop-research.md** — пометить как реализованное (Вариант C → cabinet/shop facade)\n4. **.ai-factory/RESEARCH.md** — добавить сессию о реализации shop\n\nНе создавать новые markdown файлы — только обновить существующие.\n\nFiles:\n- AGENTS.md\n- docs/product/master-plan.md (если секция shop существует)\n- .ai-factory/RESEARCH.md\n\nLOGGING: N/A",
"activeForm": "Updating documentation",
"status": "pending",
"blocks": [],
"blockedBy": [
"10"
]
}
## 2026-04-03 Implementation Status

This file is now historical research context, not the active implementation
contract.

Current implementation direction:
- backend facade in `diaverseapi/app/cabinet/shop/`
- same-origin Next.js BFF in `frontend/app/api/cabinet/shop/*`
- web shop v1 scope: `pets`, `pet_skins`, `pilot_skins`
- payment method in v1: `XDV`

Current source-of-truth references:
- `../../features/cabinet/shop-web.md`
- `.ai-factory/plans/codex-cabinet-shop-xdv.md`
