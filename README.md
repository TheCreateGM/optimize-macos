# OptimacOS - macOS System Optimization Script

A comprehensive shell script designed to fix common macOS issues including Finder crashes, app launch problems, system slowdowns, and startup disk space issues.

## 🚀 Features

This script provides 24 different system optimization and repair operations:

### Core System Fixes
- **Finder Issues**: Restart Finder, clear preferences, and fix unresponsive behavior
- **App Launch Problems**: Reset Launch Services database and clear quarantine attributes
- **System Performance**: Clear caches, purge memory, and run maintenance scripts
- **Storage Management**: Free up startup disk space and identify large files

### Performance Optimization
- **Animation Disabling**: Remove all UI animations for faster system responsiveness
- **Memory Management**: Purge inactive memory and optimize system resources

### Advanced Diagnostics
- **Crash Detection**: Analyze system logs for application crashes
- **Disk Health**: Verify startup disk integrity and repair permissions
- **Network Issues**: Fix Wi-Fi connectivity problems and flush DNS cache
- **Battery Optimization**: Diagnose and optimize battery performance

## 📋 Requirements

- macOS (tested on macOS 10.15+ and later)
- Administrator privileges (script will prompt for sudo access)
- Terminal application

## 🔧 Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/TheCreateGM/optimize-macos/refs/heads/main/optimacos.sh
   ```

2. Make it executable:
   ```bash
   chmod +x optimacos.sh
   ```

## 🏃 Usage

Run the script from Terminal:

```bash
./optimacos.sh
```

### Interactive Mode
The script runs in interactive mode, asking for confirmation before each operation. You can:
- Choose which fixes to apply by answering `y` (yes) or `n` (no)
- Press Enter to default to "no" for any operation
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
| 16 | Check for Large Files | Identifies files >1GB in home folder |
| 17 | Verify Startup Disk | Checks disk for errors |
| 18 | Check System Crash Logs | Analyzes recent crashes |
| 19 | Check Finder Logs | Diagnoses Finder-specific issues |
| 20 | Free Startup Disk Space | Comprehensive disk cleanup |
| 21 | Disable Login Items | Speeds up system startup |
| 22 | Fix Battery Drain | Optimizes battery performance |
| 23 | Fix Wi-Fi Issues | Resolves network connectivity problems |
| 24 | Disable All Animations | Removes UI animations for better performance |

## ⚙️ Configuration

You can modify these variables at the top of the script:

```bash
LOG_RETENTION_DAYS=7     # How many days of logs to keep
LARGE_FILE_SIZE_GB=1     # Size threshold for "large" files
```

## 🛡️ Safety Features

- **Interactive confirmations**: Every operation requires user approval
- **Non-destructive**: Most operations clear caches and temporary files
- **Backup recommendations**: Script advises creating backups before major changes
- **Graceful handling**: Continues even if individual operations fail

## 📝 Generated Files

The script may create diagnostic files on your Desktop:
- `app_crash_log_check.txt` - Recent application crash logs
- `finder_log_check.txt` - Finder-specific error logs

These files are automatically removed if no issues are found.

## 🔄 What Gets Cleared/Reset

### Temporary Files
- User and system caches
- Application saved states
- Temporary files in `/tmp` and `/var/tmp`
- Browser caches (Safari, Chrome, Firefox)

### System Databases
- Launch Services database
- Font cache
- DNS cache
- Spotlight index (rebuilt)

### System Preferences
- User interface settings (animations, smooth scrolling)
- Dock and window behavior settings
- Finder display preferences

### Storage Cleanup
- Trash contents
- Old downloads (30+ days)
- iOS device backups
- Xcode derived data
- Time Machine local snapshots

## ⚠️ Important Notes

1. **Administrator Access**: The script requires sudo privileges for system-level operations
2. **Application Closure**: Close all apps before running for best results
3. **Restart Recommended**: Some changes require a system restart to take full effect
4. **Backup First**: Consider backing up important data before running extensive cleanups

## 🚨 Troubleshooting

If you encounter issues:

1. **Permission Denied**: Ensure you have administrator privileges
2. **Script Won't Run**: Check file permissions with `ls -la optimacos.sh`
3. **Operations Fail**: Some operations may fail on newer macOS versions due to system restrictions

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

## 📞 Support

If you experience persistent issues after running the script, the script provides additional troubleshooting steps:

- Boot into Safe Mode
- Run Apple Diagnostics
- Check Activity Monitor
- Create a new user account for testing
- Consider macOS reinstallation

## 📄 License

This script is provided as-is for educational and personal use. Use at your own risk and always backup your data before running system maintenance scripts.

## 🤝 Contributing

Feel free to submit issues, feature requests, or improvements to make this script better for the macOS community.

---

**Version**: 1.0
**Last Updated**: 2025
**Compatibility**: macOS 10.15+
