#!/bin/bash

# macOS Minimal Rice Script
# Aesthetic & Performance Optimized Configuration
# Compatible with macOS 10.14+

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════╗
║   macOS Minimal Rice Configuration   ║
║        Aesthetic & Optimized          ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is designed for macOS only${NC}"
    exit 1
fi

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}━━━ $1 ━━━${NC}\n"
}

# Function to ask yes/no questions
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Backup existing settings
backup_settings() {
    print_section "Creating Backup"
    BACKUP_DIR="$HOME/.macos_rice_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup dock settings
    defaults read com.apple.dock > "$BACKUP_DIR/dock_settings.plist" 2>/dev/null || true

    echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_section "Installing Homebrew"
        echo -e "${YELLOW}Homebrew is required but not installed.${NC}"
        echo -e "${YELLOW}Installing Homebrew automatically...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == 'arm64' ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        echo -e "${GREEN}✓ Homebrew installed successfully${NC}"
    else
        echo -e "${GREEN}✓ Homebrew already installed${NC}"
    fi
}

# Install essential tools
install_tools() {
    print_section "Installing Essential Tools"

    # Ensure Homebrew is in PATH
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Error: Homebrew not found in PATH${NC}"
        return 1
    fi

    echo -e "${YELLOW}Updating Homebrew...${NC}"
    brew update

    local tools=(
        "neofetch"          # System info
        "htop"              # Process viewer
        "bat"               # Better cat
        "exa"               # Better ls
        "fzf"               # Fuzzy finder
        "ripgrep"           # Better grep
        "fd"                # Better find
        "starship"          # Terminal prompt
    )

    echo -e "${YELLOW}Checking and installing tools automatically...${NC}\n"

    for tool in "${tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            echo -e "${GREEN}✓ $tool already installed${NC}"
        else
            echo -e "${YELLOW}► Installing $tool...${NC}"
            if brew install "$tool"; then
                echo -e "${GREEN}✓ $tool installed successfully${NC}"
            else
                echo -e "${RED}✗ Failed to install $tool${NC}"
            fi
        fi
    done

    echo -e "\n${GREEN}✓ All tools processed${NC}"
}

# Configure Dock - Minimal Style
configure_dock() {
    print_section "Configuring Dock (Minimal)"

    # Minimize dock size
    defaults write com.apple.dock tilesize -int 36

    # Auto-hide dock
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0.1
    defaults write com.apple.dock autohide-time-modifier -float 0.5

    # Remove all apps from dock (clean slate)
    if ask_yes_no "Remove all apps from Dock for minimal look?"; then
        defaults write com.apple.dock persistent-apps -array
    fi

    # Minimize dock magnification
    defaults write com.apple.dock magnification -bool false

    # Show only active apps
    defaults write com.apple.dock static-only -bool true

    # Don't show recent apps
    defaults write com.apple.dock show-recents -bool false

    # Minimize animation
    defaults write com.apple.dock minimize-to-application -bool true

    echo -e "${GREEN}✓ Dock configured${NC}"
}

# Configure Finder - Clean & Minimal
configure_finder() {
    print_section "Configuring Finder"

    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Show file extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Default to list view
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Disable animations
    defaults write com.apple.finder DisableAllAnimations -bool true

    # Keep folders on top
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # Search current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable warning when changing file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    echo -e "${GREEN}✓ Finder configured${NC}"
}

# Configure Menu Bar - Minimal
configure_menubar() {
    print_section "Configuring Menu Bar"

    # Auto-hide menu bar
    if ask_yes_no "Auto-hide menu bar?"; then
        defaults write NSGlobalDomain _HIHideMenuBar -bool true
    fi

    # Show battery percentage
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"

    # Clock format (24-hour)
    defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"

    echo -e "${GREEN}✓ Menu bar configured${NC}"
}

# Configure System Appearance
configure_appearance() {
    print_section "Configuring System Appearance"

    # Dark mode
    if ask_yes_no "Enable Dark Mode?"; then
        osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
    fi

    # Reduce transparency
    defaults write com.apple.universalaccess reduceTransparency -bool true

    # Reduce motion
    defaults write com.apple.universalaccess reduceMotion -bool true

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # Save screenshots to dedicated folder
    mkdir -p "$HOME/Pictures/Screenshots"
    defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

    # Save screenshots as PNG
    defaults write com.apple.screencapture type -string "png"

    echo -e "${GREEN}✓ Appearance configured${NC}"
}

# Optimize Performance
optimize_performance() {
    print_section "Optimizing Performance"

    # Disable animations
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    defaults write com.apple.dock expose-animation-duration -float 0.1

    # Speed up Mission Control
    defaults write com.apple.dock expose-animation-duration -float 0.1

    # Disable dashboard
    defaults write com.apple.dashboard mcx-disabled -bool true

    # Disable Time Machine prompts
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    # Disable sudden motion sensor (for SSDs)
    sudo pmset -a sms 0 2>/dev/null || true

    # Disable hibernation
    if ask_yes_no "Disable hibernation (recommended for SSD)?"; then
        sudo pmset -a hibernatemode 0
        sudo rm -f /var/vm/sleepimage
        sudo mkdir /var/vm/sleepimage
    fi

    echo -e "${GREEN}✓ Performance optimized${NC}"
}

# Configure Terminal
configure_terminal() {
    print_section "Configuring Terminal"

    # Check and install Starship if not present
    if ! command -v starship &> /dev/null; then
        echo -e "${YELLOW}Starship not found. Installing automatically...${NC}"
        if brew install starship; then
            echo -e "${GREEN}✓ Starship installed${NC}"
        else
            echo -e "${RED}✗ Failed to install Starship${NC}"
            return 1
        fi
    fi

    if command -v starship &> /dev/null; then
        # Create starship config
        mkdir -p "$HOME/.config"
        cat > "$HOME/.config/starship.toml" << 'STARSHIP_EOF'
# Minimal Starship Configuration
format = """
[┌───────────────────>](bold green)
[│](bold green) $directory$git_branch$git_status
[└─>](bold green) """

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold yellow"
conflicted = "⚔️ "
ahead = "⬆️ "
behind = "⬇️ "
diverged = "⬍⬌ "
untracked = "🤷 "
stashed = "📦 "
modified = "📝 "
staged = "✓ "
renamed = "➡️ "
deleted = "🗑️ "

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
STARSHIP_EOF

        # Add to shell config
        SHELL_CONFIG="$HOME/.zshrc"
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        fi

        if ! grep -q "starship init" "$SHELL_CONFIG" 2>/dev/null; then
            echo '' >> "$SHELL_CONFIG"
            echo '# Starship prompt' >> "$SHELL_CONFIG"
            echo 'eval "$(starship init zsh)"' >> "$SHELL_CONFIG"
        fi

        echo -e "${GREEN}✓ Starship configured${NC}"
    fi

    # Detect shell config file
    SHELL_CONFIG="$HOME/.zshrc"
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi

    # Check if aliases already exist
    if grep -q "# Minimal Rice Aliases" "$SHELL_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓ Aliases already configured${NC}"
    else
        # Add useful aliases only if tools are installed
        echo -e "${YELLOW}Adding terminal aliases...${NC}"

        cat >> "$SHELL_CONFIG" << 'ALIAS_EOF'

# Minimal Rice Aliases
ALIAS_EOF

        # Add aliases only for installed tools
        command -v exa &> /dev/null && cat >> "$SHELL_CONFIG" << 'ALIAS_EOF'
alias ls='exa --icons --group-directories-first'
alias ll='exa -l --icons --group-directories-first'
alias la='exa -la --icons --group-directories-first'
ALIAS_EOF

        command -v bat &> /dev/null && echo "alias cat='bat --style=plain'" >> "$SHELL_CONFIG"
        command -v fd &> /dev/null && echo "alias find='fd'" >> "$SHELL_CONFIG"
        command -v rg &> /dev/null && echo "alias grep='rg'" >> "$SHELL_CONFIG"
        command -v htop &> /dev/null && echo "alias top='htop'" >> "$SHELL_CONFIG"

        # Add general aliases
        cat >> "$SHELL_CONFIG" << 'ALIAS_EOF'
alias cleanup='find . -type f -name "*.DS_Store" -ls -delete'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
ALIAS_EOF

        echo -e "${GREEN}✓ Aliases configured${NC}"
    fi

    echo -e "${GREEN}✓ Terminal configuration complete${NC}"
}

# Install fonts
install_fonts() {
    print_section "Installing Fonts"

    if ask_yes_no "Install Nerd Fonts (recommended for terminal)?"; then
        echo -e "${YELLOW}Adding font repository...${NC}"
        brew tap homebrew/cask-fonts 2>/dev/null || true

        local fonts=(
            "font-jetbrains-mono-nerd-font"
            "font-fira-code-nerd-font"
        )

        for font in "${fonts[@]}"; do
            if brew list --cask "$font" &>/dev/null; then
                echo -e "${GREEN}✓ $font already installed${NC}"
            else
                echo -e "${YELLOW}► Installing $font...${NC}"
                if brew install --cask "$font"; then
                    echo -e "${GREEN}✓ $font installed successfully${NC}"
                else
                    echo -e "${RED}✗ Failed to install $font${NC}"
                fi
            fi
        done

        echo -e "${GREEN}✓ Fonts installation complete${NC}"
    else
        echo -e "${YELLOW}Skipping font installation${NC}"
    fi
}

# Cleanup and restart services
cleanup_restart() {
    print_section "Finalizing Configuration"

    echo "Restarting affected services..."
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    echo -e "${GREEN}✓ Services restarted${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}This script will configure your macOS for a minimal, aesthetic setup.${NC}"
    echo -e "${YELLOW}A backup will be created before making changes.${NC}\n"

    if ! ask_yes_no "Continue?"; then
        echo "Exiting..."
        exit 0
    fi

    backup_settings
    install_homebrew
    install_tools
    configure_dock
    configure_finder
    configure_menubar
    configure_appearance
    optimize_performance
    configure_terminal
    install_fonts
    cleanup_restart

    print_section "Complete!"
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  macOS Rice Configuration Complete!  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please restart your Mac for all changes to take effect.${NC}"
    echo -e "${YELLOW}Backup location: $BACKUP_DIR${NC}"
    echo ""
    echo -e "${BLUE}To restore defaults, run:${NC}"
    echo "  defaults read com.apple.dock"
    echo ""
    echo -e "${BLUE}Enjoy your minimal macOS setup!${NC}"
}

# Run main function
main
