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

# --- 16. Check for Large Files ---
check_large_files() {
    echo -e "\n🗂️ Section 16: Checking for Large Files"
    echo "---------------------------------------"
    if ask_yes_no "Scan Home folder for files larger than ${LARGE_FILE_SIZE_GB}GB?"; then
        echo "Searching for large files..."
        find ~ -type f -size +${LARGE_FILE_SIZE_GB}G -print0 | xargs -0 -I {} du -sh {}
        echo "✅ Large file check complete."
    else
        echo "Skipping large file check."
    fi
}

# --- 17. Verify Startup Disk ---
verify_disk() {
    echo -e "\n💿 Section 17: Verifying Startup Disk"
    echo "-------------------------------------"
    if ask_yes_no "Verify the startup disk for errors?"; then
        echo "Verifying startup disk..."
        if sudo diskutil verifyVolume /; then
            echo "✅ Startup disk verification complete."
        else
            echo "⚠️ Startup disk verification reported errors."
        fi
    else
        echo "Skipping startup disk verification."
    fi
}

# --- 18. Check System Logs for App Crashes ---
check_crash_logs() {
    echo -e "\n📋 Section 18: Checking System Logs for App Crashes"
    echo "---------------------------------------------------"
    if ask_yes_no "Check recent system logs for application crashes?"; then
        echo "Extracting recent application crash logs..."
        log show --predicate 'eventMessage contains "crashed"' --last 1h | grep -i "crash\|error\|exception" > ~/Desktop/app_crash_log_check.txt
        if [ -s ~/Desktop/app_crash_log_check.txt ]; then
            echo "⚠️ Found potential application crashes. Check ~/Desktop/app_crash_log_check.txt for details."
        else
            echo "✅ No recent application crashes found in logs."
            rm ~/Desktop/app_crash_log_check.txt
        fi
    else
        echo "Skipping application crash log check."
    fi
}

# --- 19. Check Finder Logs ---
check_finder_logs() {
    echo -e "\n📋 Section 19: Checking Finder Logs"
    echo "-------------------------------------"
    if ask_yes_no "Check recent Finder-related system logs for errors?"; then
        echo "Extracting recent Finder-related logs..."
        log show --predicate 'process == "Finder"' --last 1h | grep -i "error\|crash" > ~/Desktop/finder_log_check.txt
        if [ -s ~/Desktop/finder_log_check.txt ]; then
            echo "⚠️ Found potential Finder issues. Check ~/Desktop/finder_log_check.txt for details."
        else
            echo "✅ No recent Finder errors or crashes found in logs."
            rm ~/Desktop/finder_log_check.txt
        fi
    else
        echo "Skipping Finder log check."
    fi
}

# --- 20. Free Up Startup Disk Space ---
free_startup_disk_space() {
    echo -e "\n💽 Section 20: Freeing Up Startup Disk Space"
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
        rm -rf ~/Library/Caches/com.apple.Safari/*
        rm -rf ~/Library/Safari/WebpageIcons.db
        rm -rf ~/Library/Caches/Google/Chrome/*
        rm -rf ~/Library/Caches/Mozilla/Firefox/*
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
            if ask_yes_no "Proceed with deleting all iOS device backups?"; then
                rm -rf ~/Library/Application\ Support/MobileSync/Backup/*
                echo "✅ iOS device backups cleared."
            else
                echo "Skipping iOS backup deletion."
            fi
        else
            echo "No iOS backups found."
        fi
    else
        echo "Skipping iOS backup cleanup."
    fi

    # Clear old iOS software updates
    if ask_yes_no "Delete cached iOS software updates?"; then
        echo "Clearing iOS software updates..."
        sudo rm -rf ~/Library/iTunes/iPhone\ Software\ Updates/*
        sudo rm -rf ~/Library/iTunes/iPad\ Software\ Updates/*
        echo "✅ iOS software updates cleared."
    else
        echo "Skipping iOS software update cleanup."
    fi

    # Clear Xcode caches if present
    if [ -d ~/Library/Developer/Xcode ]; then
        if ask_yes_no "Clear Xcode derived data and caches?"; then
            echo "Clearing Xcode caches..."
            rm -rf ~/Library/Developer/Xcode/DerivedData/*
            rm -rf ~/Library/Developer/Xcode/Archives/*
            rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
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

# --- 21. Disable Login Items (Optional) ---
disable_login_items() {
    echo -e "\n😴 Section 21: Disabling Login Items (Optional)"
    echo "---------------------------------------------"
    if ask_yes_no "Disable non-essential login items to speed up login?"; then
        echo "Disabling non-essential login items..."
        # This requires manual intervention, guide the user.
        echo "Open System Settings -> Users & Groups -> Login Items."
        echo "Disable any items you don't need to start automatically at login."
        echo "✅  Remember to re-enable essential login items later if needed."
    else
        echo "Skipping login item disabling."
    fi
}

# --- 22. Fix Battery Draining Quickly ---
fix_battery_drain() {
    echo -e "\n🔋 Section 22: Fixing Battery Draining Quickly"
    echo "---------------------------------------------"
    if ask_yes_no "Run battery diagnostics and optimizations?"; then
        echo "Running battery diagnostics..."
        sudo pmset -g batt
        echo "Optimizing battery settings..."
        sudo pmset -b sleep 10
        sudo pmset -b disksleep 10
        sudo pmset -b halfdim 1
        sudo pmset -b lessbright 1
        sudo pmset -b lowpowermode 1
        echo "✅ Battery diagnostics and optimizations complete."
    else
        echo "Skipping battery diagnostics and optimizations."
    fi
}

# --- 23. Fix Wi-Fi Not Connecting or Dropping ---
fix_wifi() {
    echo -e "\n📡 Section 23: Fixing Wi-Fi Not Connecting or Dropping"
    echo "-----------------------------------------------------"
    if ask_yes_no "Run Wi-Fi diagnostics and optimizations?"; then
        echo "Running Wi-Fi diagnostics..."
        sudo networksetup -listallhardwareports
        echo "Optimizing Wi-Fi settings..."
        sudo networksetup -setairportpower en0 off
        sleep 5
        sudo networksetup -setairportpower en0 on
        echo "Clearing Network Configuration..."
        sudo rm /Library/Preferences/SystemConfiguration/preferences.plist
        sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
        sudo rm /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
        sudo rm /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist
        echo "Rebooting the system to apply changes..."
        echo "✅ Wi-Fi diagnostics and optimizations complete. Please reboot your system."
    else
        echo "Skipping Wi-Fi diagnostics and optimizations."
    fi
}

# --- 24. Disable All Animation Effects ---
disable_animations() {
    echo -e "\n⚡ Section 24: Disabling All Animation Effects"
    echo "---------------------------------------------"
    if ask_yes_no "Disable all macOS animation effects for better performance?"; then
        echo "Disabling all animation effects..."

        # Disable Dock animations
        defaults write com.apple.dock autohide-time-modifier -float 0
        defaults write com.apple.dock autohide-delay -float 0
        defaults write com.apple.dock expose-animation-duration -float 0.1
        defaults write com.apple.dock launchanim -bool false

        # Disable Mission Control animations
        defaults write com.apple.dock expose-animation-duration -float 0.1

        # Disable opening and closing animations
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

        # Disable smooth scrolling
        defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

        # Disable menu bar animations
        defaults write NSGlobalDomain NSScrollViewRubberbanding -bool false

        # Disable window resize animation
        defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

        # Disable Finder animations
        defaults write com.apple.finder DisableAllAnimations -bool true

        # Disable animations when opening Quick Look windows
        defaults write -g QLPanelAnimationDuration -float 0

        # Disable animation when opening the Info window in Finder
        defaults write com.apple.finder DisableAllAnimations -bool true

        # Disable animations when opening applications
        defaults write com.apple.dock springboard-show-duration -float 0
        defaults write com.apple.dock springboard-hide-duration -float 0

        # Restart affected applications
        killall Dock
        killall Finder

        echo "✅ All animation effects disabled."
    else
        echo "Skipping animation effects disabling."
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
clear_diagnostic_reports # Added new step
check_large_files # Shifted from 15 to 16
verify_disk # Shifted from 16 to 17
check_crash_logs # Shifted from 17 to 18
check_finder_logs # Shifted from 18 to 19
free_startup_disk_space # Shifted from 19 to 20
disable_login_items # Shifted from 20 to 21
fix_battery_drain # Added new step
fix_wifi # Added new step
disable_animations # Added new step

# --- Final Advice ---
echo -e "\n🏁 System Fix Script Finished! 🏁"
echo "------------------------------------"
echo "Additional steps if issues persist:"
echo "  🔹 Restart your Mac"
echo "  🔹 Check for macOS updates: System Settings > General > Software Update"
echo "  🔹 Boot into Safe Mode: Hold Shift during startup"
echo "  🔹 Run Apple Diagnostics: Hold 'D' during startup"
echo "  🔹 Check Activity Monitor for problematic processes"
echo "  🔹 Try creating a new user account to test apps"
echo "  🔹 Reinstall problematic applications"
echo "  🔹 Consider reinstalling macOS if problems continue"
echo ""
echo "For persistent disk space issues:"
echo "  🔹 Use Storage Management: Apple Menu > About This Mac > More Info > Storage Settings"
echo "  🔹 Move large files to external storage"
echo "  🔹 Use cloud storage for documents and photos"
echo "  🔹 Uninstall unused applications"

# Clean up admin privileges keep-alive
if [[ -n "$ADMIN_KEEP_ALIVE_PID" ]]; then
    kill "$ADMIN_KEEP_ALIVE_PID"
fi

echo "✅ All selected operations complete."
