# 🖱️ Configurador do Cursor IDE para Ubuntu

Este script automatiza a configuração do Cursor IDE no Ubuntu, resolvendo problemas comuns de sandbox e adicionando integração completa com o sistema operacional.

## 🚀 O que o script faz

✅ **Configura execução sem sandbox** - Resolve erros de inicialização  
✅ **Execução em background** - Terminal não fica preso aos logs  
✅ **Ícone no menu de aplicações** - Integração visual completa  
✅ **Suporte para dock** - Pode ser fixado na barra de tarefas  
✅ **Multi-shell** - Funciona com bash, zsh e fish  
✅ **Detecção automática** - Encontra o Cursor automaticamente  

## 📋 Pré-requisitos

- Ubuntu (ou distribuições baseadas em Ubuntu)
- Cursor IDE baixado (formato .AppImage)
- Usuário normal (não root)

## 🛠️ Como usar

### Opção 1: Detecção automática
```bash
./setup-cursor-ubuntu.sh
```

### Opção 2: Especificar caminho
```bash
./setup-cursor-ubuntu.sh /caminho/para/cursor.AppImage
```

## 📥 Instalação rápida

1. **Baixar o Cursor:**
   ```bash
   # Visite https://cursor.sh ou baixe diretamente:
   curl -L -o ~/Applications/cursor.AppImage "https://downloader.cursor.sh/linux/appImage/x64"
   chmod +x ~/Applications/cursor.AppImage
   ```

2. **Executar o configurador:**
   ```bash
   chmod +x setup-cursor-ubuntu.sh
   ./setup-cursor-ubuntu.sh
   ```

## 🎯 Locais onde o script procura o Cursor

- `~/Applications/cursor.AppImage` (recomendado)
- `~/Downloads/cursor.AppImage`
- `~/Desktop/cursor.AppImage`
- `~/.local/bin/cursor.AppImage`
- `/opt/cursor.AppImage`
- `/usr/local/bin/cursor.AppImage`

## ⚙️ O que é configurado

### 1. Alias de terminal
O script adiciona um alias no seu arquivo de configuração do shell:
```bash
alias cursor='nohup ~/Applications/cursor.AppImage --no-sandbox > /dev/null 2>&1 &'
```

### 2. Arquivo .desktop
Cria `~/.local/share/applications/cursor.desktop` com:
- Ícone personalizado
- Integração com tipos de arquivo
- Ações contextuais
- Categorias apropriadas

### 3. Ícone do sistema
Extrai e instala o ícone oficial em `~/.local/share/icons/cursor.png`

## 🐚 Shells suportados

- **Bash** (`~/.bashrc`)
- **Zsh** (`~/.zshrc`) 
- **Fish** (`~/.config/fish/config.fish`)

## ✨ Após a instalação

### Terminal
```bash
# Aplicar configurações imediatamente
source ~/.zshrc    # ou ~/.bashrc para bash

# Usar o Cursor
cursor
cursor /path/to/project
```

### Interface gráfica
- 📱 **Menu de aplicações**: Procure por "Cursor"
- 📌 **Dock**: Clique com botão direito → "Adicionar aos favoritos"
- 🖥️ **Área de trabalho**: Arrastar do menu de aplicações

## 🔧 Problemas conhecidos e soluções

### Erro de sandbox
```
The SUID sandbox helper binary was found, but is not configured correctly
```
**Solução:** O script já configura `--no-sandbox` automaticamente.

### Cursor não aparece no menu
```bash
# Atualizar cache manualmente
update-desktop-database ~/.local/share/applications/
```

### Alias não funciona
```bash
# Verificar se foi adicionado
grep cursor ~/.zshrc  # ou ~/.bashrc

# Aplicar configurações
source ~/.zshrc
```

## 🗑️ Desinstalação

Para reverter as configurações:

```bash
# Remover alias
sed -i '/alias cursor=/d' ~/.zshrc
sed -i '/## CURSOR/d' ~/.zshrc

# Remover arquivos do sistema
rm ~/.local/share/applications/cursor.desktop
rm ~/.local/share/icons/cursor.png

# Atualizar cache
update-desktop-database ~/.local/share/applications/
```

## 📊 Compatibilidade

- ✅ Ubuntu 20.04+
- ✅ Linux Mint
- ✅ Elementary OS
- ✅ Pop!_OS
- ⚠️ Outras distribuições (pode funcionar)

## 🤝 Contribuições

O script é modular e pode ser facilmente extendido. Principais funções:

- `find_cursor_appimage()` - Localiza o Cursor
- `setup_shell_alias()` - Configura alias por shell
- `extract_icon()` - Extrai ícone do AppImage
- `create_desktop_file()` - Cria integração desktop

## 📝 Log de mudanças

- **v1.0**: Versão inicial com suporte bash/zsh/fish
- Detecção automática de Cursor
- Extração de ícone do AppImage
- Configuração completa de .desktop
- Testes de validação

## 📞 Suporte

Se encontrar problemas:

1. Execute com debug: `bash -x setup-cursor-ubuntu.sh`
2. Verifique os logs de saída coloridos
3. Teste manualmente: `~/Applications/cursor.AppImage --no-sandbox --version`

---

**Feito com ❤️ para a comunidade Ubuntu + Cursor IDE**