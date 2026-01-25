# jq Examples and Recipes

Practical examples and common patterns for real-world JSON processing.

## API Response Processing

### Extract value from nested structure
```json
{"data": {"users": [{"id": 1, "name": "Alice"}]}}
```
```bash
jq '.data.users[0].name'        # "Alice"
jq '.data.users[] | .name'      # All names
```

### Filter array of objects
```json
{"users": [{"name": "Alice", "active": true}, {"name": "Bob", "active": false}]}
```
```bash
jq '.users[] | select(.active == true)'    # Active users only
jq '.users | map(select(.active))'         # As array
jq '[.users[] | select(.active)]'          # Same as above
```

### Transform array structure
```json
{"items": [{"id": 1, "value": {"amount": 10}}, {"id": 2, "value": {"amount": 20}}]}
```
```bash
jq '.items[] | {id, amount: .value.amount}'
# Output: {"id": 1, "amount": 10}, {"id": 2, "amount": 20}

jq '.items | map({id, amount: .value.amount})'
# Output as array: [{"id": 1, "amount": 10}, ...]
```

### Flatten and process nested arrays
```json
{"data": {"groups": [{"name": "A", "items": [1, 2]}, {"name": "B", "items": [3, 4]}]}}
```
```bash
jq '.data.groups[].items[]'        # All items: 1, 2, 3, 4
jq '[.data.groups[].items[]]'      # As array: [1, 2, 3, 4]

# With group name
jq '.data.groups[] | .items[] | {item: ., group: .name}'  # Wrong: . is now item
jq '.data.groups[] | {name, items: .items}'              # Preserve structure
```

## Data Transformation

### Rename keys
```json
[{"user_name": "Alice", "user_email": "alice@example.com"}]
```
```bash
jq '.[] | {name: .user_name, email: .user_email}'
# Or using shorthand with transformation:
jq '.[] | {name: .user_name, email: .user_email}'
```

### Add computed fields
```json
[{"price": 100, "tax_rate": 0.1}, {"price": 200, "tax_rate": 0.15}]
```
```bash
jq '.[] | {price, tax: (.price * .tax_rate), total: (.price * (1 + .tax_rate))}'
jq '.[] | {price, tax, total: (.price + .tax)}'
```

### Filter and aggregate
```json
[{"category": "A", "value": 10}, {"category": "A", "value": 20}, {"category": "B", "value": 30}]
```
```bash
# Sum by category
jq 'group_by(.category) | map({category: .[0].category, total: map(.value) | add})'
# Output: [{"category": "A", "total": 30}, {"category": "B", "total": 30}]

# Count by category
jq 'group_by(.category) | map({category: .[0].category, count: length})'
```

### Merge multiple objects
```bash
# Merge array of objects into one
jq 'add' items.json                    # Simple merge
jq 'reduce .[] as $item ({}; . + $item)' items.json  # With custom logic

# Add defaults to each object
echo '{"defaults": {"active": true}, "items": [{"id": 1}]}' | \
  jq '.defaults as $d | .items[] | $d + .'
```

## CSV / Table Operations

### Convert JSON to CSV
```json
[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]
```
```bash
jq -r '.[] | [.name, .age] | @csv'     # "Alice",30\n"Bob",25
jq -r '.[] | [.name, .age] | @tsv'     # Tab-separated
jq -r '["Name","Age"], (.[] | [.name, .age]) | @csv'  # With header
```

### Convert CSV to JSON
```bash
# If you have csv2json tool, or use jq with --slurp
jq -n --arg csv "$(cat data.csv)" \
  '$csv | split("\n") | .[1:] | map(split(",") | {"name": .[0], "age": .[1] | tonumber})'
```

### Create ASCII table
```bash
jq -r '.[] | "\(.name)\t\(.age)\t\(.email)"' | column -t -s $'\t'
```

## String Processing

### Parse and format URLs
```json
[{"url": "https://example.com/path?q=search"}, {"url": "https://test.org/page"}]
```
```bash
jq '.[] | .url | split("?")[0]'                       # Remove query string
jq '.[] | {url: .url, domain: (.url | split("/")[2])}'  # Extract domain
jq '.[] | .url | test("^https")'                      # Check if HTTPS
```

### Clean and normalize text
```json
["  Hello  ", "WORLD", "  Mixed Case  "]
```
```bash
jq '.[] | ascii_downcase | ltrimstr(" ") | rtrimstr(" ")'
jq '.[] | trim | ascii_upcase'                         # All uppercase
```

### Search and replace
```json
["file-001.txt", "file-002.txt", "file-003.txt"]
```
```bash
jq '.[] | sub("file-"; "document-")'                   # Replace first
jq '.[] | gsub("[0-9]+"; "NUM")'                       # Replace all numbers
```

### Extract with regex
```bash
echo '["user@example.com", "admin@test.org"]' | jq '.[] | match("^[^@]+") | .string'
# Output: "user", "admin"

echo '["user@example.com", "admin@test.org"]' | jq '.[] | capture("(?<user>[^@]+)@(?<domain>.+)")'
# Output: {"user":"user","domain":"example.com"}
```

## Working with Numbers

### Sum array field
```json
[{"price": 10}, {"price": 20}, {"price": 30}]
```
```bash
jq '[.[] | .price] | add'              # 60
jq 'map(.price) | add'                 # Same
jq '.[] | .price | add'                # Using generator form
```

### Calculate statistics
```bash
# Sum, average, min, max
jq '[.[] | .price] | {sum: add, avg: add/length, min: min, max: max}' numbers.json

# For a single array
jq '{sum: add, avg: add/length, min: min, max: max, count: length}' array.json

# Median (for sorted array)
jq 'if length % 2 == 0 then (.[length/2-1] + .[length/2]) / 2 else .[length/2] end' \
  <(jq -S 'sort' array.json)
```

### Round numbers
```bash
jq 'map(.price | floor / ceil / round)'   # Round down/up/nearest
jq 'map(.price * 100 | round / 100)'      # Round to 2 decimals
```

## Configuration Files

### Extract specific keys
```json
{"database": {"host": "localhost", "port": 5432, "user": "admin"}, "cache": {"enabled": true}}
```
```bash
jq '.database | {host, port}'             # Only host and port
jq 'pick(.database.host, .cache.enabled)' # Multiple paths
```

### Merge with defaults
```bash
jq '.config + $defaults' --argjson defaults '{"timeout": 30}' config.json
jq '. as $current | $defaults + $current'  # Defaults overridden by current
```

### Update nested value
```json
{"api": {"endpoint": {"url": "http://old.com"}}}
```
```bash
jq '.api.endpoint.url = "https://new.com"' config.json > new_config.json
jq '.api.endpoint.url |= "https://new.com"'  # Same with update
```

## Log Processing

### Parse JSON logs
```bash
journalctl -o json | jq '.MESSAGE'
kubectl logs -l app=myapp -o json | jq '. | select(.message != null) | .message'
```

### Filter logs by criteria
```bash
jq 'select(.level == "ERROR")'                    # Only errors
jq 'select(.level == "ERROR" or .level == "WARN")'
jq 'select(.timestamp | fromdate > now - 3600)'   # Last hour
jq 'select(.message | test("pattern"))'           # Regex match in message
```

### Extract and format log entries
```bash
jq -r '[.timestamp, .level, .message] | @tsv'     # Tab-separated
jq -r '\(.timestamp) [\(.level)] \(.message)'     # Custom format
jq '{time: .timestamp, msg: .message}'            # Reformat
```

### Count occurrences
```bash
jq 'group_by(.level) | map({level: .[0].level, count: length})'
jq '[.[] | .level] | group_by(.) | map({level: .[0], count: length})'
```

## File Operations

### Process multiple files
```bash
# Read multiple files into array
jq -n '[inputs]' file1.json file2.json file3.json

# Process each file separately
jq '.' *.json                    # Outputs each file's content

# Merge all files
jq -s 'add' *.json               # Slurp all files, then merge
jq -n 'reduce inputs as $item ({}; . + $item)' *.json
```

### Combine related files
```bash
# Merge users.json with posts.json on user_id
jq -s '
  (.[0] | INDEX(.id)) as $users |
  (.[1] | map(. + {user_name: $users[.user_id].name}))
' users.json posts.json

# Or using JOIN:
jq -s '
  (.[0] | INDEX(.id)) as $idx |
  .[1] | JOIN($idx; .user_id; {user_id}; . + {user_name: .user.name})
' users.json posts.json
```

## Large File Processing

### Stream processing (memory efficient)
```bash
# Process one object at a time
jq -c '.[]' large.json | while read -r item; do
  echo "$item" | jq '.field'
done

# Process with streaming parser
jq --stream 'select(length == 2 and .[0][-1] == "target_field")' large.json
```

### Filter large files efficiently
```bash
# Use --stream for huge files
jq --stream 'fromstream(inputs)' | select(.active == true)

# Chunked processing
jq -c '.[]' large.json | split -l 10000 - chunk_
for f in chunk_*; do
  jq 'select(.active)' "$f" > filtered_"$f"
done
```

## Date/Time Operations

### Parse and format dates
```json
[{"created": "2024-01-15T10:30:00Z"}, {"created": "2024-02-20T14:45:00Z"}]
```
```bash
# Convert to readable format
jq '.[] | .created | fromdate | strftime("%Y-%m-%d %H:%M:%S")'

# Calculate age in days
jq '.[] | {created, age_days: ((now - (.created | fromdate)) / 86400) | floor}'

# Filter by date range
jq '.[] | select(.created | fromdate > (now - 7*86400))'  # Last 7 days
```

### Group by date
```bash
jq 'group_by(.created | fromdate | strftime("%Y-%m-%d")) |
    map({date: .[0].created, count: length})'
```

## Conditional Logic

### Complex conditions
```bash
# Multiple conditions
jq 'select(.age >= 18 and .country == "US")'

# Nested conditions
jq 'select(
  if .type == "user" then
    .age >= 18
  elif .type == "admin" then
    true
  else
    false
  end
)'

# Using or for alternative paths
jq '.[] | .email // .username // "unknown"'
```

### Error-safe operations
```bash
# Safely access nested fields
jq '.data.users[0].name?'      # No error if missing
jq '.data.users[0].name // "N/A"'

# Try-catch for parsing
jq 'map(.value | tonumber? // 0)'
jq 'map(try tonumber catch 0)'

# Validate before processing
jq 'if type == "array" then map(.+1) else error("Expected array") end'
```

## Recursive Structures

### Process tree structures
```json
{
  "name": "root",
  "children": [
    {"name": "a", "children": [{"name": "a1"}, {"name": "a2"}]},
    {"name": "b", "children": []}
  ]
}
```
```bash
# Get all names at any depth
jq 'recurse(.children[]) | .name'

# Get leaf nodes (no children)
jq 'recurse(.children[]) | select(.children == null or .children == [])'

# Find node by name
jq 'recurse(.children[]) | select(.name == "a2")'
```

### Flatten nested objects
```json
{"a": {"b": {"c": 1}}, "x": 2}
```
```bash
jq '[path(.. | select(type == "number") | select(. != null)),
      (.. | select(type == "number") | select(. != null))] |
     transpose | map({(.[0] | map(tostring) | join(".")): .[1]}) | add'
# Complex: {"a.b.c": 1, "x": 2}
```

## Performance Tips

### Efficient array operations
```bash
# Avoid multiple passes
jq 'map(select(.active) | .name)'          # Single pass vs select then map

# Use generators for early termination
jq 'limit(1; .[] | select(.target == "value"))'  # Stop after first match

# Use --compact-output for large intermediate results
jq -c '.[] | .field' large.json | ...
```

### Memory-efficient patterns
```bash
# Use -c for compact output when chaining
jq -c '.[]' input.json | while read -r line; do
  echo "$line" | jq '.field'
done

# Use delete to remove unnecessary data early
jq 'del(.unnested_large_field) | ...'
```

## Debugging

### Inspect values
```bash
jq '. as $val | debug("input:", $val) | .field'    # Print value, continue
jq '. | debug'                                    # Print each value
jq 'debug("processing: \(.)") | .'                # With custom message
```

### Trace execution
```bash
# Show intermediate values
jq '.[] | .field | debug("field value") | .*2'

# Check types
jq 'map(type)'                                    # Types of all values
jq 'map({value: ., type})'                        # Value with type
```

### Validate structure
```bash
jq 'has("required_field")'                        # Check if field exists
jq '.[] | has("name") and has("id")'             # All have both fields
jq '[.[] | type] | unique'                        # All types present
```
