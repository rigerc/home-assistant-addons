---
name: gum
description: This skill should be used when the user asks to "create an interactive shell script", "build a TUI", "make a CLI menu", "add interactive prompts", "use gum", "gum choose", "gum filter", "gum input", "gum confirm", "gum spin", "create a glamorous script", or mentions building interactive terminal interfaces.
version: 0.1.0
---

# Gum - Interactive Shell Script Helper

Gum is a tool for creating glamorous, interactive shell scripts without writing Go code. Use Bubble tea's power to add TUI elements to scripts through simple commands.

## When to Use

Use gum when building:
- Interactive shell scripts with user input
- Terminal menus and choosers
- Fuzzy finders for lists
- Confirmation prompts
- Spinners for long-running commands
- Styled output for scripts
- Filter/select interfaces for data

## Core Commands

### Input (`gum input`)
Prompt for single-line input:

```bash
# Basic input
NAME=$(gum input --placeholder "Enter your name")

# Password input (hidden)
PASSWORD=$(gum input --password)

# Pre-filled value
VALUE=$(gum input --value "default" --placeholder "Edit this")
```

### Write (`gum write`)
Prompt for multi-line text (ctrl+d to finish):

```bash
DESCRIPTION=$(gum write --placeholder "Enter description")

# With width limit
NOTES=$(gum write --width 80 --placeholder "Enter notes")
```

### Choose (`gum choose`)
Select from a list of options:

```bash
# Single selection
ACTION=$(gum choose "Start" "Stop" "Restart")

# Multiple selection
ITEMS=$(gum choose --no-limit "Option 1" "Option 2" "Option 3")

# Limited selection
CHOICES=$(gum choose --limit 2 "A" "B" "C" "D")

# With header
FRUIT=$(gum choose --header "Pick a fruit" "Apple" "Banana" "Cherry")
```

### Filter (`gum filter`)
Fuzzy-find from a list:

```bash
# Filter from stdin
echo -e "Apple\nBanana\nCherry" | gum filter

# Filter file list
git branch | gum filter --placeholder "Select branch"

# Multi-select
git status --short | cut -c 4- | gum filter --no-limit
```

### Confirm (`gum confirm`)
Yes/no confirmation (exits 0 for yes, 1 for no):

```bash
gum confirm "Continue?" && echo "Yes" || echo "No"

# With custom text
gum confirm "Delete files?" && rm *.txt
```

### Spin (`gum spin`)
Show spinner while running command:

```bash
# Basic spinner
gum spin --title "Loading..." -- sleep 3

# Show command output
gum spin --show-output --title "Building..." -- make build

# Spinner types: line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger
gum spin --spinner monkey --title "Working..." -- long_command
```

### Style (`gum style`)
Apply colors, borders, spacing to text:

```bash
# Simple styling
gum style --foreground 212 --bold "Purple bold text"

# With border and padding
gum style \
  --border double \
  --border-foreground 212 \
  --padding "1 2" \
  --margin "1" \
  "Bordered text"

# Center aligned
gum style --align center --width 50 "Centered text"
```

### Join (`gum join`)
Combine styled text horizontally or vertically:

```bash
# Horizontal join
LEFT=$(gum style --border double "Left")
RIGHT=$(gum style --border double "Right")
gum join "$LEFT" "$RIGHT"

# Vertical join
gum join --vertical "Top" "Bottom"
```

### Format (`gum format`)
Format markdown, templates, or emojis:

```bash
# Markdown
gum format -- "# Heading" "- Item 1" "- Item 2"

# Template syntax
echo '{{ Bold "Bold" }} {{ Italic "Italic" }}' | gum format -t template

# Emojis
echo 'I :heart: gum' | gum format -t emoji

# Code with syntax highlighting
cat script.sh | gum format -t code
```

### Table (`gum table`)
Display tabular data:

```bash
# From CSV
gum table < data.csv

# Select row
SELECTED=$(gum table < menu.csv | cut -d',' -f1)
```

### File (`gum file`)
Interactive file picker:

```bash
# Pick file to edit
$EDITOR $(gum file)

# Pick from directory
$EDITOR $(gum file ~/Documents)
```

### Pager (`gum pager`)
Scroll through long documents:

```bash
gum pager < README.md
gum pager --height 20 < long-file.txt
```

### Log (`gum log`)
Log messages at different levels:

```bash
gum log --level info "Starting process"
gum log --level warn "Warning message"
gum log --level error "Error occurred"
gum log --level debug "Debug info"

# With structured fields
gum log --structured --level error "Failed" file=file.txt
```

## Common Patterns

### Git Commit Helper
```bash
TYPE=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore")
SCOPE=$(gum input --placeholder "scope (optional)")
test -n "$SCOPE" && SCOPE="($SCOPE)"
SUMMARY=$(gum input --value "$TYPE$SCOPE: " --placeholder "Summary")
DESCRIPTION=$(gum write --placeholder "Details")
gum confirm "Commit?" && git commit -m "$SUMMARY" -m "$DESCRIPTION"
```

### Interactive Menu
```bash
ACTION=$(gum choose "Option 1" "Option 2" "Option 3" "Quit")
case "$ACTION" in
  "Option 1") echo "Running option 1" ;;
  "Option 2") echo "Running option 2" ;;
  "Option 3") echo "Running option 3" ;;
  "Quit") exit 0 ;;
esac
```

### Filter and Process
```bash
# Filter branches and checkout
git branch | cut -c 3- | gum filter | xargs git checkout

# Filter packages and uninstall
brew list | gum choose --no-limit | xargs brew uninstall
```

### Key-Value Selection
```bash
# Filter by key, extract value
LIST="Apple:Red\nBanana:Yellow\nCherry:Red"
ITEM=$(echo "$LIST" | cut -d':' -f1 | gum filter)
VALUE=$(echo "$LIST" | grep "$ITEM" | cut -d':' -f2)
```

## Customization

Customize via flags or environment variables:

```bash
# Via flags
gum input --cursor.foreground "#FF0" --prompt.foreground "#0FF"

# Via environment (prefix GUM_<COMMAND>_<FLAG>)
export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
gum input
```

## Output Capture

Always capture output with `$()` or redirect to file:

```bash
# Capture to variable
RESULT=$(gum choose "Yes" "No")

# Redirect to file
gum input > response.txt
```

## Additional Resources

### Reference Files

For detailed examples and advanced patterns, consult:
- **`references/commands.md`** - Comprehensive command reference
- **`references/workflows.md`** - Common workflow patterns

### Example Files

Working examples in `examples/`:
- **`examples/commit.sh`** - Conventional commits script
- **`examples/git-branch-manager.sh`** - Branch management workflow
- **`examples/git-stage.sh`** - Interactive git staging
- **`examples/demo.sh`** - Comprehensive demo of all features
