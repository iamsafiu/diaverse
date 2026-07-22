# Tribute Shop API Runbook

Note for Club checkout: the shop club banner does not use this Tribute API
runbook. In the club banner flow, Tribute is configured only by
`NEXT_PUBLIC_CLUB_TRIBUTE_URL` and opens as an external link. It does not create
a backend payment session, callback, reconciliation event, onboarding link, or
private group link in this slice.

Коротко: без аккаунта Tribute можно безопасно деплоить код только с выключенными флагами. Реальный
  checkout не запустить, пока не получим merchant/shop account, API key и не подтвердим версию Shop API.

  Важный стоппер
  Публичная wiki Tribute сейчас показывает Shop API на https://tribute.tg/api/v1/shop/... и header Api-Key,
  а наш адаптер собран под TRIBUTE_BASE_URL=https://api.tribute.tg/api/v2 и header Authorization: Api-Key
  .... До live smoke надо через аккаунт/саппорт Tribute подтвердить, какой API доступен. Если дадут только
  v1, адаптер надо слегка поправить: header, response aliases uuid/paymentUrl/webappPaymentUrl, возможно
  GET /orders/{uuid}/status.

  Что сделать сначала

  1. В Telegram открыть @Tribute / Tribute web app.
  2. Создать creator/shop account, пройти payout/KYC, если запросит.
  3. В Dashboard/Settings найти API Keys, сгенерировать API key. Документация Tribute говорит, что ключ
  берётся в settings/API Keys и используется в API-запросах.
  4. В тех же настройках webhook указать:
     https://<api-host>/v1/cabinet/payments/tribute/callback?callback_token=<relay-token>

  5. У саппорта/в кабинете уточнить: это Shop API для внешнего создания заказов, не Digital Products и не
  subscriptions.

  Источники Tribute: Shop API (https://wiki.tribute.tg/for-shops/api), Shop API methods
  (https://wiki.tribute.tg/for-shops/api/methods), Webhooks
  (https://wiki.tribute.tg/for-shops/api/webhooks), FAQ/KYC (https://wiki.tribute.tg/faq).

  Env для backend
  В stage сначала ставим так:

  CABINET_GENERIC_PAYMENTS_ENABLED=true

  CABINET_PAYMENTS_TRIBUTE_VISIBLE=false
  CABINET_PAYMENTS_TRIBUTE_ENABLED=false

  TRIBUTE_BASE_URL=https://api.tribute.tg/api/v2
  TRIBUTE_API_TOKEN=<secret-from-tribute>
  TRIBUTE_CALLBACK_URL=https://<api-host>/v1/cabinet/payments/tribute/callback
  TRIBUTE_CALLBACK_RELAY_TOKEN=<high-entropy-secret>
  TRIBUTE_PAYMENT_CURRENCY=RUB
  TRIBUTE_TIMEOUT_SECONDS=15
  TRIBUTE_CHECKOUT_TTL_MINUTES=30

  Локальный source of truth: /C:/Users/Indigo/Desktop/diaverse/diaverseapi/.env.example:42 и /C:/Users/
  Indigo/Desktop/diaverse/diaverseapi/app/core/settings.py:274.

  Порядок запуска

  1. Деплоим backend с VISIBLE=false, ENABLED=false.
  2. Деплоим frontend из ветки feature/tribute-advent-payments.
  3. Проверяем старые платежки Advent: Pay1Time/Zion/Prodamus.
  4. В stage включаем только видимость:
     CABINET_PAYMENTS_TRIBUTE_VISIBLE=true

  5. Проверяем capabilities:
      - guest не видит доступный Tribute;
      - auth user без tg_user_id получает disabled reason telegram_identity_required;
      - auth user с tg_user_id видит Tribute.

  6. После подтверждения API-варианта Tribute включаем создание заказов:
     CABINET_PAYMENTS_TRIBUTE_ENABLED=true

  7. Smoke: Telegram-linked пользователь открывает платный Advent cell, выбирает Tribute, создаётся
  checkout через:
     POST /v1/cabinet/offers/advent/{code}/checkout/{day}
     body: {"provider_code":"tribute-hosted"}

  8. Проверяем redirect на Tribute, callback, status page и финализацию.

  Rollback

  CABINET_PAYMENTS_TRIBUTE_ENABLED=false
  CABINET_PAYMENTS_TRIBUTE_VISIBLE=false

  Это остановит новые Tribute-заказы и скроет метод. Уже созданные local sessions не удаляем, оставляем на
  reconciliation/manual review.

  Для stage MVP можно тестировать с relay token + server-side GET order reconciliation. Для production я бы
  добавил trbt-signature HMAC validation, потому что текущая публичная webhook-дока Tribute уже описывает
  подпись.




Процесс для пользователя в MVP будет выглядеть так:

  1. Пользователь заходит на сайт
  Открывает Advent calendar: /{lang}/offers/advent.

  Видит обычную сетку адвента: дни, награды, платные/бесплатные ячейки. Никакой отдельной “платежной
  витрины Tribute” на первом экране нет.

  2. Нажимает на платную ячейку
  Открывается текущая модалка ячейки:

  - заголовок типа Day 1;
  - цена, например 0.1 USD;
  - кнопка Pay.

  Если Tribute включен и пользователь подходит под условия, после нажатия Pay появится выбор платежки.

  3. Выбор платежки
  В модалке появляется блок “Choose payment method” с кнопками:

  - SBP / RUB
  - Crypto
  - РБ/RUB
  - Tribute или backend label, например Tribute Pay

  Пользователь нажимает Tribute.

  Важно: Tribute сейчас доступен только authenticated пользователю с привязанным Telegram ID. Guest не
  увидит Tribute как доступный метод. Authenticated user без tg_user_id тоже не сможет выбрать Tribute.

  4. Переход на payment/status page
  Frontend открывает отдельный payment route:

  /{lang}/offers/advent/payment?...&provider=tribute-hosted

  Визуально это компактная payment-card страница:

  - loader / preloader;
  - заголовок вроде Preparing checkout;
  - ниже строка:
      - Payment method
      - Tribute / Tribute Pay

  - кнопка Back to calendar;
  - если что-то пошло не так, кнопка Retry.

  На этом этапе backend создает локальную payment session и Tribute order.

  5. Открывается hosted checkout Tribute
  Наш сайт не собирает карту, не показывает свою форму оплаты и не хранит платежные данные.

  После создания заказа открывается hosted Tribute checkout в новой вкладке/окне. Точный внешний вид уже
  будет экраном Tribute: сумма, валюта, описание заказа, кнопка оплаты, возможно Telegram/WebApp-обвязка.

  6. Пользователь платит в Tribute
  Дальше пользователь действует на стороне Tribute:

  - подтверждает оплату;
  - либо отменяет;
  - либо платеж зависает/не проходит.

  7. Callback и статус
  Tribute отправляет callback на backend:

  /v1/cabinet/payments/tribute/callback?callback_token=...

  Для пользователя это невидимо. Backend не доверяет callback вслепую: он берет order id и делает server-
  side reconcile через Tribute API, сверяет сумму, валюту и локальную ссылку заказа.

  8. Возврат / ожидание / итог
  Payment page показывает одно из состояний:

  - Preparing checkout - создаем заказ;
  - Awaiting payment - ждем оплату;
  - Processing - платеж обрабатывается;
  - Payment complete - оплачено, Advent-награда финализирована;
  - Manual review - refund/chargeback/mismatch/неоднозначный статус;
  - Payment error - ошибка создания или оплаты.

  Если пользователь закрыл Tribute-окно и вернулся на сайт, status page продолжит проверять локальный
  checkout reference.

  Как это выглядит в одну линию

  Advent grid
    -> click paid cell
    -> modal with price
    -> Pay
    -> payment method buttons
    -> Tribute
    -> payment/status page with loader + "Payment method: Tribute"
    -> hosted Tribute checkout opens
    -> user pays
    -> backend callback + reconciliation
    -> status page: success / awaiting / review / error

  Что я бы улучшил визуально перед stage smoke
  Сейчас disabled Tribute не будет отдельной красивой disabled-кнопкой с причиной. Он просто фильтруется
  как невыбираемый метод. Для тестового запуска нормально, но для понятности лучше добавить UI-сообщение:

  - “Tribute доступен после входа через Telegram”
  - “Привяжите Telegram, чтобы оплатить через Tribute”

  Это особенно полезно, если Tribute станет единственной тестируемой платежкой в Advent.

## Related Runbooks

- [Referral Structure Rollout And Rollback](../runbooks/referral-structure-rollout.md) — referral DCR projection включается последней и только после callback/refund reconciliation.
- [DCR Web Commerce Rollout](../tasks/dcr/web-commerce-rollout.md) — разграничение real-money top-up и внутреннего DCR spend.
