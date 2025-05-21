#!/bin/bash

# Telepipe Installer Script - Version 1.0.3

# Clear screen
clear

echo "Welcome to this Telepipe installer!"
echo

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p /etc/telepipe
mkdir -p /usr/local/bin

# Install dependencies
echo "Checking for dependencies..."
if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y curl
    elif command -v yum &> /dev/null; then
        yum install -y curl
    elif command -v brew &> /dev/null; then
        brew install curl
    else
        echo "Package manager not detected. Please install curl manually."
        exit 1
    fi
fi

# Get necessary information
echo
echo "Please provide your Telegram bot token"
echo "(get it from BotFather https://t.me/botfather):"
read -r BOT_TOKEN

echo
echo "Please provide your Telegram chat ID:"
read -r CHAT_ID

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

# Create configuration file
echo
echo "Creating configuration file..."
cat > /etc/telepipe/config << EOF
# Telepipe Configuration File

# Your Telegram Bot Token
# Get it from BotFather (https://t.me/botfather)
BOT_TOKEN="${BOT_TOKEN}"

# Telegram Chat ID
# For channels/groups with -100 prefix, use the full ID including -100
CHAT_ID="${CHAT_ID}"

# Maximum message length before sending as a file (in characters)
# Default: 4096
MAX_LEN=${MAX_LEN}

# Request timeout in seconds
# Default: 5
TIMEOUT=${TIMEOUT}

# Whether to disable link previews in Telegram (true/false)
# Default: true
DISABLE_LINK_PREVIEW=${DISABLE_LINK_PREVIEW}
EOF

# Install telepipe script
echo "Installing telepipe to /usr/local/bin..."
# Copy the file directly instead of recreating it
cp "$(dirname "$0")/telepipe" /usr/local/bin/telepipe

# Make both files executable and secure
chmod 755 /usr/local/bin/telepipe
chmod 600 /etc/telepipe/config

# Test if curl is working
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
echo "Configuration file: /etc/telepipe/config"
echo "Binary location: /usr/local/bin/telepipe"
echo