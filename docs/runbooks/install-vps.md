Окей, тогда план такой:

Что нужно на сервере

┌─────────────────────────────────────────────┐
│ nginx (:80/:443) │
│ SSL (Let's Encrypt) │
│ │
│ cabinet.твой-домен.com │
│ ├── / → frontend :3000 │
│ └── /api/ → backend :8000 │
└──────────┬──────────────┬────────────────────┘
│ │
┌─────▼─────┐ ┌─────▼─────┐
│ Next.js │ │ FastAPI │
│ :3000 │ │ :8000 │
└───────────┘ └─────┬─────┘
│
┌─────────┴─────────┐
│ │
┌─────▼─────┐ ┌─────▼─────┐
│ PostgreSQL │ │ Redis │
│ :5432 │ │ :6379 │
└────────────┘ └───────────┘

Шаг за шагом

1. Установить зависимости

# Node.js 20

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# Python 3.12

sudo apt install -y python3.12 python3.12-venv python3-pip

# PostgreSQL 16

sudo apt install -y postgresql postgresql-contrib

# Redis

sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

2. Настроить PostgreSQL

sudo -u postgres psql
CREATE USER diaverse WITH PASSWORD 'надёжный_пароль';
CREATE DATABASE diaverse OWNER diaverse;
\q

3. Клонировать проект

cd /var/www
git clone <твой-репо> diaweb
cd diaweb

4. Backend

cd /var/www/diaweb/backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e .

Создать .env:
DATABASE*URL=postgresql+asyncpg://diaverse:надёжный*пароль@localhost:5432/diaverse
REDIS*URL=redis://localhost:6379/0
JWT_SECRET_KEY=сгенерируй-длинный-рандом
TELEGRAM_BOT_TOKEN=токен*бота
LOG_LEVEL=INFO
CORS_ORIGINS=https://cabinet.твой-домен.com

Миграции:
alembic upgrade head

5. Frontend

cd /var/www/diaweb/frontend
npm install

Создать .env:
NEXT*PUBLIC_API_URL=https://cabinet.твой-домен.com
NEXT_PUBLIC_TELEGRAM_BOT_NAME=имя*бота

Собрать:
npm run build

6. PM2
   cd /var/www/diaweb/backend
   pm2 start .venv/bin/python --name "diaweb-backend" -- -m uvicorn src.main:app --host 127.0.0.1 --port 8000

cd /var/www/diaweb/frontend
pm2 start npm --name "diaweb-frontend" -- run start -- -p 3000

pm2 save

pm2 startup 7. Nginx

sudo nano /etc/nginx/sites-available/diaweb

/etc/nginx/sites-available/diaweb:
server {
server_name diaverse.app www.diaverse.app;

    # --- НОВЫЙ БЛОК ДЛЯ БЭКЕНДА ---
    location /api/ {
        proxy_pass http://127.0.0.1:8000; # Ваш Python/Uvicorn
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Если бэкенд использует WebSocket (опционально)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
    }

    # --- ВАШ СТАРЫЙ БЛОК ДЛЯ ФРОНТЕНДА ---
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # --- НАСТРОЙКИ SSL (Оставляем как было) ---
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/diaverse.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/diaverse.app/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}

# Редирект с HTTP на HTTPS (обычно Certbot добавляет это в конец файла или в отдельный блок)

server {
if ($host = www.diaverse.app) { return 301 https://$host$request_uri; }
    if ($host = diaverse.app) { return 301 https://$host$request_uri; }
listen 80;
server_name diaverse.app www.diaverse.app;
return 404;
}

sudo ln -s /etc/nginx/sites-available/diaweb /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

8. SSL

sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d cabinet.твой-домен.com

9. BotFather

Домен бота → cabinet.твой-домен.com

---

После этого открываешь https://cabinet.твой-домен.com/ru/login — и виджет Telegram должен
появиться. Хочешь — могу помочь с каким-то конкретным шагом?
