# Step Pass Shop Research

Короткий ответ: **да, step pass у вас уже был в старой shop-линии, но текущий магазин сознательно вырезал его из активной архитектуры**.  
И лучший senior-путь сейчас: **не запихивать Basic/Pro в текущий `XDV` storefront-модуль как обычные товары**, а добавить их как **второй source внутри того же shop facade**, но с **отдельным purchase flow**.

**Что я подтвердил**

- В старом shop-плане step pass был частью магазина: [feature-cabinet-shop.md](/C:/Users/Indigo/Desktop/diaverse/diaweb/.ai-factory/plans/feature-cabinet-shop.md).
- 3 апреля 2026 у вас даже был фикс на tier-detection для Basic/Pro: [2026-04-03-11.43.md](/C:/Users/Indigo/Desktop/diaverse/diaweb/.ai-factory/patches/2026-04-03-11.43.md).
- Но текущий live shop уже другой:
  - во фронте есть только `pets | pet_skins | pilot_skins`: [types.ts](/C:/Users/Indigo/Desktop/diaverse/diaweb/frontend/modules/shop/types.ts)
  - в backend facade нет `passes` ни в section enum, ни в source type: [models.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/cabinet/shop/models.py)
  - в актуальной shop-документации `fitness pass` явно вне scope: [cabinet-shop-web.md](../../features/cabinet/shop-web.md), [codex-cabinet-shop-xdv.md](/C:/Users/Indigo/Desktop/diaverse/diaweb/.ai-factory/plans/codex-cabinet-shop-xdv.md)

**Почему не надо добавлять его “как обычный XDV товар”**

- Текущий `cabinet/shop` заточен под `cab_shop_items.price_xdv` и `POST /purchase` с внутренним XDV-spend: [schemas.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/cabinet/shop/schemas.py), [service.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/cabinet/shop/service.py).
- А step pass уже живёт в другом домене:
  - каталог товаров идёт из `market_products` c `category=fitness_pass`: [market/api.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/market/api.py), [market/models.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/market/models.py)
  - entitlement/доступ сидит в `subscriptions` и `fitness_pass`: [subscriptions/models.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/subscriptions/models.py), [fitness_pass/usecases.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/fitness_pass/usecases.py)
  - выдача после оплаты уже завязана на payment reward strategy: [strategy.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/payment/rewards/strategy.py)
- Если засунуть passes в `cab_shop_items`, вы создадите **второй источник правды по цене и продуктам**, а это плохая архитектура.

**Что я рекомендую**
Сделать **единый storefront, но два purchase engine**:

```text
Browser
  -> /api/cabinet/shop/catalog
     -> backend cabinet shop facade
        -> XDV storefront from cab_shop_items
        -> Step Pass catalog from market_products(category=fitness_pass)

Writes:
  XDV goods      -> /api/cabinet/shop/purchase
  Step Pass      -> /api/cabinet/shop/passes/checkout   (или similar)
```

То есть:

- **читать вместе**
  - один `/shop`
  - один catalog response
- **покупать по-разному**
  - `pets/skins` через текущий XDV purchase
  - `step pass` через отдельный checkout flow

**Как именно я бы это сделал**

1. В backend facade добавить секцию `passes`, но **не через `cab_shop_items`**.
2. Источник для `passes`:
   - `GET market_products where category=fitness_pass`
   - нормализация в facade
3. Нормализовать Basic/Pro **по `sku` в первую очередь**, не по `name`:
   - `sub_fitness_pass_basic_1_month`
   - `sub_fitness_pass_pro_1_month`
     Это важно, потому что у вас уже был баг с неправильным tier detection: [2026-04-03-11.43.md](/C:/Users/Indigo/Desktop/diaverse/diaweb/.ai-factory/patches/2026-04-03-11.43.md)
4. UI не делать как 8 отдельных generic-card товаров.
   Делать **2 карточки**:
   - `Basic`
   - `Pro`
     внутри каждой selector срока: `1 / 3 / 6 / 12 months`
5. Активность/ownership вычислять из subscription features:
   - `basic_fitness_pass`
   - `pro_fitness_pass`
     Источник: [subscriptions/models.py](/C:/Users/Indigo/Desktop/diaverse/diaverseapi/app/subscriptions/models.py)
6. Покупку не пихать в текущий `POST /purchase` для XDV.
   Для pass нужен отдельный action:
   - `create checkout`
   - или пока `coming_soon`, если web provider ещё не выбран

**Моя жёсткая рекомендация**

- **Да**: добавить Step Pass в магазин как часть общего storefront.
- **Нет**: хранить его цену и ассортимент в `cab_shop_items`.
- **Да**: backend facade должен агрегировать `market fitness_pass` в текущий `/shop`.
- **Нет**: не возвращаться к frontend-only агрегации напрямую из браузера.
- **Да**: для passes нужен отдельный section renderer (`StepPassSection` / `StepPassCard`), а не текущий generic [ShopItemCard.tsx](/C:/Users/Indigo/Desktop/diaverse/diaweb/frontend/modules/shop/components/shared/ShopItemCard.tsx).

Если в одной фразе:  
**лучший lead/senior путь — это unified catalog, split purchase flows, market as source of truth for Step Pass.**

Если хочешь, следующим сообщением я разложу это уже в **конкретный implementation plan backend + frontend**, без кода, но по шагам и с правильным scope.
