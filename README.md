# macOS System Optimization & Ricing Scripts

Two powerful bash scripts for macOS: **OptimacOS** for comprehensive system optimization and troubleshooting, and **RicemacOS** for aesthetic customization and minimal setup.

---

## 📦 Scripts Overview

### 1. OptimacOS (`optimacos.sh`)
A comprehensive system optimization and repair script with 39 different operations to fix common macOS issues, improve performance, and manage system resources.

### 2. RicemacOS (`ricemacos.sh`)
A minimal aesthetic configuration script that transforms your macOS into a clean, optimized, and visually appealing setup with modern CLI tools.

---

## 🚀 OptimacOS Features

This script provides 39 different system optimization and repair operations:

### Core System Fixes
- **Finder Issues**: Restart Finder, clear preferences, and fix unresponsive behavior
- **App Launch Problems**: Reset Launch Services database and clear quarantine attributes
- **System Performance**: Clear caches, purge memory, and run maintenance scripts
- **Storage Management**: Free up startup disk space and identify large files
- **System Optimization**: Advanced kernel parameter optimization for better performance
- **Memory Optimization**: Enhanced memory management and pressure control
- **SSD Optimization**: Special settings for solid-state drives including TRIM
- **Security Settings**: Firewall configuration and stealth mode activation

### Performance Optimization
- **Animation Disabling**: Remove all UI animations for faster system responsiveness
- **Visual Effects Reduction**: Minimize transparency and effects for better performance
- **Memory Management**: Purge inactive memory and optimize system resources
- **Kernel Parameter Tuning**: Optimize connection limits, file descriptors, and process thresholds

### Advanced Diagnostics
- **Crash Detection**: Analyze system logs for application crashes
- **Disk Health**: Verify startup disk integrity and repair permissions
- **Network Issues**: Fix Wi-Fi connectivity problems and flush DNS cache
- **Battery Optimization**: Diagnose and optimize battery performance

### User Management
- **Bulk User Creation**: Create multiple users with customizable settings
- **User Preferences**: Configure user defaults and skip setup assistants
- **Spotlight Control**: Enable/disable Spotlight indexing for specific users
- **Security Options**: Optional sudo access and password management

## 📋 Requirements

- macOS (tested on macOS 10.15+ and later)
- Administrator privileges (script will prompt for sudo access)
- Terminal application

## 🔧 Installation

### OptimacOS Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/TheCreateGM/optimize-macos/refs/heads/main/optimacos.sh
   ```

2. Make it executable:
   ```bash
   chmod +x optimacos.sh
   ```

### RicemacOS Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/TheCreateGM/optimize-macos/refs/heads/main/ricemacos.sh
   ```

2. Make it executable:
   ```bash
   chmod +x ricemacos.sh
   ```

## 🏃 Usage

### OptimacOS Usage

Run the script from Terminal with various execution modes:

```bash
./optimacos.sh [options]
```

### Command Line Options
- `--all`: Run all optimizations without prompting
- `--verbose`: Show detailed command output
- `--quiet`: Minimize output messages
- `--yes`: Default to 'yes' for all prompts
- `--help`, `-h`: Show help message

### Execution Modes
The script offers three execution modes:
1. **Run All Functions**: Automatically run all optimization functions
2. **Run Selected Categories**: Choose which categories of optimizations to run
3. **Run Individual Functions**: Select specific functions to execute

### Interactive Mode
The script runs in interactive mode by default, asking for confirmation before each operation. You can:
- Choose which fixes to apply by answering `y` (yes) or `n` (no)
- Press Enter to default to "no" for any operation (or "yes" if using `--yes`)
- Exit at any time with `Ctrl+C`

### Before Running
⚠️ **Important**: Close all applications before running the script for best results.

## 📊 What Each Section Does

| Section | Operation | Purpose |
|---------|-----------|---------|
| 1 | Restart Finder | Fixes unresponsive Finder |
| 2 | Clear Finder Preferences | Resets Finder to default settings |
| 3 | Clear Caches | Removes user and system cache files |
| 4 | Reset Launch Services | Fixes app launch issues and duplicates |
| 5 | Clear App Saved States | Prevents apps from restoring corrupted states |
| 6 | Reset Font Cache | Fixes font-related crashes |
| 7 | Repair Disk Permissions | Fixes permission-related launch issues |
| 8 | Clear Quarantine Attributes | Fixes "app can't be opened" messages |
| 9 | Purge Inactive Memory | Frees up RAM |
| 10 | Flush DNS Cache | Fixes network connectivity issues |
| 11 | Re-index Spotlight | Improves search performance |
| 12 | Run Maintenance Scripts | Executes system maintenance |
| 13 | Thin Time Machine Snapshots | Frees up disk space |
| 14 | Delete Old System Logs | Removes logs older than 7 days |
| 15 | Clear Diagnostic Reports | Removes crash reports |
| 16 | Disable Crash Reporter Prompts | Stops crash dialog popups |
| 17 | Clear Old User Logs | Removes user logs older than 7 days |
| 18 | Check for Large Files | Identifies files >1GB in home folder |
| 19 | Verify Startup Disk | Checks disk for errors |
| 20 | Check System Crash Logs | Analyzes recent crashes |
| 21 | Check Finder Logs | Diagnoses Finder-specific issues |
| 22 | Free Startup Disk Space | Comprehensive disk cleanup |
| 23 | Disable Login Items | Speeds up system startup |
| 24 | Fix Battery Drain | Optimizes battery performance |
| 25 | Fix Wi-Fi Issues | Resolves network connectivity problems |
| 26 | Disable All Animations | Removes UI animations for better performance |
| 27 | Reduce Visual Effects | Minimizes transparency and effects |
| 28 | Keep Software Updated | Checks for and installs macOS updates |
| 29 | Bulk User Creation | Creates multiple user accounts with custom settings |
| 30 | System Performance Optimization | Optimizes kernel parameters for better performance |
| 31 | Memory Management Optimization | Enhanced memory management and pressure control |
| 32 | SSD Optimization | Configures settings optimized for SSD drives |
| 33 | Security Settings Optimization | Configures firewall and security settings |
| 34 | CPU/GPU Thread Optimization | Advanced thread allocation and scheduling |
| 35 | Thermal Management | Optimizes cooling and thermal settings |
| 36 | Kernel-Level Optimization | Linux-inspired kernel parameter tuning |
| 37 | OpenCore/Hackintosh Optimization | Optimizations for non-Apple hardware |
| 38 | Advanced Hardware Tuning | WindowServer priority and architecture-specific tuning |
| 39 | SMC & NVRAM Reset Guidance | Instructions for hardware-level resets |

## ⚙️ Configuration

You can modify these variables at the top of the script:

```bash
LOG_RETENTION_DAYS=7     # How many days of logs to keep
LARGE_FILE_SIZE_GB=1     # Size threshold for "large" files
DEFAULT_YES=false        # Set to true for default "yes" in prompts
VERBOSE=true             # Set to false to reduce output verbosity
RUN_ALL=false            # Set to true to run all tasks without prompting
SCRIPT_VERSION="1.0.0"   # Version of this script
```

## 🛡️ Safety Features

- **Interactive confirmations**: Every operation requires user approval
- **Non-destructive**: Most operations clear caches and temporary files
- **Backup recommendations**: Script advises creating backups before major changes
- **Graceful handling**: Continues even if individual operations fail
- **Error reporting**: Detailed status reporting for each operation
- **Initial system checks**: Verifies disk space before operations
- **OS version detection**: Ensures compatibility with your macOS version

## 📝 Generated Files

The script may create diagnostic files on your Desktop:
- `app_crash_log_check_TIMESTAMP.txt` - Recent application crash logs
- `finder_log_check_TIMESTAMP.txt` - Finder-specific error logs
- Temporary files in system temp directories for operation processing

These files are automatically removed if no issues are found or when operations complete.

## 🔄 What Gets Cleared/Reset

### Temporary Files
- User and system caches
- Application saved states
- Temporary files in `/tmp` and `/var/tmp`
- Browser caches (Safari, Chrome, Firefox)
- Old diagnostic reports and crash logs

### System Databases
- Launch Services database
- Font cache
- DNS cache
- Spotlight index (rebuilt)

### System Preferences
- User interface settings (animations, smooth scrolling)
- Dock and window behavior settings
- Finder display preferences
- Crash reporter dialog settings

### Storage Cleanup
- Trash contents
- Old downloads (30+ days)
- iOS device backups
- iOS software updates
- Xcode derived data and archives
- Time Machine local snapshots

## ⚠️ Important Notes

1. **Administrator Access**: The script requires sudo privileges for system-level operations
2. **Application Closure**: Close all apps before running for best results
3. **Restart Recommended**: Some changes require a system restart to take full effect
4. **Backup First**: Consider backing up important data before running extensive cleanups
5. **Network Configuration**: Wi-Fi fixes may require a system restart

## 🚨 Troubleshooting

If you encounter issues:

1. **Permission Denied**: Ensure you have administrator privileges
2. **Script Won't Run**: Check file permissions with `ls -la optimacos.sh`
3. **Operations Fail**: Some operations may fail on newer macOS versions due to system restrictions
4. **Verbose Mode**: Run with `--verbose` to see detailed command output for debugging
5. **Individual Functions**: Run specific functions using execution mode 3 to isolate issues
6. **Command Timeouts**: Some operations may time out on slower systems - increase timeout values in script if needed

## 🔍 Common Issues Fixed

- Finder not responding or crashing
- Applications won't launch or crash on startup
- System running slowly
- "Application can't be opened" errors
- Low disk space warnings
- Wi-Fi connectivity problems
- Poor battery life
- Slow startup times
- Sluggish UI animations and transitions
- Persistent crash reporter dialogs

## 📞 Support

If you experience persistent issues after running the script, the script provides additional troubleshooting steps:

- Boot into Safe Mode
- Run Apple Diagnostics
- Check Activity Monitor for problematic processes
- Manage Login Items in System Settings
- Create a new user account for testing
- Consider macOS reinstallation

## 🎯 Performance Optimization Features

The script includes several performance-focused optimizations:

- **Animation Removal**: Disables Dock, window, and UI animations
- **Visual Effects Reduction**: Minimizes transparency and shadows
- **Memory Optimization**: Purges inactive memory and reduces background processes
- **Battery Management**: Configures power settings for optimal battery life
- **Login Optimization**: Guides users to disable unnecessary startup items
- **Kernel Parameter Tuning**: Optimizes system connection limits and resource allocations
- **SSD-Specific Optimizations**: Special settings for solid state drives
- **Security Hardening**: Optimizes firewall and security settings
- **System-wide Performance**: Increases system resource limits and connection pools

## 🧑‍💻 Bulk User Creation

The script includes a powerful bulk user creation functionality (Section 29) that allows:

- Creating multiple user accounts with sequential UIDs
- Customizing user shell, group ID, and home directories
- Setting user preferences and skipping setup assistants
- Enabling/disabling Spotlight for new users
- Setting passwords and sudo access (with security warnings)
- Creating home directories with proper permissions

This is particularly useful for setting up lab environments, testing, or when preparing multiple workstations.

---

## 🎨 RicemacOS Features

RicemacOS transforms your macOS into a minimal, aesthetic, and performance-optimized setup.

### Core Features

#### 🛠️ Essential Tools Installation
Automatically installs modern CLI tools via Homebrew:
- **fastfetch** - Modern system info display (neofetch alternative)
- **btop** - Beautiful process viewer (htop alternative)
- **bat** - Enhanced cat with syntax highlighting
- **eza** - Modern ls replacement with icons
- **fzf** - Fuzzy finder for quick file navigation
- **ripgrep** - Lightning-fast grep alternative
- **fd** - User-friendly find alternative
- **starship** - Customizable cross-shell prompt
- **zoxide** - Smarter cd command with frecency

#### 🎯 System Appearance
- **Dark Mode** - Optional system-wide dark theme
- **Minimal Dock** - Auto-hiding, small size, clean slate
- **Clean Menu Bar** - Auto-hide option, minimal icons
- **Reduced Transparency** - Better performance
- **Reduced Motion** - Faster UI animations
- **Custom Screenshots** - Dedicated folder, PNG format, no shadows

#### 📁 Finder Configuration
- Show hidden files and extensions
- Path bar and status bar enabled
- List view by default
- Folders on top
- Disabled animations
- No extension change warnings

#### ⚡ Performance Optimizations
- All UI animations disabled
- Faster Mission Control
- Dashboard disabled
- Time Machine prompts disabled
- Hibernation optimization for SSDs
- Sudden motion sensor disabled (for SSDs)

#### 🎨 Terminal Customization
- **Starship Prompt** - Beautiful, minimal prompt with Git integration
- **Useful Aliases** - Enhanced commands for common tasks
- **Nerd Fonts** - Optional installation of JetBrains Mono and Fira Code

#### 🔧 Configuration Management
- Automatic backup creation before changes
- Non-destructive modifications
- Easy restoration options

### RicemacOS Usage

Run the script interactively:

```bash
./ricemacos.sh
```

The script will:
1. Create a backup of your current settings
2. Install Homebrew if not present
3. Ask for confirmation before each major change
4. Install tools and apply configurations
5. Restart affected services

### What Gets Configured

#### Dock Settings
```bash
# Minimal dock size (36px)
# Auto-hide with fast animations
# No magnification
# Show only active apps
# No recent apps
```

#### Finder Settings
```bash
# Show all files and extensions
# Path and status bars visible
# List view default
# Folders first
# Fast animations
# Current folder search
```

#### Terminal Aliases
```bash
ls='exa --icons --group-directories-first'
ll='exa -l --icons --group-directories-first'
la='exa -la --icons --group-directories-first'
cat='bat --style=plain'
find='fd'
grep='rg'
cleanup='find . -type f -name "*.DS_Store" -ls -delete'
showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
```

### Starship Configuration

RicemacOS includes a minimal Starship prompt configuration:

```toml
format = """
[┌───────────────────>](bold green)
[│](bold green) $directory$git_branch$git_status
[└─>](bold green) """

[directory]
style = "bold cyan"
truncation_length = 3

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold yellow"
```

### Backup & Restoration

RicemacOS creates a timestamped backup before making changes:

```bash
~/.macos_rice_backup_YYYYMMDD_HHMMSS/
└── dock_settings.plist
```

To restore defaults:
```bash
defaults read com.apple.dock
# Then manually restore settings or use Time Machine
```

### Font Installation

Optional Nerd Fonts installation for enhanced terminal experience:
- **JetBrains Mono Nerd Font** - Clean, readable monospace font
- **Fira Code Nerd Font** - Popular coding font with ligatures

### System Requirements

- macOS 10.14 (Mojave) or later
- Administrator privileges
- Internet connection (for Homebrew and tool installation)

---

## 🔄 Comparison: OptimacOS vs RicemacOS

| Feature | OptimacOS | RicemacOS |
|---------|-----------|-----------|
| **Purpose** | System repair & optimization | Aesthetic customization |
| **Complexity** | Advanced (39 operations) | Simple (focused setup) |
| **Target Users** | Power users, troubleshooting | Developers, minimalists |
| **Modifications** | System-level changes | User-level preferences |
| **Tools** | Built-in macOS utilities | Modern CLI tools |
| **Reversibility** | Mostly reversible | Fully reversible |
| **Time Required** | 5-30 minutes | 5-10 minutes |
| **Restart Required** | Recommended | Optional |

### When to Use OptimacOS
- System is running slowly
- Apps are crashing frequently
- Finder is unresponsive
- Low disk space issues
- Need advanced performance tuning
- Troubleshooting system problems

### When to Use RicemacOS
- Setting up a new Mac
- Want a minimal aesthetic
- Need modern CLI tools
- Prefer keyboard-driven workflow
- Want better terminal experience
- Like clean, distraction-free UI

---

## 📄 License

This script is provided as-is for educational and personal use. Use at your own risk and always backup your data before running system maintenance scripts.

## 🤝 Contributing

Feel free to submit issues, feature requests, or improvements to make this script better for the macOS community.

---

## 📊 Quick Start Guide

### For System Optimization & Repair
```bash
# Download and run OptimacOS
curl -O https://raw.githubusercontent.com/TheCreateGM/optimize-macos/refs/heads/main/optimacos.sh
chmod +x optimacos.sh
./optimacos.sh --help
```

### For Aesthetic Customization
```bash
# Download and run RicemacOS
curl -O https://raw.githubusercontent.com/TheCreateGM/optimize-macos/refs/heads/main/ricemacos.sh
chmod +x ricemacos.sh
./ricemacos.sh
```

### For Complete Setup (Both Scripts)
```bash
# Run OptimacOS first for system optimization
./optimacos.sh --all

# Then run RicemacOS for aesthetic setup
./ricemacos.sh

# Restart your Mac
sudo shutdown -r now
```

---

**OptimacOS Version**: 1.0.0  
**RicemacOS Version**: 1.0.0  
**Last Updated**: 2025  
**Compatibility**: macOS 10.14+ (Mojave and later)

**Note**: Both scripts are safe, non-destructive, and create backups before making changes. Always review what each script does before running it.
