---
name: laravel-dusk
description: Escreve, configura e executa testes end-to-end com Laravel Dusk — automação de browser real (Chrome), simulação de fluxos de usuário, asserções de UI, ambiente isolado com SQLite e DuskSeed. Use quando precisar testar navegação, formulários, cliques ou comportamento visual da aplicação.
compatibility: opencode
---

## O que faço

- Escrever testes de navegação e interação com a interface do usuário
- Validar fluxos de usuário através do navegador real (Chrome)
- Simular cliques, preenchimento de formulários e navegação
- Fazer asserções sobre elementos visíveis na página
- Configurar ambientes isolados para testes Dusk

## Quando usar

Use quando você precisa testar o comportamento real de um usuário navegando na aplicação - cliques, formulários, navegação entre páginas, validações de UI. **Estes são testes específicos de browser, separados dos testes unitários e de feature**.

## Estrutura isolada de testes Dusk

Os testes Dusk são **completamente independentes** dos outros testes (Unit, Feature):

```
tests/
  ├── Browser/           # Testes Dusk (isolados)
  ├── Feature/           # NÃO incluir em Dusk
  ├── Unit/              # NÃO incluir em Dusk
  ├── Support/           # Classes auxiliares
  ├── DuskTestCase.php   # Classe base Dusk
  └── TestCase.php       # Base para Unit/Feature
```

## Configuração de ambiente separado

### Arquivo `.env.dusk.local` (exclusivo para Dusk)
```env
APP_ENV=local
APP_DEBUG=true
APP_URL=http://127.0.0.1:8000

# Dusk configuration
DUSK_HEADLESS_DISABLED=true  # false para modo headless/CI
DISPLAY=:1                    # Para ambientes com servidor X11

# Database configuration (use SQLite isolado)
DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

# Session e cache específicos para testes
SESSION_DRIVER=array
CACHE_STORE=array
```

### Arquivo `phpunit.dusk.xml` (configuração exclusiva)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit>
    <testsuites>
        <testsuite name="Browser Test Suite">
            <directory suffix="Test.php">./tests/Browser</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

**Nota:** Este arquivo só inclui testes do diretório `Browser/`. Os testes Feature e Unit têm seu próprio `phpunit.xml`.

## Configuração de banco de dados isolado com DuskSeed

Os testes Dusk usam um banco de dados SQLite **isolado** que deve ser preparado com um Seed específico chamado `DuskSeed`.

### Criar, caso não exista, o Seeder `DuskSeeder`

```bash
php artisan make:seeder DuskSeed
```


## Executando testes Dusk com preparação de banco

### 1. Preparar banco de dados isolado com `DuskSeed`

```bash
# Recrear banco SQLite e executar DuskSeed
php artisan migrate:fresh --seed --seeder=DuskSeed --env=dusk
```

### 2. Executar testes Dusk

```bash
# Executar testes (banco já preparado)
php artisan dusk --env=dusk

```

### Fluxo completo (recomendado)

```bash
#!/bin/bash

# 1. Preparar banco de dados SQLite isolado
php artisan migrate:fresh --env=dusk

# 2. Executar DuskSeed para popular dados de teste
php artisan db:seed --seeder=DuskSeed --env=dusk

# 3. Levantar servidor Laravel em background
php artisan serve --env=dusk &
SERVER_PID=$!

# 4. Aguardar servidor ficar disponível
sleep 5
until curl -f http://127.0.0.1:8000 > /dev/null 2>&1; do
    echo "Aguardando servidor Dusk iniciar..."
    sleep 2
done

echo "✓ Servidor Dusk iniciado com sucesso"

# 5. Executar testes Dusk
php artisan dusk --env=dusk

# 6. Parar o servidor
kill $SERVER_PID

```

### Scripts Dusk no `composer.json`

```json
"scripts": {
    "dusk:prepare": [
        "@php artisan migrate:fresh --env=dusk",
        "@php artisan db:seed --seeder=DuskSeed --env=dusk"
    ],
    "test:dusk": [
        "@dusk:prepare",
        "php -r \"echo 'Iniciando servidor Dusk...\\n'; $server = proc_open('php artisan serve --env=dusk', [1 => STDOUT, 2 => STDERR], $pipes); sleep(5); passthru('@php artisan dusk --env=dusk'); proc_terminate($server);\""
    ],
    "test:dusk-headless": [
        "@dusk:prepare",
        "php -r \"echo 'Iniciando servidor Dusk (headless)...\\n'; putenv('DUSK_HEADLESS_DISABLED=false'); $server = proc_open('php artisan serve --env=dusk', [1 => STDOUT, 2 => STDERR], $pipes); sleep(5); passthru('@php artisan dusk --env=dusk'); proc_terminate($server);\""
    ]
}
```

**Importante:** O `DuskSeeder` é **exclusivo** para testes Dusk e não afeta nenhum outro ambiente de desenvolvimento.

## Configuração base (DuskTestCase)

A classe `DuskTestCase` deve:
- Estender apenas `Laravel\Dusk\TestCase`
- Configurar Chrome com opções adequadas (`--headless=new`, `--no-sandbox`, etc)
- Definir timeouts (connection/request: 60000ms)
- Implementar método `prepare()` com `#[BeforeClass]` para inicializar ChromeDriver
- Aguardar disponibilidade do ChromeDriver na porta 9515


## Scripts no composer.json

```json
"scripts": {
    "test:dusk": [
        "@php artisan dusk"
    ],
    "test:dusk-headless": [
        "DUSK_HEADLESS_DISABLED=false @php artisan dusk"
    ]
}
```

## Boas práticas

- **Isolamento:** Use `.env.dusk.local` e `phpunit.dusk.xml` exclusivos
- **Independência:** Execute `php artisan dusk --env=dusk`
- **Grupos:** Use `#[Group('')]` para identificar testes 
- **ChromeDriver:** Configure com `--no-sandbox` e `--disable-dev-shm-usage` para Docker
- **Headless:** Defina `DUSK_HEADLESS_DISABLED=false` apenas em CI/CD
- **Banco de dados:** Use SQLite `:memory:`, se possivel, para rapidez (se compatível com seu setup)
- **Aguardas:** Sempre use `waitFor*()` antes de fazer asserções
- **Limpeza:** Implemente `afterClass()` para fechar conexões e drivers
