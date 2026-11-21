#!/usr/bin/env bash
set -euo pipefail

exec 9>/tmp/wp-deploy.lock
flock -n 9 || { echo "Another deploy is running"; exit 1; }

cd /opt/project-team1
git pull --ff-only
cd wordpress
sudo docker compose pull
sudo docker compose up -d --remove-orphans

for i in $(seq 1 30); do
  if curl -fsS -o /dev/null http://localhost/wp-login.php; then
    echo "Deploy OK"
    exit 0
  fi
  sleep 2
done
echo "Healthcheck failed"
sudo docker compose logs --tail 50
exit 1
