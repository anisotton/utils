#!/bin/bash

log_info "Configurando Traefik..."

TRAEFIK_DIR="/opt/traefik"

if [ "$EUID" -eq 0 ]; then
    mkdir -p "$TRAEFIK_DIR"
else
    sudo mkdir -p "$TRAEFIK_DIR"
fi

log_info "Criando rede Docker 'proxy'..."
if ! docker network ls | grep -q proxy; then
    docker network create proxy
    log_info "Rede 'proxy' criada"
else
    log_info "Rede 'proxy' já existe"
fi

log_info "Criando $TRAEFIK_DIR/traefik.yml..."
if [ "$EUID" -eq 0 ]; then
    cat > "$TRAEFIK_DIR/traefik.yml" <<'EOF'
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    exposedByDefault: false
EOF
else
    sudo tee "$TRAEFIK_DIR/traefik.yml" > /dev/null <<'EOF'
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    exposedByDefault: false
EOF
fi

log_info "Criando $TRAEFIK_DIR/docker-compose.yml..."
if [ "$EUID" -eq 0 ]; then
    cat > "$TRAEFIK_DIR/docker-compose.yml" <<'EOF'
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF
else
    sudo tee "$TRAEFIK_DIR/docker-compose.yml" > /dev/null <<'EOF'
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF
fi

log_info "Subindo Traefik..."
if [ "$EUID" -eq 0 ]; then
    docker compose -f "$TRAEFIK_DIR/docker-compose.yml" up -d
else
    sudo docker compose -f "$TRAEFIK_DIR/docker-compose.yml" up -d
fi

log_info "Traefik configurado. Dashboard disponível em http://localhost:8080"
