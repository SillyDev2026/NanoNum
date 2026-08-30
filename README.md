# NanoNum

**NanoNum** is a compact huge-number formatter, parser, serializer, and leaderboard codec for Roblox Luau.

It is designed for games that need to **store and display numbers far beyond normal `number` range** without paying the cost of a fixed 17-byte representation for every value.

NanoNum uses an **adaptive bit-packed buffer format**. Small values stay tiny, huge values switch to logarithmic forms, layered values carry only the metadata they need, and multiple values can be packed together without wasting a full byte boundary per record.

> Current release: **V0.1.0**  
> Parser: **V3**  
> Suffix codec: **V3**  
> Performance layout: **V5**  
> Path architecture: **V1 / Path 0**  
> Leaderboard codec: **LB V1**

---

## Highlights

- Adaptive Roblox `buffer` representation
- Small values can fit in **1 byte**
- Exact compact storage for many small integers
- Huge scientific values such as `1e1000`
- Tiny symbolic values such as `1e-1000`
- Direct and logarithmic layered values
- Layer height support up to the NanoNum layer envelope
- Fast byte-scanned `fromString`
- Reciprocal formatting such as `1/1k`
- Standard, Extended, Hybrid, Alphabetic, Metric, Scientific, Engineering, and Exponent notation
- Automatic compact exponent notation such as `E3,000`
- Bit-level `packMany` / `unpackMany`
- Safe decoding and structural validation
- Monotonic OrderedDataStore-friendly **LB V1**
- `--!native`
- `--!optimize 2`
- Path-0 hot-path design inspired by direct buffer-oriented number libraries

---

# Installation

Place the module in your game, then require it normally:

```lua
local NanoNum = require(path.To.NanoNum)
```

The ModuleScript can be named whatever you want. The examples in this README use `NanoNum`.

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

print(NanoNum.format(huge))
-- 1e1000

print(NanoNum.format(massive))
-- E3,000

print(NanoNum.format(tiny))
-- 1/1e1000
```

---

# Why NanoNum?

A traditional huge-number buffer often uses a fixed layout such as:

```text
sign     : 1 byte
layer    : 8 bytes
exponent : 8 bytes
-------------------
total    : 17 bytes
```

That is simple and fast, but even the number `1` still costs 17 bytes.

NanoNum instead uses several compact record classes and chooses the smallest useful representation.

Conceptually:

```text
small integer
    ↓
tiny record

ordinary integer
    ↓
integer record

ordinary decimal
    ↓
normal scientific record

1e1000
    ↓
log record

e^1000 5
    ↓
layer record
```

The buffer grows only when the value needs more metadata.

---

# Adaptive Storage

NanoNum records are bit-packed.

Standalone Roblox buffers still have whole-byte physical lengths, but NanoNum tracks the **useful bit length** separately.

Typical examples:

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

The exact representation depends on which encoding is smaller.

Use:

```lua
local value = NanoNum.fromString("1e1000")

print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))
```

---

# Representation Classes

NanoNum internally distinguishes several record types.

## Tiny

Used for zero and compact positive small integers.

```lua
NanoNum.fromNumber(0)
NanoNum.fromNumber(1)
NanoNum.fromNumber(100)
```

## Negative Small

Compact encoding for small negative integers.

```lua
NanoNum.fromNumber(-1)
NanoNum.fromNumber(-64)
```

## Integer

Used when exact integer storage is cheaper than a normal decimal record.

```lua
NanoNum.fromNumber(1250)
NanoNum.fromNumber(100000)
```

## Normal

Compact scientific-style storage for ordinary finite numbers.

```lua
NanoNum.fromNumber(12345.678)
```

## Log

Stores very large or very small layer-1 values through their base-10 logarithm.

```lua
NanoNum.fromLog10(1000)
NanoNum.fromString("1e1000")
NanoNum.fromString("1e-1000")
```

## Layer

Stores values above ordinary logarithmic range.

```lua
NanoNum.fromLayer(2, 1000)
NanoNum.fromLayer(1000, 5)
```

## Log-Layer

Stores astronomical layer heights through `log10(layerHeight)`.

```lua
NanoNum.fromLayerLog10(308, 5)
```

## Special

Used for:

- `+inf`
- `-inf`
- `NaN`
- reserved/invalid forms

---

# Number Range

NanoNum exposes:

```lua
NanoNum.MAX_LAYER
-- 1e308

NanoNum.MAX_LAYER_LOG10
-- 1e308
```

A direct layer can therefore be represented up to the direct layer envelope, while `fromLayerLog10()` can describe a layer height whose base-10 logarithm is itself as large as `1e308`.

Example:

```lua
local direct = NanoNum.fromLayer(1e308, 5)

local logHeight = NanoNum.fromLayerLog10(1e308, 5)
```

`fromLayerLog10(1e308, 5)` conceptually represents a layer height near:

```text
10^(1e308)
```

This is a formatting/storage representation, not an exact arbitrary-precision integer rank.

---

# Constructors

## `fromNumber`

```lua
local n = NanoNum.fromNumber(12345.678)
```

```lua
NanoNum.fromNumber(0)
NanoNum.fromNumber(1000)
NanoNum.fromNumber(-5)
NanoNum.fromNumber(math.huge)
```

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
	1000, -- layer
	5,    -- top
	false, -- negative
	false  -- reciprocal
)
```

Conceptually:

```text
e^1000 5
```

NanoNum canonicalizes reducible layered values where possible.

---

## `fromLayerLog10`

Use this when the layer count itself is too large to describe directly.

```lua
local value = NanoNum.fromLayerLog10(
	1e308,
	5
)
```

---

# Fast String Parsing

NanoNum's parser handles normal numbers, scientific notation, suffixes, reciprocal notation, layered notation, and compact exponent notation.

```lua
NanoNum.fromString("1250")
NanoNum.fromString("12345.678")
NanoNum.fromString("1e1000")
NanoNum.fromString("1e-1000")
NanoNum.fromString("1.25M")
NanoNum.fromString("1/1k")
NanoNum.fromString("E3,000")
NanoNum.fromString("1.25E3,006")
NanoNum.fromString("ee1000")
NanoNum.fromString("e^1000 5")
NanoNum.fromString("e^(10^1e308) 5")
```

The parser avoids converting enormous scientific strings into native infinity/zero before NanoNum gets a chance to preserve them symbolically.

For example:

```lua
local a = NanoNum.fromString("1e1000")
local b = NanoNum.fromString("1e-1000")

print(NanoNum.format(a))
print(NanoNum.format(b))
```

---

# Formatting

The main formatter is:

```lua
NanoNum.format(value, precision?, suffixType?)
```

Example:

```lua
local value = NanoNum.fromNumber(1250000)

print(NanoNum.format(value))
-- 1.25M
```

Default precision is optimized for compact display.

---

# Suffix Types

NanoNum V0.1.0 includes:

```text
standard
extended
hybrid
alphabetic
metric
exponent
scientific
engineering
```

You can change the global default:

```lua
NanoNum.setDefaultSuffixType("extended")
```

Check a type:

```lua
print(NanoNum.isSuffixType("standard"))
```

---

## Standard

Traditional incremental suffixes:

```text
1e3   -> 1k
1e6   -> 1M
1e9   -> 1B
1e12  -> 1T
...
1e303 -> 1Ce
```

At exponent `3000` and above, Standard automatically switches to compact exponent notation:

```text
1e3000 -> E3,000
```

---

## Extended

Extended starts with the Standard suffix family and then continues with generated alphabetic suffixes.

Conceptually:

```text
...
1e303  -> 1Ce
1e306  -> 1aa
1e309  -> 1ab
1e312  -> 1ac
...
1e2997 -> generated extended suffix
1e3000 -> E3,000
```

Use:

```lua
print(NanoNum.formatExtended(
	NanoNum.fromString("1e306")
))
```

---

## Hybrid

Hybrid uses Standard suffixes first, then alphabetic generation for higher suffix indices.

```lua
NanoNum.formatHybrid(value)
```

This mode is useful when you want suffixes to continue instead of switching to the Standard/Extended `E3,000` cutoff behavior.

---

## Alphabetic

Alphabetic notation starts generated suffixes immediately.

```text
1e3  -> 1aa
1e6  -> 1ab
...
```

```lua
NanoNum.formatAlphabetic(value)
```

---

## Metric

Metric-style suffixes:

```text
k
M
G
T
P
E
Z
Y
R
Q
```

Example:

```lua
print(NanoNum.formatMetric(
	NanoNum.fromNumber(1e9)
))
-- 1G
```

---

## Scientific

```lua
NanoNum.formatScientific(
	NanoNum.fromString("1e300")
)
```

Example output:

```text
1e300
```

---

## Engineering

Engineering notation keeps the exponent divisible by 3.

```lua
NanoNum.formatEngineering(
	NanoNum.fromNumber(10000)
)
```

Example:

```text
10e3
```

---

## Exponent / E Notation

NanoNum's compact exponent style is intended for very large display exponents.

```lua
NanoNum.formatExponent(
	NanoNum.fromString("1e3000")
)
```

Output:

```text
E3,000
```

Mantissas are preserved:

```text
1.25e3006
↓
1.25E3,006
```

Reciprocals are also supported:

```text
1e-3000
↓
1/E3,000
```

The Standard and Extended formatters automatically use this style starting at:

```lua
NanoNum.E_NOTATION_START
-- 3000
```

---

# Suffix Lookup

Get a suffix by index:

```lua
print(NanoNum.getSuffix(1, "standard"))
-- k

print(NanoNum.getSuffix(101, "standard"))
-- Ce
```

Find the index of a suffix:

```lua
print(NanoNum.suffixIndex("Ce", "standard"))
-- 101
```

Generated alphabetic suffixes are also supported:

```lua
NanoNum.getSuffix(1, "alphabetic")
NanoNum.suffixIndex("aa", "alphabetic")
```

---

# Reciprocal Formatting

NanoNum preserves tiny values symbolically instead of collapsing them to native zero.

Examples:

```text
1/100
1/1k
1/1M
1/1e1000
1/E3,000
```

```lua
local value = NanoNum.fromString("1e-3000")

print(NanoNum.format(value))
-- 1/E3,000
```

---

# Path-0 Performance Design

NanoNum V0.1.0 uses a **Path-0 hot-path architecture**.

The important rule is:

> Common canonical inputs should do the work directly inside the public function.

Conceptually:

```text
public function
    ↓
common input
    ↓
direct buffer work
    ↓
return
```

Only unusual values enter extra handling:

```text
public function
    ↓
special / malformed / alias / complex layer
    ↓
fallback logic
```

NanoNum does **not** maintain a runtime `path = 0` variable. Path 0 is an architectural concept, so there is no extra per-call path-tracking cost.

Metadata:

```lua
NanoNum.PATH_VERSION
-- 1

NanoNum.DEFAULT_PATH
-- 0
```

Examples of Path-0 behavior include:

- direct construction for common `fromNumber` values
- direct `fromLog10` record creation
- direct canonical formatter routes
- direct canonical suffix routes
- direct buffer-to-LB encoding
- structural validation without allocating a decoded component table

---

# Decode API

## `decodeAt`

Decode one record beginning at a bit offset.

```lua
local decoded, nextBit = NanoNum.decodeAt(data, 0)
```

This is the trusted/hot-path decoder.

---

## `tryDecodeAt`

Protected decoding for untrusted data.

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

`isValid()` performs structural validation and padding checks.

---

# Components

Inspect the logical representation:

```lua
local value = NanoNum.fromString("1e1000")

local parts = NanoNum.components(value)
print(parts)
```

The exact fields depend on the record class.

---

# Inspect

For debugging:

```lua
local info = NanoNum.inspect(
	NanoNum.fromString("1e1000")
)

print(info.bits)
print(info.bytes)
print(info.paddingBits)
print(info.decoded)
```

---

# Bit Length

Useful bits:

```lua
local bits = NanoNum.bitLength(value)
```

Physical buffer bytes:

```lua
local bytes = NanoNum.byteLength(value)
```

These are intentionally different concepts.

A value can use 17 useful bits while still occupying a 3-byte Roblox buffer.

---

# Packing Multiple NanoNums

Standalone buffers must end on whole bytes.

NanoNum can remove that internal padding by packing records consecutively into one shared bitstream.

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

The next record begins immediately after the previous record's final useful bit.

Only the final shared buffer has unavoidable byte padding.

---

# Unpacking

```lua
local unpacked = NanoNum.unpackMany(
	packed,
	#values,
	totalBits
)
```

Providing `totalBits` is recommended when the exact useful stream length is known.

---

# Safe Batch Unpacking

For untrusted or persisted streams:

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

# Leaderboard Encoding

NanoNum includes a monotonic signed integer codec intended for Roblox OrderedDataStore-style ranking.

Current codec:

```lua
NanoNum.LB_VERSION
-- 1
```

Range:

```lua
NanoNum.LB_MAX
-- 9007199254740991
```

The codec stays inside the exact integer range of an IEEE-754 double.

Important anchor:

```lua
NanoNum.LB_ONE
-- 4503599627370496
```

Conceptually:

```text
-inf  ... negative values ... -1 ... tiny negatives ... 0 ...
tiny positives ... 1 ... huge positives ... +inf
```

Numeric LB codes preserve leaderboard ordering.

---

## LB Encode

```lua
local value = NanoNum.fromString("1e1000")

local code = NanoNum.lbencode(value)
print(code)
```

You may also pass numbers and strings:

```lua
NanoNum.lbencode(1000)
NanoNum.lbencode("1e1000")
```

Buffers use the fastest path.

---

## Safe LB Encode

Use this if NaN/invalid distinction matters:

```lua
local ok, code = NanoNum.tryLBEncode(value)

if ok then
	print(code)
end
```

---

## LB Decode

```lua
local restored = NanoNum.lbdecode(code)

print(NanoNum.format(restored))
```

LB is a ranking/quantization codec. It is not intended to preserve more precision than NanoNum's representation and LB bucket layout provide.

---

## LB Pack

For persisted data, store codec version alongside the code:

```lua
local packed = NanoNum.lbpack(value)

print(packed.v)
print(packed.c)
```

Decode:

```lua
local restored = NanoNum.lbunpack(packed)
```

This makes future leaderboard codec migration easier.

---

## LB Helpers

```lua
NanoNum.lbinfo(value)

NanoNum.lbquantize(value)

NanoNum.lbSameBucket(a, b)

NanoNum.lbRoundTripStable(value)

NanoNum.lbCompare(a, b)
```

Aliases are also available:

```lua
NanoNum.LBEncode
NanoNum.LBDecode
NanoNum.LBEncodeV1
NanoNum.LBDecodeV1
NanoNum.LBCompare
NanoNum.LBRoundTripStable
```

---

# Public API Reference

## Suffix

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
```

## Decode / Validation

```lua
NanoNum.decodeAt(data, bitOffset?)
NanoNum.tryDecodeAt(data, bitOffset?)
NanoNum.isValid(value)
NanoNum.components(value)
NanoNum.bitLength(value)
NanoNum.byteLength(value)
NanoNum.inspect(value)
```

## Formatting

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
```

## Packing

```lua
NanoNum.packMany(values)
NanoNum.unpackMany(packed, count, totalBits?)
NanoNum.tryUnpackMany(packed, count, totalBits?)
```

## Leaderboard

```lua
NanoNum.tryLBEncode(value)
NanoNum.lbencode(value)
NanoNum.lbdecode(encoded, version?)

NanoNum.lbcodecVersion()

NanoNum.lbpack(value)
NanoNum.lbunpack(data)

NanoNum.lbinfo(value)
NanoNum.lbquantize(value)
NanoNum.lbSameBucket(a, b)
NanoNum.lbRoundTripStable(value)
NanoNum.lbCompare(a, b)
```

---

# Version Metadata

```lua
print(NanoNum.VERSION)
-- 0.1.0

print(NanoNum.PARSER_VERSION)
-- 3

print(NanoNum.SUFFIX_VERSION)
-- 3

print(NanoNum.PERF_VERSION)
-- 5

print(NanoNum.PATH_VERSION)
-- 1

print(NanoNum.LB_VERSION)
-- 1
```

These versions are separated intentionally.

For example, a performance rewrite does not necessarily require changing the persisted LB mapping or the compact buffer interpretation.

---

# Precision

NanoNum is compact, so some representations are intentionally quantized.

Current significant-field settings include:

```lua
NanoNum.NORMAL_SIGNIFICAND_BITS
-- 16

NanoNum.SCALAR_SIGNIFICAND_BITS
-- 14
```

This means NanoNum should be treated as a:

- huge-number display system
- compact serialization system
- leaderboard ordering system
- simulator/clicker number representation

It should **not** be treated as an exact arbitrary-precision arithmetic library.

If you need exact arbitrary-precision integer/floating-point mathematics, use a representation designed for exact math.

---

# Exact Integer Notes

NanoNum can preserve many integers exactly when the integer record is cheaper than another representation.

However, NanoNum always chooses the representation it considers most efficient.

That means the smallest encoded form can sometimes be a logarithmic or normal representation rather than the largest exact-integer representation.

If absolute exactness for every large integer is your primary goal, NanoNum's automatic compact encoding may not be the correct storage mode.

---

# Layer Precision Notes

Luau `number` uses IEEE-754 double precision.

That means direct integer layer counts above `2^53` cannot represent every adjacent integer exactly.

For astronomical layer heights, use the symbolic/log-layer APIs when appropriate:

```lua
NanoNum.fromLayerLog10(...)
```

---

# Buffer Safety

`decodeAt()` and `unpackMany()` are intended for trusted hot paths.

For untrusted, external, or corrupted input prefer:

```lua
NanoNum.tryDecodeAt(...)
NanoNum.tryUnpackMany(...)
NanoNum.isValid(...)
```

---

# Recommended Save Pattern

For one value:

```lua
local value = NanoNum.fromString("1e1000")

-- Save the buffer using your own binary/base64 persistence layer.
```

For many values:

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

print("Coins:", NanoNum.format(coins))
```

Output:

```text
Coins: 1e1000
```

Later:

```lua
coins = NanoNum.fromString("1e3000")

print("Coins:", NanoNum.format(coins))
```

Output:

```text
Coins: E3,000
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

Later:

```lua
local restored = NanoNum.lbdecode(code)

print(NanoNum.format(restored))
```

---

# Performance Testing

NanoNum releases can be tested with RTT-style microbenchmarks.

For meaningful results:

1. use the same benchmark script between versions
2. warm each function before measuring
3. subtract loop/closure baseline
4. use several rounds
5. use adaptive iteration counts
6. compare the same input cases
7. test inside the same Roblox Studio/server environment

A faster benchmark result is only useful if regression tests still pass.

---

# Design Goals

NanoNum prioritizes:

1. **Low storage cost**
2. **Fast common paths**
3. **Readable huge-number formatting**
4. **Symbolic preservation of huge/tiny values**
5. **Safe optional decoding**
6. **Stable leaderboard ordering**
7. **Backward-compatible codec evolution where possible**

---

# Non-Goals

NanoNum is not currently intended to be:

- a complete arbitrary-precision arithmetic engine
- a drop-in replacement for every layered-number library
- a lossless decimal library for every possible input
- a cryptographic binary format

Its focus is compact huge-number representation, formatting, parsing, packing, and ranking.

---

# Compatibility

V0.1.0 keeps the current major internal codec generations:

```text
Parser V3
Suffix V3
LB V1
Path V1
```

When changing persisted formats in future releases, version the codec instead of silently changing the meaning of old saved data.

For leaderboard persistence, prefer `lbpack()` / `lbunpack()` because the version travels with the code.

---

# Suggested Module Layout

```text
NanoNum/
├── NanoNum.lua
├── NanoNum_Test.lua
├── NanoNum_FullAPIBenchmark.lua
└── README.md
```

---

# Current Constants

Useful public constants include:

```lua
NanoNum.VERSION

NanoNum.MAX_LAYER
NanoNum.MAX_LAYER_LOG10

NanoNum.NORMAL_SIGNIFICAND_BITS
NanoNum.SCALAR_SIGNIFICAND_BITS

NanoNum.PARSER_VERSION
NanoNum.SUFFIX_VERSION
NanoNum.PERF_VERSION
NanoNum.PATH_VERSION

NanoNum.DEFAULT_PATH
NanoNum.DEFAULT_SUFFIX_TYPE
NanoNum.E_NOTATION_START

NanoNum.LB_VERSION
NanoNum.LB_MAX
NanoNum.LB_FINITE_MAX
NanoNum.LB_ONE
NanoNum.LB_POSITIVE_SPAN
```

---

# Summary

NanoNum is built around one main idea:

> **Do not spend bits, bytes, or CPU time on information the current number does not need.**

Small values stay small.

Huge values become logarithmic.

Astronomical values become layered.

Tiny values remain symbolic.

Formatting automatically moves through suffix, scientific, layered, and compact `E3,000` styles.

And when many values are stored together, NanoNum can remove the per-buffer padding and pack the records directly beside each other at the bit level.
