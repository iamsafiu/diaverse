# Потерянный календарь (Web Cabinet)

## Что изменилось

Календарь больше не использует время в настройках старта и окончания. На уровне админки, frontend API и backend это теперь `date-only` логика:

- `start_date` — день, с которого календарь открывается для каждого пользователя в `00:00` его локального дня.
- `end_date` — последний день доступности календаря. Он действует включительно до конца локального дня пользователя.
- Время убрано из редактора, потому что оно давало двусмысленное поведение между часовыми поясами и путало публикацию.

## Что это значит для админки

- В редакторе используются обычные поля даты, без `datetime-local`.
- Черновик можно хранить без дат.
- Публикация требует `start_date`.
- Диапазон валиден только если `start_date <= end_date`.

Практическое правило:

- если нужен запуск “с 1 декабря”, ставим `start_date = 2026-12-01`;
- если нужен календарь “включая 31 декабря”, ставим `end_date = 2026-12-31`.

Админу больше не нужно думать про UTC, смещения и “в чьей таймзоне сохранится 00:00”.

## Как работает runtime

Backend читает `X-TimeZone` из frontend-клиента и валидирует IANA-таймзону пользователя. Если таймзона отсутствует или невалидна, используется `UTC`.

Дальше вся календарная логика считает именно локальную дату пользователя:

- `_get_local_today()` получает `today_local`
- `_check_date_range()` сравнивает `today_local` с `start_date` и `end_date`
- `compute_today_calendar_day()` считает номер календарного дня относительно `start_date`
- `has_claimable()` и `claim_day()` используют ту же самую локальную дату, без отдельной UTC-ветки

Формула для первого прохождения:

```text
today_calendar_day = (today_local - start_date).days + 1
clamp to 0..days_count
```

## Run 1 и Run 2+

### Первый проход

На первом проходе день можно забрать только если одновременно выполняются условия:

```text
day D claimable
  iff D == last_claimed_day + 1
  AND D <= today_calendar_day(user_tz)
  AND (cell.free OR payment_unlocked[run, D])
```

Если `start_date` не задан, первый проход считается некорректным, поэтому публикация без него запрещена.

### Второй и последующие проходы

Начиная со второго прохода дата-гейт отключён. Остаётся только последовательность, шаги и paid-логика:

```text
day D claimable
  iff D == last_claimed_day + 1
  AND (cell.free OR payment_unlocked[run, D])
```

## Как работает `DATE_LOCKED`

Если пользователь пытается открыть день, который ещё не наступил по его локальной дате, backend возвращает `DATE_LOCKED`.

Для этой ошибки backend отдаёт:

- `day_number`
- `today_calendar_day`
- `next_available_date` в формате `YYYY-MM-DD`

Пример:

```json
{
  "message": "Day is locked by calendar date",
  "reason_code": "DATE_LOCKED",
  "day_number": 9,
  "today_calendar_day": 8,
  "next_available_date": "2026-12-09"
}
```

`next_available_date` считается как:

```text
start_date + (day_number - 1) days
```

Frontend показывает эту дату как дату открытия ячейки и больше не парсит `YYYY-MM-DD` через UTC-сдвигающий `new Date("...")`.

## Примеры по часовым поясам

Если в админке выставлен `start_date = 2026-12-01`, то:

- пользователь из Москвы увидит открытие `1 декабря 2026` в `00:00` по Москве
- пользователь из Екатеринбурга увидит открытие `1 декабря 2026` в `00:00` по Екатеринбургу
- пользователь из западной таймзоны тоже увидит открытие в `00:00` своего локального дня

Если выставлен `end_date = 2026-12-31`, календарь останется доступным весь локальный день `31 декабря 2026` для каждого пользователя и закроется уже после окончания этого дня в его TZ.

## Контракт данных

Во frontend и backend `start_date`, `end_date` и `next_available_date` должны передаваться как plain date:

- `YYYY-MM-DD`
- без времени
- без `Z`
- без локального ISO-конверта

## Логи для отладки

Новые runtime-логи, по которым дебажим календарь:

- `DEBUG [advent.tz]` — какая таймзона разрешилась и какая локальная дата получилась
- `DEBUG [advent.window]` — сравнение `start/end/today`
- `DEBUG [advent.today]` — расчёт `today_calendar_day`
- `INFO [advent.claim] reject reason=DATE_LOCKED` — ранний доступ к будущему дню
- `INFO [advent.claim] reject reason=NOT_STARTED` — календарь ещё не начался
- `INFO [advent.claim] reject reason=EXPIRED` — календарь уже закончился

Логи админки:

- `DEBUG [AdminService.create_advent_calendar] normalized_schedule`
- `DEBUG [AdminService.update_advent_calendar] normalized_schedule`
- `DEBUG [AdminService._validate_publish_ready]`
- `INFO [AdminService.create_advent_calendar] created ... start=... end=...`
- `INFO [AdminService.update_advent_calendar] updated ... start=... end=...`
- `INFO [AdminService.publish_advent_calendar] ... start=... end=...`
- `WARN [AdminService._validate_date_window] invalid_range ...`
- `WARN [AdminService._validate_publish_ready] missing_start_date ...`

## Smoke Checklist

- Создать черновик без дат: черновик сохраняется, публикация не должна проходить.
- Поставить только `start_date`: календарь должен публиковаться.
- Поставить `start_date > end_date`: backend должен вернуть ошибку диапазона.
- Проверить пользователя в другой таймзоне: день 1 должен открываться в `00:00` локального дня пользователя, а не в таймзоне редактора.
- Проверить `end_date`: календарь доступен весь последний локальный день включительно.
- Проверить `DATE_LOCKED`: frontend должен показать правильную дату открытия ячейки без сдвига на сутки.

## Staff Analytics

Staff analytics has a dedicated `Адвент` tab under `/staff/analytics`.

Backend endpoint:

- `GET /v1/analytics/advent?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD&line_id=<uuid>`

Metric rules:

- `date_from` / `date_to` define the starter cohort window: actors that entered day 1 in this period.
- If `line_id` is omitted, backend selects the active published calendar first, then the latest available calendar.
- `started_participants` counts unique authenticated users plus guest sessions that claimed or created a pending/imported entitlement for day 1.
- Imported guest entitlements with `imported_user_id` normalize to the authenticated user key to avoid double counting after login.
- `completed_participants` uses `CabAdventProgress.completed_runs > 0`; when progress is missing, a max-day claim/imported entitlement can also count as completion.
- `completion_rate` is `completed_participants / started_participants * 100`.
- `average_reached_day` is the average max claimed day among started actors.
- `active_now` means the actor is in an unfinished current run.
- `paid_cells` are behavioral only: reached paid gate, checkout started, unlocked, claimed.
- `repeat_runs` is based on authenticated `CabAdventProgress.run_number` and `completed_runs`.

Empty states are explicit:

- `no_calendars` — no Advent calendars exist.
- `calendar_not_found` — requested `line_id` does not exist.
- `no_participants` — selected calendar has no day-1 starters in the selected period.

Financial analytics are intentionally excluded from this tab. Revenue by day/currency/provider/cell and ARPU/ARPPU belong to the separate revenue module.

## Guest Mode (Web Cabinet)

Guest mode now applies to the public cabinet Advent route as well.

- `/{lang}/offers/advent` is readable without authentication.
- Free guest claim creates a pending reward and shows a sign-in CTA instead of granting directly.
- Guest paid flow starts a real hosted checkout in `diaverseapi`, stores a guest external order plus pending paid unlock, and only imports the reward after Telegram login.
- Post-login reconciliation clears cached guest Advent data before redirecting back, so the calendar rehydrates against the authenticated account state.

## Платные ячейки Advent

Оплата платных ячеек теперь работает через cabinet-only интеграцию `pay1time` в sibling backend `diaverseapi`. Во frontend нет прямой работы с токеном провайдера, подписью коллбека или provider API.

Граница ответственности:

- `diaweb` отвечает за запуск checkout, редирект на hosted payment form и восстановление UI-состояния после возврата.
- `diaverseapi` отвечает за создание checkout, хранение provider identifiers, обработку callback, reconciliation и финализацию unlock/claim.
- существующий mobile payment flow не участвует в этом сценарии и не меняется.

Backend routes:

- `POST /v1/cabinet/offers/advent/{code}/checkout/{day_number}` — auth checkout init
- `GET /v1/cabinet/offers/advent/checkout/{public_checkout_reference}` — auth checkout status/sync
- `POST /v1/cabinet/offers/advent/{code}/guest-checkout/{day_number}` — guest checkout init
- `GET /v1/cabinet/offers/advent/guest-checkout/{public_checkout_reference}` — guest checkout status/sync
- `POST /v1/cabinet/payments/pay1time/callback` — cabinet-scoped provider callback

### Multi-provider update (2026-04-16)

Paid Advent cells now sit on a provider-neutral cabinet payments layer.

Current provider rails:
- `pay1time-sbp` — hosted checkout, provider-facing quote in `RUB`
- `zion-crypto` — hosted Zion invoice checkout; Advent selects only the provider, while the final coin/network is chosen on the Zion hosted page

Shared contract rules:
- frontend never owns provider credentials, webhook verification, or direct provider API calls
- frontend chooses from backend-provided capabilities and may pass optional `provider_code` during checkout init
- if no `provider_code` is sent, backend keeps backward-compatible default-provider behavior
- if capabilities cannot be loaded in the UI, Advent falls back to backend-default checkout resolution instead of blocking the current live pay1time flow
- if the user explicitly selected `zion-crypto`, a Zion init error must remain a Zion error and must not silently reroute that checkout into `pay1time`
- `payment_quote` is immutable provider snapshot data and must be rendered as returned; frontend must not recalculate provider charge
- `review_required` is a first-class terminal state and must not be rendered as a normal retry/payment-failed state

Capability contract:
- `GET /v1/cabinet/offers/advent/payment-capabilities` returns actor-aware `default_provider_code` plus `methods[]`
- each method exposes `provider_code`, `method_kind`, public label, availability status, and guest/auth support
- provider metadata may expose `checkout_kind = hosted`; Advent must stay provider-level only and must not invent a local Zion coin chooser from this contract
- Advent modal renders method choice only from this payload; future modules (for example Shop) should reuse the same seam instead of inventing provider-specific UI contracts

Operational alert expectations:
- stuck `created` / `awaiting_payment` / `processing` sessions should continue surfacing through cabinet logging detector rules
- `review_required` sessions should be visible in cabinet logging as operational follow-up items rather than silent success
- return-page recovery should log provider code, checkout reference, status transitions, and fallback decisions
- hosted Zion should preserve preliminary invoice identity alongside the final provider payment identity so callback recovery and manual investigation stay possible

Zion operational prerequisites:
- keep both `CABINET_PAYMENTS_ZION_VISIBLE=false` and `CABINET_PAYMENTS_ZION_ENABLED=false` until the backend deploy and pay1time parity smoke are complete
- fill `ZION_BASE_URL`, `ZION_CHECKOUT_BASE_URL`, `ZION_API_TOKEN`, `ZION_SHOP_ID`, `ZION_CALLBACK_SECRET`, and `ZION_PAYMENT_CURRENCY` before the first stage smoke
- hosted public checkout URL is composed as `<ZION_CHECKOUT_BASE_URL>/invoice/<invoice.id>/`; keep the host explicit in config rather than hardcoding it in rollout scripts
- visible coins/networks are controlled by the merchant's enabled Zion shop currencies; `diaweb` does not render a local provider-option selector for Zion
- webhook verification depends on the incoming `X-Signature` header and backend `ZION_CALLBACK_SECRET`; confirm the operational source of that secret with Zion before production activation

Production activation order:
1. Deploy backend/frontend with Zion credentials present but Zion still hidden/disabled.
2. Smoke existing pay1time parity on the live calendar.
3. Smoke `GET /payment-capabilities` for both guest and authenticated actors on stage.
4. Enable Zion in stage, then verify hosted invoice creation, redirect to Zion checkout, callback linkage, ambiguous return states, and `review_required` logging visibility.
5. Deploy to production with Zion still disabled if needed for safety.
6. Flip Zion visibility/enabled flags only after post-deploy pay1time smoke passes.
7. Re-run production smoke on both rails and confirm cabinet logging shows no stuck or review-required anomalies.

### Return flow contract

Каждый checkout получает opaque `public_checkout_reference`. Во внешний URL не светятся внутренние `UUID` заказа или payment session.

Backend собирает три возвратных URL на Advent payment page:

- `return_url` → `/{lang}/offers/advent/payment?checkout=<public_checkout_reference>&state=return`
- `fail_url` → `/{lang}/offers/advent/payment?checkout=<public_checkout_reference>&state=fail`
- `processing_url` → `/{lang}/offers/advent/payment?checkout=<public_checkout_reference>&state=processing`

`state` в query-параметре — это только подсказка о маршруте возврата из hosted checkout, но не источник истины о результате оплаты.
Истина всегда читается из backend status endpoint (`GET /checkout/{public_checkout_reference}` или `GET /guest-checkout/{public_checkout_reference}`).
Даже при `state=fail` frontend должен продолжать синхронизацию и держать `processing`, пока backend не подтвердит терминальный сбой (`failed`, `cancelled`, `expired`) или успех (`paid` и финальный `finalization_status` для auth checkout).

Frontend route `/{lang}/offers/advent/payment`:

- если `checkout` отсутствует, сам инициализирует checkout для текущего guest/auth сценария;
- если `checkout` уже есть, опрашивает backend status endpoint по `public_checkout_reference`;
- переживает hard refresh и повторное открытие вкладки без повторного создания локальной оплаты.

Operational log checkpoints для отладки return-flow:
- Frontend `DEBUG [advent] Checkout view state resolved.` с полями `publicCheckoutReference`, `paymentStatus`, `finalizationStatus`, `returnState`, `resolvedViewState`
- Frontend `DEBUG [advent] Advent payment view state transition.` для проверки переходов UI-состояний и recovery-действий
- Backend `DEBUG [advent.auth|advent.guest] status_read reconciliation eligibility ...`
- Backend `INFO [advent.auth|advent.guest] status_read reconciliation attempt/result ...`
- Backend `INFO [advent.auth] status_read finalization check ...`

### Auth flow

1. Пользователь пытается забрать платную ячейку и получает `PAYMENT_REQUIRED`.
2. Frontend вызывает `POST /v1/cabinet/offers/advent/{code}/checkout/{day_number}`.
3. Backend создает или переиспользует `CabAdventPaymentSession`, выбирает provider adapter по `provider_code` или backend default, сохраняет provider references и возвращает `redirect_url` + return-flow contract.
4. Пользователь уходит на hosted payment form.
5. После callback и/или status sync backend переводит локальную сессию в `paid`, `failed`, `cancelled`, `expired` или `imported`.
6. При успешной оплате backend идемпотентно завершает unlock/claim ровно один раз.

Провайдер-специфично:
- `pay1time-sbp` сохраняет прежний hosted checkout path с provider-facing суммой в `RUB`
- `zion-crypto` создает hosted preliminary `invoice`, сохраняет `provider_invoice_id` / `provider_invoice_guid`, а затем редиректит пользователя на Zion hosted checkout

### Guest flow

1. Гость открывает платную ячейку и запускает `POST /v1/cabinet/offers/advent/{code}/guest-checkout/{day_number}`.
2. Backend создает guest external order с выбранным `provider_code` и pending entitlement типа `advent_paid_unlock`.
3. После hosted checkout guest order получает один из терминальных статусов: `paid`, `failed`, `cancelled`, `expired`, `imported`.
4. После Telegram login existing guest transfer pipeline переносит уже оплаченную entitlement в реальный аккаунт.

### Callback, reconciliation и late success

- Callback подпись проверяется на backend провайдер-специфично:
  - `pay1time` — через `PAY1TIME_TOKEN`
  - `zion` — через `X-Signature` и `ZION_CALLBACK_SECRET`
- Потерянный callback не должен навсегда блокировать оплату: status-read path и login transfer запускают reconciliation через выбранный provider adapter.
- Для Zion reconciliation сначала может восстанавливаться hosted preliminary `invoice`, а уже потом финальный provider `payment`.
- При guest login transfer backend дополнительно пытается синхронизировать внешний order, если он завис в `created` или `awaiting_payment`.
- Late success policy зафиксирован так: если checkout был создан в допустимое окно дня, поздний `SUCCESS` после возврата со страницы оплаты все равно завершает unlock/claim автоматически.
- Финализация награды остается в Advent/guest cabinet services, а не в provider callback handler.

## Rollout Checklist for Paid Cells

- Заполнить `PAY1TIME_TOKEN`, `PAY1TIME_CALLBACK_URL`, `PAY1TIME_MERCHANT_NAME`, `PAY1TIME_MERCHANT_URL` и `CABINET_PUBLIC_BASE_URL` в backend environment.
- Для Zion заполнить `ZION_BASE_URL`, `ZION_CHECKOUT_BASE_URL`, `ZION_API_TOKEN`, `ZION_SHOP_ID`, `ZION_CALLBACK_SECRET` и `ZION_PAYMENT_CURRENCY`.
- Зарегистрировать callback URL `POST /v1/cabinet/payments/zion/callback` в merchant settings Zion до первого stage/prod smoke.
- Зарегистрировать production callback URL у провайдера.
- Передать в поддержку `pay1time` production IP-адреса backend для whitelist.
- Учитывать требование провайдера: запросы должны идти по HTTP/1.1.
- Проверить возврат на `/{lang}/offers/advent/payment` для `return`, `fail` и `processing` сценариев.
- Прогнать оба пути: guest paid cell -> login import и authenticated paid cell -> instant finalization.
- Для Zion проверить, что hosted checkout реально показывает currencies/networks, включенные в текущем merchant shop.

### Canonical paid price

- Paid Advent cell price is now canonical in `USD`.
- Staff constructor stores paid `price_amount`/`price_currency` as `USD` only.
- Public Advent calendar and payment page show the canonical source price in dollars.
- `pay1time` remains a RUB-only rail. The backend converts from canonical USD to a checkout-time RUB quote; the frontend does not calculate the charged amount.
- `zion-crypto` keeps the same canonical USD source price but creates the hosted invoice in the backend-configured denomination currency (`ZION_PAYMENT_CURRENCY`). The final wallet/network choice then happens on Zion's hosted page.

### FX quote and fee policy (`pay1time`)

- FX source: official Bank of Russia XML daily endpoint (`https://www.cbr.ru/scripts/XML_daily.asp`).
- The backend reads the latest registered `USD` row, parses decimal comma, and normalizes rate as `Value / Nominal`.
- Default fee policy for `pay1time`: `5.5%`, configured by `PAY1TIME_FEE_RATE`.
- Quote formula:

```text
usd_price = canonical cell price in USD
usd_rub_rate = latest official CBR USD/RUB rate
base_rub = usd_price * usd_rub_rate
gross_rub = base_rub / (1 - fee_rate)
provider_amount_minor = ceil(gross_rub * 100)
provider_amount = provider_amount_minor / 100
```

- Rounding policy is always upward to provider minor units so the fee gross-up does not undercharge.
- Backend stores the immutable checkout quote snapshot in `payment_quote` and returns it both on checkout init and status reads.
- If CBR is unavailable, backend may reuse the latest stored successful USD/RUB snapshot only within the configured stale window (`CABINET_FX_STALE_HOURS`). Otherwise checkout init fails with a retryable error before any provider invoice is created.

### Quote snapshot contract

- `payment_payload.price_amount` / `price_currency` remains the canonical cell price.
- `payment_quote` carries the provider-facing amount snapshot for the selected provider:
  - `source_amount`, `source_currency`
  - `provider_amount`, `provider_currency`, `provider_amount_minor`
  - provider-specific metadata in `provider_quote_meta`
  - `quote_created_at`, optional `quote_expires_at`
- Decimal fields are serialized as strings; `provider_amount_minor` stays integer.
- Payment return/status UI must render the stored `payment_quote` snapshot when available and must not recalculate the amount from route query params.

Provider notes:
- for `pay1time`, `payment_quote` includes FX metadata such as `fx_rate`, `fx_rate_provider`, `fx_rate_date`, `fx_rate_fetched_at`, `fee_rate`, `fee_formula`, and `base_amount`
- for `zion-crypto`, `payment_quote.provider_quote_meta` may include hosted-checkout metadata such as `checkout_kind = hosted` and the invoice denomination currency used to create the preliminary Zion invoice

### Safe rollout for live calendar

Use the same published Advent line. Do not create a replacement calendar for this rollout.

Order of operations:

1. Set backend env vars: `PAY1TIME_FEE_RATE`, `CABINET_FX_CBR_XML_DAILY_URL`, `CABINET_FX_TIMEOUT_SECONDS`, `CABINET_FX_STALE_HOURS`, plus existing `pay1time` credentials.
2. Deploy backend migration, FX snapshot service, checkout quote logic, retryable quote error mapping, USD admin validation, and the updater command.
3. Deploy frontend USD display support for staff editor, public Advent grid/modal, and payment page quote rendering.
4. Run dry-run on production:

```bash
python -m app.commands.update_advent_paid_prices_usd \
  --expected-code <published_calendar_code> \
  --prices-json '{"3":"9.99"}'
```

5. After confirming the report, run the real update with `--apply`.
6. Verify:
   - existing claimed day 1 is still collected;
   - day 3 shows the new USD price;
   - checkout init returns `payment_quote`;
   - `pay1time` receives RUB amount;
   - payment status page restores the same stored quote after return.
7. Keep legacy RUB runtime compatibility only for already-existing rows during rollout. Remove that fallback in a later cleanup release.

Production invariants:

- Do not change `line_id`, `code`, `start_date`, day order, or already-claimed progress rows.
- User progress and claimed rewards remain stable because Advent ownership is keyed by `line_id + run_number + day_number`, not by item UUID.
- If UI unpublish/edit/publish flow is used instead of the updater command, the downtime window must be short and monitored.

## Advent Background Storage

Uploaded Advent background images are now treated as persistent user uploads, not as repository-owned static assets.

- Public URL stays the same: `/static/advent/backgrounds/<filename>`.
- General `/static/...` serving stays unchanged for the rest of the product.
- Mobile clients and existing web static assets are not migrated or remapped by this change.
- Backend stores Advent backgrounds in a dedicated persistent directory mounted into the API container.
- The persistent host directory must stay outside `/home/diaverse`, because `/home/diaverse` is rewritten by deploy-time `rsync --delete`.

Recommended runtime paths:

- Host: `/home/storage/advent-backgrounds`
- Container: `/app/uploads/advent-backgrounds`

Relevant backend env/config:

- `ADVENT_BACKGROUNDS_DIR` - container-side upload directory for Advent backgrounds
- `ADVENT_BACKGROUNDS_HOST_DIR` - host-side bind mount path used by Docker Compose

Rollout outline:

1. Create the persistent host directory and verify permissions.
2. Add the Docker bind mount for the API service.
3. Deploy the backend with the dedicated Advent background mount.
4. Run `python scripts/migrate_advent_backgrounds.py --dry-run` in `diaverseapi`.
5. Run `python scripts/migrate_advent_backgrounds.py`.
6. Verify old and new `/static/advent/backgrounds/...` URLs still return `200`.

Useful backend logs:

- `INFO/WARN/ERROR [static.config]` - Advent background directory resolution and mount state
- `INFO/ERROR [AdminService.upload_advent_calendar_background]` - upload target path and write failures
- `WARN [static.serve]` - requested Advent background file is missing
- `INFO/WARN/ERROR [advent.backgrounds.migrate]` - migration progress and summary
