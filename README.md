# NanoNum

**NanoNum** is a huge-number math, formatting, serialization, and leaderboard library for Roblox Luau.

NanoNum is built for simulator, clicker, incremental, economy, and progression systems that need ordinary finite math to stay accurate and fast while still supporting values far beyond the native Luau `number` range.

> Current release: **v2.0.3 — Speed-Tuned Compact Kernel**  
> Typecheck: **v3**  
> Binary format: **v2**  
> Parser: **v8**  
> Notation: **v9**  
> Suffix system: **v5**  
> Performance layout: **v14**  
> Path architecture: **v5 / Path 0**  
> Math: **v23**  
> Math correctness: **v13**  
> Math safety: **v7**  
> Math performance: **v12 / Math Path v7**  
> Tetration: **v7**  
> Slog: **v5**  
> Gamma/Beta: **v5**  
> Leaderboard codec: **LB v1**  
> Register scopes: **v4**  
> Compact kernel: **v2**  
> Fast unary API: **v3**

---

## Highlights

- Exact ordinary finite math through a native **f64 finite record**
- Compact exact small integers and variable-bit safe integers
- Symbolic values far beyond native `number`, including `1e1000` and layered towers
- Automatic range promotion:
  `finite -> log10 -> layer -> layer-log -> infinity`
- Mixed `number`, `buffer`, and `string` math inputs
- **54 typed binary kernels** under `NanoNum.fast`
- **5 typed unary buffer kernels** under `NanoNum.fast`
- Direct exact-f64 shortcuts for common buffer arithmetic
- First-byte buffer dispatch on common decode paths
- `compile`, `bindBinary`, and `bindRight` for hot loops
- Canonicalization and representation inspection APIs
- Bit-level `packMany` / `unpackMany`
- 53-bit-safe monotonic **LB v1** leaderboard codec
- Standard, Extended, Hybrid, Alphabetic, Metric, Exponent, Scientific, Engineering, Roman, and Roman Extended formatting
- Logs, roots, powers, interpolation, combinatorics, economy helpers, tetration, slog, gamma, beta, and more
- `--!native`
- `--!optimize 2`

---

# What changed in v2.0.3

v2.0.3 is a performance-focused update. It keeps the v2 math model and public API while reducing work on the most common finite paths.

Main changes:

- Faster `fromNumber()` integer/exact encoding.
- Faster first-byte dispatch when decoding NanoNum buffers.
- Direct exact-f64 shortcuts in common `BB` math.
- Faster `BN` / `NB` mixed math.
- Faster buffer unary paths.
- Faster generic finite arithmetic.
- Shared huge/log/layer fallback is retained instead of duplicating the full kernel into every function.
- The module remains compact instead of returning to the generated 30k+ line inline build.
- Huge-number promotion and v2 power behavior are unchanged.

The goal of v2.0.3 is:

```text
common finite value
    -> shortest possible finite path

huge / log / layer value
    -> shared symbolic kernel
```

rather than making every operation pay the full symbolic decode cost.

---

# Correctness status

The supplied v2.0.3 benchmark completed its correctness/promotion checks with:

```text
Passed: 23
Failed: 0
```

Those checks include:

- exact finite addition/multiplication/division
- finite power
- `10^1e308` log promotion
- `10^(10^1e308)` layer promotion
- third-level power towers
- `pow(10, hugeLog)` vs `pow10(hugeLog)`
- layer logarithm round trips
- nested power parsing
- canonical finite/layer values
- scientific construction
- `scale10`
- fast `BB` arithmetic agreement
- LB v1 round-trip stability
- retained range/clamp/predicate APIs

Run the included regression suite in Roblox Studio whenever changing the kernel.

---

# Compatibility

## Current binary format

```lua
NanoNum.BINARY_FORMAT_VERSION
-- 2
```

v2.0.3 supports the current record families:

```text
small integer
exact variable-bit integer
exact f64
log
layer
layer-log
special (NaN / +/-inf)
```

## Legacy Normal records

The old v1.8.x 31-bit quantized **Normal** record is no longer accepted by the v2 runtime decoder.

This is intentional. v2 removes that legacy path so the common decoder can stay smaller and faster.

If persisted data may still contain v1.8 Normal records, migrate it through a version that can read those records before switching the save format permanently to v2.

`DecodedNormal` remains in the exported type surface for source/type compatibility, but current v2 decoding does not produce a Normal value.

`NORMAL_SIGNIFICAND_BITS` also remains exposed as a compatibility constant; current ordinary fractional values do not use that old record.

For persisted data, keep your own schema/version field around NanoNum data.

---

# Installation

Place `NanoNum.lua` in your game and require it normally:

```lua
local NanoNum = require(path.To.NanoNum)
```

The module table is named `NanoNum`.

---

# Quick Start

```lua
local NanoNum = require(path.To.NanoNum)

local normal = NanoNum.fromNumber(12.5)
local huge = NanoNum.fromString("1e1000")
local tower = NanoNum.fromString("10^(10^1e308)")

print(NanoNum.toNumber(NanoNum.add(normal, 7.25)))
-- 19.75

print(NanoNum.formatScientific(huge))
-- 1e1000

print(NanoNum.rangeClass(tower))
-- layer
```

NanoNum values are Roblox `buffer` values:

```lua
local value = NanoNum.fromString("1e1000")

print(typeof(value))
-- buffer
```

Flexible math accepts all three input forms:

```lua
local a = NanoNum.add(12.5, 7.25)
local b = NanoNum.mul("1e1000", 10)
local c = NanoNum.div(NanoNum.fromNumber(100), 8)
```

For performance-critical code, compile strings once:

```lua
local increment = NanoNum.compile("1e1000")
local value = NanoNum.fromNumber(0)

for _ = 1, 1000 do
    value = NanoNum.add(value, increment)
end
```

---

# Representation

NanoNum uses multiple representations rather than forcing every value into one fixed-width structure.

```text
0..127
    -> 1-byte positive tiny integer

-1..-64
    -> 1-byte negative tiny integer

larger safe integer
    -> exact variable-bit integer

ordinary finite fraction
    -> exact f64 record

large/tiny magnitude
    -> log record

power-tower range
    -> layer record

extreme layer count
    -> layer-log record

NaN / +/-inf
    -> special record
```

## Exact finite record

Ordinary non-integer finite values use an exact Luau/IEEE-754 double payload.

```lua
local x = NanoNum.fromNumber(12.5)
local info = NanoNum.inspect(x)

print(info.Bits)
-- 72

print(info.Bytes)
-- 9

print(info.Data.Kind)
-- Exact
```

The standalone record is one NanoNum tag byte plus the 8-byte f64 payload.

## Compact integers

Small integers can use one byte:

```text
0..127
-1..-64
```

Larger safe integers use a variable-bit exact record through the normal IEEE-754 safe-integer envelope:

```text
-9007199254740991 .. 9007199254740991
```

## Symbolic scalars

Log/layer metadata uses NanoNum's compact scalar representation.

```lua
print(NanoNum.SCALAR_SIGNIFICAND_BITS)
-- 14
```

These fields are compact symbolic metadata, not arbitrary-precision decimal storage.

---

# Storage examples

Typical standalone storage from the current v2 benchmark:

| Value | Typical size |
|---|---:|
| exact finite fraction | 9 bytes / 72 bits |
| larger integer example | 4 bytes / 26 bits |
| huge log value | 4 bytes / 32 bits |
| layer-2 value | 5 bytes / 39 bits |
| layer-3 value | 5 bytes / 39 bits |
| scientific `1.25e1000` | 4 bytes / 32 bits |

Use runtime helpers instead of assuming a fixed size:

```lua
local value = NanoNum.fromNumber(123.456)

print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))
```

For multiple values, use `packMany()` to remove repeated standalone byte padding.

---

# Number range

NanoNum separates native finite values from its symbolic huge-number range.

```lua
NanoNum.MAX_LAYER
-- 1e308

NanoNum.MAX_LAYER_LOG10
-- 1e308
```

These values limit the metadata carriers, not the mathematical magnitude NanoNum can represent.

Examples:

```lua
local a = NanoNum.fromString("1e1000")
local b = NanoNum.fromLayer(3, 1000)
local c = NanoNum.fromLayerLog10(1e6, 1000)

local inner = NanoNum.pow(10, 1e308)
local tower = NanoNum.pow(10, inner)
```

Nested parser form:

```lua
local tower = NanoNum.fromString("10^(10^1e308)")
```

Compact tower notation is also supported by the current parser/formatter:

```text
e1e308
ee1e308
eee1e308
```

Important: this cannot work as native Luau:

```lua
NanoNum.pow(10, 10 ^ 1e308)
```

because Luau evaluates `10 ^ 1e308` first and turns it into `math.huge` before NanoNum receives it.

Use nested NanoNum operations instead.

---

# Constructors

## `fromNumber`

```lua
local value = NanoNum.fromNumber(12345.678)
```

Behavior:

- NaN -> special NaN
- `+math.huge` -> positive infinity
- `-math.huge` -> negative infinity
- `0..127` exact integer -> 1 byte
- `-1..-64` exact integer -> 1 byte
- other safe integers -> variable-bit exact integer
- other finite native numbers -> exact-f64

## `fromLog10`

```lua
local huge = NanoNum.fromLog10(1000)
local tiny = NanoNum.fromLog10(-1000)
```

## `fromLayer`

```lua
local value = NanoNum.fromLayer(1000, 5, false, false)
```

## `fromLayerLog10`

```lua
local value = NanoNum.fromLayerLog10(1e6, 1000)
```

## `fromScientific`

```lua
local value = NanoNum.fromScientific(1.25, 1000)
```

Equivalent conceptually to:

```text
1.25 * 10^1000
```

without forcing the exponent through a native finite intermediate.

## `scale10`

```lua
local value = NanoNum.scale10(1.25, 1000)
```

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

## `compile`

Compile flexible input once before a hot loop:

```lua
local value = NanoNum.compile("1e1000")
```

Input behavior:

```text
buffer -> validated/reused NanoNum value
number -> fromNumber
string -> fromString
```

---

# Decode, validation, and inspection

## `decodeAt`

```lua
local decoded, nextBit = NanoNum.decodeAt(value, 0)
```

Current runtime `Kind` values are:

```text
Integer
Exact
Log
Layer
Infinity
NaN
Reserved
```

Legacy `Normal` records are rejected in binary format v2.

## `tryDecodeAt`

```lua
local ok, decoded, nextBit = NanoNum.tryDecodeAt(value, 0)
```

Use this for untrusted buffers.

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

## Engine metadata

```lua
local info = NanoNum.engineInfo()

print(info.Version)
print(info.BinaryFormatVersion)
print(info.CompactKernelVersion)
print(info.LegacyNormalRecords)
```

Current v2.0.3 reports legacy Normal records as disabled.

---

# Packing

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

---

# Core math

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

For ordinary native inputs, NanoNum attempts the native finite path first.

```lua
print(NanoNum.toNumber(NanoNum.add(12.5, 7.25)))
-- 19.75

print(NanoNum.toNumber(NanoNum.sub(12.5, 7.25)))
-- 5.25

print(NanoNum.toNumber(NanoNum.mul(12.5, 8)))
-- 100

print(NanoNum.toNumber(NanoNum.div(100, 8)))
-- 12.5
```

When a result leaves native finite range, NanoNum promotes into the symbolic log/layer kernel.

---

# Direct typed math — `NanoNum.fast`

`NanoNum.fast` contains the typed hot-path matrix for known input types.

Binary operations:

```text
add
sub
mul
div
pow
compare
```

Operand codes:

```text
N = number
B = buffer
S = string
```

Each binary operation exposes:

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

That is 54 binary entries.

Examples:

```lua
NanoNum.fast.addNN(10, 20)
NanoNum.fast.addBB(a, b)
NanoNum.fast.mulBN(bufferValue, 10)
NanoNum.fast.divNB(100, bufferValue)
NanoNum.fast.powSS("1e10", "2")
NanoNum.fast.compareNN(10, 20)
```

v2 also provides five unary buffer fast paths:

```lua
NanoNum.fast.pow10B(value)
NanoNum.fast.log10B(value)
NanoNum.fast.negB(value)
NanoNum.fast.absB(value)
NanoNum.fast.reciprocalB(value)
```

Use `fast` when the operand types are already known.

For exact-f64 buffers, v2.0.3 can bypass much of the generic symbolic decoder.

---

# Binding hot paths

## `bindBinary`

```lua
local addBuffers = NanoNum.bindBinary("add", "B", "B")
local result = addBuffers(a, b)
```

## `bindRight`

```lua
local multiplyBy10 = NanoNum.bindRight("mul", 10, "B")
local result = multiplyBy10(value)
```

String constants can be compiled once when binding.

---

# Safe runtime helpers

```lua
local okValue, compiled = NanoNum.tryCompile(value)
local okMath, result = NanoNum.tryMath("add", a, b)
local okCompare, comparison = NanoNum.tryCompare(a, b)

print(NanoNum.isMathValue(value))
```

---

# Unary and classification

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

Range inspection:

```lua
NanoNum.rangeClass(value)
NanoNum.layerDepth(value)
NanoNum.log10Abs(value)
```

`rangeClass()` can return:

```text
nan
infinity
layer-log
layer
log
zero
finite
```

---

# Logs, powers, roots, and exponentials

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

Power operations automatically promote instead of collapsing to native infinity when NanoNum can represent the result symbolically.

---

# Rounding and integer helpers

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

Some exact integer helpers remain limited to values that can be treated as exact native-safe integers.

---

# Range, interpolation, and statistics

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

NanoNum.sum(values)
NanoNum.product(values)
NanoNum.mean(values)
NanoNum.geometricMean(values)
NanoNum.harmonicMean(values)
```

---

# Combinatorics, Gamma, and Beta

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

v2 extends factorial/gamma handling into huge positive values through NanoNum-space approximations when direct native evaluation is not available.

---

# Series and progression

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

# Economy helpers

```lua
NanoNum.geometricCost(baseCost, growth, owned, amount)
NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned?)
NanoNum.bulkBuyGeometric(currency, baseCost, growth, owned?)
NanoNum.nextGeometricCost(baseCost, growth, owned)
```

These are intended for incremental/clicker upgrade systems.

---

# Tetration and super-logarithm

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

Base-10 tetration can use the layer/log-layer representation for heights far beyond ordinary native iteration counts.

---

# Formatting

Main formatter:

```lua
NanoNum.format(value, decimalPlaces?, suffixType?)
```

Dedicated modes:

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

Suffix types:

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

---

# Time and utility formatting

```lua
NanoNum.formatTime(value, style?, precision?, maxParts?)
NanoNum.formatClock(value, precision?)
NanoNum.parseTime(text)

NanoNum.formatRate(value, unit?, decimalPlaces?, suffixType?)
NanoNum.formatBytes(value, precision?, binary?)
NanoNum.formatOrdinal(value)
NanoNum.formatSigned(value, precision?, suffixType?)
```

Time styles:

```text
compact
long
clock
seconds
```

---

# Leaderboard codec — LB v1

NanoNum includes a monotonic signed-integer codec for Roblox `OrderedDataStore` ranking.

```lua
print(NanoNum.lbcodecVersion())
-- 1
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

LB v1 is intentionally quantized. It is a ranking codec, not the lossless NanoNum serializer.

The stability invariant is:

```text
lbencode(x)
==
lbencode(lbdecode(lbencode(x)))
```

---

# Performance

Benchmark numbers depend on hardware, Roblox runtime, Studio load, plugin activity, warmup, and the exact benchmark script.

Always compare versions using the same script and environment.

## v2.0.3 current benchmark

The supplied v2.0.3 run completed:

```text
Tests: 90
Correctness passed: 23
Correctness failed: 0
BENCH STATUS: PASS
```

### Ordinary number math

| Operation | Median |
|---|---:|
| `NanoNum.add(number, number)` | **82.534 ns** |
| `NanoNum.sub(number, number)` | **82.135 ns** |
| `NanoNum.mul(number, number)` | **80.745 ns** |
| `NanoNum.div(number, number)` | **83.447 ns** |
| `NanoNum.pow(number, number)` | **180.484 ns** |
| `NanoNum.compare(number, number)` | **32.204 ns** |

### Typed `NN`

| Operation | Median |
|---|---:|
| `fast.addNN` | **83.502 ns** |
| `fast.subNN` | **82.080 ns** |
| `fast.mulNN` | **80.884 ns** |
| `fast.divNN` | **84.332 ns** |
| `fast.powNN` | **177.430 ns** |
| `fast.compareNN` | **31.188 ns** |

### Typed `BB`

| Operation | Median |
|---|---:|
| `fast.addBB` | **84.499 ns** |
| `fast.subBB` | **87.877 ns** |
| `fast.mulBB` | **87.506 ns** |
| `fast.divBB` | **88.443 ns** |
| `fast.powBB` | **135.003 ns** |
| `fast.compareBB` | **34.432 ns** |

### Generic buffer math

| Operation | Median |
|---|---:|
| `add(buffer, buffer)` | **84.424 ns** |
| `sub(buffer, buffer)` | **84.290 ns** |
| `mul(buffer, buffer)` | **83.818 ns** |
| `div(buffer, buffer)` | **84.115 ns** |
| `pow(buffer, buffer)` | **129.437 ns** |
| `compare(buffer, buffer)` | **34.618 ns** |

### Unary buffer paths

| Operation | Median |
|---|---:|
| `fast.pow10B` | **147.835 ns** |
| `fast.log10B` | **94.589 ns** |
| `fast.negB` | **81.467 ns** |
| `fast.absB` | **80.519 ns** |
| `fast.reciprocalB` | **183.309 ns** |

### Higher math

| Operation | Median |
|---|---:|
| `sqrt` finite | **191.669 ns** |
| `root` finite | **294.419 ns** |
| `log(x, 2)` | **308.384 ns** |
| `exp` finite | **205.904 ns** |
| `gamma(12.5)` | **491.867 ns** |
| `slog10(layer3)` | **391.747 ns** |
| `geometricCost` | **1139.500 ns** |
| `maxAffordableGeometric` | **3618.267 ns** |

### Huge-range examples

| Operation | Median |
|---|---:|
| `pow(10, 1e308)` | **198.697 ns** |
| `pow(10, hugeLog)` | **518.521 ns** |
| `pow10(hugeLog)` | **468.360 ns** |
| `log10(layer2)` | **471.693 ns** |
| `mul(hugeLog, hugeLog)` | **719.644 ns** |
| `compare(layer3, layer2)` | **564.533 ns** |

## v2.0.2 -> v2.0.3 examples

The v2.0.3 speed pass notably improved the common exact-buffer path.

Approximate changes from the supplied runs:

| Path | v2.0.2 | v2.0.3 |
|---|---:|---:|
| `fast.addBB` | 271.314 ns | **84.499 ns** |
| `fast.mulBB` | 268.589 ns | **87.506 ns** |
| `fast.powBB` | 313.624 ns | **135.003 ns** |
| `fast.compareBB` | 205.570 ns | **34.432 ns** |
| `fast.log10B` | 228.695 ns | **94.589 ns** |
| `fast.negB` | 192.268 ns | **81.467 ns** |
| `fast.absB` | 190.807 ns | **80.519 ns** |

Do not treat tiny sub-percent differences as meaningful without multiple isolated runs.

## Historical v1.9 note

The old v1.9 README reported results from a different benchmark generation.

Those numbers are useful as historical context, but they should not be treated as a strict apples-to-apples comparison with the current v2.0.3 suite unless both versions are run under the same script, Studio state, and hardware.

---

# Performance guidance

For ordinary code:

```lua
NanoNum.add(a, b)
```

For repeated strings:

```lua
local huge = NanoNum.compile("1e1000")
```

For known input types:

```lua
local addBB = NanoNum.fast.addBB

for _ = 1, 1000 do
    value = addBB(value, increment)
end
```

Benchmark both generic and typed paths in your real workload.

In v2.0.3, generic exact-buffer arithmetic can be as fast as or slightly faster than some `fast.BB` calls because both now receive specialized exact-f64 handling. `fast` is still useful for known-type dispatch and non-generic call sites.

Avoid parsing strings repeatedly inside hot loops.

---

# Precision model

NanoNum has different precision goals for different ranges.

## Native finite values

Ordinary non-integer finite values store a native f64 payload, preserving the finite precision Luau already provides.

## Safe integers

Safe integers are stored exactly through:

```text
-9007199254740991 .. 9007199254740991
```

## Huge symbolic values

Log/layer scalar metadata is compact and may be quantized.

NanoNum is therefore:

- exact for the native finite value it stores,
- exact for supported safe integers,
- symbolic/compact for enormous values,
- not an arbitrary-precision decimal package,
- not an arbitrary-precision integer package.

## Leaderboard values

LB v1 is intentionally quantized for sortable 53-bit-safe ranking keys.

---

# Version metadata

```lua
NanoNum.VERSION
-- "2.0.3"

NanoNum.TYPECHECK_VERSION
-- 3

NanoNum.REGISTER_SCOPE_VERSION
-- 4

NanoNum.BINARY_FORMAT_VERSION
-- 2

NanoNum.PARSER_VERSION
-- 8

NanoNum.NOTATION_VERSION
-- 9

NanoNum.SUFFIX_VERSION
-- 5

NanoNum.ROMAN_VERSION
-- 1

NanoNum.TIME_VERSION
-- 1

NanoNum.UTILITY_FORMAT_VERSION
-- 5

NanoNum.PERF_VERSION
-- 14

NanoNum.PATH_VERSION
-- 5

NanoNum.MATH_SCOPE_VERSION
-- 7

NanoNum.MATH_VERSION
-- 23

NanoNum.MATH_CLEANUP_VERSION
-- 8

NanoNum.MATH_CORRECTNESS_VERSION
-- 13

NanoNum.MATH_SAFETY_VERSION
-- 7

NanoNum.MATH_PERF_VERSION
-- 12

NanoNum.MATH_PATH_VERSION
-- 7

NanoNum.CALL_VERSION
-- 10

NanoNum.DIRECT_CALL_VERSION
-- 10

NanoNum.BIND_VERSION
-- 7

NanoNum.COMPILE_VERSION
-- 7

NanoNum.TETRATION_VERSION
-- 7

NanoNum.SLOG_VERSION
-- 5

NanoNum.GAMMA_VERSION
-- 5

NanoNum.POWER_VERSION
-- 2

NanoNum.CANONICAL_VERSION
-- 1

NanoNum.CANONICAL_API_VERSION
-- 1

NanoNum.RANGE_PROMOTION_VERSION
-- 1

NanoNum.SCIENTIFIC_API_VERSION
-- 1

NanoNum.FAST_UNARY_VERSION
-- 3

NanoNum.COMPACT_KERNEL_VERSION
-- 2

NanoNum.LB_SCOPE_VERSION
-- 1

NanoNum.LB_VERSION
-- 1
```

Subsystem versions are independent.

---

# Public API summary

## Construction / parsing

```text
fromNumber
fromLog10
fromLayer
fromLayerLog10
fromScientific
fromString
scale10
compile
tryCompile
isMathValue
```

## Decode / validation / representation

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

## Unary / classification

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

## Range / rounding

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

## Logs / powers / roots

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

## Interpolation / distance / statistics

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

## Combinatorics / special math

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

## Series / progression

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

## Iteration / hyper-operations

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

## Hot-path / runtime helpers

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

# Migration from v1.9 / v1.8

## From v1.9

The v2 math model keeps the exact-f64 ordinary finite architecture and expands the huge-number system with stronger promotion and power handling.

If your stored values are current integer/exact/log/layer/special records, test them against the v2 migration path before deploying.

## From v1.8

v1.8 Normal records are no longer decoded by v2.

If those records exist in persistent storage:

1. Load them with a version that still understands the old Normal format.
2. Re-encode them into current exact/integer/log/layer NanoNum values.
3. Save with your own schema version updated.
4. Only then remove the migration reader.

Do not deploy a format-2-only decoder against unknown historical data without a migration plan.

---

# Design goals

NanoNum prioritizes:

1. Correct ordinary finite math.
2. Fast common arithmetic.
3. Symbolic huge-number range.
4. Compact exact integers.
5. Predictable range promotion instead of premature native infinity.
6. Stable LB v1 ranking behavior.
7. Typed hot paths for performance-sensitive Roblox code.
8. A compact maintainable kernel instead of generated code duplication.
9. Simulator-oriented math, progression, economy, and formatting APIs.

NanoNum does **not** attempt to be a general arbitrary-precision decimal engine.

---

# Current status

v2.0.3 currently has:

```text
Benchmark tests: 90
Correctness checks passed: 23
Correctness checks failed: 0
Benchmark status: PASS
```

Continue testing:

- finite correctness,
- huge/log/layer correctness,
- integer boundary encoding,
- canonicalization,
- LB v1 bucket stability,
- pack/unpack round trips,
- persisted-data migration,
- and hot-path performance.

For performance comparisons, always benchmark the exact versions under the same Roblox Studio conditions.
