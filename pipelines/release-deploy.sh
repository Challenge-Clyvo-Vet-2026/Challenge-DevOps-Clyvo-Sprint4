#!/usr/bin/env bash
# Script da task "Deploy no Web App" (Bash, inline) do pipeline de CD elo-vet-api-CD.
# As variaveis $(WEBAPP_NAME), $(DEPLOY_USER) e $(DEPLOY_PASS) sao definidas na aba
# Variables da Release; DEPLOY_USER e DEPLOY_PASS ficam marcadas como secretas (cadeado).

JAR=$(find "$(System.DefaultWorkingDirectory)" -name "*.jar" ! -name "*-plain.jar" | head -n 1)
echo "Enviando $JAR"
curl -f --max-time 600 -X POST -H "Content-Type: application/octet-stream" \
  -u '$(DEPLOY_USER):$(DEPLOY_PASS)' --data-binary @"$JAR" \
  "https://$(WEBAPP_NAME).scm.azurewebsites.net/api/publish?type=jar"
