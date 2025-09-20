# 🖱️ Cursor IDE Setup for Ubuntu

This script automates the configuration of Cursor IDE on Ubuntu, resolving common sandbox issues and adding complete system integration.

## 🚀 What the script does

✅ **Configures sandbox-free execution** - Resolves startup errors  
✅ **Background execution** - Terminal doesn't get stuck with logs  
✅ **Application menu icon** - Complete visual integration  
✅ **Dock support** - Can be pinned to taskbar  
✅ **Multi-shell support** - Works with bash, zsh, and fish  
✅ **Auto-detection** - Finds Cursor automatically  

## 📋 Prerequisites

- Ubuntu (or Ubuntu-based distributions)
- Cursor IDE downloaded (.AppImage format)
- Regular user (not root)

## 🛠️ How to use

### Option 1: Auto-detection
```bash
./setup-cursor-ubuntu.sh
```

### Option 2: Specify path
```bash
./setup-cursor-ubuntu.sh /path/to/cursor.AppImage
```

## 📥 Quick installation

1. **Download Cursor:**
   ```bash
   # Visit https://cursor.sh or download directly:
   curl -L -o ~/Applications/cursor.AppImage "https://downloader.cursor.sh/linux/appImage/x64"
   chmod +x ~/Applications/cursor.AppImage
   ```

2. **Run the setup:**
   ```bash
   chmod +x setup-cursor-ubuntu.sh
   ./setup-cursor-ubuntu.sh
   ```

## 🎯 Where the script looks for Cursor

- `~/Applications/cursor.AppImage` (recommended)
- `~/Downloads/cursor.AppImage`
- `~/Desktop/cursor.AppImage`
- `~/.local/bin/cursor.AppImage`
- `/opt/cursor.AppImage`
- `/usr/local/bin/cursor.AppImage`

## ⚙️ What gets configured

### 1. Terminal alias
The script adds an alias to your shell configuration file:
```bash
alias cursor='nohup ~/Applications/cursor.AppImage --no-sandbox > /dev/null 2>&1 &'
```

### 2. .desktop file
Creates `~/.local/share/applications/cursor.desktop` with:
- Custom icon
- File type integration
- Context actions
- Appropriate categories

### 3. System icon
Extracts and installs the official icon at `~/.local/share/icons/cursor.png`

## 🐚 Supported shells

- **Bash** (`~/.bashrc`)
- **Zsh** (`~/.zshrc`) 
- **Fish** (`~/.config/fish/config.fish`)

## ✨ After installation

### Terminal
```bash
# Apply settings immediately
source ~/.zshrc    # or ~/.bashrc for bash

# Use Cursor
cursor
cursor /path/to/project
```

### Graphical interface
- 📱 **Application menu**: Search for "Cursor"
- 📌 **Dock**: Right-click → "Add to favorites"
- 🖥️ **Desktop**: Drag from application menu

## 🔧 Known issues and solutions

### Sandbox error
```
The SUID sandbox helper binary was found, but is not configured correctly
```
**Solution:** The script automatically configures `--no-sandbox`.

### Cursor doesn't appear in menu
```bash
# Update cache manually
update-desktop-database ~/.local/share/applications/
```

### Alias doesn't work
```bash
# Check if it was added
grep cursor ~/.zshrc  # or ~/.bashrc

# Apply settings
source ~/.zshrc
```

## 🗑️ Uninstallation

To revert the configuration:

```bash
# Remove alias
sed -i '/alias cursor=/d' ~/.zshrc
sed -i '/## CURSOR/d' ~/.zshrc

# Remove system files
rm ~/.local/share/applications/cursor.desktop
rm ~/.local/share/icons/cursor.png

# Update cache
update-desktop-database ~/.local/share/applications/
```

## 📊 Compatibility

- ✅ Ubuntu 20.04+
- ✅ Linux Mint
- ✅ Elementary OS
- ✅ Pop!_OS
- ⚠️ Other distributions (may work)

## 🤝 Contributing

The script is modular and can be easily extended. Main functions:

- `find_cursor_appimage()` - Locates Cursor
- `setup_shell_alias()` - Configures shell aliases
- `extract_icon()` - Extracts icon from AppImage
- `create_desktop_file()` - Creates desktop integration

## 📝 Changelog

- **v1.0**: Initial version with bash/zsh/fish support
- Automatic Cursor detection
- AppImage icon extraction
- Complete .desktop configuration
- Validation tests

## 📞 Support

If you encounter issues:

1. Run with debug: `bash -x setup-cursor-ubuntu.sh`
2. Check the colored output logs
3. Test manually: `~/Applications/cursor.AppImage --no-sandbox --version`

---

**Made with ❤️ for the Ubuntu + Cursor IDE community**
