#!/bin/bash

# --- Configuration ---
LOG_RETENTION_DAYS=7 # How many days of system logs to keep
LARGE_FILE_SIZE_GB=1 # Size in GB to consider a file "large"

# --- Helper Functions ---
ask_yes_no() {
    while true; do
        read -p "$1 [y/N]: " yn
        case $yn in
            [Yy]* ) return 0;; # Yes
            [Nn]* | "" ) return 1;; # No or Enter
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# --- Main Script ---
echo "🚀 macOS System Fix Script 🚀"
echo "-----------------------------------------"
echo "This script focuses on resolving Finder not responding, app crashes, launching issues, and startup disk space problems."
echo "It also includes performance optimization steps."
echo "⚠️ IMPORTANT: Close all applications before proceeding for best results."
echo "Some operations require administrator privileges."
echo

# Require admin privileges upfront and keep them alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
ADMIN_KEEP_ALIVE_PID=$! # Save PID to kill it later

# --- 1. Restart Finder ---
restart_finder() {
    echo -e "\n📁 Section 1: Restarting Finder"
    echo "---------------------------------"
    if ask_yes_no "Force quit and restart Finder?"; then
        echo "Restarting Finder..."
        killall Finder
        echo "✅ Finder restarted."
    else
        echo "Skipping Finder restart."
    fi
}

# --- 2. Clear Finder Preferences ---
clear_finder_prefs() {
    echo -e "\n🧹 Section 2: Clearing Finder Preferences"
    echo "-----------------------------------------"
    if ask_yes_no "Delete Finder preferences? (This resets Finder settings to default)"; then
        echo "Removing Finder preferences..."
        rm -f ~/Library/Preferences/com.apple.finder.plist
        rm -f ~/Library/Preferences/com.apple.sidebarlists.plist
        killall Finder
        echo "✅ Finder preferences cleared and Finder restarted."
    else
        echo "Skipping Finder preferences clear."
    fi
}

# --- 3. Clear Caches ---
clear_caches() {
    echo -e "\n🧹 Section 3: Clearing Caches"
    echo "---------------------------------"
    if ask_yes_no "Clear User Caches including Finder-specific caches?"; then
        echo "Clearing User Caches..."
        rm -rf ~/Library/Caches/*
        rm -rf ~/Library/Preferences/ByHost/com.apple.finder*
        rm -rf ~/Library/Saved\ Application\ State/com.apple.finder.savedState
        echo "✅ User and Finder-specific caches cleared."
    else
        echo "Skipping User Caches."
    fi

    if ask_yes_no "Clear System Caches?"; then
        echo "Clearing System Caches..."
        sudo rm -rf /Library/Caches/*
        sudo rm -rf /System/Library/Caches/*
        echo "✅ System Caches cleared."
    else
        echo "Skipping System Caches."
    fi
}

# --- 4. Reset Launch Services Database ---
reset_launch_services() {
    echo -e "\n🔄 Section 4: Resetting Launch Services Database"
    echo "-----------------------------------------------"
    if ask_yes_no "Reset Launch Services database? (This fixes app launch issues and duplicate apps)"; then
        echo "Resetting Launch Services database..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
        echo "✅ Launch Services database reset."
    else
        echo "Skipping Launch Services reset."
    fi
}

# --- 5. Clear Application Saved States ---
clear_app_saved_states() {
    echo -e "\n💾 Section 5: Clearing Application Saved States"
    echo "----------------------------------------------"
    if ask_yes_no "Clear all application saved states? (Prevents apps from restoring corrupted states)"; then
        echo "Clearing application saved states..."
        rm -rf ~/Library/Saved\ Application\ State/*
        echo "✅ Application saved states cleared."
    else
        echo "Skipping application saved states clear."
    fi
}

# --- 6. Reset Font Cache ---
reset_font_cache() {
    echo -e "\n🔤 Section 6: Resetting Font Cache"
    echo "----------------------------------"
    if ask_yes_no "Reset font cache? (Fixes font-related app crashes)"; then
        echo "Resetting font cache..."
        sudo atsutil databases -remove
        atsutil server -shutdown
        atsutil server -ping
        echo "✅ Font cache reset."
    else
        echo "Skipping font cache reset."
    fi
}

# --- 7. Repair Disk Permissions ---
repair_permissions() {
    echo -e "\n🔐 Section 7: Repairing Disk Permissions"
    echo "----------------------------------------"
    if ask_yes_no "Repair disk permissions? (Fixes app launch permission issues)"; then
        echo "Repairing disk permissions..."
        sudo diskutil resetUserPermissions / $(id -u)
        echo "✅ Disk permissions repaired."
    else
        echo "Skipping disk permissions repair."
    fi
}

# --- 8. Clear Quarantine Attributes ---
clear_quarantine() {
    echo -e "\n🛡️ Section 8: Clearing Quarantine Attributes"
    echo "--------------------------------------------"
    if ask_yes_no "Clear quarantine attributes from Applications folder? (Fixes 'app can't be opened' issues)"; then
        echo "Clearing quarantine attributes..."
        sudo xattr -rd com.apple.quarantine /Applications
        echo "✅ Quarantine attributes cleared from Applications folder."
    else
        echo "Skipping quarantine attributes clear."
    fi
}

# --- 9. Purge Inactive Memory ---
purge_memory() {
    echo -e "\n🧠 Section 9: Purging Inactive Memory"
    echo "--------------------------------------"
    if ask_yes_no "Run 'sudo purge' to free inactive RAM?"; then
        echo "Purging inactive memory..."
        sudo purge
        echo "✅ Memory purged."
    else
        echo "Skipping memory purge."
    fi
}

# --- 10. Flush DNS Cache ---
flush_dns() {
    echo -e "\n🌐 Section 10: Flushing DNS Cache"
    echo "---------------------------------"
    if ask_yes_no "Flush DNS Cache?"; then
        echo "Flushing DNS cache..."
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder
        echo "✅ DNS cache flushed."
    else
        echo "Skipping DNS cache flush."
    fi
}

# --- 11. Re-index Spotlight ---
reindex_spotlight() {
    echo -e "\n🔦 Section 11: Re-indexing Spotlight"
    echo "------------------------------------"
    if ask_yes_no "Re-index Spotlight for the main drive?"; then
        echo "Starting Spotlight re-indexing for / ..."
        sudo mdutil -E /
        echo "✅ Spotlight re-indexing initiated."
    else
        echo "Skipping Spotlight re-indexing."
    fi
}

# --- 12. Run System Maintenance Scripts ---
run_maintenance_scripts() {
    echo -e "\n🛠️ Section 12: Running System Maintenance Scripts"
    echo "-----------------------------------------------"
    if ask_yes_no "Run system maintenance scripts?"; then
        echo "Running periodic maintenance scripts..."
        sudo periodic daily weekly monthly
        echo "✅ System maintenance scripts executed."
    else
        echo "Skipping system maintenance scripts."
    fi
}

# --- 13. Thin Time Machine Local Snapshots ---
thin_local_snapshots() {
    echo -e "\n💾 Section 13: Thinning Time Machine Local Snapshots"
    echo "----------------------------------------------------"
    if ask_yes_no "Thin Time Machine local snapshots?"; then
        echo "Thinning local snapshots..."
        # Thin local snapshots older than 4 hours, trying to free up to 100GB
        sudo tmutil thinlocalsnapshots / 100000000000 4
        echo "✅ Local snapshots thinning process initiated."
    else
        echo "Skipping thinning local snapshots."
    fi
}

# --- 14. Delete Old System Logs ---
delete_old_logs() {
    echo -e "\n🧼 Section 14: Deleting Old System Logs"
    echo "---------------------------------------"
    if ask_yes_no "Delete system logs older than ${LOG_RETENTION_DAYS} days?"; then
        echo "Deleting system logs..."
        sudo find /private/var/log -type f -mtime +${LOG_RETENTION_DAYS} -delete
        echo "✅ Old system logs deleted."
    else
        echo "Skipping old system log deletion."
    fi
}

# --- 15. Clear Old Diagnostic Reports ---
clear_diagnostic_reports() {
    echo -e "\n📋 Section 15: Clearing Old Diagnostic Reports"
    echo "--------------------------------------------"
    if ask_yes_no "Delete old application diagnostic reports and crash logs? (Can free space and improve responsiveness)"; then
        echo "Clearing old diagnostic reports..."
        # Diagnostic reports are in ~/Library/Logs/DiagnosticReports/
        # Delete all files and directories within DiagnosticReports, excluding the directory itself
        if [ -d ~/Library/Logs/DiagnosticReports ]; then
            find ~/Library/Logs/DiagnosticReports -mindepth 1 -delete
            echo "✅ Old diagnostic reports cleared."
        else
            echo "No DiagnosticReports directory found."
        fi
    else
        echo "Skipping diagnostic reports cleanup."
    fi
}

# --- 16. Disable Crash Reporter Prompts ---
disable_crash_reporter() {
    echo -e "\n❌ Section 16: Disable Crash Reporter Prompts"
    echo "---------------------------------------------"
    if ask_yes_no "Disable dialog prompts when applications crash? (Logs are still recorded)"; then
        echo "Disabling Crash Reporter prompts..."
        defaults write com.apple.CrashReporter DialogType none
        echo "✅ Crash Reporter prompts disabled."
    else
        echo "Skipping disabling Crash Reporter prompts."
    fi
}

# --- 17. Clear Old User Logs ---
clear_user_logs() {
    echo -e "\n🧼 Section 17: Deleting Old User Logs"
    echo "-------------------------------------"
    if ask_yes_no "Delete user logs (in ~/Library/Logs) older than ${LOG_RETENTION_DAYS} days?"; then
        echo "Deleting user logs..."
        if [ -d ~/Library/Logs ]; then
            find ~/Library/Logs -type f -mtime +${LOG_RETENTION_DAYS} -delete
            echo "✅ Old user logs deleted."
        else
            echo "No User Logs directory found."
        fi
    else
        echo "Skipping old user log deletion."
    fi
}

# --- 18. Check for Large Files ---
check_large_files() {
    echo -e "\n🗂️ Section 18: Checking for Large Files"
    echo "---------------------------------------"
    if ask_yes_no "Scan Home folder for files larger than ${LARGE_FILE_SIZE_GB}GB?"; then
        echo "Searching for large files..."
        # Use 1G instead of 1G for consistency with find size flag
        find ~ -type f -size +${LARGE_FILE_SIZE_GB}G -print0 | xargs -0 -I {} du -sh {} 2>/dev/null
        echo "✅ Large file check complete."
    else
        echo "Skipping large file check."
    fi
}

# --- 19. Verify Startup Disk ---
verify_disk() {
    echo -e "\n💿 Section 19: Verifying Startup Disk"
    echo "-------------------------------------"
    if ask_yes_no "Verify the startup disk for errors? (Does not repair)"; then
        echo "Verifying startup disk..."
        if sudo diskutil verifyVolume /; then
            echo "✅ Startup disk verification complete."
        else
            echo "⚠️ Startup disk verification reported errors. Consider running 'diskutil repairVolume /' from Recovery Mode."
        fi
    else
        echo "Skipping startup disk verification."
    fi
}

# --- 20. Check System Logs for App Crashes ---
check_crash_logs() {
    echo -e "\n📋 Section 20: Checking System Logs for App Crashes"
    echo "---------------------------------------------------"
    if ask_yes_no "Check recent system logs for application crashes?"; then
        echo "Extracting recent application crash logs..."
        # Look for 'crashed' in the last 1 hour, filter for keywords
        log show --predicate 'eventMessage contains "crashed"' --last 1h | grep -i "crash\|error\|exception" > ~/Desktop/app_crash_log_check.txt
        if [ -s ~/Desktop/app_crash_log_check.txt ]; then
            echo "⚠️ Found potential application crashes. Check ~/Desktop/app_crash_log_check.txt for details."
        else
            echo "✅ No recent application crashes found in logs."
            rm ~/Desktop/app_crash_log_check.txt 2>/dev/null
        fi
    else
        echo "Skipping application crash log check."
    fi
}

# --- 21. Check Finder Logs ---
check_finder_logs() {
    echo -e "\n📋 Section 21: Checking Finder Logs"
    echo "-------------------------------------"
    if ask_yes_no "Check recent Finder-related system logs for errors?"; then
        echo "Extracting recent Finder-related logs..."
        # Look for 'Finder' process logs in the last 1 hour, filter for errors/crashes
        log show --predicate 'process == "Finder"' --last 1h | grep -i "error\|crash" > ~/Desktop/finder_log_check.txt
        if [ -s ~/Desktop/finder_log_check.txt ]; then
            echo "⚠️ Found potential Finder issues. Check ~/Desktop/finder_log_check.txt for details."
        else
            echo "✅ No recent Finder errors or crashes found in logs."
            rm ~/Desktop/finder_log_check.txt 2>/dev/null
        fi
    else
        echo "Skipping Finder log check."
    fi
}

# --- 22. Free Up Startup Disk Space ---
free_startup_disk_space() {
    echo -e "\n💽 Section 22: Freeing Up Startup Disk Space"
    echo "--------------------------------------------"

    # Show current disk usage
    echo "Current disk usage:"
    df -h /
    echo ""

    # Empty Trash
    if ask_yes_no "Empty Trash for all users?"; then
        echo "Emptying Trash..."
        sudo rm -rf ~/.Trash/*
        sudo rm -rf /Volumes/*/.Trashes
        echo "✅ Trash emptied."
    else
        echo "Skipping Trash empty."
    fi

    # Clear Downloads folder of old files
    if ask_yes_no "Delete files older than 30 days from Downloads folder?"; then
        echo "Clearing old Downloads..."
        find ~/Downloads -type f -mtime +30 -delete 2>/dev/null
        echo "✅ Old Downloads cleared."
    else
        echo "Skipping old Downloads cleanup."
    fi

    # Clear browser caches
    if ask_yes_no "Clear browser caches (Safari, Chrome, Firefox)?"; then
        echo "Clearing browser caches..."
        rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null
        rm -rf ~/Library/Safari/WebpageIcons.db 2>/dev/null
        rm -rf ~/Library/Application\ Support/Google/Chrome/*/Default/Cache/* 2>/dev/null # Updated Chrome path
        rm -rf ~/Library/Caches/Google/Chrome/* 2>/dev/null # Keep old path for compatibility
        rm -rf ~/Library/Caches/Firefox/Profiles/*/Cache/* 2>/dev/null # Updated Firefox path
        rm -rf ~/Library/Caches/Mozilla/Firefox/* 2>/dev/null # Keep old path for compatibility
        echo "✅ Browser caches cleared."
    else
        echo "Skipping browser cache cleanup."
    fi

    # Clear iOS device backups
    if ask_yes_no "Delete old iOS device backups?"; then
        echo "Clearing iOS device backups..."
        if [ -d ~/Library/Application\ Support/MobileSync/Backup ]; then
            BACKUP_SIZE=$(du -sh ~/Library/Application\ Support/MobileSync/Backup 2>/dev/null | cut -f1)
            echo "Current iOS backups size: $BACKUP_SIZE"
            if [ -n "$BACKUP_SIZE" ] && [ "$BACKUP_SIZE" != "0B" ]; then # Check if backup exists and is not 0B
                 if ask_yes_no "Proceed with deleting all iOS device backups?"; then
                    rm -rf ~/Library/Application\ Support/MobileSync/Backup/*
                    echo "✅ iOS device backups cleared."
                else
                    echo "Skipping iOS backup deletion."
                fi
            else
                echo "No significant iOS backups found."
            fi
        else
            echo "No iOS backups directory found."
        fi
    else
        echo "Skipping iOS backup cleanup."
    fi

    # Clear old iOS software updates
    if ask_yes_no "Delete cached iOS software updates?"; then
        echo "Clearing iOS software updates..."
        sudo rm -rf ~/Library/iTunes/iPhone\ Software\ Updates/* 2>/dev/null
        sudo rm -rf ~/Library/iTunes/iPad\ Software\ Updates/* 2>/dev/null
         # Also check newer MobileSync location
        sudo rm -rf ~/Library/MobileDevice/Software\ Updates/* 2>/dev/null
        echo "✅ iOS software updates cleared."
    else
        echo "Skipping iOS software update cleanup."
    fi

    # Clear Xcode caches if present
    if [ -d ~/Library/Developer/Xcode ]; then
        if ask_yes_no "Clear Xcode derived data and caches?"; then
            echo "Clearing Xcode caches..."
            rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
            rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null
            rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null
            echo "✅ Xcode caches cleared."
        else
            echo "Skipping Xcode cache cleanup."
        fi
    fi

    # Clear system temp files
    if ask_yes_no "Clear system temporary files?"; then
        echo "Clearing system temporary files..."
        sudo rm -rf /private/tmp/*
        sudo rm -rf /private/var/tmp/*
        echo "✅ System temporary files cleared."
    else
        echo "Skipping system temp file cleanup."
    fi

    # Show disk usage after cleanup
    echo ""
    echo "Disk usage after cleanup:"
    df -h /
}

# --- 23. Disable Login Items (Optional) ---
disable_login_items() {
    echo -e "\n😴 Section 23: Disabling Login Items (Optional)"
    echo "---------------------------------------------"
    if ask_yes_no "Disable non-essential login items to speed up login?"; then
        echo "Disabling non-essential login items..."
        # This requires manual intervention, guide the user.
        echo "Open System Settings -> General -> Login Items." # Updated path for modern macOS
        echo "Disable any items you don't need to start automatically at login."
        echo "✅  Remember to re-enable essential login items later if needed."
    else
        echo "Skipping login item disabling."
    fi
}

# --- 24. Fix Battery Draining Quickly ---
fix_battery_drain() {
    echo -e "\n🔋 Section 24: Fixing Battery Draining Quickly"
    echo "---------------------------------------------"
    if ask_yes_no "Run battery diagnostics and optimizations?"; then
        echo "Running battery diagnostics..."
        sudo pmset -g batt
        echo "Optimizing battery settings..."
        # These settings are primarily for power saving, not necessarily performance while plugged in
        sudo pmset -b sleep 10 # Battery sleep time
        sudo pmset -b disksleep 10 # Battery disk sleep time
        sudo pmset -b halfdim 1 # Half dim display on battery
        sudo pmset -b lessbright 1 # Use slightly less bright display on battery
        sudo pmset -b lowpowermode 1 # Enable Low Power Mode on battery
        echo "✅ Battery diagnostics and optimizations complete."
    else
        echo "Skipping battery diagnostics and optimizations."
    fi
}

# --- 25. Fix Wi-Fi Not Connecting or Dropping ---
fix_wifi() {
    echo -e "\n📡 Section 25: Fixing Wi-Fi Not Connecting or Dropping"
    echo "-----------------------------------------------------"
    if ask_yes_no "Run Wi-Fi diagnostics and optimizations?"; then
        echo "Running Wi-Fi diagnostics..."
        sudo networksetup -listallhardwareports
        echo "Optimizing Wi-Fi settings..."
        # Toggling Wi-Fi off/on
        WIFI_PORT=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')
        if [ -n "$WIFI_PORT" ]; then
            echo "Found Wi-Fi interface: $WIFI_PORT"
            sudo networksetup -setairportpower "$WIFI_PORT" off
            sleep 2 # Reduced sleep time slightly
            sudo networksetup -setairportpower "$WIFI_PORT" on
        else
            echo "Could not determine Wi-Fi interface."
        fi

        # Clearing Network Configuration - Potentially disruptive, warn user or make optional
        if ask_yes_no "Delete network configuration preference files? (Requires reboot, can fix persistent Wi-Fi issues)"; then
             echo "Clearing Network Configuration..."
             sudo rm /Library/Preferences/SystemConfiguration/preferences.plist 2>/dev/null
             sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist 2>/dev/null
             sudo rm /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist 2>/dev/null
             sudo rm /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist 2>/dev/null
             echo "✅ Network configuration preference files cleared."
             echo "Rebooting the system is highly recommended to apply changes."
        else
             echo "Skipping deletion of network configuration files."
        fi

        echo "✅ Wi-Fi diagnostics and toggling complete."
    else
        echo "Skipping Wi-Fi diagnostics and optimizations."
    fi
}

# --- 26. Disable All Animation Effects ---
disable_animations() {
    echo -e "\n⚡ Section 26: Disabling All Animation Effects"
    echo "---------------------------------------------"
    if ask_yes_no "Disable most macOS animation effects for better performance?"; then # Changed wording slightly
        echo "Disabling most animation effects..."

        # Disable Dock animations
        defaults write com.apple.dock autohide-time-modifier -float 0
        defaults write com.apple.dock autohide-delay -float 0
        defaults write com.apple.dock expose-animation-duration -float 0.1
        defaults write com.apple.dock launchanim -bool false

        # Disable Mission Control animations (using the same key as expose)
        defaults write com.apple.dock expose-animation-duration -float 0.1

        # Disable opening and closing window animations
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

        # Disable smooth scrolling (can sometimes impact performance)
        defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

        # Disable menu bar animations (part of general UI animation)
        defaults write NSGlobalDomain NSScrollViewRubberbanding -bool false # This is more about scroll rubberbanding, not specific menu bar animation

        # Disable window resize animation
        defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

        # Disable Finder animations (already included)
        defaults write com.apple.finder DisableAllAnimations -bool true

        # Disable animations when opening Quick Look windows
        defaults write -g QLPanelAnimationDuration -float 0

        # Disable animations when opening applications (part of Dock launchanim)
        # defaults write com.apple.dock springboard-show-duration -float 0 # Springboard keys less relevant
        # defaults write com.apple.dock springboard-hide-duration -float 0 # Springboard keys less relevant

        # Disable transparency and reduce motion (Accessibility settings, can improve performance on older Macs)
        defaults write com.apple.universalaccess reduceMotion -bool true
        defaults write com.apple.universalaccess reduceTransparency -bool true

        # Restart affected applications for changes to take effect
        killall Dock 2>/dev/null
        killall Finder 2>/dev/null

        echo "✅ Most animation and visual effects disabled."
    else
        echo "Skipping animation effects disabling."
    fi
}

# --- 27. Reduce Visual Effects for Performance Optimization ---
reduce_visual_effects() {
    echo -e "\n🎨 Section 27: Reducing Visual Effects for Performance Optimization"
    echo "---------------------------------------------------------------"
    if ask_yes_no "Reduce visual effects for better performance?"; then
        echo "Reducing visual effects..."

        # Disable transparency in the Dock
        defaults write com.apple.dock showhidden -bool true
        defaults write com.apple.dock no-bouncing -bool true

        # Disable Dashboard
        defaults write com.apple.dashboard mcx-disabled -bool true

        # Disable translucent menu bar and Dock
        defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false
        defaults write com.apple.dock hide-mirror -bool true

        # Disable shadows in windows
        defaults write NSGlobalDomain AppleWindowShadow -bool false

        # Disable the "Genie" effect when minimizing windows
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

        # Disable the "Scale" effect when opening windows
        defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

        # Restart affected applications for changes to take effect
        killall Dock 2>/dev/null
        killall Finder 2>/dev/null

        echo "✅ Visual effects reduced for better performance."
    else
        echo "Skipping visual effects reduction."
    fi
}

# --- 28. Keep Software Updated for macOS ---
keep_software_updated() {
    echo -e "\n⬆️ Section 28: Keep Software Updated for macOS"
    echo "-------------------------------------------------"
    if ask_yes_no "Check for and install available macOS updates?"; then
        echo "Checking for software updates..."
        # Run softwareupdate tool in non-interactive mode to install all recommended updates
        sudo softwareupdate -i -a --restart
        echo "✅ Software update process initiated. System will restart automatically if updates require it."
    else
        echo "Skipping software update check."
    fi
}

# --- Call functions ---
restart_finder
clear_finder_prefs
clear_caches
reset_launch_services
clear_app_saved_states
reset_font_cache
repair_permissions
clear_quarantine
purge_memory
flush_dns
reindex_spotlight
run_maintenance_scripts
thin_local_snapshots
delete_old_logs
clear_diagnostic_reports
disable_crash_reporter # Added new step
clear_user_logs # Added new step
check_large_files
verify_disk
check_crash_logs
check_finder_logs
free_startup_disk_space
disable_login_items
fix_battery_drain
fix_wifi
disable_animations
reduce_visual_effects
keep_software_updated

# --- Final Advice ---
echo -e "\n🏁 System Fix & Optimization Script Finished! 🏁"
echo "------------------------------------"
echo "Additional steps if issues persist or for further optimization:"
echo "  🔹 Restart your Mac (especially after clearing network preferences)"
echo "  🔹 Check for macOS updates: System Settings > General > Software Update"
echo "  🔹 Boot into Safe Mode: Hold Shift during startup (runs additional checks and clears caches)"
echo "  🔹 Run Apple Diagnostics: Hold 'D' during startup (checks hardware)"
echo "  🔹 Check Activity Monitor for problematic processes consuming high CPU/Memory"
echo "  🔹 Manage Login Items: System Settings > General > Login Items (Disable items you don't need)"
echo "  🔹 Uninstall unused applications (Use Launchpad or Applications folder)"
echo "  🔹 Try creating a new user account to test if the issue is user-specific"
echo "  🔹 Reinstall problematic applications"
echo "  🔹 Consider reinstalling macOS if problems continue (Backup your data first!)"
echo ""
echo "For persistent disk space issues:"
echo "  🔹 Use Storage Management: Apple Menu > About This Mac > More Info > Storage Settings (Identifies large categories of files)"
echo "  🔹 Manually review and delete large/unused files (Documents, Movies, Pictures)"
echo "  🔹 Move large files to external storage"
echo "  🔹 Use cloud storage for documents and photos (iCloud, Dropbox, Google Drive)"
echo "  🔹 Clean up system junk using third-party tools (Use with caution)"

# Clean up admin privileges keep-alive
if [[ -n "$ADMIN_KEEP_ALIVE_PID" ]]; then
    kill "$ADMIN_KEEP_ALIVE_PID" 2>/dev/null
fi

echo "✅ All selected operations complete."
