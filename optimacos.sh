#!/bin/bash

# --- Configuration ---
LOG_RETENTION_DAYS=7 # How many days of system logs to keep
LARGE_FILE_SIZE_GB=1 # Size in GB to consider a file "large"
DEFAULT_YES=false    # Set to true for default "yes" in prompts
VERBOSE=true         # Set to false to reduce output verbosity
RUN_ALL=false        # Set to true to run all tasks without prompting
SCRIPT_VERSION="1.0.0" # Version of this script
START_TIME=$(date +%s) # For calculating total execution time

# --- Helper Functions ---
ask_yes_no() {
    # Skip prompting if RUN_ALL is enabled
    if [[ "$RUN_ALL" == true ]]; then
        return 0
    fi

    # Skip if non-interactive mode
    if [[ ! -t 0 ]]; then
        return 1
    fi

    local prompt="$1"
    local default_option="n"

    if [[ "$DEFAULT_YES" == true ]]; then
        prompt="$1 [Y/n]: "
        default_option="y"
    else
        prompt="$1 [y/N]: "
        default_option="n"
    fi

    while true; do
        read -p "$prompt" yn
        yn=${yn:-$default_option}
        case $yn in
            [Yy]* ) return 0;; # Yes
            [Nn]* ) return 1;; # No
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Detect operating system version
detect_os_version() {
    OS_VERSION=$(sw_vers -productVersion)
    OS_MAJOR_VERSION=$(echo "$OS_VERSION" | cut -d. -f1)
    OS_MINOR_VERSION=$(echo "$OS_VERSION" | cut -d. -f2)

    if [[ "$VERBOSE" == true ]]; then
        echo "Detected macOS version: $OS_VERSION (Major: $OS_MAJOR_VERSION, Minor: $OS_MINOR_VERSION)"
    fi
}

# Runs at script start
initialize_script() {
    detect_os_version
    check_disk_space
}

# Check available disk space
check_disk_space() {
    local available_space=$(df -h / | awk 'NR==2 {print $4}')
    echo "Available disk space: $available_space"

    # Convert to bytes for comparison if needed
    local available_bytes=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_bytes -lt 1048576 ]]; then # Less than 1GB
        echo "⚠️ WARNING: Low disk space. Some operations may fail."
    fi
}

# Print section header
print_section_header() {
    local emoji="$1"
    local section_num="$2"
    local title="$3"
    local separator_line=""

    # Generate separator line matching title length
    for ((i=0; i<${#title}+4; i++)); do
        separator_line+="-"
    done

    echo -e "\n$emoji Section $section_num: $title"
    echo "$separator_line"
}

# Show task result status
check_status() {
    local message="$1"
    local task_name="$2"
    local exit_code="${3:-$?}"

    if [ $exit_code -eq 0 ]; then
        echo "✅ $message"
    else
        echo "❌ Error in $task_name: exit code $exit_code"
    fi

    return $exit_code
}

# Execute command with error handling
run_command() {
    local cmd="$1"
    local success_msg="$2"
    local task_name="$3"

    if [[ "$VERBOSE" == true ]]; then
        echo "Executing: $cmd"
    fi

    eval "$cmd"
    check_status "$success_msg" "$task_name"
    return $?
}

# --- Main Script ---
echo "🚀 macOS System Fix & Optimization Script v$SCRIPT_VERSION 🚀"
echo "-----------------------------------------"
echo "This script focuses on resolving Finder not responding, app crashes, launching issues, and startup disk space problems."
echo "It also includes performance optimization steps and bulk user creation functionality."
echo "⚠️ IMPORTANT: Close all applications before proceeding for best results."
echo "Some operations require administrator privileges."
echo "Start time: $(date)"
echo

# Initialize script environment
initialize_script

# Print script banner
cat << "EOF"
  ___  __  __  ____  ____  __  __    __    ___  _____  ____
 / __)(  \/  )(_  _)(_  _)(  \/  )  /__\  / __)(  _  )(_  _)
( (__  )    (  _)(_  _)(_  )    (  /(__)\( (__  )(_)(  _)(_
 \___)(_/\/\_)(____)(____)(_/\/\_)(__)(__)\___)(_____)(____)
EOF
echo

# Menu options
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --all       Run all optimizations without prompting"
    echo "  --verbose   Show detailed command output"
    echo "  --quiet     Minimize output messages"
    echo "  --yes       Default to 'yes' for all prompts"
    echo "  --help, -h  Show this help message"
    exit 0
fi

# Process command line options
for arg in "$@"; do
    case "$arg" in
        --all)      RUN_ALL=true ;;
        --verbose)  VERBOSE=true ;;
        --quiet)    VERBOSE=false ;;
        --yes)      DEFAULT_YES=true ;;
    esac
done

# Require admin privileges upfront and keep them alive
echo "Requesting administrator privileges..."
sudo -v
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
ADMIN_KEEP_ALIVE_PID=$! # Save PID to kill it later
echo "Administrator privileges granted."

# --- 1. Restart Finder ---
restart_finder() {
    print_section_header "📁" "1" "Restarting Finder"

    if ask_yes_no "Force quit and restart Finder?"; then
        echo "Restarting Finder..."
        run_command "killall Finder" "Finder restarted" "restart_finder"
    else
        echo "Skipping Finder restart."
    fi
}

# --- 2. Clear Finder Preferences ---
clear_finder_prefs() {
    print_section_header "🧹" "2" "Clearing Finder Preferences"

    if ask_yes_no "Delete Finder preferences? (This resets Finder settings to default)"; then
        echo "Removing Finder preferences..."
        run_command "rm -f ~/Library/Preferences/com.apple.finder.plist ~/Library/Preferences/com.apple.sidebarlists.plist && killall Finder" "Finder preferences cleared and Finder restarted" "clear_finder_prefs"
    else
        echo "Skipping Finder preferences clear."
    fi
}

# --- 3. Clear Caches ---
clear_caches() {
    print_section_header "🧹" "3" "Clearing Caches"

    if ask_yes_no "Clear User Caches including Finder-specific caches?"; then
        echo "Clearing User Caches..."
        run_command "rm -rf ~/Library/Caches/* ~/Library/Preferences/ByHost/com.apple.finder* ~/Library/Saved\ Application\ State/com.apple.finder.savedState" "User and Finder-specific caches cleared" "clear_user_caches"
    else
        echo "Skipping User Caches."
    fi

    if ask_yes_no "Clear System Caches? (requires admin privileges)"; then
        echo "Clearing System Caches..."
        run_command "sudo rm -rf /Library/Caches/* /System/Library/Caches/*" "System caches cleared" "clear_system_caches"
    else
        echo "Skipping System Caches."
    fi
}

# --- 4. Reset Launch Services Database ---
reset_launch_services() {
    print_section_header "🔄" "4" "Resetting Launch Services Database"

    if ask_yes_no "Reset Launch Services database? (This fixes app launch issues and duplicate apps)"; then
        echo "Resetting Launch Services database..."
        run_command "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user" "Launch Services database reset" "reset_launch_services"
    else
        echo "Skipping Launch Services reset."
    fi
}

# --- 5. Clear Application Saved States ---
clear_app_saved_states() {
    print_section_header "💾" "5" "Clearing Application Saved States"

    if ask_yes_no "Clear all application saved states? (Prevents apps from restoring corrupted states)"; then
        echo "Clearing application saved states..."
        run_command "rm -rf ~/Library/Saved\ Application\ State/*" "Application saved states cleared" "clear_app_saved_states"
    else
        echo "Skipping application saved states clear."
    fi
}

# --- 6. Reset Font Cache ---
reset_font_cache() {
    print_section_header "🔤" "6" "Resetting Font Cache"

    if ask_yes_no "Reset font cache? (Fixes font-related app crashes)"; then
        echo "Resetting font cache..."
        run_command "sudo atsutil databases -remove && atsutil server -shutdown && atsutil server -ping" "Font cache reset" "reset_font_cache"
    else
        echo "Skipping font cache reset."
    fi
}

# --- 7. Repair Disk Permissions ---
repair_permissions() {
    print_section_header "🔐" "7" "Repairing Disk Permissions"

    if ask_yes_no "Repair disk permissions? (Fixes app launch permission issues)"; then
        echo "Repairing disk permissions..."
        run_command "sudo diskutil resetUserPermissions / $(id -u)" "Disk permissions repaired" "repair_permissions"
    else
        echo "Skipping disk permissions repair."
    fi
}

# --- 8. Clear Quarantine Attributes ---
clear_quarantine() {
    print_section_header "🛡️" "8" "Clearing Quarantine Attributes"

    if ask_yes_no "Clear quarantine attributes from Applications folder? (Fixes 'app can't be opened' issues)"; then
        echo "Clearing quarantine attributes..."
        run_command "sudo xattr -rd com.apple.quarantine /Applications" "Quarantine attributes cleared from Applications folder" "clear_quarantine"
    else
        echo "Skipping quarantine attributes clear."
    fi
}

# --- 9. Purge Inactive Memory ---
purge_memory() {
    print_section_header "🧠" "9" "Purging Inactive Memory"

    if ask_yes_no "Run 'sudo purge' to free inactive RAM?"; then
        echo "Purging inactive memory..."
        run_command "sudo purge" "Memory purged" "purge_memory"

        # Show memory stats after purge
        if [[ "$VERBOSE" == true ]]; then
            echo "Memory stats after purge:"
            vm_stat | grep -E "Pages free:|Pages active:|Pages inactive:|Pages speculative:|Pages wired down:"
        fi
    else
        echo "Skipping memory purge."
    fi
}

# --- 10. Flush DNS Cache ---
flush_dns() {
    print_section_header "🌐" "10" "Flushing DNS Cache"

    if ask_yes_no "Flush DNS Cache?"; then
        echo "Flushing DNS cache..."
        run_command "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder" "DNS cache flushed" "flush_dns"
    else
        echo "Skipping DNS cache flush."
    fi
}

# --- 11. Re-index Spotlight ---
reindex_spotlight() {
    print_section_header "🔦" "11" "Re-indexing Spotlight"

    if ask_yes_no "Re-index Spotlight for the main drive?"; then
        echo "Starting Spotlight re-indexing for / ..."
        run_command "sudo mdutil -E /" "Spotlight re-indexing initiated" "reindex_spotlight"
    else
        echo "Skipping Spotlight re-indexing."
    fi
}

# --- 12. Run System Maintenance Scripts ---
run_maintenance_scripts() {
    print_section_header "🛠️" "12" "Running System Maintenance Scripts"

    if ask_yes_no "Run system maintenance scripts?"; then
        echo "Running periodic maintenance scripts..."
        run_command "sudo periodic daily weekly monthly" "System maintenance scripts executed" "run_maintenance_scripts"
    else
        echo "Skipping system maintenance scripts."
    fi
}

# --- 13. Thin Time Machine Local Snapshots ---
thin_local_snapshots() {
    print_section_header "💾" "13" "Thinning Time Machine Local Snapshots"

    # Check if Time Machine is enabled
    local tm_enabled=false
    if tmutil status 2>/dev/null | grep -q "Backup"; then
        tm_enabled=true
    fi

    if [[ "$tm_enabled" == true ]] && ask_yes_no "Thin Time Machine local snapshots?"; then
        echo "Thinning local snapshots..."
        # Thin local snapshots older than 4 hours, trying to free up to 100GB
        run_command "sudo tmutil thinlocalsnapshots / 100000000000 4" "Local snapshots thinning process initiated" "thin_local_snapshots"
    else
        if [[ "$tm_enabled" == false ]]; then
            echo "Time Machine not enabled. Skipping thinning local snapshots."
        else
            echo "Skipping thinning local snapshots."
        fi
    fi
}

# --- 14. Delete Old System Logs ---
delete_old_logs() {
    print_section_header "🧼" "14" "Deleting Old System Logs"

    if ask_yes_no "Delete system logs older than ${LOG_RETENTION_DAYS} days?"; then
        echo "Deleting system logs..."
        run_command "sudo find /private/var/log -type f -mtime +${LOG_RETENTION_DAYS} -delete" "Old system logs deleted" "delete_old_logs"

        # Show space saved if verbose
        if [[ "$VERBOSE" == true ]]; then
            echo "Current log directory size:"
            sudo du -sh /private/var/log
        fi
    else
        echo "Skipping old system log deletion."
    fi
}

# --- 15. Clear Old Diagnostic Reports ---
clear_diagnostic_reports() {
    print_section_header "📋" "15" "Clearing Old Diagnostic Reports"

    if ask_yes_no "Delete old application diagnostic reports and crash logs? (Can free space and improve responsiveness)"; then
        echo "Clearing old diagnostic reports..."

        # Check if the directory exists and clean it
        if [ -d ~/Library/Logs/DiagnosticReports ]; then
            # Count files before deletion if verbose
            if [[ "$VERBOSE" == true ]]; then
                local file_count=$(find ~/Library/Logs/DiagnosticReports -type f | wc -l)
                echo "Found $file_count diagnostic report files"
            fi

            run_command "find ~/Library/Logs/DiagnosticReports -mindepth 1 -delete" "Old diagnostic reports cleared" "clear_diagnostic_reports"
        else
            echo "No DiagnosticReports directory found."
        fi
    else
        echo "Skipping diagnostic reports clear."
    fi
}

# --- 16. Disable Crash Reporter Prompts ---
disable_crash_reporter() {
    print_section_header "❌" "16" "Disable Crash Reporter Prompts"

    if ask_yes_no "Disable dialog prompts when applications crash? (Logs are still recorded)"; then
        echo "Disabling Crash Reporter prompts..."
        run_command "defaults write com.apple.CrashReporter DialogType none" "Crash Reporter prompts disabled" "disable_crash_reporter"

        # Show current setting if verbose
        if [[ "$VERBOSE" == true ]]; then
            echo "Current CrashReporter DialogType setting:"
            defaults read com.apple.CrashReporter DialogType 2>/dev/null || echo "Setting not found (using default)"
        fi
    else
        echo "Skipping disabling Crash Reporter prompts."
    fi
}

# --- 17. Clear Old User Logs ---
clear_user_logs() {
    print_section_header "🧼" "17" "Deleting Old User Logs"

    if ask_yes_no "Delete user logs (in ~/Library/Logs) older than ${LOG_RETENTION_DAYS} days?"; then
        echo "Deleting user logs..."
        if [ -d ~/Library/Logs ]; then
            # Count files to be deleted if verbose
            if [[ "$VERBOSE" == true ]]; then
                local file_count=$(find ~/Library/Logs -type f -mtime +${LOG_RETENTION_DAYS} | wc -l)
                echo "Found $file_count log files older than ${LOG_RETENTION_DAYS} days"
            fi

            run_command "find ~/Library/Logs -type f -mtime +${LOG_RETENTION_DAYS} -delete" "Old user logs deleted" "clear_user_logs"
        else
            echo "No User Logs directory found."
        fi
    else
        echo "Skipping user log deletion."
    fi
}

# --- 18. Check for Large Files ---
check_large_files() {
    print_section_header "🗂️" "18" "Checking for Large Files"

    if ask_yes_no "Scan Home folder for files larger than ${LARGE_FILE_SIZE_GB}GB?"; then
        echo "Searching for large files..."

        # Create a temporary file for the results
        local tmp_file=$(mktemp)

        # Search for large files and save results
        find ~ -type f -size +${LARGE_FILE_SIZE_GB}G -print0 2>/dev/null |
            xargs -0 -I {} du -sh {} 2>/dev/null > "$tmp_file"

        # Display results
        echo "Files larger than ${LARGE_FILE_SIZE_GB}GB:"
        if [ -s "$tmp_file" ]; then
            cat "$tmp_file" | sort -hr

            # Count and summarize if verbose
            if [[ "$VERBOSE" == true ]]; then
                local file_count=$(cat "$tmp_file" | wc -l)
                echo "Found $file_count large files"
            fi
        else
            echo "No files larger than ${LARGE_FILE_SIZE_GB}GB found."
        fi

        rm "$tmp_file"
        check_status "Large file check complete" "check_large_files"
    else
        echo "Skipping large file check."
    fi
}

# --- 19. Verify Startup Disk ---
verify_disk() {
    print_section_header "💿" "19" "Verifying Startup Disk"

    if ask_yes_no "Verify the startup disk for errors? (Does not repair)"; then
        echo "Verifying startup disk..."

        # Get the startup disk identifier
        local startup_disk=$(df / | awk 'NR==2 {print $1}')

        if [ -n "$startup_disk" ]; then
            echo "Startup disk identified as: $startup_disk"

            if sudo diskutil verifyVolume "$startup_disk"; then
                echo "✅ Startup disk verification complete. No errors found."
            else
                echo "⚠️ Startup disk verification reported errors. Consider running 'diskutil repairVolume $startup_disk' from Recovery Mode."
            fi
        else
            echo "❌ Could not determine startup disk identifier."
        fi
    else
        echo "Skipping startup disk verification."
    fi
}

# --- 20. Check System Logs for App Crashes ---
check_crash_logs() {
    print_section_header "📋" "20" "Checking System Logs for App Crashes"

    if ask_yes_no "Check recent system logs for application crashes?"; then
        echo "Extracting recent application crash logs..."

        # Create a temporary log file with timestamp
        local log_file=~/Desktop/app_crash_log_check_$(date +%Y%m%d_%H%M%S).txt

        # Add header to the log file
        echo "Application Crash Log Check - $(date)" > "$log_file"
        echo "=======================================" >> "$log_file"
        echo "" >> "$log_file"

        # Look for 'crashed' in the last 1 hour, filter for keywords
        log show --predicate 'eventMessage contains "crashed"' --last 1h 2>/dev/null |
            grep -i "crash\|error\|exception" >> "$log_file" || true

        if [ -s "$log_file" ] && [ $(wc -l < "$log_file") -gt 3 ]; then
            echo "⚠️ Found potential application crashes. Check $log_file for details."

            # Count crashes if verbose
            if [[ "$VERBOSE" == true ]]; then
                local crash_count=$(grep -c -i "crashed" "$log_file")
                echo "Found approximately $crash_count application crash events"
            fi
        else
            echo "✅ No recent application crashes found in logs."
            rm "$log_file"
        fi
    else
        echo "Skipping application crash log check."
    fi
}

# --- 21. Check Finder Logs ---
check_finder_logs() {
    print_section_header "📋" "21" "Checking Finder Logs"

    if ask_yes_no "Check recent Finder-related system logs for errors?"; then
        echo "Extracting recent Finder-related logs..."

        # Create a temporary log file with timestamp
        local log_file=~/Desktop/finder_log_check_$(date +%Y%m%d_%H%M%S).txt

        # Add header to the log file
        echo "Finder Log Check - $(date)" > "$log_file"
        echo "===========================" >> "$log_file"
        echo "" >> "$log_file"

        # Look for 'Finder' process logs in the last 1 hour, filter for errors/crashes
        log show --predicate 'process == "Finder"' --last 1h 2>/dev/null |
            grep -i "error\|crash" >> "$log_file" || true

        if [ -s "$log_file" ] && [ $(wc -l < "$log_file") -gt 3 ]; then
            echo "⚠️ Found potential Finder issues. Check $log_file for details."

            # Show error count if verbose
            if [[ "$VERBOSE" == true ]]; then
                local error_count=$(grep -c -i "error\|crash" "$log_file")
                echo "Found approximately $error_count Finder error/crash events"
            fi
        else
            echo "✅ No recent Finder errors or crashes found in logs."
            rm "$log_file"
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
    print_section_header "😴" "23" "Disabling Login Items (Optional)"

    if ask_yes_no "Disable non-essential login items to speed up login?"; then
        echo "Disabling non-essential login items..."

        # List current login items if possible
        if [[ "$VERBOSE" == true ]]; then
            echo "Current login items:"
            osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null ||
                echo "Could not retrieve login items programmatically"
        fi

        # This requires manual intervention, guide the user
        echo "Instructions:"
        echo "  1. Open System Settings -> General -> Login Items"
        echo "  2. Review the list of startup items"
        echo "  3. Click the '-' button to remove unnecessary items"
        echo "  4. Keep essential items like security software"
        echo "✅ Remember to re-enable essential login items later if needed."

        # If supported, open the preference pane directly
        if ask_yes_no "Open Login Items preferences now?"; then
            open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        fi
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
        defaults write com.apple.dock springboard-show-duration -float 0 # Springboard keys less relevant
        defaults write com.apple.dock springboard-hide-duration -float 0 # Springboard keys less relevant

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

# --- 30. System Performance Optimization ---
optimize_system_performance() {
    print_section_header "⚡" "30" "System Performance Optimization"

    if ask_yes_no "Optimize system performance settings?"; then
        echo "Optimizing system performance..."

        # Create a temporary file for sysctl settings
        local tmp_sysctl=$(mktemp)
        cat > "$tmp_sysctl" << EOF
kern.ipc.somaxconn=2048
kern.ipc.nmbclusters=65536
kern.maxvnodes=750000
kern.maxproc=2048
kern.maxfiles=200000
kern.maxfilesperproc=100000
EOF

        # Apply all settings at once for efficiency
        run_command "sudo sysctl -w $(cat $tmp_sysctl | tr '\n' ' ')" "System performance optimized" "optimize_system_performance"
        rm "$tmp_sysctl"

        # Show current settings if verbose
        if [[ "$VERBOSE" == true ]]; then
            echo "Current system settings:"
            sudo sysctl kern.ipc.somaxconn kern.ipc.nmbclusters kern.maxvnodes kern.maxproc kern.maxfiles kern.maxfilesperproc
        fi
    else
        echo "Skipping system performance optimization."
    fi
}

# --- 31. Memory Management Optimization ---
optimize_memory_management() {
    print_section_header "🧠" "31" "Memory Management Optimization"

    if ask_yes_no "Optimize memory management settings?"; then
        echo "Optimizing memory management..."

        # Create a combined command for all memory operations
        local cmd="sudo purge && \
                  sudo pmset -a sms 0 && \
                  sudo sysctl -w kern.maxvnodes=750000 kern.maxproc=2048 kern.maxfiles=200000 kern.maxfilesperproc=100000 && \
                  sudo sync && \
                  sudo purge"

        run_command "$cmd" "Memory management optimized" "optimize_memory_management"

        # Show memory stats after optimization
        if [[ "$VERBOSE" == true ]]; then
            echo "Memory stats after optimization:"
            vm_stat | head -10
        fi
    else
        echo "Skipping memory management optimization."
    fi
}

# --- 32. SSD Optimization ---
optimize_ssd() {
    print_section_header "💽" "32" "SSD Optimization"

    # Check if system has an SSD
    local has_ssd=false
    if system_profiler SPStorageDataType 2>/dev/null | grep -q "SSD"; then
        has_ssd=true
        echo "SSD detected in system."
    fi

    if [[ "$has_ssd" == true ]] && ask_yes_no "Optimize SSD settings? (Recommended for SSD drives)"; then
        echo "Optimizing SSD settings..."

        # Combined SSD optimization command
        run_command "sudo trimforce enable && sudo pmset -a hibernatemode 0 && sudo rm -f /var/vm/sleepimage 2>/dev/null || true" "SSD optimized" "optimize_ssd"

        # Check and report sleep image status
        if [[ "$VERBOSE" == true ]]; then
            if [ ! -f /var/vm/sleepimage ]; then
                echo "Sleep image successfully removed."
            fi
            echo "Current hibernation mode: $(pmset -g | grep hibernatemode)"
        fi
    else
        if [[ "$has_ssd" == false ]]; then
            echo "No SSD detected. Skipping SSD optimization."
        else
            echo "Skipping SSD optimization."
        fi
    fi
}

# --- 33. Security Optimization ---
optimize_security() {
    print_section_header "🔒" "33" "Security Settings Optimization"

    if ask_yes_no "Optimize security settings (enable firewall and stealth mode)?"; then
        echo "Optimizing security settings..."

        # Combined security settings command
        run_command "sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1 && \
                    sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1 && \
                    sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -int 1 && \
                    sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null && \
                    sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist" \
                    "Security settings optimized" "optimize_security"

        # Verify firewall status
        if [[ "$VERBOSE" == true ]]; then
            echo "Current firewall status:"
            sudo defaults read /Library/Preferences/com.apple.alf globalstate
            echo "Stealth mode status:"
            sudo defaults read /Library/Preferences/com.apple.alf stealthenabled
        fi
    else
        echo "Skipping security optimization."
    fi
}

# --- Function Array for Execution ---
# --- 29. Bulk User Creation ---
bulk_user_creation() {
    print_section_header "👥" "29" "Bulk User Creation"

    if ask_yes_no "Create multiple users in bulk?"; then
        echo "Bulk user creation options:"
        echo "  • Count: Number of users to create"
        echo "  • Prefix: Username prefix (default: user)"
        echo "  • Shell: Shell for new users (default: /bin/bash)"
        echo "  • Create home directories: Yes/No"
        echo "  • Disable Spotlight: Yes/No"
        echo "  • Set password: Optional password for all users"
        echo ""

        read -p "Enter number of users to create: " USER_COUNT
        read -p "Enter username prefix (default: user): " PREFIX
        read -p "Enter shell path (default: /bin/bash): " USER_SHELL
        read -p "Enter group ID (optional): " GROUP_ID

        # Set defaults
        USER_COUNT="${USER_COUNT:-0}"
        PREFIX="${PREFIX:-user}"
        USER_SHELL="${USER_SHELL:-/bin/bash}"

        if [[ "${USER_COUNT}" -le 0 ]]; then
            echo "❌ Invalid user count. Skipping bulk user creation."
            return
        fi

        # Options
        MKDIRS=""
        DISABLE_SPOTLIGHT=""
        USER_PASSWORD=""
        DISABLE_PASSWORDS=""
        ALL_SUDOERS=""

        if ask_yes_no "Create home directories for users?"; then
            MKDIRS=1
        fi

        if ask_yes_no "Disable Spotlight for new users?"; then
            DISABLE_SPOTLIGHT=1
        fi

        read -p "Set password for all users (leave empty for no password): " USER_PASSWORD

        if ask_yes_no "Disable passwords globally? (INSECURE)"; then
            DISABLE_PASSWORDS=1
        fi

        if ask_yes_no "Make all users sudoers? (EXTREMELY INSECURE)"; then
            ALL_SUDOERS=1
        fi

        echo "Creating ${USER_COUNT} users with prefix '${PREFIX}'..."

        # Fetch the next available UniqueID
        CURRENT_MAX_USER="$(dscl . -list /Users UniqueID | awk -F\  '{ print $2 }' | sort -n | tail -n1)"
        CURRENT_MAX_USER="${CURRENT_MAX_USER:=501}"

        STARTING_FROM="$((CURRENT_MAX_USER+1))"
        NEXT_USER="${STARTING_FROM}"
        ENDING_AT="$((NEXT_USER+${USER_COUNT}))"

        echo "Starting from UID: ${STARTING_FROM}"
        echo "Ending at UID: ${ENDING_AT}"

        USER_ARRAY=($(seq "${STARTING_FROM}" "$((ENDING_AT-1))"))

        # Create users efficiently using a combined approach
        local created_count=0
        for USER_ID in "${USER_ARRAY[@]}"; do
            REAL_NAME="${PREFIX}${USER_ID}"
            echo "Creating user: ${REAL_NAME} (${created_count+1}/${USER_COUNT})"

            # Use a single combined command with error handling
            if ! (sysadminctl -addUser "${REAL_NAME}" -fullName "${REAL_NAME}" \
                 -UID "${USER_ID}" ${GROUP_ID:+-GID "${GROUP_ID}"} \
                 -shell "${USER_SHELL}" -password '' \
                 -home "/Users/${REAL_NAME}" 2>/dev/null); then

                # Fallback to dscl method if sysadminctl fails
                echo "⚠️ Using alternative creation method for ${REAL_NAME}..."
                (sudo dscl . -create "/Users/${REAL_NAME}" && \
                 sudo dscl . -create "/Users/${REAL_NAME}" UserShell "${USER_SHELL}" && \
                 sudo dscl . -create "/Users/${REAL_NAME}" RealName "${REAL_NAME}" && \
                 sudo dscl . -create "/Users/${REAL_NAME}" UniqueID "${USER_ID}" && \
                 sudo dscl . -create "/Users/${REAL_NAME}" PrimaryGroupID "${GROUP_ID:-20}" && \
                 sudo dscl . -create "/Users/${REAL_NAME}" NFSHomeDirectory "/Users/${REAL_NAME}") || \
                 { echo "❌ Failed to create user ${REAL_NAME}"; continue; }
            fi

            # Create home directory if it doesn't exist
            sudo mkdir -p "/Users/${REAL_NAME}" 2>/dev/null || true
            created_count=$((created_count+1))
        done

        # Configure all users in batch operations where possible
        echo "Configuring ${created_count} users..."

        # Setup variables for optimization
        sw_vers="$(sw_vers -productVersion)"
        sw_build="$(sw_vers -buildVersion)"

        # Find all newly created users' directories
        local processed=0
        for USER_DIR in /Users/*; do
            case "${USER_DIR}" in
                /Users/administrator ) continue ;;
                /Users/user ) continue ;;
                /Users/Guest ) continue ;;
                /Users/Shared ) continue ;;
                "/Users/$(whoami)" ) continue ;;
            esac

            REAL_NAME="$(basename "${USER_DIR}")"

            # Skip if not one of our created users
            [[ "${REAL_NAME}" =~ ^${PREFIX}[0-9]+$ ]] || continue

            USER_ID="${REAL_NAME//[^[:digit:]]/}"
            processed=$((processed+1))

            echo -ne "Configuring user ${processed}/${created_count}: ${REAL_NAME}\r"

            # Create home directory and set permissions
            if [[ "${MKDIRS}" ]]; then
                sudo mkdir -p "${USER_DIR}/Library/Preferences" 2>/dev/null || true
                sudo chown -R "${REAL_NAME}:${USER_ID}" "${USER_DIR}" 2>/dev/null || true
            fi

            # Set password if specified
            if [[ "${USER_PASSWORD}" ]]; then
                sudo dscl . -passwd "/Users/${REAL_NAME}" "${USER_PASSWORD}" 2>/dev/null || true
            fi

            # Disable spotlight if requested
            if [[ "${DISABLE_SPOTLIGHT}" ]]; then
                sudo -u "${REAL_NAME}" mdutil -i off -a 2>/dev/null || true
            fi

            # Disable passwords if requested
            if [[ "${DISABLE_PASSWORDS}" ]]; then
                sudo tee "/etc/sudoers.d/${REAL_NAME}" <<< "${REAL_NAME}     ALL=(ALL)       NOPASSWD: ALL" > /dev/null
            fi

            # Skip setup assistant - Using a more efficient approach with fewer commands
            sudo chmod 700 "/Users/${REAL_NAME}/Library" 2>/dev/null || true

            # Use a single defaults write command for each domain for efficiency
            if [[ "$VERBOSE" == true ]]; then
                echo "Setting up preferences for ${REAL_NAME}..."
            fi

            # Create setup assistant preference files with all settings at once using here documents
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipAppearance -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipCloudSetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipiCloudStorageSetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipPrivacySetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipSiriSetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipTrueTone -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipScreenTime -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipTouchIDSetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed SkipFirstLoginOptimization -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed DidSeeCloudSetup -bool true 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastPrivacyBundleVersion "2" 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenCloudProductVersion "${sw_vers}" 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenDiagnosticsProductVersion "${sw_vers}" 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenSiriProductVersion "${sw_vers}" 2>/dev/null || true
            sudo -u "${REAL_NAME}" defaults write com.apple.SetupAssistant.managed LastSeenBuddyBuildVersion "${sw_build}" 2>/dev/null || true
        done
        echo # New line after progress output

        # Make everyone a sudo user if requested - do this once at the end
        if [[ "${ALL_SUDOERS}" ]]; then
            echo "⚠️ Making all users sudoers (EXTREMELY INSECURE)"
            sudo sed -i -e s/required/optional/g /etc/pam.d/* 2>/dev/null || true
            sudo sed -i -e s/sufficient/optional/g /etc/pam.d/* 2>/dev/null || true
        fi

        check_status "Bulk user creation completed. Created ${created_count} users." "bulk_user_creation"
    else
        echo "Skipping bulk user creation."
    fi
}

FUNCTIONS=(
    "restart_finder"
    "clear_finder_prefs"
    "clear_caches"
    "reset_launch_services"
    "clear_app_saved_states"
    "reset_font_cache"
    "repair_permissions"
    "clear_quarantine"
    "purge_memory"
    "flush_dns"
    "reindex_spotlight"
    "run_maintenance_scripts"
    "thin_local_snapshots"
    "delete_old_logs"
    "clear_diagnostic_reports"
    "disable_crash_reporter"
    "clear_user_logs"
    "check_large_files"
    "verify_disk"
    "check_crash_logs"
    "check_finder_logs"
    "free_startup_disk_space"
    "disable_login_items"
    "fix_battery_drain"
    "fix_wifi"
    "disable_animations"
    "reduce_visual_effects"
    "keep_software_updated"
    "bulk_user_creation"
    "optimize_system_performance"
    "optimize_memory_management"
    "optimize_ssd"
    "optimize_security"
)

# Run selected functions
if [[ "$RUN_ALL" == true ]]; then
    echo "Running all optimization functions..."
    for func in "${FUNCTIONS[@]}"; do
        $func
    done
else
    # Offer different execution modes
    echo "Select execution mode:"
    echo "1. Run all functions"
    echo "2. Run selected categories"
    echo "3. Run individual functions"
    read -p "Enter your choice (1-3) [1]: " execution_mode
    execution_mode=${execution_mode:-1}

    case $execution_mode in
        1)
            # Run all functions
            echo "Running all optimization functions..."
            for func in "${FUNCTIONS[@]}"; do
                $func
            done
            ;;

        2)
            # Run by categories
            echo "Select categories to run:"

            if ask_yes_no "Run System Performance functions?"; then
                echo "Running system performance optimizations..."
                restart_finder
                purge_memory
                optimize_system_performance
                optimize_memory_management
                optimize_ssd
            fi

            if ask_yes_no "Run Cleanup functions?"; then
                echo "Running cleanup functions..."
                clear_caches
                clear_app_saved_states
                reset_font_cache
                delete_old_logs
                clear_diagnostic_reports
                clear_user_logs
                thin_local_snapshots
            fi

            if ask_yes_no "Run System Maintenance functions?"; then
                echo "Running system maintenance functions..."
                reset_launch_services
                repair_permissions
                flush_dns
                reindex_spotlight
                run_maintenance_scripts
                verify_disk
            fi

            if ask_yes_no "Run UI Optimization functions?"; then
                echo "Running UI optimization functions..."
                disable_animations
                reduce_visual_effects
                disable_login_items
            fi

            if ask_yes_no "Run Security functions?"; then
                echo "Running security functions..."
                clear_quarantine
                optimize_security
            fi

            if ask_yes_no "Run Diagnostic functions?"; then
                echo "Running diagnostic functions..."
                check_large_files
                check_crash_logs
                check_finder_logs
            fi

            if ask_yes_no "Run Bulk User Creation?"; then
                bulk_user_creation
            fi
            ;;

        3)
            # Run individual functions
            echo "Select individual functions to run:"
            for func in "${FUNCTIONS[@]}"; do
                if ask_yes_no "Run ${func}?"; then
                    $func
                fi
            done
            ;;

        *)
            echo "Invalid choice. Running all functions..."
            for func in "${FUNCTIONS[@]}"; do
                $func
            done
            ;;
    esac
fi

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

# Calculate execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
MINUTES=$((EXECUTION_TIME / 60))
SECONDS=$((EXECUTION_TIME % 60))

# Clean up admin privileges keep-alive
if [[ -n "$ADMIN_KEEP_ALIVE_PID" ]]; then
    kill "$ADMIN_KEEP_ALIVE_PID" 2>/dev/null
fi

# Display final summary
echo -e "\n✅ Optimization Complete! ✅"
echo "--------------------------"
echo "Time completed: $(date)"
echo "Total execution time: ${MINUTES}m ${SECONDS}s"
echo ""
echo "System information:"
echo "  - macOS version: $(sw_vers -productVersion)"
echo "  - Build: $(sw_vers -buildVersion)"
echo "  - Available disk space: $(df -h / | awk 'NR==2 {print $4}')"
echo "  - Memory stats: $(vm_stat | grep 'Pages free' | awk '{print $3}' | sed 's/\.//') free pages"
echo ""
echo "Thank you for using the macOS System Fix & Optimization Script!"
echo "Report any issues to: https://github.com/sickcodes/osx-optimizer"
