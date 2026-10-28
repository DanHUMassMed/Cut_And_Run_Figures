#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# required_dependencies.sh
# Checks for and installs system prerequisites: curl, make, uv, and Python 3.12.
# Supports macOS and major Linux distributions.
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

OS="$(uname -s)"

# Ensure common user-binary paths are available in PATH
for p in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
    if [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]]; then
        export PATH="$p:$PATH"
    fi
done

# Detect sudo if needed on Linux
SUDO=""
if [ "$OS" = "Linux" ] && [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        error "Root privileges or 'sudo' required to install system packages on Linux."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# 1. Check & Install curl
# ------------------------------------------------------------------------------
check_curl() {
    command -v curl >/dev/null 2>&1
}

install_curl() {
    info "Installing 'curl'..."
    case "$OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install curl
            else
                error "curl is missing. Please install Homebrew (https://brew.sh) or Xcode Command Line Tools."
                exit 1
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                $SUDO apt-get update -y && $SUDO apt-get install -y curl
            elif command -v dnf >/dev/null 2>&1; then
                $SUDO dnf install -y curl
            elif command -v yum >/dev/null 2>&1; then
                $SUDO yum install -y curl
            elif command -v pacman >/dev/null 2>&1; then
                $SUDO pacman -Sy --noconfirm curl
            elif command -v apk >/dev/null 2>&1; then
                apk add --no-cache curl
            elif command -v zypper >/dev/null 2>&1; then
                $SUDO zypper install -y curl
            else
                error "Unsupported package manager. Please install 'curl' manually."
                exit 1
            fi
            ;;
        *)
            error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 2. Check & Install make
# ------------------------------------------------------------------------------
check_make() {
    if command -v make >/dev/null 2>&1; then
        return 0
    fi
    if command -v brew >/dev/null 2>&1; then
        local brew_prefix
        brew_prefix="$(brew --prefix make 2>/dev/null || true)"
        if [ -n "$brew_prefix" ] && [ -x "$brew_prefix/libexec/gnubin/make" ]; then
            export PATH="$brew_prefix/libexec/gnubin:$PATH"
            if command -v make >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    return 1
}

install_make() {
    info "Installing 'make'..."
    case "$OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install make
                local brew_gnubin
                brew_gnubin="$(brew --prefix make)/libexec/gnubin"
                if [ -d "$brew_gnubin" ]; then
                    export PATH="$brew_gnubin:$PATH"
                fi
            elif command -v xcode-select >/dev/null 2>&1; then
                warn "Prompting installation of Apple Command Line Tools (includes make)..."
                xcode-select --install || true
                info "Please complete the Apple installation dialog, then re-run this script."
                exit 0
            else
                error "Neither Homebrew nor xcode-select found. Install Homebrew (https://brew.sh) or Xcode tools."
                exit 1
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                $SUDO apt-get update -y && $SUDO apt-get install -y make build-essential
            elif command -v dnf >/dev/null 2>&1; then
                $SUDO dnf install -y make
            elif command -v yum >/dev/null 2>&1; then
                $SUDO yum install -y make
            elif command -v pacman >/dev/null 2>&1; then
                $SUDO pacman -Sy --noconfirm make
            elif command -v apk >/dev/null 2>&1; then
                apk add --no-cache make build-base
            elif command -v zypper >/dev/null 2>&1; then
                $SUDO zypper install -y make
            else
                error "Unsupported package manager. Please install 'make' manually."
                exit 1
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 3. Check & Install uv
# ------------------------------------------------------------------------------
check_uv() {
    command -v uv >/dev/null 2>&1
}

install_uv() {
    info "Installing 'uv' (Python package & environment manager)..."
    if check_curl; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        error "'curl' is required to install 'uv'."
        exit 1
    fi
    # Add newly installed uv to PATH in the current session
    for p in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
        if [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]]; then
            export PATH="$p:$PATH"
        fi
    done
}

# ==============================================================================
# Main Verification Flow
# ==============================================================================

echo -e "${BOLD}Checking required system dependencies...${RESET}"
echo "Operating System: $OS"
echo ""

# 1. curl
if check_curl; then
    success "curl is installed: $(command -v curl)"
else
    warn "curl not found."
    install_curl
    if check_curl; then
        success "curl installed successfully: $(command -v curl)"
    else
        error "Failed to install curl."
        exit 1
    fi
fi

# 2. make
if check_make; then
    success "make is installed: $(command -v make) ($(make --version | head -n 1))"
else
    warn "make not found."
    install_make
    if check_make; then
        success "make installed successfully: $(command -v make)"
    else
        error "Failed to install make."
        exit 1
    fi
fi

# 3. uv
if check_uv; then
    success "uv is installed: $(command -v uv) ($(uv --version))"
else
    warn "uv not found."
    install_uv
    if check_uv; then
        success "uv installed successfully: $(command -v uv) ($(uv --version))"
    else
        error "Failed to install uv. Make sure $HOME/.local/bin is in your PATH."
        exit 1
    fi
fi

echo ""
echo -e "${BOLD}${GREEN}====================================================================${RESET}"
echo -e "${BOLD}${GREEN}  All required dependencies (curl, make, uv) are ready!${RESET}"
echo -e "${BOLD}${GREEN}====================================================================${RESET}"
echo ""
echo -e "Next steps to complete setup:"
echo -e "  1. ${BOLD}make install${RESET}"
echo -e "     Sets up virtual environment, packages, kernel, and liftOver."
echo ""
echo -e "  2. Configure ${BOLD}.env${RESET} with your data directory (before running notebooks):"
echo -e "     ${BOLD}echo 'WALKER_LAB_DIR=\"/path/to/cut_run092226\"' > .env${RESET}"
echo -e "     (or open '.env' in TextEdit / nano)"
echo ""
echo -e "  3. ${BOLD}make notebook${RESET}"
echo -e "     Launches JupyterLab in your default browser."
echo ""
