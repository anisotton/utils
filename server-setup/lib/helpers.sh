#!/bin/bash

# Reutiliza os helpers do ubuntu-setup com o caminho correto
UBUNTU_SETUP_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../ubuntu-setup" && pwd)"
source "$UBUNTU_SETUP_PATH/lib/helpers.sh"
