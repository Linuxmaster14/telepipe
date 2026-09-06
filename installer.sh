#!/bin/bash

# Telepipe Installer Script - Version 1.1.0

if [ -t 1 ] && command -v clear >/dev/null 2>&1; then
    clear
fi

echo "Welcome to this Telepipe installer!"
echo

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 1
TELEPIPE_SOURCE="${SCRIPT_DIR}/telepipe"

if [ ! -f "$TELEPIPE_SOURCE" ]; then
    echo "Error: Could not find the telepipe executable at $TELEPIPE_SOURCE" >&2
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    INSTALL_MODE="system"
    BIN_DIR="/usr/local/bin"
    CONFIG_DIR="/etc/telepipe"
    CONFIG_DIR_MODE="755"
else
    INSTALL_MODE="user"
    if [ -z "${HOME:-}" ]; then
        echo "Error: HOME is not set; cannot determine user installation paths." >&2
        exit 1
    fi
    BIN_DIR="$HOME/.local/bin"
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/telepipe"
    CONFIG_DIR_MODE="700"
fi

INSTALL_PATH="${BIN_DIR}/telepipe"
CONFIG_FILE="${CONFIG_DIR}/config"

install_curl_for_system() {
    echo "curl not found. Installing it for the system..."

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl
    elif command -v apk >/dev/null 2>&1; then
        apk add curl
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm curl
    elif command -v brew >/dev/null 2>&1; then
        brew install curl
    else
        echo "Error: No supported package manager was detected." >&2
        echo "Install curl with your operating system's package manager, then rerun the installer." >&2
        return 1
    fi
}

explain_user_curl_install() {
    echo "Error: curl is required, but it is not installed." >&2
    echo "Telepipe will not use sudo or otherwise elevate privileges in user mode." >&2

    if command -v apt-get >/dev/null 2>&1; then
        echo "Install it with: sudo apt-get update && sudo apt-get install curl" >&2
    elif command -v dnf >/dev/null 2>&1; then
        echo "Install it with: sudo dnf install curl" >&2
    elif command -v yum >/dev/null 2>&1; then
        echo "Install it with: sudo yum install curl" >&2
    elif command -v apk >/dev/null 2>&1; then
        echo "Install it with: sudo apk add curl" >&2
    elif command -v pacman >/dev/null 2>&1; then
        echo "Install it with: sudo pacman -S curl" >&2
    else
        echo "Install curl with your operating system's package manager, then rerun the installer." >&2
    fi
}

echo "Installation mode: ${INSTALL_MODE}"
echo "Checking for dependencies..."
if ! command -v curl >/dev/null 2>&1; then
    if [ "$INSTALL_MODE" = "system" ]; then
        if ! install_curl_for_system || ! command -v curl >/dev/null 2>&1; then
            echo "Error: curl could not be installed. Install it manually, then rerun the installer." >&2
            exit 1
        fi
    elif command -v brew >/dev/null 2>&1; then
        echo "curl not found. Installing it with Homebrew (without sudo)..."
        if ! brew install curl || ! command -v curl >/dev/null 2>&1; then
            echo "Error: Homebrew could not install curl. Run 'brew install curl', then rerun the installer." >&2
            exit 1
        fi
    else
        explain_user_curl_install
        exit 1
    fi
fi

echo "Creating directories..."
if ! install -d -m 755 "$BIN_DIR"; then
    echo "Error: Could not create executable directory $BIN_DIR" >&2
    exit 1
fi
if ! install -d -m "$CONFIG_DIR_MODE" "$CONFIG_DIR"; then
    echo "Error: Could not create configuration directory $CONFIG_DIR" >&2
    exit 1
fi

echo
echo "Please provide your Telegram bot token"
echo "(get it from BotFather https://t.me/botfather; input will be hidden):"
read -r -s BOT_TOKEN
echo

if [ -z "$BOT_TOKEN" ]; then
    echo "Error: The Telegram bot token cannot be empty." >&2
    exit 1
fi

echo
echo "Please provide your Telegram chat ID:"
read -r CHAT_ID

if [ -z "$CHAT_ID" ]; then
    echo "Error: The Telegram chat ID cannot be empty." >&2
    exit 1
fi

echo
echo "Maximum message length before sending as file:"
echo "  1) 1024 characters"
echo "  2) 4096 characters (recommended)"
echo "  3) 8192 characters"
echo "  4) Specify custom length"
echo "Max length [2]: "
read -r max_len_choice

case $max_len_choice in
    1) MAX_LEN=1024 ;;
    3) MAX_LEN=8192 ;;
    4)
        echo "Enter custom length: "
        read -r MAX_LEN
        ;;
    *) MAX_LEN=4096 ;;
esac

if ! [[ "$MAX_LEN" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Maximum message length must be a positive integer." >&2
    exit 1
fi

echo
echo "Request timeout in seconds:"
echo "  1) 3 seconds"
echo "  2) 5 seconds (recommended)"
echo "  3) 10 seconds"
echo "  4) Specify custom timeout"
echo "Timeout [2]: "
read -r timeout_choice

case $timeout_choice in
    1) TIMEOUT=3 ;;
    3) TIMEOUT=10 ;;
    4)
        echo "Enter custom timeout: "
        read -r TIMEOUT
        ;;
    *) TIMEOUT=5 ;;
esac

if ! [[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Request timeout must be a positive integer." >&2
    exit 1
fi

echo
echo "Should Telepipe disable link previews in Telegram?"
echo "  1) Yes (recommended)"
echo "  2) No"
echo "Disable link previews [1]: "
read -r preview_choice

case $preview_choice in
    2) DISABLE_LINK_PREVIEW=false ;;
    *) DISABLE_LINK_PREVIEW=true ;;
esac

CONFIG_TMP=""
cleanup() {
    if [ -n "$CONFIG_TMP" ]; then
        rm -f "$CONFIG_TMP"
    fi
}
trap cleanup EXIT

echo
echo "Creating configuration file..."
umask 077
CONFIG_TMP=$(mktemp "${CONFIG_DIR}/.config.XXXXXX") || {
    echo "Error: Could not create a temporary configuration file in $CONFIG_DIR" >&2
    exit 1
}
if ! chmod 600 "$CONFIG_TMP"; then
    echo "Error: Could not secure temporary configuration file $CONFIG_TMP" >&2
    exit 1
fi

{
    printf '%s\n' '# Telepipe Configuration File' ''
    printf '%s\n' '# Your Telegram Bot Token' '# Get it from BotFather (https://t.me/botfather)'
    printf 'BOT_TOKEN=%q\n\n' "$BOT_TOKEN"
    printf '%s\n' '# Telegram Chat ID' '# For channels/groups with -100 prefix, use the full ID including -100'
    printf 'CHAT_ID=%q\n\n' "$CHAT_ID"
    printf '%s\n' '# Maximum message length before sending as a file (in characters)' '# Default: 4096'
    printf 'MAX_LEN=%q\n\n' "$MAX_LEN"
    printf '%s\n' '# Request timeout in seconds' '# Default: 5'
    printf 'TIMEOUT=%q\n\n' "$TIMEOUT"
    printf '%s\n' '# Whether to disable link previews in Telegram (true/false)' '# Default: true'
    printf 'DISABLE_LINK_PREVIEW=%q\n' "$DISABLE_LINK_PREVIEW"
} > "$CONFIG_TMP"

if ! mv -f "$CONFIG_TMP" "$CONFIG_FILE"; then
    echo "Error: Could not install configuration file at $CONFIG_FILE" >&2
    exit 1
fi
CONFIG_TMP=""
if ! chmod 600 "$CONFIG_FILE"; then
    echo "Error: Could not secure configuration file $CONFIG_FILE" >&2
    exit 1
fi

echo "Installing telepipe to $INSTALL_PATH..."
if ! install -m 755 "$TELEPIPE_SOURCE" "$INSTALL_PATH"; then
    echo "Error: Could not install telepipe at $INSTALL_PATH" >&2
    exit 1
fi

echo
echo "Testing connection to Telegram API..."
if curl -s -m 10 -o /dev/null -w "%{http_code}" "https://api.telegram.org/bot${BOT_TOKEN}/getMe" | grep -q "200"; then
    echo "Connection successful! Bot token appears valid."
else
    echo "Warning: Could not verify bot token. Continuing installation anyway."
    echo "Please check your network connection and bot token later."
fi

echo
echo "Installation completed!"
echo
echo "Usage:"
echo "  echo \"Hello World\" | telepipe"
echo "  cat file.txt | telepipe"
echo "  command | telepipe"
echo "  command | telepipe --quiet  # No output if successful"
echo "  telepipe --interactive      # Start interactive multi-line messaging session"
echo
echo "Configuration file: $CONFIG_FILE"
echo "Binary location: $INSTALL_PATH"

if [ "$INSTALL_MODE" = "user" ]; then
    case ":${PATH:-}:" in
        *":${BIN_DIR}:"*) ;;
        *)
            echo
            echo "Note: $BIN_DIR is not currently on PATH."
            echo "Add this line to the startup file for your shell, then open a new terminal:"
            printf '  export PATH="%s:$PATH"\n' "$BIN_DIR"
            echo "The installer did not modify any shell startup files."
            ;;
    esac
fi

echo
