# Clubbot10000 Diaverse Notes

РќР° diaverseapi СЃРµСЂРІРµСЂРµ РЅСѓР¶РЅРѕ СЃРґРµР»Р°С‚СЊ РЅРµ вЂњРЅР°СЃС‚СЂРѕР№РєСѓвЂќ, Р° РїРѕР»РЅРѕС†РµРЅРЅС‹Р№ backend deploy РЅРѕРІРѕРіРѕ commit 0decc7b7.

  Р“Р»Р°РІРЅРѕРµ: СЃРµР№С‡Р°СЃ club10000-bot СЃРјРѕС‚СЂРёС‚ РІ https://api.diaverse.app, Р° DNS СЌС‚РѕРіРѕ РґРѕРјРµРЅР° РІРµРґРµС‚ РЅР° 5.35.7.178.
  РЎРµСЂРІРµСЂ 5.42.116.157, РєРѕС‚РѕСЂС‹Р№ СЏ СЃРјРѕС‚СЂРµР», РѕР±СЃР»СѓР¶РёРІР°РµС‚ api.dev.diaverse.app. РџРѕ SSH РЅР° 5.35.7.178 РјРѕР№ РєР»СЋС‡
  РЅРµ РїСѓСЃРєР°РµС‚.

  Р§С‚Рѕ РЅСѓР¶РЅРѕ СЃРґРµР»Р°С‚СЊ РЅР° РїСЂР°РІРёР»СЊРЅРѕРј API-СЃРµСЂРІРµСЂРµ:

  1. Р”РµРїР»РѕР№ РєРѕРґР° diaverseapi
     РќСѓР¶РЅРѕ РґРѕСЃС‚Р°РІРёС‚СЊ commit:

  0decc7b7 feat(club): accept Club10000 payment events

  РћРЅ РґРѕР±Р°РІР»СЏРµС‚ endpoint:

  POST /v1/internal/club/payment-events

  Рё РјРёРіСЂР°С†РёРё РґР»СЏ:

  club_payment_provider_events
  club_payment_contracts provider indexes

  2. Р”РѕР±Р°РІРёС‚СЊ env РЅР° API-СЃРµСЂРІРµСЂРµ

  CLUB10000_PAYMENT_BRIDGE_SECRET=<С‚РѕС‚ Р¶Рµ secret, С‡С‚Рѕ DIAVERSE_CLUB10000_SECRET Сѓ club10000-bot>
  CLUB10000_PAYMENT_BRIDGE_KEY_ID=club10000-payment

  CLUBBOT_INTERNAL_SECRET РЅРµ С‚СЂРѕРіР°С‚СЊ, СЌС‚Рѕ РґСЂСѓРіРѕР№ РєРѕРЅС‚СѓСЂ.

  3. РџСЂРѕРіРЅР°С‚СЊ РјРёРіСЂР°С†РёРё

  Р”Р»СЏ СЃРµСЂРІРµСЂР° СЃ compose РєР°Рє РЅР° 5.42.116.157 РєРѕРјР°РЅРґС‹ С‚Р°РєРёРµ:

  cd /home/config
  docker compose run --rm migrate

  4. РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ API-СЃРµСЂРІРёСЃС‹

  cd /home/config
  docker compose up -d --force-recreate --no-deps api worker scheduler
  docker compose ps

  5. РџСЂРѕРІРµСЂРёС‚СЊ, С‡С‚Рѕ endpoint РїРѕСЏРІРёР»СЃСЏ

  curl -i -X POST https://api.diaverse.app/v1/internal/club/payment-events \
    -H "Content-Type: application/json" \
    --data '{}'

  РќРѕСЂРјР°Р»СЊРЅРѕ, РµСЃР»Рё Р±СѓРґРµС‚ 401, 403, 400 РёР»Рё 422. Р“Р»Р°РІРЅРѕРµ, С‡С‚РѕР±С‹ СѓР¶Рµ РЅРµ 404.

  6. РўРѕР»СЊРєРѕ РїРѕСЃР»Рµ СЌС‚РѕРіРѕ РЅР° СЃРµСЂРІРµСЂРµ club10000-bot

  cd /srv/club10000-bot
  # РІРµСЂРЅСѓС‚СЊ DIAVERSE_OUTBOX_ENABLED=true РІ .env
  docker compose -f docker-compose.production.yml up -d --force-recreate --no-deps bot
  docker compose -f docker-compose.production.yml exec bot python scripts/sync_diaverse_payments.py
  --enqueue

  Р’Р°Р¶РЅС‹Р№ РјРѕРјРµРЅС‚: РЅР° 5.42.116.157 repo /home/diaverse РѕС‡РµРЅСЊ РіСЂСЏР·РЅС‹Р№ Рё СЃРёР»СЊРЅРѕ behind origin, РїРѕСЌС‚РѕРјСѓ С‚Р°Рј
  РЅРµР»СЊР·СЏ РїСЂРѕСЃС‚Рѕ РґРµР»Р°С‚СЊ git pull. Р‘РµР·РѕРїР°СЃРЅРµРµ Р»РёР±Рѕ РґРµРїР»РѕРёС‚СЊ С‡РµСЂРµР· РЅРѕСЂРјР°Р»СЊРЅС‹Р№ clean release/CI, Р»РёР±Рѕ С‚РѕС‡РµС‡РЅРѕ
  РїРµСЂРµРЅРµСЃС‚Рё С„Р°Р№Р»С‹ РёР· commit 0decc7b7, СЃРґРµР»Р°С‚СЊ backup Р·Р°РјРµРЅСЏРµРјС‹С… С„Р°Р№Р»РѕРІ, РїРѕС‚РѕРј РјРёРіСЂР°С†РёРё Рё restart.
  Р”Р°, РІСЂСѓС‡РЅСѓСЋ РѕСЃС‚Р°Р»РѕСЃСЊ РЅРµРјРЅРѕРіРѕ, РЅРѕ СЌС‚Рѕ РєСЂРёС‚РёС‡РЅС‹Рµ РІРµС‰Рё.
 
   РќР° РїСЂР°РІРёР»СЊРЅРѕРј diaverseapi production-СЃРµСЂРІРµСЂРµ
   РЎРЅР°С‡Р°Р»Р° РІР°Р¶РЅРѕ: api.diaverse.app СЃРµР№С‡Р°СЃ РІРµРґРµС‚ РЅР° 5.35.7.178, Р° РЅРµ РЅР° 5.42.116.157. Рљ 5.35.7.178 РјРѕР№ SSH-
   РєР»СЋС‡ РЅРµ РїРѕРґРѕС€РµР». Р—РЅР°С‡РёС‚ РЅР°РґРѕ Р»РёР±Рѕ РґР°С‚СЊ РґРѕСЃС‚СѓРї Рє СЌС‚РѕРјСѓ СЃРµСЂРІРµСЂСѓ, Р»РёР±Рѕ РїРѕРґС‚РІРµСЂРґРёС‚СЊ, С‡С‚Рѕ club10000-bot РґРѕР»Р¶РµРЅ
   СЃРјРѕС‚СЂРµС‚СЊ РЅР° api.dev.diaverse.app.
 
   РќР° production diaverseapi РЅСѓР¶РЅРѕ РґРѕР±Р°РІРёС‚СЊ env:
 
   CLUB10000_PAYMENT_BRIDGE_SECRET=<С‚РѕС‚ Р¶Рµ secret, С‡С‚Рѕ DIAVERSE_CLUB10000_SECRET Сѓ club10000-bot>
   CLUB10000_PAYMENT_BRIDGE_KEY_ID=club10000-payment
 
   РџРѕС‚РѕРј Р·Р°РґРµРїР»РѕРёС‚СЊ commit 0decc7b7, РїСЂРѕРіРЅР°С‚СЊ РјРёРіСЂР°С†РёРё Рё РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ API.
 
   РџСЂРѕРІРµСЂРєР° РїРѕСЃР»Рµ РґРµРїР»РѕСЏ:
 
   curl -i -X POST https://api.diaverse.app/v1/internal/club/payment-events \
     -H "Content-Type: application/json" \
     --data '{}'
 
   Р“Р»Р°РІРЅРѕРµ: РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ СѓР¶Рµ РЅРµ 404. 401/403/400/422 РЅРѕСЂРјР°Р»СЊРЅРѕ, Р·РЅР°С‡РёС‚ РјР°СЂС€СЂСѓС‚ СЃСѓС‰РµСЃС‚РІСѓРµС‚.
 
   РќР° club10000-bot СЃРµСЂРІРµСЂРµ
   РЎРµР№С‡Р°СЃ СЏ СЃРїРµС†РёР°Р»СЊРЅРѕ РѕСЃС‚Р°РІРёР»:
 
   DIAVERSE_OUTBOX_ENABLED=false
 
   Р­С‚Рѕ Р·Р°С‰РёС‚Р°, РїРѕРєР° API endpoint РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚. РџРѕСЃР»Рµ РґРµРїР»РѕСЏ diaverseapi РЅР°РґРѕ РІРµСЂРЅСѓС‚СЊ:
 
   DIAVERSE_OUTBOX_ENABLED=true
 
   Рё РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ:
 
   cd /srv/club10000-bot
   docker compose -f docker-compose.production.yml up -d --force-recreate --no-deps bot
 
   РџРѕС‚РѕРј РІС‹РїРѕР»РЅРёС‚СЊ bootstrap:
 
   docker compose -f docker-compose.production.yml exec bot python scripts/sync_diaverse_payments.py
   --enqueue
 
   Р’ Prodamus
   Р•СЃР»Рё РµС‰Рµ РЅРµ РІС‹СЃС‚Р°РІР»РµРЅРѕ РІСЂСѓС‡РЅСѓСЋ РІ РєР°Р±РёРЅРµС‚Рµ, callback РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ:
 
   https://iamgradov.ru/payments/prodamus/callback
 
   Р§С‚Рѕ СѓР¶Рµ РЅРµ РЅР°РґРѕ С‚СЂРѕРіР°С‚СЊ
   Caddy route РЅР° iamgradov.ru, bot container, Postgres restore, webhook /webhook/bot, Prodamus route smoke
   check СѓР¶Рµ СЃРґРµР»Р°РЅС‹. Bot Р¶РёРІРѕР№, РЅРѕ РѕС‚РїСЂР°РІРєР° РІ Diaverse РЅР°РјРµСЂРµРЅРЅРѕ РїРѕСЃС‚Р°РІР»РµРЅР° РЅР° РїР°СѓР·Сѓ РґРѕ backend deploy.



вЂў Р”Р°, BOT_TOKEN РґР»СЏ @club10000_bot РѕР±СЏР·Р°С‚РµР»СЊРЅРѕ РЅСѓР¶РµРЅ РІ .env РЅР° СЃРµСЂРІРµСЂРµ club10000-bot.

  РќРѕ РѕРЅ СѓР¶Рµ Р±С‹Р» РІ РёСЃС…РѕРґРЅРѕРј .env, РєРѕС‚РѕСЂС‹Р№ СЏ РїРµСЂРµРЅРµСЃ РІ:

  /srv/club10000-bot/.env

  Р Р±РѕС‚ СѓР¶Рµ СЃС‚Р°СЂС‚РѕРІР°Р», РїРѕСЃС‚Р°РІРёР» webhook:

  https://iamgradov.ru/webhook/bot

  Р—РЅР°С‡РёС‚ BOT_TOKEN С‚Р°Рј РµСЃС‚СЊ Рё СЂР°Р±РѕС‡РёР№. РРЅР°С‡Рµ Р±РѕС‚ Р±С‹ РЅРµ СЃРјРѕРі Р·Р°РїСѓСЃС‚РёС‚СЊСЃСЏ Рё РІС‹Р·РІР°С‚СЊ Telegram setWebhook.

  Р§С‚Рѕ РІР°Р¶РЅРѕ РїСЂРѕРІРµСЂРёС‚СЊ РІСЂСѓС‡РЅСѓСЋ: С‚РѕРєРµРЅ РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РёРјРµРЅРЅРѕ РѕС‚ @club10000_bot, Р° РЅРµ РѕС‚ copywriting-clubbot. Р­С‚Рѕ
  РјРѕР¶РЅРѕ РїСЂРѕРІРµСЂРёС‚СЊ Р±РµР· СЂР°СЃРєСЂС‹С‚РёСЏ С‚РѕРєРµРЅР°:

  cd /srv/club10000-bot
  docker compose -f docker-compose.production.yml exec bot python - <<'PY'
  import asyncio
  from aiogram import Bot
  from app.config import settings

  async def main():
      bot = Bot(settings.BOT_TOKEN)
      me = await bot.get_me()
      print(me.username, me.id)

  asyncio.run(main())
  PY

  РћР¶РёРґР°РµРјРѕ РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ С‡С‚Рѕ-С‚Рѕ РІСЂРѕРґРµ:

  club10000_bot <id>

  Р•СЃР»Рё Р±СѓРґРµС‚ РґСЂСѓРіРѕР№ username, С‚РѕРіРґР° РЅР°РґРѕ Р·Р°РјРµРЅРёС‚СЊ BOT_TOKEN РІ /srv/club10000-bot/.env Рё РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ РєРѕРЅС‚РµР№РЅРµСЂ.
