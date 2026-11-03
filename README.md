# Elo Vet — Sprint 4 · DevOps Tools & Cloud Computing

Entrega da **Sprint 4** da disciplina **DevOps Tools & Cloud Computing** (FIAP · Challenge 2026).

Este repositório documenta a esteira de **CI/CD no Azure DevOps** da API Java do **Elo Vet**, publicada no **Azure Web App** com banco **PostgreSQL gerenciado (PaaS)** na Azure.

| | Link |
|---|---|
| 💻 **Código da API Java** | https://github.com/Challenge-2026-EloVet/elo-vet-api |
| 🔷 **Projeto no Azure DevOps** | https://dev.azure.com/EloOrganization/EloVet |
| 🎬 **Vídeo da demonstração** | https://www.youtube.com/watch?v=F53Geu5QT2c |
| 🌐 **API publicada** | https://api-java-seurm-565421.azurewebsites.net |

---

## Sumário

1. [Descrição da solução](#1-descrição-da-solução)
2. [Stack de tecnologias](#2-stack-de-tecnologias)
3. [Arquitetura e fluxo CI/CD](#3-arquitetura-e-fluxo-cicd)
4. [Configuração do projeto no Azure DevOps](#4-configuração-do-projeto-no-azure-devops)
5. [Pipeline de CI](#5-pipeline-de-ci)
6. [Pipeline de CD](#6-pipeline-de-cd)
7. [Infraestrutura na Azure](#7-infraestrutura-na-azure)
8. [Banco de dados](#8-banco-de-dados)
9. [Segurança e variáveis de ambiente](#9-segurança-e-variáveis-de-ambiente)
10. [Testando a API (CRUD)](#10-testando-a-api-crud)
11. [Estrutura deste repositório](#11-estrutura-deste-repositório)
12. [Integrantes](#12-integrantes)

---

## 1. Descrição da solução

O **Elo Vet** é um ecossistema **B2B2C** de cuidado veterinário pós-consulta. O veterinário registra a consulta no portal web integrado à IA da Clyvo; a solução cruza os dados do pet com regras clínicas, gera alertas de saúde e envia um **plano de cuidados** direto ao WhatsApp do tutor, que acompanha o tratamento e agenda retornos pelo app.

Os principais diferenciais são o **prontuário portátil**, que unifica o histórico do pet em qualquer clínica da rede, a **IA preditiva** por raça e o **engajamento ativo** do tutor depois da consulta. O modelo de negócio combina **assinatura SaaS** paga pelas clínicas (fila virtual, prontuário e assistente de IA) com uma **taxa de transação** sobre agendamentos e serviços preventivos feitos pelo marketplace do app.

A **API Java** (`elo-vet-api`) é o núcleo da solução e oferece:

- **CRUD de pets** e de **responsáveis (tutores)**, com o vínculo entre eles;
- **Autenticação e autorização com JWT** (Spring Security), com os perfis `ADMIN`, `USER`, `VETERINARIO` e `RESPONSAVEL`;
- **Planos de cuidado** com checklist terapêutico (remédios, vacinas e retornos) e lembretes ao tutor;
- **Versionamento do banco** com Flyway.

---

## 2. Stack de tecnologias

| Camada | Tecnologia |
|---|---|
| Linguagem | Java 21 |
| Framework | Spring Boot 4 (Web MVC, Data JPA, Validation, Security) |
| Autenticação | Spring Security + JWT |
| Build | Gradle (wrapper incluso no projeto) |
| Testes | JUnit 5 + Mockito |
| Banco de dados | **Azure Database for PostgreSQL Flexible Server** (PaaS) |
| Migrações | Flyway |
| Repositório | **Azure Repos** (Git), com o código importado do GitHub |
| Gestão do trabalho | **Azure Boards** (processo Scrum) |
| Integração contínua | **Azure Pipelines** — YAML |
| Entrega contínua | **Azure Pipelines** — Release |
| Hospedagem | **Azure App Service** — Web App Linux, Java 21 |
| Infraestrutura | Azure CLI (scripts em [`infra/`](infra)) |

---

## 3. Arquitetura e fluxo CI/CD

![Arquitetura e fluxo CI/CD do Elo Vet](docs/arquitetura-elovet-cicd.png)

> O arquivo editável do diagrama está em [`docs/arquitetura-elovet-cicd.drawio`](docs/arquitetura-elovet-cicd.drawio) (abrir em https://app.diagrams.net).

### Fluxo numerado

| # | Etapa | Ferramenta |
|---|---|---|
| 1 | O **desenvolvedor** faz o commit na branch `DevOpsEntrega` e abre um **Pull Request** para a `main` | Azure Repos |
| 2 | O **merge na `main`** dispara automaticamente o pipeline de CI | Azure Pipelines (YAML) |
| 3 | O CI compila a API com **Gradle (Java 21)** e executa os **testes automatizados** (JUnit + Mockito) | Azure Pipelines |
| 4 | O CI publica os **resultados dos testes** e o **artefato** `drop` com o `.jar` | Azure Pipelines / Artifacts |
| 5 | O novo artefato dispara automaticamente o **pipeline de CD** | Azure Pipelines (Release) |
| 6 | O CD faz o **deploy do `.jar`** no Azure Web App, com credenciais guardadas como **variáveis secretas** | Release → Azure App Service |
| 7 | A API lê e grava os dados no **PostgreSQL** via JDBC com SSL; o Flyway aplica as migrações | Azure Database for PostgreSQL |
| 8 | O **usuário final** (tutor, clínica ou veterinário) acessa a API pela internet, via HTTPS com token JWT | Azure Web App |

---

## 4. Configuração do projeto no Azure DevOps

| Item | Configuração |
|---|---|
| Organização / Projeto | `EloOrganization` / `EloVet` |
| Visibilidade | **Private** |
| Controle de versão | **Git** (Azure Repos) |
| Processo de trabalho | **Scrum** (Product Backlog Items, Features e Epics no Azure Boards) |
| Branch principal | `main` — protegida por política: alterações somente via **Pull Request** |
| Branch de trabalho | `DevOpsEntrega` |
| Acesso do professor | Nível **Basic** na organização e **Project Administrator** no projeto |

---

## 5. Pipeline de CI

Arquivo: [`pipelines/azure-pipelines.yml`](pipelines/azure-pipelines.yml) (na raiz do repositório da API no Azure Repos).

- **Gatilho:** toda alteração na branch `main`.
- **Agente:** `ubuntu-latest` (Microsoft-hosted).

| # | Task | O que faz |
|---|---|---|
| 1 | `script: chmod +x gradlew` | Dá permissão de execução ao Gradle Wrapper no agente Linux |
| 2 | `Gradle@3` — **Build e testes (Java 21)** | Executa `./gradlew build`: compila o código, **roda os testes JUnit** e publica os resultados na aba **Tests** da execução. Se algum teste falhar, o pipeline para e **não há deploy** |
| 3 | `CopyFiles@2` — **Copiar JAR executável** | Copia o `.jar` executável de `build/libs`, ignorando o `-plain.jar` |
| 4 | `PublishBuildArtifacts@1` — **Publicar artefato** | Publica o artefato `drop` no Azure DevOps |

### Testes automatizados

Os testes ficam em `src/test/java` no repositório da API e rodam no agente do Azure Pipelines a cada execução do CI. São testes unitários com **JUnit 5 + Mockito**, que não dependem do banco de dados:

| Classe | Testes | O que valida |
|---|---|---|
| `PetServiceTest` | 6 | Listar, criar, atualizar e excluir pets; erro ao buscar e ao excluir pet inexistente |
| `PetMapperTest` | 2 | Conversão de request para entidade, inclusive com sexo nulo |

Resultado: **8 testes, 100% aprovados**, visíveis na aba **Tests** de cada execução.

---

## 6. Pipeline de CD

Release **`elo-vet-api-CD`**, estágio **`Producao`**.

| Item | Configuração |
|---|---|
| Artefato | Saída do pipeline de CI (`_EloVet` / `drop`) |
| Gatilho | **Continuous deployment trigger** ativado: cada novo artefato cria uma release automaticamente |
| Agente | `ubuntu-latest` |
| Task | **Bash — Deploy no Web App**: envia o `.jar` para o Web App pela API de publicação do Kudu (`/api/publish?type=jar`) |
| Variáveis | `WEBAPP_NAME`, `DEPLOY_USER` 🔒 e `DEPLOY_PASS` 🔒 (secretas) |

Script da task: [`pipelines/release-deploy.sh`](pipelines/release-deploy.sh)

```bash
JAR=$(find "$(System.DefaultWorkingDirectory)" -name "*.jar" ! -name "*-plain.jar" | head -n 1)
echo "Enviando $JAR"
curl -f --max-time 600 -X POST -H "Content-Type: application/octet-stream" \
  -u '$(DEPLOY_USER):$(DEPLOY_PASS)' --data-binary @"$JAR" \
  "https://$(WEBAPP_NAME).scm.azurewebsites.net/api/publish?type=jar"
```

> O deploy usa as credenciais de publicação do Web App, guardadas como variáveis secretas na Release. A senha nunca aparece no log da execução.

---

## 7. Infraestrutura na Azure

| Recurso | Nome | Detalhes |
|---|---|---|
| Resource Group | `rg-elovet-devops` | Região Canada Central |
| App Service Plan | `plan-elovet-devops` | Linux, SKU B2 |
| Web App | `api-java-seurm-565421` | Runtime `JAVA:21-java21` |
| PostgreSQL Flexible Server | `elovet-postgres-565421` | Burstable `Standard_B1ms` (PaaS) |
| Database | `elovet` | Schema versionado pelo Flyway |

A infraestrutura é criada pelo script [`infra/criar-infra.sh`](infra/criar-infra.sh), com Azure CLI. As senhas são pedidas durante a execução e **não ficam salvas** em nenhum arquivo. Para remover tudo depois da correção: [`infra/limpar-infra.sh`](infra/limpar-infra.sh).

---

## 8. Banco de dados

**Azure Database for PostgreSQL Flexible Server** (PaaS). O schema é criado e versionado pelo **Flyway** quando a API sobe (`src/main/resources/db/migration` no repositório da API).

| Tabela | Descrição | Relacionamentos |
|---|---|---|
| `elo_login` | Usuários do sistema (login e perfil) | — |
| `elo_responsavel` | Tutores (responsáveis pelos pets) | FK `id_usuario` → `elo_login` |
| `elo_pet` | Cadastro de pets | — |
| `elo_pet_responsavel` | Vínculo N:N entre pets e responsáveis | FK `id_pet` → `elo_pet`, FK `id_responsavel` → `elo_responsavel` |
| `care_plan`, `care_plan_item`, `notification`, `follow_up_log` | Planos de cuidado, itens do checklist, notificações e histórico de acompanhamento | Referenciam o pet, o tutor e o plano pelos ids |

---

## 9. Segurança e variáveis de ambiente

Nenhuma credencial fica no código. A aplicação lê tudo de variáveis de ambiente, configuradas como **App Settings** do Web App:

| Variável | Descrição |
|---|---|
| `SPRING_DATASOURCE_URL` | URL JDBC do PostgreSQL (com `sslmode=require`) |
| `SPRING_DATASOURCE_USERNAME` | Usuário do banco |
| `SPRING_DATASOURCE_PASSWORD` | Senha do banco |
| `SPRING_JPA_HIBERNATE_DDL_AUTO` | Estratégia do Hibernate |
| `API_SECURITY_TOKEN_SECRET` | Segredo de assinatura dos tokens JWT (gerado aleatoriamente) |

Na Release, `DEPLOY_USER` e `DEPLOY_PASS` são **variáveis secretas** (cadeado), exibidas como `********`.

---

## 10. Testando a API (CRUD)

Base: `https://api-java-seurm-565421.azurewebsites.net` · Body em JSON.

**1. Login** — `POST /auth/login`

```json
{
  "email": "admin@elovet.com",
  "senha": "admin123"
}
```

Copie o `token` da resposta e envie em todas as requisições de `/pet` no header `Authorization: Bearer <token>`.

**2. CRUD de Pet**, com conferência no banco depois de cada operação:

| Operação | Requisição | Status | Conferência no PostgreSQL |
|---|---|---|---|
| Inserir | `POST /pet` | 201 | `SELECT * FROM elo_pet ORDER BY id_pet DESC;` |
| Consultar | `GET /pet/{id}` | 200 | `SELECT * FROM elo_pet WHERE id_pet = {id};` |
| Atualizar | `PUT /pet/{id}` | 200 | `SELECT * FROM elo_pet WHERE id_pet = {id};` |
| Excluir | `DELETE /pet/{id}` | 204 | `SELECT * FROM elo_pet WHERE id_pet = {id};` (nenhuma linha) |

Body do `POST` e do `PUT`:

```json
{
  "nome": "Rex",
  "especie": "Cachorro",
  "raca": "Labrador",
  "sexo": "M",
  "dataNascimento": "2022-03-15",
  "idadeAproximada": 4,
  "flagCastrado": 1
}
```

**3. Alteração demonstrada no vídeo:** a mensagem de pet não encontrado (`GET /pet/999`) passou de `Pet not found with id: 999` para `Pet não encontrado com o id: 999`, publicada pela esteira de CI/CD.

---

## 11. Estrutura deste repositório

```
.
├── README.md                          # Esta documentação
├── docs/
│   ├── arquitetura-elovet-cicd.png    # Diagrama de arquitetura e fluxo CI/CD
│   └── arquitetura-elovet-cicd.drawio # Arquivo editável do diagrama
├── pipelines/
│   ├── azure-pipelines.yml            # Pipeline de CI (YAML)
│   └── release-deploy.sh              # Script da task de deploy do CD
└── infra/
    ├── criar-infra.sh                 # Criação dos recursos na Azure (Azure CLI)
    └── limpar-infra.sh                # Remoção dos recursos
```

---

## 12. Integrantes

| Nome completo | RM | Turma |
|---|---|---|
| Arthur Graciani Bezerra | RM561728 | 2TDSPX |
| Gustavo Pinheiro De Oliveira | RM566358 | 2TDSPX |
| João Pedro Scarpin de Assis Carvalho | RM565421 | 2TDSPX |
| Lucas Hideki Penha Suguiura de Souza | RM565355 | 2TDSPX |
| Wesley Silva de Andrade | RM563593 | 2TDSPX |
