#!/usr/bin/env bash
set -euo pipefail

exec 9>/tmp/wp-deploy.lock
flock -n 9 || { echo "Another deploy is running"; exit 1; }

cd /opt/project-team1
PREV=$(git rev-parse HEAD)
git pull --ff-only
cd wordpress

healthcheck() {
  for i in $(seq 1 30); do
    if curl -fsS -o /dev/null http://localhost/wp-login.php; then
      return 0
    fi
    sleep 2
  done
  return 1
}

if sudo docker compose pull && sudo docker compose up -d --remove-orphans && healthcheck; then
  echo "Deploy OK"
  exit 0
fi

echo "Deploy FAILED, rolling back to $PREV"
sudo docker compose logs --tail 50 || true
cd /opt/project-team1
git reset --hard "$PREV"
cd wordpress
sudo docker compose up -d --remove-orphans
if healthcheck; then
  echo "Rolled back to $PREV, site is up"
else
  echo "Rollback failed too, check the server"
fi
exit 1
