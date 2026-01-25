# jq Function Reference

Complete reference of jq built-in functions organized by category.

## Array Functions

| Function | Description | Example |
|----------|-------------|---------|
| `length` | Number of elements | `[1,2,3] \| length` → `3` |
| `first` | First element | `[1,2,3] \| first` → `1` |
| `last` | Last element | `[1,2,3] \| last` → `3` |
| `nth(n)` | Element at index n | `[1,2,3] \| nth(1)` → `2` |
| `reverse` | Reverse array | `[1,2,3] \| reverse` → `[3,2,1]` |
| `sort` | Sort values | `[3,1,2] \| sort` → `[1,2,3]` |
| `sort_by(f)` | Sort by function result | `[{a:2},{a:1}] \| sort_by(.a)` |
| `group_by(f)` | Group by function result | `[{a:1},{a:1}] \| group_by(.a)` |
| `min` | Minimum value | `[3,1,2] \| min` → `1` |
| `max` | Maximum value | `[3,1,2] \| max` → `3` |
| `min_by(f)` | Element with minimum f value | `[{a:2},{a:1}] \| min_by(.a)` |
| `max_by(f)` | Element with maximum f value | `[{a:2},{a:1}] \| max_by(.a)` |
| `unique` | Remove duplicates, sorted | `[1,2,1,3] \| unique` → `[1,2,3]` |
| `unique_by(f)` | One element per unique f value | |
| `flatten` | Flatten nested arrays | `[[1],[2]] \| flatten` → `[1,2]` |
| `flatten(n)` | Flatten n levels | `[[[1]]] \| flatten(1)` → `[[1]]` |
| `range(upto)` | 0 to upto-1 | `range(3)` → `0,1,2` |
| `range(from;upto)` | from to upto-1 | `range(1;4)` → `1,2,3` |
| `range(from;upto;by)` | with step | `range(0;10;2)` → `0,2,4,6,8` |
| `transpose` | Transpose matrix | `[[1],[2,3]] \| transpose` → `[[1,2],[null,3]]` |
| `bsearch(x)` | Binary search, returns index | `[1,2,3] \| bsearch(2)` → `1` |
| `indices(s)` | All indices where s occurs | `[1,2,1,3] \| indices(1)` → `[0,2]` |
| `index(s)` | First index where s occurs | `[1,2,1,3] \| index(1)` → `0` |
| `rindex(s)` | Last index where s occurs | `[1,2,1,3] \| rindex(1)` → `2` |
| `combinations` | All combinations of arrays | `[[1,2],[3,4]] \| combinations` |
| `combinations(n)` | n-repetitions of input | `[1,2] \| combinations(2)` |

## Object Functions

| Function | Description | Example |
|----------|-------------|---------|
| `keys` | Object keys, sorted | `{a:1,b:2} \| keys` → `["a","b"]` |
| `keys_unsorted` | Keys in insertion order | `{a:1,b:2} \| keys_unsorted` |
| `length` | Number of key-value pairs | `{a:1,b:2} \| length` → `2` |
| `has(key)` | Check if key exists | `{a:1} \| has("a")` → `true` |
| `del(path)` | Delete key/path | `{a:1,b:2} \| del(.a)` → `{b:2}` |
| `to_entries` | Object to entry array | `{a:1} \| to_entries` → `[{"key":"a","value":1}]` |
| `from_entries` | Entry array to object | `[{"key":"a","value":1}] \| from_entries` → `{a:1}` |
| `with_entries(f)` | Transform entries | `with_entries(.key |= "KEY_" + .)` |
| `getpath(PATHS)` | Get values at paths | `getpath(["a","b"])` |
| `setpath(PATH;VALUE)` | Set value at path | `setpath(["a","b"];1)` → `{a:{b:1}}` |
| `delpaths(PATHS)` | Delete paths | `delpaths([["a"]])` |
| `pick(paths)` | Project by paths | `pick(.a,.b)` |

## String Functions

| Function | Description | Example |
|----------|-------------|---------|
| `length` | Character count | `"hello" \| length` → `5` |
| `utf8bytelength` | Byte count (UTF-8) | `"μ" \| utf8bytelength` → `2` |
| `explode` | String to codepoints | `"AB" \| explode` → `[65,66]` |
| `implode` | Codepoints to string | `[65,66] \| implode` → `"AB"` |
| `split(s)` | Split by string | `"a,b" \| split(",")` → `["a","b"]` |
| `split(regex;flags)` | Split by regex | `"a,b" \| split(", *")` |
| `splits(regex;flags)` | Split as stream | `"a,b" \| splits(",")` → `"a","b"` |
| `join(s)` | Join array into string | `["a","b"] \| join("-")` → `"a-b"` |
| `ltrimstr(s)` | Trim prefix | `"fooprefix" \| ltrimstr("foo")` → `"prefix"` |
| `rtrimstr(s)` | Trim suffix | `"suffixbar" \| rtrimstr("bar")` → `"suffix"` |
| `trimstr(s)` | Trim both ends | `"foo" \| trimstr("\"")` → `foo` |
| `trim` | Trim whitespace | `" abc " \| trim` → `"abc"` |
| `ltrim` | Trim leading whitespace | `" abc " \| ltrim` → `"abc "` |
| `rtrim` | Trim trailing whitespace | `" abc " \| rtrim` → `" abc"` |
| `ascii_upcase` | Convert to uppercase | `"abc" \| ascii_upcase` → `"ABC"` |
| `ascii_downcase` | Convert to lowercase | `"ABC" \| ascii_downcase` → `"abc"` |
| `startswith(str)` | Check prefix | `"foo" \| startswith("fo")` → `true` |
| `endswith(str)` | Check suffix | `"bar" \| endswith("ar")` → `true` |
| `contains(s)` | Check if contains substring | `"foobar" \| contains("oob")` → `true` |
| `inside(s)` | Check if contained in s | `"foo" \| inside("foobar")` → `true` |

## Regex Functions (Oniguruma)

| Function | Description | Example |
|----------|-------------|---------|
| `test(regex)` | Match test, returns bool | `"foo" \| test("foo")` → `true` |
| `test(regex;flags)` | With flags (g,i,m,n,s,l,x,p) | `"foo" \| test("f.o"; "i")` |
| `match(regex)` | Match object with details | `"foo" \| match("f.o")` → `{"offset":0,"length":3,...}` |
| `match(regex;flags)` | With flags | `"foo" \| match("f.+"; "g")` |
| `capture(regex)` | Named captures as object | `"a-1" \| capture("(?<a>[a-z])-(?<n>[0-9])")` |
| `capture(regex;flags)` | With flags | |
| `scan(regex)` | Stream of matching substrings | `"abcabc" \| scan("ab")` → `"ab","ab"` |
| `scan(regex;flags)` | With flags | |
| `sub(regex;tostring)` | Replace first match | `"aaa" \| sub("a"; "b")` → `"baa"` |
| `sub(regex;tostring;flags)` | With flags | `"aaa" \| sub("a"; "b"; "g")` → `"bbb"` |
| `gsub(regex;tostring)` | Replace all matches | `"aaa" \| gsub("a"; "b")` → `"bbb"` |
| `gsub(regex;tostring;flags)` | With flags | |

**Flags:** `g` (global), `i` (case-insensitive), `m` (multi-line), `s` (single-line), `n` (ignore empty matches), `x` (extended/verbose), `p` (both s and m), `l` (longest matches)

## Arithmetic Functions

| Function | Description | Example |
|----------|-------------|---------|
| `+` | Addition (numbers, strings, arrays, objects) | `1 + 2` → `3` |
| `-` | Subtraction (numbers, array difference) | `5 - 3` → `2` |
| `*` | Multiplication (numbers, string*n, objects) | `3 * 4` → `12` |
| `/` | Division (numbers, string split) | `10 / 2` → `5` |
| `%` | Modulo | `10 % 3` → `1` |
| `abs` | Absolute value | `-5 \| abs` → `5` |
| `floor` | Round down | `3.9 \| floor` → `3` |
| `sqrt` | Square root | `9 \| sqrt` → `3` |

## Math Functions (C Library)

**One-argument:** `acos`, `acosh`, `asin`, `asinh`, `atan`, `atanh`, `cbrt`, `ceil`, `cos`, `cosh`, `erf`, `erfc`, `exp`, `exp10`, `exp2`, `expm1`, `fabs`, `floor`, `gamma`, `j0`, `j1`, `lgamma`, `log`, `log10`, `log1p`, `log2`, `logb`, `nearbyint`, `rint`, `round`, `significand`, `sin`, `sinh`, `sqrt`, `tan`, `tanh`, `tgamma`, `trunc`, `y0`, `y1`

**Two-argument:** `atan2`, `copysign`, `drem`, `fdim`, `fmax`, `fmin`, `fmod`, `frexp`, `hypot`, `jn`, `ldexp`, `modf`, `nextafter`, `nexttoward`, `pow`, `remainder`, `scalb`, `scalbln`, `yn`

**Three-argument:** `fma`

## Type Functions

| Function | Description | Example |
|----------|-------------|---------|
| `type` | Type name string | `42 \| type` → `"number"` |
| `arrays` | Select only arrays | |
| `objects` | Select only objects | |
| `iterables` | Select arrays or objects | |
| `booleans` | Select only booleans | |
| `numbers` | Select only numbers | |
| `strings` | Select only strings | |
| `nulls` | Select only null | |
| `values` | Select non-null | |
| `scalars` | Select non-iterables | |
| `normals` | Select normal numbers | |
| `finites` | Select finite numbers | |
| `isnan` | True if NaN | |
| `isfinite` | True if finite | |
| `isinfinite` | True if infinite | |
| `isnormal` | True if normal number | |
| `infinite` | Return positive infinite value | |
| `nan` | Return NaN value | |

## Conversion Functions

| Function | Description | Example |
|----------|-------------|---------|
| `tonumber` | Parse to number | `"42" \| tonumber` → `42` |
| `tostring` | Convert to string | `42 \| tostring` → `"42"` |
| `toboolean` | Parse to boolean | `"true" \| toboolean` → `true` |
| `tojson` | Encode as JSON string | `[1] \| tojson` → `"[1]"` |
| `fromjson` | Parse JSON string | `"[1]" \| fromjson` → `[1]` |

## Format Functions

| Function | Description | Example |
|----------|-------------|---------|
| `@text` | Apply tostring | |
| `@json` | Serialize as JSON | |
| `@html` | HTML-escape | `"<div>" \| @html` → `"&lt;div&gt;"` |
| `@uri` | Percent-encode | `"a b" \| @uri` → `"a%20b"` |
| `@urid` | Percent-decode | `"a%20b" \| @urid` → `"a b"` |
| `@csv` | Format as CSV | `[1,"a"] \| @csv` → `"1,""a""` |
| `@tsv` | Format as TSV | `[1,"a"] \| @tsv` → `"1\t"a"` |
| `@sh` | Shell-escape | |
| `@base64` | Base64 encode | `"abc" \| @base64` → `"YWJj"` |
| `@base64d` | Base64 decode | `"YWJj" \| @base64d` → `"abc"` |

## Date/Time Functions

| Function | Description | Example |
|----------|-------------|---------|
| `now` | Current timestamp (seconds) | `now` → `1234567890` |
| `fromdate` | Parse ISO 8601 to timestamp | `"2024-01-01T00:00:00Z" \| fromdate` |
| `fromdateiso8601` | Same as fromdate | |
| `todate` | Format timestamp to ISO 8601 | `1234567890 \| todate` |
| `todateiso8601` | Same as todate | |
| `strptime(fmt)` | Parse with format | `"2024-01-01" \| strptime("%Y-%m-%d")` |
| `strftime(fmt)` | Format with format | |
| `strflocaltime(fmt)` | Format using local timezone | |
| `gmtime` | Timestamp to broken-down time | |
| `localtime` | Timestamp to local broken-down time | |
| `mktime` | Broken-down time to timestamp | |

## Control Flow Functions

| Function | Description | Example |
|----------|-------------|---------|
| `map(f)` | Apply f to each element | `[1,2,3] \| map(.+1)` → `[2,3,4]` |
| `map_values(f)` | Apply f to object values | `{a:1} \| map_values(.+1)` |
| `select(f)` | Filter where f is true | `[1,2,3] \| map(select(.>1))` |
| `empty` | Produce no output | `1, empty, 2` → `1,2` |
| `error(msg)` | Produce error | `error("bad")` raises error |
| `error` | Error with input value | |
| `halt` | Stop with exit 0 | |
| `halt_error(n)` | Stop with exit code n | |
| `limit(n;expr)` | First n outputs | `limit(2; range(10))` → `0,1` |
| `skip(n;expr)` | Skip first n outputs | `skip(5; range(10))` → `5-9` |
| `first(expr)` | First output | `first(range(10))` → `0` |
| `last(expr)` | Last output | `last(range(10))` → `9` |
| `nth(n;expr)` | nth output | `nth(5; range(10))` → `5` |
| `isempty(expr)` | True if no outputs | `isempty(empty)` → `true` |
| `while(cond;update)` | Repeat while cond true | `while(.<100; .*2)` |
| `repeat(exp)` | Repeat until error | `repeat(.*2, error)?` |
| `until(cond;next)` | Repeat until cond true | `until(.>10; .*2)` |
| `recurse(f)` | Recursive descent | `recurse(.children[])` |
| `recurse(f;cond)` | With condition | `recurse(.+1; .<10)` |
| `walk(f)` | Apply f recursively | `walk(if type=="array" then sort else . end)` |
| `break $label` | Break out of loop | `label $out \| ... break $out` |
| `label $x \| ...` | Define break label | |

## Reduction Functions

| Function | Description | Example |
|----------|-------------|---------|
| `add` | Sum/concatenate array | `[1,2,3] \| add` → `6` |
| `add(generator)` | Sum generator results | `add(.[].a)` |
| `any` | True if any element true | `[false,true] \| any` → `true` |
| `any(condition)` | Test each element | `[1,2,3] \| any(.>2)` → `true` |
| `any(gen;cond)` | Test generator outputs | |
| `all` | True if all elements true | `[true,true] \| all` → `true` |
| `all(condition)` | Test each element | `[1,2,3] \| all(.>0)` → `true` |
| `all(gen;cond)` | Test generator outputs | |
| `reduce` | Fold left | `reduce .[] as $x (0; .+$x)` |
| `foreach` | Fold with intermediates | `foreach .[] as $x (0; .+$x; $x)` |

## Utility Functions

| Function | Description | Example |
|----------|-------------|---------|
| `builtins` | List all builtins (name/arity) | `builtins` |
| `env` | Current environment object | `env.PAGER` |
| `$ENV` | Environment at startup | `$ENV.PATH` |
| `input_filename` | Current file name | |
| `input_line_number` | Current line number | |
| `debug` | Print to stderr, pass through | |
| `debug(msgs)` | Print msgs to stderr | |
| `stderr` | Output to stderr (raw) | |
| `input` | Read one input value | |
| `inputs` | Read all remaining inputs | |
| `$ARGS.named` | Named arguments (--arg) | |
| `$ARGS.positional` | Positional arguments (--args) | |
| `have_decnum` | True if decnum support | |
| `have_literal_numbers` | True if literal number support | |
| `$JQ_BUILD_CONFIGURATION` | Build config string | |

## Path Functions

| Function | Description | Example |
|----------|-------------|---------|
| `path(expr)` | Get path as array | `path(.a.b[0])` → `["a","b",0]` |
| `paths` | All paths in value | `[paths]` |
| `paths(f)` | Paths where f is true | `paths(type=="number")` |
| `getpath(ARRAY)` | Get value at path | `getpath(["a","b"])` |
| `setpath(ARRAY;VALUE)` | Set value at path | `setpath(["a"];1)` |
| `delpaths(ARRAY)` | Delete paths | `delpaths([["a"]])` |

## SQL-Style Operators

| Function | Description |
|----------|-------------|
| `INDEX(stream;expr)` | Build index object |
| `JOIN($idx;stream;idx_expr)` | Join stream with index |
| `JOIN($idx;stream;idx_expr;join_expr)` | Join with custom expression |
| `IN(s)` | Test if in stream |
| `IN(source;s)` | Test if any in source in s |

## Streaming Functions

| Function | Description |
|----------|-------------|
| `truncate_stream(stream)` | Truncate stream paths |
| `fromstream(stream)` | Convert stream to values |
| `tostream` | Convert value to stream |
