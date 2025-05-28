# Telepipe

A simple command-line utility to send messages or files to Telegram chat directly from your terminal.

## Features

- Send messages to Telegram channel/chat/group directly from command line
- **Message formatting support** with Markdown and HTML modes
- Interactive shell mode for multi-line messaging
- Automatically switch between message and file mode based on content length
- Generate shareable Telegram links
- Quiet/Silent mode for scripting
- Easy installation with guided setup
- Simple configuration

## Installation

1. Clone this repository:

```bash
git clone https://github.com/linuxmaster14/telepipe.git
cd telepipe
```

2. Run the installation script with an optional topic name:

```bash
chmod +x installer.sh
sudo ./installer.sh
```

During installation, you'll need to provide:
1. Your Telegram Bot Token (get it from [BotFather](https://t.me/botfather))
2. Your Chat ID (can be a group, channel, or user ID)

## Usage

```bash
# Show help
telepipe --help

# Show version
telepipe --version

# Send a simple message
echo "Hello from my server!" | telepipe

# Send the output of a command
uptime | telepipe

# Send the contents of a file
cat logfile.txt | telepipe

# Send a message without displaying the URL (quiet mode)
echo "Notification" | telepipe --quiet

# Start an interactive multi-line messaging session
telepipe --interactive

# Send formatted messages with Markdown
echo "*Bold text* and _italic text_" | telepipe --format markdown

# Send formatted messages with HTML
echo "<b>Bold</b> and <i>italic</i>" | telepipe --format html

# Send code snippets with formatting
echo 'Check this `inline code` example' | telepipe --format markdown

# Send code blocks
echo -e "\`\`\`bash\necho 'Hello World'\nls -la\n\`\`\`" | telepipe --format markdown

# Use it in your scripts
backup_db() {
  # backup logic here
  if [ $? -eq 0 ]; then
    echo "Database backup completed successfully at $(date)" | telepipe
  else
    echo "Database backup FAILED at $(date)" | telepipe
  fi
}

# Script example with quiet mode
monitoring_check() {
  if ! ping -c 1 server.example.com > /dev/null; then
    echo "Server unreachable at $(date)" | telepipe --quiet && 
    echo "Alert sent"
  fi
}
```

## Options

- `-h, --help` - Show this help message and exit
- `-i, --interactive` - Enter interactive mode for multi-line messaging
- `-q, --quiet` - Quiet mode - suppress output (except errors)
- `-v, --version` - Show version information and exit
- `--format MODE` - Set message formatting mode: `markdown`, `html`, or `none`

## Message Formatting

Telepipe supports three formatting modes:

### Markdown Mode (`--format markdown`)
Uses Telegram's MarkdownV2 formatting with automatic escaping of special characters:

- **Bold**: `*bold text*`
- **Italic**: `_italic text_`
- **Inline code**: `` `inline code` ``
- **Code blocks**: 
  ```
  ```language
  code block
  ```
  ```

Example:
```bash
echo "*Important*: Server status is \`ONLINE\`" | telepipe --format markdown
```

### HTML Mode (`--format html`)
Uses HTML formatting tags:

- **Bold**: `<b>bold text</b>`
- **Italic**: `<i>italic text</i>`
- **Inline code**: `<code>inline code</code>`
- **Code blocks**: `<pre>code block</pre>`

Example:
```bash
echo "<b>Alert</b>: Database backup <code>COMPLETED</code>" | telepipe --format html
```

### Plain Text Mode (`--format none` or default)
Sends messages without any formatting - useful when you want to send literal markdown/HTML characters.

### Interactive Mode Formatting
In interactive mode, you can change formatting on-the-fly:

```bash
telepipe --interactive
# Then use commands like:
# /format markdown
# /format html
# /status
```

## Configuration

The configuration file is located at `/etc/telepipe/config` and includes the following settings:

- `BOT_TOKEN`: Your Telegram bot token from BotFather
- `CHAT_ID`: ID of the chat where messages will be sent
- `MAX_LEN`: Maximum message length before sending as file (default: 4096)
- `TIMEOUT`: API request timeout in seconds (default: 5)
- `DISABLE_LINK_PREVIEW`: Whether to disable link previews (default: true)

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.