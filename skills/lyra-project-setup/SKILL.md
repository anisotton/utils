---
name: lyra-project-setup
description: Use when creating or reading a codebase project in the Isotton Corp infrastructure. Creates the Paperclip project object (ou atualiza um já existente), a estrutura de pastas em /srv/projects/{slug}/, Dockerfile, docker-compose.yml, conf/ do webdevops/php-nginx, Traefik dynamic config e project.yml. Pergunta os dados obrigatórios antes de executar.
compatibility: Detecta o contexto na Etapa 0 — roda DENTRO do Lyra (execução local, sem SSH) ou remoto via `ssh anisotton@lyra`. Requer PAPERCLIP_API_KEY env var ou sessão Paperclip, Docker no Lyra, rede Docker externa `proxy` já criada (Traefik)
metadata:
  author: isotton-corp
  version: "2.1"
---

# Lyra Project Setup

## Objetivo

Criar (ou completar) a estrutura de um projeto de código da Isotton Corp no servidor Lyra, no padrão vigente — cruzado entre `trimasy` e `brilhart` (ISO-1261), que **não são byte-idênticos** (versão do PHP e `conf/30-laravel-setup.sh` divergem por motivos legítimos, ver Etapas 5 e 7) mas seguem a mesma forma estrutural. **Use `/srv/projects/trimasy` como ponto de partida quando este documento e o disco divergirem, mas confira também `/srv/projects/brilhart` antes de assumir que uma divergência é regressão** — pode ser uma correção mais nova que ainda não voltou para o outro projeto.

1. **Objeto de projeto no Paperclip** — criar (`POST`) ou completar um projeto já existente (`PATCH`)
2. **Pasta no servidor Lyra** — `/srv/projects/{slug}/` (alias `/home/anisotton/projects/{slug}/` — mesmo caminho, `/home/anisotton/projects` é symlink para `/srv/projects`)
3. **Repositório clonado** — `{slug}/app/` com o código do GitHub
4. **Workspace primário no Paperclip** — registrado **depois** que `app/` existe (ver armadilha abaixo)
5. **Arquivos de config** — `Dockerfile`, `docker-compose.yml`, `docker-compose.override.yml`, `conf/{10-php.conf,30-laravel-setup.sh,queue-worker.conf}`, `.env`/`.env.example`, `Makefile`, `project.yml`
6. **Rota Traefik** — `/opt/traefik/dynamic/{slug}.yml`, roteando para o container via rede externa `proxy` (sem bind de porta no host)

Todo o tráfego chega pelo Traefik já rodando no Lyra, escutando na rede Docker externa `proxy`. **Nenhum serviço faz bind de porta no host** — nem app, nem db, nem redis. `app_port` no `project.yml` é a porta **interna** do container (`80`), não uma porta do host.

---

## Etapa 0: Detectar contexto de execução (RODAR ANTES DE TUDO)

Sem mudanças — esta etapa está correta e funciona. Roda **dentro do próprio Lyra** (agentes no servidor) ou **de uma máquina remota** (workstation); detecta onde estamos e define `lyra_exec`, usada por todas as etapas seguintes. Rodar **uma vez** no início, na mesma sessão de shell:

```bash
HN="$(hostname 2>/dev/null)"
if [ "${HN%%.*}" = "lyra" ]; then
  LYRA_MODE="local"
  echo "[lyra-setup] Rodando DENTRO do Lyra -> execução local (sem SSH)."
elif ssh -o BatchMode=yes -o ConnectTimeout=5 anisotton@lyra true 2>/dev/null; then
  LYRA_MODE="ssh"
  echo "[lyra-setup] Rodando remoto -> execução via 'ssh anisotton@lyra'."
else
  LYRA_MODE="none"
  echo "[lyra-setup] ERRO: não consegui conectar no Lyra (não estou nele e 'ssh anisotton@lyra' falhou)." >&2
fi

lyra_exec() {
  case "$LYRA_MODE" in
    local) bash -c "$1" ;;
    ssh)   ssh anisotton@lyra "$1" ;;
    *)     echo "[lyra-setup] ERRO: não consegui conectar no Lyra. Rode a Etapa 0 primeiro." >&2; return 1 ;;
  esac
}
```

**Se `LYRA_MODE=none`: PARAR aqui.** Avisar o usuário com a mensagem `"Não consegui conectar no Lyra (nem localmente, nem via ssh anisotton@lyra)."` e não seguir para as próximas etapas.

---

## ⚠️ Armadilha de workspace (leia antes da Etapa 2)

Rodar o provisionamento **de dentro de uma issue que já vive no projeto-alvo** falha com `workspace_validation_failed` — o runtime tenta validar o workspace primário do projeto no checkout, e esse workspace aponta para `{slug}/app/`, que **ainda não existe** no disco. Foi o que matou a [ISO-1260](/ISO/issues/ISO-1260): o projeto 06 — Brilhart já tinha sido criado no Paperclip (por outra via) com workspace primário apontando para a pasta, e a issue de provisionamento foi aberta dentro desse mesmo projeto.

**Regra:** a issue que executa esta skill deve viver **fora** do projeto-alvo (num projeto de onboarding/infra, ou sem projeto vinculado). Só depois que a Etapa 4 (clone) tiver criado `{slug}/app/` no disco é seguro abrir/rodar issues **dentro** do projeto-alvo — nesse ponto o workspace primário passa a validar normalmente.

Se o projeto-alvo já existe e já tem um workspace primário configurado (caminho "projeto já existe", Etapa 2), **confira isso antes de tudo**: `GET /api/projects/{id}/workspaces`. Se o `cwd` retornado ainda não existe no disco, trate como o cenário acima — não execute nada a partir de dentro desse projeto até a Etapa 4 (clone) terminar.

---

## Etapa 1: Coletar informações

Perguntar ao usuário os dados abaixo antes de criar qualquer coisa. Se o usuário já forneceu algum campo, não perguntar novamente.

| Campo | Obrigatório | Padrão | Exemplo |
|---|---|---|---|
| `slug` | Sim | — | `smasy` |
| `display_name` | Sim | — | `SMASY - Sistema de Gestão Acadêmica` |
| `description` | Sim | — | `Sistema de gestão para escolas e academias` |
| `github_repo` | Sim | — | `anisotton/smasy` (org `anisotton`, não `IsottonCorp` — ver nota abaixo) |
| `paperclip_project_id` | Não | — | preencher **só** se o projeto já existe no Paperclip — muda a Etapa 2 de `POST` para `PATCH` |
| `stack` | Não | `laravel` | `laravel`, `node`, `python` |
| `database` | Não | `mysql` | `mysql`, `postgres`, `sqlite`, `none` |
| `default_branch` | Não | detectar do repo (`git remote show`) ou perguntar | `main`, `master` |
| `git.base_branch` | Não | mesmo valor de `default_branch` | `release/v0.0.0-alpha` (trimasy usa uma branch de integração própria — não assumir `main`) |
| `url` | Não | `{slug}.lyra` | `smasy.lyra` |

Notas:
- **`app_port` não é mais um input do usuário.** Todo projeto Laravel/PHP no Lyra usa `app_port: 80` (porta interna do container) — não há bind de porta no host, o Traefik chega pelo container via rede `proxy`. Não perguntar "próxima porta livre".
- **Org do GitHub:** ruling do CTO em ISO-425 — todos os repos ficam em `anisotton/{slug}` (reuso de chave SSH e consistência com smasy/spomsy/trimasy), não em `IsottonCorp/`. Migração para uma org própria é iniciativa separada; não presumir `IsottonCorp` como default.
- Apresentar resumo completo dos valores e pedir confirmação antes de prosseguir.

---

## Etapa 2: Criar ou atualizar projeto no Paperclip

### Caminho A — projeto novo (sem `paperclip_project_id`)

```bash
PAPERCLIP_API_BASE="${PAPERCLIP_API_URL%/}"; PAPERCLIP_API_BASE="${PAPERCLIP_API_BASE%/api}"
COMPANY_ID="${PAPERCLIP_COMPANY_ID:-c282c1b4-cc48-404d-a349-b89e776b79b8}"

CODE=$(curl -sS -o /tmp/lyra-setup-project.json -w "%{http_code}" -X POST \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$DISPLAY_NAME\", \"description\": \"$DESCRIPTION\", \"env\": {
        \"STACK\": {\"type\": \"plain\", \"value\": \"$STACK\"},
        \"APP_URL\": {\"type\": \"plain\", \"value\": \"https://$URL\"},
        \"DATABASE\": {\"type\": \"plain\", \"value\": \"$DATABASE\"},
        \"GITHUB_REPO\": {\"type\": \"plain\", \"value\": \"https://github.com/$GITHUB_REPO\"}
      }}" \
  "${PAPERCLIP_API_BASE}/api/companies/${COMPANY_ID}/projects")

echo "HTTP=$CODE"
[ "$CODE" = "201" ] || { echo "ERRO ao criar projeto (HTTP $CODE):"; cat /tmp/lyra-setup-project.json; return 1; }
PAPERCLIP_PROJECT_ID=$(python3 -c "import json;print(json.load(open('/tmp/lyra-setup-project.json'))['id'])")
```

**Não passe `workspace` neste `POST`.** Se o objeto de projeto nascer com um workspace primário apontando para `$BASE/app` antes de esse caminho existir no disco, você reproduz a armadilha do topo deste documento. O workspace é registrado só na Etapa 6, depois do clone.

### Caminho B — projeto já existe (`paperclip_project_id` fornecido)

Este é o caminho que faltava na v1.0 e gerou risco de projeto duplicado na ISO-1261. **Nunca faça `POST` se já existe um `PAPERCLIP_PROJECT_ID`** — sempre `PATCH`:

```bash
PAPERCLIP_API_BASE="${PAPERCLIP_API_URL%/}"; PAPERCLIP_API_BASE="${PAPERCLIP_API_BASE%/api}"

CODE=$(curl -sS -o /tmp/lyra-setup-project.json -w "%{http_code}" -X PATCH \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"env\": {
        \"STACK\": {\"type\": \"plain\", \"value\": \"$STACK\"},
        \"APP_URL\": {\"type\": \"plain\", \"value\": \"https://$URL\"},
        \"DATABASE\": {\"type\": \"plain\", \"value\": \"$DATABASE\"},
        \"GITHUB_REPO\": {\"type\": \"plain\", \"value\": \"https://github.com/$GITHUB_REPO\"}
      }}" \
  "${PAPERCLIP_API_BASE}/api/projects/${PAPERCLIP_PROJECT_ID}")

echo "HTTP=$CODE"
[ "$CODE" = "200" ] || { echo "ERRO ao atualizar projeto (HTTP $CODE):"; cat /tmp/lyra-setup-project.json; return 1; }
```

Antes de seguir, confira se o projeto já tem workspace (ver armadilha no topo):

```bash
curl -sS -o /tmp/lyra-setup-workspaces.json -w "%{http_code}" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  "${PAPERCLIP_API_BASE}/api/projects/${PAPERCLIP_PROJECT_ID}/workspaces"
```

Se já existe um workspace primário com `cwd` que ainda não existe no disco, pule direto para a Etapa 3 sem tentar rodar mais nada *dentro* deste projeto — só volte a interagir com issues dele depois que a Etapa 4 (clone) terminar.

Toda chamada à API do Paperclip segue o padrão `curl -sS -o <arquivo> -w "%{http_code}"` com checagem explícita do código — nunca `curl -s` sozinho (POLICY §6). `000`/`5xx` é erro explícito.

---

## Etapa 3: Criar estrutura de pastas no Lyra

```bash
BASE="/srv/projects/$SLUG"

lyra_exec "
  mkdir -p $BASE/data/storage
  mkdir -p $BASE/data/logs
  mkdir -p $BASE/conf
"
if [ "$DATABASE" != "none" ] && [ "$DATABASE" != "sqlite" ]; then
  lyra_exec "mkdir -p $BASE/data/$( [ $DATABASE = mysql ] && echo mysql || echo postgres )"
fi
if [ "$DATABASE" != "none" ]; then
  lyra_exec "mkdir -p $BASE/data/redis"
fi
```

Note que **não há mais `$BASE/app` pré-criado à parte** — ele nasce do `git clone` na Etapa 4 (senão o clone falha por a pasta já existir e não estar vazia, dependendo da versão do git).

---

## Etapa 4: Clonar repositório GitHub

```bash
lyra_exec "
  git clone git@github.com:$GITHUB_REPO.git $BASE/app 2>/dev/null \
    || echo 'Repo nao existe ainda — app/ criado vazio (mkdir -p $BASE/app)'
"
```

A partir daqui `$BASE/app` existe no disco — é seguro registrar o workspace (Etapa 6) e, dali em diante, abrir issues dentro do projeto-alvo.

---

## Etapa 5: Criar `conf/` (obrigatório — não existia na v1.0)

Três arquivos, montados pelo `docker-compose.yml` na imagem `webdevops/php-nginx`. `10-php.conf` e `queue-worker.conf` são idênticos em todos os projetos Lyra — copiar literalmente de `/srv/projects/trimasy/conf/` ou gerar com o conteúdo abaixo. `30-laravel-setup.sh` **não é** — o `trimasy` (Sep/24, mais recente) e o `brilhart` (Sep/23) têm scripts diferentes porque cada um carrega a correção de um incidente distinto; o template abaixo funde os dois em vez de escolher um.

**`conf/10-php.conf`** — diz ao PHP que está atrás de HTTPS (Traefik termina o TLS):

```bash
lyra_exec "cat > $BASE/conf/10-php.conf << 'PHPCONF'
location ~ \.php\$ {
    fastcgi_split_path_info ^(.+\.php)(/.+)\$;
    fastcgi_pass php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME     \$request_filename;
    fastcgi_param HTTPS               on;
    fastcgi_read_timeout 600;
}
PHPCONF"
```

**`conf/queue-worker.conf`** — supervisor do worker de fila:

```bash
lyra_exec "cat > $BASE/conf/queue-worker.conf << 'QUEUECONF'
[program:laravel-queue-worker]
command=php /app/artisan queue:work redis --queue=default --sleep=3 --tries=3 --backoff=30 --max-time=3600
directory=/app
user=application
autostart=true
autorestart=true
numprocs=1
process_name=%(program_name)s_%(process_num)02d
startsecs=5
stopwaitsecs=3600
stdout_logfile=/app/storage/logs/queue-worker.log
stdout_logfile_maxbytes=10MB
redirect_stderr=true
QUEUECONF"
```

**`conf/30-laravel-setup.sh`** — corrige ownership de `storage/`/`bootstrap/cache`, garante que o nginx consiga ler o docroot montado do host, e roda migrations a cada start do container (roda como root, hook `entrypoint.d` do webdevops, antes do PHP-FPM subir):

```bash
lyra_exec "cat > $BASE/conf/30-laravel-setup.sh << 'SETUPSH'
#!/usr/bin/env bash
# Fix storage/cache ownership to match the PHP-FPM pool user and run pending migrations
# on every container start. Runs as root (webdevops entrypoint.d hook) before PHP-FPM starts.
#
# Ownership must match the FPM pool user's uid exactly, not just be group-writable: Blade's
# compiled-view cache calls touch(\$path, \$mtime) with an explicit mtime, and utime() only
# succeeds for the file's owner (or root) — group/other write access is not enough. A view
# compiled by \`docker exec\` running as root (the default) silently poisons the cache for the
# pool user, which then 500s (\"Utime failed: Operation not permitted\") on the next request
# that needs to recompile it. See ISO-1335/ISO-1336.

set -e

POOL_CONF=\"\$(grep -l '^\[www\]' /usr/local/etc/php-fpm.d/*.conf 2>/dev/null | head -n1)\"
if [ -n \"\${POOL_CONF:-}\" ]; then
  APP_USER=\"\$(grep -E '^user[[:space:]]*=' \"\$POOL_CONF\" | head -n1 | cut -d= -f2 | tr -d '[:space:]')\"
  APP_GROUP=\"\$(grep -E '^group[[:space:]]*=' \"\$POOL_CONF\" | head -n1 | cut -d= -f2 | tr -d '[:space:]')\"
fi

APP_USER=\"\${APP_USER:-\${APPLICATION_USER:-application}}\"
APP_GROUP=\"\${APP_GROUP:-\${APPLICATION_GROUP:-\$APP_USER}}\"

mkdir -p /app/storage/logs /app/storage/framework/{cache,sessions,views} /app/bootstrap/cache
chown -R \"\${APP_USER}:\${APP_GROUP}\" /app/storage /app/bootstrap/cache
chmod -R ug+rwX /app/storage /app/bootstrap/cache

# Let nginx (its own uid/gid inside the container, no relation to the host-mounted
# /app owner) read the docroot. Whether this is needed depends on the host directory's
# permission bits at the time \$BASE was created (umask-dependent — brilhart needed it,
# trimasy didn't, same skill, same mount pattern). Running it unconditionally is harmless
# when \"other\" already has read access, and closes the gap when it doesn't: chmod o+rX
# alone doesn't stick because the host directory's default ACL denies new files (Vite
# builds, git checkouts) \"other\" access; adding nginx to the mount's owning group does,
# because it rides the group bits the ACL already grants.
HOST_GID=\"\$(stat -c %g /app)\"
HOST_GROUP=\"\$(getent group \"\$HOST_GID\" 2>/dev/null | cut -d: -f1)\" || true
if [ -z \"\${HOST_GROUP:-}\" ]; then
  HOST_GROUP=\"hostdevs\"
  addgroup -g \"\$HOST_GID\" \"\$HOST_GROUP\"
fi
addgroup nginx \"\$HOST_GROUP\"

echo \"[laravel-setup] Running migrations...\"
gosu \"\${APP_USER}\" php /app/artisan migrate --force --no-interaction
echo \"[laravel-setup] Done.\"
SETUPSH
chmod +x $BASE/conf/30-laravel-setup.sh"
```

`stack=node` não usa este template (não há PHP-FPM nem `artisan`); adaptar ou omitir `conf/` conforme a stack.

---

## Etapa 6: Registrar workspace primário no Paperclip

**Só rodar depois da Etapa 4** — `$BASE/app` precisa existir no disco, senão você reproduz a armadilha do topo deste documento.

```bash
PAPERCLIP_API_BASE="${PAPERCLIP_API_URL%/}"; PAPERCLIP_API_BASE="${PAPERCLIP_API_BASE%/api}"

CODE=$(curl -sS -o /tmp/lyra-setup-workspace.json -w "%{http_code}" -X POST \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"app\", \"sourceType\": \"git_repo\", \"cwd\": \"$BASE/app\",
       \"repoUrl\": \"https://github.com/$GITHUB_REPO\", \"defaultRef\": \"$DEFAULT_BRANCH\",
       \"isPrimary\": true}" \
  "${PAPERCLIP_API_BASE}/api/projects/${PAPERCLIP_PROJECT_ID}/workspaces")

echo "HTTP=$CODE"
[ "$CODE" = "201" ] || { echo "ERRO ao registrar workspace (HTTP $CODE):"; cat /tmp/lyra-setup-workspace.json; return 1; }
```

Se o Caminho B (Etapa 2) já encontrou um workspace primário existente com `cwd` correto, **pule esta etapa** — já está registrado.

---

## Etapa 7: Criar Dockerfile

Na **raiz do projeto** (não em `app/`), `context: .`. **A tag `webdevops/php-nginx` não é uma constante fixa da skill — segue o `require.php` do `composer.json` clonado na Etapa 4.** Os 5 projetos vivos no Lyra provam isso: `trimasy` pede `^8.5` e usa `8.5-alpine`; `brilhart` e `spomsy` pedem `^8.4` e usam `8.4-alpine`; `smasy` pede `^8.3`. Rodar sempre depois do clone:

```bash
PHP_CONSTRAINT="$(lyra_exec "grep -m1 '\"php\"' $BASE/app/composer.json" | grep -oE '8\.[0-9]+')"
PHP_TAG="${PHP_CONSTRAINT:-8.4}-alpine"

lyra_exec "cat > $BASE/Dockerfile << DOCKERFILE
FROM webdevops/php-nginx:$PHP_TAG

# Browser stack for Laravel Dusk end-to-end tests.
# DuskTestCase.php expects /usr/bin/chromedriver (provided by chromium-chromedriver).
RUN apk add --no-cache chromium chromium-chromedriver
DOCKERFILE"
```

Se o `composer.json` ainda não tiver `require.php` (repo `app/` vazio, primeiro provisionamento antes do código chegar), perguntar a versão ao usuário em vez de assumir — não fixar `8.4` ou `8.5` "porque foi o que apareceu na maioria dos projetos".

Se o projeto não usa Dusk (`stack=node`, ou Laravel sem testes de browser), omitir o `RUN apk add` e usar a imagem base direto — mas isso é excepcional; todos os projetos Laravel do Lyra hoje incluem Dusk.

---

## Etapa 8: Criar docker-compose.yml

Template base (adaptar por `stack` e `database`) — **sem bind de porta no host em nenhum serviço**:

```bash
lyra_exec "cat > $BASE/docker-compose.yml << COMPOSE
services:
  $SLUG-app:
    build:
      context: .
      dockerfile: Dockerfile
    image: $SLUG-app:local
    container_name: $SLUG-app
    restart: unless-stopped
    working_dir: /app
    volumes:
      - ./app:/app
      - ./data/storage:/app/storage
      - ./data/logs:/app/logs
      - ./conf/10-php.conf:/opt/docker/etc/nginx/vhost.common.d/10-php.conf:ro
      - ./conf/30-laravel-setup.sh:/opt/docker/provision/entrypoint.d/30-laravel-setup.sh:ro
      - ./conf/queue-worker.conf:/opt/docker/etc/supervisor.d/queue-worker.conf:ro
    environment:
      WEB_DOCUMENT_ROOT: /app/public
      PHP_DISMOD: mailparse,xdebug
    depends_on:
      - $SLUG-db
      - $SLUG-redis
    networks:
      # Resolve $SLUG.lyra to this container over the private network so the Dusk
      # Chrome node reaches the app directly (https/self-signed, cert errors ignored).
      # A Docker DNS alias tracks the container IP across restarts (ISO-240: hardcoded
      # extra_hosts pins silently break when the proxy network reassigns IPs).
      $SLUG-internal:
        aliases:
          - $SLUG.lyra
      proxy:

  $SLUG-db:
    image: mysql:8.4
    container_name: $SLUG-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: \${DB_DATABASE:-$SLUG}
      MYSQL_USER: \${DB_USERNAME:-$SLUG}
      MYSQL_PASSWORD: \${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
    volumes:
      - ./data/mysql:/var/lib/mysql
    networks:
      - $SLUG-internal

  $SLUG-redis:
    image: redis:8-alpine
    container_name: $SLUG-redis
    restart: unless-stopped
    volumes:
      - ./data/redis:/data
    networks:
      - $SLUG-internal

  $SLUG-chrome:
    profiles: [\"qa\"]
    image: selenium/standalone-chromium:4
    container_name: $SLUG-chrome
    restart: unless-stopped
    shm_size: 2gb
    environment:
      SE_NODE_MAX_SESSIONS: 4
    networks:
      - $SLUG-internal
      - proxy

networks:
  $SLUG-internal:
    name: $SLUG-internal
  proxy:
    external: true
COMPOSE"
```

**Adaptações obrigatórias:**
- `database=postgres` → sem precedente validado no Lyra ainda (todos os projetos atuais usam `mysql:8.4`); se precisar, seguir o padrão do serviço `db` mas revisar com o Sentinel antes de assumir `postgres:16-alpine`.
- `database=sqlite` → remover serviço `$SLUG-db`, ajustar `depends_on`.
- `database=none` → remover serviços `$SLUG-db` e `$SLUG-redis`, remover `depends_on`.
- `stack=node` → ajustar `working_dir`/volumes de `/app` conforme o projeto, e o `Dockerfile` da Etapa 7 não usa `webdevops/php-nginx`.
- Se o projeto não roda Dusk, o serviço `$SLUG-chrome` pode ser omitido (mas hoje nenhum projeto Laravel do Lyra omite).
- A rede `proxy` já existe no host (criada pelo Traefik) — **não criar de novo**, só referenciar como `external: true`.

---

## Etapa 9: Criar docker-compose.override.yml

**Não existia na v1.0 e não estava nesta reescrita até a revisão do Sentinel apontar a ausência.** Limites de memória + rotação de log, aplicados em todos os 5 projetos vivos do Lyra desde 26/jul/2026 (via `lyra-hardening-20260726.sh`, script de hardening fora do escopo desta skill) — sem ele, um projeto novo sobe sem os limites que todo projeto real hoje tem, e um container com leak de memória pode derrubar o host.

```bash
lyra_exec "cat > $BASE/docker-compose.override.yml << OVERRIDE
# Limites de memória + rotação de log (padrão de 26/jul/2026, replicado do trimasy)
# Aplicados ao vivo via docker update; este arquivo efetiva na próxima recriação (docker compose up -d)
services:
  $SLUG-app:
    mem_limit: 1g
    memswap_limit: 2g
    logging:
      driver: json-file
      options:
        max-size: \"20m\"
        max-file: \"3\"
  $SLUG-db:
    mem_limit: 1g
    memswap_limit: 2g
    logging:
      driver: json-file
      options:
        max-size: \"20m\"
        max-file: \"3\"
  $SLUG-redis:
    mem_limit: 256m
    memswap_limit: 512m
    logging:
      driver: json-file
      options:
        max-size: \"20m\"
        max-file: \"3\"
  $SLUG-chrome:
    mem_limit: 2g
    memswap_limit: 3g
    logging:
      driver: json-file
      options:
        max-size: \"20m\"
        max-file: \"3\"
OVERRIDE"
```

Remover o bloco do serviço correspondente para cada serviço que a Etapa 8 tiver omitido (`$SLUG-db` se `database=none`, `$SLUG-redis` se `database=none`, `$SLUG-chrome` se o projeto não roda Dusk — é exatamente o caso do `isotton`, o único dos 5 sem bloco `-chrome` no override).

---

## Etapa 10: Criar `.env` e `.env.example`

```bash
lyra_exec "cat > $BASE/.env.example << ENV
APP_NAME=$DISPLAY_NAME
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=https://$URL
ASSET_URL=https://$URL

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=$DATABASE
DB_HOST=$SLUG-db
DB_PORT=3306
DB_DATABASE=${SLUG//-/_}
DB_USERNAME=${SLUG//-/_}
DB_PASSWORD=changeme
DB_ROOT_PASSWORD=changeme

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=$SLUG-redis
REDIS_PORT=6379
ENV"

lyra_exec "cp $BASE/.env.example $BASE/.env"
```

Gerar `APP_KEY` e trocar as senhas (`DB_PASSWORD`, `DB_ROOT_PASSWORD`) antes de subir em produção — `.env.example` fica com placeholders, `.env` **não é versionado**.

---

## Etapa 11: Criar Makefile

**Não existe target `deploy` no padrão atual** — a v1.0 tinha um `deploy` com `git pull origin main` fixo, mas nenhum dos 5 projetos vivos no Lyra usa isso hoje (deploy/atualização de código é feito por fora, projeto a projeto). O Makefile real é minimalista:

```bash
lyra_exec "cat > $BASE/Makefile << 'MAKE'
.PHONY: up down logs shell artisan migrate fresh seed composer

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f SLUG_PLACEHOLDER-app

shell:
	docker compose exec SLUG_PLACEHOLDER-app bash

artisan:
	docker compose exec SLUG_PLACEHOLDER-app php artisan \$(filter-out \$@,\$(MAKECMDGOALS))

migrate:
	docker compose exec SLUG_PLACEHOLDER-app php artisan migrate

fresh:
	docker compose exec SLUG_PLACEHOLDER-app php artisan migrate:fresh --seed

seed:
	docker compose exec SLUG_PLACEHOLDER-app php artisan db:seed

composer:
	docker compose exec SLUG_PLACEHOLDER-app composer \$(filter-out \$@,\$(MAKECMDGOALS))

%:
	@:
MAKE
sed -i \"s/SLUG_PLACEHOLDER/\$SLUG/g\" $BASE/Makefile"
```

Para `stack=node`, substituir os targets `artisan`/`migrate`/`fresh`/`seed`/`composer` pelos equivalentes Node.js do projeto.

---

## Etapa 12: Criar project.yml

```bash
lyra_exec "cat > $BASE/project.yml << YAML
git:
  base_branch: $GIT_BASE_BRANCH
slug: $SLUG
display_name: \"$DISPLAY_NAME\"
description: \"$DESCRIPTION\"
github: \"$GITHUB_REPO\"
url: \"https://$URL\"
stack: $STACK
database: $DATABASE
# Padrão Lyra: Traefik roteia para o container ($SLUG-app:80) via rede \`proxy\`.
# Não há bind de porta no host. app_port = porta interna do container.
app_port: 80
server:
  host: lyra
  folder: $BASE
traefik_config: /opt/traefik/dynamic/$SLUG.yml
# Contrato lido pelo workflow de QA do Sentinel (batch por projeto).
qa:
  app_dir: app
  container: $SLUG-app
  phpunit:
    enabled: true
    command: \"php artisan test --log-junit storage/logs/qa-junit.xml\"
    report: storage/logs/qa-junit.xml
  dusk:
    enabled: true
    command: \"php artisan dusk --log-junit storage/logs/qa-dusk-junit.xml\"
    report: storage/logs/qa-dusk-junit.xml
paperclip:
  company_id: c282c1b4-cc48-404d-a349-b89e776b79b8
  project_id: \"$PAPERCLIP_PROJECT_ID\"
created_at: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
YAML"
```

- `git.base_branch`: **não assumir `main`.** Se o `project.yml` já existir (projeto lido, não criado) e tiver esse campo, respeitar o valor gravado — cada repo pode ter sua própria branch de integração (trimasy usa `release/v0.0.0-alpha`, não `main`). Se for projeto novo e o campo não foi informado na Etapa 1, perguntar ao Oráculo — não adivinhar.
- Se `stack=node` ou `database` não usa PHPUnit/Dusk, ajustar ou remover o bloco `qa:` de acordo — ele é lido pelo workflow de QA do Sentinel, então precisa refletir o que realmente roda no projeto.
- `company_id` é **sempre** `c282c1b4-cc48-404d-a349-b89e776b79b8`. O valor `64cd2bec-...` da v1.0 está obsoleto — não usar em nenhuma referência nova.

---

## Etapa 13: Criar config do Traefik

Sem `entryPoints: web` e sem bind de porta — só `websecure` + `tls: {}`, backend apontando para o container pelo nome (rede `proxy`), não para `127.0.0.1`:

```bash
lyra_exec "sudo tee /opt/traefik/dynamic/$SLUG.yml << TRAEFIK
http:
  routers:
    $SLUG:
      rule: \"Host(\\\`$URL\\\`)\"
      entryPoints:
        - websecure
      service: $SLUG
      tls: {}
  services:
    $SLUG:
      loadBalancer:
        servers:
          - url: \"http://$SLUG-app:80\"
TRAEFIK"
```

O Traefik recarrega automaticamente (`watch: true`). O container `$SLUG-app` só é resolvível pelo Traefik porque está na rede externa `proxy` (Etapa 8) — sem isso o roteador sobe mas todo request cai em 502.

---

## Etapa 14: Subir containers e verificar

```bash
lyra_exec "cd $BASE && docker compose up -d"
lyra_exec "cd $BASE && docker compose ps"
lyra_exec "curl -sS -o /dev/null -w '%{http_code}\n' -k https://$SLUG.lyra/ || true"
```

Reportar ao usuário:

```
=== Projeto {slug} criado com sucesso ===

Paperclip project ID : {paperclip_project_id}
URL                  : https://{url}
Pasta no Lyra        : /srv/projects/{slug}/
GitHub               : github.com/{github_repo}
Stack                : {stack} | DB: {database}

Arquivos criados:
  [OK] project.yml
  [OK] Dockerfile
  [OK] docker-compose.yml
  [OK] docker-compose.override.yml
  [OK] conf/{10-php.conf,30-laravel-setup.sh,queue-worker.conf}
  [OK] .env / .env.example
  [OK] Makefile
  [OK] /opt/traefik/dynamic/{slug}.yml
  [OK] workspace primário registrado no Paperclip (app/)
  [OK] data/{database?}/, data/redis/, data/storage/, data/logs/

Próximos passos:
  ssh anisotton@lyra
  cd /srv/projects/{slug}
  nano .env   # ajustar APP_KEY e senhas (.env não é versionado)
  make up
```

---

## Referências de infraestrutura

| Recurso | Valor |
|---|---|
| Servidor | `lyra` (SSH: `anisotton@lyra`) |
| Projetos | `/srv/projects/` (alias `/home/anisotton/projects/`, symlink) |
| Traefik configs | `/opt/traefik/dynamic/` |
| Rede Docker externa | `proxy` (criada pelo Traefik; toda app se conecta nela, sem bind de porta no host) |
| DNS | `*.lyra` → `100.112.103.123` (Tailscale, via dnsmasq) |
| Paperclip API | usar `$PAPERCLIP_API_URL` (fallback `http://dashboard.lyra:3100`) |
| Company ID Paperclip | `c282c1b4-cc48-404d-a349-b89e776b79b8` — **não** `64cd2bec-...` (obsoleto) |
| PAPERCLIP_API_KEY | disponível via env em heartbeats; para uso local, gerar via dashboard |
| Org GitHub | `anisotton` (ruling ISO-425) — não `IsottonCorp` |
| Imagem base app | `webdevops/php-nginx:8.5-alpine` (+ `chromium`/`chromium-chromedriver` para Dusk) |
| Imagens DB/cache | `mysql:8.4`, `redis:8-alpine` |
| Chrome/Dusk | serviço `{slug}-chrome`, `selenium/standalone-chromium:4`, profile `qa` |

## Lendo um projeto existente

Para ler um projeto já existente (sem criar), ler:

```bash
lyra_exec "cat /srv/projects/{slug}/project.yml"
```

O `project.yml` é a fonte de verdade de todos os metadados do projeto — inclusive `git.base_branch` e o bloco `qa:`, que **não existiam na v1.0** e não devem ser inventados; se ausentes num projeto legado, perguntar antes de assumir um valor.

## Referência canônica e validação cruzada

Este documento foi escrito a partir de `/srv/projects/trimasy` e conferido contra `/srv/projects/brilhart` (ISO-1261) arquivo por arquivo — não presuma paridade sem checar; a checagem para esta v2.0 encontrou três divergências reais entre os dois, todas incorporadas ao documento em vez de silenciadas:

- **Versão do PHP no Dockerfile**: `trimasy` usa `8.5-alpine`, `brilhart`/`spomsy` usam `8.4-alpine`, `smasy` pede `8.3`. Não é drift — é o `require.php` de cada `composer.json` (Etapa 7). Uma skill que fixasse um valor único estaria sempre errada para algum projeto.
- **`conf/30-laravel-setup.sh`**: o `trimasy` (mais recente) tem a correção de ownership do ISO-1335/1336; o `brilhart` tem uma correção de leitura do docroot pelo nginx que o `trimasy` não tem. A Etapa 5 funde as duas em vez de copiar só uma — do contrário, o próximo projeto herdaria a lacuna de qualquer um dos dois lados.
- **`docker-compose.override.yml`**: ausente da v1.0 e da primeira versão desta reescrita; presente e idêntico nos 5 projetos vivos (Etapa 9).

Mesmo `Makefile` e mesmo layout de `docker-compose.yml`/`conf/` (troque só o slug) continuam valendo como paridade real, confirmada nos dois projetos. Encontrar uma nova divergência sem explicação registrada no `project.yml` ou numa issue é sinal de que este `SKILL.md` ficou defasado de novo — reabra uma issue como a ISO-1262, e verifique no disco antes de descrever qualquer coisa como "idêntica".
