#!/bin/bash

# Telepipe Installer Script - Version 1.0.1

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

# Create telepipe script
echo "Installing telepipe to /usr/local/bin..."
cat > /usr/local/bin/telepipe << 'EOF'
#!/bin/bash

# Telepipe: Send messages to Telegram from your terminal
VERSION="1.0.0"

# Configuration file location
CONFIG_FILE="/etc/telepipe/config"

# Display help message
show_help() {
    cat << EOF_HELP
Telepipe v${VERSION} - Send messages to Telegram from your terminal

Usage: telepipe [OPTIONS]
   or: command | telepipe
   or: cat file.txt | telepipe

When used without options, telepipe reads from standard input and sends 
the content to Telegram.

Options:
  -h, --help     Show this help message and exit
  -v, --version  Show version information and exit

Examples:
  echo "Hello World" | telepipe
  uptime | telepipe
  cat logfile.txt | telepipe

Configuration: 
  Edit settings in ${CONFIG_FILE}
EOF_HELP
    exit 0
}

# Display version information
show_version() {
    echo "Telepipe v${VERSION}"
    exit 0
}

# Check for command line options
if [ "$#" -gt 0 ]; then
    case "$1" in
        -h|--help)
            show_help
            ;;
        -v|--version)
            show_version
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            echo "Try 'telepipe --help' for more information." >&2
            exit 1
            ;;
    esac
fi

# Check if there's input on stdin
if [ -t 0 ]; then
    # No stdin, show help
    show_help
fi

# Check if config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file not found at $CONFIG_FILE" >&2
  exit 1
fi

# Load configuration file
source "$CONFIG_FILE"

# Check for required configuration
if [[ -z "$BOT_TOKEN" ]]; then
  echo "Error: No Telegram bot token configured. Please set BOT_TOKEN in $CONFIG_FILE" >&2
  exit 1
fi

if [[ -z "$CHAT_ID" ]]; then
  echo "Error: No Telegram chat ID configured. Please set CHAT_ID in $CONFIG_FILE" >&2
  exit 1
fi

# Set defaults for optional parameters if not defined in config
: "${MAX_LEN:=4096}"
: "${TIMEOUT:=5}"
: "${DISABLE_LINK_PREVIEW:=true}"

# Read from stdin and interpret escape sequences (like \n)
TEXT=$(echo -e "$(cat)")

# Process response and generate URL
process_response() {
  local resp=$1
  local exit_code=$2
  
  # Check if curl timed out or had connection issues
  if [[ $exit_code -ne 0 ]]; then
    echo "Error: Request to Telegram API failed (timeout or connection error)" >&2
    return 1
  fi
  
  # First check if the request was successful
  if echo "$resp" | grep -q '"ok":true'; then
    # Try to extract the message_id using grep (more portable than jq)
    local id=$(echo "$resp" | grep -o '"message_id":[0-9]*' | grep -o '[0-9]*')
    
    if [[ -n "$id" ]]; then
      # Generate URL based on chat ID format
      if [[ $CHAT_ID == @* ]]; then
        echo "https://t.me/${CHAT_ID#@}/${id}"
      elif [[ $CHAT_ID == -100* ]]; then
        local channel_num=${CHAT_ID#-100}
        echo "https://t.me/c/${channel_num}/${id}"
      else
        # If it's a direct message or unsupported format, just return success
        echo "Message sent successfully (ID: ${id})"
      fi
      return 0
    fi
  fi
  
  # If we couldn't extract the message_id or the request failed
  echo "Error: Failed to send message or extract message_id:" >&2
  echo "$resp" | grep -o '"description":"[^"]*"' >&2
  return 1
}

# Send message and get response
if [[ ${#TEXT} -gt $MAX_LEN ]]; then
  # For long messages, send as file
  # Use a more secure random string generation
  random_string=$(head -c 16 /dev/urandom | md5sum | head -c 8)
  tmpfile="/tmp/tgmsg.${random_string}.txt"
  echo "$TEXT" > "$tmpfile"
  
  response=$(curl -s --connect-timeout $TIMEOUT --max-time $TIMEOUT -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
    -F chat_id="${CHAT_ID}" \
    -F document=@"${tmpfile}")
  curl_status=$?
  
  rm -f "$tmpfile"
else
  # For shorter messages, send as text with disable_web_page_preview option
  disable_preview=""
  if [[ "$DISABLE_LINK_PREVIEW" == "true" ]]; then
    disable_preview="-d disable_web_page_preview=true"
  fi
  
  response=$(curl -s --connect-timeout $TIMEOUT --max-time $TIMEOUT -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    --data-urlencode text="${TEXT}" \
    $disable_preview)
  curl_status=$?
fi

# Process response and output URL
process_response "$response" $curl_status
exit $?
EOF

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
echo
echo "Configuration file: /etc/telepipe/config"
echo "Binary location: /usr/local/bin/telepipe"
echo