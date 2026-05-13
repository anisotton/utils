#!/bin/bash

log_info "Verificando pacotes base do servidor..."
ensure_packages curl git btop vim net-tools unzip
