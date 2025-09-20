# 🔧 Cursor Freeze Troubleshooting Guide

This guide addresses the common "Cursor is not responding" issue on Linux systems.

## 🚨 Common Symptoms

- Cursor becomes unresponsive/frozen
- UI stops updating but process remains active
- High CPU/memory usage
- Application hangs during file operations
- Slow startup or project opening

## 🔍 Root Causes & Solutions

### 1. Hardware Acceleration Issues

**Problem**: GPU conflicts causing renderer freezes

**Solution**: Disable problematic GPU features
```bash
cursor --disable-gpu --disable-gpu-sandbox
```

**Permanent Fix**: Use the optimized launcher (automatic with our script)

### 2. File System Watcher Limits

**Problem**: Linux limits on file watching cause freezes with large projects

**Check current limit**:
```bash
cat /proc/sys/fs/inotify/max_user_watches
```

**Fix**: Increase limit to 524288
```bash
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 3. Wayland Compatibility

**Problem**: Wayland display server causes Electron app issues

**Detection**:
```bash
echo $XDG_SESSION_TYPE  # Should show 'wayland' or 'x11'
```

**Fix**: Use X11 compatibility mode
```bash
export GDK_BACKEND=x11
cursor
```

### 4. Memory Issues

**Problem**: Insufficient RAM or swap causing freezes

**Check resources**:
```bash
free -h  # Check RAM and swap
```

**Solutions**:
- Close other applications
- Increase swap file
- Use memory-optimized launch flags

### 5. Extension Conflicts

**Problem**: Problematic extensions causing crashes

**Fix**: Start in safe mode
```bash
cursor --disable-extensions
```

**Reset extensions**:
```bash
rm -rf ~/.config/Cursor/User/extensions
```

### 6. Cache Corruption

**Problem**: Corrupted cache files causing instability

**Clean cache** (preserves settings):
```bash
# Stop Cursor
pkill -f cursor

# Clean cache files
rm -rf ~/.config/Cursor/CachedData
rm -rf ~/.config/Cursor/logs  
rm -rf ~/.cache/cursor

# Restart Cursor
```

## 🛠️ Quick Fixes

### Emergency Commands

**Kill all Cursor processes**:
```bash
pkill -9 -f cursor
```

**Reset everything** (nuclear option):
```bash
rm -rf ~/.config/Cursor
# Will lose all settings and extensions
```

**Check system resources**:
```bash
# Memory usage by Cursor
ps aux | grep cursor | awk '{sum+=$4} END {print "Memory: " sum "%"}'

# CPU usage by Cursor  
ps aux | grep cursor | awk '{sum+=$3} END {print "CPU: " sum "%"}'
```

## 📊 System Requirements

### Minimum Recommended:
- **RAM**: 4GB (8GB+ recommended)
- **CPU**: Multi-core processor
- **Disk**: SSD preferred for better I/O
- **GPU**: Hardware acceleration support

### Linux-Specific:
- **Kernel**: 4.0+ with namespace support
- **File watchers**: 524288+ limit
- **Display**: X11 or Wayland with compatibility layer

## 🔧 Optimized Launch Configuration

Our script creates an optimized launcher with these flags:

```bash
cursor \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-extensions-except \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-backgrounding-occluded-windows \
    --max_old_space_size=4096
```

### Environment Variables:
```bash
export ELECTRON_NO_SANDBOX=1
export NODE_OPTIONS="--max-old-space-size=4096"
export ELECTRON_DISABLE_SECURITY_WARNINGS=true
```

## 🏥 Health Check Commands

**System diagnostics**:
```bash
# Check file watcher limits
cat /proc/sys/fs/inotify/max_user_watches

# Check available memory
free -m

# Check GPU info
lspci | grep -i vga
glxinfo | grep "OpenGL renderer"

# Check display server
echo $XDG_SESSION_TYPE

# Monitor Cursor processes
watch 'ps aux | grep cursor'
```

## 🚀 Performance Optimization

### System-level optimizations:

**1. File system performance**:
```bash
# Add to /etc/sysctl.conf
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=256
fs.inotify.max_queued_events=32768
```

**2. Memory management**:
```bash
# Add to /etc/sysctl.conf
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
```

**3. Process limits**:
```bash
# Add to /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
```

## 🐛 Debug Mode

**Enable verbose logging**:
```bash
export ELECTRON_ENABLE_LOGGING=true
cursor --verbose
```

**Check logs**:
```bash
tail -f ~/.config/Cursor/logs/main.log
```

## 📞 When All Else Fails

1. **Update Cursor**: Download latest version from https://cursor.sh
2. **Update system**: Ensure latest kernel and drivers
3. **Try different display server**: Switch between X11/Wayland
4. **Hardware test**: Run `memtest86` to check RAM
5. **Fresh install**: Complete removal and reinstall

## 🤝 Community Solutions

Common workarounds reported by users:

- **Large projects**: Use `.cursorrignore` file to exclude node_modules, .git
- **Docker projects**: Exclude container volumes from file watching
- **Network drives**: Avoid opening projects on network/cloud storage
- **Virtual machines**: Increase allocated RAM and enable 3D acceleration

---

**Need more help?** Run our diagnostic script: `./cursor-fix-freeze.sh`