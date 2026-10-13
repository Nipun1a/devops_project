#!/bin/bash
set -euo pipefail

# Run as root. Re-running preserves the database credentials and Docker volumes.
install -d -m 700 /opt/sonarqube
printf 'vm.max_map_count=524288\n' > /etc/sysctl.d/99-sonarqube.conf
sysctl -p /etc/sysctl.d/99-sonarqube.conf
if [ "$(sysctl -n fs.file-max)" -lt 131072 ]; then
  echo 'fs.file-max=131072' >> /etc/sysctl.d/99-sonarqube.conf
  sysctl -p /etc/sysctl.d/99-sonarqube.conf
fi
if [ ! -f /opt/sonarqube/database.env ]; then
  umask 077
  sonar_db_password=$(openssl rand -hex 32)
  printf 'POSTGRES_USER=sonarqube\nPOSTGRES_DB=sonarqube\nPOSTGRES_PASSWORD=%s\n' "$sonar_db_password" > /opt/sonarqube/database.env
  printf 'SONAR_JDBC_URL=jdbc:postgresql://sonar-db:5432/sonarqube\nSONAR_JDBC_USERNAME=sonarqube\nSONAR_JDBC_PASSWORD=%s\n' "$sonar_db_password" > /opt/sonarqube/server.env
  unset sonar_db_password
fi
docker network inspect sonarqube >/dev/null 2>&1 || docker network create sonarqube
if ! docker container inspect sonar-db >/dev/null 2>&1; then
  docker run -d --name sonar-db --restart unless-stopped --network sonarqube \
    --env-file /opt/sonarqube/database.env \
    -v sonarqube_postgres:/var/lib/postgresql/data postgres:17
else
  docker start sonar-db
fi
sonar_db_ready=false
for attempt in $(seq 1 60); do
  if docker exec sonar-db pg_isready -U sonarqube -d sonarqube; then
    sonar_db_ready=true
    break
  fi
  sleep 2
done
if [ "$sonar_db_ready" != true ]; then
  echo 'SonarQube database did not become ready.' >&2
  exit 1
fi
if ! docker container inspect sonar >/dev/null 2>&1; then
  docker run -d --name sonar --restart unless-stopped --network sonarqube \
    --env-file /opt/sonarqube/server.env \
    --ulimit nofile=131072:131072 --ulimit nproc=8192:8192 \
    -p 9000:9000 \
    -v sonarqube_data:/opt/sonarqube/data \
    -v sonarqube_logs:/opt/sonarqube/logs \
    -v sonarqube_extensions:/opt/sonarqube/extensions sonarqube:community
else
  docker start sonar
fi
