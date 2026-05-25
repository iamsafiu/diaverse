# Update VPS

1.  Залить изменения в репо

Сначала закоммить фикс с BigInteger и запушь (локально):

git add backend/src/modules/auth/models.py
git commit -m "fix: use BigInteger for tg_id to support large Telegram IDs"
git push

2. На сервере

cd /var/www/diaapp
git pull

Бэкенд — перезапустить:
pm2 restart diaweb-backend

Если менял фронтенд тоже — пересобрать и перезапустить:
cd /var/www/diaapp/frontend
npm run build
pm2 restart diaweb-frontend

3. Проверить

pm2 logs diaweb-backend --lines 20
