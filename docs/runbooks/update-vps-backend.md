# Update VPS Backend

У тебя уже настроен GitLab CI/CD — обновление полностью автоматическое:

Dev сервер → пуш в ветку dev
git push origin dev

Прод сервер → пуш в ветку main
git push origin main

CI сам:

1. Копирует файлы через rsync на сервер
2. Делает make build (пересобирает Docker образ)
3. Делает make migrate (запускает Alembic миграции)
4. Делает make deploy (перезапускает контейнеры)

Т.е. вручную на VPS заходить не нужно. Просто мёрджишь изменения в нужную ветку и пушишь.
