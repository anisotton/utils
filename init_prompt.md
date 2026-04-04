Estou utilizando Ubuntu Linux e preciso finalizar meu setup de desenvolvimento.

Por favor, gere uma sequência de comandos que verifique se cada item abaixo já está instalado. Se não estiver, instale e configure (lidando com dependências).

**1. Navegador:**
*   **Google Chrome:** Verifique se está instalado. Se não, baixe o pacote `.deb` oficial mais recente e instale.

**2. Terminal e Shell (Zsh):**
*   **Zsh:** Verifique se o `zsh` está instalado. Se não, instale e defina como shell padrão.
*   **Oh My Zsh:** Instale apenas se a pasta `~/.oh-my-zsh` não existir.
*   **Tema Macovsky:** O tema "macovsky" é externo. Baixe o arquivo `macovsky.zsh-theme` (do repositório `iiio7/macovsky-zsh-theme` ou similar) e salve em `~/.oh-my-zsh/custom/themes/`.
*   **Configurar Tema:** Altere a variável `ZSH_THEME` no `~/.zshrc` para `ZSH_THEME="macovsky"`.
*   **Plugins Externos:** Clone os repositórios para `zsh-autosuggestions` e `zsh-syntax-highlighting` na pasta custom do Oh My Zsh.
*   **Configuração de Plugins:** Configure o `~/.zshrc` para usar a lista:
    `plugins=(git docker docker-compose npm composer sudo web-search z zsh-autosuggestions zsh-syntax-highlighting)`
*   **Alias Personalizados:** Adicione uma linha ao final do `~/.zshrc` para importar seus aliases, verificando antes se o arquivo existe:
    `[ -f ~/IsottonTecnologia/Comandos/alias_zsh.txt ] && source ~/IsottonTecnologia/Comandos/alias_zsh.txt`

**3. Gerenciadores e Linguagens:**
*   **NVM:** Verifique se o `nvm` carrega. Se não, instale e adicione ao `.zshrc`.
*   **PHP e Composer:** Verifique e instale as versões mais recentes.

**4. Docker:**
*   Verifique o `docker`. Se não existir, instale e adicione meu usuário ao grupo `docker`.

**5. Ferramentas de Desenvolvimento Local:**
*   **Valet Linux:** Verifique o comando `valet`. Se ausente, instale via Composer Global (`cpriego/valet-linux`) junto com dependências (`libnss3-tools`, `jq`, `xsel`) e execute `valet install`.
*   **Takeout:** Verifique o comando `takeout`. Se ausente, instale via Composer Global (`tightenco/takeout`).

**6. Serviços do Takeout:**
*   Garanta que o Docker esteja rodando e habilite: `mysql` (8.0), `redis`, `mailhog`, `meilisearch`, `minio`.

**7. Aplicativos GUI:**
*   **VS Code Insiders:** Instale a versão `code-insiders` via Snap (use a flag `--classic`).
*   **DBeaver:** Instale via Snap.
*   **ApiDog:** Baixe e instale o `.deb` oficial.
