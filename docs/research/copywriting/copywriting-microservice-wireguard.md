Порядок выполнения:

Task 1 + Task 2 (параллельно) — WireGuard на обоих серверах  
 ↓  
 Task 3 — развернуть aibot на зарубежном
↓ Task 4 — перенести session файл
Task 5 — переключить diaweb ↓  
 Task 7 — smoke-test
↓
Task 6 — остановить старый aibot

Tasks 1 и 2 можно делать одновременно. Самый критичный момент — Task 5 (переключение), после него copywriting временно может не работать если что-то не так с туннелем.

Для старта: /aif-implement

✻ Cogitated for 1m 46s

❯ /aif-implement  
 ⎿ Read .ai-factory\PLAN.md (155 lines)

● Этот план — инфраструктурный, все задачи выполняются на удалённых серверах по SSH. Я не могу выполнить их автоматически, но могу провести
тебя пошагово.

Готов начать? Подключись к обоим серверам по SSH (два терминала) и скажи "поехали" — буду давать команды по одной.

Или если хочешь, могу сразу выдать полный скрипт для каждого сервера, чтобы ты запустил самостоятельно.

Как удобнее: 1. Пошагово — я даю команду, ты выполняешь, показываешь результат  
 2. Скриптом — два готовых скрипта (foreign + russian), запускаешь сам  
❯ давай полный порядок действий

● Ниже — полный порядок действий. Обозначения:

- [FOREIGN] — выполняй на зарубежном сервере
- [RUSSIAN] — выполняй на российском VPS
- <FOREIGN_IP> — публичный IP зарубежного сервера

---

Phase 1: WireGuard туннель  
 1.1 [FOREIGN] — установка и ключи  
 sudo apt update
sudo apt install -y wireguard
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
sudo chmod 600 /etc/wireguard/private.key

Запомни вывод public.key — это FOREIGN_PUB.

1.2 [RUSSIAN] — установка и ключи

sudo apt update
sudo apt install -y wireguard
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
sudo chmod 600 /etc/wireguard/private.key

Запомни вывод public.key — это RUSSIAN_PUB.

1.3 [FOREIGN] — конфиг

sudo tee /etc/wireguard/wg0.conf << 'EOF'
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <вставь содержимое /etc/wireguard/private.key ЭТОГО сервера>

[Peer]
PublicKey = <вставь RUSSIAN_PUB>
AllowedIPs = 10.0.0.2/32
EOF

sudo systemctl enable --now wg-quick@wg0

Если есть ufw:
sudo ufw allow 51820/udp

1.4 [RUSSIAN] — конфиг

sudo tee /etc/wireguard/wg0.conf << 'EOF'
[Interface]
Address = 10.0.0.2/24
PrivateKey = <вставь содержимое /etc/wireguard/private.key ЭТОГО сервера>

[Peer]
PublicKey = <вставь FOREIGN_PUB>
Endpoint = <FOREIGN_IP>:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
EOF

sudo systemctl enable --now wg-quick@wg0

1.5 [RUSSIAN] — проверка туннеля

ping -c 3 10.0.0.1

Если пингуется — Phase 1 готова.

---

Phase 2: Развёртывание aibot

2.1 [FOREIGN] — установить Docker и git

sudo apt install -y docker.io docker-compose-plugin git
sudo systemctl enable --now docker

2.2 [FOREIGN] — склонировать aibot

sudo mkdir -p /srv
cd /srv
git clone <repo-aibot-url> aibot
cd /srv/aibot

2.3 [FOREIGN] — создать .env.production

sudo nano /srv/aibot/.env.production

Содержимое — скопируй с российского VPS (cat /srv/aibot/.env.production), вставь на новый сервер. Все секреты остаются те же.

2.4 [FOREIGN] — открыть порт API на WireGuard

sudo nano /srv/aibot/docker-compose.prod.yml

В секции copywriting-api, после expose: ["8090"] добавь:

      ports:
        - "10.0.0.1:8090:8090"

Можно оставить expose или убрать — ports его перекрывает.

2.5 [FOREIGN] — запустить стек

cd /srv/aibot
docker compose -f docker-compose.prod.yml up -d --build

Дождись сборки, затем проверь:

docker compose -f docker-compose.prod.yml ps
curl http://10.0.0.1:8090/internal/v1/health

---

Phase 3: Перенос Telethon session

3.1 [RUSSIAN] — скопировать session

mkdir -p /tmp/userbot-backup
docker cp copywriting-userbot:/var/lib/copywriting/userbot/. /tmp/userbot-backup/
scp -r /tmp/userbot-backup/ user@<FOREIGN_IP>:/tmp/userbot-backup/

3.2 [FOREIGN] — восстановить session

docker cp /tmp/userbot-backup/. copywriting-userbot:/var/lib/copywriting/userbot/
docker restart copywriting-userbot

Проверь что userbot живой:

cd /srv/aibot
docker compose -f docker-compose.prod.yml logs --tail=20 copywriting-userbot

---

Phase 4: Переключение diaweb

4.1 [RUSSIAN] — обновить env

sudo nano /srv/diaweb/frontend/.env.production

Найди строку:
COPYWRITING_API_URL=http://copywriting-api:8090/internal/v1

Замени на:
COPYWRITING_API_URL=http://10.0.0.1:8090/internal/v1

4.2 [RUSSIAN] — пересобрать diaweb

cd /srv/diaweb
docker compose -f docker-compose.prod.yml up -d --build

---

Phase 5: Smoke-test

5.1 [RUSSIAN] — проверки

# API через WireGuard

curl -fsS http://10.0.0.1:8090/internal/v1/health

# diaweb health

curl -fsS http://127.0.0.1:3000/api/health

# BFF (ожидаем 401 — это нормально)

curl -i http://127.0.0.1:3000/api/staff/copywriting/briefs

5.2 [FOREIGN] — проверки сервисов

cd /srv/aibot

# worker heartbeat

docker compose -f docker-compose.prod.yml exec copywriting-worker \
 python scripts/runtime_probe.py heartbeat \
 --file /tmp/copywriting-worker-heartbeat.json --max-age 90

# userbot heartbeat

docker compose -f docker-compose.prod.yml exec copywriting-userbot \
 python scripts/runtime_probe.py heartbeat \
 --file /tmp/copywriting-userbot-heartbeat.json --max-age 180

5.3 [FOREIGN] — проверка что OpenAI/Groq не блокируется

docker compose -f docker-compose.prod.yml exec copywriting-worker \
 python -c "import httpx; r = httpx.get('https://api.openai.com/v1/models', timeout=10); print(r.status_code)"

Если вернёт 401 (unauthorized, но не timeout/connection error) — значит сеть работает, блокировки нет.

---

Phase 6: Cleanup

6.1 [RUSSIAN] — остановить старый aibot

Только после того как всё проверено:

cd /srv/aibot
docker compose -f docker-compose.prod.yml down

Опционально, удалить старые volumes:

docker volume rm copywriting_postgres_data copywriting_api_userbot_session copywriting_userbot_session copywriting_exports

---

Rollback (если что-то пошло не так)

# [RUSSIAN] — вернуть env обратно

sudo nano /srv/diaweb/frontend/.env.production

# COPYWRITING_API_URL=http://copywriting-api:8090/internal/v1

# [RUSSIAN] — поднять старый aibot

cd /srv/aibot
docker compose -f docker-compose.prod.yml up -d

# [RUSSIAN] — пересобрать diaweb

cd /srv/diaweb
docker compose -f docker-compose.prod.yml up -d --build

---

По ходу выполнения пиши мне вывод каждого шага — помогу если что-то пойдёт не так.

✻ Brewed for 37s

Обновления

# [FOREIGN]

cd /srv/aibot  
 git pull  
 docker compose -f docker-compose.prod.yml up -d --build

Единственный нюанс — не потеряй свою правку в docker-compose.prod.yml (добавленный ports: ["10.0.0.1:8090:8090"]). Если git pull покажет конфликт в этом файле — просто сохрани свою строку ports.  
 diaweb обновляется как раньше, на российском VPS:

# [RUSSIAN]

cd /srv/diaweb
git pull
docker compose -f docker-compose.prod.yml up -d --build

Порядок обновления тот же: сначала aibot, потом diaweb.

5.35.7.178 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEUBEmnSo6DsQOBCziqsdBCTz6yByUkLVKU+V6HAOt2fAlzkgbvkE3vA+Fu4g4KHVxSSOXExn7QHLKWQdK/GqDe8UyTuc9DJOdV8ShfLcOyMI8Lr3YPCC+88b6fAzrLx00dzhSrUE92E9Y7LZ/W/dF+BZlHL5MXOtaNs46FpUFIyTGQJ3Jk7/lb1amEkKCbml27V8ruNsTOBEirLbvsWwceeSp6aA6RvQXMDjxbkmoUipae/11x9eKTs3PRty5239u4gQYf+2JBdEhSQmt1pUpI1SIaePuXSctJMKuIIu29w8CcCRiVX1OYfA39PFGsJO+5hsiyhqkhonM51A+l72UECtwgGqcU5B3cNCFurj7EQOd5rfTJY+CYYFfVQcJ5rx7ksuvNz3nA+H71quo8dK68DFJnYOBacE/UGIWzy7RlbwAyA+7tB7z+ESt7sVFZVFDdanHLLgaWo1vLR0GuTQEoTERQZSqfLN5AhPlwluLVykslsLEIewSzJsE5ZTxUC8=
5.35.7.178 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCKt0jl7GbCjWin39TwmXr+bi+Gv0jT0guMQJhxdlEiSXYO6C1oZFDCgneCUZfqbUTI9ILIk4z/GNz322hNbeaU=
5.35.7.178 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBABU7E2D1kzUpSEJ0GjkXkO7C4H5MMqlhmEQbSNUlI1
