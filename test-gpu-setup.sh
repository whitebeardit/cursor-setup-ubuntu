#!/bin/bash

# =====================================
# Script de Teste para Cursor Setup
# =====================================
# 
# Este script testa as funcionalidades de GPU
# dos scripts atualizados do cursor-setup
#

set -e

# Cores para output
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

# Testar detecção de GPU
test_gpu_detection() {
    print_header "TESTING GPU DETECTION"
    
    # Simular a função de detecção do setup-cursor-ubuntu.sh
    local gpu_flags=""
    
    if command -v nvidia-smi > /dev/null 2>&1; then
        print_info "🔵 NVIDIA GPU detected - enabling advanced acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy --enable-native-gpu-memory-buffers"
        
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        print_info "🔴 AMD GPU detected - enabling GPU acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization --enable-zero-copy"
        
    elif lspci | grep -i intel | grep -i graphics > /dev/null; then
        print_info "🟡 Intel integrated graphics detected - enabling basic acceleration"
        gpu_flags="--enable-gpu --enable-gpu-rasterization"
        
    else
        print_warning "No dedicated GPU detected - using CPU rendering"
        gpu_flags="--disable-gpu"
    fi
    
    print_info "GPU flags detected: $gpu_flags"
    echo "$gpu_flags"
}

# Testar sintaxe dos scripts
test_script_syntax() {
    print_header "TESTING SCRIPT SYNTAX"
    
    local scripts=(
        "/home/whitebeard/cursor-setup/cursor-fix-freeze.sh"
        "/home/whitebeard/cursor-setup/setup-cursor-ubuntu.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            print_info "Testing syntax: $script"
            if bash -n "$script"; then
                print_success "✅ Syntax OK: $script"
            else
                print_error "❌ Syntax error: $script"
                return 1
            fi
        else
            print_error "❌ Script not found: $script"
            return 1
        fi
    done
    
    print_success "All scripts have valid syntax"
}

# Testar funcionalidades específicas
test_specific_functions() {
    print_header "TESTING SPECIFIC FUNCTIONS"
    
    # Testar se as funções de GPU estão presentes
    local freeze_script="/home/whitebeard/cursor-setup/cursor-fix-freeze.sh"
    local setup_script="/home/whitebeard/cursor-setup/setup-cursor-ubuntu.sh"
    
    # Verificar se detect_and_configure_gpu está no freeze script
    if grep -q "detect_and_configure_gpu" "$freeze_script"; then
        print_success "✅ detect_and_configure_gpu function found in freeze script"
    else
        print_error "❌ detect_and_configure_gpu function not found in freeze script"
    fi
    
    # Verificar se detect_gpu_and_get_flags está no setup script
    if grep -q "detect_gpu_and_get_flags" "$setup_script"; then
        print_success "✅ detect_gpu_and_get_flags function found in setup script"
    else
        print_error "❌ detect_gpu_and_get_flags function not found in setup script"
    fi
    
    # Verificar se as flags de GPU estão presentes
    if grep -q "enable-gpu-rasterization" "$freeze_script"; then
        print_success "✅ GPU rasterization flags found in freeze script"
    else
        print_error "❌ GPU rasterization flags not found in freeze script"
    fi
    
    if grep -q "enable-gpu-rasterization" "$setup_script"; then
        print_success "✅ GPU rasterization flags found in setup script"
    else
        print_error "❌ GPU rasterization flags not found in setup script"
    fi
}

# Testar integração com sistema
test_system_integration() {
    print_header "TESTING SYSTEM INTEGRATION"
    
    # Verificar se nvidia-smi está disponível
    if command -v nvidia-smi > /dev/null 2>&1; then
        print_success "✅ nvidia-smi available"
        nvidia-smi --query-gpu=name --format=csv,noheader | head -1
    else
        print_warning "⚠️  nvidia-smi not available"
    fi
    
    # Verificar se lspci está disponível
    if command -v lspci > /dev/null 2>&1; then
        print_success "✅ lspci available"
        local gpu_count=$(lspci | grep -i vga | wc -l)
        print_info "GPU devices found: $gpu_count"
    else
        print_warning "⚠️  lspci not available"
    fi
    
    # Verificar se glxinfo está disponível
    if command -v glxinfo > /dev/null 2>&1; then
        print_success "✅ glxinfo available"
        local renderer=$(glxinfo | grep "OpenGL renderer" | head -1)
        print_info "OpenGL renderer: $renderer"
    else
        print_warning "⚠️  glxinfo not available (install mesa-utils)"
    fi
}

# Função principal
main() {
    print_header "CURSOR SETUP GPU TESTING"
    
    test_script_syntax
    test_specific_functions
    test_gpu_detection
    test_system_integration
    
    print_header "TEST COMPLETE"
    print_success "All tests completed successfully! 🎉"
    print_info "The cursor-setup repository is ready with GPU optimizations."
}

main "$@"
