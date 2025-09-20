#!/bin/bash

# =====================================
# Cursor Freeze Fix Script for Linux
# =====================================
# 
# This script addresses the common "Cursor is not responding" issue
# by applying multiple known fixes for Electron-based apps on Linux
#
# Common causes and fixes:
# 1. Hardware acceleration issues (GPU conflicts)
# 2. Wayland compatibility problems
# 3. Memory/swap configuration
# 4. File system watchers limits
# 5. Electron cache corruption
# 6. Extension conflicts
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detectar ambiente gráfico
detect_display_server() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo "wayland"
    elif [[ -n "$DISPLAY" ]]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

# Verificar recursos do sistema
check_system_resources() {
    print_header "CHECKING SYSTEM RESOURCES"
    
    # Verificar RAM
    local total_ram=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    print_info "Total RAM: ${total_ram}GB"
    
    if [[ $total_ram -lt 4 ]]; then
        print_warning "Low RAM detected. Cursor may freeze with insufficient memory."
    fi
    
    # Verificar swap
    local swap=$(free -m | awk 'NR==3{printf "%.0f", $2}')
    print_info "Swap: ${swap}MB"
    
    if [[ $swap -eq 0 ]]; then
        print_warning "No swap configured. This can cause freezes under memory pressure."
        print_info "Consider adding swap: sudo fallocate -l 2G /swapfile"
    fi
    
    # Verificar file watchers
    local max_user_watches=$(cat /proc/sys/fs/inotify/max_user_watches)
    print_info "File watcher limit: $max_user_watches"
    
    if [[ $max_user_watches -lt 524288 ]]; then
        print_warning "Low file watcher limit. Large projects may cause freezes."
        print_info "Recommendation: Increase to 524288"
    fi
}

# Corrigir limites de file watchers
fix_file_watchers() {
    print_header "FIXING FILE WATCHERS"
    
    local current_limit=$(cat /proc/sys/fs/inotify/max_user_watches)
    local recommended_limit=524288
    
    if [[ $current_limit -lt $recommended_limit ]]; then
        print_info "Increasing file watcher limit from $current_limit to $recommended_limit..."
        
        # Temporário
        echo "fs.inotify.max_user_watches=$recommended_limit" | sudo tee -a /etc/sysctl.d/60-cursor-fix.conf
        sudo sysctl -p /etc/sysctl.d/60-cursor-fix.conf
        
        print_success "File watcher limit increased"
    else
        print_info "File watcher limit is already sufficient"
    fi
}

# Limpar cache do Cursor
clean_cursor_cache() {
    print_header "CLEANING CURSOR CACHE"
    
    local cursor_config="$HOME/.config/Cursor"
    local cursor_cache="$HOME/.cache/cursor"
    
    # Parar Cursor se estiver rodando
    if pgrep -f cursor > /dev/null; then
        print_info "Stopping running Cursor instances..."
        pkill -f cursor || true
        sleep 2
    fi
    
    # Backup e limpeza de cache
    if [[ -d "$cursor_config" ]]; then
        print_info "Backing up Cursor configuration..."
        cp -r "$cursor_config" "$cursor_config.backup.$(date +%Y%m%d_%H%M%S)" || true
        
        # Limpar apenas cache, preservar configurações
        find "$cursor_config" -name "*.log" -delete 2>/dev/null || true
        find "$cursor_config" -name "CachedData" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$cursor_config" -name "logs" -type d -exec rm -rf {} + 2>/dev/null || true
        
        print_success "Cursor cache cleaned"
    fi
    
    if [[ -d "$cursor_cache" ]]; then
        print_info "Cleaning system cursor cache..."
        rm -rf "$cursor_cache"
        print_success "System cursor cache cleaned"
    fi
}

# Criar script de inicialização otimizado
create_optimized_launcher() {
    print_header "CREATING OPTIMIZED LAUNCHER"
    
    local cursor_path=""
    local common_paths=(
        "$HOME/Applications/cursor.AppImage"
        "$HOME/Downloads/cursor.AppImage"
        "$HOME/Desktop/cursor.AppImage"
        "$HOME/.local/bin/cursor.AppImage"
    )
    
    for path in "${common_paths[@]}"; do
        if [[ -f "$path" ]]; then
            cursor_path="$path"
            break
        fi
    done
    
    if [[ -z "$cursor_path" ]]; then
        print_error "Cursor AppImage not found. Please specify path manually."
        return 1
    fi
    
    local display_server=$(detect_display_server)
    local launcher_script="$HOME/.local/bin/cursor-optimized"
    
    print_info "Creating optimized launcher at $launcher_script"
    
    mkdir -p "$(dirname "$launcher_script")"
    
    cat > "$launcher_script" << 'EOF'
#!/bin/bash

# Cursor Optimized Launcher
# Addresses common freeze issues on Linux

# Export environment variables for better compatibility
export ELECTRON_NO_SANDBOX=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=true
export ELECTRON_ENABLE_LOGGING=true

# GPU acceleration environment variables
export ELECTRON_ENABLE_GPU=1
export ELECTRON_DISABLE_GPU_SANDBOX=1
export ELECTRON_ENABLE_GPU_RASTERIZATION=1

# Memory management
export NODE_OPTIONS="--max-old-space-size=4096"

# Display server specific fixes
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    # Wayland fixes
    export ELECTRON_OZONE_PLATFORM_HINT=auto
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland,x11
    EXTRA_FLAGS="--ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations"
else
    # X11 fixes
    export GDK_BACKEND=x11
    EXTRA_FLAGS=""
fi

# GPU acceleration fixes (optimized for better GPU utilization)
GPU_FLAGS="--disable-gpu-sandbox --ignore-gpu-blacklist --enable-gpu --enable-gpu-rasterization --enable-zero-copy --enable-native-gpu-memory-buffers --enable-gpu-memory-buffer-compositor-resources --enable-gpu-memory-buffer-video-frames"

# Find Cursor executable
CURSOR_PATH=""
COMMON_PATHS=(
    "$HOME/Applications/cursor.AppImage"
    "$HOME/Downloads/cursor.AppImage" 
    "$HOME/Desktop/cursor.AppImage"
    "$HOME/.local/bin/cursor.AppImage"
)

for path in "${COMMON_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        CURSOR_PATH="$path"
        break
    fi
done

if [[ -z "$CURSOR_PATH" ]]; then
    echo "Error: Cursor AppImage not found"
    exit 1
fi

# Launch with optimized flags
exec "$CURSOR_PATH" \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-extensions-except \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-backgrounding-occluded-windows \
    --max_old_space_size=4096 \
    --enable-features=VaapiVideoDecoder,VaapiVideoEncoder \
    --enable-accelerated-video-decode \
    --enable-accelerated-mjpeg-decode \
    --enable-accelerated-video-encode \
    $GPU_FLAGS \
    $EXTRA_FLAGS \
    "$@"
EOF
    
    chmod +x "$launcher_script"
    print_success "Optimized launcher created at $launcher_script"
    
    # Atualizar função no shell
    update_shell_function "$launcher_script"
}

# Atualizar função do shell
update_shell_function() {
    local launcher_path="$1"
    local shell_name=$(basename "$SHELL")
    local config_file=""
    
    case "$shell_name" in
        bash) config_file="$HOME/.bashrc" ;;
        zsh) config_file="$HOME/.zshrc" ;;
        fish) config_file="$HOME/.config/fish/config.fish" ;;
        *) config_file="$HOME/.bashrc" ;;
    esac
    
    print_info "Updating shell function in $config_file..."
    
    # Remover função antiga
    sed -i '/## CURSOR/,/^}/d' "$config_file" 2>/dev/null || true
    
    # Adicionar nova função otimizada
    cat >> "$config_file" << EOF

## CURSOR - Optimized for freeze prevention
cursor() {
    $launcher_path "\$@" > /dev/null 2>&1 &
}
EOF
    
    print_success "Shell function updated with optimized launcher"
}

# Configurar limites do sistema
configure_system_limits() {
    print_header "CONFIGURING SYSTEM LIMITS"
    
    # Criar configuração de limites
    sudo tee /etc/security/limits.d/cursor.conf << EOF > /dev/null
# Cursor IDE limits to prevent freezes
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
EOF
    
    # Configurações sysctl para melhor performance
    sudo tee /etc/sysctl.d/60-cursor-performance.conf << EOF > /dev/null
# File system watchers
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=256
fs.inotify.max_queued_events=32768

# Memory management
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Network performance  
net.core.rmem_default=262144
net.core.rmem_max=16777216
net.core.wmem_default=262144
net.core.wmem_max=16777216
EOF
    
    # Aplicar configurações
    sudo sysctl -p /etc/sysctl.d/60-cursor-performance.conf
    
    print_success "System limits configured"
}

# Detectar e configurar GPU automaticamente
detect_and_configure_gpu() {
    print_header "DETECTING AND CONFIGURING GPU"
    
    local gpu_type=""
    local gpu_optimized_flags=""
    
    # Verificar NVIDIA
    if command -v nvidia-smi > /dev/null 2>&1; then
        print_info "🔵 NVIDIA GPU detected"
        local nvidia_info=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)
        print_info "GPU Info: $nvidia_info"
        gpu_type="nvidia"
        gpu_optimized_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy --enable-native-gpu-memory-buffers"
        
        # Verificar se está funcionando
        if nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | grep -q "[0-9]"; then
            print_success "NVIDIA GPU is active and functional"
        else
            print_warning "NVIDIA GPU detected but may not be in use"
        fi
        
    # Verificar AMD
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        print_info "🔴 AMD GPU detected"
        lspci | grep -i amd | grep -i vga
        gpu_type="amd"
        gpu_optimized_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy"
        
    # Verificar Intel
    elif lspci | grep -i intel | grep -i graphics > /dev/null; then
        print_info "🟡 Intel integrated graphics detected"
        lspci | grep -i intel | grep -i graphics
        gpu_type="intel"
        gpu_optimized_flags="--enable-gpu --enable-gpu-rasterization"
        
    else
        print_warning "No dedicated GPU detected, using CPU rendering"
        gpu_type="cpu"
        gpu_optimized_flags="--disable-gpu"
    fi
    
    # Testar aceleração de hardware
    if command -v glxinfo > /dev/null 2>&1; then
        local renderer=$(glxinfo | grep "OpenGL renderer" | head -1)
        print_info "OpenGL renderer: $renderer"
        
        if echo "$renderer" | grep -i "software\|llvmpipe" > /dev/null; then
            print_warning "Software rendering detected. Hardware acceleration may be disabled."
            print_info "Consider installing proper GPU drivers"
        else
            print_success "Hardware acceleration appears to be working"
        fi
    else
        print_warning "glxinfo not available. Install mesa-utils to check GPU acceleration"
    fi
    
    # Verificar VA-API para Intel/AMD
    if [[ "$gpu_type" == "intel" || "$gpu_type" == "amd" ]]; then
        if command -v vainfo > /dev/null 2>&1; then
            print_info "VA-API available for video acceleration"
        else
            print_warning "VA-API not available. Install: sudo apt install vainfo mesa-va-drivers"
        fi
    fi
    
    # Retornar configuração otimizada
    echo "$gpu_optimized_flags"
}

# Diagnosticar problemas de GPU (função legada mantida para compatibilidade)
diagnose_gpu_issues() {
    detect_and_configure_gpu
}

# Criar script de monitoramento
create_monitor_script() {
    print_header "CREATING MONITORING SCRIPT"
    
    local monitor_script="$HOME/.local/bin/cursor-monitor"
    
    cat > "$monitor_script" << 'EOF'
#!/bin/bash

# Cursor Monitor Script
# Monitors Cursor processes and system resources

while true; do
    echo "=== $(date) ==="
    
    # Check if Cursor is running
    if pgrep -f cursor > /dev/null; then
        echo "✅ Cursor is running"
        
        # Memory usage
        local mem_usage=$(ps aux | grep cursor | grep -v grep | awk '{sum += $4} END {print sum}')
        echo "📊 Memory usage: ${mem_usage}%"
        
        # CPU usage
        local cpu_usage=$(ps aux | grep cursor | grep -v grep | awk '{sum += $3} END {print sum}')
        echo "🔥 CPU usage: ${cpu_usage}%"
        
        # Check for zombie processes
        if ps aux | grep cursor | grep -q "<defunct>"; then
            echo "⚠️  Zombie cursor processes detected"
            pkill -9 -f cursor
            echo "🧹 Cleaned up zombie processes"
        fi
    else
        echo "❌ Cursor is not running"
    fi
    
    # System resources
    echo "💾 Free memory: $(free -m | awk 'NR==2{printf "%.1f%%\n", $7*100/$2 }')"
    echo "💿 Disk space: $(df -h / | awk 'NR==2{print $5}') used"
    
    echo "---"
    sleep 30
done
EOF
    
    chmod +x "$monitor_script"
    print_success "Monitoring script created at $monitor_script"
    print_info "Run: $monitor_script &  # to start monitoring"
}

# Menu principal
show_menu() {
    print_header "CURSOR FREEZE FIX MENU"
    echo "1. Quick Fix (Recommended)"
    echo "2. Full System Optimization" 
    echo "3. GPU Optimization Only"
    echo "4. Clean Cache Only"
    echo "5. Create Optimized Launcher"
    echo "6. System Diagnostics"
    echo "7. Create Monitor Script"
    echo "8. Emergency Reset"
    echo "9. Exit"
    echo
    read -p "Choose an option [1-9]: " choice
}

# Quick fix
quick_fix() {
    print_header "APPLYING QUICK FIXES"
    
    fix_file_watchers
    clean_cursor_cache
    create_optimized_launcher
    
    print_success "Quick fixes applied! Please restart your terminal and try Cursor."
}

# GPU optimization only
gpu_optimization() {
    print_header "GPU OPTIMIZATION ONLY"
    
    detect_and_configure_gpu
    create_optimized_launcher
    
    print_success "GPU optimization complete! Restart Cursor to apply changes."
    print_info "Monitor GPU usage with: watch -n 1 nvidia-smi"
}

# Full optimization
full_optimization() {
    print_header "FULL SYSTEM OPTIMIZATION"
    
    check_system_resources
    configure_system_limits
    fix_file_watchers
    clean_cursor_cache
    detect_and_configure_gpu
    create_optimized_launcher
    create_monitor_script
    
    print_success "Full optimization complete! Reboot recommended."
}

# Emergency reset
emergency_reset() {
    print_header "EMERGENCY RESET"
    
    print_warning "This will remove all Cursor configuration and cache!"
    read -p "Are you sure? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Stop all Cursor processes
        pkill -9 -f cursor 2>/dev/null || true
        
        # Remove all Cursor data
        rm -rf "$HOME/.config/Cursor"
        rm -rf "$HOME/.cache/cursor"
        rm -rf "$HOME/.cursor"
        
        # Remove our configurations
        sudo rm -f /etc/sysctl.d/60-cursor*.conf
        sudo rm -f /etc/security/limits.d/cursor.conf
        
        print_success "Emergency reset complete. Cursor will start fresh."
    else
        print_info "Reset cancelled."
    fi
}

# Main function
main() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Don't run this script as root!"
        exit 1
    fi
    
    while true; do
        show_menu
        case $choice in
            1) quick_fix ;;
            2) full_optimization ;;
            3) gpu_optimization ;;
            4) clean_cursor_cache ;;
            5) create_optimized_launcher ;;
            6) 
                check_system_resources
                detect_and_configure_gpu
                ;;
            7) create_monitor_script ;;
            8) emergency_reset ;;
            9) 
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-9."
                ;;
        esac
        echo
        read -p "Press Enter to continue..."
        echo
    done
}

main "$@"
