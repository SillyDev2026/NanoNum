# NanoNum

**NanoNum** is a compact huge-number formatter, parser, serializer, math layer, and leaderboard codec for Roblox Luau.

It is designed for simulator/clicker-style games that need to **store, compare, calculate with, and display values far beyond normal `number` range** without paying for a fixed-width huge-number record on every value.

NanoNum uses an **adaptive bit-packed `buffer` representation**. Small integers can use one byte, larger finite values use compact integer/normal records, huge values switch to logarithmic storage, and astronomical values use layered storage. Multiple NanoNums can also be packed into one shared bitstream so record padding is not repeated.

> Current release: **V0.5.0 — Register Scope V1**  
> Typecheck: **V2**  
> Parser: **V5**  
> Suffix system: **V3**  
> Roman formatter: **V1**  
> Time / utility formatting: **V1**  
> Performance layout: **V5**  
> Path architecture: **V1 / Path 0**  
> Notation: **V4 / Compact Coordinate V1**  
> Math: **V8**  
> Math correctness: **V3**  
> Math safety: **V1**  
> Math performance: **V2 / Math Path V3**  
> Tetration: **V3**  
> Decimal tetration: **V1**  
> Slog: **V2**  
> Gamma/Beta: **V2**  
> Leaderboard codec: **LB V1**  
> Register scopes: **V1**

---

## Highlights

- Adaptive Roblox `buffer` representation
- **1-byte** storage for zero and many small integers
- Exact variable-bit integer records when that representation is cheaper
- Symbolic huge values such as `1e1000`
- Symbolic tiny values such as `1e-1000`
- Direct and logarithmic layered values
- **Parser V5** with ordinary, suffix, E, L, and legacy `e`-family syntax
- **Notation V4** with clean `E` -> `L` progression
- Compact E/L coordinates such as `E100UCe`, `L2 100UCe`, and `L3 100UCe`
- Standard, Extended, Hybrid, Alphabetic, Metric, Exponent, Scientific, Engineering, Roman, and Roman Extended formatting
- Time/duration, clock, rate, byte-size, ordinal, and signed-value formatting
- Bit-level `packMany` / `unpackMany`
- Structural validation and protected decode helpers
- Monotonic 53-bit-safe **LB V1** leaderboard codec
- Full mixed-type math API for `number`, `buffer`, and `string`
- **Math V8** safety boundary for normal public math calls
- `tryCompile`, `tryMath`, and `tryCompare` for unknown/untrusted values
- **54 typed direct math calls** through `NanoNum.fast`
- `compile`, `bindBinary`, and `bindRight` for hot loops
- Logs, roots, powers, rounding, interpolation, series, combinatorics, simulator economy helpers, tetration, slog, gamma, beta, and more
- **Full Typecheck V2** public module surface
- **Register Scope V1** isolates register-heavy subsystems so the outer module does not exceed Luau's local-register ceiling
- `--!native`
- `--!optimize 2`

---

# Installation

Place the module in your game and require it normally:

```lua
local NanoNum = require(path.To.NanoNum)
```

The source currently names its internal module table `NanoFormat`; that does not affect usage. You can require the ModuleScript into any variable name you want.

---

# Quick Start

```lua
local NanoNum = require(path.To.NanoNum)

local small = NanoNum.fromNumber(1250)
local huge = NanoNum.fromString("1e1000")
local massive = NanoNum.fromString("1e3000")
local tiny = NanoNum.fromString("1e-1000")

print(NanoNum.format(small))
-- 1.25k

print(NanoNum.formatScientific(huge))
-- 1e1000

print(NanoNum.format(massive))
-- E3,000

print(NanoNum.formatScientific(tiny))
-- 1e-1000
```

NanoNum values are buffers:

```lua
local value = NanoNum.fromString("1e1000")

print(typeof(value))
-- buffer
```

Math functions return NanoNum buffers too:

```lua
local a = NanoNum.fromString("1e1000")
local b = NanoNum.mul(a, 10)
local c = NanoNum.pow10(5000)

print(NanoNum.format(b))
print(NanoNum.format(c))
```

The flexible math API accepts `number`, `string`, and `buffer` inputs:

```lua
local result = NanoNum.add("1e1000", 250)
local power = NanoNum.pow("1e50", 2)
```

## Clean E / L progression

V0.5.0 keeps coordinates readable instead of falling back to raw Lua scientific text:

```lua
local value = NanoNum.fromString("1e308")

print(NanoNum.format(value, 2))
-- 1e308

value = NanoNum.pow10(value)
print(NanoNum.format(value, 2))
-- E100UCe

value = NanoNum.pow10(value)
print(NanoNum.format(value, 2))
-- L2 100UCe

value = NanoNum.pow10(value)
print(NanoNum.format(value, 2))
-- L3 100UCe
```

`100UCe` is a coordinate-only compact spelling for `1e308`:

```text
1e308
= 100 * 10^306
= 100UCe
```

The public Standard suffix table itself still ends at `Ce`; this coordinate extension does not change normal Standard suffix semantics.

---

# Why NanoNum?

A traditional layered huge-number buffer often uses a fixed layout similar to:

```text
sign     : 1 byte
layer    : 8 bytes
exponent : 8 bytes
-------------------
total    : 17 bytes
```

That layout is simple, but even `0`, `1`, or `100` still costs the full record size.

NanoNum instead selects a compact record class based on the value.

Conceptually:

```text
small integer
    ↓
1-byte integer record

larger exact integer
    ↓
variable-bit integer record

ordinary decimal
    ↓
31-bit normal record

1e1000
    ↓
log record

L1000 1000
    ↓
layer record

L(10^308) 5
    ↓
log-layer field inside a layer record
```

The representation grows only when the value requires more metadata.

---

# Adaptive Storage

NanoNum records are bit-packed.

A standalone Roblox `buffer` must still have a whole-byte physical length, but NanoNum tracks the **useful bit length** separately. This matters when values are later combined with `packMany()`.

Typical examples from the current codec design:

| Value | Useful bits | Physical bytes |
|---|---:|---:|
| `0` | 8 | 1 |
| `1` | 8 | 1 |
| `100` | 8 | 1 |
| `1000` | 16 | 2 |
| `1e6` | 17 | 3 |
| `1e12` | 18 | 3 |
| normal decimal record | 31 | 4 |
| `1e1000` | 24 | 3 |
| layered values | variable | variable |

The exact choice is value-dependent. NanoNum can choose a logarithmic record for exact powers of ten when that record is smaller than the integer/normal alternative.

Inspect sizes with:

```lua
local value = NanoNum.fromString("1e1000")

print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))
```

---

# Record Classes

The current binary format has seven top-level prefix classes.

## Integer / Tiny

Zero and positive integers from `0` through `127` can use a one-byte record.

```lua
NanoNum.fromNumber(0)
NanoNum.fromNumber(1)
NanoNum.fromNumber(100)
NanoNum.fromNumber(127)
```

## Negative Small

Small negative integers from `-1` through `-64` also use one byte.

```lua
NanoNum.fromNumber(-1)
NanoNum.fromNumber(-64)
```

## Variable Integer

Larger safe integers can use an exact variable-bit integer record.

```lua
NanoNum.fromNumber(1250)
NanoNum.fromNumber(123456789)
```

NanoNum can still choose a smaller logarithmic representation when that is cheaper, especially for exact powers of ten.

## Normal

Ordinary finite decimals use a compact scientific-style record with a 16-bit quantized mantissa field.

```lua
NanoNum.fromNumber(12345.678)
```

## Log

Layer-1 values store a base-10 exponent symbolically.

```lua
NanoNum.fromLog10(1000)
-- 10^1000

NanoNum.fromLog10(-1000)
-- 10^-1000
```

## Layer

Values above layer 1 use a layer record.

```lua
NanoNum.fromLayer(2, 1000)
NanoNum.fromLayer(1000, 1000)
```

The layer field can be encoded directly or logarithmically.

## Special

Special records represent:

- `+inf`
- `-inf`
- `NaN`
- reserved/invalid forms

---

# Number Range

NanoNum separates its **finite carrier limits** from its **conceptual huge-number range**.

The current implementation exposes finite scalar/layer carrier constants:

```lua
NanoNum.MAX_LAYER
-- 1e308

NanoNum.MAX_LAYER_LOG10
-- 1e308
```

Those constants are not meant to say that NanoNum's final value range stops at `1e308`. They are finite fields used to describe layer counts, layer logarithms, and top scalars inside the compact representation.

## Conceptual Maximum

NanoNum's intended maximum scale is:

```text
10 ↑↑ (10 ↑ (2^1024))
```

Equivalently:

```text
10 tetrated to height 10^(2^1024)
```

where:

```text
↑   = exponentiation
↑↑  = tetration
```

The important idea is that NanoNum does **not** attempt to materialize that tetration height as a normal Luau `number`. It represents astronomical heights symbolically through the layer/log-layer system.

Conceptually:

```text
height = 10^(2^1024)
value  = 10 ↑↑ height
```

For example, log-layer storage describes the logarithm of a layer count instead of allocating or iterating through every layer:

```lua
local value = NanoNum.fromLayerLog10(1e308, 10)
print(NanoNum.format(value))
```

The formatter uses NanoNum's compact layer notation for values in this region, such as:

```text
L(10^...) ...
```

### About `MAX - 1`

At this scale, expressions such as `2^1024 - 1`, `1e308 - 1`, or "one layer below the maximum" cannot be represented exactly with an ordinary IEEE-754 Luau `number`. Boundary tests should therefore use NanoNum's symbolic layer/log-layer representation instead of subtracting `1` from a native floating-point value.

This maximum describes NanoNum's huge-number/layer envelope. NanoNum is still a compact, quantized representation rather than an exact arbitrary-precision integer engine.

---
# Constructors

## `fromNumber`

```lua
local n = NanoNum.fromNumber(12345.678)
```

Handles finite values, zero, infinities, and NaN.

```lua
NanoNum.fromNumber(0)
NanoNum.fromNumber(1000)
NanoNum.fromNumber(-5)
NanoNum.fromNumber(math.huge)
NanoNum.fromNumber(-math.huge)
```

The V0.5.0 path includes dedicated hot paths for zero, positive one-byte integers, negative one-byte integers, exact safe integers, powers of ten, and ordinary normal values.

---

## `fromLog10`

Creates a layer-1 logarithmic value.

```lua
local huge = NanoNum.fromLog10(1000)
-- 10^1000

local tiny = NanoNum.fromLog10(-1000)
-- 10^-1000
```

Optional outer sign:

```lua
local negativeHuge = NanoNum.fromLog10(1000, true)
```

---

## `fromLayer`

```lua
local value = NanoNum.fromLayer(
    1000,  -- layer
    5,     -- top
    false, -- negative
    false  -- reciprocal
)
```

The constructor canonicalizes reducible layered inputs when possible.

---

## `fromLayerLog10`

Use this when the layer count itself is too large to represent directly.

```lua
local value = NanoNum.fromLayerLog10(
    1e308, -- log10(layer count)
    5
)
```

---

## `compile`

`compile()` converts supported flexible values into a validated NanoNum buffer once.

```lua
local compiled = NanoNum.compile("1e1000")
```

Accepted input types:

```text
buffer -> validated/reused
number -> fromNumber
string -> fromString
other  -> NaN buffer
```

This is especially useful before hot loops so a constant string does not need to be reparsed on every operation.

---

# Parser V5

The current parser supports ordinary decimal input, scientific notation, public suffixes, reciprocal syntax, compact exponent syntax, restored L-notation, compact coordinate suffixes, and the legacy `e`-family layer notation.

Examples:

```lua
NanoNum.fromString("1250")
NanoNum.fromString("12345.678")
NanoNum.fromString("1e1000")
NanoNum.fromString("1e-1000")
NanoNum.fromString("1.25M")
NanoNum.fromString("1/1k")

NanoNum.fromString("E3,000")
NanoNum.fromString("E1M")
NanoNum.fromString("E100UCe")

NanoNum.fromString("L2 1000")
NanoNum.fromString("L3 1k")
NanoNum.fromString("L3:1k")
NanoNum.fromString("L2 100UCe")
NanoNum.fromString("L3 100UCe")
NanoNum.fromString("L(10^1M) 1k")

NanoNum.fromString("1/L3 1k")
NanoNum.fromString("-L3 1k")

-- Legacy layer syntax remains parseable
NanoNum.fromString("ee1000")
NanoNum.fromString("eee5")
NanoNum.fromString("e^1000 5")
NanoNum.fromString("e^(10^1e308) 5")
```

Whitespace is accepted around structured layer forms where the parser expects a separator.

The parser avoids first converting enormous scientific strings to a native Luau number when doing so would overflow to infinity or underflow to zero:

```lua
local huge = NanoNum.fromString("1e1000")
local tiny = NanoNum.fromString("1e-1000")
```

Both remain symbolic NanoNum values.

V0.5.0 also keeps the previous raw-coordinate fallback strings parseable for compatibility:

```text
E1e+308
L3 1e+308
```

---

# Notation V4 — Standard -> E -> L

Notation V4 restores the compact L-notation path and fixes E/L coordinate rendering.

The main progression is:

```text
ordinary / suffix value
        ↓
compact E notation for layer-1/log values
        ↓
L notation for actual layer-2+ values
```

Examples:

```text
1e3                  -> 1k
1e3000               -> E3,000
10^(1,000,000)       -> E1M
10^(1e308)           -> E100UCe
10^(10^(1e308))      -> L2 100UCe
10^(10^(10^(1e308))) -> L3 100UCe
```

Direct layer examples:

```text
fromLayer(2, 309)         -> L2 309
fromLayer(3, 1000)        -> L3 1k
fromLayer(1e6, 1000)      -> L1M 1k
fromLayerLog10(1e6, 1000) -> L(10^1M) 1k
```

A reciprocal layer is prefixed with `1/`:

```text
1/L2 1k
```

A negative outer sign stays outside the representation:

```text
-L3 1k
```

## Compact Coordinate V1

E/L coordinates are themselves compacted instead of using raw Lua text.

The public Standard suffix table remains unchanged through `Ce`, but E/L scalar coordinates have one private extension:

```text
10^306 -> UCe
1e308  -> 100UCe
```

Therefore:

```text
E1e+308      -> E100UCe
L2 1e+308    -> L2 100UCe
L3 1e+308    -> L3 100UCe
```

This is display/parser behavior only; it does not change the NanoNum wire representation.

## Legacy display modes

Scientific/Engineering/Hybrid/Alphabetic/Metric formatting can still use the older `e`-family form where appropriate:

```text
ee1000
eee5
e^1000 5
e^(10^308) 5
```

The parser accepts both families.

---

# Formatting

Main formatter:

```lua
NanoNum.format(value, precision?, suffixType?)
```

`value` is a NanoNum `buffer`. Default precision is `4`; explicit precision is clamped to `1..8`.

```lua
local value = NanoNum.fromNumber(1250000)

print(NanoNum.format(value))
-- 1.25M
```

Dedicated number-format helpers:

```lua
NanoNum.formatStandard(value, precision?)
NanoNum.formatExtended(value, precision?)
NanoNum.formatExponent(value, precision?)
NanoNum.formatHybrid(value, precision?)
NanoNum.formatAlphabetic(value, precision?)
NanoNum.formatMetric(value, precision?)
NanoNum.formatScientific(value, precision?)
NanoNum.formatEngineering(value, precision?)
NanoNum.formatRoman(value, precision?)
NanoNum.formatRomanExtended(value, precision?)
```

## Roman V1

Classical Roman display:

```lua
print(NanoNum.formatRoman(NanoNum.fromNumber(2026)))
-- MMXXVI
```

Classical mode supports magnitudes through `3999`.

Extended Roman mode uses parenthesized x1000 groups and supports integers through the safe-integer envelope:

```lua
print(NanoNum.formatRomanExtended(NanoNum.fromNumber(4000)))
-- (IV)
```

Roman formatting is display-only. Unsupported Roman values fall back to normal NanoNum formatting.

## Time / Duration V1

`formatTime` and its alias `formatDuration` accept normal NanoNum math inputs (`number`, `string`, or `buffer`):

```lua
NanoNum.formatTime(3661)
-- compact duration

NanoNum.formatTime(3661, "long")
-- word-style duration

NanoNum.formatClock(3661, 0)
-- timer/clock-style output
```

Accepted time styles:

```text
compact
long
clock
seconds
```

Aliases also include:

```text
timer -> clock
words -> long
raw   -> seconds
```

Parse duration strings:

```lua
NanoNum.parseTime("1h 30m")
NanoNum.fromTime("1h 30m")
NanoNum.parseDuration("1h 30m")
```

## Utility Formatters

```lua
NanoNum.formatRate(value, unit?, precision?, suffixType?)
NanoNum.formatBytes(value, precision?, binary?)
NanoNum.formatOrdinal(value)
NanoNum.formatSigned(value, precision?, suffixType?)
NanoNum.toNumberSafe(value)
```

Examples:

```lua
NanoNum.formatRate("1e6", "s")
-- 1M/s

NanoNum.formatBytes(1048576, 2, true)
-- 1 MiB

NanoNum.formatOrdinal(23)
-- 23rd

NanoNum.formatSigned(1250)
-- +1.25k
```

`formatOrdinal()` is a text/UI helper; it does not change the underlying NanoNum value.

---

# Suffix Types

NanoNum V0.5.0 exposes ten canonical formatting modes:

```text
standard
extended
hybrid
alphabetic
metric
exponent
scientific
engineering
roman
romanextended
```

Aliases are accepted:

| Alias | Mode |
|---|---|
| `short` | `standard` |
| `ext`, `compact` | `extended` |
| `mixed` | `hybrid` |
| `alpha`, `letters` | `alphabetic` |
| `si` | `metric` |
| `exp`, `enotation` | `exponent` |
| `sci` | `scientific` |
| `eng` | `engineering` |
| `romanx`, `roman_ext` | `romanextended` |

Set the default:

```lua
NanoNum.setDefaultSuffixType("hybrid")
```

Check a mode or alias:

```lua
print(NanoNum.isSuffixType("standard"))
print(NanoNum.isSuffixType("romanx"))
```

## Standard

Standard uses the V0.5.x simulator suffix table through centillion:

```text
1e3   -> 1k
1e6   -> 1M
1e9   -> 1B
...
1e303 -> 1Ce
```

Current public maximum suffix index:

```lua
NanoNum.STANDARD_SUFFIX_MAX_INDEX
-- 101
```

The public Standard table intentionally stays at 101 for compatibility.

At exponent `3000` and above, Standard uses compact E notation:

```text
1e3000 -> E3,000
```

E/L **coordinates** may additionally use the private `UCe` coordinate spelling:

```text
10^(1e308) -> E100UCe
```

That does not make `getSuffix(102, "standard")` a public Standard suffix.

## Extended

Extended keeps the Standard table through index 101, then uses generated alphabetic suffixes through index 999 before falling back to E notation.

Conceptually:

```text
standard suffixes through Ce
then
aa, ab, ac, ...
through index 999
then
E notation
```

```lua
NanoNum.formatExtended(value)
```

## Hybrid

Hybrid keeps Standard through index 101 and then continues generated alphabetic suffixes without Extended's index-1000 cutoff.

```lua
NanoNum.formatHybrid(value)
```

## Alphabetic

Alphabetic starts generated suffixes immediately:

```text
1e3 -> 1aa
1e6 -> 1ab
...
```

```lua
NanoNum.formatAlphabetic(value)
```

Generated alphabetic suffixes support lengths from 2 through 11 characters within the safe integer index envelope.

## Metric

Metric suffixes:

```text
k M G T P E Z Y R Q
```

```lua
print(NanoNum.formatMetric(
    NanoNum.fromNumber(1e9)
))
-- 1G
```

Maximum metric suffix index:

```lua
NanoNum.METRIC_SUFFIX_MAX_INDEX
-- 10
```

## Scientific

```lua
print(NanoNum.formatScientific(
    NanoNum.fromString("1e300")
))
-- 1e300
```

For layered values Scientific keeps the legacy `e`-family representation instead of the Standard L display.

## Engineering

Engineering notation keeps the exponent divisible by three:

```lua
print(NanoNum.formatEngineering(
    NanoNum.fromNumber(10000)
))
-- 10e3
```

## Exponent / E Notation

Exponent mode uses compact display exponent notation:

```lua
print(NanoNum.formatExponent(
    NanoNum.fromString("1e3000")
))
-- E3,000
```

Mantissas are preserved:

```text
1.25e3006
->
1.25E3,006
```

Reciprocals are preserved:

```text
1e-3000
->
1/E3,000
```

Coordinates are compacted too:

```text
10^(1,000,000) -> E1M
10^(1e308)      -> E100UCe
```

Automatic Standard/Extended E cutoff:

```lua
NanoNum.E_NOTATION_START
-- 3000
```

## Roman / Roman Extended

Use:

```lua
NanoNum.formatRoman(value)
NanoNum.formatRomanExtended(value)
```

Roman modes are intended for UI/display rather than huge-number progression.

---

# Suffix Lookup

Get a suffix:

```lua
print(NanoNum.getSuffix(1, "standard"))
-- k

print(NanoNum.getSuffix(2, "standard"))
-- M
```

Find a suffix index:

```lua
print(NanoNum.suffixIndex("M", "standard"))
-- 2
```

Alphabetic:

```lua
print(NanoNum.getSuffix(1, "alphabetic"))
-- aa

print(NanoNum.suffixIndex("aa", "alphabetic"))
-- 1
```

---

# Reciprocal Formatting

Tiny values stay symbolic instead of collapsing to native zero.

Examples:

```text
1/100
1/1k
1/1M
1/1e1000
1/E3,000
1/L2 1000
```

```lua
local value = NanoNum.fromString("1e-3000")
print(NanoNum.format(value))
-- 1/E3,000
```

---

# Decode API

## `decodeAt`

Trusted/hot-path decoder:

```lua
local decoded, nextBit = NanoNum.decodeAt(data, 0)
```

`decodeAt()` throws on malformed/truncated records, so use it for data you already trust.

Current decoded shapes include:

```lua
{Kind = "Integer", Value = 123, Negative = false}

{
    Kind = "Normal",
    Negative = false,
    Exponent = 4,
    Mantissa = 1.234,
}

{
    Kind = "Log",
    Negative = false,
    Reciprocal = false,
    Layer = 1,
    Top = 1000,
}

{
    Kind = "Layer",
    Negative = false,
    Reciprocal = false,
    Layer = 1000,
    LayerLog10 = nil,
    LayerIsLog = false,
    Top = 5,
}
```

---

## `tryDecodeAt`

Protected decoder for untrusted data:

```lua
local ok, decoded, nextBit = NanoNum.tryDecodeAt(data, 0)

if not ok then
    warn("Invalid NanoNum buffer")
end
```

---

# Validation

```lua
local value = NanoNum.fromNumber(123)

print(NanoNum.isValid(value))
-- true
```

`isValid()` checks the record structure, rejects the reserved special form, and verifies that unused trailing padding bits are zero.

---

# Components

```lua
local value = NanoNum.fromString("1e1000")
local parts = NanoNum.components(value)

print(parts.Kind)
print(parts.Top)
```

`components()` returns the current decoded record table directly.

---

# Inspect

```lua
local info = NanoNum.inspect(
    NanoNum.fromString("1e1000")
)

print(info.Version)
print(info.Bits)
print(info.Bytes)
print(info.PaddingBits)
print(info.Data)
```

Current `inspect()` keys are capitalized:

```text
Version
Bits
Bytes
PaddingBits
Data
```

---

# Bit Length vs Byte Length

Useful bits:

```lua
local bits = NanoNum.bitLength(value)
```

Physical bytes:

```lua
local bytes = NanoNum.byteLength(value)
```

These are intentionally different.

A standalone record can use 17 useful bits while requiring a 3-byte physical Roblox buffer.

---

# Packing Multiple NanoNums

Standalone buffers end on whole-byte boundaries. `packMany()` removes per-record padding by placing useful bits directly beside each other.

```lua
local values = {
    NanoNum.fromNumber(1),
    NanoNum.fromNumber(1000),
    NanoNum.fromString("1e1000"),
    NanoNum.fromString("1e-1000"),
}

local packed, totalBits = NanoNum.packMany(values)

print(buffer.len(packed))
print(totalBits)
```

Only the final shared buffer needs unavoidable byte padding.

---

# Unpacking

```lua
local unpacked = NanoNum.unpackMany(
    packed,
    #values,
    totalBits
)
```

Passing `totalBits` is recommended when you persisted the exact useful stream length.

---

# Safe Batch Unpacking

```lua
local ok, values = NanoNum.tryUnpackMany(
    packed,
    4,
    totalBits
)

if not ok then
    warn("Invalid packed NanoNum stream")
end
```

---

# Leaderboard Codec — LB V1

NanoNum includes a monotonic signed-integer codec intended for Roblox `OrderedDataStore` ranking.

```lua
NanoNum.LB_VERSION
-- 1
```

The key stays inside the IEEE-754 exact integer envelope:

```lua
NanoNum.LB_MAX
-- 9007199254740991
```

Central positive anchor:

```lua
NanoNum.LB_ONE
-- 4503599627370496
```

LB is intentionally separate from NanoNum's bit-packed buffer serialization:

```text
NanoNum buffer codec
    -> minimize storage / preserve NanoNum representation

LB codec
    -> monotonic sortable 53-bit-safe ranking key
```

## Important: LB V1 is quantized

LB V1 preserves ordering/buckets; it is not a lossless serializer for every NanoNum.

`lbdecode()` returns the representative NanoNum for the encoded leaderboard bucket.

Use the regular NanoNum buffer/packing codec when you need the actual NanoNum representation persisted.

## LB Encode / Decode

```lua
local original = NanoNum.fromString("1e1000")

local code = NanoNum.lbencode(original)
local restored = NanoNum.lbdecode(code)

print("Before:", NanoNum.format(original))
print("LB Code:", code)
print("Bucket:", NanoNum.format(restored))
print("Stable key:", NanoNum.lbRoundTripStable(original))
```

`lbRoundTripStable()` means:

```text
encode(value)
==
encode(decode(encode(value)))
```

It does **not** mean every original NanoNum bit pattern is recovered exactly.

Numbers, strings, and NanoNum buffers are accepted:

```lua
NanoNum.lbencode(1000)
NanoNum.lbencode("1e1000")
NanoNum.lbencode(NanoNum.fromString("1e1000"))
```

Protected input handling:

```lua
local ok, code = NanoNum.tryLBEncode(value)

if ok then
    local rankedValue = NanoNum.lbdecode(code)
end
```

Validate an existing code:

```lua
NanoNum.isLBCode(code)
```

## LB Bands

The codec maps values through monotonic regions for:

```text
ordinary exact-ish range
ordinary logarithmic range
huge logarithmic range
low direct layers
high direct layers
log-layer values
```

Sign and reciprocal ordering are arranged symmetrically around `LB_ONE`.

Inspect the selected band:

```lua
local info = NanoNum.lbinfo(value)

print(info.version)
print(info.code)
print(info.band)
print(info.negative)
print(info.reciprocal)
print(info.distanceFromOne)
```

## LB Pack / Unpack

Persist the codec version with the key:

```lua
local packed = NanoNum.lbpack(value)

print(packed.v)
-- 1

print(packed.c)
```

Decode later:

```lua
local restored = NanoNum.lbunpack(packed)
```

Accepted packet shapes are:

```lua
{v = 1, c = code}
```

and the legacy-key naming form:

```lua
{version = 1, code = code}
```

An unknown explicit codec version decodes to NaN rather than silently being treated as another mapping.

## LB Helpers

```lua
NanoNum.isLBCode(code)
NanoNum.lbcodecVersion()
NanoNum.lbinfo(value)
NanoNum.lbquantize(value)
NanoNum.lbSameBucket(a, b)
NanoNum.lbRoundTripStable(value)
NanoNum.lbCompare(a, b)
```

Compatibility aliases:

```lua
NanoNum.lbencodeV1
NanoNum.lbdecodeV1
NanoNum.LBEncode
NanoNum.LBDecode
NanoNum.LBEncodeV1
NanoNum.LBDecodeV1
NanoNum.LBCompare
NanoNum.LBRoundTripStable
```

---

# Math V8

NanoNum V0.5.0 includes the restored full math layer plus a **Math V8 safety boundary**.

Main math inputs use:

```text
number
buffer
string
```

Example:

```lua
local a = NanoNum.add(100, "1e1000")
local b = NanoNum.mul(a, NanoNum.fromNumber(2))
local c = NanoNum.div(b, "1e10")
```

Successful arithmetic functions return NanoNum buffers, except comparison, predicate, sign, and other APIs that intentionally return Lua numbers/booleans.

## Math Safety V1

Normal public math calls validate malformed buffer inputs before reaching direct bit readers.

For unknown/untrusted runtime values, use:

```lua
local okValue, compiled = NanoNum.tryCompile(value)

local okMath, result = NanoNum.tryMath("add", a, b)

local okCompare, comparison = NanoNum.tryCompare(a, b)
```

`NanoNum.fast` remains the intentionally trusted hot-path layer. It assumes its typed inputs are structurally valid and avoids the normal flexible dispatch/safety work.

```text
normal API -> typed + validated public boundary
try* API   -> unknown/untrusted inputs
fast API   -> trusted hot paths
```

---

# Core Arithmetic

```lua
NanoNum.add(a, b)
NanoNum.sub(a, b)
NanoNum.mul(a, b)
NanoNum.div(a, b)
NanoNum.pow(a, b)
NanoNum.compare(a, b)
```

Comparison result:

```text
-1 -> a < b
 0 -> a == b
 1 -> a > b
NaN -> invalid comparison
```

Convenience comparisons:

```lua
NanoNum.eq(a, b)
NanoNum.lt(a, b)
NanoNum.lte(a, b)
NanoNum.gt(a, b)
NanoNum.gte(a, b)
```

---

# Direct Typed Math — `NanoNum.fast`

The direct-call layer avoids the two flexible `typeof` checks performed by the normal binary dispatcher.

Supported operations:

```text
add
sub
mul
div
compare
pow
```

Type codes:

```text
N = number
B = buffer
S = string
```

Examples:

```lua
NanoNum.fast.addNN(10, 20)
NanoNum.fast.addBB(a, b)
NanoNum.fast.mulBN(bufferValue, 10)
NanoNum.fast.divNB(100, bufferValue)
NanoNum.fast.powSS("1e10", "2")
```

Available pair families for each direct binary operation:

```text
NN
BB
BN
NB
SS
SB
BS
SN
NS
```

If you already know the operand types in a hot path, use the direct function rather than the flexible dispatcher.

---

# Binding Hot Paths

## `bindBinary`

Resolve a direct typed function once:

```lua
local addBuffers = NanoNum.bindBinary(
    "add",
    "buffer",
    "buffer"
)

local result = addBuffers(a, b)
```

Short type codes also work:

```lua
local mulBN = NanoNum.bindBinary("mul", "B", "N")
```

Supported operation names:

```text
add
sub
mul
div
compare
pow
```

---

## `bindRight`

Bind a constant right operand:

```lua
local multiplyBy10 = NanoNum.bindRight("mul", 10)

local result = multiplyBy10(value)
```

You can also lock the left operand type:

```lua
local addTax = NanoNum.bindRight(
    "mul",
    1.07,
    "buffer"
)
```

String constants are compiled to buffers once when the binding is created.

---

# Math Performance Metadata

```lua
print(NanoNum.MATH_VERSION)
-- 7

print(NanoNum.MATH_PERF_VERSION)
-- 2

print(NanoNum.MATH_PATH_VERSION)
-- 3

print(NanoNum.MATH_DEFAULT_PATH)
-- 0
```

Runtime info:

```lua
print(NanoNum.mathPerfInfo())
print(NanoNum.callPerfInfo())
```

Current path intent:

```text
Math Path 0 -> canonical buffer / native-number fast path
Math Path 1 -> mixed, symbolic, special, or deep-layer fallback
```

The current `mathPerfInfo()` reports zero temporary decode tables on Path 0.

---

# Unary / Conversion Math

```lua
NanoNum.sign(value)          -- Lua number: -1 / 0 / 1
NanoNum.neg(value)
NanoNum.abs(value)
NanoNum.reciprocal(value)
NanoNum.toNumber(value)      -- native number when representable
NanoNum.copySign(value, signSource)
```

Classification:

```lua
NanoNum.isNaN(value)
NanoNum.isInfinite(value)
NanoNum.isFinite(value)
NanoNum.isZero(value)
NanoNum.isInteger(value)
NanoNum.isPositive(value)
NanoNum.isNegative(value)
NanoNum.isOdd(value)
NanoNum.isEven(value)
```

---

# Logs, Exponentials, Powers, and Roots

```lua
NanoNum.log10(value)
NanoNum.log2(value)
NanoNum.ln(value)
NanoNum.log(value, base?)

NanoNum.pow10(value)
NanoNum.exp(value)
NanoNum.exp2(value)
NanoNum.expm1(value)
NanoNum.log1p(value)

NanoNum.sqrt(value)
NanoNum.cbrt(value)
NanoNum.root(value, degree)
NanoNum.square(value)
NanoNum.cube(value)
NanoNum.powInt(base, exponent)
```

Example:

```lua
local huge = NanoNum.pow10(1000)
local lg = NanoNum.log10(huge)

print(NanoNum.format(lg))
-- 1k
```

---

# Rounding and Integer Helpers

```lua
NanoNum.floor(value)
NanoNum.ceil(value)
NanoNum.trunc(value)
NanoNum.round(value, decimals?)
NanoNum.frac(value)
NanoNum.mod(a, b)
NanoNum.fmod(a, b)
NanoNum.divmod(a, b)
```

`mod` is restricted to exact safe-integer-compatible inputs. Invalid/non-exact cases return NaN rather than pretending the result is exact.

---

# Min / Max / Clamp / Distance

```lua
NanoNum.min(a, b)
NanoNum.max(a, b)
NanoNum.clamp(value, low, high)
NanoNum.clamp01(value)
NanoNum.distance(a, b)
NanoNum.relativeDifference(a, b)
NanoNum.approxEq(a, b, relativeTolerance?, absoluteTolerance?)
```

Default relative tolerance for `approxEq()` is `1e-9`.

---

# Interpolation

```lua
NanoNum.lerp(a, b, t)
NanoNum.inverseLerp(a, b, value)
NanoNum.remap(value, inMin, inMax, outMin, outMax)
NanoNum.smoothstep(edge0, edge1, value)
NanoNum.smootherstep(edge0, edge1, value)
NanoNum.moveTowards(current, target, maxDelta)
```

---

# Aggregates and Means

```lua
NanoNum.sum(values)
NanoNum.product(values)
NanoNum.mean(values)
NanoNum.geometricMean(values)
NanoNum.harmonicMean(values)
NanoNum.hypot(a, b)
```

---

# Integer / Combinatoric Helpers

```lua
NanoNum.gcd(a, b)
NanoNum.lcm(a, b)
NanoNum.factorial(value)
NanoNum.permutation(n, r)
NanoNum.combination(n, r)
```

Real-valued factorial is separate:

```lua
NanoNum.factorialReal(value)
```

---

# Series and Growth Helpers

```lua
NanoNum.arithmeticSeries(first, difference, count)
NanoNum.geometricSeries(first, ratio, count)
NanoNum.compound(principal, rate, periods)
NanoNum.ratio(a, b)
NanoNum.orderOfMagnitude(value)
NanoNum.digitCount(value)
```

---

# Softcaps / Diminishing Returns

```lua
NanoNum.softcap(value, start, power)
NanoNum.inverseSoftcap(value, start, power)
NanoNum.diminishingReturns(value, scale)
NanoNum.inverseDiminishingReturns(value, scale)
NanoNum.sigmoid(value)
NanoNum.logit(value)
```

These are useful for simulator progression curves and stat scaling.

---

# Simulator Economy Helpers

NanoNum includes geometric-price helpers for upgrade systems.

## Total cost of buying levels

```lua
local cost = NanoNum.geometricCost(
    baseCost,
    growth,
    owned,
    amount
)
```

Formula is the standard geometric sum based on the current owned level.

## Maximum affordable amount

```lua
local amount = NanoNum.maxAffordableGeometric(
    currency,
    baseCost,
    growth,
    owned
)
```

## Bulk buy

```lua
local amount, cost, remaining = NanoNum.bulkBuyGeometric(
    currency,
    baseCost,
    growth,
    owned
)
```

## Next level cost

```lua
local nextCost = NanoNum.nextGeometricCost(
    baseCost,
    growth,
    owned
)
```

These helpers reject invalid negative inputs and growth factors below `1` with a NaN result.

---

# Iterated Exponentials and Logs

```lua
NanoNum.iteratedExp10(value, times)
NanoNum.iteratedLog10(value, times)
```

These are building blocks for layered-number operations.

---

# Tetration V3

NanoNum provides base-10 and general-base tetration helpers.

## Base-10 tetration

```lua
NanoNum.tetrate10(height, payload?)
NanoNum.tetrate10Integer(height, payload?)
```

Examples:

```lua
local a = NanoNum.tetrate10(3)
local b = NanoNum.tetrate10(2.5)
local c = NanoNum.tetrate10(3, 2)
```

The base-10 implementation has a direct symbolic layered path and supports fractional heights under NanoNum's current interpolation rule.

With no payload, the standard base-10 path accepts heights down to `-1`; values below `-1` return NaN.

## General-base tetration

```lua
NanoNum.tetrate(base, height, payload?)
NanoNum.tetrateInteger(base, height, payload?)
```

Example:

```lua
local value = NanoNum.tetrate(2, 4)
```

General-base fractional tetration uses the module's interpolation rule. Analytic tetration is not unique, so do not assume this interpolation is identical to another huge-number library's definition.

The current non-base-10 iterative path limits whole iteration counts above 256 and returns NaN rather than running an unbounded loop.

Version metadata:

```lua
NanoNum.TETRATION_VERSION
-- 3

NanoNum.DECIMAL_TETRATION_VERSION
-- 1
```

---

# Super-Logarithm

Base-10:

```lua
NanoNum.slog10(value)
```

General base:

```lua
NanoNum.slog(value, base?)
```

The default base is `10`.

Examples:

```lua
local x = NanoNum.tetrate10(4)
local h = NanoNum.slog10(x)
```

For non-base-10 `slog`, the base must be greater than `1` and the value must be non-negative.

```lua
NanoNum.SLOG_VERSION
-- 2
```

---

# Gamma / Beta Functions

NanoNum Math V8 includes gamma-family helpers.

```lua
NanoNum.gammaSign(value)   -- Lua number sign
NanoNum.logGamma(value)
NanoNum.gamma(value)
NanoNum.factorialReal(value)

NanoNum.betaSign(a, b)     -- Lua number sign
NanoNum.logBeta(a, b)
NanoNum.beta(a, b)
```

`factorialReal(x)` is based on gamma continuation rather than the exact-integer-only factorial path.

```lua
NanoNum.GAMMA_VERSION
-- 2
```

---

# Public API Reference

V0.5.0's exported module surface is fully typed by **Typecheck V2**.

## Exported Value Types

```lua
type MathValue = number | string | buffer
```

Useful exported structural types include:

```text
DecodedValue
DecodedInteger
DecodedNormal
DecodedLog
DecodedLayer
DecodedInfinity
DecodedNaN
DecodedReserved
InspectInfo
LBPacket
LBPacketInput
LBInfo
MathPerfInfo
CallPerfInfo
FastMath
NanoNumCore
NanoNumFormatting
NanoNumPacking
NanoNumLeaderboard
NanoNumMath
NanoNumAliases
NanoNumMetadata
NanoNumModule
```

## Suffix / Formatting Configuration

```lua
NanoNum.isSuffixType(suffixType)
NanoNum.setDefaultSuffixType(suffixType)
NanoNum.getSuffix(index, suffixType?)
NanoNum.suffixIndex(suffix, suffixType?)
```

## Construction

```lua
NanoNum.fromNumber(value)
NanoNum.fromLog10(exponent, negative?)
NanoNum.fromLayer(layer, top, negative?, reciprocal?)
NanoNum.fromLayerLog10(layerLog10, top, negative?, reciprocal?)
NanoNum.fromString(value, suffixType?)
NanoNum.compile(value)
NanoNum.tryCompile(value)
NanoNum.isMathValue(value)
```

## Decode / Validation / Inspection

```lua
NanoNum.decodeAt(data, bitOffset)
NanoNum.tryDecodeAt(data, bitOffset?)
NanoNum.isValid(value)
NanoNum.components(value)
NanoNum.bitLength(value)
NanoNum.byteLength(value)
NanoNum.inspect(value)
NanoNum.toNumberSafe(value)
```

## Number Formatting

```lua
NanoNum.format(value, precision?, suffixType?)
NanoNum.formatStandard(value, precision?)
NanoNum.formatExtended(value, precision?)
NanoNum.formatExponent(value, precision?)
NanoNum.formatHybrid(value, precision?)
NanoNum.formatAlphabetic(value, precision?)
NanoNum.formatMetric(value, precision?)
NanoNum.formatScientific(value, precision?)
NanoNum.formatEngineering(value, precision?)
NanoNum.formatRoman(value, precision?)
NanoNum.formatRomanExtended(value, precision?)
```

## Time / Utility Formatting

```lua
NanoNum.formatTime(value, style?, precision?, maxParts?)
NanoNum.formatDuration(value, style?, precision?, maxParts?)
NanoNum.formatClock(value, precision?)

NanoNum.parseTime(text)
NanoNum.fromTime(text)
NanoNum.parseDuration(text)

NanoNum.formatRate(value, unit?, precision?, suffixType?)
NanoNum.formatBytes(value, precision?, binary?)
NanoNum.formatOrdinal(value)
NanoNum.formatSigned(value, precision?, suffixType?)
```

## Packing

```lua
NanoNum.packMany(values)
NanoNum.unpackMany(packed, count, totalBits?)
NanoNum.tryUnpackMany(packed, count, totalBits?)
```

## Leaderboard

```lua
NanoNum.isLBCode(code)
NanoNum.tryLBEncode(value)
NanoNum.lbencode(value)
NanoNum.lbencodeV1(value)
NanoNum.lbdecode(code, version?)
NanoNum.lbdecodeV1(code, version?)
NanoNum.lbcodecVersion()
NanoNum.lbpack(value)
NanoNum.lbunpack(data)
NanoNum.lbinfo(value)
NanoNum.lbquantize(value)
NanoNum.lbSameBucket(a, b)
NanoNum.lbRoundTripStable(value)
NanoNum.lbCompare(a, b)
```

## Core Math

```lua
NanoNum.add(a, b)
NanoNum.sub(a, b)
NanoNum.mul(a, b)
NanoNum.div(a, b)
NanoNum.pow(a, b)
NanoNum.compare(a, b)

NanoNum.eq(a, b)
NanoNum.lt(a, b)
NanoNum.lte(a, b)
NanoNum.gt(a, b)
NanoNum.gte(a, b)

NanoNum.tryMath(operation, a, b)
NanoNum.tryCompare(a, b)
```

## Unary / Classification

```lua
NanoNum.sign(value)
NanoNum.neg(value)
NanoNum.abs(value)
NanoNum.reciprocal(value)
NanoNum.toNumber(value)
NanoNum.copySign(value, signSource)

NanoNum.isNaN(value)
NanoNum.isInfinite(value)
NanoNum.isFinite(value)
NanoNum.isZero(value)
NanoNum.isInteger(value)
NanoNum.isPositive(value)
NanoNum.isNegative(value)
NanoNum.isOdd(value)
NanoNum.isEven(value)
```

## Log / Exp / Root

```lua
NanoNum.log10(value)
NanoNum.log2(value)
NanoNum.ln(value)
NanoNum.log(value, base?)
NanoNum.log1p(value)

NanoNum.pow10(value)
NanoNum.exp(value)
NanoNum.exp2(value)
NanoNum.expm1(value)

NanoNum.sqrt(value)
NanoNum.cbrt(value)
NanoNum.root(value, degree)
NanoNum.square(value)
NanoNum.cube(value)
NanoNum.powInt(base, exponent)
```

## Rounding / Integer

```lua
NanoNum.floor(value)
NanoNum.ceil(value)
NanoNum.trunc(value)
NanoNum.round(value, decimals?)
NanoNum.frac(value)

NanoNum.mod(a, b)
NanoNum.fmod(a, b)
NanoNum.divmod(a, b)

NanoNum.gcd(a, b)
NanoNum.lcm(a, b)
```

## Range / Comparison Helpers

```lua
NanoNum.min(a, b)
NanoNum.max(a, b)
NanoNum.clamp(value, low, high)
NanoNum.clamp01(value)
NanoNum.distance(a, b)
NanoNum.relativeDifference(a, b)
NanoNum.approxEq(a, b, relativeTolerance?, absoluteTolerance?)
```

## Interpolation

```lua
NanoNum.lerp(a, b, t)
NanoNum.inverseLerp(a, b, value)
NanoNum.remap(value, inMin, inMax, outMin, outMax)
NanoNum.smoothstep(edge0, edge1, value)
NanoNum.smootherstep(edge0, edge1, value)
NanoNum.moveTowards(current, target, maxDelta)
```

## Aggregate / Statistics

```lua
NanoNum.sum(values)
NanoNum.product(values)
NanoNum.mean(values)
NanoNum.geometricMean(values)
NanoNum.harmonicMean(values)
NanoNum.hypot(a, b)
```

## Combinatorics / Series

```lua
NanoNum.factorial(value)
NanoNum.factorialReal(value)
NanoNum.permutation(n, r)
NanoNum.combination(n, r)
NanoNum.arithmeticSeries(first, difference, count)
NanoNum.geometricSeries(first, ratio, count)
NanoNum.compound(principal, rate, periods)
NanoNum.ratio(a, b)
NanoNum.orderOfMagnitude(value)
NanoNum.digitCount(value)
```

## Progression Curves

```lua
NanoNum.softcap(value, start, power)
NanoNum.inverseSoftcap(value, start, power)
NanoNum.diminishingReturns(value, scale)
NanoNum.inverseDiminishingReturns(value, scale)
NanoNum.sigmoid(value)
NanoNum.logit(value)
```

## Simulator Economy

```lua
NanoNum.geometricCost(baseCost, growth, owned, amount)
NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned?)
NanoNum.bulkBuyGeometric(currency, baseCost, growth, owned?)
NanoNum.nextGeometricCost(baseCost, growth, owned)
```

## Iteration / Tetration / Slog

```lua
NanoNum.iteratedExp10(value, times)
NanoNum.iteratedLog10(value, times)

NanoNum.tetrate10(height, payload?)
NanoNum.tetrate(base, height, payload?)
NanoNum.tetrateInteger(base, height, payload?)
NanoNum.tetrate10Integer(height, payload?)

NanoNum.slog10(value)
NanoNum.slog(value, base?)
```

## Gamma / Beta

```lua
NanoNum.gammaSign(value)
NanoNum.logGamma(value)
NanoNum.gamma(value)
NanoNum.factorialReal(value)

NanoNum.betaSign(a, b)
NanoNum.logBeta(a, b)
NanoNum.beta(a, b)
```

## Direct Calls / Binding / Perf

```lua
NanoNum.fast

NanoNum.bindBinary(operation, leftType, rightType)
NanoNum.bindRight(operation, constant, leftType?)

NanoNum.mathPerfInfo()
NanoNum.callPerfInfo()
```

`NanoNum.fast` contains 54 typed direct functions: 9 operand-pair variants for each of `add`, `sub`, `mul`, `div`, `pow`, and `compare`.

## Compatibility Aliases

Important aliases include:

```text
formatDuration -> formatTime
fromTime -> parseTime
parseDuration -> parseTime

subtract -> sub
multiply -> mul
divide -> div
power -> pow
equal -> eq

modulo -> mod
remainder -> fmod
average -> mean
choose / nCr -> combination
nPr -> permutation
nthRoot -> root
almostEqual -> approxEq

tetr -> tetrate
superLog -> slog
inverse -> reciprocal
negative -> neg
```

---

# Version Metadata

```lua
print(NanoNum.VERSION)
-- 0.5.0

print(NanoNum.TYPECHECK_VERSION)
-- 2

print(NanoNum.PARSER_VERSION)
-- 5

print(NanoNum.SUFFIX_VERSION)
-- 3

print(NanoNum.ROMAN_VERSION)
-- 1

print(NanoNum.TIME_VERSION)
-- 1

print(NanoNum.UTILITY_FORMAT_VERSION)
-- 1

print(NanoNum.PERF_VERSION)
-- 5

print(NanoNum.PATH_VERSION)
-- 1

print(NanoNum.NOTATION_VERSION)
-- 4

print(NanoNum.REGISTER_SCOPE_VERSION)
-- 1

print(NanoNum.FORMAT_SCOPE_VERSION)
-- 1

print(NanoNum.UTILITY_SCOPE_VERSION)
-- 1

print(NanoNum.PACK_SCOPE_VERSION)
-- 1

print(NanoNum.LB_SCOPE_VERSION)
-- 1

print(NanoNum.LB_VERSION)
-- 1

print(NanoNum.MATH_SCOPE_VERSION)
-- 1

print(NanoNum.MATH_VERSION)
-- 8

print(NanoNum.MATH_CORRECTNESS_VERSION)
-- 3

print(NanoNum.MATH_SAFETY_VERSION)
-- 1

print(NanoNum.MATH_PERF_VERSION)
-- 2

print(NanoNum.MATH_PATH_VERSION)
-- 3

print(NanoNum.TETRATION_VERSION)
-- 3

print(NanoNum.DECIMAL_TETRATION_VERSION)
-- 1

print(NanoNum.SLOG_VERSION)
-- 2

print(NanoNum.GAMMA_VERSION)
-- 2
```

Subsystem versions are deliberately independent. A notation change does not automatically imply a wire-format, leaderboard, or math-version migration.

---

# Current Constants

Important public constants and metadata include:

```lua
NanoNum.VERSION
NanoNum.TYPECHECK_VERSION

NanoNum.MAX_LAYER
NanoNum.MAX_LAYER_LOG10

NanoNum.NORMAL_SIGNIFICAND_BITS
NanoNum.SCALAR_SIGNIFICAND_BITS

NanoNum.PARSER_VERSION
NanoNum.NOTATION_VERSION
NanoNum.SUFFIX_VERSION
NanoNum.ROMAN_VERSION
NanoNum.TIME_VERSION
NanoNum.UTILITY_FORMAT_VERSION

NanoNum.PERF_VERSION
NanoNum.PATH_VERSION
NanoNum.DEFAULT_PATH

NanoNum.DEFAULT_SUFFIX_TYPE
NanoNum.E_NOTATION_START
NanoNum.STANDARD_SUFFIX_MAX_INDEX
NanoNum.METRIC_SUFFIX_MAX_INDEX
NanoNum.SUFFIX_TYPES

NanoNum.ROMAN_CLASSICAL_MAX
NanoNum.ROMAN_EXTENDED_MAX

NanoNum.REGISTER_SCOPE_VERSION
NanoNum.FORMAT_SCOPE_VERSION
NanoNum.UTILITY_SCOPE_VERSION
NanoNum.PACK_SCOPE_VERSION

NanoNum.LB_SCOPE_VERSION
NanoNum.LB_VERSION
NanoNum.LB_MAX
NanoNum.LB_FINITE_MAX
NanoNum.LB_ONE
NanoNum.LB_POSITIVE_SPAN

NanoNum.LB_ORDINARY_EXACT_MAX
NanoNum.LB_ORDINARY_SUBSLOTS
NanoNum.LB_ORDINARY_LOG_SHARE
NanoNum.LB_HUGE_LOG_SHARE
NanoNum.LB_LOW_LAYER_MAX
NanoNum.LB_LAYER_TOP_BUCKETS
NanoNum.LB_HIGH_LAYER_SHARE

NanoNum.MATH_SCOPE_VERSION
NanoNum.MATH_VERSION
NanoNum.MATH_CORRECTNESS_VERSION
NanoNum.MATH_SAFETY_VERSION
NanoNum.MATH_PERF_VERSION
NanoNum.MATH_PATH_VERSION
NanoNum.MATH_DEFAULT_PATH

NanoNum.CALL_VERSION
NanoNum.DIRECT_CALL_VERSION
NanoNum.BIND_VERSION
NanoNum.COMPILE_VERSION

NanoNum.TETRATION_VERSION
NanoNum.DECIMAL_TETRATION_VERSION
NanoNum.SLOG_VERSION
NanoNum.GAMMA_VERSION
```

The compact coordinate `UCe` extension used by E/L rendering is intentionally private; `STANDARD_SUFFIX_MAX_INDEX` remains `101`.

---

# Precision

NanoNum prioritizes compact representation and speed, so several fields are intentionally quantized.

Current significant fields:

```lua
NanoNum.NORMAL_SIGNIFICAND_BITS
-- 16

NanoNum.SCALAR_SIGNIFICAND_BITS
-- 14
```

Treat NanoNum as a:

- huge-number game math system
- compact serialization system
- display/notation system
- simulator/clicker currency representation
- leaderboard ranking system
- layered symbolic math system

Do **not** treat it as a lossless arbitrary-precision decimal or arbitrary-precision integer package.

---

# Exact Integer Notes

NanoNum can preserve many integers exactly when the integer record is selected. The current `fromNumber()` encoder has a dedicated exact-integer hot path through magnitude `2,097,151`; larger finite integers normally fall through to the compact normal/log selection logic.

Luau numbers themselves are IEEE-754 doubles, so the absolute exact consecutive-integer envelope still ends at:

```text
2^53 - 1
= 9,007,199,254,740,991
```

NanoNum may intentionally choose a smaller logarithmic representation instead of a larger exact integer record for some values such as exact powers of ten.

If bit-for-bit exact preservation of every large integer is your primary requirement, use a dedicated exact integer format.

---

# Layer Precision Notes

Direct layer counts are passed as Luau numbers, so integer layer counts above `2^53 - 1` cannot represent every adjacent integer exactly.

For astronomical layer heights, use:

```lua
NanoNum.fromLayerLog10(...)
```

This stores the logarithm of the layer height rather than pretending the enormous rank is an exact native integer.

---

# Math Accuracy Notes

The math system operates on NanoNum's compact representation. Results can therefore inherit quantization from normal/scalar fields.

Some operations also use symbolic/logarithmic approximations when exact native evaluation is impossible or would overflow.

Important consequences:

- equality of two independently computed approximate huge values may not imply mathematical identity
- decimal tetration follows NanoNum's interpolation rule
- LB round trips are quantized ranking round trips
- `toNumber()` can overflow/underflow when a NanoNum cannot fit in a native double
- gamma/beta and advanced functions are numerical/symbolic game-math helpers, not arbitrary-precision scientific-computing replacements

Use `approxEq()` where tolerance-based comparison is appropriate.

---

# Buffer Safety

Trusted hot paths:

```lua
NanoNum.decodeAt(...)
NanoNum.unpackMany(...)
```

Untrusted, persisted, or externally supplied data:

```lua
NanoNum.tryDecodeAt(...)
NanoNum.tryUnpackMany(...)
NanoNum.isValid(...)
```

---

# Recommended Save Pattern

For one NanoNum:

```lua
local value = NanoNum.fromString("1e1000")

-- Save the buffer through your own persistence encoding layer.
```

For many NanoNums:

```lua
local packed, usefulBits = NanoNum.packMany(values)

local saveData = {
    Buffer = packed,
    Bits = usefulBits,
    Count = #values,
}
```

For leaderboard ranking:

```lua
local leaderboardData = NanoNum.lbpack(value)

-- leaderboardData.v = codec version
-- leaderboardData.c = sortable code
```

---

# Example: Simulator Currency

```lua
local NanoNum = require(path.To.NanoNum)

local coins = NanoNum.fromString("1e1000")

coins = NanoNum.mul(coins, 25)
coins = NanoNum.add(coins, "1e999")

print("Coins:", NanoNum.format(coins))
```

---

# Example: Geometric Upgrade Buy

```lua
local currency = NanoNum.fromString("1e50")
local baseCost = NanoNum.fromNumber(100)
local growth = 1.15
local owned = 250

local amount, cost, remaining = NanoNum.bulkBuyGeometric(
    currency,
    baseCost,
    growth,
    owned
)

print("Buy:", NanoNum.format(amount))
print("Cost:", NanoNum.format(cost))
print("Left:", NanoNum.format(remaining))
```

---

# Example: Compile a Hot-Loop Constant

Avoid reparsing the same string:

```lua
local multiplier = NanoNum.compile("1e100")

for _ = 1, 1000 do
    value = NanoNum.mul(value, multiplier)
end
```

For an even tighter known-type loop:

```lua
local mulBB = NanoNum.fast.mulBB

for _ = 1, 1000 do
    value = mulBB(value, multiplier)
end
```

---

# Example: Bind a Constant

```lua
local multiplyBy125 = NanoNum.bindRight(
    "mul",
    1.25,
    "buffer"
)

value = multiplyBy125(value)
```

---

# Example: Packed Player Data

```lua
local values = {
    NanoNum.fromString("1250"),
    NanoNum.fromString("1e1000"),
    NanoNum.fromString("1e-1000"),
}

local packed, bits = NanoNum.packMany(values)

print("Physical bytes:", buffer.len(packed))
print("Useful bits:", bits)

local restored = NanoNum.unpackMany(
    packed,
    #values,
    bits
)

for _, value in restored do
    print(NanoNum.format(value))
end
```

---

# Example: OrderedDataStore Code

```lua
local score = NanoNum.fromString("1e1000")
local ok, code = NanoNum.tryLBEncode(score)

if ok then
    print("Leaderboard code:", code)
end
```

Restore:

```lua
local restored = NanoNum.lbdecode(code)
print(NanoNum.format(restored))
```

---

# Register Scope V1

V0.5.0 fixes the Luau compile failure:

```text
Out of local registers when trying to allocate lbDecodePositiveDelta:
exceeded limit 200
```

The issue was not that `lbDecodePositiveDelta()` itself had 200 locals. V0.5.4 had accumulated too many direct locals in the module chunk, so Luau exhausted the outer function register frame while declaring later helpers.

V0.5.0 moves register-heavy subsystems into real function frames using immediately invoked functions:

```lua
(function()
    -- subsystem locals/helpers
end)()
```

A plain:

```lua
do
    -- ...
end
```

is not enough for this purpose because it still uses the same Luau function register frame.

Static register-budget audit:

| Scope | Direct locals |
|---|---:|
| Main module chunk | **124** |
| Formatter | 16 |
| Utility formatting | 5 |
| Packing | 4 |
| Leaderboard | 59 |
| Math core engine frame | 90 |
| Math V8 safety | 24 |

V0.5.4's module chunk was approximately:

```text
203 direct top-level locals
```

V0.5.0 reduces it to:

```text
124 direct top-level locals
```

The conservative static scan reports the largest individual function, `fromString`, at approximately 99 lexical locals + parameters.

Current scope metadata:

```lua
NanoNum.REGISTER_SCOPE_VERSION
NanoNum.FORMAT_SCOPE_VERSION
NanoNum.UTILITY_SCOPE_VERSION
NanoNum.PACK_SCOPE_VERSION
NanoNum.LB_SCOPE_VERSION
NanoNum.MATH_SCOPE_VERSION
```

The v0.5.0 structural audit reports:

```text
35 PASS
0 FAIL
```

This is a static source/register-budget audit. Requiring the module in Roblox Studio remains the final Luau compiler/runtime verification.

---

# Performance Testing

For meaningful RTT-style microbenchmarks:

1. use the same benchmark script between versions
2. warm every function before measuring
3. subtract loop/closure baseline when appropriate
4. run multiple rounds
5. use adaptive iteration counts
6. compare identical input cases
7. benchmark the direct typed API separately from the flexible API
8. benchmark string parsing separately from precompiled buffers
9. test in the same Roblox Studio/server environment
10. keep correctness/regression tests enabled between performance changes

A faster result is useful only if the value, parser, formatting, and math regression tests still pass.

---

# Migrating an Older README

If your README still documents the V0.3.x line, the major documentation changes for V0.5.0 are:

- release metadata is now **V0.5.0**
- **Typecheck V2** covers the exported module surface
- Parser is **V5**
- public suffix system is **V3**
- public Standard suffix maximum is **101**, not 999
- Roman formatting is **V1**
- time/utility formatting is **V1**
- Notation is **V4**
- clean Standard -> E -> L formatting is restored
- compact coordinate output now includes `E100UCe`, `L2 100UCe`, and `L3 100UCe`
- `UCe` is a private coordinate extension; it does not change `getSuffix(102, "standard")`
- Math is now **V8**
- Math correctness is **V3**
- Math Safety **V1** protects the normal public math boundary
- `tryCompile`, `tryMath`, and `tryCompare` are available for unknown inputs
- Roman/time/bytes/rate/ordinal/signed formatters are documented
- leaderboard default is **LB V1**, which is a quantized monotonic ranking codec
- LB V2 reversible claims from older documentation do **not** apply to this build
- Register Scope **V1** isolates formatter, utility, packing, leaderboard, and math subsystems
- the main module register budget was reduced from roughly **203 -> 124** direct top-level local bindings
- the public wire prefix layout remains unchanged by the register-scope release

---

# Design Goals

NanoNum prioritizes:

1. **Low storage cost**
2. **Fast canonical paths**
3. **Readable Standard -> E -> L huge-number formatting**
4. **Symbolic preservation of huge/tiny values**
5. **Useful game-oriented huge-number math**
6. **Safe public boundaries for malformed/untrusted data**
7. **Stable monotonic leaderboard ordering**
8. **Hot-loop APIs with avoidable dispatch/parsing removed**
9. **Strong exported Luau typechecking**
10. **Register-safe subsystem architecture**
11. **Versioned subsystem evolution**

---

# Non-Goals

NanoNum is not intended to be:

- an exact arbitrary-precision integer library
- an exact arbitrary-precision decimal library
- a cryptographic binary format
- a mathematically unique analytic tetration implementation
- a replacement for scientific arbitrary-precision packages

Its focus is **compact huge-number storage, parsing, notation, game math, packing, and ranking**.

---

# Suggested Module Layout

```text
NanoNum/
├── NanoNum.lua
├── README.md
├── NanoNum_v0.5.0_RegisterScopeRegression.server.lua
├── NanoNum_v0.5.0_CompactCoordinateRegression.server.lua
├── NanoNum_v0.5.0_TypecheckCoverage.server.lua
├── NanoNum_FullAPIBenchmark.lua
└── NanoNum_MathBenchmark.lua
```

---

# Summary

NanoNum is built around one main idea:

> **Do not spend bits, bytes, parsing work, dispatch work, or compiler register budget on information the current value does not need.**

Small values stay small.

Huge values become logarithmic.

Astronomical values become layered.

Tiny values remain symbolic.

Multiple values can share one packed bitstream.

Standard display progresses cleanly from suffixes into `E` notation and then actual `L` layers.

Coordinates are compacted too, so values such as `10^(1e308)` display as `E100UCe` instead of `E1e+308`.

Math V8 lets the same representation participate directly in game calculations while keeping a protected normal API, safe `try*` boundaries, and 54 trusted direct `NanoNum.fast` calls.

Typecheck V2 gives the public module an explicit exported Luau surface.

Register Scope V1 keeps formatter, utility, packing, leaderboard, and math helper locals in separate function frames so the module does not hit Luau's 200-local register ceiling.

And leaderboard ranking remains independently versioned from the NanoNum buffer codec, parser, notation, and math layers.
