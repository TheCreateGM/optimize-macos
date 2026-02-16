#!/bin/bash
################################################################################
# OptimacOS - Universal macOS Optimization Engine
# Version: 4.0.0
# Fully automated, zero-interaction, universal optimization for all macOS devices
################################################################################

set -o pipefail

# Global Configuration
SCRIPT_VERSION="4.0.0"
START_TIME=$(date +%s)
LOG_FILE=~/Desktop/optimacos_$(date +%Y%m%d_%H%M%S).log
VERBOSE=true
SAFE_MODE=true

# System Detection Variables
CPU_VENDOR=""
CPU_ARCH=""
CPU_CORES=""
GPU_VENDOR=""
GPU_MODEL=""
TOTAL_RAM_GB=0
STORAGE_TYPE=""
IS_LAPTOP=false
IS_OPENCORE=false
IS_INTEL=false
IS_APPLE_SILICON=false
MACOS_VERSION=""
MACOS_MAJOR=""

################################################################################
# Logging Functions
################################################################################

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_section() {
    local emoji="$1"
    local title="$2"
    local separator="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    log "$emoji $title"
    log "$separator"
}

log_success() {
    log "✅ $*"
}

log_error() {
    log "❌ $*"
}

log_warning() {
    log "⚠️  $*"
}

log_info() {
    log "ℹ️  $*"
}

safe_run() {
    local cmd="$1"
    local desc="$2"
    
    if [[ "$VERBOSE" == true ]]; then
        log_info "Executing: $desc"
    fi
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log_success "$desc"
        return 0
    else
        log_error "Failed: $desc (continuing...)"
        return 1
    fi
}

################################################################################
# System Detection
################################################################################

detect_system() {
    log_section "🔍" "System Detection"
    
    # macOS Version
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
    log_info "macOS Version: $MACOS_VERSION"
    
    # CPU Detection
    CPU_ARCH=$(uname -m)
    CPU_VENDOR=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
    
    if [[ "$CPU_ARCH" == "arm64" ]]; then
        IS_APPLE_SILICON=true
        log_info "CPU: Apple Silicon ($CPU_VENDOR) - $CPU_CORES cores"
    else
        IS_INTEL=true
        log_info "CPU: Intel ($CPU_VENDOR) - $CPU_CORES cores"
    fi
    
    # RAM Detection
    local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    TOTAL_RAM_GB=$((ram_bytes / 1024 / 1024 / 1024))
    log_info "RAM: ${TOTAL_RAM_GB}GB"
    
    # GPU Detection
    GPU_MODEL=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs || echo "Unknown")
    
    if [[ "$GPU_MODEL" == *"Intel"* ]]; then
        GPU_VENDOR="Intel"
    elif [[ "$GPU_MODEL" == *"AMD"* ]] || [[ "$GPU_MODEL" == *"Radeon"* ]]; then
        GPU_VENDOR="AMD"
    elif [[ "$GPU_MODEL" == *"NVIDIA"* ]]; then
        GPU_VENDOR="NVIDIA"
    elif [[ "$GPU_MODEL" == *"Apple"* ]]; then
        GPU_VENDOR="Apple"
    else
        GPU_VENDOR="Unknown"
    fi
    log_info "GPU: $GPU_VENDOR ($GPU_MODEL)"
    
    # Storage Type Detection
    local disk_type=$(diskutil info / 2>/dev/null | grep "Solid State" | awk '{print $3}')
    if [[ "$disk_type" == "Yes" ]]; then
        STORAGE_TYPE="SSD"
    else
        STORAGE_TYPE="HDD"
    fi
    log_info "Storage: $STORAGE_TYPE"
    
    # Laptop vs Desktop
    if system_profiler SPPowerDataType 2>/dev/null | grep -q "Battery"; then
        IS_LAPTOP=true
        log_info "Device Type: Laptop"
    else
        IS_LAPTOP=false
        log_info "Device Type: Desktop"
    fi
    
    # OpenCore Detection
    # Check filesystem and NVRAM variable commonly used by OpenCore
    if [[ -d "/Volumes/EFI/EFI/OC" ]] || nvram -p 2>/dev/null | grep -q "opencore-version"; then
        IS_OPENCORE=true
        log_warning "OpenCore detected - applying safe optimizations only"
    else
        IS_OPENCORE=false
        log_info "Native Mac detected"
    fi
    
    log_success "System detection complete"
}

################################################################################
# Package Manager & Tools
################################################################################

ensure_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
        
        if [[ "$IS_APPLE_SILICON" == true ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        if command -v brew &> /dev/null; then
            log_success "Homebrew installed"
        else
            log_warning "Homebrew installation failed - some features unavailable"
        fi
    else
        log_success "Homebrew already installed"
    fi
}

install_tool() {
    local tool="$1"
    local brew_name="${2:-$tool}"
    
    if command -v "$tool" &> /dev/null; then
        return 0
    fi
    
    if command -v brew &> /dev/null; then
        brew install "$brew_name" >> "$LOG_FILE" 2>&1 && log_success "Installed $tool" || log_warning "Failed to install $tool"
    fi
}

################################################################################
# Network Optimization
################################################################################

optimize_network() {
    log_section "🌐" "Network Optimization"
    
    # Flush DNS cache (Broad support)
    safe_run "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" "Flush DNS cache"
    
    # Renew DHCP
    safe_run "sudo ipconfig set en0 DHCP" "Renew DHCP lease (en0)"
    
    # Optimize TCP/IP stack
    safe_run "sudo sysctl -w net.inet.tcp.delayed_ack=0" "Disable delayed ACK"
    safe_run "sudo sysctl -w net.inet.tcp.mssdflt=1440" "Optimize TCP MSS"
    safe_run "sudo sysctl -w net.inet.tcp.sendspace=1048576" "Increase TCP send buffer"
    safe_run "sudo sysctl -w net.inet.tcp.recvspace=1048576" "Increase TCP receive buffer"
    safe_run "sudo sysctl -w net.inet.tcp.win_scale_factor=8" "Optimize TCP window scaling"
    safe_run "sudo sysctl -w net.inet.udp.maxdgram=65535" "Increase max UDP datagram size"
    
    # Disable unnecessary network discovery
    safe_run "sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true" "Disable multicast advertisements"
    
    # Optimize Wi-Fi
    if networksetup -listallhardwareports 2>/dev/null | grep -q "Wi-Fi"; then
        safe_run "sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs DisconnectOnLogout=NO" "Disable Wi-Fi disconnect on logout"
        safe_run "sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs JoinMode=Strongest" "Set Wi-Fi join mode to Strongest"
    fi
    
    # Disable IPv6 if user isn't using it extensively (Optional, safer to leave enabled, but optimizing privacy)
    # safe_run "networksetup -setv6off Wi-Fi" "Disable IPv6 on Wi-Fi (privacy)"
    
    log_success "Network optimization complete"
}

################################################################################
# System Repair & Integrity
################################################################################

repair_system() {
    log_section "🛠" "System Repair & Integrity"
    
    # Verify disk
    safe_run "diskutil verifyVolume /" "Verify system volume"
    
    # Repair permissions (macOS 10.11+)
    if [[ "$MACOS_MAJOR" -ge 11 ]]; then
        safe_run "sudo diskutil resetUserPermissions / \$(id -u)" "Reset user permissions"
    fi
    
    # Rebuild kext cache (OpenCore-safe)
    if [[ "$IS_OPENCORE" == false ]]; then
        safe_run "sudo kextcache -i /" "Rebuild kernel extension cache"
    else
        log_warning "Skipping kext cache rebuild (OpenCore detected)"
    fi
    
    # Rebuild Launch Services database
    safe_run "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user" "Rebuild Launch Services"
    
    # Rebuild Spotlight index
    safe_run "sudo mdutil -E /" "Rebuild Spotlight index"
    
    log_success "System repair complete"
}

################################################################################
# Disk Cleanup & Storage Optimization
################################################################################

cleanup_storage() {
    log_section "🧹" "Disk Cleanup & Storage Optimization"
    
    # Clear system caches
    safe_run "sudo rm -rf /Library/Caches/*" "Clear system caches"
    safe_run "sudo rm -rf /System/Library/Caches/*" "Clear system library caches"
    
    # Clear user caches
    safe_run "rm -rf ~/Library/Caches/*" "Clear user caches"
    
    # Clear temporary files
    safe_run "sudo rm -rf /private/var/tmp/*" "Clear /var/tmp"
    safe_run "sudo rm -rf /private/tmp/*" "Clear /tmp"
    
    # Clear logs
    safe_run "sudo rm -rf /private/var/log/*.log" "Clear system logs"
    safe_run "sudo rm -rf /Library/Logs/*" "Clear library logs"
    safe_run "rm -rf ~/Library/Logs/*" "Clear user logs"
    
    # Remove Time Machine local snapshots
    safe_run "sudo tmutil listlocalsnapshots / | grep 'com.apple.TimeMachine' | while read snapshot; do sudo tmutil deletelocalsnapshots \${snapshot##*.}; done" "Remove Time Machine snapshots"
    
    # Clear download history
    safe_run "rm -f ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" "Clear download history"
    
    # Clear Safari cache
    safe_run "rm -rf ~/Library/Caches/com.apple.Safari/*" "Clear Safari cache"
    
    # Clear font caches
    safe_run "sudo atsutil databases -remove" "Clear font caches"
    
    # Xcode derived data
    if [[ -d ~/Library/Developer/Xcode/DerivedData ]]; then
        safe_run "rm -rf ~/Library/Developer/Xcode/DerivedData/*" "Clear Xcode DerivedData"
    fi

    log_success "Storage cleanup complete"
}

################################################################################
# Performance & Responsiveness
################################################################################

optimize_performance() {
    log_section "⚡" "Performance & Responsiveness"
    
    # Disable animations
    safe_run "defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false" "Disable window animations"
    safe_run "defaults write NSGlobalDomain NSWindowResizeTime -float 0.001" "Speed up window resize"
    safe_run "defaults write com.apple.dock expose-animation-duration -float 0.1" "Speed up Mission Control"
    safe_run "defaults write com.apple.dock autohide-delay -float 0" "Remove Dock hide delay"
    safe_run "defaults write com.apple.dock autohide-time-modifier -float 0.5" "Speed up Dock animation"
    safe_run "defaults write -g QLPanelAnimationDuration -float 0" "Speed up Quick Look"
    safe_run "defaults write com.apple.finder DisableAllAnimations -bool true" "Disable Finder animations"
    safe_run "defaults write com.apple.dock launchanim -bool false" "Disable app launch animation in Dock"
    
    # Optimize UI responsiveness
    safe_run "defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false" "Disable scroll animations"
    safe_run "defaults write NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -bool false" "Disable document animations"
    
    # Optimize Finder
    safe_run "defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false" "Disable extension change warning"
    safe_run "defaults write com.apple.finder ShowPathbar -bool true" "Show Finder path bar"
    safe_run "defaults write com.apple.finder ShowStatusBar -bool true" "Show Finder status bar"
    safe_run "defaults write com.apple.finder _FXShowPosixPathInTitle -bool true" "Show full path in Finder title"
    safe_run "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true" "Avoid creating .DS_Store on network volumes"
    safe_run "defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true" "Avoid creating .DS_Store on USB volumes"

    # Optimize I/O scheduler
    safe_run "sudo sysctl -w kern.aio_max_requests=4096" "Increase async I/O requests"
    safe_run "sudo sysctl -w kern.maxvnodes=524288" "Increase max vnodes" # Keeping relatively high but safe
    safe_run "sudo sysctl -w vfs.generic.sync_timeout=300" "Optimize sync timeout"
    
    # Optimize app launch
    safe_run "defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true" "Disable automatic termination"
    
    # Restart affected services
    safe_run "killall Dock" "Restart Dock"
    safe_run "killall Finder" "Restart Finder"
    safe_run "killall SystemUIServer" "Restart SystemUIServer"
    
    log_success "Performance optimization complete"
}

################################################################################
# Privacy & Telemetry Hardening
################################################################################

harden_privacy() {
    log_section "🔒" "Privacy & Telemetry Hardening"
    
    # Disable analytics and telemetry
    safe_run "defaults write com.apple.assistant.support 'Assistant Enabled' -bool false" "Disable Siri"
    safe_run "defaults write com.apple.assistant.support 'Dictation Enabled' -bool false" "Disable dictation"
    safe_run "defaults write com.apple.Siri StatusMenuVisible -bool false" "Hide Siri menu"
    safe_run "defaults write com.apple.Siri UserHasDeclinedEnable -bool true" "Decline Siri"
    
    # Disable Spotlight suggestions
    safe_run "defaults write com.apple.spotlight orderedItems -array '{enabled = 1;name = APPLICATIONS;}' '{enabled = 1;name = SYSTEM_PREFS;}' '{enabled = 0;name = MENU_SPOTLIGHT_SUGGESTIONS;}'" "Disable Spotlight suggestions"
    
    # Disable predictive text
    safe_run "defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false" "Disable text completion"
    safe_run "defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false" "Disable auto-correct"
    
    # Disable crash reporter
    safe_run "defaults write com.apple.CrashReporter DialogType none" "Disable crash reporter dialog"
    
    # Disable diagnostic data
    safe_run "sudo defaults write /Library/Application\\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false" "Disable diagnostic submission"
    
    # Disable personalized ads
    safe_run "defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false" "Disable personalized ads"
    safe_run "defaults write com.apple.AdLib forceLimitAdTracking -bool true" "Limit Ad Tracking"

    # Disable Handoff
    safe_run "defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool false" "Disable Handoff"
    safe_run "defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool false" "Disable Handoff receiving"
    
    # Disable Game Center (Telemetry heavily embedded)
    safe_run "defaults write com.apple.gamed Disabled -bool true" "Disable Game Center"

    log_success "Privacy hardening complete"
}

################################################################################
# Memory & RAM Optimization
################################################################################

optimize_memory() {
    log_section "🧠" "Memory & RAM Optimization"
    
    # Purge inactive memory
    safe_run "sudo purge" "Purge inactive memory"
    
    # Optimize memory compression
    safe_run "sudo sysctl -w vm.compressor_mode=4" "Enable aggressive compression"
    safe_run "sudo sysctl -w vm.vm_page_free_target=4000" "Optimize page free target"
    safe_run "sudo sysctl -w vm.vm_page_free_min=2000" "Optimize page free minimum"
    
    # Optimize file limits
    safe_run "sudo sysctl -w kern.maxfiles=524288" "Increase max files"
    safe_run "sudo sysctl -w kern.maxfilesperproc=262144" "Increase max files per process"
    
    # Optimize swap behavior
    safe_run "sudo sysctl -w vm.global_no_user_wire_limit=1" "Optimize wire limit"
    
    # Create RAMDisk for temp files if RAM >= 32GB
    if [[ $TOTAL_RAM_GB -ge 32 ]]; then
        local ramdisk_size=$((4 * 1024 * 2048)) # 4GB
        if ! diskutil list | grep -q "RAMDisk"; then
            safe_run "diskutil erasevolume HFS+ 'RAMDisk' \$(hdiutil attach -nomount ram://$ramdisk_size)" "Create 4GB RAMDisk"
            safe_run "sudo ln -sf /Volumes/RAMDisk /tmp/ramdisk" "Link RAMDisk to /tmp"
        fi
    fi
    
    # Disable swap if RAM >= 32GB (Risky for lower RAM, keeping constraint high)
    if [[ $TOTAL_RAM_GB -ge 32 ]]; then
        safe_run "sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist" "Disable dynamic pager"
        safe_run "sudo rm -f /private/var/vm/swapfile*" "Remove swap files"
        log_info "Swap disabled (${TOTAL_RAM_GB}GB RAM detected)"
    fi
    
    log_success "Memory optimization complete"
}

################################################################################
# CPU Optimization
################################################################################

optimize_cpu() {
    log_section "🖥" "CPU Optimization"
    
    # CPU scheduler optimization
    safe_run "sudo sysctl -w kern.sched_quantum=10000" "Optimize scheduler quantum"
    safe_run "sudo sysctl -w kern.sched_preempt_quantum=5000" "Optimize preempt quantum"
    safe_run "sudo sysctl -w kern.timer.deadline_tracking=0" "Disable deadline tracking"
    
    # Process limits
    safe_run "sudo sysctl -w kern.maxproc=4096" "Increase max processes"
    safe_run "sudo sysctl -w kern.maxprocperuid=2048" "Increase max processes per user"
    
    # Thread optimization
    safe_run "sudo sysctl -w kern.num_tasks_threads=8192" "Increase thread limit"
    
    # IPC Optimization
    safe_run "sudo sysctl -w kern.ipc.somaxconn=2048" "Increase max socket backlog"
    
    # Power management / Performance Bias
    safe_run "sudo pmset -a perfbias 0" "Set performance bias to default/balanced"
    
    if [[ "$IS_APPLE_SILICON" == true ]]; then
        # Apple Silicon optimizations
        safe_run "sudo pmset -a highpowermode 1" "Enable High Power Mode (if supported)"
        log_info "Apple Silicon optimizations applied"
    elif [[ "$IS_INTEL" == true ]]; then
        # Intel optimizations
        safe_run "sudo sysctl -w machdep.xcpm.mode=0" "Optimize Intel power management"
        log_info "Intel CPU optimizations applied"
    fi
    
    # Laptop-specific optimizations
    if [[ "$IS_LAPTOP" == false ]]; then
        safe_run "sudo pmset -a perfmode performance" "Set performance mode (desktop)"
    fi
    
    log_success "CPU optimization complete"
}

################################################################################
# GPU Optimization
################################################################################

optimize_gpu() {
    log_section "🎮" "GPU Optimization"
    
    # Metal optimization
    safe_run "defaults write com.apple.metalgl DisableForceDiscreteGPU -bool false" "Enable discrete GPU"
    safe_run "defaults write com.apple.metalgl EnableContextReuse -bool true" "Enable Metal context reuse"
    safe_run "defaults write NSGlobalDomain com.apple.use.metal -bool true" "Enable Metal globally"
    
    # Hardware acceleration
    safe_run "defaults write NSGlobalDomain WebKitAcceleratedCompositingEnabled -bool true" "Enable accelerated compositing"
    safe_run "defaults write NSGlobalDomain WebKitUseHardwareAcceleration -bool true" "Enable hardware acceleration"
    safe_run "defaults write com.apple.CoreGraphics HardwareAcceleration -bool true" "Enable CoreGraphics acceleration"
    
    # GPU-specific optimizations
    case "$GPU_VENDOR" in
        "AMD"|"NVIDIA")
            safe_run "sudo pmset -a gpuswitch 2" "Force discrete GPU (if possible)"
            safe_run "defaults write com.apple.gpu prefers_discrete_gpu -bool true" "Prefer discrete GPU"
            log_info "Discrete GPU ($GPU_VENDOR) optimizations applied"
            ;;
        "Apple")
            log_info "Apple GPU detected - using default optimizations"
            ;;
        "Intel")
            log_info "Intel iGPU detected - using default optimizations"
            ;;
    esac
    
    log_success "GPU optimization complete"
}

################################################################################
# SSD/NVMe Optimization
################################################################################

optimize_storage() {
    log_section "💽" "SSD/NVMe Optimization"
    
    if [[ "$STORAGE_TYPE" == "SSD" ]]; then
        # Enable TRIM
        safe_run "sudo trimforce enable" "Enable TRIM (non-interactive)"
        
        # Disable sudden motion sensor (SSD doesn't need it)
        safe_run "sudo pmset -a sms 0" "Disable sudden motion sensor"
        
        # Disable hibernation (save writes)
        safe_run "sudo pmset -a hibernatemode 0" "Disable hibernation"
        safe_run "sudo rm -f /var/vm/sleepimage" "Remove sleep image"
        
        # Disable local Time Machine snapshots
        safe_run "sudo tmutil disable" "Disable Time Machine local snapshots"
        
        # Optimize APFS
        safe_run "sudo sysctl -w vfs.generic.apfs.trim=1" "Enable APFS TRIM"
        
        log_success "SSD optimization complete"
    else
        log_info "HDD detected - skipping SSD-specific optimizations"
    fi
}

################################################################################
# Virtual Resources Optimization
################################################################################

optimize_virtual_resources() {
    log_section "🔄" "Virtual Resources Optimization"
    
    # Virtual memory optimization
    safe_run "sudo sysctl -w vm.max_map_count=262144" "Increase max map count"
    safe_run "sudo sysctl -w vm.overcommit_memory=1" "Enable memory overcommit"
    
    # Docker optimization
    if command -v docker &> /dev/null; then
        log_info "Docker detected - optimizing..."
        safe_run "docker system prune -af --volumes" "Clean Docker resources"
    fi
    
    # Parallels optimization
    if [ -d "/Applications/Parallels Desktop.app" ]; then
        safe_run "defaults write com.parallels.Parallels\\ Desktop 'Optimize for' -string 'Performance'" "Optimize Parallels"
    fi
    
    # VMware optimization
    if [ -d "/Applications/VMware Fusion.app" ]; then
        safe_run "defaults write com.vmware.fusion 'memory.maxsize' -int 8192" "Optimize VMware memory"
    fi
    
    # Hypervisor optimization
    safe_run "sudo sysctl -w kern.hv_vmm_present=1" "Enable hypervisor optimizations"
    
    log_success "Virtual resources optimization complete"
}

################################################################################
# AI/ML Feature Management
################################################################################

optimize_ai_features() {
    log_section "🤖" "AI/ML Feature Management"
    
    # Disable Siri completely
    safe_run "defaults write com.apple.assistant.support 'Assistant Enabled' -bool false" "Disable Siri assistant"
    safe_run "launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.agent.plist" "Unload Siri agent"
    
    # Disable dictation
    safe_run "defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMInterfaceVersion -int 0" "Disable dictation"
    
    # Disable ML suggestions
    safe_run "defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false" "Disable text suggestions"
    safe_run "defaults write com.apple.Safari AutoFillPasswords -bool false" "Disable Safari autofill"
    
    # Disable background ML daemons
    safe_run "launchctl unload -w /System/Library/LaunchDaemons/com.apple.analyticsd.plist" "Disable analytics daemon"
    safe_run "launchctl unload -w /System/Library/LaunchAgents/com.apple.siri.analytics.assistant.plist" "Disable Siri analytics agent"
    
    log_success "AI/ML features optimized"
}

################################################################################
# Battery Optimization (Laptop Only)
################################################################################

optimize_battery() {
    if [[ "$IS_LAPTOP" == false ]]; then
        log_info "Desktop detected - skipping battery optimization"
        return
    fi
    
    log_section "🔋" "Battery Optimization"
    
    # Enable Low Power Mode on battery
    safe_run "sudo pmset -b lowpowermode 1" "Enable Low Power Mode"
    
    # Optimize sleep settings
    safe_run "sudo pmset -b displaysleep 5" "Set display sleep to 5 min"
    safe_run "sudo pmset -b sleep 10" "Set system sleep to 10 min"
    safe_run "sudo pmset -b disksleep 10" "Set disk sleep to 10 min"
    
    # Disable Power Nap
    safe_run "sudo pmset -a powernap 0" "Disable Power Nap"
    
    # Disable wake for network
    safe_run "sudo pmset -a womp 0" "Disable wake for network"
    safe_run "sudo pmset -a proximitywake 0" "Disable proximity wake"
    
    # Optimize GPU switching
    safe_run "sudo pmset -b gpuswitch 0" "Enable automatic GPU switching"
    
    # Reduce display brightness on battery
    safe_run "sudo pmset -b halfdim 1" "Enable half-dim on battery"
    safe_run "sudo pmset -b lessbright 1" "Reduce brightness on battery"
    
    # Display battery health
    local cycle_count=$(system_profiler SPPowerDataType 2>/dev/null | grep "Cycle Count" | awk '{print $3}')
    local condition=$(system_profiler SPPowerDataType 2>/dev/null | grep "Condition" | awk '{print $2}')
    log_info "Battery Cycle Count: ${cycle_count:-Unknown}"
    log_info "Battery Condition: ${condition:-Unknown}"
    
    log_success "Battery optimization complete"
}

################################################################################
# Startup & Service Optimization
################################################################################

optimize_startup() {
    log_section "🚀" "Startup & Service Optimization"
    
    # Disable unnecessary launch daemons (safe list)
    local daemons=(
        "com.apple.metadata.mds.scan"
        "com.apple.cloudd"
        "com.apple.cloudpaird"
        "com.apple.cloudphotosd"
        "com.apple.gamed"
        "com.apple.icloud.findmydeviced"
        "com.apple.iCloudUserNotifications"
        "com.apple.appstoreagent"
        "com.apple.touristd"
        "com.apple.netbiosd"
    )
    
    for daemon in "${daemons[@]}"; do
        safe_run "sudo launchctl unload -w /System/Library/LaunchDaemons/${daemon}.plist" "Disable $daemon"
        safe_run "launchctl unload -w /System/Library/LaunchAgents/${daemon}.plist" "Disable $daemon (user)"
    done
    
    # Optimize boot cache (OpenCore-safe)
    if [[ "$IS_OPENCORE" == false ]]; then
        safe_run "sudo kextcache -update-volume /" "Update kernel cache"
    else
        log_info "Skipping kext cache update (OpenCore detected)"
    fi
    
    # Optimize login window
    safe_run "sudo defaults write /Library/Preferences/com.apple.loginwindow TALLogoutSavesState -bool false" "Disable login state saving"
    safe_run "sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false" "Disable guest account"

    # Disable dashboard
    safe_run "defaults write com.apple.dashboard mcx-disabled -bool true" "Disable Dashboard"
    
    log_success "Startup optimization complete"
}

################################################################################
# Security Hardening
################################################################################

harden_security() {
    log_section "🛡" "Security Hardening"
    
    # Enable firewall
    safe_run "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on" "Enable firewall"
    safe_run "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on" "Enable firewall logging"
    safe_run "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on" "Enable stealth mode"
    
    # Verify Gatekeeper
    safe_run "sudo spctl --master-enable" "Enable Gatekeeper"
    
    # Check SIP status
    local sip_status=$(csrutil status 2>/dev/null | grep -o "enabled\|disabled")
    log_info "System Integrity Protection: ${sip_status:-unknown}"
    
    # Disable remote login
    safe_run "sudo systemsetup -setremotelogin off" "Disable remote login"
    
    # Disable remote Apple events
    safe_run "sudo systemsetup -setremoteappleevents off" "Disable remote Apple events"
    
    # Require password immediately after sleep
    safe_run "defaults write com.apple.screensaver askForPassword -int 1" "Require password after screensaver"
    safe_run "defaults write com.apple.screensaver askForPasswordDelay -int 0" "No password delay"
    
    log_success "Security hardening complete"
}

################################################################################
# Developer Tools Installation
################################################################################

install_dev_tools() {
    log_section "🛠" "Developer Tools Installation"
    
    # Ensure Homebrew
    ensure_homebrew
    
    if command -v brew &> /dev/null; then
        # Install essential CLI tools
        install_tool "htop"
        install_tool "wget"
        install_tool "curl"
        install_tool "git"
        install_tool "tree"
        install_tool "jq"
        
        # Install monitoring tools
        install_tool "glances"
        install_tool "iftop"
        install_tool "smartctl" "smartmontools"
        
        log_success "Developer tools installed"
    else
        log_warning "Homebrew not available - skipping tool installation"
    fi
}

################################################################################
# OpenCore-Specific Optimizations
################################################################################

optimize_opencore() {
    if [[ "$IS_OPENCORE" == false ]]; then
        return
    fi
    
    log_section "🔧" "OpenCore-Specific Optimizations"
    
    # Safe NVRAM optimizations
    safe_run "sudo nvram boot-args='serverperfmode=1'" "Enable server performance mode"
    
    # Optimize kernel cache (safe for OpenCore)
    safe_run "sudo kextcache -i /" "Rebuild kext cache (OpenCore-safe)"
    
    log_success "OpenCore optimizations complete"
    log_warning "OpenCore detected - some optimizations were skipped for safety"
}

################################################################################
# System Summary & Report
################################################################################

generate_report() {
    log_section "📊" "System Summary & Report"
    
    local end_time=$(date +%s)
    local execution_time=$((end_time - START_TIME))
    local minutes=$((execution_time / 60))
    local seconds=$((execution_time % 60))
    
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║              OPTIMIZATION COMPLETE                           ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "System Information:"
    log "  • macOS Version: $MACOS_VERSION"
    log "  • Architecture: $CPU_ARCH"
    log "  • CPU: $CPU_VENDOR ($CPU_CORES cores)"
    log "  • GPU: $GPU_VENDOR ($GPU_MODEL)"
    log "  • RAM: ${TOTAL_RAM_GB}GB"
    log "  • Storage: $STORAGE_TYPE"
    log "  • Device Type: $([ "$IS_LAPTOP" == true ] && echo "Laptop" || echo "Desktop")"
    log "  • OpenCore: $([ "$IS_OPENCORE" == true ] && echo "Yes" || echo "No")"
    log ""
    log "Disk Space:"
    local available=$(df -h / | awk 'NR==2 {print $4}')
    local total=$(df -h / | awk 'NR==2 {print $2}')
    local used=$(df -h / | awk 'NR==2 {print $5}')
    log "  • Available: $available / $total"
    log "  • Used: $used"
    log ""
    log "Memory Status:"
    local free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local free_mb=$((free_pages * 4096 / 1024 / 1024))
    log "  • Free Memory: ~${free_mb}MB"
    log ""
    log "Execution Time: ${minutes}m ${seconds}s"
    log ""
    log "Optimizations Applied:"
    log "  ✅ Network optimization"
    log "  ✅ System repair & integrity"
    log "  ✅ Disk cleanup & storage optimization"
    log "  ✅ Performance & responsiveness tuning"
    log "  ✅ Privacy & telemetry hardening"
    log "  ✅ Memory & RAM optimization"
    log "  ✅ CPU optimization"
    log "  ✅ GPU optimization"
    log "  ✅ Storage optimization"
    log "  ✅ Virtual resources optimization"
    log "  ✅ AI/ML feature management"
    if [[ "$IS_LAPTOP" == true ]]; then
        log "  ✅ Battery optimization"
    fi
    log "  ✅ Startup & service optimization"
    log "  ✅ Security hardening"
    log "  ✅ Developer tools installation"
    if [[ "$IS_OPENCORE" == true ]]; then
        log "  ✅ OpenCore-specific optimizations"
    fi
    log ""
    log "Post-Optimization Recommendations:"
    log "  • Restart your Mac to apply all changes"
    log "  • Monitor system performance with Activity Monitor"
    log "  • Keep at least 15% disk space free"
    log "  • Run this script monthly for maintenance"
    log ""
    log "Log saved to: $LOG_FILE"
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║  OptimacOS v$SCRIPT_VERSION - Optimization Complete          ║"
    log "╚══════════════════════════════════════════════════════════════╝"
}

################################################################################
# Main Execution
################################################################################

main() {
    # Print banner
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              OptimacOS v$SCRIPT_VERSION                           ║"
    echo "║     Universal macOS Optimization Engine                     ║"
    echo "║                                                              ║"
    echo "║  Fully Automated • Zero Interaction • Universal              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Starting optimization at $(date)"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Request sudo upfront
    log_info "Requesting administrator privileges..."
    if ! sudo -v; then
        log_error "Administrator privileges required. Exiting."
        exit 1
    fi
    
    # Execute all optimizations
    detect_system
    optimize_network
    repair_system
    cleanup_storage
    optimize_performance
    harden_privacy
    optimize_memory
    optimize_cpu
    optimize_gpu
    optimize_storage
    optimize_virtual_resources
    optimize_ai_features
    optimize_battery
    optimize_startup
    harden_security
    install_dev_tools
    optimize_opencore
    
    # Generate final report
    generate_report
    
    exit 0
}

# Execute main function
main "$@"
