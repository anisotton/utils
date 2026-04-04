#!/bin/bash

log_info "Checking base prerequisites..."
ensure_packages git curl wget unzip build-essential libssl-dev lsof
