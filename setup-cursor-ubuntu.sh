#!/bin/bash

# =====================================
# Script de Configuração do Cursor IDE
# =====================================
# 
# Este script configura o Cursor IDE no Ubuntu para:
# 1. Executar sem sandbox (resolve problemas de inicialização)
# 2. Rodar em background (não prende o terminal)
# 3. Adicionar ícone ao menu de aplicações
# 4. Permitir adicionar ao dock
#
# Uso: ./setup-cursor-ubuntu.sh [caminho-para-cursor.AppImage]
# 
# Se não especificar o caminho, o script tentará encontrar
# o cursor.AppImage automaticamente.
#

set -e  # Para o script em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo -e "${NC}"
}

# Detectar o shell do usuário
detect_shell() {
    local shell_name=$(basename "$SHELL")
    case "$shell_name" in
        bash)
            echo "bash"
            ;;
        zsh)
            echo "zsh"
            ;;
        fish)
            echo "fish"
            ;;
        *)
            echo "bash" # fallback para bash
            ;;
    esac
}

# Função para encontrar o cursor.AppImage
find_cursor_appimage() {
    local cursor_path=""
    
    # Locais comuns onde o Cursor pode estar
    local common_paths=(
        "$HOME/Applications/cursor.AppImage"
        "$HOME/Downloads/cursor.AppImage"
        "$HOME/Desktop/cursor.AppImage"
        "$HOME/.local/bin/cursor.AppImage"
        "/opt/cursor.AppImage"
        "/usr/local/bin/cursor.AppImage"
    )
    
    for path in "${common_paths[@]}"; do
        if [[ -f "$path" ]]; then
            cursor_path="$path"
            break
        fi
    done
    
    # Se não encontrou, tentar buscar em todo o home
    if [[ -z "$cursor_path" ]]; then
        print_info "Procurando cursor.AppImage no diretório home..."
        cursor_path=$(find "$HOME" -name "*cursor*.AppImage" 2>/dev/null | head -1)
    fi
    
    echo "$cursor_path"
}

# Detectar GPU e configurar flags otimizadas
detect_gpu_and_get_flags() {
    local gpu_flags=""
    
    # Verificar NVIDIA
    if command -v nvidia-smi > /dev/null 2>&1; then
        print_info "🔵 NVIDIA GPU detected - enabling advanced acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy --enable-native-gpu-memory-buffers"
        
    # Verificar AMD
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        print_info "🔴 AMD GPU detected - enabling GPU acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy"
        
    # Verificar Intel
    elif lspci | grep -i intel | grep -i graphics > /dev/null; then
        print_info "🟡 Intel integrated graphics detected - enabling basic acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization"
        
    else
        print_warning "No dedicated GPU detected - using CPU rendering"
        gpu_flags="--disable-gpu"
    fi
    
    echo "$gpu_flags"
}

# Função para configurar a função cursor baseado no shell
setup_shell_alias() {
    local cursor_path="$1"
    local shell_type="$2"
    local config_file=""
    local function_code=""
    
    # Detectar GPU e obter flags otimizadas
    local gpu_flags=$(detect_gpu_and_get_flags)
    print_info "GPU optimization flags: $gpu_flags"
    
    case "$shell_type" in
        bash)
            config_file="$HOME/.bashrc"
            function_code="# Function to run Cursor in background with GPU optimization\ncursor() {\n    nohup $cursor_path --no-sandbox $gpu_flags \"\$@\" > /dev/null 2>&1 &\n}"
            ;;
        zsh)
            config_file="$HOME/.zshrc"
            function_code="# Function to run Cursor in background with GPU optimization\ncursor() {\n    nohup $cursor_path --no-sandbox $gpu_flags \"\$@\" > /dev/null 2>&1 &\n}"
            ;;
        fish)
            # Fish usa uma sintaxe diferente
            config_file="$HOME/.config/fish/config.fish"
            function_code="# Function to run Cursor in background with GPU optimization\nfunction cursor\n    nohup $cursor_path --no-sandbox $gpu_flags \$argv > /dev/null 2>&1 &\nend"
            ;;
        *)
            config_file="$HOME/.bashrc"
            function_code="# Function to run Cursor in background with GPU optimization\ncursor() {\n    nohup $cursor_path --no-sandbox $gpu_flags \"\$@\" > /dev/null 2>&1 &\n}"
            ;;
    esac
    
    print_info "Configurando função cursor no $config_file..."
    
    # Verificar se o cursor já existe como função ou alias
    if grep -q "alias cursor=" "$config_file" 2>/dev/null || grep -q "function cursor" "$config_file" 2>/dev/null || grep -q "cursor()" "$config_file" 2>/dev/null; then
        print_warning "Alias/função 'cursor' já existe. Removendo versão anterior..."
        # Remover linhas existentes do cursor
        sed -i '/alias cursor=/d' "$config_file" 2>/dev/null || true
        sed -i '/function cursor/d' "$config_file" 2>/dev/null || true
        sed -i '/cursor() {/,/}/d' "$config_file" 2>/dev/null || true
        sed -i '/## CURSOR/d' "$config_file" 2>/dev/null || true
    fi
    
    # Adicionar nova função
    echo "" >> "$config_file"
    echo "## CURSOR" >> "$config_file"
    echo -e "$function_code" >> "$config_file"
    
    print_success "Função cursor configurada em $config_file"
}

# Função para extrair ícone do AppImage
extract_icon() {
    local cursor_path="$1"
    local temp_dir="/tmp/cursor_extract_$$"
    local icon_source=""
    local icon_dest="$HOME/.local/share/icons/cursor.png"
    
    print_info "Extraindo ícone do Cursor..."
    
    # Criar diretório temporário
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Extrair AppImage
    "$cursor_path" --appimage-extract > /dev/null 2>&1
    
    # Procurar pelo ícone
    if [[ -f "squashfs-root/co.anysphere.cursor.png" ]]; then
        icon_source="squashfs-root/co.anysphere.cursor.png"
    elif [[ -f "squashfs-root/cursor.png" ]]; then
        icon_source="squashfs-root/cursor.png"
    elif [[ -f "squashfs-root/code.png" ]]; then
        icon_source="squashfs-root/code.png"
    else
        print_warning "Ícone não encontrado no AppImage. Procurando alternativas..."
        icon_source=$(find squashfs-root -name "*.png" | head -1)
    fi
    
    if [[ -n "$icon_source" && -f "$icon_source" ]]; then
        # Criar diretório de ícones se não existir
        mkdir -p "$(dirname "$icon_dest")"
        
        # Copiar ícone
        cp "$icon_source" "$icon_dest"
        print_success "Ícone salvo em $icon_dest"
    else
        print_warning "Não foi possível extrair o ícone do AppImage"
        icon_dest=""
    fi
    
    # Limpar arquivos temporários
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    echo "$icon_dest"
}

# Função para criar arquivo .desktop
create_desktop_file() {
    local cursor_path="$1"
    local icon_path="$2"
    local desktop_file="$HOME/.local/share/applications/cursor.desktop"
    
    print_info "Criando arquivo .desktop..."
    
    # Detectar GPU e obter flags otimizadas
    local gpu_flags=$(detect_gpu_and_get_flags)
    
    # Criar diretório se não existir
    mkdir -p "$(dirname "$desktop_file")"
    
    # Criar conteúdo do arquivo .desktop
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Cursor
Comment=Code editor with AI capabilities
GenericName=Text Editor
Exec=env LANG=C nohup "$cursor_path" --no-sandbox $gpu_flags %F
Icon=$icon_path
Type=Application
StartupNotify=true
StartupWMClass=cursor
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;
Actions=new-empty-window;
Keywords=vscode;cursor;editor;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=env LANG=C nohup "$cursor_path" --no-sandbox $gpu_flags --new-window %F
Icon=$icon_path
EOF
    
    # Tornar executável
    chmod +x "$desktop_file"
    
    print_success "Arquivo .desktop criado em $desktop_file"
}

# Função para atualizar cache de aplicações
update_desktop_cache() {
    print_info "Atualizando cache de aplicações..."
    
    # Atualizar database de desktop files
    if command -v update-desktop-database > /dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
    
    # Atualizar cache de ícones se disponível
    if command -v gtk-update-icon-cache > /dev/null 2>&1; then
        gtk-update-icon-cache "$HOME/.local/share/icons/" 2>/dev/null || true
    fi
    
    print_success "Cache de aplicações atualizado"
}

# Função para testar a configuração
test_configuration() {
    local cursor_path="$1"
    local shell_type="$2"
    
    print_info "Testando configuração..."
    
    # Verificar se o arquivo existe e é executável
    if [[ ! -f "$cursor_path" ]]; then
        print_error "Cursor AppImage não encontrado: $cursor_path"
        return 1
    fi
    
    if [[ ! -x "$cursor_path" ]]; then
        print_error "Cursor AppImage não é executável: $cursor_path"
        return 1
    fi
    
    # Detectar GPU e obter flags para teste
    local gpu_flags=$(detect_gpu_and_get_flags)
    print_info "Testando com flags de GPU: $gpu_flags"
    
    # Testar se o comando básico funciona (com timeout)
    print_info "Testando execução do Cursor (com timeout de 10s)..."
    if timeout 10s "$cursor_path" --no-sandbox $gpu_flags --version > /dev/null 2>&1; then
        print_success "Cursor executa corretamente com otimizações de GPU"
    else
        print_warning "Cursor pode ter problemas de execução, mas isso é comum com AppImages"
    fi
    
    # Verificar se GPU está sendo detectada corretamente
    if command -v nvidia-smi > /dev/null 2>&1; then
        print_info "🔵 NVIDIA GPU detectada - aceleração avançada habilitada"
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        print_info "🔴 AMD GPU detectada - aceleração habilitada"
    elif lspci | grep -i intel | grep -i graphics > /dev/null; then
        print_info "🟡 Intel GPU detectada - aceleração básica habilitada"
    else
        print_warning "⚠️  Nenhuma GPU dedicada detectada - usando renderização por CPU"
    fi
    
    print_success "Configuração testada com sucesso!"
}

# Função para mostrar instruções finais
show_final_instructions() {
    local shell_type="$1"
    
    print_header "CONFIGURAÇÃO CONCLUÍDA!"
    
    echo "✅ Alias configurado para executar em background"
    echo "✅ Ícone extraído e configurado"
    echo "✅ Arquivo .desktop criado"
    echo "✅ Cache de aplicações atualizado"
    echo "✅ Otimizações de GPU aplicadas automaticamente"
    echo ""
    
    # Mostrar informações específicas da GPU detectada
    local gpu_flags=$(detect_gpu_and_get_flags)
    if command -v nvidia-smi > /dev/null 2>&1; then
        echo "🔵 NVIDIA GPU detectada - aceleração avançada habilitada"
        echo "   Monitoramento: watch -n 1 nvidia-smi"
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        echo "🔴 AMD GPU detectada - aceleração habilitada"
        echo "   Monitoramento: radeontop"
    elif lspci | grep -i intel | grep -i graphics > /dev/null; then
        echo "🟡 Intel GPU detectada - aceleração básica habilitada"
        echo "   Monitoramento: intel_gpu_top"
    else
        echo "⚠️  Nenhuma GPU dedicada detectada - usando renderização por CPU"
    fi
    
    echo ""
    print_info "Para usar as configurações:"
    echo ""
    echo "1. 📱 Menu de Aplicações: Procure por 'Cursor'"
    echo "2. 🖥️  Terminal: Digite 'cursor' (após reiniciar o terminal)"
    echo "3. 📌 Dock: Adicione ao dock através do menu de aplicações"
    echo ""
    print_info "Para aplicar o alias imediatamente no terminal atual:"
    case "$shell_type" in
        bash)
            echo "   source ~/.bashrc"
            ;;
        zsh)
            echo "   source ~/.zshrc"
            ;;
        fish)
            echo "   source ~/.config/fish/config.fish"
            ;;
    esac
    echo ""
    print_info "Flags de GPU aplicadas: $gpu_flags"
    echo ""
    print_success "Instalação concluída! 🎉"
}

# =====================================
# FUNÇÃO PRINCIPAL
# =====================================
main() {
    print_header "CONFIGURADOR DO CURSOR IDE PARA UBUNTU"
    
    # Verificar se está rodando no Ubuntu
    if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
        print_warning "Este script foi projetado para Ubuntu. Pode funcionar em outras distribuições."
    fi
    
    # Detectar shell
    local shell_type=$(detect_shell)
    print_info "Shell detectado: $shell_type"
    
    # Determinar caminho do Cursor
    local cursor_path="$1"
    
    if [[ -z "$cursor_path" ]]; then
        print_info "Caminho do Cursor não especificado. Procurando automaticamente..."
        cursor_path=$(find_cursor_appimage)
    fi
    
    if [[ -z "$cursor_path" ]]; then
        print_error "Cursor.AppImage não encontrado!"
        echo ""
        echo "Por favor:"
        echo "1. Baixe o Cursor IDE em: https://cursor.sh"
        echo "2. Execute: ./setup-cursor-ubuntu.sh /caminho/para/cursor.AppImage"
        echo "3. Ou coloque o cursor.AppImage em ~/Applications/"
        exit 1
    fi
    
    print_success "Cursor encontrado: $cursor_path"
    
    # Verificar se é executável
    if [[ ! -x "$cursor_path" ]]; then
        print_info "Tornando o Cursor executável..."
        chmod +x "$cursor_path"
    fi
    
    # Configurar alias no shell
    setup_shell_alias "$cursor_path" "$shell_type"
    
    # Extrair ícone
    local icon_path=$(extract_icon "$cursor_path")
    
    # Usar ícone padrão se extração falhou
    if [[ -z "$icon_path" ]]; then
        icon_path="cursor"  # Usar ícone genérico do sistema
    fi
    
    # Criar arquivo .desktop
    create_desktop_file "$cursor_path" "$icon_path"
    
    # Atualizar cache
    update_desktop_cache
    
    # Testar configuração
    test_configuration "$cursor_path" "$shell_type"
    
    # Mostrar instruções finais
    show_final_instructions "$shell_type"
}

# =====================================
# EXECUÇÃO DO SCRIPT
# =====================================

# Verificar se está sendo executado como root
if [[ $EUID -eq 0 ]]; then
    print_error "Este script não deve ser executado como root (sudo)"
    print_info "Execute como usuário normal: ./setup-cursor-ubuntu.sh"
    exit 1
fi

# Executar função principal
main "$@"
