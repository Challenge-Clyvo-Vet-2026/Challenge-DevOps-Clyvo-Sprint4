#!/usr/bin/env bash
# Cria a infraestrutura da Sprint 4 na Azure (Azure CLI).
# Nenhuma senha fica no arquivo: elas sao pedidas durante a execucao.
set -euo pipefail

RG="rg-elovet-devops"
LOCATION="canadacentral"
PG_SERVER="elovet-postgres-565421"
PG_DB="elovet"
PLAN="plan-elovet-devops"
WEBAPP="api-java-seurm-565421"

read -rp  "Usuario admin do PostgreSQL: " PG_USER
read -rsp "Senha do admin do PostgreSQL: " PG_PASS; echo

echo ">> Resource Group"
az group create -n "$RG" -l "$LOCATION" -o none

echo ">> PostgreSQL Flexible Server (PaaS)"
az postgres flexible-server create -g "$RG" -n "$PG_SERVER" -l "$LOCATION" \
  --tier Burstable --sku-name Standard_B1ms --storage-size 32 \
  --admin-user "$PG_USER" --admin-password "$PG_PASS" \
  --public-access 0.0.0.0-255.255.255.255 -o none
az postgres flexible-server db create -g "$RG" -s "$PG_SERVER" -d "$PG_DB" -o none

echo ">> App Service Plan (Linux) e Web App Java 21"
az appservice plan create -g "$RG" -n "$PLAN" --is-linux --sku B2 -o none
az webapp create -g "$RG" -p "$PLAN" -n "$WEBAPP" --runtime "JAVA:21-java21" -o none

echo ">> Variaveis de ambiente do Web App"
JWT_SECRET=$(openssl rand -base64 48)
az webapp config appsettings set -g "$RG" -n "$WEBAPP" -o none --settings \
  SPRING_DATASOURCE_URL="jdbc:postgresql://$PG_SERVER.postgres.database.azure.com:5432/$PG_DB?sslmode=require" \
  SPRING_DATASOURCE_USERNAME="$PG_USER" \
  SPRING_DATASOURCE_PASSWORD="$PG_PASS" \
  SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
  API_SECURITY_TOKEN_SECRET="$JWT_SECRET"

echo ">> Credencial de publicacao usada pela Release (CD)"
read -rp  "Usuario de deployment: " DEPLOY_USER
read -rsp "Senha de deployment: " DEPLOY_PASS; echo
az webapp deployment user set --user-name "$DEPLOY_USER" --password "$DEPLOY_PASS" -o none

echo ">> Pronto: https://$WEBAPP.azurewebsites.net"
