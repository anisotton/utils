#!/bin/bash

log_info "=== Configurando LLM Local (Ollama) ==="

OLLAMA_DIR="$REAL_HOME/ollama"
TRAEFIK_DYNAMIC_DIR="/opt/traefik/dynamic"

# --- Seleção de modelo ---
echo ""
echo -e "${GREEN}=== Seleção de Modelo LLM ===${NC}"
echo "Escolha o modelo para instalar:"
echo ""
echo "  1) qwen2.5:7b-instruct-q4_K_M  (~4.4 GB)  — Recomendado, bom PT-BR, uso geral"
echo "  2) llama3.2:3b-instruct-q8_0    (~3.4 GB)  — Mais rápido, menor qualidade"
echo "  3) mistral:7b-instruct-q4_K_M   (~4.4 GB)  — Bom para inglês e código"
echo "  4) phi3.5:mini-instruct-q8_0    (~2.6 GB)  — Muito rápido, uso leve"
echo "  5) Digitar manualmente"
echo ""
echo "Escolha [1]:"
read -r MODEL_CHOICE

case "$MODEL_CHOICE" in
    2) LLM_MODEL="llama3.2:3b-instruct-q8_0" ;;
    3) LLM_MODEL="mistral:7b-instruct-q4_K_M" ;;
    4) LLM_MODEL="phi3.5:mini-instruct-q8_0" ;;
    5)
        echo "Digite o nome do modelo (ex: llama3.2, gemma2:9b):"
        read -r LLM_MODEL
        ;;
    *) LLM_MODEL="qwen2.5:7b-instruct-q4_K_M" ;;
esac

log_info "Modelo selecionado: $LLM_MODEL"

# --- Docker Compose ---
log_info "Criando diretório $OLLAMA_DIR..."
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$OLLAMA_DIR"
    chown "$REAL_USER:$REAL_USER" "$OLLAMA_DIR"
else
    mkdir -p "$OLLAMA_DIR"
fi

log_info "Criando $OLLAMA_DIR/docker-compose.yml..."
if [ "$EUID" -eq 0 ]; then
    cat > "$OLLAMA_DIR/docker-compose.yml" <<EOF
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - $REAL_HOME/.ollama:/root/.ollama
    environment:
      - OLLAMA_NUM_PARALLEL=1
      - OLLAMA_MAX_LOADED_MODELS=1
    ports:
      - "11434:11434"
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF
    chown "$REAL_USER:$REAL_USER" "$OLLAMA_DIR/docker-compose.yml"
else
    cat > "$OLLAMA_DIR/docker-compose.yml" <<EOF
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - $REAL_HOME/.ollama:/root/.ollama
    environment:
      - OLLAMA_NUM_PARALLEL=1
      - OLLAMA_MAX_LOADED_MODELS=1
    ports:
      - "11434:11434"
    networks:
      - proxy

networks:
  proxy:
    external: true
EOF
fi

# --- Traefik dynamic config ---
log_info "Criando config dinâmica do Traefik em $TRAEFIK_DYNAMIC_DIR/ollama.yml..."
if [ "$EUID" -eq 0 ]; then
    mkdir -p "$TRAEFIK_DYNAMIC_DIR"
    cat > "$TRAEFIK_DYNAMIC_DIR/ollama.yml" <<EOF
http:
  routers:
    ollama:
      rule: "Host(\`ollama.$SERVER_NAME\`)"
      service: ollama
      entryPoints:
        - web

  services:
    ollama:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:11434"
EOF
else
    sudo mkdir -p "$TRAEFIK_DYNAMIC_DIR"
    sudo tee "$TRAEFIK_DYNAMIC_DIR/ollama.yml" > /dev/null <<EOF
http:
  routers:
    ollama:
      rule: "Host(\`ollama.$SERVER_NAME\`)"
      service: ollama
      entryPoints:
        - web

  services:
    ollama:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:11434"
EOF
fi

# --- Subir container ---
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^ollama$'; then
    log_info "Container Ollama já está rodando."
else
    log_info "Subindo container Ollama..."
    run_as_user "docker compose -f '$OLLAMA_DIR/docker-compose.yml' up -d"
fi

# --- Aguardar Ollama ---
log_info "Aguardando Ollama inicializar..."
TIMEOUT=60
COUNT=0
until curl -sf http://localhost:11434 > /dev/null 2>&1; do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$TIMEOUT" ]; then
        log_error "Timeout aguardando Ollama. Verifique com: docker logs ollama"
        return 1 2>/dev/null || exit 1
    fi
    sleep 1
done
log_info "Ollama está respondendo."

# --- Pull do modelo ---
if docker exec ollama ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qF "$LLM_MODEL"; then
    log_info "Modelo $LLM_MODEL já está disponível — pulando download."
else
    log_info "Baixando modelo $LLM_MODEL (isso pode levar vários minutos)..."
    docker exec ollama ollama pull "$LLM_MODEL"
fi

# --- Verificação ---
log_info "Verificando modelo com inferência simples..."
INFERENCE_RESPONSE=$(docker exec ollama ollama run "$LLM_MODEL" "Responda em uma palavra: qual é a capital do Brasil?" 2>/dev/null || echo "(falha na inferência)")
log_info "Resposta do modelo: $INFERENCE_RESPONSE"

# --- Resumo ---
echo ""
echo -e "${GREEN}=========================================="
echo "  Ollama configurado com sucesso!"
echo "==========================================${NC}"
log_info "Modelo instalado: $LLM_MODEL"
log_info "URL de acesso:    http://ollama.$SERVER_NAME"
log_info "Endpoints da API:"
log_info "  POST http://ollama.$SERVER_NAME/api/chat"
log_info "  POST http://ollama.$SERVER_NAME/v1/chat/completions"
echo ""
log_info "Exemplo de uso:"
echo "  curl http://ollama.${SERVER_NAME}/api/chat \\"
echo "    -d '{\"model\":\"${LLM_MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\"Olá!\"}]}'"
