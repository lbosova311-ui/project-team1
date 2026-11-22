# WordPress on AWS: CI/CD Test Bed

A working WordPress site running on EC2 with its database in RDS. Deployment is handled by a single script that Jenkins calls. Everything lives in the `us-east-1` region.

## Architecture

```
push to main
   |
   v
Jenkins (separate AWS account)
   |  SSH, key restricted to deploy.sh
   v
EC2 wp-app: scripts/deploy.sh
   git pull, docker compose up, health check, rollback on failure
   |
   v
RDS MySQL (reachable only from sg_wordpress)
```

## Resources

| Resource | Value |
|---|---|
| Region | us-east-1 (N. Virginia) |
| Site | http://184.196.191.91 |
| Admin panel | http://184.196.191.91/wp-admin |
| EC2 | wp-app, Ubuntu 24.04, t3.small, `i-0bec1b10ca26928d6` |
| Elastic IP | 184.196.191.91 |
| RDS | wp-db, MySQL 8.4, db.t4g.micro, endpoint `wp-db.cwh24w222lht.us-east-1.rds.amazonaws.com`, database `wordpress`, user `wpadmin` |
| Server security group | sg_wordpress |
| Database security group | sg_rds (port 3306 only from sg_wordpress) |
| Repository on the server | /opt/project-team1 |
| Project folder | wordpress/ |

## How deployment works

The single entry point is `wordpress/scripts/deploy.sh`:

1. Records the currently deployed commit.
2. Runs `git pull --ff-only` from `main`.
3. Runs `docker compose pull` and `docker compose up -d --remove-orphans`.
4. Waits up to 60 seconds for `wp-login.php` to respond.
5. On failure, restores the previous commit, restarts the container and exits with an error.

Concurrent runs are blocked with `flock`. The outcome is visible in the exit code: 0 means success, 1 means failure (the rollback has already been performed).

Manual run on the server:

```bash
bash /opt/project-team1/wordpress/scripts/deploy.sh
```

## Secrets

The database password and the WordPress session keys live only in `wordpress/.env` on the server. Git contains `.env.example`, which lists the variable names. Never commit the real `.env`.

## Access

| Who | How they connect |
|---|---|
| Jenkins | SSH to `ubuntu@184.196.191.91` with a key that is restricted in `authorized_keys` to `command="bash /opt/project-team1/wordpress/scripts/deploy.sh"`. Port 22 is open for the Jenkins IP only (/32) |
| Administrator | SSH with a personal key, or AWS Session Manager |
