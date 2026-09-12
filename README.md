# NanoNum

**NanoNum** is a huge-number math, formatting, serialization, and leaderboard library for Roblox Luau.

NanoNum is designed for simulator, clicker, incremental, economy, and progression systems that need to work with values far beyond normal Luau `number` range while still keeping ordinary finite math accurate and fast.

> Current release: **v1.9.0 — AccurateFinite**  
> Typecheck: **v3**  
> Parser: **v6**  
> Notation: **v7**  
> Suffix system: **v5**  
> Performance layout: **v10**  
> Path architecture: **v4 / Path 0**  
> Math: **v19**  
> Math correctness: **v9**  
> Math safety: **v5**  
> Math performance: **v7 / Math Path v2**  
> Tetration: **v5**  
> Slog: **v4**  
> Gamma/Beta: **v4**  
> Leaderboard codec: **LB v1**  
> Register scopes: **v3**

---

## Highlights

- Exact ordinary finite math through a native **f64 finite record**
- Small integers remain compact and exact
- Safe integers use variable-bit exact integer records
- Legacy 1.8.x 31-bit normal records remain decodable
- Symbolic huge values such as `1e1000`
- Symbolic tiny values such as `1e-1000`
- Direct-layer and log-layer values
- Mixed `number`, `buffer`, and `string` math inputs
- **54 typed direct math kernels** under `NanoNum.fast`
- `compile`, `bindBinary`, and `bindRight` for hot loops
- Bit-level `packMany` / `unpackMany`
- 53-bit-safe monotonic **LB v1** leaderboard codec
- Standard, Extended, Hybrid, Alphabetic, Metric, Exponent, Scientific, Engineering, Roman, and Roman Extended formatting
- Duration, clock, rate, byte-size, ordinal, and signed formatting
- Logs, roots, powers, interpolation, series, combinatorics, economy helpers, tetration, slog, gamma, beta, and more
- `--!native`
- `--!optimize 2`

---

# What changed in v1.9.0

v1.9.0 replaces the lossy ordinary-decimal path from v1.8.x with an exact native-double path.

In v1.8.x, ordinary decimals were normally stored as a 31-bit scientific record containing a 16-bit quantized mantissa. That was compact, but values could change slightly during construction and every later operation inherited that error.

For example, the old path could produce results such as:

```text
12.5 + 7.25 -> 19.749141680018315
100 / 8     -> 12.499427786678874
```

v1.9.0 stores ordinary non-integer finite values in a 9-byte exact-f64 record instead:

```text
12.5 + 7.25 -> 19.75
12.5 - 7.25 -> 5.25
12.5 * 8    -> 100
100 / 8     -> 12.5
```

The huge-number log/layer architecture is unchanged in purpose: native finite math is used while it is representable, and symbolic log/layer storage handles values outside the ordinary finite range.

### Compatibility

- Existing compact integer records remain supported.
- Existing log/layer/special records remain supported.
- Legacy 1.8.x quantized normal records remain **readable**.
- New ordinary fractional finite values are written using the exact-f64 record.
- **LB v1 remains the active leaderboard format.**
- LB encoding intentionally preserves the legacy v1 ranking quantization so the finite-accuracy rewrite does not silently redesign leaderboard ordering.

---

# Installation

Place `NanoNum.lua` in your game and require it normally:

```lua
local NanoNum = require(path.To.NanoNum)
```

The module table is named `NanoNum` internally and externally.

---

# Quick Start

```lua
local NanoNum = require(path.To.NanoNum)

local normal = NanoNum.fromNumber(12.5)
local huge = NanoNum.fromString("1e1000")
local tiny = NanoNum.fromString("1e-1000")

print(NanoNum.toNumber(NanoNum.add(normal, 7.25)))
-- 19.75

print(NanoNum.formatScientific(huge))
-- 1e1000

print(NanoNum.formatScientific(tiny))
-- 1e-1000
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

---

# Representation

NanoNum uses multiple record classes instead of forcing every value into one fixed-width huge-number structure.

Conceptually:

```text
small integer
    -> 1-byte compact integer

larger safe integer
    -> exact variable-bit integer

ordinary fractional finite value
    -> exact f64 record

legacy v1.8.x ordinary decimal
    -> old 31-bit normal record, decode-compatible only

1e1000
    -> logarithmic record

layer-2+ value
    -> layered record

very large layer count
    -> log-layer field

NaN / +/-inf
    -> special record
```

## Exact finite record

New ordinary fractional finite values are stored using an exact Luau/IEEE-754 double payload.

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

The record uses one byte of NanoNum tagging plus an 8-byte `f64` payload.

This intentionally trades a few bytes of storage for correct ordinary finite math.

## Legacy normal record

`NORMAL_SIGNIFICAND_BITS` is still exposed as `16` because NanoNum can decode legacy compact normal records created by older versions.

```lua
print(NanoNum.NORMAL_SIGNIFICAND_BITS)
-- 16
```

That constant does **not** mean v1.9.0 writes new ordinary fractional numbers using the old 16-bit mantissa path.

## Scalar fields

Huge-number metadata such as log/layer scalar fields still uses NanoNum's compact scalar codec.

```lua
print(NanoNum.SCALAR_SIGNIFICAND_BITS)
-- 14
```

Those symbolic fields are intentionally compact and should not be confused with the exact-f64 ordinary finite path.

---

# Storage Examples

Storage depends on the value.

| Value class | Typical storage |
|---|---:|
| `0..127` small positive integer | 1 byte |
| `-1..-64` small negative integer | 1 byte |
| larger safe integer | variable |
| ordinary fractional finite | 9 bytes |
| legacy normal record | 31 useful bits / 4 bytes |
| huge log value | variable |
| layer value | variable |
| special value | 1 byte |

Use the runtime helpers instead of assuming a fixed size:

```lua
local value = NanoNum.fromNumber(123.456)

print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))
```

For many values, use `packMany()` to remove repeated standalone byte padding between records.

---

# Number Range

NanoNum separates ordinary finite values from its symbolic huge-number range.

```lua
NanoNum.MAX_LAYER
-- 1e308

NanoNum.MAX_LAYER_LOG10
-- 1e308
```

These are carrier limits for layer metadata. They are not the maximum mathematical value NanoNum can describe.

Huge values are represented symbolically through log, layer, and log-layer records rather than trying to materialize the entire number as an IEEE-754 double.

Examples:

```lua
local a = NanoNum.fromString("1e1000")
local b = NanoNum.fromLayer(3, 1000)
local c = NanoNum.fromLayerLog10(1e6, 1000)
```

---

# Constructors

## `fromNumber`

```lua
local value = NanoNum.fromNumber(12345.678)
```

v1.9.0 behavior:

- NaN -> special NaN record
- `+math.huge` -> positive infinity record
- `-math.huge` -> negative infinity record
- `0..127` exact positive integer -> 1-byte record
- `-1..-64` exact negative integer -> 1-byte record
- other safe integers -> exact variable-bit integer record
- other finite native numbers -> exact-f64 record

## `fromLog10`

```lua
local huge = NanoNum.fromLog10(1000)
-- 10^1000

local tiny = NanoNum.fromLog10(-1000)
-- 10^-1000
```

If the result is directly representable as a finite native number, NanoNum can return through the exact finite constructor. Otherwise it stays symbolic.

## `fromLayer`

```lua
local value = NanoNum.fromLayer(
    1000,
    5,
    false,
    false
)
```

## `fromLayerLog10`

```lua
local value = NanoNum.fromLayerLog10(1e6, 1000)
```

Use this when the layer count itself is more naturally represented by its logarithm.

## `fromString`

```lua
NanoNum.fromString("1250")
NanoNum.fromString("12345.678")
NanoNum.fromString("1e1000")
NanoNum.fromString("1e-1000")
NanoNum.fromString("1.25M")
NanoNum.fromString("1/1k")
NanoNum.fromString("E3,000")
NanoNum.fromString("L3 1k")
```

## `compile`

Compile a flexible value once before a hot loop:

```lua
local value = NanoNum.compile("1e1000")
```

Input behavior:

```text
buffer -> reused/validated NanoNum value
number -> fromNumber
string -> fromString
```

---

# Decode API

## `decodeAt`

```lua
local decoded, nextBit = NanoNum.decodeAt(value, 0)
```

Possible `Kind` values include:

```text
Integer
Normal   -- legacy compact normal
Exact    -- v1.9 exact finite f64
Log
Layer
Infinity
NaN
Reserved
```

Example exact finite result:

```lua
{
    Kind = "Exact",
    Value = 12.5,
    Negative = false,
}
```

`decodeAt()` is the trusted decoder and throws on malformed/truncated records.

## `tryDecodeAt`

```lua
local ok, decoded, nextBit = NanoNum.tryDecodeAt(value, 0)
```

Use this when the buffer may be invalid or untrusted.

---

# Validation and Inspection

```lua
local value = NanoNum.fromNumber(12.5)

print(NanoNum.isValid(value))
print(NanoNum.bitLength(value))
print(NanoNum.byteLength(value))

local components = NanoNum.components(value)
local info = NanoNum.inspect(value)
```

`inspect()` returns:

```text
Version
Bits
Bytes
PaddingBits
Data
```

---

# Packing

Pack multiple NanoNum buffers into one shared bitstream:

```lua
local values = {
    NanoNum.fromNumber(1),
    NanoNum.fromNumber(12.5),
    NanoNum.fromString("1e1000"),
    NanoNum.fromString("1e-1000"),
}

local packed, totalBits = NanoNum.packMany(values)
```

Unpack them later:

```lua
local values2 = NanoNum.unpackMany(packed, #values, totalBits)
```

Protected unpacking:

```lua
local ok, values2 = NanoNum.tryUnpackMany(packed, #values, totalBits)
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
```

Comparison helpers:

```lua
NanoNum.eq(a, b)
NanoNum.lt(a, b)
NanoNum.lte(a, b)
NanoNum.gt(a, b)
NanoNum.gte(a, b)
```

## Accurate finite math

When both operands are ordinary finite values, v1.9.0 keeps the operation on the native finite path whenever possible.

```lua
local add = NanoNum.add(12.5, 7.25)
local sub = NanoNum.sub(12.5, 7.25)
local mul = NanoNum.mul(12.5, 8)
local div = NanoNum.div(100, 8)

print(NanoNum.toNumber(add)) -- 19.75
print(NanoNum.toNumber(sub)) -- 5.25
print(NanoNum.toNumber(mul)) -- 100
print(NanoNum.toNumber(div)) -- 12.5
```

When a result cannot stay on the native finite path, NanoNum falls back into the log/layer huge-number kernel.

---

# Direct Typed Math — `NanoNum.fast`

`NanoNum.fast` contains 54 direct binary kernels.

Operations:

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

Each operation has:

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

Examples:

```lua
NanoNum.fast.addNN(10, 20)
NanoNum.fast.addBB(a, b)
NanoNum.fast.mulBN(bufferValue, 10)
NanoNum.fast.divNB(100, bufferValue)
NanoNum.fast.powSS("1e10", "2")
NanoNum.fast.compareNN(10, 20)
```

Use `fast` only when you already know the input types and trust the buffer inputs.

---

# Binding Hot Paths

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

Strings bound as constants are compiled once when possible, avoiding repeated parser work.

---

# Safe Runtime Helpers

For unknown or untrusted runtime values:

```lua
local okValue, compiled = NanoNum.tryCompile(value)
local okMath, result = NanoNum.tryMath("add", a, b)
local okCompare, comparison = NanoNum.tryCompare(a, b)
```

Check supported input types with:

```lua
NanoNum.isMathValue(value)
```

---

# Unary / Conversion

```lua
NanoNum.sign(value)
NanoNum.neg(value)
NanoNum.abs(value)
NanoNum.reciprocal(value)
NanoNum.copySign(value, signSource)
NanoNum.toNumber(value)
NanoNum.toNumberSafe(value)
```

Classification:

```lua
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

---

# Logs, Exponentials, Powers, and Roots

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

---

# Rounding / Integer Helpers

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

---

# Range, Interpolation, and Statistics

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
```

Interpolation:

```lua
NanoNum.lerp(a, b, t)
NanoNum.inverseLerp(a, b, value)
NanoNum.remap(value, inMin, inMax, outMin, outMax)
NanoNum.moveTowards(current, target, maxDelta)
NanoNum.smoothstep(edge0, edge1, value)
NanoNum.smootherstep(edge0, edge1, value)
```

Aggregates:

```lua
NanoNum.sum(values)
NanoNum.product(values)
NanoNum.mean(values)
NanoNum.geometricMean(values)
NanoNum.harmonicMean(values)
```

---

# Combinatorics / Series

```lua
NanoNum.factorial(value)
NanoNum.factorialReal(value)
NanoNum.permutation(n, r)
NanoNum.combination(n, r)

NanoNum.arithmeticSeries(first, difference, count)
NanoNum.geometricSeries(first, ratio, count)
NanoNum.compound(principal, rate, periods)
```

---

# Progression / Economy Helpers

```lua
NanoNum.softcap(value, start, power)
NanoNum.inverseSoftcap(value, start, power)
NanoNum.diminishingReturns(value, scale)
NanoNum.inverseDiminishingReturns(value, scale)
NanoNum.sigmoid(value)
NanoNum.logit(value)
```

Geometric upgrade helpers:

```lua
NanoNum.geometricCost(baseCost, growth, owned, amount)
NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned?)
NanoNum.bulkBuyGeometric(currency, baseCost, growth, owned?)
NanoNum.nextGeometricCost(baseCost, growth, owned)
```

---

# Tetration and Super-Logarithm

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

Current metadata:

```lua
NanoNum.TETRATION_VERSION
-- 5

NanoNum.SLOG_VERSION
-- 4
```

---

# Gamma / Beta

```lua
NanoNum.gammaSign(value)
NanoNum.logGamma(value)
NanoNum.gamma(value)
NanoNum.factorialReal(value)

NanoNum.betaSign(a, b)
NanoNum.logBeta(a, b)
NanoNum.beta(a, b)
```

```lua
NanoNum.GAMMA_VERSION
-- 4
```

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

Current suffix types:

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

# Time / Utility Formatting

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

# Leaderboard Codec — LB v1

NanoNum includes a monotonic signed-integer codec intended for Roblox `OrderedDataStore` ranking.

```lua
print(NanoNum.lbcodecVersion())
-- 1
```

Important constants:

```lua
NanoNum.LB_MAX
-- 9007199254740991

NanoNum.LB_ONE
-- 4503599627370496
```

Encode and decode:

```lua
local value = NanoNum.fromString("1e1000")
local code = NanoNum.lbencode(value)
local bucketValue = NanoNum.lbdecode(code)
```

LB v1 is intentionally **quantized**. It is a sortable ranking codec, not the lossless NanoNum serializer.

Use:

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

The v1.9 finite rewrite keeps LB v1 compatibility by mapping exact-f64 finite values through the legacy leaderboard quantization rules before generating their ranking code.

Do **not** assume `lbdecode(lbencode(x))` recreates the exact original NanoNum value. The intended invariant is:

```text
lbencode(x)
==
lbencode(lbdecode(lbencode(x)))
```

---

# Performance

v1.9.0 improved both correctness and core hot-path speed compared with v1.8.2.

Example Roblox Studio full benchmark run:

| Function | v1.8.2 | v1.9.0 | Approx. speedup |
|---|---:|---:|---:|
| `fromNumber` | 170.553 ns | **62.389 ns** | **2.73x** |
| `add` | 582.375 ns | **268.587 ns** | **2.17x** |
| `sub` | 579.756 ns | **264.620 ns** | **2.19x** |
| `mul` | 587.734 ns | **268.954 ns** | **2.19x** |
| `div` | 601.657 ns | **270.621 ns** | **2.22x** |
| `compare` | 425.467 ns | **206.159 ns** | **2.06x** |
| `toNumber` | 253.122 ns | **129.833 ns** | **1.95x** |
| `log10` | 438.506 ns | **231.143 ns** | **1.90x** |
| `sqrt` | 461.503 ns | **285.397 ns** | **1.62x** |
| `compile.number` | 186.167 ns | **95.134 ns** | **1.96x** |
| `fast.addNN` | 186.128 ns | **101.215 ns** | **1.84x** |
| `fast.subNN` | 200.743 ns | **82.811 ns** | **2.42x** |
| `fast.mulNN` | 185.295 ns | **91.349 ns** | **2.03x** |
| `fast.divNN` | 189.510 ns | **89.387 ns** | **2.12x** |
| `fast.compareBB` | 417.887 ns | **217.650 ns** | **1.92x** |

The v1.9.0 full benchmark also reported:

```text
Registered cases : 220
Passed           : 220
Failed           : 0
Elapsed          : 62.043 s
```

Correctness spot checks all passed:

```text
add 12.5+7.25   PASS 19.75
sub 12.5-7.25   PASS 5.25
mul 12.5*8      PASS 100
div 100/8       PASS 12.5
pow 10^2        PASS 100
sqrt 100        PASS 10
LB round-trip   PASS
pack/unpack     PASS
```

Benchmark timings depend on machine, Roblox runtime, Studio state, plugins, warmup, and the exact benchmark script. Compare versions with the same test setup.

---

# Performance Guidance

For ordinary code:

```lua
NanoNum.add(a, b)
```

For repeated string constants, compile once:

```lua
local huge = NanoNum.compile("1e1000")

for _ = 1, 1000 do
    value = NanoNum.add(value, huge)
end
```

If the operand types are known in a hot loop, use the typed API:

```lua
local addBB = NanoNum.fast.addBB

for _ = 1, 1000 do
    value = addBB(value, increment)
end
```

Or bind once:

```lua
local addBuffers = NanoNum.bindBinary("add", "B", "B")
```

Avoid repeatedly parsing strings in performance-critical loops.

---

# Precision Model

NanoNum v1.9.0 has two different precision goals depending on the value class.

## Ordinary finite values

Ordinary non-integer finite values use an exact native-double payload, so NanoNum preserves the same finite precision that Luau's `number` type provides.

This fixes the old false-math behavior caused by repeatedly quantizing an ordinary decimal mantissa.

## Safe integers

Safe integers are stored exactly through the IEEE-754 exact integer envelope:

```text
-9007199254740991 .. 9007199254740991
```

## Huge symbolic values

Log/layer metadata remains a compact huge-number representation. Scalar fields can be quantized and should not be treated as an arbitrary-precision decimal engine.

NanoNum is therefore:

- exact for the native finite value it stores,
- exact for supported safe integers,
- symbolic/compact for enormous values,
- not an arbitrary-precision decimal or arbitrary-precision integer library.

## Leaderboard values

LB v1 is intentionally quantized for sortable 53-bit-safe ranking keys.

---

# Version Metadata

```lua
NanoNum.VERSION
-- "1.9.0"

NanoNum.TYPECHECK_VERSION
-- 3

NanoNum.REGISTER_SCOPE_VERSION
-- 3

NanoNum.PARSER_VERSION
-- 6

NanoNum.NOTATION_VERSION
-- 7

NanoNum.SUFFIX_VERSION
-- 5

NanoNum.ROMAN_VERSION
-- 1

NanoNum.TIME_VERSION
-- 1

NanoNum.UTILITY_FORMAT_VERSION
-- 3

NanoNum.PERF_VERSION
-- 10

NanoNum.PATH_VERSION
-- 4

NanoNum.MATH_SCOPE_VERSION
-- 4

NanoNum.MATH_VERSION
-- 19

NanoNum.MATH_CLEANUP_VERSION
-- 5

NanoNum.MATH_CORRECTNESS_VERSION
-- 9

NanoNum.MATH_SAFETY_VERSION
-- 5

NanoNum.MATH_PERF_VERSION
-- 7

NanoNum.MATH_PATH_VERSION
-- 2

NanoNum.CALL_VERSION
-- 6

NanoNum.DIRECT_CALL_VERSION
-- 6

NanoNum.BIND_VERSION
-- 6

NanoNum.COMPILE_VERSION
-- 6

NanoNum.TETRATION_VERSION
-- 5

NanoNum.SLOG_VERSION
-- 4

NanoNum.GAMMA_VERSION
-- 4

NanoNum.LB_SCOPE_VERSION
-- 1

NanoNum.LB_VERSION
-- 1
```

Subsystem version numbers are independent. A math update does not automatically imply a leaderboard codec migration.

---

# Public Constants

Important public values include:

```lua
NanoNum.VERSION
NanoNum.TYPECHECK_VERSION
NanoNum.REGISTER_SCOPE_VERSION

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
NanoNum.DEFAULT_PRECISION
NanoNum.MAX_PRECISION
NanoNum.FORMAT_PRECISION_MODE
NanoNum.E_NOTATION_START
NanoNum.STANDARD_SUFFIX_MAX_INDEX
NanoNum.METRIC_SUFFIX_MAX_INDEX
NanoNum.SUFFIX_TYPES

NanoNum.ROMAN_CLASSICAL_MAX
NanoNum.ROMAN_EXTENDED_MAX

NanoNum.LB_SCOPE_VERSION
NanoNum.LB_VERSION
NanoNum.LB_MAX
NanoNum.LB_FINITE_MAX
NanoNum.LB_ONE
NanoNum.LB_POSITIVE_SPAN

NanoNum.MATH_SCOPE_VERSION
NanoNum.MATH_VERSION
NanoNum.MATH_CLEANUP_VERSION
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
NanoNum.SLOG_VERSION
NanoNum.GAMMA_VERSION
```

---

# Public API Summary

Construction / parsing:

```text
fromNumber, fromLog10, fromLayer, fromLayerLog10, fromString
compile, tryCompile, isMathValue
```

Decode / validation:

```text
decodeAt, tryDecodeAt, isValid, components, bitLength, byteLength, inspect
```

Core math:

```text
add, sub, mul, div, pow, compare
eq, lt, lte, gt, gte
```

Unary / classification:

```text
sign, neg, abs, reciprocal, copySign, toNumber, toNumberSafe
isNaN, isInfinite, isFinite, isZero, isInteger
isOdd, isEven, isPositive, isNegative
```

Range / rounding:

```text
min, max, clamp, clamp01
floor, ceil, trunc, round, frac
mod, fmod, divmod
```

Logs / powers / roots:

```text
log10, ln, log, log2, log1p
exp, exp2, expm1, pow10, powInt
sqrt, cbrt, root, square, cube, hypot
```

Interpolation / distance:

```text
lerp, inverseLerp, remap, moveTowards
distance, ratio, relativeDifference, approxEq
orderOfMagnitude, digitCount, smoothstep, smootherstep
```

Aggregates:

```text
sum, product, mean, geometricMean, harmonicMean
```

Combinatorics / special math:

```text
factorial, gammaSign, logGamma, gamma, factorialReal
permutation, combination, gcd, lcm
betaSign, logBeta, beta
```

Series / progression:

```text
arithmeticSeries, geometricSeries, compound
softcap, inverseSoftcap
diminishingReturns, inverseDiminishingReturns
sigmoid, logit
```

Economy:

```text
geometricCost, maxAffordableGeometric, bulkBuyGeometric, nextGeometricCost
```

Iteration / hyper-operations:

```text
iteratedExp10, iteratedLog10
tetrate10, tetrate, tetrateInteger, tetrate10Integer
slog10, slog
```

Formatting:

```text
format, formatStandard, formatExtended, formatExponent
formatHybrid, formatAlphabetic, formatMetric
formatScientific, formatEngineering
formatRoman, formatRomanExtended
formatTime, formatClock, parseTime
formatRate, formatBytes, formatOrdinal, formatSigned
```

Packing:

```text
packMany, unpackMany, tryUnpackMany
```

Leaderboard:

```text
isLBCode, tryLBEncode, lbencode, lbdecode, lbcodecVersion
lbinfo, lbquantize, lbSameBucket, lbRoundTripStable, lbCompare
```

Hot-path API:

```text
NanoNum.fast
bindBinary, bindRight
mathPerfInfo, callPerfInfo
tryMath, tryCompare
```

---

# Migration from v1.8.x

The main compatibility consideration is the ordinary finite record.

### Old

```text
ordinary fractional number
-> 31-bit quantized normal
-> 4 standalone bytes
```

### v1.9.0

```text
ordinary fractional number
-> exact f64
-> 9 standalone bytes
```

This means new finite fractions can consume more storage, but arithmetic no longer starts from an already-quantized value.

If maximum storage compression matters more than exact normal-number behavior, v1.8.x was smaller. If mathematical correctness and hot-path arithmetic are the priority, v1.9.0 is the recommended architecture.

Legacy normal buffers remain decodable, so old serialized NanoNum values do not need to be immediately rewritten just to be read.

For persisted data, it is still good practice to store a schema/data version around your save format so future migrations can be controlled explicitly.

---

# Design Goals

NanoNum prioritizes:

1. Correct ordinary finite math.
2. Fast common arithmetic.
3. Symbolic huge-number range.
4. Compact small integers.
5. Backward readability of legacy normal records.
6. Stable LB v1 ranking behavior.
7. Typed hot paths for performance-sensitive Roblox code.
8. A broad simulator-oriented math and formatting API.

NanoNum does not attempt to be a general arbitrary-precision decimal package. It combines native finite precision with a symbolic layered huge-number system built for Roblox gameplay workloads.

---

# Current Status

The v1.9.0 full benchmark exercised **220 registered benchmark cases** and completed with:

```text
Passed: 220
Failed: 0
```

The most important correctness regression tests now pass exactly, while the main `add/sub/mul/div` buffer paths are roughly twice as fast as the previous v1.8.2 build in the supplied benchmark run.

For development, continue testing both:

- finite correctness,
- huge/log/layer correctness,
- legacy buffer decode compatibility,
- LB v1 bucket stability,
- pack/unpack round trips,
- and hot-path performance.
