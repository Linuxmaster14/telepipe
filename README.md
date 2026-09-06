# Telepipe

A simple command-line utility to send messages or files to Telegram chat directly from your terminal.

## Features

- Send messages to Telegram channel/chat/group directly from command line
- **File upload support** with original filename preservation
- **Video streaming support** with optimized playback in Telegram
- **Message formatting support** with Markdown and HTML modes
- **Scheduled message delivery** with specific time or delay options
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

2. Choose an installation mode.

For a per-user installation (recommended for normal interactive use), run without
`sudo`:

```bash
chmod +x installer.sh
./installer.sh
```

This installs the executable at `$HOME/.local/bin/telepipe` and writes the private
configuration file (mode `600`) to
`${XDG_CONFIG_HOME:-$HOME/.config}/telepipe/config`. The installer creates missing
directories but does not edit shell startup files. If `$HOME/.local/bin` is not on
your `PATH`, follow the instruction printed at the end of installation. For example:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

For a system-wide installation, run with `sudo`:

```bash
sudo ./installer.sh
```

This installs the executable at `/usr/local/bin/telepipe` and writes the private,
root-owned configuration file (mode `600`) to `/etc/telepipe/config`. This mode is
intended for root-run scripts and services. Other users can still use the system-wide
executable with their own per-user configuration or a readable file selected through
`TELEPIPE_CONFIG`.

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

# Schedule messages for future delivery
echo "Daily backup completed" | telepipe --schedule "2025-05-28 09:00:00"

# Send delayed messages
echo "Server maintenance starting" | telepipe --delay 1800  # 30 minutes delay

# Upload files with original names
telepipe --file backup.tar.gz
telepipe --file /path/to/document.pdf
telepipe --file archive.zip --quiet

# Upload videos with streaming support
telepipe --video movie.mp4
telepipe --video /path/to/video.avi

# Upload files/videos with captions
echo "Database backup from $(date)" | telepipe --file backup.sql
echo "Movie night! 🎬" | telepipe --video film.mp4

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

# Scheduled maintenance notifications
schedule_maintenance_alerts() {
  echo "🔧 Server maintenance starts in 1 hour" | telepipe --delay 3600
  echo "⚠️ Server maintenance starts in 15 minutes" | telepipe --delay 5400
  echo "🚨 Server maintenance starting NOW" | telepipe --delay 6900
}

# Daily report scheduling
schedule_daily_reports() {
  echo "📊 Daily system report: $(date)" | telepipe --schedule "$(date -v+1d '+%Y-%m-%d 09:00:00')"
}

# Automated backup with file upload
daily_backup() {
  local backup_file="backup-$(date +%Y%m%d).tar.gz"
  tar -czf "$backup_file" /important/data
  if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully at $(date)" | telepipe --file "$backup_file"
  else
    echo "❌ Backup failed at $(date)" | telepipe
  fi
}

# Log file monitoring with upload
check_error_logs() {
  local error_count=$(grep -c "ERROR" /var/log/app.log)
  if [ "$error_count" -gt 10 ]; then
    echo "🚨 High error count detected: $error_count errors" | telepipe --file /var/log/app.log
  fi
}
```

## Options

- `-h, --help` - Show this help message and exit
- `-i, --interactive` - Enter interactive mode for multi-line messaging
- `-q, --quiet` - Quiet mode - suppress output (except errors)
- `-v, --version` - Show version information and exit
- `--format MODE` - Set message formatting mode: `markdown`, `html`, or `none`
- `--schedule TIME` - Schedule message for specific time (YYYY-MM-DD HH:MM:SS)
- `--delay SECONDS` - Delay message delivery by specified seconds
- `--file PATH` - Upload a file to Telegram (preserves original filename)
- `--video PATH` - Upload a video with streaming support (auto-detects video metadata)

## Message Formatting

Telepipe supports three formatting modes:

### Markdown Mode (`--format markdown`)
Uses Telegram's MarkdownV2 formatting with automatic escaping of special characters:

- **Bold**: `*bold text*`
- **Italic**: `_italic text_`
- **Inline code**: `` `inline code` ``
- **Code blocks**: 
  ````
  ```language
  code block
  ```
  ````

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

## Scheduled Message Delivery

Telepipe supports scheduling messages for future delivery in two ways:

### Absolute Time Scheduling (`--schedule`)
Schedule a message for a specific date and time:

```bash
# Schedule a reminder for a specific time
echo "Meeting starts in 15 minutes" | telepipe --schedule "2025-05-28 14:45:00"

# Schedule daily reports
echo "Daily backup completed successfully" | telepipe --schedule "2025-05-29 09:00:00"

# Works with formatting
echo "*Important*: Server maintenance begins now" | telepipe --schedule "2025-05-28 22:00:00" --format markdown
```

### Relative Time Delay (`--delay`)
Delay message delivery by a specified number of seconds:

```bash
# Send reminder in 1 hour (3600 seconds)
echo "Backup completed" | telepipe --delay 3600

# Send alert in 30 minutes (1800 seconds)
echo "⚠️ Maintenance window starting soon" | telepipe --delay 1800

# Quick 5-minute delay
echo "Process finished successfully" | telepipe --delay 300
```

**Notes:**
- Scheduled messages run as background processes
- The process ID is displayed for tracking (unless using `--quiet`)
- Scheduling cannot be combined with `--interactive` mode
- Time format for `--schedule` is: `YYYY-MM-DD HH:MM:SS`
- Scheduled time must be in the future

## File Upload

Telepipe can upload files directly to Telegram while preserving their original filenames:

### Basic File Upload
```bash
# Upload a file
telepipe --file backup.tar.gz
telepipe --file /path/to/document.pdf
telepipe --file ~/Downloads/movie.mp4

# Upload with quiet mode (no URL output)
telepipe --file large-backup.zip --quiet
```

### File Upload with Caption
You can add a caption to uploaded files by piping text to telepipe:
```bash
# Add caption from command line
echo "Database backup from $(date)" | telepipe --file backup.sql

# Add caption from another command
hostname | telepipe --file system-report.txt

# Multi-line caption
echo -e "Weekly Report\nGenerated: $(date)\nSize: $(du -h report.pdf)" | telepipe --file report.pdf
```

### Practical Examples
```bash
# Backup with timestamp caption
echo "Backup completed at $(date)" | telepipe --file backup-$(date +%Y%m%d).tar.gz

# Log file with context
echo "Error logs from server crash at $(date)" | telepipe --file /var/log/error.log

# Automated script backup
tar -czf backup.tar.gz /important/data && echo "Backup created: $(du -h backup.tar.gz)" | telepipe --file backup.tar.gz
```

**Notes:**
- Maximum file size: 50MB (Telegram Bot API limit)
- Supports all file types
- Original filename is preserved
- Cannot be combined with `--interactive`, `--schedule`, or `--delay` options
- Caption text supports the same formatting as regular messages when used with `--format`

## Video Streaming

Telepipe supports optimized video uploads with streaming playback directly in Telegram:

### Basic Video Upload
```bash
# Upload video with streaming support
telepipe --video movie.mp4
telepipe --video /path/to/video.avi
telepipe --video recording.mov

# Upload with quiet mode
telepipe --video large-video.mp4 --quiet
```

### Video Upload with Caption
```bash
# Add caption to video
echo "Movie night! 🎬" | telepipe --video film.mp4
echo "Security footage from $(date)" | telepipe --video camera-feed.mp4

# Formatted caption
echo "*Important*: Training video" | telepipe --video training.mp4 --format markdown
```

### Advanced Features
- **Automatic metadata detection**: If `ffprobe` (from FFmpeg) is installed, telepipe automatically detects:
  - Video duration
  - Resolution (width/height)
  - These enhance the streaming experience in Telegram

- **Streaming optimization**: Videos are sent using Telegram's `sendVideo` API with `supports_streaming=true`, enabling:
  - Inline playback in chat
  - Better video player interface
  - Thumbnail generation
  - Progress bar during playback

### Install FFmpeg for Better Support
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install ffmpeg
```

### Practical Examples
```bash
# Screen recording with timestamp
echo "Screen recording from $(date)" | telepipe --video screen-capture.mp4

# Security camera upload
echo "Motion detected at front door" | telepipe --video security-$(date +%H%M).mp4

# Meeting recording
echo "📹 Team meeting recording - $(date '+%Y-%m-%d')" | telepipe --video meeting.mp4 --format markdown
```

**Video vs File Upload:**
- Use `--video` for: MP4, AVI, MOV, MKV, WebM video files
- Use `--file` for: Documents, archives, images, audio, or when you want document-style upload

**Notes:**
- Maximum video size: 50MB (Telegram Bot API limit)
- Supports common video formats (MP4, AVI, MOV, MKV, WebM, etc.)
- Automatic streaming optimization
- Cannot be combined with `--interactive`, `--schedule`, or `--delay` options
- Caption text supports formatting when used with `--format`

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

Telepipe selects its configuration in this order:

1. The path in `TELEPIPE_CONFIG`, when the variable is set.
2. `${XDG_CONFIG_HOME:-$HOME/.config}/telepipe/config`, when that file exists.
3. `/etc/telepipe/config` as the system-wide fallback.

For example, to use a configuration stored elsewhere:

```bash
TELEPIPE_CONFIG=/path/to/telepipe.conf telepipe --help
echo "Hello" | TELEPIPE_CONFIG=/path/to/telepipe.conf telepipe
```

The installer keeps generated configuration files private with mode `600`. If the
selected file is missing or unreadable, Telepipe reports the path and exits without
contacting Telegram.

The configuration file includes the following settings:

- `BOT_TOKEN`: Your Telegram bot token from BotFather
- `CHAT_ID`: ID of the chat where messages will be sent
- `MAX_LEN`: Maximum message length before sending as file (default: 4096)
- `TIMEOUT`: API request timeout in seconds (default: 5)
- `DISABLE_LINK_PREVIEW`: Whether to disable link previews (default: true)

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
