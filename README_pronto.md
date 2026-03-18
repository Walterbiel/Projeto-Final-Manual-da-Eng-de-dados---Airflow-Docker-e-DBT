# Guia Rápido — Subir o Projeto do Zero

> Pré-requisitos instalados: Python 3.13+, Docker Desktop (aberto), Astro CLI, Git.

---

## 1. Clonar o projeto

```bash
git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
cd projeto_final_engenharia
```

---

## 2. Subir o PostgreSQL

```bash
cd 1_local_setup
docker compose up -d
docker ps   # confirme: dbt_postgres está Up e (healthy)
```

---

## 3. Ambiente Python + dbt

```bash
# Ainda em 1_local_setup/
uv venv .venv
source .venv/bin/activate        # Git Bash / Linux / Mac
# .venv\Scripts\Activate.ps1    # PowerShell

uv sync
dbt --version   # confirme que instalou
```

---

## 4. Criar o profiles.yml

Crie o arquivo `2_data_warehouse/dw_bootcamp/profiles.yml` com o conteúdo abaixo:

```yaml
dw_bootcamp:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5433
      user: postgres
      password: postgres
      dbname: dbt_db
      schema: public
      threads: 4
```

---

## 5. Rodar o pipeline dbt

```bash
cd ../2_data_warehouse/dw_bootcamp

dbt debug   # deve mostrar tudo OK
dbt deps    # instala os pacotes (dbt-utils, dbt-expectations)
dbt seed    # carrega o CSV no banco (~5 min)
dbt build --exclude-resource-type seed   # roda models + testes
```

### Ver a documentação

```bash
dbt docs generate
dbt docs serve --port 8085
# Acesse: http://localhost:8085
```

---

## 6. Subir o Airflow

```bash
# Copie o projeto dbt para dentro da pasta do Airflow
cp -r 2_data_warehouse/dw_bootcamp 3_airflow/dbt/

cd 3_airflow
astro dev start
# Acesse: http://localhost:8080  |  usuário: admin  |  senha: admin
```

### Configurar conexão no Airflow (uma vez só)

**Admin → Connections → +**

| Campo | Valor |
|---|---|
| Connection Id | `docker_postgres_db` |
| Connection Type | `Postgres` |
| Host | `host.docker.internal` |
| Schema | `dbt_db` |
| Login | `postgres` |
| Password | `postgres` |
| Port | `5433` |

### Configurar variável no Airflow (uma vez só)

**Admin → Variables → +**

| Key | Val |
|---|---|
| `dbt_env` | `dev` |

### Ativar e rodar o DAG

1. Na tela de DAGs, localize `dag_dw_bootcamp_dev`
2. Ative o toggle
3. Clique em **▶ Trigger DAG**

---

## 7. CI/CD com GitHub Actions

O workflow roda automaticamente a cada `push` ou Pull Request para `main`. Não precisa configurar nada além de ter o repositório no GitHub.

### Publicar o projeto no GitHub (primeira vez)

```bash
git init
git add .
git commit -m "feat: projeto inicial"
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
git branch -M main
git push -u origin main
```

### Acompanhar o CI

1. Acesse o repositório no GitHub
2. Clique na aba **Actions**
3. Aguarde os dois jobs:

```
✅ Compilar modelos dbt (validação de sintaxe)   ~2 min
✅ Executar pipeline completo (seed + run + test) ~10-15 min
```

### Baixar a documentação gerada pelo CI

No workflow concluído → seção **Artifacts** → clique em **dbt-docs** → extraia o `.zip` e abra o `index.html`.

### Enviar atualizações (dia a dia)

```bash
git add .
git commit -m "sua mensagem"
git push
# O CI roda automaticamente
```

### Trabalhar com branches (fluxo de equipe)

```bash
git checkout -b feature/minha-alteracao
# faça suas alterações...
git add .
git commit -m "feat: descrição da mudança"
git push origin feature/minha-alteracao
# Abra um Pull Request no GitHub — o CI valida antes do merge
```

---

## 8. Parar tudo

```bash
# Parar Airflow
cd 3_airflow
astro dev stop

# Parar PostgreSQL
cd ../1_local_setup
docker compose down
```

---

## Portas de referência

| Serviço | URL |
|---|---|
| Airflow UI | http://localhost:8080 |
| dbt docs | http://localhost:8085 |
| PostgreSQL local | localhost:5433 |
