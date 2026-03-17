# 🚀 Projeto Final – Data Warehouse com dbt, Docker e Airflow

Este projeto tem como objetivo construir um **Data Warehouse completo**, utilizando **PostgreSQL**, **dbt**, **Docker** e **Airflow**, seguindo boas práticas de engenharia de dados.

---

## 1️⃣ Setup do Ambiente Local

### Pré-requisitos

- Python instalado  
- Acesso ao terminal (PowerShell ou Git Bash)  
- Docker e Docker Desktop instalados  

---

### Estrutura de Pastas do Projeto

Criar as seguintes pastas na raiz do repositório:

```
1_local_setup
2_data_warehouse
3_airflow
```

---

### Setup do Ambiente Python

Instalar o `uv` (gerenciador de dependências e ambientes virtuais):

```bash
pip install uv
uv --version
```

Entrar na pasta de setup local:

```bash
cd .\1_local_setup\
```

Criar e ativar o ambiente virtual:

```bash
uv venv .venv
.\.venv\Scripts\Activate.ps1
```
---
```bash
uv init
```

> ⚠️ **Importante**  
> Sempre execute os comandos **nesta ordem** para evitar problemas de ambiente.

---

### Instalação das Dependências

```bash
uv add dbt-core dbt-postgres faker pandas numpy
```

---

## 🐳 Docker

### Docker Compose

- Criar o arquivo `docker-compose.yml` dentro da pasta `1_local_setup`
- Responsável por subir o PostgreSQL local

---

### Arquivo `.env`

Criar o arquivo `.env` dentro da pasta `1_local_setup`:

```env
DBT_USER=postgres
DBT_PASSWORD=postgres
```

Adicionar o arquivo `.env` ao `.gitignore`.

---

### Subir o Ambiente Docker

```bash
docker compose up -d
```

Validar se o container está rodando no Docker Desktop.

---

## 2️⃣ Data Warehouse com dbt

Entrar na pasta:

```bash
cd 2_data_warehouse

..\1_local_setup\.venv\Scripts\activate
```

Inicializar o projeto dbt:

```bash
dbt init
```

---

### Configuração Interativa do dbt

Durante a inicialização:

- Nome do projeto  
- Opção: PostgreSQL  
- Host: `localhost`  
- Porta: `5433`  
- User: conforme `.env`  
- Senha: conforme `.env`  
- Database: `dbt_db`  
- Schema: `public`  
- Threads: `4`  

---

### Validação da Conexão

```bash
cd dw_bootcamp
dbt debug
```

---

## Seeds

- Colocar arquivos CSV dentro da pasta `seeds/`
- Seeds representam dados de origem para estudo e testes

---

## Configuração do `dbt_project.yml`

```yml
name: 'dw_bootcamp'
version: '1.0.0'

profile: 'dw_bootcamp'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

vars:
  "dbt_date:time_zone": "America/Sao_Paulo"

clean-targets:
  - "target"
  - "dbt_packages"

models:
  dw_bootcamp:
    staging:
      +materialized: view
    intermediate:
      +materialized: table
    mart:
      +materialized: table
```

---

## Estrutura de Models

```
models/
├── staging
├── intermediate
└── mart
```

- **staging**: limpeza e padronização dos dados
- **intermediate**: criação de fatos e dimensões
- **mart**: modelos finais prontos para análise

---

## Execução do dbt

Pipeline completo:

```bash
dbt build
```

Rodar apenas um modelo específico:

```bash
dbt run -s stg_airline_delay_cause
```

Para rodar sem executar seeds novamente:

```bash
dbt build --exclude-resource-type seed
```

---

## Pacotes do dbt

Criar o arquivo `packages.yml`:

```yml
packages:

  - package: dbt-labs/dbt_utils
    version: "1.3.0"

  - package: metaplane/dbt_expectations
    version: "0.10.8"
```

Instalar os pacotes:

```bash
dbt deps
```

---

## 3️⃣ Airflow

Instalar o Astro CLI:

```bash
winget install -e --id Astronomer.Astro
```

Requeriments.txt do airflow:

'''
apache-airflow-providers-postgres
astronomer-cosmos
'''


Criar dag python:

```python
# Importa o Variable do Airflow, que permite ler variáveis configuradas na UI do Airflow
# (ex: escolher se o DAG roda em dev ou prod sem mudar o código)
from airflow.models import Variable

# Importa os componentes do Cosmos, biblioteca que transforma um projeto dbt em um DAG no Airflow
# - DbtDag: cria o DAG automaticamente com base nos modelos do dbt
# - ProjectConfig: aponta onde está o projeto dbt
# - ProfileConfig: define qual profile/target do dbt será usado
# - ExecutionConfig: define como executar o dbt (caminho do executável)
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig

# Importa o mapeamento de profile para Postgres usando usuário/senha a partir de uma conexão do Airflow
# (Cosmos “traduz” uma Airflow Connection em um profiles.yml em tempo de execução)
from cosmos.profiles import PostgresUserPasswordProfileMapping

# Importa os para lidar com variáveis de ambiente e caminhos
import os

# Importa datetime do pendulum (o Airflow usa pendulum para datas/timezones de forma mais robusta)
from pendulum import datetime


# =========================
# 1) CONFIG DE PROFILE DEV
# =========================
# Cria um ProfileConfig para o ambiente dev
# - profile_name: nome do profile do dbt (equivalente ao que existiria no profiles.yml)
# - target_name: target do dbt (dev)
# - profile_mapping: como o Cosmos vai montar as credenciais do dbt usando uma conexão do Airflow
profile_config_dev = ProfileConfig(
    profile_name="dw_bootcamp",
    target_name="dev",
    profile_mapping=PostgresUserPasswordProfileMapping(
        # conn_id: nome da conexão cadastrada no Airflow (Admin -> Connections)
        # Essa conexão deve apontar para o Postgres do Docker local
        conn_id="docker_postgres_db",
        # profile_args: argumentos extras do profile do dbt
        # Aqui estamos forçando o schema a ser "public"
        profile_args={"schema": "public"},
    ),
)


# ==========================
# 2) CONFIG DE PROFILE PROD
# ==========================
# Cria um ProfileConfig para o ambiente prod
# Aqui a diferença principal é a conexão do Airflow (conn_id)
# que deve apontar para o Postgres em ambiente remoto (ex: Railway)
profile_config_prod = ProfileConfig(
    profile_name="dw_bootcamp",
    target_name="prod",
    profile_mapping=PostgresUserPasswordProfileMapping(
        # Conexão do Airflow para o Postgres remoto (produção)
        conn_id="railway_postgres_db",
        # Mesmo schema para o dbt
        profile_args={"schema": "public"},
    ),
)


# ======================================
# 3) DEFINIR QUAL AMBIENTE VAI EXECUTAR
# ======================================
# Lê a variável "dbt_env" do Airflow
# - Se não existir, usa "dev" como padrão
# - lower() garante que não importa se o usuário digitou DEV/Dev/dev
dbt_env = Variable.get("dbt_env", default_var="dev").lower()

# Valida a variável para evitar valores errados (ex: "teste", "local", etc.)
# Se não for dev ou prod, dispara erro e o DAG não sobe corretamente
if dbt_env not in ("dev", "prod"):
    raise ValueError(f"dbt_env inválido: {dbt_env!r}, use 'dev' ou 'prod'")

# Escolhe qual profile_config será usado com base no ambiente
# - dev -> profile_config_dev
# - prod -> profile_config_prod
profile_config = profile_config_dev if dbt_env == "dev" else profile_config_prod


# ======================================
# 4) CRIAR O DAG DO DBT COM O COSMOS
# ======================================
# DbtDag cria automaticamente as tasks do dbt (run/test/etc) com base no projeto dbt
my_cosmos_dag = DbtDag(

    # -----------------------------
    # 4.1) Configuração do projeto
    # -----------------------------
    project_config=ProjectConfig(
        # Caminho onde o projeto dbt está dentro do container do Airflow
        # (ex: você copiou para /usr/local/airflow/dbt/dw_bootcamp)
        dbt_project_path="/usr/local/airflow/dbt/dw_bootcamp",
        # Nome do projeto dbt (mesmo do dbt_project.yml)
        project_name="dw_bootcamp",
    ),

    # -----------------------------
    # 4.2) Configuração do profile
    # -----------------------------
    # Aqui o Cosmos injeta as credenciais baseado na conexão do Airflow escolhida
    profile_config=profile_config,

    # --------------------------------
    # 4.3) Como executar o dbt no DAG
    # --------------------------------
    execution_config=ExecutionConfig(
        # Caminho do executável dbt dentro do container
        # Aqui você está usando um virtualenv (dbt_venv) criado no Dockerfile
        dbt_executable_path=f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt",
    ),

    # -----------------------------------------
    # 4.4) Argumentos adicionais do operador
    # -----------------------------------------
    operator_args={
        # install_deps=True faz o Cosmos rodar "dbt deps" antes da execução
        # Isso garante que pacotes do packages.yml (dbt_utils, dbt_expectations) sejam baixados
        "install_deps": True,

        # target: define qual target do dbt será usado (dev ou prod)
        # Está ligado ao profile_config selecionado
        "target": profile_config.target_name,
    },

    # -----------------------------
    # 4.5) Agendamento do DAG
    # -----------------------------
    # "@daily" significa que o DAG roda uma vez por dia
    schedule="@daily",

    # Data a partir da qual o Airflow considera o DAG válido para agendar execuções
    start_date=datetime(2025, 12, 15),

    # catchup=False impede que o Airflow tente executar dias passados automaticamente
    # (senão ele criaria execuções retroativas desde start_date até hoje)
    catchup=False,

    # ID do DAG no Airflow
    # Aqui você está colocando o ambiente no nome para ficar claro no painel
    dag_id=f"dag_dw_bootcamp_{dbt_env}",

    # Configuração padrão de tentativas em caso de falha
    default_args={"retries": 2},

    # Comentário livre seu
    #atualizando
)

```

---
Arrastar pasta do projeto dbt na pasta 2 para dbt na pasta 3 (apenas copiar)
---

Inicializar o Airflow:

```bash
cd 3_airflow
astro dev init


astro dev start
```

reiniciar caso necessario:
'''
cd 3_airflow
astro dev stop
astro dev start --no-cache
'''


---

### Dockerfile do Airflow

Adicionar:

```dockerfile
RUN python -m venv dbt_venv \
    && . dbt_venv/bin/activate \
    && pip install --no-cache-dir dbt-postgres==1.9.0 \
    && deactivate
```

---

### Docker Compose Override

```yml
services:
  scheduler:
    volumes:
      - ./dbt/dw_bootcamp:/usr/local/airflow/dbt/dw_bootcamp

  dag-processor:
    volumes:
      - ./dbt/dw_bootcamp:/usr/local/airflow/dbt/dw_bootcamp
```

---

### Documentação do dbt

```bash
cd ..\2_data_warehouse\dw_bootcamp
dbt docs generate --target dev
dbt docs serve --port 8085
```


---
3️⃣ Agora crie a conexão 

Airflow UI → Admin → Connections → Add

Agora você verá:

✅ Connection Type: Postgres

Preencha assim:

Connection Id: docker_postgres_db

Connection Type: Postgres

Host: host.docker.internal

Schema (Database): dbt_db

Login: postgres

Password: postgres

Port: 5433