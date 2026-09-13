# NanoNum

**Huge-number math, formatting, serialization, and leaderboard utilities for Roblox Luau.**

NanoNum is designed for simulator, clicker, incremental, economy, and progression systems that need fast ordinary-number math while still supporting values far beyond the native Luau `number` range.

> **Current release:** `v2.1.9`  
> **Binary format:** `v3`  
> **Leaderboard codec:** `LB v2`  
> **Parser:** `v11`  
> **Math:** `v27`  
> **Compact kernel:** `v8`

---

## Overview

NanoNum uses multiple compact numeric representations instead of forcing every value into one fixed structure.

It keeps ordinary finite values on fast native paths, stores supported integers exactly, and promotes oversized values into logarithmic and layered representations when native Luau would overflow.

### Highlights

- Exact ordinary finite values through an IEEE-754 `f64` record
- Exact safe integers through the normal Luau safe-integer envelope
- Compact 1-byte encoding for very small integers
- Symbolic values far beyond native `number`
- Log, layer, layer-log, and hyper-layer representations
- Automatic range promotion instead of premature native infinity
- Mixed `number`, `buffer`, and `string` math inputs
- 54 typed binary hot paths under `NanoNum.fast`
- 5 typed unary buffer hot paths
- Bit-level `packMany` / `unpackMany`
- Monotonic 53-bit-safe `LB v2` ranking codec for `OrderedDataStore`
- Standard, Extended, Hybrid, Alphabetic, Metric, Exponent, Scientific, Engineering, Roman, and Roman Extended formatting
- Time, byte, rate, ordinal, and signed formatting helpers
- Logs, roots, powers, interpolation, statistics, combinatorics, economy helpers, tetration, slog, gamma, beta, and more
- Built for `--!native` and `--!optimize 2`

---

## Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Current Engine Versions](#current-engine-versions)
- [Number Model](#number-model)
- [Constructing Values](#constructing-values)
- [Core Math](#core-math)
- [Fast Typed Math](#fast-typed-math)
- [Hot-Loop Helpers](#hot-loop-helpers)
- [Validation and Inspection](#validation-and-inspection)
- [Packing and Serialization](#packing-and-serialization)
- [Formatting](#formatting)
- [Time and Utility Formatting](#time-and-utility-formatting)
- [Leaderboard Codec](#leaderboard-codec)
- [Higher Math](#higher-math)
- [Economy Helpers](#economy-helpers)
- [Tetration and Slog](#tetration-and-slog)
- [Performance Guidance](#performance-guidance)
- [Precision and Limits](#precision-and-limits)
- [Compatibility and Migration](#compatibility-and-migration)
- [Public API Reference](#public-api-reference)
- [Recommended Usage](#recommended-usage)

---

# Installation

Place `NanoNum.lua` somewhere accessible to both the server and client if both environments need it.

For example:

```text
ReplicatedStorage
└── Packages
    └── NanoNum
```

Require it normally:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NanoNum = require(ReplicatedStorage.Packages.NanoNum)
```

NanoNum values are Roblox `buffer` objects.

---

# Quick Start

```lua
local NanoNum = require(path.To.NanoNum)

local coins = NanoNum.fromNumber(12.5)
local huge = NanoNum.fromString("1e1000")
local tower = NanoNum.fromString("10^(10^1e308)")

local total = NanoNum.add(coins, 7.25)

print(NanoNum.toNumber(total))
-- 19.75

print(NanoNum.formatScientific(huge))
-- 1e1000

print(NanoNum.rangeClass(tower))
-- layer / layer-log / hyper-layer depending on magnitude
```

Flexible math accepts numbers, strings, and NanoNum buffers:

```lua
local a = NanoNum.add(12.5, 7.25)
local b = NanoNum.mul("1e1000", 10)
local c = NanoNum.div(NanoNum.fromNumber(100), 8)
```

For repeated string constants, compile once:

```lua
local gain = NanoNum.compile("1e1000")
local value = NanoNum.fromNumber(0)

for _ = 1, 1000 do
    value = NanoNum.add(value, gain)
end
```

---

# Current Engine Versions

`v2.1.9` exposes the following subsystem versions:

| Component | Version |
|---|---:|
| NanoNum | **2.1.9** |
| Typecheck | 3 |
| Binary format | **3** |
| Parser | 11 |
| Notation | 14 |
| Suffix system | 5 |
| Roman formatter | 2 |
| Time formatter | 4 |
| Utility formatter | 10 |
| Performance layout | 19 |
| Path architecture | 5 |
| Math | 27 |
| Math cleanup | 16 |
| Math correctness | 20 |
| Math safety | 10 |
| Math performance | 16 |
| Math path | 9 |
| Direct call | 12 |
| Call layer | 12 |
| Bind | 7 |
| Compile | 7 |
| Tetration | 8 |
| Slog | 6 |
| Gamma / Beta | 6 |
| Canonical representation | 4 |
| Range promotion | 2 |
| Compact kernel | **8** |
| Fast unary API | 3 |
| Hyper-layer | **1** |
| Inline math | 2 |
| Cold fallback | 1 |
| Register scope | 6 |
| Register frame | 2 |
| Leaderboard codec | **LB v2** |

Subsystem versions are independent and may advance without a major NanoNum version change.

You can inspect runtime metadata directly:

```lua
local info = NanoNum.engineInfo()

print(info.Version)
print(info.BinaryFormatVersion)
print(info.CompactKernelVersion)
print(info.HyperLayer)
print(info.HyperLayerVersion)
```

---

# Number Model

NanoNum uses the smallest practical representation for the current magnitude class.

```text
small integer
    -> compact integer record

larger safe integer
    -> exact variable-bit integer

ordinary finite fraction
    -> exact f64 record

large or tiny magnitude
    -> log record

power-tower magnitude
    -> layer record

very large layer count
    -> layer-log record

extreme layer-count magnitude
    -> hyper-layer record

NaN / +/-infinity
    -> special record
```

## Exact finite values

Ordinary non-integer finite values use an exact Luau double payload.

```lua
local value = NanoNum.fromNumber(12.5)
local info = NanoNum.inspect(value)

print(info.Data.Kind)
-- Exact

print(info.Bits)
-- 72

print(info.Bytes)
-- 9
```

The standalone exact-f64 record uses one tag byte plus the 8-byte `f64` payload.

## Safe integers

NanoNum can store supported safe integers exactly through:

```text
-9007199254740991 .. 9007199254740991
```

Very small signed integers use especially compact records.

## Symbolic huge values

Huge values are not stored as arbitrary decimal strings. NanoNum promotes them into logarithmic and layered metadata.

This keeps representation compact while allowing values that are mathematically far beyond native Luau range.

---

# Constructing Values

## `fromNumber`

```lua
local value = NanoNum.fromNumber(12345.678)
```

Use this for native finite Luau numbers.

## `fromString`

```lua
NanoNum.fromString("1250")
NanoNum.fromString("12345.678")
NanoNum.fromString("1e1000")
NanoNum.fromString("1e-1000")
NanoNum.fromString("10^(10^1e308)")
NanoNum.fromString("1.25M")
NanoNum.fromString("1/1k")
NanoNum.fromString("L3 1000")
```

Use strings when a value cannot safely exist as a native Luau intermediate.

## `fromLog10`

```lua
local huge = NanoNum.fromLog10(1000)
local tiny = NanoNum.fromLog10(-1000)
```

Conceptually:

```text
10^1000
10^-1000
```

## `fromLayer`

```lua
local value = NanoNum.fromLayer(1000, 5)
```

## `fromLayerLog10`

```lua
local value = NanoNum.fromLayerLog10(1000, 5)
```

## `fromLayerLog10Log10`

`v2.1.9` includes an additional hyper-layer constructor for layer counts whose logarithm itself needs logarithmic representation.

```lua
local value = NanoNum.fromLayerLog10Log10(400, 5)
```

Alias:

```lua
local value = NanoNum.fromHyperLayerLog10(400, 5)
```

## `fromScientific`

```lua
local value = NanoNum.fromScientific(1.25, 1000)
```

Conceptually:

```text
1.25 * 10^1000
```

without forcing `10^1000` through a native Luau number.

## `scale10`

```lua
local value = NanoNum.scale10(1.25, 1000)
```

## `compile`

Compile a flexible input once before a hot loop:

```lua
local value = NanoNum.compile("1e1000")
```

Input behavior:

```text
buffer -> validate/reuse NanoNum value
number -> fromNumber
string -> fromString
```

## Important native-overflow rule

Do not do this:

```lua
NanoNum.pow(10, 10 ^ 1e308)
```

Luau evaluates `10 ^ 1e308` first, so NanoNum receives native infinity.

Build the value inside NanoNum instead:

```lua
local inner = NanoNum.pow(10, 1e308)
local result = NanoNum.pow(10, inner)
```

or parse the expression:

```lua
local result = NanoNum.fromString("10^(10^1e308)")
```

---

# Core Math

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
```

Examples:

```lua
print(NanoNum.toNumber(NanoNum.add(12.5, 7.25)))
-- 19.75

print(NanoNum.toNumber(NanoNum.mul(12.5, 8)))
-- 100

print(NanoNum.toNumber(NanoNum.div(100, 8)))
-- 12.5
```

When a result leaves the native finite range, NanoNum can promote it into the symbolic huge-number kernel.

---

# Fast Typed Math

`NanoNum.fast` is intended for hot code where operand types are already known.

Operand codes:

```text
N = number
B = NanoNum buffer
S = string
```

Each binary operation provides the full typed matrix:

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

Supported binary operations:

```text
add
sub
mul
div
pow
compare
```

That produces **54 typed binary kernels**.

Examples:

```lua
local resultA = NanoNum.fast.addNN(10, 20)
local resultB = NanoNum.fast.addBB(a, b)
local resultC = NanoNum.fast.mulBN(bufferValue, 10)
local resultD = NanoNum.fast.divNB(100, bufferValue)
local resultE = NanoNum.fast.powSS("1e10", "2")
local order = NanoNum.fast.compareNN(10, 20)
```

Five unary buffer hot paths are also available:

```lua
NanoNum.fast.pow10B(value)
NanoNum.fast.log10B(value)
NanoNum.fast.negB(value)
NanoNum.fast.absB(value)
NanoNum.fast.reciprocalB(value)
```

Use the generic API for normal gameplay code and `NanoNum.fast` when profiling shows type dispatch matters.

---

# Hot-Loop Helpers

## `bindBinary`

Bind a typed operation once:

```lua
local addBuffers = NanoNum.bindBinary("add", "B", "B")
local result = addBuffers(a, b)
```

## `bindRight`

Bind the right operand once:

```lua
local multiplyBy10 = NanoNum.bindRight("mul", 10, "B")
local result = multiplyBy10(value)
```

## Localize frequently used kernels

```lua
local addBB = NanoNum.fast.addBB

for _ = 1, 1000 do
    value = addBB(value, increment)
end
```

## Compile repeated strings

```lua
local cost = NanoNum.compile("1e250")
```

Avoid reparsing the same string every frame or every purchase operation.

---

# Validation and Inspection

## Decode

```lua
local decoded, nextBit = NanoNum.decodeAt(value, 0)
```

Protected decode:

```lua
local ok, decoded, nextBit = NanoNum.tryDecodeAt(value, 0)
```

Use protected decoding for untrusted buffers.

## Validation helpers

```lua
NanoNum.isValid(value)
NanoNum.bitLength(value)
NanoNum.byteLength(value)
NanoNum.components(value)
NanoNum.inspect(value)
```

## Canonicalization

```lua
local canonical = NanoNum.canonicalize(value)
local alreadyCanonical = NanoNum.isCanonical(value)
```

## Range inspection

```lua
NanoNum.rangeClass(value)
NanoNum.layerDepth(value)
NanoNum.log10Abs(value)
```

Possible range classes include ordinary finite values, logs, layers, layer-log values, hyper-layer values, infinity, and NaN.

## Safe runtime wrappers

```lua
local okValue, compiled = NanoNum.tryCompile(value)
local okMath, result = NanoNum.tryMath("add", a, b)
local okCompare, comparison = NanoNum.tryCompare(a, b)

print(NanoNum.isMathValue(value))
```

---

# Packing and Serialization

NanoNum's compact buffer format is separate from its leaderboard codec.

## Pack multiple values

```lua
local values = {
    NanoNum.fromNumber(1),
    NanoNum.fromNumber(12.5),
    NanoNum.fromString("1e1000"),
    NanoNum.fromString("1e-1000"),
}

local packed, totalBits = NanoNum.packMany(values)
local unpacked = NanoNum.unpackMany(packed, #values, totalBits)
```

Protected unpacking:

```lua
local ok, unpacked = NanoNum.tryUnpackMany(packed, #values, totalBits)
```

`packMany()` is useful when storing or transmitting several NanoNum values because records can be packed at bit granularity instead of padding every value independently.

## Check encoded size

```lua
print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))
```

Do not assume every NanoNum value has a fixed byte size.

---

# Formatting

Main formatter:

```lua
NanoNum.format(value, decimalPlaces?, suffixType?)
```

Dedicated formatters:

```lua
NanoNum.formatStandard(value, decimalPlaces?)
NanoNum.formatExtended(value, decimalPlaces?)
NanoNum.formatExponent(value, decimalPlaces?)
NanoNum.formatHybrid(value, decimalPlaces?)
NanoNum.formatAlphabetic(value, decimalPlaces?)
NanoNum.formatMetric(value, decimalPlaces?)
NanoNum.formatScientific(value, decimalPlaces?)
NanoNum.formatEngineering(value, decimalPlaces?)
NanoNum.formatRoman(value, decimalPlaces?)
NanoNum.formatRomanExtended(value, decimalPlaces?)
```

Supported suffix types:

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

Defaults:

```lua
NanoNum.DEFAULT_SUFFIX_TYPE
-- "standard"

NanoNum.DEFAULT_PRECISION
-- 2

NanoNum.MAX_PRECISION
-- 8
```

Suffix helpers:

```lua
NanoNum.isSuffixType(typeName)
NanoNum.setDefaultSuffixType(typeName)
NanoNum.getSuffix(index, typeName?)
NanoNum.suffixIndex(suffix, typeName?)
```

Roman formatting constants:

```lua
NanoNum.ROMAN_CLASSICAL_MAX
-- 3999

NanoNum.ROMAN_EXTENDED_MAX
-- 9007199254740991
```

---

# Time and Utility Formatting

Time helpers:

```lua
NanoNum.formatTime(value, style?, precision?, maxParts?)
NanoNum.formatClock(value, precision?)
NanoNum.parseTime(text)
```

Time styles:

```text
compact
long
clock
seconds
```

Additional utility formatters:

```lua
NanoNum.formatRate(value, unit?, decimalPlaces?, suffixType?)
NanoNum.formatBytes(value, precision?, binary?)
NanoNum.formatOrdinal(value)
NanoNum.formatSigned(value, precision?, suffixType?)
```

These helpers are useful for simulator UI, stat panels, rates, storage displays, timers, and progression screens.

---

# Leaderboard Codec

NanoNum includes **LB v2**, a separate codec for Roblox ranking keys.

The compact NanoNum buffer serializer is optimized for representation size. The LB codec instead maps values into a monotonic signed integer inside the safe 53-bit integer range so the result can be used with `OrderedDataStore`.

```lua
print(NanoNum.lbcodecVersion())
-- 2
```

Core API:

```lua
NanoNum.lbencode(value)
NanoNum.tryLBEncode(value)
NanoNum.lbdecode(code)
NanoNum.isLBCode(code)
NanoNum.lbcodecVersion()
NanoNum.lbinfo(value)
NanoNum.lbquantize(value)
NanoNum.lbSameBucket(a, b)
NanoNum.lbRoundTripStable(value)
NanoNum.lbCompare(a, b)
```

Important constants:

```lua
NanoNum.LB_MAX
-- 9007199254740991

NanoNum.LB_ONE
-- 4503599627370496
```

LB v2 allocates ranking space across ordinary values, huge logs, layers, log-layer values, and hyper-layer values.

It is intentionally quantized. Use it for **ordering**, not as a lossless replacement for NanoNum serialization.

A useful stability property is:

```text
lbencode(x)
==
lbencode(lbdecode(lbencode(x)))
```

Example leaderboard key:

```lua
local score = NanoNum.fromString("1e1000")
local orderedKey = NanoNum.lbencode(score)
```

---

# Higher Math

## Unary and classification

```lua
NanoNum.sign(value)
NanoNum.neg(value)
NanoNum.abs(value)
NanoNum.reciprocal(value)
NanoNum.copySign(value, signSource)

NanoNum.toNumber(value)
NanoNum.toNumberSafe(value)

NanoNum.isNaN(value)
NanoNum.isInfinite(value)
NanoNum.isFinite(value)
NanoNum.isZero(value)
NanoNum.isInteger(value)
NanoNum.isOdd(value)
NanoNum.isEven(value)
NanoNum.isPositive(value)
NanoNum.isNegative(value)
```

## Logs, powers, roots, and exponentials

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
NanoNum.powInt(base, exponent)

NanoNum.sqrt(value)
NanoNum.cbrt(value)
NanoNum.root(value, degree)
NanoNum.square(value)
NanoNum.cube(value)
NanoNum.hypot(a, b)
```

## Rounding and integer helpers

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

## Range and interpolation

```lua
NanoNum.min(a, b)
NanoNum.max(a, b)
NanoNum.clamp(value, low, high)
NanoNum.clamp01(value)

NanoNum.distance(a, b)
NanoNum.ratio(a, b)
NanoNum.relativeDifference(a, b)
NanoNum.approxEq(a, b, relativeTolerance?, absoluteTolerance?)
NanoNum.orderOfMagnitude(value)
NanoNum.digitCount(value)

NanoNum.lerp(a, b, t)
NanoNum.inverseLerp(a, b, value)
NanoNum.remap(value, inMin, inMax, outMin, outMax)
NanoNum.moveTowards(current, target, maxDelta)
NanoNum.smoothstep(edge0, edge1, value)
NanoNum.smootherstep(edge0, edge1, value)
```

## Statistics

```lua
NanoNum.sum(values)
NanoNum.product(values)
NanoNum.mean(values)
NanoNum.geometricMean(values)
NanoNum.harmonicMean(values)
```

## Combinatorics, Gamma, and Beta

```lua
NanoNum.factorial(value)
NanoNum.factorialReal(value)
NanoNum.permutation(n, r)
NanoNum.combination(n, r)

NanoNum.gammaSign(value)
NanoNum.logGamma(value)
NanoNum.gamma(value)

NanoNum.betaSign(a, b)
NanoNum.logBeta(a, b)
NanoNum.beta(a, b)
```

## Series and progression

```lua
NanoNum.arithmeticSeries(first, difference, count)
NanoNum.geometricSeries(first, ratio, count)
NanoNum.compound(principal, rate, periods)

NanoNum.softcap(value, start, power)
NanoNum.inverseSoftcap(value, start, power)

NanoNum.diminishingReturns(value, scale)
NanoNum.inverseDiminishingReturns(value, scale)

NanoNum.sigmoid(value)
NanoNum.logit(value)
```

---

# Economy Helpers

NanoNum includes common incremental-game economy formulas:

```lua
NanoNum.geometricCost(baseCost, growth, owned, amount)
NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned?)
NanoNum.bulkBuyGeometric(currency, baseCost, growth, owned?)
NanoNum.nextGeometricCost(baseCost, growth, owned)
```

Example:

```lua
local currency = NanoNum.fromString("1e50")
local baseCost = NanoNum.fromNumber(10)
local growth = NanoNum.fromNumber(1.15)

local amount = NanoNum.maxAffordableGeometric(currency, baseCost, growth, 0)
```

---

# Tetration and Slog

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

NanoNum can promote base-10 tetration into layer, layer-log, and hyper-layer representations instead of trying to iterate impossible native values directly.

---

# Performance Guidance

NanoNum `v2.1.9` separates common finite work from cold huge-number fallback logic.

`NanoNum.mathPerfInfo()` reports the current architecture as:

```text
Path 0
    macro-inline finite math
    typed direct decode/encode
    zero-substring parser paths

Path 1
    one-call cold log/layer/hyper-layer fallback kernel
```

For normal code, start with the generic API:

```lua
value = NanoNum.add(value, gain)
```

For repeated strings, compile once:

```lua
local gain = NanoNum.compile("1e1000")
```

For known operand types in a measured hot loop:

```lua
local addBB = NanoNum.fast.addBB

for _ = 1, 1000 do
    value = addBB(value, gain)
end
```

### Benchmark policy

Performance depends on hardware, Roblox runtime, Studio load, plugin activity, warmup, benchmark shape, and the exact NanoNum revision.

Do not reuse benchmark numbers from an older release as current `v2.1.9` results.

For meaningful comparisons:

1. Use the same benchmark script.
2. Use the same machine.
3. Use the same Studio/runtime state.
4. Warm both versions equally.
5. Run multiple rounds.
6. Compare medians rather than one-off measurements.
7. Verify correctness before accepting a speedup.

---

# Precision and Limits

NanoNum has different precision goals for different magnitude classes.

## Native finite values

Ordinary finite fractions preserve the native `f64` value stored by Luau.

## Safe integers

Supported safe integers are exact through:

```text
-9007199254740991 .. 9007199254740991
```

## Huge symbolic values

Log, layer, layer-log, and hyper-layer metadata are compact symbolic representations and may be quantized.

NanoNum is therefore:

- exact for the finite `f64` value it stores,
- exact for supported safe integers,
- compact and symbolic for enormous values,
- not an arbitrary-precision decimal package,
- not an arbitrary-precision integer package.

## Layer metadata limits

```lua
NanoNum.MAX_LAYER
-- 1e308

NanoNum.MAX_LAYER_LOG10
-- 1e308

NanoNum.MAX_LAYER_LOG10_LOG10
-- 1e308
```

These constants limit representation metadata, not the intuitive size of the mathematical value being represented.

---

# Compatibility and Migration

## Current binary format

```lua
NanoNum.BINARY_FORMAT_VERSION
-- 3
```

Treat NanoNum's binary format as versioned persistent data.

Store your own schema/version field around saved NanoNum buffers so migrations are explicit.

## Legacy Normal records

Legacy quantized `Normal` records are not accepted by the current runtime decoder.

`NanoNum.engineInfo()` reports:

```lua
LegacyNormalRecords = false
```

If old persistent data may contain legacy Normal records, migrate it through a version that can still decode that historical format before switching permanently to the current serializer.

## Binary format upgrades

Do not assume serialized buffers from older binary-format versions are wire-compatible with Binary Format v3 unless you have explicitly tested that migration path.

Recommended deployment flow:

1. Keep a save-schema version outside the NanoNum payload.
2. Load historical data with a compatible reader.
3. Convert into current NanoNum values.
4. Re-encode using the current format.
5. Save the new schema version.
6. Remove migration code only after historical data is no longer expected.

## Legacy strings

The current parser contains compatibility handling for older layer-style display strings, but serialized-buffer compatibility should still be treated separately from text-parser compatibility.

---

# Public API Reference

## Construction and parsing

```text
fromNumber
fromLog10
fromLayer
fromLayerLog10
fromLayerLog10Log10
fromHyperLayerLog10
fromScientific
fromString
scale10
compile
tryCompile
isMathValue
```

## Decode, validation, and representation

```text
decodeAt
tryDecodeAt
isValid
components
bitLength
byteLength
inspect
canonicalize
isCanonical
rangeClass
layerDepth
log10Abs
engineInfo
```

## Core math

```text
add
sub
mul
div
pow
compare
eq
lt
lte
gt
gte
```

## Unary and classification

```text
sign
neg
abs
reciprocal
copySign
toNumber
toNumberSafe
isNaN
isInfinite
isFinite
isZero
isInteger
isOdd
isEven
isPositive
isNegative
```

## Range and rounding

```text
min
max
clamp
clamp01
floor
ceil
trunc
round
frac
mod
fmod
divmod
```

## Logs, powers, and roots

```text
log10
ln
log
log2
log1p
exp
exp2
expm1
pow10
powInt
sqrt
cbrt
root
square
cube
hypot
```

## Interpolation, distance, and statistics

```text
lerp
inverseLerp
remap
moveTowards
distance
ratio
relativeDifference
approxEq
orderOfMagnitude
digitCount
smoothstep
smootherstep
sum
product
mean
geometricMean
harmonicMean
```

## Combinatorics and special math

```text
factorial
factorialReal
permutation
combination
gcd
lcm
gammaSign
logGamma
gamma
betaSign
logBeta
beta
```

## Series and progression

```text
arithmeticSeries
geometricSeries
compound
softcap
inverseSoftcap
diminishingReturns
inverseDiminishingReturns
sigmoid
logit
```

## Economy

```text
geometricCost
maxAffordableGeometric
bulkBuyGeometric
nextGeometricCost
```

## Hyper-operations

```text
iteratedExp10
iteratedLog10
tetrate10
tetrate
tetrateInteger
tetrate10Integer
slog10
slog
```

## Formatting

```text
format
formatStandard
formatExtended
formatExponent
formatHybrid
formatAlphabetic
formatMetric
formatScientific
formatEngineering
formatRoman
formatRomanExtended
formatTime
formatClock
parseTime
formatRate
formatBytes
formatOrdinal
formatSigned
```

## Packing

```text
packMany
unpackMany
tryUnpackMany
```

## Leaderboard

```text
isLBCode
tryLBEncode
lbencode
lbdecode
lbcodecVersion
lbinfo
lbquantize
lbSameBucket
lbRoundTripStable
lbCompare
```

## Hot-path and runtime helpers

```text
NanoNum.fast
bindBinary
bindRight
mathPerfInfo
callPerfInfo
tryMath
tryCompare
```

---

# Recommended Usage

### Gameplay state

Store gameplay values as NanoNum buffers:

```lua
local coins = NanoNum.fromNumber(0)
coins = NanoNum.add(coins, gain)
```

### Display

Format only when the UI needs text:

```lua
CoinsLabel.Text = NanoNum.format(coins, 2, "standard")
```

### Repeated constants

Compile large strings once:

```lua
local upgradeCost = NanoNum.compile("1e500")
```

### Hot loops

Use typed kernels only after profiling:

```lua
local addBB = NanoNum.fast.addBB
```

### Untrusted data

Prefer protected APIs:

```lua
NanoNum.tryDecodeAt(...)
NanoNum.tryCompile(...)
NanoNum.tryMath(...)
NanoNum.tryCompare(...)
NanoNum.tryUnpackMany(...)
NanoNum.tryLBEncode(...)
```

### OrderedDataStore

Use `lbencode()` for ranking keys, not for normal persistence:

```lua
local rankKey = NanoNum.lbencode(score)
```

### Persistence

Use NanoNum serialization for NanoNum values and keep an application-level schema version alongside the data.

---

# Design Goals

NanoNum prioritizes:

1. Correct ordinary finite math.
2. Fast common arithmetic.
3. Symbolic huge-number range.
4. Compact exact integers.
5. Predictable range promotion.
6. Layer, layer-log, and hyper-layer scaling.
7. Stable monotonic leaderboard ranking.
8. Typed hot paths for performance-sensitive Roblox code.
9. Compact serialization and bit packing.
10. Simulator-oriented math, economy, progression, and formatting APIs.
11. Maintainable hot/cold execution paths instead of duplicating the full huge-number kernel everywhere.

NanoNum does **not** attempt to be a general arbitrary-precision decimal engine.

---

# Testing Checklist

Before shipping a NanoNum update, test at least:

- finite arithmetic correctness,
- safe-integer boundaries,
- `fromString()` parsing,
- huge log promotion,
- layer promotion,
- layer-log promotion,
- hyper-layer promotion,
- powers and roots,
- canonicalization,
- `packMany()` / `unpackMany()` round trips,
- time formatting and parsing,
- suffix formatting,
- Roman formatting,
- LB v2 ordering and round-trip stability,
- persisted-data migration,
- and hot-path performance.

Run correctness checks before using benchmark wins as release criteria.

---

## Repository

NanoNum is developed for Roblox Luau and maintained in the NanoNum project repository:

`https://github.com/SillyDev2026/NanoNum`
