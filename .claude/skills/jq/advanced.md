# Advanced jq Features

Deep dive into advanced jq capabilities including modules, streaming, recursion, and mathematical operations.

## Modules and Libraries

### Module System Overview

jq modules are `.jq` files that can be imported and reused across scripts.

### Creating a Module

```jq
# File: helpers.jq
def map_values(f):
  with_entries(.value |= f);

def sum_by(f):
  map(f) | add;

def avg_by(f):
  sum_by(f) / length;

module {
  name: "helpers",
  version: "1.0.0",
  description: "Helper functions for data processing"
};
```

### Importing Modules

```jq
# Import with namespace prefix
import "helpers" as helpers;

# Use imported functions
helpers::map_values(.+1)
helpers::sum_by(.price)

# Import without namespace (include)
include "helpers";

# Use directly
map_values(.+1)
```

### Importing JSON Data

```jq
# Import JSON as variable
import "config.json" as config;

# Access with namespace
config::settings.api_key
```

### Module Search Path

Modules are searched in:
1. Paths specified with `-L` option
2. `~/.jq/` (user's home directory)
3. `$ORIGIN/../lib/jq` (relative to jq binary)
4. `$ORIGIN/../lib`

Path substitutions:
- `~/` → user's home directory
- `$ORIGIN/` → directory of jq executable
- `./` or `.` → directory of the including file

### Module Metadata

```jq
module {
  name: "mymodule",
  version: "1.0.0",
  description: "My awesome module",
  homepage: "https://example.com/mymodule",
  dependencies: [
    {name: "othermodule", version: ">=1.0"}
  ]
};

# Read metadata from another module
modulemeta::mymodule
```

## Streaming JSON

### Why Use Streaming?

The `--stream` option parses JSON incrementally, useful for:
- Very large JSON files (gigabytes in size)
- Processing before full parse completes
- Memory-constrained environments

### Stream Format

Streaming produces path-value pairs:
- `[path, value]` - scalar values, empty arrays/objects
- `[path]` - end of array/object

Example:
```json
["a", ["b"]]
```

Stream output:
```json
[[0],"a"]
[[1,0],"b"]
[[1,0]]
[[1]]
```

### Streaming Functions

#### `tostream`
Convert value to stream format:
```jq
tostream
# Input: [1, [2, 3]]
# Output: [[0],1], [[1,0],2], [[1,1],3], [[1,0]], [[1]]
```

#### `fromstream`
Convert stream back to value:
```jq
fromstream(inputs)
# Reconstruct from streaming format
```

#### `truncate_stream`
Remove path prefixes:
```jq
truncate_stream(stream_expr)
# Removes first n path elements from stream outputs
```

### Practical Streaming Example

Process only specific fields from large JSON:
```bash
jq --stream 'select(.[1] != null and .[0][-1] == "target_field")' large.json
```

## Recursion and Iteration

### Recursive Functions

Define recursive functions for tree traversal:
```jq
# Sum nested numbers
def sum_nested:
  if type == "number" then .
  elif type == "array" then map(sum_nested) | add
  elif type == "object" then map(sum_nested) | add
  else 0 end;

# Find all values at a path
def find_values(path):
  path as $p |
  if type == "array" or type == "object" then
    .[] | find_values($p)
  else . end;
```

### Recursion with `recurse`

```jq
recurse(f)           # Recursively apply f
recurse(f; condition)  # Recurse while condition is true
recurse               # Same as recurse(.[]?)

# Examples:
recurse(.children[])              # All descendants
recurse(.+1; . < 10)              # 0,1,2,...,9
recurse(. * 2; . < 100)           # Powers of 2 under 100
```

### Tail Recursion Optimization

Tail calls are optimized when the expression before the recursive call outputs only one value:
```jq
# Efficient tail recursion
def recurse_sum:
  if length == 0 then 0
  else .[0] + (.[1:] | recurse_sum)
  end;

# Less efficient (not tail position)
def recurse_sum:
  if length == 0 then 0
  else .[0] + (.[1:] | recurse_sum) + debug("processing")
  end;
```

### Custom `while` Implementation

```jq
def while(cond; update):
  def _while:
    if cond then ., (update | _while) else empty end;
  _while;

def repeat(exp):
  def _repeat:
    exp, _repeat;
  _repeat;
```

## Control Flow and Labels

### Breaking Out of Loops

Use labels to break out of nested loops:
```jq
label $out |
reduce .[] as $item (null; if $item == "stop" then break $out else . end)

# Search with early exit
label $found |
foreach .[] as $x (null;
  if .x == $target then break $found else . end;
  $x)
```

### Error Handling Patterns

```jq
# Early return on error
def process:
  (try .validate catch error("Invalid input")) |
  .transform;

# Collect all errors
map(try .parse catch {error: .}) |
  map(select(has("error"))) as $errors |
  if $errors | length > 0 then
    error($errors | join(", "))
  else
    .
  end
```

## Assignment Deep Dive

### Assignment vs Update Assignment

```jq
# Plain assignment (=)
.a = .b          # Sets .a to the value of .b (from input)

# Update assignment (|=)
.a |= .b         # Sets .a to .b(.a), passing current .a value to .b

# Example difference:
# Input: {"a": {"b": 10}, "b": 20}

jq '.a = .b'     # Output: {"a": 20, "b": 20}
jq '.a |= .b'    # Output: {"a": 10, "b": 20}  (evaluates .a.b = 10)
```

### Complex Path Assignments

```jq
# Multiple paths
(.foo, .bar) |= . + 1

# Iterated paths
.posts[].comments |= . + ["new"]

# Conditional paths
(if type == "object" then .field else .field2 end) = "value"

# Computed keys
(.[$key]) |= . + 1
```

### Assignment Behavior

Values are immutable; assignment computes new values:
```jq
# This does NOT modify .bar
{foo: [1], bar: [1]} | .foo += [2]
# Output: {"foo": [1,2], "bar": [1]}  # bar unchanged
```

## Advanced Reduction

### Custom Reduction with `reduce`

```jq
# Group by key
reduce .[] as $item ({}; .[$item.key] += [$item])

# Build lookup map
reduce .[] as $item ({}; .[$item.id] = $item)

# Running total with conditions
reduce .[] as $item (
  {sum: 0, count: 0};
  if $item.value > 0 then
    {sum: .sum + $item.value, count: .count + 1}
  else .
  end
)
```

### `foreach` for Intermediate Results

```jq
# Running totals
foreach .[] as $item (0; . + $item; $item, .)
# Output pairs: each item with running total

# Indexed iteration
foreach .[] as $item (0; . + 1; {index: ., item: $item})

# State machine
foreach inputs as $line (
  {state: "idle", buffer: ""};
  if $line == "START" then {state: "active", buffer: ""}
  elif $line == "END" then {state: "idle", buffer: .buffer}
  elif .state == "active" then {state: "active", buffer: (.buffer + $line)}
  else .
  end;
  if .state == "idle" and .buffer != "" then .buffer else empty end
)
```

## Mathematical Operations

### IEEE754 Double Precision

All numbers in jq are IEEE754 double-precision floats:
- Approximately 15-17 decimal digits of precision
- Maximum value ≈ 1.7977e+308
- Minimum positive normal ≈ 2.225e-308
- Special values: `infinite`, `nan`

### Number Handling

```jq
# Literal preservation (with decnum build)
0.12345678901234567890123456789  # Preserved if not mutated

# Precision loss on operations
1E1234567890 | .  # May lose precision (converted to double)

# Big decimal comparisons
[1e100, 1e100 + 1] | map(. == .[0])
# Output: [true, true]  # Both compare equal due to precision limits
```

### Math Functions by Category

**Trigonometric:**
```jq
sin(x), cos(x), tan(x)
asin(x), acos(x), atan(x)
atan2(y, x)       # Arc tangent of y/x
sinh(x), cosh(x), tanh(x)
asinh(x), acosh(x), atanh(x)
```

**Exponential/Logarithmic:**
```jq
exp(x)            # e^x
exp10(x)          # 10^x
exp2(x)           # 2^x
expm1(x)          # e^x - 1 (more precise for small x)
log(x)            # Natural log
log10(x)          # Base-10 log
log2(x)           # Base-2 log
log1p(x)          # log(1+x) (more precise for small x)
```

**Power Functions:**
```jq
sqrt(x)           # Square root
cbrt(x)           # Cube root
pow(x, y)         # x^y
hypot(x, y)       # sqrt(x^2 + y^2)
```

**Rounding:**
```jq
ceil(x)           # Round up
floor(x)          # Round down
round(x)          # Round to nearest
trunc(x)          # Truncate toward zero
rint(x)           # Round to nearest integer
nearbyint(x)      # Round to nearest integer
```

**Special Functions:**
```jq
erf(x)            # Error function
erfc(x)           # Complementary error function
gamma(x)          # Gamma function
tgamma(x)         # True gamma function
lgamma(x)         # Log-gamma function
j0(x), j1(x)      # Bessel functions
y0(x), y1(x)      # Bessel functions of second kind
jn(n, x)          # Bessel function of order n
yn(n, x)          # Bessel y of order n
```

**Other:**
```jq
fabs(x)           # Absolute value (float)
abs(x)            # Absolute value (any number)
significand(x)    # Significand/mantissa
logb(x)           # Exponent of floating point
copysign(x, y)    # Copy sign from y to x
fmod(x, y)        # Floating point remainder
remainder(x, y)   # IEEE remainder
drem(x, y)        # Old name for remainder
fdim(x, y)        # Positive difference (x-y) or 0
fmax(x, y)        # Maximum
fmin(x, y)        # Minimum
frexp(x)          # Split into mantissa and exponent [m, e]
ldexp(x, e)       # x * 2^e
modf(x)           # Split into fractional and integer [f, i]
scalb(x, n)       # x * FLT_RADIX^n
scalbln(x, n)     # Same with long n
nextafter(x, y)   # Next representable value toward y
nexttoward(x, y)  # Same but with long double precision
fma(x, y, z)      # (x*y) + z with only one rounding
```

### Infinite and NaN

```jq
infinite          # Returns +Infinity
nan               # Returns NaN

isnan             # True if input is NaN
isfinite          # True if not infinite or NaN
isinfinite        # True if +Infinity or -Infinity
isnormal          # True if normal number (not zero, subnormal, infinite, NaN)
```

### Build Configuration

```jq
have_decnum               # True if built with decimal number support
have_literal_numbers      # True if literal number preservation enabled
$JQ_BUILD_CONFIGURATION   # Build configuration string
```

## Advanced Regex Patterns

### Named Captures

```jq
capture("(?<name>[a-z]+)-(?<num>[0-9]+)")
# Input: "abc-123"
# Output: {"name": "abc", "num": "123"}
```

### Conditional Regex with Flags

```jq
# Case-insensitive match
test("foo"; "i")

# Multi-line mode (dot matches newlines)
match(".*"; "m")

# Extended mode (ignore whitespace, allow comments)
match("
  \w+      # word characters
  \s+      # whitespace
  \d+      # digits
"; "x")

# Combination flags
match("pattern"; "im")    # Case-insensitive, multi-line
```

### Using Flags in Regex

```jq
# Flags embedded in pattern (PCRE style)
"(?i)case-insensitive"
"(?i)case(?-i)sensitive"  # Only first part case-insensitive

# Result: matches "caseSensitive", "CASEsensitive", etc.
```

## Advanced String Interpolation

### Nested Interpolation

```jq
"The value is \(.value | tonumber * 2)"
"Nested: \(.nested | tostring)"
```

### With Format Strings

```jq
@uri "https://example.com?q=\(.search | @uri)&lang=\(.lang)"
@csv "Name:\(.name),Age:\(.age)"
```

## I/O and Environment

### Multi-Input Processing

```jq
# Read multiple inputs
jq -n 'reduce inputs as $x (0; . + $x)' numbers.json

# Read line by line with -n
jq -n 'input | .field' <(echo '{"field": 1}'; echo '{"field": 2}')

# Combine with slurp
jq -s '.' file1.json file2.json  # Array of all inputs
```

### File Position

```jq
input_filename       # Name of current input file
input_line_number    # Current line number

# Track source
{file: input_filename, line: input_line_number, value: .}
```

### Debug Output

```jq
# Simple debug
debug  # Prints to stderr, passes value through

# Debug with message
debug("Processing: \(.)")

# Multiple debug points
. as $original |
debug("input", $original) |
.transform |
debug("output")

# stderr for raw output
stderr  # Raw output to stderr (no JSON encoding)
```

## Performance Optimization

### Memory Efficiency

```jq
# Use streaming for large files
jq --stream 'select(...)' large.json

# Delete unnecessary data early
del(.large_unneeded_field) | ...

# Use generators instead of arrays
.[] | select(...)      # Better than [.[] | select(...)]
```

### CPU Efficiency

```jq
# Avoid multiple passes
map(select(.active) | .name)  # Single pass
# vs
map(select(.active)) | map(.name)  # Two passes

# Use index-based lookups for large datasets
INDEX(.[]; .id) as $lookup |
.[] | .data | $lookup[.]

# Avoid expensive operations in loops
# Bad:
.[] | .name | ascii_upcase | ascii_downcase  # Pointless
# Good:
.[] | .name
```

### Caching Intermediate Results

```jq
# Use variables for expensive computations
.data as $data |
{$data, processed: $data | expensive_transform}

# Cache across multiple uses
length as $len |
{total: add, average: add / $len}
```

## Integration Patterns

### With Shell Commands

```bash
# Pipe to/from other tools
curl -s api.example.com | jq '.data'

# Use jq output in shell
value=$(jq -r '.field' config.json)

# Process line by line
jq -c '.[]' large.json | while read -r obj; do
  echo "$obj" | jq '.field'
done

# Conditional execution
if jq -e '.error' response.json > /dev/null; then
  echo "Error occurred"
fi
```

### With Data Tools

```bash
# Convert to CSV and import to spreadsheet
jq -r '.[] | [.a, .b, .c] | @csv' data.json > output.csv

# Import to database
jq -c '.[]' data.json | while read -r line; do
  psql -c "INSERT INTO table (data) VALUES ('$line')"
done

# Use with awk for custom formatting
jq -r '.[] | @tsv' data.json | awk '{printf "%-20s %10s\n", $1, $2}'
```

### With Version Control

```bash
# Compare JSON files
diff <(jq -S '.' file1.json) <(jq -S '.' file2.json)

# Sort JSON keys for easier diffs
jq -S '.' file.json > file.sorted.json

# Extract specific fields for comparison
jq '.field1, .field2' file1.json > fields1.json
jq '.field1, .field2' file2.json > fields2.json
diff fields1.json fields2.json
```
