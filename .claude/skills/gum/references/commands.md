# Gum Commands Reference

Detailed reference for all gum commands and their options.

## choose

Choose an option from a list of choices.

### Flags

| Flag | Description |
|------|-------------|
| `--height <height>` | Maximum height of the list |
| `--limit <int>` | Maximum number of items to choose |
| `--no-limit` | Allow choosing unlimited items |
| `--cursor <string>` | Cursor prefix |
| `--cursor.foreground <color>` | Cursor color |
| `--selected.foreground <color>` | Selected item color |
| `--selected.prefix <string>` | Prefix for selected items |
| `--header <string>` | Header text |
| `--header.foreground <color>` | Header color |
| `--item.foreground <color>` | Item color |
| `--placeholder <string>` | Placeholder text |

### Usage

```bash
# Basic single select
CHOICE=$(gum choose "Option 1" "Option 2" "Option 3")

# Multi-select with tab
MULTI=$(gum choose --no-limit "A" "B" "C" "D")

# Limited to 2 selections
TWO=$(gum choose --limit 2 "Red" "Blue" "Green" "Yellow")

# With styling
FRUIT=$(gum choose \
  --selected.foreground "#FF0" \
  --cursor.foreground "#0FF" \
  --header "Pick a fruit" \
  "Apple" "Banana" "Cherry")
```

### Environment Variables

- `GUM_CHOOSE_HEIGHT`
- `GUM_CHOOSE_LIMIT`
- `GUM_CHOOSE_CURSOR`
- `GUM_CHOOSE_CURSOR_FOREGROUND`
- `GUM_CHOOSE_SELECTED_FOREGROUND`
- `GUM_CHOOSE_SELECTED_PREFIX`
- `GUM_CHOOSE_HEADER`
- `GUM_CHOOSE_HEADER_FOREGROUND`
- `GUM_CHOOSE_ITEM_FOREGROUND`
- `GUM_CHOOSE_PLACEHOLDER`

## confirm

Ask user to confirm an action. Exits 0 (yes) or 1 (no).

### Flags

| Flag | Description |
|------|-------------|
| `--affirmed <string>` | Affirmative text (default: "Yes") |
| `--negated <string>` | Negative text (default: "No") |
| `--default <bool>` | Default selection (true/false) |
| `--timeout <duration>` | Auto-select default after timeout |

### Usage

```bash
# Basic confirmation
gum confirm "Continue?" && echo "Yes" || echo "No"

# Custom labels
gum confirm \
  --affirmed "Sure" \
  --negated "No thanks" \
  "Do you want to proceed?"

# With default
gum confirm --default false "Delete files?"

# Timeout (auto-confirm after 5 seconds)
gum confirm --timeout 5s "Continue?"
```

### Environment Variables

- `GUM_CONFIRM_AFFIRMED`
- `GUM_CONFIRM_NEGATED`
- `GUM_CONFIRM_DEFAULT`
- `GUM_CONFIRM_TIMEOUT`

## file

Pick a file from a directory.

### Flags

| Flag | Description |
|------|-------------|
| `--path <path>` | Root path to browse (default: current dir) |
| `--height <height>` | Maximum height of the list |

### Usage

```bash
# Pick file
FILE=$(gum file)

# Pick from specific directory
DOC=$(gum file ~/Documents)

# Edit selected file
$EDITOR $(gum file)
```

### Environment Variables

- `GUM_FILE_PATH`
- `GUM_FILE_HEIGHT`

## filter

Fuzzy-find items from a list.

### Flags

| Flag | Description |
|------|-------------|
| `--limit <int>` | Maximum number of items to select |
| `--no-limit` | Allow unlimited selections |
| `--height <height>` | Maximum height of the list |
| `--placeholder <string>` | Placeholder text |
| `--prompt <string>` | Prompt text |
|--indicator <string>` | Selection indicator |
| `--indicator.foreground <color>` | Indicator color |
| `--match.foreground <color>` | Match highlight color |
| `--header <string>` | Header text |

### Usage

```bash
# Filter from stdin
echo -e "Apple\nBanana\nCherry" | gum filter

# Filter git branches
git branch | cut -c 3- | gum filter --placeholder "Select branch"

# Multi-select
git status --short | cut -c 4- | gum filter --no-limit

# Filter with limit
echo -e "A\nB\nC\nD" | gum filter --limit 2

# Custom styling
ls | gum filter \
  --indicator.foreground "#FF0" \
  --match.foreground "#0FF" \
  --header "Select file"
```

### Environment Variables

- `GUM_FILTER_LIMIT`
- `GUM_FILTER_HEIGHT`
- `GUM_FILTER_PLACEHOLDER`
- `GUM_FILTER_PROMPT`
- `GUM_FILTER_INDICATOR`
- `GUM_FILTER_INDICATOR_FOREGROUND`
- `GUM_FILTER_MATCH_FOREGROUND`
- `GUM_FILTER_HEADER`

## format

Format text with markdown, templates, or emojis.

### Flags

| Flag | Description |
|------|-------------|
| `-t, --type <type>` | Type: markdown, code, template, emoji |
| `--theme <theme>` | Syntax highlighting theme |

### Usage

```bash
# Markdown
gum format -- "# Heading" "- Item" "```code```"

# Code syntax highlighting
cat script.py | gum format -t code

# Template with helpers
echo '{{ Bold "Bold" }} {{ Italic "Italic" }} {{ Color "212" "Purple" }}' | gum format -t template

# Emojis
echo 'I :heart: gum :candy:' | gum format -t emoji

# From file
cat README.md | gum format
```

### Environment Variables

- `GUM_FORMAT_TYPE`
- `GUM_FORMAT_THEME`

## input

Prompt for single-line input.

### Flags

| Flag | Description |
|------|-------------|
| `--placeholder <string>` | Placeholder text |
| `--prompt <string>` | Prompt text (default: "> ") |
| `--value <string>` | Default/pre-filled value |
| `--password` | Hide input (password mode) |
| `--cursor <string>` | Cursor character |
| `--width <width>` | Input width |
| `--prompt.foreground <color>` | Prompt color |
| `--placeholder.foreground <color>` | Placeholder color |
| `--cursor.foreground <color>` | Cursor color |
| `--header <string>` | Header text |
| `--header.foreground <color>` | Header color |

### Usage

```bash
# Basic input
NAME=$(gum input --placeholder "Enter name")

# Password input
PASSWORD=$(gum input --password)

# Pre-filled
EDIT=$(gum input --value "default text" --placeholder "Edit this")

# Custom styling
gum input \
  --prompt.foreground "#FF0" \
  --cursor.foreground "#0FF" \
  --placeholder "What is your name?"
```

### Environment Variables

- `GUM_INPUT_PLACEHOLDER`
- `GUM_INPUT_PROMPT`
- `GUM_INPUT_VALUE`
- `GUM_INPUT_PASSWORD`
- `GUM_INPUT_CURSOR`
- `GUM_INPUT_WIDTH`
- `GUM_INPUT_PROMPT_FOREGROUND`
- `GUM_INPUT_PLACEHOLDER_FOREGROUND`
- `GUM_INPUT_CURSOR_FOREGROUND`
- `GUM_INPUT_HEADER`
- `GUM_INPUT_HEADER_FOREGROUND`

## join

Combine text horizontally or vertically.

### Flags

| Flag | Description |
|------|-------------|
| `--vertical` | Join vertically instead of horizontally |
| `--align <align>` | Alignment: left, center, right |
| `--gap <gap>` | Space between items |

### Usage

```bash
# Horizontal
LEFT=$(gum style --border double "Left")
RIGHT=$(gum style --border double "Right")
gum join "$LEFT" "$RIGHT"

# Vertical
gum join --vertical "Top" "Middle" "Bottom"

# Aligned
gum join --align center "$A" "$B" "$C"
```

### Environment Variables

- `GUM_JOIN_VERTICAL`
- `GUM_JOIN_ALIGN`
- `GUM_JOIN_GAP`

## log

Log messages at different levels.

### Flags

| Flag | Description |
|------|-------------|
| `--level <level>` | Level: info, warn, error, debug, fatal |
| `--structured` | Enable structured logging |
| `--time <format>` | Time format (rfc822, etc.) |
| `--key <key>` | Structured key-value pairs |

### Usage

```bash
# Log levels
gum log --level info "Starting..."
gum log --level warn "Warning..."
gum log --level error "Error!"

# Structured
gum log --structured --level error "Failed" file=file.txt line=42

# With timestamp
gum log --time rfc822 --level info "Message"
```

### Environment Variables

- `GUM_LOG_LEVEL`
- `GUM_LOG_STRUCTURED`
- `GUM_LOG_TIME`

## pager

Scroll through a long document.

### Flags

| Flag | Description |
|------|-------------|
| `--height <height>` | Viewport height |
| `--line-number` | Show line numbers |
| `--match <string>` | Highlight matching text |
| `--match.foreground <color>` | Match color |
| `--soft-wrap` | Soft wrap long lines |
| `--show-line-numbers` | Alias for --line-number |

### Usage

```bash
# Basic pager
gum pager < README.md

# With height
gum pager --height 20 < long-file.txt

# Show line numbers
gum pager --show-line-numbers < file.txt

# Highlight pattern
gum pager --match "error" < log.txt
```

### Environment Variables

- `GUM_PAGER_HEIGHT`
- `GUM_PAGER_LINE_NUMBER`
- `GUM_PAGER_MATCH`
- `GUM_PAGER_MATCH_FOREGROUND`
- `GUM_PAGER_SOFT_WRAP`

## spin

Display spinner while running a command.

### Flags

| Flag | Description |
|------|-------------|
| `--spinner <name>` | Spinner: line, dot, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger |
| `--title <string>` | Title text |
| `--show-output` | Show command output |
| `--show-error` | Show errors |
| `--align <align>` | Alignment: left, center, right |

### Usage

```bash
# Basic spinner
gum spin --title "Loading..." -- sleep 3

# Show output
gum spin --show-output --title "Building..." -- make build

# Different spinner
gum spin --spinner monkey --title "Working..." -- long_command

# With error handling
gum spin --show-error --title "Installing..." -- npm install
```

### Environment Variables

- `GUM_SPIN_SPINNER`
- `GUM_SPIN_TITLE`
- `GUM_SPIN_SHOW_OUTPUT`
- `GUM_SPIN_SHOW_ERROR`
- `GUM_SPIN_ALIGN`

## style

Apply colors, borders, spacing to text.

### Flags

| Flag | Description |
|------|-------------|
| `--foreground <color>` | Text color |
| `--background <color>` | Background color |
| `--border <style>` | Border: none, single, double, rounded, thick, hidden |
| `--border.foreground <color>` | Border color |
| `--background <color>` | Background color |
| `--align <align>` | Alignment: left, center, right |
| `--width <width>` | Width |
| `--height <height>` | Height |
| `--margin <margin>` | Margin (top bottom left right or horizontal vertical) |
| `--padding <padding>` | Padding |
| `--bold` | Bold text |
| `--italic` | Italic text |
| `--underline` | Underline text |
| `--strikethrough` | Strikethrough text |
| `--faint` | Dim/faint text |

### Usage

```bash
# Colors
gum style --foreground 212 "Purple text"
gum style --background "#FF0" "Yellow background"

# Border
gum style --border double "Bordered"
gum style --border rounded --border-foreground "#FF0" "Styled border"

# Alignment and spacing
gum style --align center --width 50 "Centered text"
gum style --margin "1 2" --padding "2 4" "Spaced text"

# Text styles
gum style --bold --italic "Bold italic"
gum style --underline --strikethrough "Underline strike"

# Complex
gum style \
  --foreground 212 \
  --border double \
  --border-foreground 212 \
  --align center \
  --width 50 \
  --margin "1 2" \
  --padding "2 4" \
  "Beautiful text"
```

### Environment Variables

- `GUM_STYLE_FOREGROUND`
- `GUM_STYLE_BACKGROUND`
- `GUM_STYLE_BORDER`
- `GUM_STYLE_BORDER_FOREGROUND`
- `GUM_STYLE_ALIGN`
- `GUM_STYLE_WIDTH`
- `GUM_STYLE_HEIGHT`
- `GUM_STYLE_MARGIN`
- `GUM_STYLE_PADDING`
- `GUM_STYLE_BOLD`
- `GUM_STYLE_ITALIC`
- `GUM_STYLE_UNDERLINE`
- `GUM_STYLE_STRIKETHROUGH`
- `GUM_STYLE_FAINT`

## table

Display tabular data and select rows.

### Flags

| Flag | Description |
|------|-------------|
| `--separator <string>` | Column separator (default: ",") |
| `--widths <widths>` | Column widths |
| `--height <height>` | Maximum height |

### Usage

```bash
# From CSV
gum table < data.csv

# Custom separator
gum table --separator "|" < data.txt

# Select row
SELECTED=$(gum table < menu.csv | cut -d',' -f1)
```

### Environment Variables

- `GUM_TABLE_SEPARATOR`
- `GUM_TABLE_WIDTHS`
- `GUM_TABLE_HEIGHT`

## write

Prompt for multi-line text input (ctrl+d to finish).

### Flags

| Flag | Description |
|------|-------------|
| `--placeholder <string>` | Placeholder text |
| `--prompt <string>` | Prompt text |
| `--value <string>` | Default value |
| `--width <width>` | Input width |
| `--height <height>` | Input height |
| `--header <string>` | Header text |
| `--show-cursor-line` | Highlight cursor line |

### Usage

```bash
# Basic multi-line input
DESCRIPTION=$(gum write --placeholder "Enter description")

# With dimensions
NOTES=$(gum write --width 80 --height 20 --placeholder "Enter notes")

# With header
COMMIT=$(gum write --header "Commit message" --placeholder "Summary")

# Pre-filled
EDIT=$(gum write --value "Existing text" --placeholder "Edit this")
```

### Environment Variables

- `GUM_WRITE_PLACEHOLDER`
- `GUM_WRITE_PROMPT`
- `GUM_WRITE_VALUE`
- `GUM_WRITE_WIDTH`
- `GUM_WRITE_HEIGHT`
- `GUM_WRITE_HEADER`
- `GUM_WRITE_SHOW_CURSOR_LINE`

## Color Specification

Colors can be specified as:
- Named colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
- Bright variants: `bright-black`, `bright-red`, etc.
- 256-color palette: `0`-`255`
- Hex colors: `#RRGGBB` or `#RGB`
- RGB: `rgb(R,G,B)` where values are 0-255

## Keyboard Shortcuts

### choose/filter
- `Enter` - Confirm selection
- `Ctrl+C` - Cancel
- `Tab` / `Ctrl+Space` - Select additional item (multi-select)
- `Ctrl+N` / `Ctrl+P` - Next/Previous item

### write
- `Ctrl+D` - Finish input
- `Ctrl+C` - Cancel
- Arrow keys - Navigate

### All commands
- `Ctrl+C` - Cancel/Quit
