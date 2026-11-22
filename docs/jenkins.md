# Jenkins CI/CD (Task 3)

## Що зроблено

| Хто | Що |
|---|---|
| Босова Єлизавета | Jenkinsfile: стадії Build → Test → Deploy → Smoke test; аплікація і Dockerfile |
| Синиця Артем | Jenkins у Docker на AWS EC2 (`jenkins/docker-compose.yml`), GitHub webhook, push у Docker Hub, автоматичний rollback |

## Як працює

1. Push у `main` → GitHub webhook → Jenkins одразу запускає білд
2. **Build**: збирається Docker-образ `myapp:<номер білду>`
3. **Test**: перевірка синтаксису PHP
4. **Push**: образ публікується в Docker Hub (теги `<номер>` і `latest`)
5. **Deploy**: новий контейнер на порту 8081
6. **Smoke test**: перевірка, що сторінка відповідає з правильним номером білду
7. Якщо Deploy або Smoke test впали → **rollback** на попередню версію

## Демо на захисті

1. Відкрити Jenkins: `http://<IP>:8080`, джоба `project-team1`
2. Змінити рядок у `README.md` прямо на GitHub і зробити Commit → білд стартує сам (`Started by GitHub push`)
3. Показати стадії білду і сайт `http://<IP>:8081` з новим номером білду
4. Показати образ у Docker Hub
5. Rollback: у `index.php` замінити `Build:` на `Bild:` → білд червоний, сайт працює на попередній версії → повернути назад

## Можливі покращення

Деплой через `docker compose` (після Task 2), перевірка PR через Multibranch Pipeline, стадія лінтера, Jenkins Configuration as Code.
