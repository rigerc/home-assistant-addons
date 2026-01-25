---
name: jq
description: Query, transform, and manipulate JSON data using jq command-line processor. Use when parsing JSON files, extracting values from API responses, filtering JSON arrays, transforming data structures, formatting JSON output, or processing JSON logs. Helps with JSON path queries, array operations, object manipulation, string formatting, date handling, regex matching on JSON, and building complex data transformations.
---

# jq - JSON Query and Transformation

## When to Use This Skill

Use this skill when you need to:
- Parse or transform JSON files
- Extract specific values from JSON data
- Filter arrays or objects based on conditions
- Format JSON output for display or further processing
- Query JSON from API responses
- Manipulate nested data structures
- Convert between JSON and other formats (CSV, TSV, etc.)
- Apply complex transformations to JSON streams

## Core Concepts

### jq is a Filter Language

Every jq expression is a "filter" that takes input and produces output:
- `.` - Identity filter, outputs input unchanged
- Filters can be combined with `|` (pipe)
- Filters can produce multiple outputs (generators)
- Filters are composed: `.a.b.c` is the same as `.a | .b | .c`

### Basic Invocation

```bash
jq '.' input.json              # Pretty-print JSON
jq '.foo' input.json           # Extract field
jq '.[] | .name' input.json    # Process array elements
echo '{"a":1}' | jq '.a'       # Read from stdin
```

**Command-line options:**
- `-r` / `--raw-output` - Output strings without quotes
- `-c` / `--compact-output` - Compact JSON (no pretty-printing)
- `-n` / `--null-input` - Use null as input
- `-s` / `--slurp` - Read all inputs into an array
- `-R` / `--raw-input` - Read input as raw text lines

## Essential Filters

### Object Access

```jq
.foo                    # Access field "foo", returns null if missing
.foo?                   # Optional access, no error if not object
.foo.bar                # Chained access (same as .foo | .bar)
["foo"]                 # Access with string expression
```

### Array Access

```jq
.[0]                    # First element (0-based indexing)
.[-1]                   # Last element (negative indices)
.[2:4]                  # Slice from index 2 to 4 (exclusive)
.[]                     # Iterator - outputs all elements
.[2,4]                  # Multiple indices (comma operator)
```

### Path Operators

```jq
..                      # Recursive descent, all values
.. | .a?                # All "a" fields at any depth
path(.a.b[0])          # Get path as array ["a","b",0]
getpath(["a","b"])     # Get value at path
setpath(["a"]; 1)      # Set value at path
delpaths([["a"]])      # Delete paths
```

## Data Construction

### Arrays

```jq
[1,2,3]                 # Literal array
[.foo, .bar]            # Array from fields
[.[] | .name]           # Collect filtered values
add                     # Sum array (or concatenate strings/arrays)
length                  # Array length
map(.+1)                # Apply to each element
reverse                 # Reverse array
sort                    # Sort array
unique                  # Remove duplicates, sorted
flatten                 # Flatten nested arrays
```

### Objects

```jq
{"a": 1, "b": 2}        # Literal object
{a: .foo, b: .bar}      # Shorthand (unquoted keys)
{a, b}                  # Even shorter (same as {a: .a, b: .b})
{(.foo): .value}        # Computed key
.keys | .[]             # Iterate keys
del(.foo)               # Delete key
```

## Conditionals and Logic

```jq
if .active then "yes" else "no" end           # If-then-else
if . > 10 then "high" elif . > 5 then "medium" else "low" end  # Elif
select(. > 5)                                # Filter values
map(select(.status == "active"))             # Filter array
```

**Comparison operators:**
- `==`, `!=` - Equal, not equal (strict)
- `>`, `>=`, `<`, `<=` - Numeric/string comparison
- `and`, `or`, `not` - Boolean logic
- `//` - Alternative operator: `.foo // 42` (use 42 if .foo is null/false)

**Error handling:**
```jq
try .foo catch "error"     # Catch errors
.foo?                      # Suppress errors (shorthand for try .foo)
try error("msg") catch .   # Handle custom errors
```

## String Operations

```jq
length                      # String length
explode                     # String to char codes
implode                     # Char codes to string
split(",")                  # Split by string
split(", *"; "g")           # Split by regex
join("-")                   # Join array into string
test("^foo")                # Regex match
sub("foo"; "bar")           # Replace first match
gsub("foo"; "bar")          # Replace all matches
ltrimstr("prefix")          # Remove prefix if present
rtrimstr("suffix")          # Remove suffix if present
trim                        # Remove whitespace
@uri                        # URL-encode
@html                       # HTML-escape
@base64                     # Base64 encode
@base64d                    # Base64 decode
```

**String interpolation:**
```jq
"The value is \(."")"       # Interpolate expression
@uri "https://example.com?q=\(.search)"  # Interpolate with formatting
```

## Array Operations

```jq
.[1] + .[2]                 # Concatenate arrays
. - ["a", "b"]              # Remove elements
length                      # Array length
first, last, nth(5)        # Access elements
map(.+1)                    # Transform each element
map_values(.+1)             # Transform object values
group_by(.category)         # Group by field
sort_by(.name)              # Sort by field
min_by(.price), max_by(.price)  # Min/max by field
indices(1)                  # Find all indices of value
index(1), rindex(1)        # First/last index
```

## Iteration and Reduction

```jq
.[]                         # Iterate array values
.[] | .name                 # Pipe each element
,                           # Concatenate outputs: .foo, .bar
range(10)                   # 0..9
range(0; 10; 2)             # 0,2,4,6,8
while(.<100; .*2)           # While loop
reduce .[] as $item (0; . + $item)      # Sum array
foreach .[] as $x (0; .+$x; [$x, .*2])  # With intermediate values
recurse(.foo[])             # Recursive traversal
walk(if type=="array" then sort else . end)  # Apply recursively
```

## Type Conversion and Checking

```jq
type                        # "array", "object", "string", "number", "boolean", "null"
tonumber                    # Parse string to number
tostring                    # Convert to JSON string representation
toboolean                   # Parse string to boolean
tojson, fromjson            # JSON encode/decode
arrays, objects, strings, numbers, nulls, booleans  # Type filters
scalars, values, normals    # Category filters
```

## Assignment and Modification

```jq
.foo = 1                    # Simple assignment
.foo |= . + 1               # Update assignment (modify in place)
.foo += 1                   # Arithmetic update (.foo |= . + 1)
(.a,.b) |= . + 1            # Update multiple paths
.posts[].comments |= . + ["new"]   # Update all matching paths
```

## Variables and Functions

```jq
. as $x | $x * 2            # Bind to variable
[.[] | . as $item | {$item}]  # Use in iteration
def increment: . + 1;       # Define function
def add(f): . + f;          # Function with filter argument
def add($x): . + $x;        # Function with value argument
```

## Date Operations

```jq
now                         # Current timestamp (seconds since epoch)
fromdate                    # Parse ISO 8601 date to timestamp
todate                      # Format timestamp to ISO 8601
strptime("%Y-%m-%d")        # Parse with format
strftime("%Y-%m-%d")        # Format with format
```

## Environment and I/O

```jq
$ENV.PAGER                  # Environment variable
env.PAGER                   # Current environment
input_filename              # Current input filename
input_line_number           # Current line number
debug                       # Print debug to stderr
stderr                      # Output to stderr
```

## Common Patterns

**Extract nested value:**
```jq
'.data.users[] | select(.id == 123) | .name'
```

**Transform array of objects:**
```jq
'.[] | {id, name: .user_name, email}'
```

**Sum field across array:**
```jq
'[.[] | .price] | add'
# Or: '.[] | .price | add' (with generator form)
```

**Filter and count:**
```jq
'[.[] | select(.active == true)] | length'
```

**Group by field:**
```jq
'group_by(.category) | map({category: .[0].category, count: length})'
```

**Flatten nested arrays:**
```jq
'.[][]'                     # Iterate nested
'flatten'                   # Fully flatten
```

**Merge objects:**
```jq
'add'                       # Merge array of objects
'$defaults + .'             # Merge with defaults
```

**CSV output:**
```jq
'.[] | [.id, .name, .email] | @csv'
```

**Format table:**
```jq
'.[] | [.name, .age] | @tsv'
```

**Read multiple files:**
```bash
jq -n 'inputs | .name' file1.json file2.json
```

## Module System

```jq
import "mylib" as lib;      # Import with prefix
include "helpers";          # Include directly
module {name: "mymodule"};  # Module metadata
```

## Progressive Disclosure References

For detailed reference information, see:
- **functions.md** - Complete function reference organized by category
- **examples.md** - Practical recipes and real-world examples
- **advanced.md** - Advanced features (streaming, recursion, modules, math)

## Quick Tips

1. **Use `-r` to get raw strings without quotes** for output to files or commands
2. **Pipe debug output:** `... | debug("value: \(.)") | ...` to inspect values
3. **Select by existence:** `select(has("foo"))` or `.foo? // null`
4. **Empty values:** `empty` produces no output, useful for filtering
5. **Multiple outputs:** `1, 2, 3` produces three separate outputs
6. **Path extraction:** `path(..)` gets all paths in structure
7. **Safe access:** `.foo?` prevents errors on non-objects
8. **Alternative values:** `.foo // "default"` for fallback
9. **Array comprehension:** `[.[] | . * 2]` collects into array
10. **Streaming mode:** `--stream` for huge JSON files
