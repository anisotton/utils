#!/bin/bash

log_info "Checking PHP..."
if ! command -v php &> /dev/null; then
    log_warning "PHP not found. Installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl
    else
        sudo apt-get install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl
    fi
    log_info "PHP installed successfully"
else
    log_info "PHP already installed: $(php -v | head -n 1)"
fi

log_info "Validating PHP version for Valet (requires >= 5.6)..."
if php -r 'exit(version_compare(PHP_VERSION, "5.6", ">=") ? 0 : 1);'; then
    log_info "PHP version requirements satisfied"
else
    log_error "PHP version $(php -v | head -n1) is lower than 5.6. Please upgrade PHP before continuing."
    exit 1
fi

log_info "Ensuring required PHP extensions for Valet..."
ensure_packages php-cli php-curl php-mbstring php-xml php-zip php-sqlite3 php-mysql php-pgsql php-intl
if apt-cache show php-mcrypt >/dev/null 2>&1; then
    ensure_packages php-mcrypt
else
    log_warning "php-mcrypt package not available on this Ubuntu release. Valet no longer depends on it, continuing."
fi

log_info "Checking Composer..."
if ! command -v composer &> /dev/null; then
    log_warning "Composer not found. Installing..."
    cd /tmp
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    if [ "$EUID" -eq 0 ]; then
        mv composer.phar /usr/local/bin/composer
        chmod +x /usr/local/bin/composer
    else
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    fi
    rm -f composer-setup.php
    log_info "Composer installed successfully"
else
    COMPOSER_VERSION=$(timeout 5 composer --version --no-ansi 2>/dev/null | head -n 1 || echo "version check timed out")
    log_info "Composer already installed: $COMPOSER_VERSION"
fi

if ! grep -q '.config/composer/vendor/bin' "$REAL_HOME/.zshrc" 2>/dev/null; then
    run_as_user "echo 'export PATH=\"\$HOME/.config/composer/vendor/bin:\$PATH\"' >> '$REAL_HOME/.zshrc'"
fi
