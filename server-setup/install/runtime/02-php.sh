#!/bin/bash

log_info "Verificando PHP 8.3..."
if ! command -v php &> /dev/null || ! php -r "exit(version_compare(PHP_VERSION, '8.3.0', '>=') ? 0 : 1);" 2>/dev/null; then
    log_warning "PHP 8.3 não encontrado. Instalando..."
    ensure_packages software-properties-common
    if [ "$EUID" -eq 0 ]; then
        add-apt-repository -y ppa:ondrej/php
        apt-get update
    else
        sudo add-apt-repository -y ppa:ondrej/php
        sudo apt-get update
    fi
    apt_install_packages php8.3-cli php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-sqlite3
    log_info "PHP instalado: $(php --version | head -1)"
else
    log_info "PHP já instalado: $(php --version | head -1)"
fi

log_info "Verificando Composer..."
if ! command -v composer &> /dev/null; then
    log_warning "Composer não encontrado. Instalando..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        log_error "Checksum do Composer inválido"
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    rm composer-setup.php
    if [ "$EUID" -eq 0 ]; then
        mv composer.phar /usr/local/bin/composer
    else
        sudo mv composer.phar /usr/local/bin/composer
    fi
    log_info "Composer instalado: $(composer --version 2>/dev/null | head -1)"
else
    log_info "Composer já instalado: $(composer --version 2>/dev/null | head -1)"
fi
