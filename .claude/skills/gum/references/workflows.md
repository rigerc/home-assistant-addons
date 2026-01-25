# Gum Workflow Patterns

Common patterns and workflows for using gum in scripts.

## Git Workflows

### Conventional Commits

```bash
#!/bin/bash
TYPE=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
SCOPE=$(gum input --placeholder "scope (optional)")

# Wrap scope in parentheses if provided
test -n "$SCOPE" && SCOPE="($SCOPE)"

SUMMARY=$(gum input --value "$TYPE$SCOPE: " --placeholder "Summary of this change")
DESCRIPTION=$(gum write --placeholder "Details of this change")

gum confirm "Commit changes?" && git commit -m "$SUMMARY" -m "$DESCRIPTION"
```

### Interactive Staging

```bash
#!/bin/bash
ADD="Add"
RESET="Reset"

ACTION=$(gum choose "$ADD" "$RESET")

if [ "$ACTION" == "$ADD" ]; then
    git status --short | cut -c 4- | gum choose --no-limit | xargs git add
else
    git status --short | cut -c 4- | gum choose --no-limit | xargs git restore
fi
```

### Branch Management

```bash
#!/bin/bash
GIT_COLOR="#f14e32"

git_color_text () {
  gum style --foreground "$GIT_COLOR" "$1"
}

get_branches () {
  if [ ${1+x} ]; then
    gum choose --selected.foreground="$GIT_COLOR" --limit="$1" $(git branch --format="%(refname:short)")
  else
    gum choose --selected.foreground="$GIT_COLOR" --no-limit $(git branch --format="%(refname:short)")
  fi
}

# Check if in git repo
git rev-parse --git-dir > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "$(git_color_text "!!") Must be run in a $(git_color_text "git") repo"
  exit 1
fi

# Display header
gum style \
  --border normal \
  --margin "1" \
  --padding "1" \
  --border-foreground "$GIT_COLOR" \
  "$(git_color_text 'Git') Branch Manager"

# Choose branches
echo "Choose $(git_color_text 'branches') to operate on:"
branches=$(get_branches)

# Choose action
echo ""
echo "Choose a $(git_color_text "command"):"
command=$(gum choose --cursor.foreground="$GIT_COLOR" rebase delete update)
echo ""

# Execute command on each branch
echo $branches | tr " " "\n" | while read -r branch
do
  case $command in
    rebase)
      base_branch=$(get_branches 1)
      git fetch origin
      git checkout "$branch"
      git rebase "origin/$base_branch"
      ;;
    delete)
      git branch -D "$branch"
      ;;
    update)
      git checkout "$branch"
      git pull --ff-only
      ;;
  esac
done
```

### Checkout PR with GitHub CLI

```bash
gh pr list | cut -f1,2 | gum choose | cut -f1 | xargs gh pr checkout
```

### Pick Commit from History

```bash
git log --oneline | gum filter | cut -d' ' -f1
```

### Clean Up Branches

```bash
git branch | cut -c 3- | gum choose --no-limit | xargs git branch -D
```

## Menu Systems

### Simple Menu

```bash
#!/bin/bash
ACTION=$(gum choose "Start" "Stop" "Restart" "Quit")

case "$ACTION" in
  "Start")
    gum spin --title "Starting..." -- sleep 2
    echo "Started!"
    ;;
  "Stop")
    echo "Stopping..."
    ;;
  "Restart")
    echo "Restarting..."
    ;;
  "Quit")
    exit 0
    ;;
esac
```

### Main Menu with Submenus

```bash
#!/bin/bash
while true; do
  CHOICE=$(gum choose "Files" "System" "Quit")

  case "$CHOICE" in
    "Files")
      SUB=$(gum choose "List" "Edit" "Back")
      case "$SUB" in
        "List") ls ;;
        "Edit") $EDITOR $(gum file) ;;
        "Back") continue ;;
      esac
      ;;
    "System")
      gum choose "Info" "Disk" "Back" > /dev/null
      ;;
    "Quit")
      exit 0
      ;;
  esac
done
```

## Data Selection Patterns

### Key-Value Selection

```bash
#!/bin/bash
# Filter by key, extract value
export LIST=$(cat <<END
Apple:Red
Banana:Yellow
Cherry:Red
END
)

ANIMAL=$(echo "$LIST" | cut -d':' -f1 | gum filter)
SOUND=$(echo "$LIST" | grep $ANIMAL | cut -d':' -f2)

echo "The $ANIMAL goes $SOUND"
```

### Multi-Select Processing

```bash
#!/bin/bash
# Select multiple items and process each
ITEMS=$(ls | gum choose --no-limit)

echo "$ITEMS" | tr " " "\n" | while read -r item; do
  echo "Processing: $item"
done
```

### Limited Selection

```bash
#!/bin/bash
# Select exactly N items
CHOICES=$(seq 1 10 | gum choose --limit 3)
echo "Selected: $CHOICES"
```

## Interactive Forms

### Simple Form

```bash
#!/bin/bash
echo "Please fill out the form:"
NAME=$(gum input --placeholder "Name")
EMAIL=$(gum input --placeholder "Email")
NOTES=$(gum write --placeholder "Notes")

gum confirm "Submit?" && echo "Submitted!" || echo "Cancelled"
```

### Form with Validation

```bash
#!/bin/bash
while true; do
  EMAIL=$(gum input --placeholder "Enter email")

  if echo "$EMAIL" | grep -q '@'; then
    break
  fi

  gum confirm "Invalid email. Try again?" || exit 1
done

echo "Valid email: $EMAIL"
```

### Progress Feedback

```bash
#!/bin/bash
steps=("Step 1" "Step 2" "Step 3" "Step 4")

for step in "${steps[@]}"; do
  gum spin --title "$step..." -- sleep 1
  gum style --foreground "green" "✓ $step complete"
done

gum style --foreground "green" --bold "All done!"
```

## Filtering Workflows

### Filter Command Output

```bash
#!/bin/bash
# Filter ps output
PROCESS=$(ps aux | gum filter | awk '{print $2}')
echo "Selected PID: $PROCESS"
```

### Filter File List

```bash
#!/bin/bash
# Filter and open file
FILE=$(ls | gum filter --placeholder "Select file")
if [ -n "$FILE" ]; then
  $EDITOR "$FILE"
fi
```

### Filter with Actions

```bash
#!/bin/bash
ACTION=$(gum choose "View" "Edit" "Delete" "Cancel")
FILE=$(gum file)

case "$ACTION" in
  "View") cat "$FILE" ;;
  "Edit") $EDITOR "$FILE" ;;
  "Delete") gum confirm "Delete $FILE?" && rm "$FILE" ;;
  "Cancel") exit 0 ;;
esac
```

## Confirmation Patterns

### Simple Confirm

```bash
gum confirm "Continue?" && echo "Yes" || echo "No"
```

### Confirm Before Destructive Action

```bash
gum confirm "Delete all files?" && rm * || echo "Aborted"
```

### Confirm With Default

```bash
# Default to no
gum confirm --default false "Proceed?" && echo "Proceeding"

# Default to yes
gum confirm --default true "Skip?" || echo "Not skipping"
```

## Styled Output

### Status Messages

```bash
#!/bin/bash
success() { gum style --foreground "green" "✓ $1"; }
error() { gum style --foreground "red" "✗ $1"; }
warn() { gum style --foreground "yellow" "⚠ $1"; }
info() { gum style --foreground "blue" "ℹ $1"; }

success "Operation complete"
error "Something went wrong"
warn "Be careful"
info "Processing..."
```

### Progress Bar Style

```bash
#!/bin/bash
total=10
for i in $(seq 1 $total); do
  percent=$((i * 100 / total))
  gum spin --title "$i/$total ($percent%)" -- sleep 1
done
```

### Boxed Output

```bash
#!/bin/bash
gum style \
  --border double \
  --border-foreground 212 \
  --padding "1 2" \
  --align center \
  "Title" "" \
  "Content here"
```

## Spinner Patterns

### Simple Spinner

```bash
gum spin --title "Loading..." -- long_command
```

### Spinner With Output

```bash
gum spin --show-output --title "Building..." -- make build
```

### Sequential Spinners

```bash
gum spin --title "Step 1..." -- sleep 1
gum spin --title "Step 2..." -- sleep 1
gum spin --title "Step 3..." -- sleep 1
```

## Layout Patterns

### Horizontal Layout

```bash
#!/bin/bash
LEFT=$(gum style --padding "1 2" --border double "Left")
RIGHT=$(gum style --padding "1 2" --border double "Right")
gum join "$LEFT" "$RIGHT"
```

### Vertical Layout

```bash
#!/bin/bash
gum join --vertical \
  "$(gum style --padding "1" "Top")" \
  "$(gum style --padding "1" "Middle")" \
  "$(gum style --padding "1" "Bottom")"
```

### Complex Layout

```bash
#!/bin/bash
HEADER=$(gum style --border double --padding "1 2" "Header")
BODY=$(gum style --padding "1" "Body content")
FOOTER=$(gum style --border single --padding "1" "Footer")

gum join --vertical "$HEADER" "$BODY" "$FOOTER"
```

## Integration Patterns

### With Tmux

```bash
SESSION=$(tmux list-sessions -F \#S | gum filter --placeholder "Pick session")
tmux switch-client -t "$SESSION" || tmux attach -t "$SESSION"
```

### With Package Managers

```bash
# Uninstall brew packages
brew list | gum choose --no-limit | xargs brew uninstall

# Uninstall npm packages
npm ls -g --depth=0 | grep -v 'npm@' | awk '{print $2}' | tr -d '@' | gum filter
```

### With Password Managers

```bash
# Skate password manager
skate list -k | gum filter | xargs skate get
```

### Shell History

```bash
# Copy command from history
gum filter < $HISTFILE --height 20
```

## Error Handling

### Check Command Success

```bash
if gum spin --title "Running..." -- command; then
  gum style --foreground "green" "Success!"
else
  gum style --foreground "red" "Failed!"
  exit 1
fi
```

### Validate Input

```bash
#!/bin/bash
while true; do
  VALUE=$(gum input --placeholder "Enter a number")

  if echo "$VALUE" | grep -qE '^[0-9]+$'; then
    break
  fi

  gum style --foreground "red" "Invalid input!"
done
```

## Long-Running Operations

### With Status Updates

```bash
#!/bin/bash
gum spin --title "Initializing..." -- sleep 1
gum style --foreground "green" "Initialized"

gum spin --title "Processing..." -- sleep 2
gum style --foreground "green" "Processed"

gum spin --title "Finalizing..." -- sleep 1
gum style --foreground "green" "Done!"
```

### With Progress

```bash
#!/bin/bash
files=($(ls))
total=${#files[@]}
current=0

for file in "${files[@]}"; do
  current=$((current + 1))
  gum spin --title "[$current/$total] Processing $file..." -- process "$file"
done
```

## Utility Functions

### Yes/No Prompt

```bash
confirm() {
  gum confirm "$1" && return 0 || return 1
}

if confirm "Continue?"; then
  echo "Continuing..."
fi
```

### Select From List

```bash
select_from() {
  echo "$@" | tr ' ' '\n' | gum choose
}

ACTION=$(select_from "Option 1" "Option 2" "Option 3")
```

### Filter List

```bash
filter_list() {
  echo "$@" | tr ' ' '\n' | gum filter
}

ITEM=$(filter_list "Apple" "Banana" "Cherry" "Date")
```

## Tips

### Always Use Command Substitution

Capture output with `$()` to use in scripts:

```bash
# Good
RESULT=$(gum choose "A" "B")

# Bad - prints to stdout
gum choose "A" "B"
```

### Wrap Styled Output

When using `gum join` with styled text, wrap in quotes to preserve newlines:

```bash
LEFT=$(gum style --border double "Left")
gum join "$LEFT" "Right"  # Note the quotes
```

### Use Descriptive Placeholders

Help users understand what to enter:

```bash
# Good
NAME=$(gum input --placeholder "Enter your full name")

# Bad
NAME=$(gum input)
```

### Provide Confirmation

For destructive operations, always confirm:

```bash
gum confirm "Delete $FILE?" && rm "$FILE"
```

### Use Spinners for Long Operations

Provide feedback for operations taking more than 1 second:

```bash
gum spin --title "Downloading..." -- wget http://example.com/file.zip
```
