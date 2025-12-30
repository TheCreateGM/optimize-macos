#!/bin/bash

# --- Configuration ---
LOG_RETENTION_DAYS=7
LARGE_FILE_SIZE_GB=1
DEFAULT_YES=false
VERBOSE=true
RUN_ALL=false
SCRIPT_VERSION="2.0.0"
START_TIME=$(date +%s)

# Package manager preferences
USE_HOMEBREW=true
USE_MACPORTS=false

# --- Helper Functions ---
ask_yes_no() {
    if [[ "$RUN_ALL" == true ]]; then
        return 0
    fi

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
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

detect_os_version() {
    OS_VERSION=$(sw_vers -productVersion)
    OS_MAJOR_VERSION=$(echo "$OS_VERSION" | cut -d. -f1)
    OS_MINOR_VERSION=$(echo "$OS_VERSION" | cut -d. -f2)

    if [[ "$VERBOSE" == true ]]; then
        echo "Detected macOS version: $OS_VERSION (Major: $OS_MAJOR_VERSION, Minor: $OS_MINOR_VERSION)"
    fi
}

check_disk_space() {
    local available_space=$(df -h / | awk 'NR==2 {print $4}')
    echo "Available disk space: $available_space"

    local available_bytes=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_bytes -lt 1048576 ]]; then
        echo "⚠️ WARNING: Low disk space. Some operations may fail."
    fi
}

initialize_script() {
    detect_os_version
    check_disk_space
}

print_section_header() {
    local emoji="$1"
    local section_num="$2"
    local title="$3"
    local separator_line=""

    for ((i=0; i<${#title}+4; i++)); do
        separator_line+="-"
    done

    echo -e "\n$emoji Section $section_num: $title"
    echo "$separator_line"
}

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

# --- Package Manager Functions ---
check_homebrew() {
    if command -v brew &> /dev/null; then
        echo "✅ Homebrew is installed"
        return 0
    else
        echo "⚠️ Homebrew is not installed"
        return 1
    fi
}

install_homebrew() {
    if ! check_homebrew; then
        if ask_yes_no "Install Homebrew? (Required for some optimizations)"; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            check_status "Homebrew installed" "install_homebrew"
        else
            echo "Skipping Homebrew installation. Some features will be unavailable."
            USE_HOMEBREW=false
        fi
    fi
}

check_macports() {
    if command -v port &> /dev/null; then
        echo "✅ MacPorts is installed"
        return 0
    else
        echo "⚠️ MacPorts is not installed"
        return 1
    fi
}

install_package() {
    local package_name="$1"
    local brew_name="${2:-$package_name}"
    local port_name="${3:-$package_name}"
    
    # Check if package is already installed
    if command -v "$package_name" &> /dev/null; then
        echo "✅ $package_name is already installed"
        return 0
    fi
    
    if [[ "$USE_HOMEBREW" == true ]] && check_homebrew; then
        echo "Installing $package_name via Homebrew..."
        brew install "$brew_name" 2>/dev/null
        return $?
    elif [[ "$USE_MACPORTS" == true ]] && check_macports; then
        echo "Installing $package_name via MacPorts..."
        sudo port install "$port_name" 2>/dev/null
        return $?
    else
        echo "⚠️ No package manager available to install $package_name"
        return 1
    fi
}

# --- NEW: Advanced Performance Optimizations ---

# --- 40. Advanced Memory Optimization ---
advanced_memory_optimization() {
    print_section_header "🧠" "40" "Advanced Memory Optimization"
    
    if ask_yes_no "Apply advanced memory optimizations?"; then
        echo "Optimizing memory subsystem..."
        
        # Install memory monitoring tools
        install_package "htop" "htop" "htop"
        
        # Memory pressure optimization
        sudo sysctl -w vm.compressor_mode=4 2>/dev/null || true
        sudo sysctl -w vm.swapusage=0 2>/dev/null || true
        sudo sysctl -w vm.vm_page_free_target=4000 2>/dev/null || true
        sudo sysctl -w vm.vm_page_free_min=2000 2>/dev/null || true
        
        # Optimize swap behavior
        sudo sysctl -w vm.global_no_user_wire_limit=1 2>/dev/null || true
        sudo sysctl -w vm.global_user_wire_limit=0 2>/dev/null || true
        
        # Memory compression optimization
        sudo sysctl -w vm.compressor_compressed_swap_chunk_size=4096 2>/dev/null || true
        
        # Clear memory pressure
        sudo purge
        
        # Optimize memory allocation
        sudo sysctl -w kern.maxfiles=524288 2>/dev/null || true
        sudo sysctl -w kern.maxfilesperproc=262144 2>/dev/null || true
        
        echo "✅ Advanced memory optimization complete"
        
        if [[ "$VERBOSE" == true ]]; then
            echo "Current memory statistics:"
            vm_stat | head -15
        fi
    else
        echo "Skipping advanced memory optimization."
    fi
}

# --- 41. Startup Optimization ---
startup_optimization() {
    print_section_header "🚀" "41" "Startup Optimization"
    
    if ask_yes_no "Optimize system startup?"; then
        echo "Optimizing startup processes..."
        
        # Disable unnecessary launch daemons
        echo "Disabling unnecessary launch daemons..."
        
        # List of daemons that can be safely disabled for better performance
        local daemons_to_disable=(
            "com.apple.metadata.mds"
            "com.apple.metadata.mds.index"
            "com.apple.metadata.mds.scan"
            "com.apple.cloudd"
            "com.apple.cloudpaird"
            "com.apple.cloudphotosd"
            "com.apple.gamed"
            "com.apple.icloud.findmydeviced"
            "com.apple.iCloudUserNotifications"
        )
        
        for daemon in "${daemons_to_disable[@]}"; do
            if ask_yes_no "Disable $daemon?"; then
                sudo launchctl unload -w "/System/Library/LaunchDaemons/${daemon}.plist" 2>/dev/null || true
                echo "  Disabled: $daemon"
            fi
        done
        
        # Optimize boot cache
        echo "Optimizing boot cache..."
        sudo kextcache -update-volume / 2>/dev/null || true
        
        # Reduce boot delay
        sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)" 2>/dev/null || true
        
        # Disable hibernation for faster wake
        sudo pmset -a hibernatemode 0 2>/dev/null || true
        sudo rm -f /var/vm/sleepimage 2>/dev/null || true
        
        # Optimize login window
        sudo defaults write /Library/Preferences/com.apple.loginwindow TALLogoutSavesState -bool false
        
        echo "✅ Startup optimization complete"
    else
        echo "Skipping startup optimization."
    fi
}

# --- 42. Advanced CPU Optimization ---
advanced_cpu_optimization() {
    print_section_header "⚡" "42" "Advanced CPU Optimization"
    
    if ask_yes_no "Apply advanced CPU optimizations?"; then
        echo "Optimizing CPU performance..."
        
        # Install CPU monitoring tools
        install_package "cpulimit" "cpulimit" "cpulimit"
        
        # Detect CPU type
        local cpu_type=$(sysctl -n machdep.cpu.brand_string)
        echo "Detected CPU: $cpu_type"
        
        # CPU scheduler optimization
        sudo sysctl -w kern.sched_quantum=10000 2>/dev/null || true
        sudo sysctl -w kern.sched_preempt_quantum=5000 2>/dev/null || true
        sudo sysctl -w kern.timer.deadline_tracking=0 2>/dev/null || true
        
        # Process priority optimization
        sudo sysctl -w kern.maxproc=4096 2>/dev/null || true
        sudo sysctl -w kern.maxprocperuid=2048 2>/dev/null || true
        
        # Thread optimization
        sudo sysctl -w kern.num_tasks_threads=8192 2>/dev/null || true
        sudo sysctl -w kern.pthread_priority_delay=50000 2>/dev/null || true
        
        # CPU power management
        sudo pmset -a perfbias 0 2>/dev/null || true
        sudo pmset -a perfmode performance 2>/dev/null || true
        
        # Turbo Boost optimization (Intel)
        if [[ "$cpu_type" == *"Intel"* ]]; then
            echo "Intel CPU detected - optimizing Turbo Boost..."
            sudo sysctl -w machdep.xcpm.mode=0 2>/dev/null || true
        fi
        
        # Apple Silicon optimization
        if [[ $(uname -m) == "arm64" ]]; then
            echo "Apple Silicon detected - enabling High Power Mode..."
            sudo pmset -a highpowermode 1 2>/dev/null || true
        fi
        
        echo "✅ Advanced CPU optimization complete"
        
        if [[ "$VERBOSE" == true ]]; then
            echo "CPU information:"
            sysctl -a | grep machdep.cpu | head -20
        fi
    else
        echo "Skipping advanced CPU optimization."
    fi
}

# --- 43. Advanced GPU Optimization ---
advanced_gpu_optimization() {
    print_section_header "🎮" "43" "Advanced GPU Optimization"
    
    if ask_yes_no "Apply advanced GPU optimizations?"; then
        echo "Optimizing GPU performance..."
        
        # Detect GPU
        local gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | cut -d: -f2 | xargs)
        echo "Detected GPU: $gpu_info"
        
        # Metal optimization
        defaults write com.apple.metalgl DisableForceDiscreteGPU -bool false 2>/dev/null || true
        defaults write com.apple.metalgl EnableContextReuse -bool true 2>/dev/null || true
        defaults write com.apple.metalgl DisableComputeCompaction -bool false 2>/dev/null || true
        defaults write NSGlobalDomain com.apple.use.metal -bool true 2>/dev/null || true
        
        # OpenGL/Metal rendering optimization
        defaults write NSGlobalDomain WebKitAcceleratedCompositingEnabled -bool true 2>/dev/null || true
        defaults write NSGlobalDomain WebKitUseHardwareAcceleration -bool true 2>/dev/null || true
        defaults write com.apple.CoreGraphics HardwareAcceleration -bool true 2>/dev/null || true
        
        # Force discrete GPU if available
        if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "AMD\|NVIDIA\|Radeon"; then
            echo "Discrete GPU detected - forcing discrete GPU usage..."
            sudo pmset -a gpuswitch 2 2>/dev/null || true
            defaults write com.apple.gpu prefers_discrete_gpu -bool true 2>/dev/null || true
        fi
        
        # GPU thread allocation
        sudo sysctl -w kern.gpu.max_threads=256 2>/dev/null || true
        
        # Disable GPU throttling
        sudo sysctl -w kern.gpu.throttle=0 2>/dev/null || true
        
        echo "✅ Advanced GPU optimization complete"
        
        if [[ "$VERBOSE" == true ]]; then
            echo "GPU information:"
            system_profiler SPDisplaysDataType | grep -A 10 "Chipset Model"
        fi
    else
        echo "Skipping advanced GPU optimization."
    fi
}

# --- 44. RAM Optimization & Management ---
ram_optimization() {
    print_section_header "💾" "44" "RAM Optimization & Management"
    
    if ask_yes_no "Optimize RAM usage and management?"; then
        echo "Optimizing RAM..."
        
        # Get total RAM
        local total_ram=$(sysctl -n hw.memsize)
        local total_ram_gb=$((total_ram / 1024 / 1024 / 1024))
        echo "Total RAM: ${total_ram_gb}GB"
        
        # Clear RAM
        sudo purge
        
        # Optimize virtual memory
        sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true
        sudo sysctl -w vm.overcommit_memory=1 2>/dev/null || true
        
        # Disable swap if enough RAM (16GB+)
        if [[ $total_ram_gb -ge 16 ]]; then
            if ask_yes_no "Disable swap? (Recommended for 16GB+ RAM)"; then
                sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist 2>/dev/null || true
                sudo rm /private/var/vm/swapfile* 2>/dev/null || true
                echo "Swap disabled"
            fi
        fi
        
        # Optimize memory pressure thresholds
        sudo sysctl -w vm.memory_pressure_critical=95 2>/dev/null || true
        sudo sysctl -w vm.memory_pressure_warn=80 2>/dev/null || true
        
        # Clear inactive memory
        sudo memory_pressure -l critical 2>/dev/null || sudo purge
        
        echo "✅ RAM optimization complete"
        
        if [[ "$VERBOSE" == true ]]; then
            echo "Current RAM usage:"
            vm_stat
        fi
    else
        echo "Skipping RAM optimization."
    fi
}

# --- 45. Advanced SSD Optimization ---
advanced_ssd_optimization() {
    print_section_header "💽" "45" "Advanced SSD Optimization"
    
    if ask_yes_no "Apply advanced SSD optimizations?"; then
        echo "Optimizing SSD performance..."
        
        # Install smartmontools for SSD health monitoring
        install_package "smartctl" "smartmontools" "smartmontools"
        
        # Enable TRIM
        sudo trimforce enable 2>/dev/null || true
        
        # Disable sudden motion sensor (for SSD)
        sudo pmset -a sms 0 2>/dev/null || true
        
        # Optimize I/O scheduler
        sudo sysctl -w kern.aio_max_requests=1024 2>/dev/null || true
        sudo sysctl -w kern.aio_listio_max=256 2>/dev/null || true
        
        # Disable local Time Machine snapshots
        sudo tmutil disable 2>/dev/null || true
        
        # Reduce writes to SSD
        sudo pmset -a hibernatemode 0 2>/dev/null || true
        sudo rm -f /var/vm/sleepimage 2>/dev/null || true
        
        # Optimize file system
        sudo sysctl -w vfs.generic.sync_timeout=300 2>/dev/null || true
        sudo sysctl -w kern.maxvnodes=1048576 2>/dev/null || true
        
        # Check SSD health
        if command -v smartctl &> /dev/null; then
            local disk_id=$(diskutil list | grep "disk0" | head -1 | awk '{print $1}')
            echo "SSD Health Check:"
            sudo smartctl -a "$disk_id" 2>/dev/null | grep -E "Percentage Used|Available Spare|Temperature" || echo "Health check not available"
        fi
        
        echo "✅ Advanced SSD optimization complete"
    else
        echo "Skipping advanced SSD optimization."
    fi
}

# --- 46. Virtual Resources Optimization ---
virtual_resources_optimization() {
    print_section_header "🔄" "46" "Virtual Resources Optimization"
    
    if ask_yes_no "Optimize virtual resources (VM, containers)?"; then
        echo "Optimizing virtual resources..."
        
        # Virtual memory optimization
        sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true
        sudo sysctl -w vm.overcommit_memory=1 2>/dev/null || true
        
        # Docker optimization (if installed)
        if command -v docker &> /dev/null; then
            echo "Optimizing Docker..."
            # Restart Docker with optimized settings
            osascript -e 'quit app "Docker"' 2>/dev/null || true
            sleep 3
            open -a Docker 2>/dev/null || true
        fi
        
        # Parallels optimization (if installed)
        if [ -d "/Applications/Parallels Desktop.app" ]; then
            echo "Optimizing Parallels Desktop settings..."
            defaults write com.parallels.Parallels\ Desktop "Optimize for" -string "Performance"
        fi
        
        # VMware optimization (if installed)
        if [ -d "/Applications/VMware Fusion.app" ]; then
            echo "Optimizing VMware Fusion settings..."
            defaults write com.vmware.fusion "memory.maxsize" -int 8192
        fi
        
        # Optimize kernel for virtualization
        sudo sysctl -w kern.hv_vmm_present=1 2>/dev/null || true
        
        echo "✅ Virtual resources optimization complete"
    else
        echo "Skipping virtual resources optimization."
    fi
}

# --- 47. AI System Removal/Optimization ---
ai_system_optimization() {
    print_section_header "🤖" "47" "AI System Optimization"
    
    if ask_yes_no "Optimize or disable AI features for performance?"; then
        echo "Managing AI system features..."
        
        # Disable Siri
        if ask_yes_no "Disable Siri?"; then
            defaults write com.apple.assistant.support "Assistant Enabled" -bool false
            defaults write com.apple.Siri "StatusMenuVisible" -bool false
            defaults write com.apple.Siri "UserHasDeclinedEnable" -bool true
            launchctl unload -w /System/Library/LaunchAgents/com.apple.Siri.agent.plist 2>/dev/null || true
            echo "Siri disabled"
        fi
        
        # Disable Spotlight suggestions
        if ask_yes_no "Disable Spotlight AI suggestions?"; then
            defaults write com.apple.spotlight orderedItems -array \
                '{"enabled" = 1;"name" = "APPLICATIONS";}' \
                '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
                '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
            killall mds 2>/dev/null || true
            echo "Spotlight AI suggestions disabled"
        fi
        
        # Disable dictation
        if ask_yes_no "Disable dictation?"; then
            defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMInterfaceVersion -int 0
            defaults write com.apple.assistant.support "Dictation Enabled" -bool false
            echo "Dictation disabled"
        fi
        
        # Disable predictive text
        if ask_yes_no "Disable predictive text?"; then
            defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false
            defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
            echo "Predictive text disabled"
        fi
        
        echo "✅ AI system optimization complete"
    else
        echo "Skipping AI system optimization."
    fi
}

# --- 48. Advanced Battery Optimization ---
advanced_battery_optimization() {
    print_section_header "🔋" "48" "Advanced Battery Optimization"
    
    if ask_yes_no "Apply advanced battery optimizations?"; then
        echo "Optimizing battery performance..."
        
        # Install battery monitoring tools
        install_package "battery" "battery" "battery"
        
        # Enable Low Power Mode
        sudo pmset -b lowpowermode 1 2>/dev/null || true
        
        # Optimize power settings
        sudo pmset -b displaysleep 5 2>/dev/null || true
        sudo pmset -b sleep 10 2>/dev/null || true
        sudo pmset -b disksleep 10 2>/dev/null || true
        
        # Disable Power Nap
        sudo pmset -a powernap 0 2>/dev/null || true
        
        # Disable Wake for network access
        sudo pmset -a womp 0 2>/dev/null || true
        
        # Disable proximity wake
        sudo pmset -a proximitywake 0 2>/dev/null || true
        
        # Optimize graphics switching
        sudo pmset -a gpuswitch 0 2>/dev/null || true
        
        # Reduce display brightness
        sudo pmset -b halfdim 1 2>/dev/null || true
        sudo pmset -b lessbright 1 2>/dev/null || true
        
        # Check battery health
        echo "Battery health information:"
        system_profiler SPPowerDataType | grep -E "Cycle Count|Condition|Capacity" || echo "Battery info not available"
        
        echo "✅ Advanced battery optimization complete"
    else
        echo "Skipping advanced battery optimization."
    fi
}

# --- 49. Service Optimization ---
service_optimization() {
    print_section_header "⚙️" "49" "Service Optimization"
    
    if ask_yes_no "Optimize system services?"; then
        echo "Optimizing system services..."
        
        # Disable unused services
        local services_to_disable=(
            "com.apple.cloudd"
            "com.apple.cloudpaird"
            "com.apple.cloudphotosd"
            "com.apple.gamed"
            "com.apple.icloud.findmydeviced"
            "com.apple.iCloudUserNotifications"
            "com.apple.appstoreagent"
            "com.apple.touristd"
        )
        
        for service in "${services_to_disable[@]}"; do
            if ask_yes_no "Disable $service?"; then
                launchctl unload -w "/System/Library/LaunchAgents/${service}.plist" 2>/dev/null || true
                sudo launchctl unload -w "/System/Library/LaunchDaemons/${service}.plist" 2>/dev/null || true
                echo "  Disabled: $service"
            fi
        done
        
        # Optimize indexing services
        if ask_yes_no "Optimize Spotlight indexing?"; then
            sudo mdutil -i off / 2>/dev/null || true
            sudo mdutil -E / 2>/dev/null || true
            sudo mdutil -i on / 2>/dev/null || true
            echo "Spotlight indexing optimized"
        fi
        
        # Clean up launch agents
        echo "Cleaning up unnecessary launch agents..."
        find ~/Library/LaunchAgents -name "*.plist" 2>/dev/null | while read agent; do
            if ask_yes_no "Review launch agent: $(basename $agent)?"; then
                echo "Agent: $agent"
                if ask_yes_no "Disable this agent?"; then
                    launchctl unload "$agent" 2>/dev/null || true
                fi
            fi
        done
        
        echo "✅ Service optimization complete"
    else
        echo "Skipping service optimization."
    fi
}

# --- 50. General System Smoothness ---
general_system_smoothness() {
    print_section_header "✨" "50" "General System Smoothness"
    
    if ask_yes_no "Apply general smoothness optimizations?"; then
        echo "Optimizing system smoothness..."
        
        # Reduce window resize time
        defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
        
        # Increase window resize speed
        defaults write NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -bool false
        
        # Faster Mission Control animations
        defaults write com.apple.dock expose-animation-duration -float 0.1
        
        # Remove Dock hide delay
        defaults write com.apple.dock autohide-delay -float 0
        defaults write com.apple.dock autohide-time-modifier -float 0.5
        
        # Speed up Quick Look
        defaults write -g QLPanelAnimationDuration -float 0
        
        # Disable dashboard
        defaults write com.apple.dashboard mcx-disabled -bool true
        
        # Optimize Finder
        defaults write com.apple.finder DisableAllAnimations -bool true
        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
        
        # Disable animations system-wide
        defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
        
        # Optimize scrolling
        defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
        defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
        
        # Restart affected services
        killall Dock 2>/dev/null || true
        killall Finder 2>/dev/null || true
        killall SystemUIServer 2>/dev/null || true
        
        echo "✅ General system smoothness optimization complete"
    else
        echo "Skipping general smoothness optimization."
    fi
}

# --- 51. Performance Monitoring Setup ---
performance_monitoring_setup() {
    print_section_header "📊" "51" "Performance Monitoring Setup"
    
    if ask_yes_no "Install performance monitoring tools?"; then
        echo "Installing performance monitoring tools..."
        
        # Install monitoring tools
        install_package "htop" "htop" "htop"
        install_package "iftop" "iftop" "iftop"
        install_package "iotop" "iotop" "iotop"
        install_package "glances" "glances" "glances"
        
        # Create monitoring script
        cat > ~/performance_monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Performance Monitor ==="
echo "Date: $(date)"
echo ""
echo "=== CPU Usage ==="
top -l 1 | head -10
echo ""
echo "=== Memory Usage ==="
vm_stat | head -10
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Network Usage ==="
netstat -ib
EOF
        chmod +x ~/performance_monitor.sh
        
        echo "✅ Performance monitoring tools installed"
        echo "Run ~/performance_monitor.sh to check system performance"
    else
        echo "Skipping performance monitoring setup."
    fi
}

# --- Original Functions (keeping essential ones) ---
restart_finder() {
    print_section_header "📁" "1" "Restarting Finder"
    if ask_yes_no "Force quit and restart Finder?"; then
        run_command "killall Finder" "Finder restarted" "restart_finder"
    else
        echo "Skipping Finder restart."
    fi
}

clear_caches() {
    print_section_header "🧹" "3" "Clearing Caches"
    if ask_yes_no "Clear User Caches?"; then
        run_command "rm -rf ~/Library/Caches/*" "User caches cleared" "clear_user_caches"
    else
        echo "Skipping User Caches."
    fi
    if ask_yes_no "Clear System Caches?"; then
        run_command "sudo rm -rf /Library/Caches/* /System/Library/Caches/*" "System caches cleared" "clear_system_caches"
    else
        echo "Skipping System Caches."
    fi
}

purge_memory() {
    print_section_header "🧠" "9" "Purging Inactive Memory"
    if ask_yes_no "Run 'sudo purge' to free inactive RAM?"; then
        run_command "sudo purge" "Memory purged" "purge_memory"
    else
        echo "Skipping memory purge."
    fi
}

# --- Main Script Execution ---
echo "🚀 Enhanced macOS Performance Optimizer v$SCRIPT_VERSION 🚀"
echo "=========================================================="
echo "This script includes advanced performance optimizations"
echo "with automatic tool installation via Homebrew/MacPorts"
echo ""

initialize_script

# Check for command line arguments
for arg in "$@"; do
    case "$arg" in
        --all) RUN_ALL=true ;;
        --verbose) VERBOSE=true ;;
        --quiet) VERBOSE=false ;;
        --yes) DEFAULT_YES=true ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --all       Run all optimizations without prompting"
            echo "  --verbose   Show detailed command output"
            echo "  --quiet     Minimize output messages"
            echo "  --yes       Default to 'yes' for all prompts"
            echo "  --homebrew  Use Homebrew for package installation (default)"
            echo "  --macports  Use MacPorts for package installation"
            echo "  --help, -h  Show this help message"
            exit 0
            ;;
        --homebrew) USE_HOMEBREW=true; USE_MACPORTS=false ;;
        --macports) USE_MACPORTS=true; USE_HOMEBREW=false ;;
    esac
done

# Request admin privileges upfront
echo "Requesting administrator privileges..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$" || exit; done 2>/dev/null &
ADMIN_KEEP_ALIVE_PID=$!
echo "Administrator privileges granted."
echo ""

# Install package managers if needed
if [[ "$USE_HOMEBREW" == true ]]; then
    install_homebrew
fi

# Display menu
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║     Enhanced macOS Performance Optimization Suite            ║
║                                                              ║
║  New Advanced Features:                                      ║
║  • Memory & RAM Optimization                                 ║
║  • Startup Optimization                                      ║
║  • Advanced CPU/GPU Optimization                             ║
║  • SSD Performance Tuning                                    ║
║  • Virtual Resources Management                              ║
║  • AI System Optimization                                    ║
║  • Battery Performance                                       ║
║  • Service Optimization                                      ║
║  • System Smoothness Enhancements                            ║
║  • Performance Monitoring Tools                              ║
╚══════════════════════════════════════════════════════════════╝
EOF

echo ""

# Define all function arrays
CORE_FUNCTIONS=(
    "restart_finder"
    "clear_caches"
    "purge_memory"
)

PERFORMANCE_FUNCTIONS=(
    "advanced_memory_optimization"
    "ram_optimization"
    "advanced_cpu_optimization"
    "advanced_gpu_optimization"
    "advanced_ssd_optimization"
    "general_system_smoothness"
)

STARTUP_FUNCTIONS=(
    "startup_optimization"
)

BATTERY_FUNCTIONS=(
    "advanced_battery_optimization"
)

SERVICE_FUNCTIONS=(
    "service_optimization"
    "ai_system_optimization"
)

VIRTUAL_FUNCTIONS=(
    "virtual_resources_optimization"
)

MONITORING_FUNCTIONS=(
    "performance_monitoring_setup"
)

ALL_FUNCTIONS=(
    "${CORE_FUNCTIONS[@]}"
    "${PERFORMANCE_FUNCTIONS[@]}"
    "${STARTUP_FUNCTIONS[@]}"
    "${BATTERY_FUNCTIONS[@]}"
    "${SERVICE_FUNCTIONS[@]}"
    "${VIRTUAL_FUNCTIONS[@]}"
    "${MONITORING_FUNCTIONS[@]}"
)

# Execution mode selection
if [[ "$RUN_ALL" == true ]]; then
    echo "Running all optimization functions..."
    for func in "${ALL_FUNCTIONS[@]}"; do
        $func
    done
else
    echo "Select execution mode:"
    echo "1. Run all optimizations"
    echo "2. Run by category"
    echo "3. Run individual functions"
    echo "4. Quick performance boost (recommended)"
    read -p "Enter your choice (1-4) [4]: " execution_mode
    execution_mode=${execution_mode:-4}

    case $execution_mode in
        1)
            # Run all functions
            echo "Running all optimization functions..."
            for func in "${ALL_FUNCTIONS[@]}"; do
                $func
            done
            ;;

        2)
            # Run by categories
            echo ""
            echo "Available categories:"
            echo "1. Core System Maintenance"
            echo "2. Performance Optimizations"
            echo "3. Startup Optimization"
            echo "4. Battery Optimization"
            echo "5. Service & AI Optimization"
            echo "6. Virtual Resources"
            echo "7. Monitoring Tools"
            echo ""

            if ask_yes_no "Run Core System Maintenance?"; then
                for func in "${CORE_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Run Performance Optimizations?"; then
                for func in "${PERFORMANCE_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Run Startup Optimization?"; then
                for func in "${STARTUP_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Run Battery Optimization?"; then
                for func in "${BATTERY_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Run Service & AI Optimization?"; then
                for func in "${SERVICE_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Run Virtual Resources Optimization?"; then
                for func in "${VIRTUAL_FUNCTIONS[@]}"; do
                    $func
                done
            fi

            if ask_yes_no "Install Monitoring Tools?"; then
                for func in "${MONITORING_FUNCTIONS[@]}"; do
                    $func
                done
            fi
            ;;

        3)
            # Run individual functions
            echo "Select functions to run:"
            echo ""
            for func in "${ALL_FUNCTIONS[@]}"; do
                if ask_yes_no "Run ${func}?"; then
                    $func
                fi
            done
            ;;

        4)
            # Quick performance boost
            echo ""
            echo "🚀 Running Quick Performance Boost..."
            echo "This will run the most impactful optimizations"
            echo ""
            
            # Essential optimizations for immediate performance gain
            clear_caches
            purge_memory
            advanced_memory_optimization
            advanced_cpu_optimization
            advanced_gpu_optimization
            general_system_smoothness
            
            echo ""
            echo "✅ Quick Performance Boost Complete!"
            ;;

        *)
            echo "Invalid choice. Running quick performance boost..."
            clear_caches
            purge_memory
            advanced_memory_optimization
            general_system_smoothness
            ;;
    esac
fi

# --- Final Report ---
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Optimization Complete!                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Calculate execution time
END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
MINUTES=$((EXECUTION_TIME / 60))
SECONDS=$((EXECUTION_TIME % 60))

# System summary
echo "📊 System Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  macOS Version: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "  Architecture: $(uname -m)"
echo "  Hostname: $(hostname)"
echo "  Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
echo ""
echo "💾 Disk Space:"
echo "  Available: $(df -h / | awk 'NR==2 {print $4}') / $(df -h / | awk 'NR==2 {print $2}')"
echo "  Used: $(df -h / | awk 'NR==2 {print $5}')"
echo ""
echo "🧠 Memory:"
MEMORY_FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
MEMORY_FREE_MB=$((MEMORY_FREE * 4096 / 1024 / 1024))
echo "  Free Memory: ~${MEMORY_FREE_MB}MB"
echo ""
echo "⏱️  Execution Time: ${MINUTES}m ${SECONDS}s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Recommendations
echo "📝 Post-Optimization Recommendations:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Restart your Mac to apply all changes"
echo "  ✓ Run Activity Monitor to check resource usage"
echo "  ✓ Test system performance with your daily applications"
echo "  ✓ Monitor battery life (if applicable)"
echo "  ✓ Check ~/performance_monitor.sh for ongoing monitoring"
echo ""
echo "  For best results:"
echo "    • Keep at least 15% of disk space free"
echo "    • Close unused applications"
echo "    • Restart weekly for optimal performance"
echo "    • Run this script monthly for maintenance"
echo ""

# Performance tips
echo "💡 Additional Performance Tips:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Disable FileVault if you don't need encryption"
echo "  2. Use an external SSD for Time Machine backups"
echo "  3. Upgrade RAM if you have less than 8GB"
echo "  4. Keep macOS and apps updated"
echo "  5. Use lightweight alternatives to resource-heavy apps"
echo "  6. Disable visual effects in Accessibility settings"
echo "  7. Use Activity Monitor to identify resource hogs"
echo "  8. Clear Safari/Chrome data regularly"
echo "  9. Uninstall unused applications completely"
echo "  10. Consider clean macOS reinstall if system is very old"
echo ""

# Installed tools
if command -v htop &> /dev/null || command -v glances &> /dev/null; then
    echo "🛠️  Installed Monitoring Tools:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    command -v htop &> /dev/null && echo "  ✓ htop - Interactive process viewer"
    command -v iftop &> /dev/null && echo "  ✓ iftop - Network bandwidth monitor"
    command -v iotop &> /dev/null && echo "  ✓ iotop - I/O monitor"
    command -v glances &> /dev/null && echo "  ✓ glances - Complete system monitor"
    command -v smartctl &> /dev/null && echo "  ✓ smartctl - SSD/HDD health monitor"
    command -v battery &> /dev/null && echo "  ✓ battery - Battery status CLI"
    echo ""
    echo "  Run these tools from Terminal for detailed monitoring"
    echo ""
fi

# Troubleshooting
echo "🔧 Troubleshooting:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  If you experience issues after optimization:"
echo "    • Boot into Safe Mode (hold Shift during startup)"
echo "    • Reset SMC and NVRAM (see Section 39 instructions)"
echo "    • Run Apple Diagnostics (hold D during startup)"
echo "    • Check Console.app for error messages"
echo "    • Revert specific changes if needed"
echo ""

# Save optimization log
LOG_FILE=~/Desktop/macos_optimization_log_$(date +%Y%m%d_%H%M%S).txt
{
    echo "macOS Optimization Log"
    echo "======================"
    echo "Date: $(date)"
    echo "Version: $SCRIPT_VERSION"
    echo "System: $(sw_vers -productVersion)"
    echo "Architecture: $(uname -m)"
    echo ""
    echo "Optimizations Applied:"
    echo "- Check terminal output for details"
    echo ""
    echo "System Status:"
    echo "- Disk Space: $(df -h / | awk 'NR==2 {print $4}') available"
    echo "- Execution Time: ${MINUTES}m ${SECONDS}s"
} > "$LOG_FILE"

echo "📄 Optimization log saved to: $LOG_FILE"
echo ""

# Clean up admin privileges keep-alive
if [[ -n "$ADMIN_KEEP_ALIVE_PID" ]]; then
    kill "$ADMIN_KEEP_ALIVE_PID" 2>/dev/null
fi

# Final message
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Thank you for using the Enhanced macOS Performance Suite!   ║"
echo "║                                                              ║"
echo "║  For support and updates, visit:                            ║"
echo "║  • GitHub: https://github.com/TheCreateGM/optimize-macos    ║"
echo "║  • Issues: Report bugs and request features                 ║"
echo "║                                                              ║"
echo "║  Please restart your Mac for all changes to take effect.    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Ask if user wants to restart now
if ask_yes_no "Restart Mac now to apply all optimizations?"; then
    echo "Restarting in 10 seconds... (Press Ctrl+C to cancel)"
    sleep 10
    sudo shutdown -r now
else
    echo "Please remember to restart your Mac later."
fi

exit 0
