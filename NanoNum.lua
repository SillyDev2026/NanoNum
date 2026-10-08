--!native
--!optimize 2
-- NanoNum v2.4.10: regression fixes for safe calls, packed streams and scientific display.
-- One standalone ModuleScript. Binary buffer format 6 remains compatible.

export type EngineInfo = {
	Version: string,
	BinaryFormatVersion: number,
	CanonicalVersion: number,
	RangePromotionVersion: number,
	PowerVersion: number,
	CanonicalApiVersion: number,
	ScientificApiVersion: number,
	FastUnaryVersion: number,
	CompactKernelVersion: number,
	LegacyNormalRecords: boolean,
	MaxLayer: number,
	MaxLayerLog10: number,
	MaxLayerLog10Log10: number,
	HyperLayer: boolean,
	HyperLayerVersion: number,
	StringParserVersion: number,
	InlineMathVersion: number,
	ColdFallbackVersion: number,
	ExactFinite: boolean,
	HugePowerPromotion: boolean,
	HugeFactorialApproximation: boolean,
}

export type ExactDecimal = {Sign: number, Digits: string, Exponent: string, Approximate: boolean?}
export type NanoNumAPI = {
	fromStringExact: (string) -> ExactDecimal,
	formatExact: (ExactDecimal, number?) -> string,
	addExact: (ExactDecimal, ExactDecimal) -> ExactDecimal,
	subExact: (ExactDecimal, ExactDecimal) -> ExactDecimal,
	mulExact: (ExactDecimal, ExactDecimal) -> ExactDecimal,
	divExact: (ExactDecimal, ExactDecimal, number?) -> ExactDecimal,
	powIntExact: (ExactDecimal, number) -> ExactDecimal,
	compareExact: (ExactDecimal, ExactDecimal) -> number,
	exponentAddExact: (string, string) -> string,
	exponentCompareExact: (string, string) -> number,
	lbencodeChecked: (MathValue) -> (number, boolean),
	lbdecodeChecked: (number) -> (boolean, buffer?),
	lbencodeV2: (MathValue) -> number,
	lbdecodeV2: (number) -> buffer,
	[string]: any,
	fromNumber: (value: number) -> buffer,
	fromLog10: (exponent: number, negative: boolean?) -> buffer,
	fromLayer: (layer: number, top: number, negative: boolean?, reciprocal: boolean?) -> buffer,
	fromLayerLog10: (layerLog10: number, top: number, negative: boolean?, reciprocal: boolean?) -> buffer,
	fromLayerLog10Log10: (layerLog10Log10: number, top: number, negative: boolean?, reciprocal: boolean?) -> buffer,
	fromHyperLayerLog10: (layerLog10Log10: number, top: number, negative: boolean?, reciprocal: boolean?) -> buffer,
	isSuffixType: (suffixType: string) -> boolean,
	setDefaultSuffixType: (suffixType: string) -> boolean,
	getSuffix: (index: number, suffixType: string?) -> string?,
	suffixIndex: (suffix: string, suffixType: string?) -> number?,
	fromString: (value: string, suffixType: SuffixName?) -> buffer,
	decodeAt: (data: buffer, bitOffset: number) -> (DecodedValue, number),
	tryDecodeAt: (data: buffer, bitOffset: number?) -> (boolean, DecodedValue?, number?),
	isValid: (value: buffer) -> boolean,
	components: (value: buffer) -> DecodedValue,
	bitLength: (value: buffer) -> number,
	byteLength: (value: buffer) -> number,
	add: (a: MathValue, b: MathValue) -> buffer,
	sub: (a: MathValue, b: MathValue) -> buffer,
	mul: (a: MathValue, b: MathValue) -> buffer,
	div: (a: MathValue, b: MathValue) -> buffer,
	pow: (a: MathValue, b: MathValue) -> buffer,
	compare: (a: MathValue, b: MathValue) -> number,
	eq: (a: MathValue, b: MathValue) -> boolean,
	lt: (a: MathValue, b: MathValue) -> boolean,
	lte: (a: MathValue, b: MathValue) -> boolean,
	gt: (a: MathValue, b: MathValue) -> boolean,
	gte: (a: MathValue, b: MathValue) -> boolean,
	sign: (value: MathValue) -> number,
	neg: (value: MathValue) -> buffer,
	abs: (value: MathValue) -> buffer,
	reciprocal: (value: MathValue) -> buffer,
	copySign: (value: MathValue, signSource: MathValue) -> buffer,
	toNumber: (value: MathValue) -> number,
	toNumberSafe: (value: MathValue) -> number?,
	isNaN: (value: MathValue) -> boolean,
	isInfinite: (value: MathValue) -> boolean,
	isFinite: (value: MathValue) -> boolean,
	isZero: (value: MathValue) -> boolean,
	isInteger: (value: MathValue) -> boolean,
	isOdd: (value: MathValue) -> boolean,
	isEven: (value: MathValue) -> boolean,
	isPositive: (value: MathValue) -> boolean,
	isNegative: (value: MathValue) -> boolean,
	min: (a: MathValue, b: MathValue) -> buffer,
	max: (a: MathValue, b: MathValue) -> buffer,
	clamp: (value: MathValue, low: MathValue, high: MathValue) -> buffer,
	clamp01: (value: MathValue) -> buffer,
	floor: (value: MathValue) -> buffer,
	ceil: (value: MathValue) -> buffer,
	trunc: (value: MathValue) -> buffer,
	round: (value: MathValue, decimals: number?) -> buffer,
	frac: (value: MathValue) -> buffer,
	mod: (a: MathValue, b: MathValue) -> buffer,
	fmod: (a: MathValue, b: MathValue) -> buffer,
	divmod: (a: MathValue, b: MathValue) -> (buffer, buffer),
	log10: (value: MathValue) -> buffer,
	ln: (value: MathValue) -> buffer,
	log: (value: MathValue, base: MathValue?) -> buffer,
	log2: (value: MathValue) -> buffer,
	log1p: (value: MathValue) -> buffer,
	exp: (value: MathValue) -> buffer,
	exp2: (value: MathValue) -> buffer,
	expm1: (value: MathValue) -> buffer,
	pow10: (value: MathValue) -> buffer,
	powInt: (base: MathValue, exponent: MathValue) -> buffer,
	sqrt: (value: MathValue) -> buffer,
	cbrt: (value: MathValue) -> buffer,
	root: (value: MathValue, degree: MathValue) -> buffer,
	square: (value: MathValue) -> buffer,
	cube: (value: MathValue) -> buffer,
	hypot: (a: MathValue, b: MathValue) -> buffer,
	lerp: (a: MathValue, b: MathValue, t: MathValue) -> buffer,
	inverseLerp: (a: MathValue, b: MathValue, value: MathValue) -> buffer,
	remap: (value: MathValue, inMin: MathValue, inMax: MathValue, outMin: MathValue, outMax: MathValue) -> buffer,
	moveTowards: (current: MathValue, target: MathValue, maxDelta: MathValue) -> buffer,
	distance: (a: MathValue, b: MathValue) -> buffer,
	ratio: (a: MathValue, b: MathValue) -> buffer,
	relativeDifference: (a: MathValue, b: MathValue) -> buffer,
	approxEq: (a: MathValue, b: MathValue, relativeTolerance: MathValue?, absoluteTolerance: MathValue?) -> boolean,
	orderOfMagnitude: (value: MathValue) -> buffer,
	digitCount: (value: MathValue) -> buffer,
	smoothstep: (edge0: MathValue, edge1: MathValue, value: MathValue) -> buffer,
	smootherstep: (edge0: MathValue, edge1: MathValue, value: MathValue) -> buffer,
	sum: (values: MathValueArray) -> buffer,
	product: (values: MathValueArray) -> buffer,
	mean: (values: MathValueArray) -> buffer,
	geometricMean: (values: MathValueArray) -> buffer,
	harmonicMean: (values: MathValueArray) -> buffer,
	factorial: (value: MathValue) -> buffer,
	gammaSign: (value: MathValue) -> number,
	logGamma: (value: MathValue) -> buffer,
	gamma: (value: MathValue) -> buffer,
	factorialReal: (value: MathValue) -> buffer,
	permutation: (nValue: MathValue, rValue: MathValue) -> buffer,
	combination: (nValue: MathValue, rValue: MathValue) -> buffer,
	gcd: (a: MathValue, b: MathValue) -> buffer,
	lcm: (a: MathValue, b: MathValue) -> buffer,
	arithmeticSeries: (first: MathValue, difference: MathValue, countValue: MathValue) -> buffer,
	geometricSeries: (first: MathValue, ratioValue: MathValue, countValue: MathValue) -> buffer,
	compound: (principal: MathValue, rate: MathValue, periods: MathValue) -> buffer,
	softcap: (value: MathValue, start: MathValue, power: MathValue) -> buffer,
	inverseSoftcap: (value: MathValue, start: MathValue, power: MathValue) -> buffer,
	diminishingReturns: (value: MathValue, scale: MathValue) -> buffer,
	inverseDiminishingReturns: (value: MathValue, scale: MathValue) -> buffer,
	sigmoid: (value: MathValue) -> buffer,
	logit: (value: MathValue) -> buffer,
	geometricCost: (baseCost: MathValue, growth: MathValue, owned: MathValue, amount: MathValue) -> buffer,
	maxAffordableGeometric: (currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?) -> buffer,
	bulkBuyGeometric: (currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?) -> (buffer, buffer, buffer),
	nextGeometricCost: (baseCost: MathValue, growth: MathValue, owned: MathValue) -> buffer,
	iteratedExp10: (value: MathValue, timesValue: MathValue) -> buffer,
	iteratedLog10: (value: MathValue, timesValue: MathValue) -> buffer,
	tetrate10: (heightValue: MathValue, payload: MathValue?) -> buffer,
	tetrate: (baseValue: MathValue, heightValue: MathValue, payload: MathValue?) -> buffer,
	tetrateInteger: (baseValue: MathValue, heightValue: MathValue, payload: MathValue?) -> buffer,
	tetrate10Integer: (heightValue: MathValue, payload: MathValue?) -> buffer,
	slog10: (value: MathValue) -> buffer,
	slog: (value: MathValue, baseValue: MathValue?) -> buffer,
	betaSign: (a: MathValue, b: MathValue) -> number,
	logBeta: (a: MathValue, b: MathValue) -> buffer,
	beta: (a: MathValue, b: MathValue) -> buffer,
	compile: (value: MathValue) -> buffer,
	toEN: (value: MathValue) -> EN,
	fromEN: (value: EN) -> buffer,
	toString: (value: MathValue) -> string,
	toStringEN: (value: MathValue) -> string,
	canonicalize: (value: MathValue) -> buffer,
	isCanonical: (value: MathValue) -> boolean,
	log10Abs: (value: MathValue) -> buffer,
	scale10: (value: MathValue, exponent: MathValue) -> buffer,
	fromScientific: (mantissa: MathValue, exponent: MathValue) -> buffer,
	layerDepth: (value: MathValue) -> buffer,
	rangeClass: (value: MathValue) -> string,
	bindBinary: (operation: BindOperation, leftType: DirectValueType, rightType: DirectValueType) -> BoundBinaryFunction?,
	bindRight: (operation: MathBinaryOperation, constant: MathValue, leftType: DirectValueType?) -> BoundUnaryFunction?,
	isMathValue: (value: any) -> boolean,
	tryCompile: (value: any) -> (boolean, buffer?),
	tryMath: (operation: MathBinaryOperation, a: any, b: any) -> (boolean, buffer?),
	tryCompare: (a: any, b: any) -> (boolean, number?),
	engineInfo: () -> EngineInfo,
	mathPerfInfo: () -> MathPerfInfo,
	callPerfInfo: () -> CallPerfInfo,
	format: (value: buffer, decimalPlaces: number?, suffixType: SuffixName?) -> string,
	formatStandard: (value: buffer, decimalPlaces: number?) -> string,
	formatExtended: (value: buffer, decimalPlaces: number?) -> string,
	formatExponent: (value: buffer, decimalPlaces: number?) -> string,
	formatHybrid: (value: buffer, decimalPlaces: number?) -> string,
	formatAlphabetic: (value: buffer, decimalPlaces: number?) -> string,
	formatMetric: (value: buffer, decimalPlaces: number?) -> string,
	formatScientific: (value: buffer, decimalPlaces: number?) -> string,
	formatEngineering: (value: buffer, decimalPlaces: number?) -> string,
	formatRoman: (value: buffer, decimalPlaces: number?) -> string,
	formatRomanExtended: (value: buffer, decimalPlaces: number?) -> string,
	formatTime: (value: MathValue, style: TimeStyle?, precision: number?, maxParts: number?) -> string,
	formatClock: (value: MathValue, precision: number?) -> string,
	parseTime: (text: string) -> buffer,
	formatRate: (value: MathValue, unit: string?, decimalPlaces: number?, suffixType: SuffixName?) -> string,
	formatBytes: (value: MathValue, precision: number?, binary: boolean?) -> string,
	formatOrdinal: (value: MathValue) -> string,
	formatSigned: (value: MathValue, precision: number?, suffixType: SuffixName?) -> string,
	packMany: (values: {buffer}) -> (buffer, number),
	unpackMany: (packed: buffer, count: number, totalBits: number?) -> {buffer},
	tryUnpackMany: (packed: buffer, count: number, totalBits: number?) -> (boolean, {buffer}?),
	inspect: (value: buffer) -> InspectInfo,
	isLBCode: (encoded: number) -> boolean,
	tryLBEncode: (value: any) -> (boolean, number),
	lbencode: (value: MathValue) -> number,
	lbdecode: (encoded: number) -> buffer,
	lbcodecVersion: () -> number,
	lbinfo: (value: MathValue) -> LBInfo,
	lbquantize: (value: MathValue) -> buffer,
	lbSameBucket: (a: MathValue, b: MathValue) -> boolean,
	lbRoundTripStable: (value: MathValue) -> boolean,
	lbCompare: (a: MathValue, b: MathValue) -> number,
}

local NanoNum: {[string]: any} = {}

export type MathValue = number | string | buffer
export type EN = {number}
export type MathBinaryOperation = "add" | "sub" | "mul" | "div" | "pow"
export type MathCompareOperation = "compare" | "eq" | "lt" | "lte" | "gt" | "gte"
export type BindOperation = MathBinaryOperation | "compare"
export type DirectValueType = "number" | "buffer" | "string" | "N" | "B" | "S"
export type MathValueArray = {MathValue}
export type SuffixType = "standard" | "extended" | "hybrid" | "alphabetic" | "metric" | "exponent" | "scientific" | "engineering" | "roman" | "romanextended"
export type SuffixName = SuffixType
export type TimeStyle = "compact" | "long" | "clock" | "seconds"
export type DecodedInteger = {Kind: "Integer", Value: number, Negative: boolean}
export type DecodedNormal = {Kind: "Normal", Negative: boolean, Exponent: number, Mantissa: number}
export type DecodedExact = {Kind: "Exact", Value: number, Negative: boolean}
export type DecodedLog = {Kind: "Log", Negative: boolean, Reciprocal: boolean, Layer: number, Top: number}
export type DecodedLayer = {Kind: "Layer", Negative: boolean, Reciprocal: boolean, Layer: number?, LayerLog10: number?, LayerLog10Log10: number?, LayerIsLog: boolean, LayerIsHyper: boolean?, Top: number}
export type DecodedInfinity = {Kind: "Infinity", Negative: boolean}
export type DecodedNaN = {Kind: "NaN", Negative: boolean}
export type DecodedReserved = {Kind: "Reserved", Negative: boolean}
export type DecodedValue = DecodedInteger | DecodedNormal | DecodedExact | DecodedLog | DecodedLayer | DecodedInfinity | DecodedNaN | DecodedReserved
export type InspectInfo = {Version: string, Bits: number, Bytes: number, PaddingBits: number, Data: DecodedValue}
export type LBInfo = {version: number, code: number, band: string, negative: boolean, reciprocal: boolean, distanceFromOne: number}
export type MathPerfInfo = {Version: number, PathVersion: number, DefaultPath: number, Path0: string, Path1: string, TemporaryDecodeTablesOnPath0: number}
export type CallPerfInfo = {
	Version: number,
	DirectCallVersion: number,
	BindVersion: number,
	CompileVersion: number,
	MathPerfVersion: number,
	MathPathVersion: number,
	FlexibleTypeChecksPerBinaryCall: number,
	DirectTypeChecksPerBinaryCall: number,
	StringParsingCanBeEliminatedByCompile: boolean,
}
export type MathBinaryFunction = (MathValue, MathValue) -> buffer
export type MathCompareFunction = (MathValue, MathValue) -> number
export type MathPredicateFunction = (MathValue, MathValue) -> boolean
export type BoundBinaryResult = buffer | number
export type BoundBinaryFunction = (MathValue, MathValue) -> BoundBinaryResult
export type BoundUnaryFunction = (MathValue) -> BoundBinaryResult
NanoNum.TYPECHECK_VERSION = 3
NanoNum.VERSION = "2.4.10-regression-fix"
NanoNum.REGISTER_SCOPE_VERSION = 6
NanoNum.MAX_LAYER = 1e308
NanoNum.MAX_LAYER_LOG10 = 1e308
NanoNum.MAX_LAYER_LOG10_LOG10 = 1e308
NanoNum.MAX_HYPER_LAYER_LOG10 = NanoNum.MAX_LAYER_LOG10_LOG10
NanoNum.NORMAL_SIGNIFICAND_BITS = 16
NanoNum.SCALAR_SIGNIFICAND_BITS = 14
NanoNum.PARSER_VERSION = 14
NanoNum.NOTATION_VERSION = 24
NanoNum.PERF_VERSION = 23
NanoNum.PATH_VERSION = 6
NanoNum.DEFAULT_PATH = 0
NanoNum.MATH_SCOPE_VERSION = 10
NanoNum.MATH_VERSION = 34
NanoNum.MATH_CLEANUP_VERSION = 17
NanoNum.CALL_VERSION = 12
NanoNum.DIRECT_CALL_VERSION = 12
NanoNum.BIND_VERSION = 7
NanoNum.COMPILE_VERSION = 7
NanoNum.MATH_PERF_VERSION = 18
NanoNum.MATH_PATH_VERSION = 10
NanoNum.MATH_DEFAULT_PATH = 0
NanoNum.MATH_CORRECTNESS_VERSION = 42
NanoNum.TETRATION_VERSION = 10
NanoNum.SLOG_VERSION = 6
NanoNum.GAMMA_VERSION = 7
NanoNum.MATH_SAFETY_VERSION = 18
NanoNum.BINARY_FORMAT_VERSION = 6
NanoNum.CANONICAL_VERSION = 5
NanoNum.RANGE_PROMOTION_VERSION = 2
NanoNum.POWER_VERSION = 4
NanoNum.CANONICAL_API_VERSION = 2
NanoNum.EN_VERSION = 3
NanoNum.SCIENTIFIC_API_VERSION = 6
NanoNum.FAST_UNARY_VERSION = 4
NanoNum.COMPACT_KERNEL_VERSION = 9
NanoNum.HYPER_LAYER_VERSION = 1
NanoNum.STRING_PARSER_VERSION = 8
NanoNum.INLINE_MATH_VERSION = 3
NanoNum.COLD_FALLBACK_VERSION = 1
NanoNum.REGISTER_FRAME_VERSION = 2
NanoNum.SOURCE_STYLE_VERSION = 2
local floor: (number) -> number = math.floor
local ceil: (number) -> number = math.ceil
local abs: (number) -> number = math.abs
local min: (...number) -> number = math.min
local max: (...number) -> number = math.max
local clamp: (number, number, number) -> number = math.clamp
local log: (number, number?) -> number = math.log
local log10: (number) -> number = math.log10
local sqrt: (number) -> number = math.sqrt
local exp: (number) -> number = math.exp
local sin: (number) -> number = math.sin
local huge = math.huge
local pi = math.pi
local format: (string, ...any) -> string = string.format
local byte: (string, number?, number?) -> ...number = string.byte
local sub: (string, number, number?) -> string = string.sub
local lower: (string) -> string = string.lower
local find = string.find
local gsub = string.gsub
local match = string.match
local split = string.split
local rep = string.rep
local char = string.char
local concat = table.concat
local tableCreate = table.create
local bufferCreate: (number) -> buffer = buffer.create
local bufferReadBits: (buffer, number, number) -> number = buffer.readbits
local bufferWriteBits: (buffer, number, number, number) -> () = buffer.writebits
local bufferWriteU8: (buffer, number, number) -> () = buffer.writeu8
local bufferReadU8: (buffer, number) -> number = buffer.readu8
local bufferReadF64: (buffer, number) -> number = buffer.readf64
local bufferWriteF64: (buffer, number, number) -> () = buffer.writef64
local bufferLen: (buffer) -> number = buffer.len
local bufferCopy: (buffer, number, buffer, number?, number?) -> () = buffer.copy
local band: (...number) -> number = bit32.band
local countlz: (number) -> number = bit32.countlz
local toNumber = tonumber
local toString = tostring
local fastPcall = pcall
local LN10: number = 2.302585092994046
local LOG10_2: number = 0.3010299956639812
local LOG10_E: number = 0.4342944819032518
local TWO_PI: number = 6.283185307179586
local SAFE_INTEGER: number = 9007199254740991
local DIRECT_LOG_MAX: number = 308.25471555991675
local DIRECT_LOG_MIN: number = -323.3062153431158
local NAN = 0 / 0
local POW10_DECIMAL = {1, 10, 100, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12}
local function oneMinusPow10Neg(distance: number): number
	local x = -distance * LN10
	if x <= -1e-4 then return 1 - 10 ^ (-distance) end
	local x2 = x * x
	return -(x + x2 * 0.5 + x2 * x / 6 + x2 * x2 / 24 + x2 * x2 * x / 120 + x2 * x2 * x2 / 720)
end
local SPECIAL_POS_INF: number = 0
local SPECIAL_NEG_INF: number = 1
local SPECIAL_NAN: number = 2
local SPECIAL_RESERVED: number = 3
local HYPER_LAYER_PREFIX: number = 23
local SCALAR_EXP_BITS: number = 10
local SCALAR_EXP_BIAS: number = 324
local SCALAR_EXP_MIN: number = -324
local SCALAR_EXP_MAX: number = 308
local SCALAR_MANT_BITS: number = 14
local SCALAR_MANT_MAX: number = 16383
local SCALAR_APPROX_BITS: number = 25
local SCALAR_SAFE_EXACT_BITS: number = 60
local EXACT_LEN_BITS: number = 6
local INTEGER_LEN_BITS: number = 5
local MAX_INTEGER_MODE_BITS: number = 53
local MAX_STANDALONE_BYTES: number = 19
local EXACT_F64_BITS: number = 72
local EXACT_F64_BYTES: number = 9
local SCALAR_F64_SENTINEL = 124 -- bit0=0, n=62: lossless structural scalar f64
local EXACT_LOG_SENTINEL = 126 -- legacy v2.3.4-v2.3.6 exact-log sentinel; decode-only compatibility
local EXACT_LOG_BITS = 80 -- 7-bit log header + 7-bit sentinel + 2 pad bits + exact f64 magnitude
local DIRECT_LAYER_LOG10_MAX: number = 308
local K_NUM: number = 1
local K_LOG: number = 2
local K_LAYER: number = 3
local K_LAYER_LOG: number = 4
local K_HYPER_LAYER: number = 5
local K_INF: number = 6
local K_NAN: number = 7
NanoNum.SUFFIX_VERSION = 7
NanoNum.ROMAN_VERSION = 2
NanoNum.TIME_VERSION = 4
NanoNum.UTILITY_FORMAT_VERSION = 11
NanoNum.FORMAT_SCOPE_VERSION = 15
NanoNum.UTILITY_SCOPE_VERSION = 2
NanoNum.PACK_SCOPE_VERSION = 3
NanoNum.LB_SCOPE_VERSION = 2
NanoNum.ROMAN_CLASSICAL_MAX = 3999
NanoNum.ROMAN_EXTENDED_MAX = SAFE_INTEGER
NanoNum.STANDARD_SUFFIX_MAX_INDEX = 999
NanoNum.HYBRID_STANDARD_MAX_INDEX = 101
NanoNum.METRIC_SUFFIX_MAX_INDEX = 10
NanoNum.DEFAULT_SUFFIX_TYPE = "standard"
NanoNum.DEFAULT_PRECISION = 2
NanoNum.MAX_PRECISION = 8
NanoNum.FORMAT_PRECISION_MODE = "decimal-places"
NanoNum.E_NOTATION_START = 3000
NanoNum.E_LAYER_TOP_MAX = NanoNum.STANDARD_SUFFIX_MAX_INDEX * 3 -- E-descriptor ceiling before true L2 display
NanoNum.SUFFIX_TYPES = {
	standard = true,
	extended = true,
	hybrid = true,
	alphabetic = true,
	metric = true,
	exponent = true,
	scientific = true,
	engineering = true,
	roman = true,
	romanextended = true,
}
local STANDARD_BEGINNING = {"k", "m", "b"}
local STANDARD_FIRST = {"", "U","D","T","Qd","Qn","Sx","Sp","Oc","No"}
local STANDARD_SECOND = {"", "De","Vt","Tg","qg","Qg","sg","Sg","Og","Ng"}
local STANDARD_THIRD = {"", "Ce", "Du","Tr","Qa","Qi","Se","Si","Ot","Ni"}
local STANDARD_SUFFIXES = tableCreate(NanoNum.STANDARD_SUFFIX_MAX_INDEX)
for index = 1, NanoNum.STANDARD_SUFFIX_MAX_INDEX do
	if index <= 3 then STANDARD_SUFFIXES[index] = STANDARD_BEGINNING[index]
	else
		local n = index - 1
		local hundred: number = floor(n / 100)
		local rem = n - hundred * 100
		local ten: number = floor(rem / 10)
		local one = rem - ten * 10
		STANDARD_SUFFIXES[index] = (STANDARD_FIRST[one + 1] or "") .. (STANDARD_SECOND[ten + 1] or "") .. (STANDARD_THIRD[hundred + 1] or "")
	end
end
local METRIC_SUFFIXES = {"k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q"}
local STANDARD_SUFFIX_TO_INDEX = {}
local METRIC_SUFFIX_TO_INDEX = {}
local STANDARD_SUFFIX_HASH = {}
local METRIC_SUFFIX_HASH = {}
local ALPHABETIC_SUFFIX_CACHE = {}
local function suffixHashLiteral(text: string): number
	local h = #text
	for i = 1, #text do h = (h * 131 + byte(text, i)) % 4294967291 end
	return h
end
for i, suffix in STANDARD_SUFFIXES do
	STANDARD_SUFFIX_TO_INDEX[suffix] = i
	STANDARD_SUFFIX_HASH[suffixHashLiteral(suffix)] = i
end
for i, suffix in METRIC_SUFFIXES do
	METRIC_SUFFIX_TO_INDEX[suffix] = i
	METRIC_SUFFIX_HASH[suffixHashLiteral(suffix)] = i
end
STANDARD_SUFFIX_TO_INDEX.K = 1
STANDARD_SUFFIX_TO_INDEX.M = 2
STANDARD_SUFFIX_TO_INDEX.B = 3
STANDARD_SUFFIX_TO_INDEX.t = 4
METRIC_SUFFIX_TO_INDEX.K = 1
local function bitsRequired(value: number): number
	if value <= 0 then return 0 end
	if value < 4294967296 then return 32 - countlz(value) end
	return 64 - countlz(floor(value / 4294967296))
end
local function isSafeInteger(value: number): boolean
	return value >= 0 and value <= SAFE_INTEGER and value == floor(value)
end
local function ceilBytes(bits: number): number
	return max(1, floor((bits + 7) / 8))
end
local function quantizeMantissa(mantissa: number, maxCode: number): number
	return clamp(floor(((mantissa - 1) / 9) * maxCode + 0.001), 0, maxCode)
end
local function decodeMantissa(code: number, maxCode: number): number
	return 1 + code / maxCode * 9
end
local function scalarExactBits(value: number): number
	if not isSafeInteger(value) then return huge end
	local n: number = bitsRequired(value)
	if n > 53 then return huge end
	return 1 + EXACT_LEN_BITS + n
end
local function scalarBits(value: number, exactSafe: boolean?, exactFloat: boolean?): number
	local exact: number = scalarExactBits(value)
	local limit = exactSafe and SCALAR_SAFE_EXACT_BITS or SCALAR_APPROX_BITS
	if exact <= limit then return exact end
	if exactFloat then return 71 end
	return SCALAR_APPROX_BITS
end
local function integerLengthFieldBits(bitLength: number): number
	if bitLength <= 31 then return INTEGER_LEN_BITS end
	return INTEGER_LEN_BITS + 5
end
local function exactIntegerRecordBits(value: number): number
	local magnitude: number = abs(value)
	if not isSafeInteger(magnitude) then return huge end
	local n: number = bitsRequired(magnitude)
	if n == 0 or n > MAX_INTEGER_MODE_BITS then return huge end
	return 3 + 1 + integerLengthFieldBits(n) + n
end
local function logRecordBits(exponentMagnitude: number): number
	-- K_LOG coordinates are correctness-critical: a tiny error in log10-space
	-- changes the visible mantissa by a multiplicative amount. Keep exact small
	-- integers compact, but store every lossy/fractional coordinate as f64.
	return 7 + scalarBits(exponentMagnitude, false, true)
end
-- Luau buffer.readbits/writebits support all 32 bits. Two chunks cover a 53-bit integer.
local function writeUIntExactAtFast(data: buffer, bitOffset: number, value: number, count: number)
	if count <= 32 then bufferWriteBits(data, bitOffset, count, value); return end
	bufferWriteBits(data, bitOffset, 32, value % 4294967296)
	bufferWriteBits(data, bitOffset + 32, count - 32, floor(value / 4294967296))
end
local function readUIntExactAtFast(data: buffer, bitOffset: number, count: number): number
	if count <= 32 then return bufferReadBits(data, bitOffset, count) end
	return bufferReadBits(data, bitOffset, 32) + bufferReadBits(data, bitOffset + 32, count - 32) * 4294967296
end
local function writeScalarAtFast(data: buffer, bitOffset: number, value: number, exactSafe: boolean?, exactFloat: boolean?)
	value = abs(value)
	local exactBits: number = scalarExactBits(value)
	local exactLimit = exactSafe and SCALAR_SAFE_EXACT_BITS or SCALAR_APPROX_BITS
	if exactBits <= exactLimit then
		local n: number = bitsRequired(value)
		bufferWriteBits(data, bitOffset, 7, n * 2)
		writeUIntExactAtFast(data, bitOffset + 7, value, n)
		return
	end
	if exactFloat then
		bufferWriteBits(data, bitOffset, 7, SCALAR_F64_SENTINEL)
		local payloadOffset = bitOffset + 7
		if band(payloadOffset, 7) == 0 then bufferWriteF64(data, payloadOffset / 8, value)
		else
			local temp: buffer = bufferCreate(8)
			bufferWriteF64(temp, 0, value)
			bufferWriteBits(data, payloadOffset, 32, bufferReadBits(temp, 0, 32))
			bufferWriteBits(data, payloadOffset + 32, 32, bufferReadBits(temp, 32, 32))
		end
		return
	end
	local lg: number = log10(value)
	local exponent: number = clamp(floor(lg), SCALAR_EXP_MIN, SCALAR_EXP_MAX)
	local mantissa = 10 ^ (lg - exponent)
	local mantCode = quantizeMantissa(mantissa, SCALAR_MANT_MAX)
	local expCode = exponent + SCALAR_EXP_BIAS
	local packed = 1 + expCode * 2 + mantCode * 2048
	bufferWriteBits(data, bitOffset, SCALAR_APPROX_BITS, packed)
end
local function readScalarAtFast(data: buffer, bitOffset: number): (number, number)
	local header: number = bufferReadBits(data, bitOffset, 7)
	if band(header, 1) == 0 then
		if header == SCALAR_F64_SENTINEL then
			local payloadOffset = bitOffset + 7
			local value
			if band(payloadOffset, 7) == 0 then value = bufferReadF64(data, payloadOffset / 8)
			else
				local temp: buffer = bufferCreate(8)
				bufferWriteBits(temp, 0, 32, bufferReadBits(data, payloadOffset, 32))
				bufferWriteBits(temp, 32, 32, bufferReadBits(data, payloadOffset + 32, 32))
				value = bufferReadF64(temp, 0)
			end
			if value ~= value or value < 0 or value == huge then error("NanoNum: invalid exact structural scalar") end
			return value, bitOffset + 71
		end
		local n: number = floor(header / 2)
		if n > 53 then error("NanoNum: invalid exact scalar bit length") end
		return readUIntExactAtFast(data, bitOffset + 7, n), bitOffset + 7 + n
	end
	local expCode: number = bufferReadBits(data, bitOffset + 1, SCALAR_EXP_BITS)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then error("NanoNum: invalid scalar exponent code") end
	local mantCode: number = bufferReadBits(data, bitOffset + 1 + SCALAR_EXP_BITS, SCALAR_MANT_BITS)
	local exponent = expCode - SCALAR_EXP_BIAS
	return decodeMantissa(mantCode, SCALAR_MANT_MAX) * (10 ^ exponent), bitOffset + SCALAR_APPROX_BITS
end
local function readExactF64At(data: buffer, bitOffset: number): number
	if band(bitOffset, 7) == 0 then
		return bufferReadF64(data, bitOffset / 8 + 1)
	end
	local temp: buffer = bufferCreate(8)
	bufferWriteBits(temp, 0, 32, bufferReadBits(data, bitOffset + 8, 32))
	bufferWriteBits(temp, 32, 32, bufferReadBits(data, bitOffset + 40, 32))
	return bufferReadF64(temp, 0)
end
local function makeSpecial(code: number): buffer
	local data: buffer = bufferCreate(1)
	bufferWriteU8(data, 0, 63 + code * 64)
	return data
end
local function isExactLogAt(data: buffer, bitOffset: number, limit: number?): boolean
	local endLimit = limit or bufferLen(data) * 8
	return bitOffset + 16 <= endLimit
		and bufferReadBits(data, bitOffset + 7, 7) == EXACT_LOG_SENTINEL
		and bufferReadBits(data, bitOffset + 14, 2) == 0
end
local function readExactLogMagnitudeAt(data: buffer, bitOffset: number): number
	local payloadOffset = bitOffset + 16
	if band(payloadOffset, 7) == 0 then return bufferReadF64(data, payloadOffset / 8) end
	local temp: buffer = bufferCreate(8)
	bufferWriteBits(temp, 0, 32, bufferReadBits(data, payloadOffset, 32))
	bufferWriteBits(temp, 32, 32, bufferReadBits(data, payloadOffset + 32, 32))
	return bufferReadF64(temp, 0)
end
local function makeLog(exponent: number, negative: boolean): buffer
	local reciprocal = exponent < 0
	local magnitude: number = abs(exponent)
	local header = 15 + (negative and 32 or 0) + (reciprocal and 64 or 0)
	-- v2.3.7: always use the scalar codec's lossless mode for K_LOG coordinates.
	-- writeScalarAtFast still keeps exact small integers compact, but fractional
	-- coordinates such as 1053 + log10(2) are encoded with SCALAR_F64_SENTINEL.
	-- This prevents the former 14-bit scalar path from turning 2e1053 into ~1.94e1053.
	local bits: number = logRecordBits(magnitude)
	local data: buffer = bufferCreate(ceilBytes(bits))
	bufferWriteBits(data, 0, 7, header)
	writeScalarAtFast(data, 7, magnitude, false, true)
	return data
end
local function layerFieldBits(layer: number, layerIsLog: boolean): number
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then return 6 end
	return 2 + scalarBits(layer, layerIsLog, true)
end
local function makeLayer(layer: number, top: number, negative: boolean, reciprocal: boolean, layerIsLog: boolean): buffer
	if top < 0 then top = 0 end
	if layerIsLog then
		layer = clamp(layer, 0, NanoNum.MAX_LAYER_LOG10)
	else
		layer = clamp(layer, 2, NanoNum.MAX_LAYER)
	end
	top = clamp(top, 0, 1e308)
	local bits = 8 + layerFieldBits(layer, layerIsLog) + scalarBits(top, false, true)
	local data: buffer = bufferCreate(ceilBytes(bits))
	bufferWriteU8(data, 0, 31 + (negative and 64 or 0) + (reciprocal and 128 or 0))
	local bitOffset: number = 8
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then
		bufferWriteBits(data, bitOffset, 6, (layer - 2) * 2)
		bitOffset += 6
	else
		bufferWriteBits(data, bitOffset, 2, 1 + (layerIsLog and 2 or 0))
		bitOffset += 2
		writeScalarAtFast(data, bitOffset, layer, layerIsLog, true)
		bitOffset += scalarBits(layer, layerIsLog, true)
	end
	writeScalarAtFast(data, bitOffset, top, false, true)
	return data
end
local function makeHyperLayer(layerLog10Log10: number, top: number, negative: boolean, reciprocal: boolean): buffer
	if top < 0 then top = 0 end
	layerLog10Log10 = clamp(layerLog10Log10, 0, NanoNum.MAX_LAYER_LOG10_LOG10)
	top = clamp(top, 0, 1e308)
	local hyperBits: number = scalarBits(layerLog10Log10, true, true)
	local bits = 8 + hyperBits + scalarBits(top, false, true)
	local data: buffer = bufferCreate(ceilBytes(bits))
	bufferWriteU8(data, 0, HYPER_LAYER_PREFIX + (negative and 32 or 0) + (reciprocal and 64 or 0))
	writeScalarAtFast(data, 8, layerLog10Log10, true, true)
	writeScalarAtFast(data, 8 + hyperBits, top, false, true)
	return data
end
local function readLayerFieldAtFast(data: buffer, bitOffset: number): (number, boolean, number)
	if bufferReadBits(data, bitOffset, 1) == 0 then
		return bufferReadBits(data, bitOffset + 1, 5) + 2, false, bitOffset + 6
	end
	local layerIsLog = bufferReadBits(data, bitOffset + 1, 1) == 1
	local layer, nextBit = readScalarAtFast(data, bitOffset + 2)
	return layer, layerIsLog, nextBit
end
local function normalizeLayerInput(layer: number, top: number, layerIsLog: boolean): (number, number, boolean)
	if layerIsLog and layer <= DIRECT_LAYER_LOG10_MAX then
		layer = 10 ^ layer
		if layer < 2 then layer = 2 end
		if layer > NanoNum.MAX_LAYER then layer = NanoNum.MAX_LAYER end
		layerIsLog = false
	end
	if not layerIsLog then
		if layer < 0 then layer = 0 end
		layer = floor(layer + 0.001)
		while layer >= 2 and top <= DIRECT_LOG_MAX and layer <= SAFE_INTEGER do
			top = top < -324 and 0 or 10 ^ top
			layer -= 1
		end
	end
	return layer, top, layerIsLog
end
function NanoNum.fromNumber(value: number): buffer
	if value ~= value then local data: buffer = bufferCreate(1); bufferWriteU8(data, 0, 191); return data end
	if value == huge then local data: buffer = bufferCreate(1); bufferWriteU8(data, 0, 63); return data end
	if value == -huge then local data: buffer = bufferCreate(1); bufferWriteU8(data, 0, 127); return data end
	local integral: number = floor(value)
	if value == integral then
		if value >= 0 and value <= 127 then
			local data: buffer = bufferCreate(1); bufferWriteU8(data, 0, value * 2); return data
		end
		if value < 0 and value >= -64 then
			local data: buffer = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-value - 1) * 4); return data
		end
		local negative = value < 0
		local magnitude = negative and -value or value
		if magnitude <= SAFE_INTEGER then
			local n: number = magnitude < 4294967296 and (32 - countlz(magnitude)) or (64 - countlz(floor(magnitude / 4294967296)))
			if n <= 31 then
				local bits = 9 + n
				local data: buffer = bufferCreate(floor((bits + 7) / 8))
				local header = 3 + (negative and 8 or 0) + n * 16
				if bits <= 32 then
					bufferWriteBits(data, 0, bits, header + magnitude * 512)
				else
					bufferWriteBits(data, 0, 9, header)
					bufferWriteBits(data, 9, n, magnitude)
				end
				return data
			end
			local bits = 14 + n
			local data: buffer = bufferCreate(floor((bits + 7) / 8))
			bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
			bufferWriteBits(data, 14, 32, magnitude % 4294967296)
			bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
			return data
		end
	end
	local data: buffer = bufferCreate(EXACT_F64_BYTES)
	bufferWriteU8(data, 0, 255)
	bufferWriteF64(data, 1, value)
	return data
end
local encodeNumber: (number) -> buffer = NanoNum.fromNumber
function NanoNum.fromLog10(exponent: number, negative: boolean?): buffer
	if exponent ~= exponent then local data = bufferCreate(1); bufferWriteU8(data, 0, 191); return data end
	if exponent == huge then local data = bufferCreate(1); bufferWriteU8(data, 0, negative and 127 or 63); return data end
	if exponent == -huge then local data = bufferCreate(1); bufferWriteU8(data, 0, 0); return data end
	if exponent == 0 then local data = bufferCreate(1); bufferWriteU8(data, 0, negative and 1 or 2); return data end
	if exponent >= DIRECT_LOG_MIN and exponent <= DIRECT_LOG_MAX then
		local magnitude = 10 ^ exponent
		if magnitude ~= 0 and magnitude ~= huge then return NanoNum.fromNumber(negative and -magnitude or magnitude) end
	end
	return makeLog(exponent, negative == true)
end
function NanoNum.fromLayer(layer: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layer ~= layer or top ~= top then return makeSpecial(SPECIAL_NAN) end
	if top == huge then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if layer == huge then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if layer > NanoNum.MAX_LAYER then return NanoNum.fromLayerLog10(log10(layer), top, negative, reciprocal) end
	local normalizedLayer, normalizedTop = normalizeLayerInput(layer, top, false)
	if normalizedLayer <= 0 then
		local value = normalizedTop
		if reciprocal then
			if value == 0 then return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
			local inverse = 1 / value
			if inverse == huge or inverse == -huge then return NanoNum.fromLog10(-log10(abs(value)), (value < 0) ~= (negative == true)) end
			value = inverse
		end
		if negative then value = -value end
		return NanoNum.fromNumber(value)
	end
	if normalizedLayer < 2 then
		return NanoNum.fromLog10(reciprocal and -normalizedTop or normalizedTop, negative)
	end
	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, false)
end
function NanoNum.fromLayerLog10(layerLog10: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layerLog10 ~= layerLog10 or top ~= top then return makeSpecial(SPECIAL_NAN) end
	if top == huge then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if layerLog10 == huge then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if layerLog10 > NanoNum.MAX_LAYER_LOG10 then return NanoNum.fromLayerLog10Log10(log10(layerLog10), top, negative, reciprocal) end
	local normalizedLayer, normalizedTop, layerIsLog = normalizeLayerInput(max(layerLog10, 0), top, true)
	if not layerIsLog then return NanoNum.fromLayer(normalizedLayer, normalizedTop, negative, reciprocal) end
	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, true)
end
function NanoNum.fromLayerLog10Log10(layerLog10Log10: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layerLog10Log10 ~= layerLog10Log10 or top ~= top then return makeSpecial(SPECIAL_NAN) end
	if top == huge then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if layerLog10Log10 == huge or layerLog10Log10 > NanoNum.MAX_LAYER_LOG10_LOG10 then return reciprocal and NanoNum.fromNumber(0) or makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	layerLog10Log10 = max(layerLog10Log10, 0)
	if layerLog10Log10 <= DIRECT_LAYER_LOG10_MAX then
		local layerLog10 = 10 ^ layerLog10Log10
		if layerLog10 ~= huge then return NanoNum.fromLayerLog10(layerLog10, top, negative, reciprocal) end
	end
	return makeHyperLayer(layerLog10Log10, top, negative == true, reciprocal == true)
end
NanoNum.fromHyperLayerLog10 = NanoNum.fromLayerLog10Log10
local function normalizeSuffixType(suffixType: string?): string
	if suffixType == nil then return NanoNum.DEFAULT_SUFFIX_TYPE end
	if NanoNum.SUFFIX_TYPES[suffixType] then return suffixType end
	local kind = lower(suffixType)
	if NanoNum.SUFFIX_TYPES[kind] then return kind end
	return NanoNum.DEFAULT_SUFFIX_TYPE
end
local function alphabeticSuffix(index: number): string?
	if index < 1 or index ~= floor(index) or index > SAFE_INTEGER then return nil end
	local cached = ALPHABETIC_SUFFIX_CACHE[index]
	if cached ~= nil then return cached end
	local n = index - 1
	local length: number = 2
	local block = 26 ^ length
	while n >= block do
		n -= block
		length += 1
		if length > 11 then return nil end
		block = 26 ^ length
	end
	local chars = tableCreate(length, "a")
	for pos = length, 1, -1 do
		local digit = n % 26
		chars[pos] = char(97 + digit)
		n = floor(n / 26)
	end
	local result = concat(chars)
	if index <= 4096 then ALPHABETIC_SUFFIX_CACHE[index] = result end
	return result
end
local function alphabeticSuffixIndex(suffix: string): number?
	local text = lower(suffix)
	local length = #text
	if length < 2 or length > 11 then return nil end
	local n: number = 0
	for i = 1, length do
		local c = byte(text, i)
		if c < 97 or c > 122 then return nil end
		n = n * 26 + c - 97
	end
	local offset: number = 0
	for l = 2, length - 1 do
		offset += 26 ^ l
	end
	local index = offset + n + 1
	if index > SAFE_INTEGER then return nil end
	return index
end
local function suffixForIndex(index: number, suffixType: string): string?
	if index < 1 or index ~= floor(index) then return nil end
	if suffixType == "standard" then return STANDARD_SUFFIXES[index] end
	if suffixType == "metric" then return METRIC_SUFFIXES[index] end
	if suffixType == "alphabetic" then return alphabeticSuffix(index) end
	if suffixType == "extended" then
		if index <= NanoNum.STANDARD_SUFFIX_MAX_INDEX then return STANDARD_SUFFIXES[index] end
		if index < 1000 then return alphabeticSuffix(index - NanoNum.STANDARD_SUFFIX_MAX_INDEX) end
		return nil
	end
	if suffixType == "hybrid" then
		if index <= NanoNum.HYBRID_STANDARD_MAX_INDEX then return STANDARD_SUFFIXES[index] end
		return alphabeticSuffix(index - NanoNum.HYBRID_STANDARD_MAX_INDEX)
	end
	return nil
end
function NanoNum.isSuffixType(suffixType: string): boolean
	return NanoNum.SUFFIX_TYPES[suffixType] == true or NanoNum.SUFFIX_TYPES[lower(suffixType)] == true
end
function NanoNum.setDefaultSuffixType(suffixType: string): boolean
	local kind = normalizeSuffixType(suffixType)
	if NanoNum.SUFFIX_TYPES[kind] ~= true then return false end
	NanoNum.DEFAULT_SUFFIX_TYPE = kind
	return true
end
function NanoNum.getSuffix(index: number, suffixType: string?): string?
	return suffixForIndex(floor(index), normalizeSuffixType(suffixType))
end
function NanoNum.suffixIndex(suffix: string, suffixType: string?): number?
	local kind = normalizeSuffixType(suffixType)
	if kind == "standard" then return STANDARD_SUFFIX_TO_INDEX[suffix] end
	if kind == "metric" then return METRIC_SUFFIX_TO_INDEX[suffix] end
	if kind == "alphabetic" then return alphabeticSuffixIndex(suffix) end
	if kind == "extended" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then return standard end
		local alpha = alphabeticSuffixIndex(suffix)
		if alpha == nil then return nil end
		local index = alpha + NanoNum.STANDARD_SUFFIX_MAX_INDEX
		if index >= 1000 then return nil end
		return index
	end
	if kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil and standard <= NanoNum.HYBRID_STANDARD_MAX_INDEX then return standard end
		local alpha = alphabeticSuffixIndex(suffix)
		if alpha == nil then return nil end
		return alpha + NanoNum.HYBRID_STANDARD_MAX_INDEX
	end
	return nil
end
-- Parser internals use a dedicated function frame to stay below Luau's local-register ceiling.
(function()
	local function isSpaceByte(c: number): boolean
		return c == 32 or c == 9 or c == 10 or c == 13
	end
	local function trimRange(text: string, first: number, last: number): (number, number)
		while first <= last and isSpaceByte(byte(text, first)) do first += 1 end
		while last >= first and isSpaceByte(byte(text, last)) do last -= 1 end
		return first, last
	end
	local function rangeEqualsCI(text: string, first: number, last: number, literal: string): boolean
		local n = last - first + 1
		if n ~= #literal then return false end
		for i = 1, n do
			local a = byte(text, first + i - 1)
			local b = byte(literal, i)
			if a >= 65 and a <= 90 then a += 32 end
			if b >= 65 and b <= 90 then b += 32 end
			if a ~= b then return false end
		end
		return true
	end
	local function rangeEquals(text: string, first: number, last: number, literal: string): boolean
		local n = last - first + 1
		if n ~= #literal then return false end
		for i = 1, n do
			if byte(text, first + i - 1) ~= byte(literal, i) then return false end
		end
		return true
	end
	local function parsePlainRange(text: string, first: number, last: number): number?
		if first > last then return nil end
		local negative: boolean = false
		local c = byte(text, first)
		if c == 45 then negative = true; first += 1
		elseif c == 43 then first += 1 end
		if first > last then return nil end
		local sawDigit: boolean = false
		local sawDot: boolean = false
		local grouped: boolean = false
		local groupDigits: number = 0
		for i = first, last do
			c = byte(text, i)
			if c >= 48 and c <= 57 then
				sawDigit = true
				if not sawDot then groupDigits += 1 end
			elseif c == 44 then
				-- Commas are grouping separators, not ignorable characters. Reject 1,2 / 12,34 / 1,234.5,6.
				if sawDot or groupDigits == 0 then return nil end
				if grouped then
					if groupDigits ~= 3 then return nil end
				else
					if groupDigits > 3 then return nil end
					grouped = true
				end
				groupDigits = 0
			elseif c == 46 and not sawDot then
				if grouped and groupDigits ~= 3 then return nil end
				sawDot = true
			else
				return nil
			end
		end
		if not sawDigit then return nil end
		if grouped and not sawDot and groupDigits ~= 3 then return nil end
		local textValue = sub(text, first, last)
		if grouped then textValue = gsub(textValue, ",", "") end
		local parsed = toNumber(textValue)
		if parsed == nil then return nil end
		return negative and -parsed or parsed
	end
	local function parsePositiveIntegerDescriptor(text: string, first: number, last: number): (number?, number?, boolean)
		if first > last then return nil, nil, false end
		local value: number = 0
		local overflow: boolean = false
		local significantDigits: number = 0
		local leading: number = 0
		local leadingDigits: number = 0
		local seenNonZero: boolean = false
		local sawDigit: boolean = false
		local grouped: boolean = false
		local groupDigits: number = 0
		for i = first, last do
			local c = byte(text, i)
			if c >= 48 and c <= 57 then
				local digit = c - 48
				sawDigit = true
				groupDigits += 1
				if digit ~= 0 or seenNonZero then
					seenNonZero = true
					significantDigits += 1
					if leadingDigits < 15 then
						leading = leading * 10 + digit
						leadingDigits += 1
					end
				end
				if not overflow then
					value = value * 10 + digit
					if value == huge then overflow = true end
				end
			elseif c == 44 then
				if groupDigits == 0 then return nil, nil, false end
				if grouped then
					if groupDigits ~= 3 then return nil, nil, false end
				else
					if groupDigits > 3 then return nil, nil, false end
					grouped = true
				end
				groupDigits = 0
			else
				return nil, nil, false
			end
		end
		if not sawDigit or (grouped and groupDigits ~= 3) then return nil, nil, false end
		if not seenNonZero then return 0, -huge, true end
		local lg = log10(leading) + significantDigits - leadingDigits
		if overflow then return nil, lg, true end
		return value, lg, true
	end
	local function suffixRangeIndex(text: string, first: number, last: number, list, hashMap): number?
		if list == STANDARD_SUFFIXES and last == first then
			local c = byte(text, first)
			if c == 75 or c == 107 then return 1 elseif c == 77 or c == 109 then return 2 elseif c == 66 or c == 98 then return 3 elseif c == 84 or c == 116 then return 4 end
		elseif last == first and (byte(text, first) == 75 or byte(text, first) == 107) then return 1 end
		local h = last - first + 1
		for i = first, last do h = (h * 131 + byte(text, i)) % 4294967291 end
		local index = hashMap[h]
		if index ~= nil and rangeEquals(text, first, last, list[index]) then return index end
		return nil
	end
	local function alphabeticRangeIndex(text: string, first: number, last: number): number?
		local length = last - first + 1
		if length < 2 or length > 11 then return nil end
		local n: number = 0
		for i = first, last do
			local c = byte(text, i)
			if c >= 65 and c <= 90 then c += 32 end
			if c < 97 or c > 122 then return nil end
			n = n * 26 + c - 97
		end
		local offset: number = 0
		local power: number = 676
		for _ = 2, length - 1 do offset += power; power *= 26 end
		local index = offset + n + 1
		return index <= SAFE_INTEGER and index or nil
	end
	local function parseCanonicalScalarRange(text: string, first: number, last: number): number?
		first, last = trimRange(text, first, last)
		if first > last then return nil end
		local plain = parsePlainRange(text, first, last)
		if plain ~= nil and plain == plain and plain ~= huge and plain ~= -huge then return plain end
		local direct = toNumber(sub(text, first, last))
		if direct ~= nil and direct == direct and direct ~= huge and direct ~= -huge then return direct end
		return nil
	end
	local function parseDisplayScalarRange(text: string, first: number, last: number, suffixType: string?): number?
		first, last = trimRange(text, first, last)
		if first > last then return nil end
		local plain = parseCanonicalScalarRange(text, first, last)
		if plain ~= nil then return plain end
		local suffixStart: number = 0
		for i = first + 1, last do
			local c = byte(text, i)
			if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then suffixStart = i; break end
		end
		if suffixStart == 0 then return nil end
		local mantissa = parsePlainRange(text, first, suffixStart - 1)
		if mantissa == nil or mantissa ~= mantissa or mantissa == huge or mantissa == -huge then return nil end
		local kind = normalizeSuffixType(suffixType)
		local index
		if kind == "metric" then
			index = suffixRangeIndex(text, suffixStart, last, METRIC_SUFFIXES, METRIC_SUFFIX_HASH)
		elseif kind == "alphabetic" then
			index = alphabeticRangeIndex(text, suffixStart, last)
		else
			index = suffixRangeIndex(text, suffixStart, last, STANDARD_SUFFIXES, STANDARD_SUFFIX_HASH)
			if kind == "hybrid" and index ~= nil and index > NanoNum.HYBRID_STANDARD_MAX_INDEX then index = nil end
			if index == nil and (kind == "extended" or kind == "hybrid") then
				local alpha = alphabeticRangeIndex(text, suffixStart, last)
				if alpha ~= nil then
					index = alpha + (kind == "hybrid" and NanoNum.HYBRID_STANDARD_MAX_INDEX or NanoNum.STANDARD_SUFFIX_MAX_INDEX)
					if kind == "extended" and index >= 1000 then index = nil end
				end
			end
		end
		if index == nil then return nil end
		local exponent = index * 3
		if exponent > 308 then return nil end
		local result = mantissa * 10 ^ exponent
		if result ~= result or result == huge or result == -huge then return nil end
		return result
	end
	-- Returns mode 0=direct layer count, 1=log10(layer), 2=log10(log10(layer)).
	local function parseLayerCountRange(text: string, first: number, last: number): (number?, number?, boolean)
		first, last = trimRange(text, first, last)
		if first > last then return nil, nil, false end
		local direct = parsePlainRange(text, first, last)
		if direct ~= nil and direct == direct and direct ~= huge and direct ~= -huge and direct >= 0 then return 0, direct, true end
		local ePos: number = 0
		for i = first + 1, last do
			local c = byte(text, i)
			if c == 101 or c == 69 then ePos = i; break end
		end
		if ePos == 0 then return nil, nil, false end
		local mantissa = parsePlainRange(text, first, ePos - 1)
		if mantissa == nil or mantissa <= 0 or mantissa == huge then return nil, nil, false end
		local expFirst = ePos + 1
		if expFirst > last then return nil, nil, false end
		-- Nested scientific layer counts such as 1e1e3000 promote directly to hyper-layer.
		if expFirst + 1 <= last and byte(text, expFirst) == 49 and (byte(text, expFirst + 1) == 101 or byte(text, expFirst + 1) == 69) then
			local nested, _, valid = parsePositiveIntegerDescriptor(text, expFirst + 2, last)
			if valid and nested ~= nil then return 2, clamp(nested, 0, NanoNum.MAX_LAYER_LOG10_LOG10), true end
		end
		local exponentNegative: boolean = false
		local c = byte(text, expFirst)
		if c == 45 then exponentNegative = true; expFirst += 1
		elseif c == 43 then expFirst += 1 end
		if exponentNegative then return nil, nil, false end
		local exponent, exponentLog10, valid = parsePositiveIntegerDescriptor(text, expFirst, last)
		if not valid then return nil, nil, false end
		if exponent ~= nil then
			local layerLog10 = exponent + log10(mantissa)
			if layerLog10 <= NanoNum.MAX_LAYER_LOG10 then return 1, max(0, layerLog10), true end
			return 2, min(log10(layerLog10), NanoNum.MAX_LAYER_LOG10_LOG10), true
		end
		if exponentLog10 == nil or exponentLog10 ~= exponentLog10 then return nil, nil, false end
		return 2, min(max(exponentLog10, 0), NanoNum.MAX_LAYER_LOG10_LOG10), true
	end
	local parseStringRange: (string, number, number, SuffixName?) -> buffer
	local function finishParsed(result: buffer, negative: boolean, reciprocal: boolean): buffer
		if reciprocal then result = NanoNum.reciprocal(result) end
		if negative then result = NanoNum.neg(result) end
		return result
	end
	parseStringRange = function(text: string, first: number, last: number, suffixType: SuffixName?): buffer
		first, last = trimRange(text, first, last)
		if first > last then return makeSpecial(SPECIAL_NAN) end
		local negative: boolean = false
		local reciprocal: boolean = false
		local c = byte(text, first)
		if c == 45 then negative = true; first += 1
		elseif c == 43 then first += 1 end
		if first > last then return makeSpecial(SPECIAL_NAN) end
		if first + 1 <= last and byte(text, first) == 49 and byte(text, first + 1) == 47 then
			reciprocal = true
			first += 2
			if first > last then return makeSpecial(SPECIAL_NAN) end
		end
		first, last = trimRange(text, first, last)
		if first > last then return makeSpecial(SPECIAL_NAN) end
		-- One sign is consumed above. A second sign here is malformed input, not another negation.
		c = byte(text, first)
		if c == 43 or c == 45 then return makeSpecial(SPECIAL_NAN) end
		if rangeEqualsCI(text, first, last, "nan") then return makeSpecial(SPECIAL_NAN) end
		if rangeEqualsCI(text, first, last, "inf") or rangeEqualsCI(text, first, last, "infinity") then
			local result = makeSpecial(SPECIAL_POS_INF)
			return finishParsed(result, negative, reciprocal)
		end
		-- NanoNum EN extensions preserve values whose EN layer cannot fit in a Lua number.
		local extensionMode: number = 0
		local extensionFirst: number = 0
		if first + 4 <= last and (byte(text, first) == 69 or byte(text, first) == 101) and (byte(text, first + 1) == 78 or byte(text, first + 1) == 110) and (byte(text, first + 2) == 76 or byte(text, first + 2) == 108) then
			if (byte(text, first + 3) == 76 or byte(text, first + 3) == 108) and byte(text, first + 4) == 59 then extensionMode = 2; extensionFirst = first + 5
			elseif byte(text, first + 3) == 59 then extensionMode = 1; extensionFirst = first + 4 end
		end
		if extensionMode ~= 0 and extensionFirst <= last then
			local semi: number = 0
			for i = extensionFirst, last do if byte(text, i) == 59 then if semi ~= 0 then semi = -1; break end; semi = i end end
			if semi > extensionFirst and semi < last then
				local descriptor = parseCanonicalScalarRange(text, extensionFirst, semi - 1)
				local top = parseCanonicalScalarRange(text, semi + 1, last)
				if descriptor ~= nil and top ~= nil and descriptor >= 0 then
					local result = extensionMode == 1 and NanoNum.fromLayerLog10(descriptor, abs(top), false, top < 0) or NanoNum.fromLayerLog10Log10(descriptor, abs(top), false, top < 0)
					return finishParsed(result, negative, reciprocal)
				end
			end
		end
		-- EternityNum canonical serialization: layer;exponent (for example 2;20 or -0;5).
		local semi: number = 0
		for i = first, last do if byte(text, i) == 59 then if semi ~= 0 then semi = -1; break end; semi = i end end
		if semi > first and semi < last then
			local layer = parseCanonicalScalarRange(text, first, semi - 1)
			local top = parseCanonicalScalarRange(text, semi + 1, last)
			if layer ~= nil and top ~= nil and layer >= 0 and layer == floor(layer) then
				local result
				if layer == 0 then result = NanoNum.fromNumber(top)
				elseif layer == 1 then result = NanoNum.fromLog10(top)
				else result = NanoNum.fromLayer(layer, abs(top), false, top < 0) end
				return finishParsed(result, negative, reciprocal)
			end
		end
		-- 10^(...) recursive power syntax. No substring is allocated: only the index range changes.
		if first + 2 <= last and byte(text, first) == 49 and byte(text, first + 1) == 48 then
			local p = first + 2
			while p <= last and isSpaceByte(byte(text, p)) do p += 1 end
			if p <= last and byte(text, p) == 94 then
				p += 1
				while p <= last and isSpaceByte(byte(text, p)) do p += 1 end
				local exponentFirst, exponentLast = p, last
				if p <= last and byte(text, p) == 40 and byte(text, last) == 41 then
					local depth: number = 0
					local wraps: boolean = true
					for i = p, last do
						local ch = byte(text, i)
						if ch == 40 then depth += 1
						elseif ch == 41 then
							depth -= 1
							if depth < 0 or (depth == 0 and i < last) then wraps = false; break end
						end
					end
					if wraps and depth == 0 then exponentFirst = p + 1; exponentLast = last - 1 end
				end
				if exponentFirst <= exponentLast then
					local exponentValue = parseStringRange(text, exponentFirst, exponentLast, suffixType)
					return finishParsed(NanoNum.pow10(exponentValue), negative, reciprocal)
				end
			end
		end
		c = byte(text, first)
		if c == 108 or c == 76 then
			local p = first + 1
			while p <= last and isSpaceByte(byte(text, p)) do p += 1 end
			-- Legacy explicit L(10^x) top remains readable.
			if p <= last and byte(text, p) == 40 then
				local close = p + 1
				local depth: number = 1
				while close <= last and depth > 0 do
					local ch = byte(text, close)
					if ch == 40 then depth += 1 elseif ch == 41 then depth -= 1 end
					close += 1
				end
				if depth == 0 then
					local insideFirst = p + 1
					local insideLast = close - 2
					local q = insideFirst
					if q + 2 <= insideLast and byte(text, q) == 49 and byte(text, q + 1) == 48 and byte(text, q + 2) == 94 then
						q += 3
						if q <= insideLast and byte(text, q) == 40 and byte(text, insideLast) == 41 then q += 1; insideLast -= 1 end
						local layerExponent = parseDisplayScalarRange(text, q, insideLast, suffixType)
						local topFirst = close
						while topFirst <= last and isSpaceByte(byte(text, topFirst)) do topFirst += 1 end
						local top = parseDisplayScalarRange(text, topFirst, last, suffixType)
						if layerExponent ~= nil and top ~= nil then return finishParsed(NanoNum.fromLayerLog10(layerExponent, top), negative, reciprocal) end
					end
				end
			end
			local tokenFirst = p
			while p <= last and not isSpaceByte(byte(text, p)) do p += 1 end
			local tokenLast = p - 1
			while p <= last and isSpaceByte(byte(text, p)) do p += 1 end
			if tokenFirst <= tokenLast then
				if p <= last then
					local top = parseDisplayScalarRange(text, p, last, suffixType)
					if top ~= nil then
						local firstCode = byte(text, tokenFirst)
						local secondCode = tokenFirst + 1 <= tokenLast and byte(text, tokenFirst + 1) or 0
						if (firstCode == 101 or firstCode == 69) and (secondCode == 101 or secondCode == 69) then
							local descriptor = parseDisplayScalarRange(text, tokenFirst + 2, tokenLast, suffixType)
							if descriptor ~= nil and descriptor >= 0 then return finishParsed(NanoNum.fromLayerLog10Log10(descriptor, top), negative, reciprocal) end
						elseif firstCode == 101 or firstCode == 69 then
							local descriptor = parseDisplayScalarRange(text, tokenFirst + 1, tokenLast, suffixType)
							if descriptor ~= nil and descriptor >= 0 then return finishParsed(NanoNum.fromLayerLog10(descriptor, top), negative, reciprocal) end
						else
							local layer = parseDisplayScalarRange(text, tokenFirst, tokenLast, suffixType)
							if layer ~= nil and layer >= 0 then return finishParsed(NanoNum.fromLayer(layer, top), negative, reciprocal) end
							local mode, descriptor, valid = parseLayerCountRange(text, tokenFirst, tokenLast)
							if valid and descriptor ~= nil then
								if mode == 2 then return finishParsed(NanoNum.fromLayerLog10Log10(descriptor, top), negative, reciprocal) end
								if mode == 1 then return finishParsed(NanoNum.fromLayerLog10(descriptor, top), negative, reciprocal) end
								return finishParsed(NanoNum.fromLayer(descriptor, top), negative, reciprocal)
							end
						end
					end
					-- Read legacy v2.1.0-v2.1.2 top-first L<top> E<descriptor> / EE<descriptor> strings.
					local legacyTop = parseDisplayScalarRange(text, tokenFirst, tokenLast, suffixType)
					if legacyTop ~= nil then
						local firstDepth = byte(text, p)
						local secondDepth = p + 1 <= last and byte(text, p + 1) or 0
						if (firstDepth == 101 or firstDepth == 69) and (secondDepth == 101 or secondDepth == 69) then
							local descriptor = parseDisplayScalarRange(text, p + 2, last, suffixType)
							if descriptor ~= nil then return finishParsed(NanoNum.fromLayerLog10Log10(descriptor, legacyTop), negative, reciprocal) end
						elseif firstDepth == 101 or firstDepth == 69 then
							local descriptor = parseDisplayScalarRange(text, p + 1, last, suffixType)
							if descriptor ~= nil then return finishParsed(NanoNum.fromLayerLog10(descriptor, legacyTop), negative, reciprocal) end
						end
					end
				else
					-- Legacy shorthand L<top> remains readable as layer 2, but is never emitted.
					local legacyTop = parseDisplayScalarRange(text, tokenFirst, tokenLast, suffixType)
					if legacyTop ~= nil then return finishParsed(NanoNum.fromLayer(2, legacyTop), negative, reciprocal) end
				end
			end
		end
		-- EternityNum clean layer notation: E(layer)top.
		if (c == 101 or c == 69) and first + 3 <= last and byte(text, first + 1) == 40 then
			local close = first + 2
			while close <= last and byte(text, close) ~= 41 do close += 1 end
			if close < last then
				local layer = parsePlainRange(text, first + 2, close - 1)
				local top = parsePlainRange(text, close + 1, last)
				if layer ~= nil and top ~= nil and layer >= 1 and layer == floor(layer) then
					return finishParsed(NanoNum.fromLayer(layer, abs(top), false, top < 0), negative, reciprocal)
				end
			end
		end
		-- E/EE/EEE parser. E3k -> 10^3000, EE3k -> 10^(10^3000).
		if c == 101 or c == 69 then
			local p = first
			local repeated: number = 0
			while p <= last and (byte(text, p) == 101 or byte(text, p) == 69) do repeated += 1; p += 1 end
			if repeated == 1 and p <= last and byte(text, p) == 94 then
				p += 1
				local tokenFirst = p
				while p <= last and not isSpaceByte(byte(text, p)) do p += 1 end
				local tokenLast = p - 1
				while p <= last and isSpaceByte(byte(text, p)) do p += 1 end
				if tokenFirst <= tokenLast and p <= last then
					local mode, descriptor, valid = parseLayerCountRange(text, tokenFirst, tokenLast)
					local top = parseDisplayScalarRange(text, p, last, suffixType)
					if valid and descriptor ~= nil and top ~= nil then
						if mode == 2 then return finishParsed(NanoNum.fromLayerLog10Log10(descriptor, top), negative, reciprocal) end
						if mode == 1 then return finishParsed(NanoNum.fromLayerLog10(descriptor, top), negative, reciprocal) end
						return finishParsed(NanoNum.fromLayer(descriptor, top), negative, reciprocal)
					end
				end
			end
			if repeated > 0 and p <= last then
				local seed = parseStringRange(text, p, last, suffixType)
				local result = NanoNum.iteratedExp10(seed, repeated)
				return finishParsed(result, negative, reciprocal)
			end
		end
		-- Scientific decimal path. The exponent is scanned in-place and can promote into layer space.
		local ePos: number = 0
		for i = first + 1, last do
			local ch = byte(text, i)
			if ch == 101 or ch == 69 then ePos = i; break end
			if (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) then break end
		end
		if ePos > first and ePos < last then
			local mantissa = parsePlainRange(text, first, ePos - 1)
			if mantissa ~= nil and mantissa == mantissa and mantissa ~= huge and mantissa ~= -huge then
				local expFirst = ePos + 1
				local exponentNegative: boolean = false
				local ch = byte(text, expFirst)
				if ch == 45 then exponentNegative = true; expFirst += 1 elseif ch == 43 then expFirst += 1 end
				-- Never accept a second exponent sign: 1e--3 / 1e+-3 must be NaN, not a different value.
				local exponentSignValid = expFirst <= last and byte(text, expFirst) ~= 43 and byte(text, expFirst) ~= 45
				if exponentSignValid then
					-- Grouped/fractional E exponents are valid display input too:
					-- 1.23E3,000.03 round-trips through fromString.
					local directExponent = parsePlainRange(text, expFirst, last)
					if directExponent ~= nil and directExponent == directExponent and directExponent ~= huge and directExponent ~= -huge then
						if mantissa == 0 then return finishParsed(NanoNum.fromNumber(0), negative, reciprocal) end
						if exponentNegative then directExponent = -directExponent end
						local totalLog = directExponent + log10(abs(mantissa))
						local result = NanoNum.fromLog10(totalLog, mantissa < 0)
						return finishParsed(result, negative, reciprocal)
					end
					local exponent, exponentLog10, valid = parsePositiveIntegerDescriptor(text, expFirst, last)
					if valid then
						if mantissa == 0 then return finishParsed(NanoNum.fromNumber(0), negative, reciprocal) end
						if exponent ~= nil then
							if exponentNegative then exponent = -exponent end
							local totalLog = exponent + log10(abs(mantissa))
							local result = NanoNum.fromLog10(totalLog, mantissa < 0)
							return finishParsed(result, negative, reciprocal)
						end
						if exponentLog10 ~= nil then
							local result = NanoNum.fromLayer(2, exponentLog10, mantissa < 0, exponentNegative)
							return finishParsed(result, negative, reciprocal)
						end
					end
				end
			end
		end
		local plain = parsePlainRange(text, first, last)
		if plain ~= nil and plain == plain and plain ~= huge and plain ~= -huge then return finishParsed(NanoNum.fromNumber(plain), negative, reciprocal) end
		-- Suffix path, also range-based: no substring allocation.
		local suffixStart: number = 0
		for i = first + 1, last do
			local ch = byte(text, i)
			if (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) then suffixStart = i; break end
		end
		if suffixStart > first then
			local mantissa = parsePlainRange(text, first, suffixStart - 1)
			if mantissa ~= nil and mantissa > 0 and mantissa ~= huge then
				local kind = normalizeSuffixType(suffixType)
				if kind ~= "scientific" and kind ~= "engineering" and kind ~= "exponent" and kind ~= "roman" and kind ~= "romanextended" then
					local index
					if kind == "metric" then index = suffixRangeIndex(text, suffixStart, last, METRIC_SUFFIXES, METRIC_SUFFIX_HASH)
					elseif kind == "alphabetic" then index = alphabeticRangeIndex(text, suffixStart, last)
					else
						index = suffixRangeIndex(text, suffixStart, last, STANDARD_SUFFIXES, STANDARD_SUFFIX_HASH)
						if kind == "hybrid" and index ~= nil and index > NanoNum.HYBRID_STANDARD_MAX_INDEX then index = nil end
						if index == nil and (kind == "extended" or kind == "hybrid") then
							local alpha = alphabeticRangeIndex(text, suffixStart, last)
							if alpha ~= nil then
								index = alpha + (kind == "hybrid" and NanoNum.HYBRID_STANDARD_MAX_INDEX or NanoNum.STANDARD_SUFFIX_MAX_INDEX)
								if kind == "extended" and index >= 1000 then index = nil end
							end
						end
					end
					if index ~= nil then
						local result = NanoNum.fromLog10(log10(mantissa) + index * 3)
						return finishParsed(result, negative, reciprocal)
					end
				end
			end
		end
		return makeSpecial(SPECIAL_NAN)
	end

	-- NanoNum v2.4.1: replace function NanoNum.fromString in the ORIGINAL parser closure.
	-- Fast path: ordinary ASCII scientific inputs with large exponents.
	-- No helper functions, NanoNum.* method dispatch, string.sub or temporary string allocations
	-- on the huge-number path. Complex cases preserve the original parser.
	-- Uses existing lexical locals: toNumber, byte, log10, abs, huge, floor,
	-- bufferCreate, bufferWriteBits, bufferWriteU8, bufferWriteF64,
	-- parseStringRange, and (for rare fast-path edge cases) the original fallback.
	function NanoNum.fromString(value: string, suffixType: SuffixName?): buffer
		local n = #value
		-- Only scan scientific candidates. Native numeric parsing remains available below.
		-- Inline scan of the mantissa, decimal position, and exponent avoids substring allocation.
		local pos = 1
		local negative = false
		local firstByte = n > 0 and byte(value, 1) or 0
		if firstByte == 45 or firstByte == 43 then
			negative = firstByte == 45
			pos = 2
		end
		local mantissa = 0
		local digitCount = 0
		local fractionalDigits = 0
		local decimalSeen = false
		local valid = pos <= n
		local ePos = 0
		while valid and pos <= n do
			local c = byte(value, pos)
			if c >= 48 and c <= 57 then
				digitCount += 1
				-- Avoid accumulated precision loss from very long mantissas.
				if digitCount > 15 then valid = false; break end
				mantissa = mantissa * 10 + (c - 48)
				if decimalSeen then fractionalDigits += 1 end
			elseif c == 46 and not decimalSeen then
				decimalSeen = true
			elseif (c == 101 or c == 69) and digitCount > 0 then
				ePos = pos
				break
			else
				valid = false
				break
			end
			pos += 1
		end
		if valid and ePos ~= 0 and ePos < n then
			pos = ePos + 1
			local exponentNegative = false
			local c = byte(value, pos)
			if c == 45 or c == 43 then
				exponentNegative = c == 45
				pos += 1
			end
			if pos <= n then
				local exponent = 0
				local exponentValid = true
				for i = pos, n do
					c = byte(value, i)
					if c < 48 or c > 57 then exponentValid = false; break end
					exponent = exponent * 10 + (c - 48)
					if exponent > 100000000000000 then exponentValid = false; break end
				end
				if exponentValid then
					if exponentNegative then exponent = -exponent end
					-- Avoid changing ordinary finite input semantics, including small
					-- scientific values that tonumber() rounds exactly.
					if exponent > 308 or exponent < -324 then
						if mantissa == 0 then
							local out = bufferCreate(1)
							bufferWriteU8(out, 0, 0)
							return out
						end
						local coordinate = exponent + log10(mantissa) - fractionalDigits
						-- Avoid very long mantissa/exponent rounding edge cases.
						if coordinate == coordinate and coordinate ~= huge and coordinate ~= -huge
							and (coordinate > 308.25471555991675 or coordinate < -323.3062153431158) then
							local reciprocal = coordinate < 0
							local magnitude = reciprocal and -coordinate or coordinate
							local header = 15 + (negative and 32 or 0) + (reciprocal and 64 or 0)
							-- Original K_LOG binary format: 7-bit header + scalar.
							-- Exact small integer coordinates use a variable-length scalar.
							if magnitude == floor(magnitude) and magnitude >= 0 and magnitude <= 9007199254740991 then
								local bits
								if magnitude == 0 then bits = 0
								elseif magnitude < 4294967296 then bits = 32 - bit32.countlz(magnitude)
								else bits = 64 - bit32.countlz(floor(magnitude / 4294967296)) end
								if 7 + bits <= 25 then
									local totalBits = 14 + bits
									local out = bufferCreate(floor((totalBits + 7) / 8))
									bufferWriteBits(out, 0, 7, header)
									bufferWriteBits(out, 7, 7, bits * 2)
									if bits > 0 then bufferWriteBits(out, 14, bits, magnitude) end
									return out
								end
							end
							-- Fractional or large logarithmic coordinates must remain
							-- exact f64, matching v2.4.1's SCALAR_F64_SENTINEL=124.
							local out = bufferCreate(10)
							bufferWriteBits(out, 0, 7, header)
							bufferWriteBits(out, 7, 7, 124)
							local scratch = bufferCreate(8)
							bufferWriteF64(scratch, 0, magnitude)
							bufferWriteBits(out, 14, 32, buffer.readbits(scratch, 0, 32))
							bufferWriteBits(out, 46, 32, buffer.readbits(scratch, 32, 32))
							return out
						end
					end
				end
			end
		end

		-- Retain your original fast finite path and all complex-format behavior.
		local direct = toNumber(value)
		if direct ~= nil and direct == direct and direct ~= huge and direct ~= -huge then
			if direct ~= 0 then return NanoNum.fromNumber(direct) end
			local scientific = false
			for i = 1, n do
				local c = byte(value, i)
				if c == 101 or c == 69 then scientific = true; break end
			end
			if not scientific then return NanoNum.fromNumber(0) end
		end
		return parseStringRange(value, 1, n, suffixType)
	end

end)()
-- Display-only precision sidecar. Existing format-6 buffer bytes are unchanged.
-- Weak keys avoid retaining buffers after callers release them.
local COMPACT_DISPLAY = setmetatable({}, {__mode = "k"}) :: {[buffer]: {mantissa: string, exponent: string, negative: boolean}}
local legacyFromString = NanoNum.fromString
NanoNum.fromString = function(value: string, suffixType: SuffixName?): buffer
	-- Native conversion rounds ordinary finite decimals once. Retain the display
	-- sidecar and underflow parser for scientific strings needing those paths.
	local direct = toNumber(value)
	if direct ~= nil and direct == direct and direct ~= huge and direct ~= -huge then
		local hasExponent = find(value, "[eE]") ~= nil
		if (direct ~= 0 or not hasExponent) and (#value < 17 or not hasExponent) then return encodeNumber(direct) end
	end
	-- Preserve original parser's fast path for ordinary values.
	-- Exact decimal exponents with >15 digits are kept as source text for display.
	local mant, exp = string.match(value, "^([+-]?%d+%.?%d*)[eE]([+-]?%d+)$")
	if mant ~= nil and exp ~= nil then
		local coefficient = tonumber(mant)
		local exponentValue = tonumber(exp)
		local magnitude = coefficient == nil and 0 or math.abs(coefficient)
		-- Scientific buffers encode a logarithmic coordinate, which is not able to
		-- reconstruct the input coefficient exactly for e.g. 2e1053. A weak-key
		-- sidecar preserves the text only for direct formatting of parsed values.
		-- Computed results never inherit this sidecar; arithmetic stays approximate.
		local preserve = #exp >= 16 or (exponentValue ~= nil and exponentValue == exponentValue
			and (exponentValue > 308 or exponentValue < -324) and magnitude >= 1 and magnitude < 10 and magnitude ~= 1)
		if preserve then
			local out = legacyFromString(value, suffixType)
			if coefficient ~= nil and coefficient ~= 0 and NanoNum.isValid(out) then
				COMPACT_DISPLAY[out] = {mantissa = mant, exponent = exp, negative = string.byte(mant, 1) == 45}
			end
			return out
		end
	end
	-- Accept compressed scientific input, e.g. 2e1.5e32, using approximate
	-- exponent arithmetic; metadata preserves the original display coefficient.
	local cm, ce, power = string.match(value, "^([+-]?%d+%.?%d*)[eE]([+-]?%d+%.?%d*)[eE]%+?(%d+)$")
	if cm ~= nil and ce ~= nil and power ~= nil then
		local m, c, pow = tonumber(cm), tonumber(ce), tonumber(power)
		if m ~= nil and c ~= nil and pow ~= nil and m ~= 0 and c > 0 and pow <= 307 then
			local exponent = c * 10 ^ pow
			if exponent < math.huge then
				local out = NanoNum.fromLog10(exponent + math.log10(math.abs(m)), m < 0)
				COMPACT_DISPLAY[out] = {mantissa = cm, exponent = ce .. "e" .. power, negative = m < 0}
				return out
			end
		end
	end
	return legacyFromString(value, suffixType)
end
local function trimText(value: string): string
	local first: number = 1
	local last = #value
	while first <= last do
		local c = byte(value, first)
		if c ~= 32 and c ~= 9 and c ~= 10 and c ~= 13 then break end
		first += 1
	end
	while last >= first do
		local c = byte(value, last)
		if c ~= 32 and c ~= 9 and c ~= 10 and c ~= 13 then break end
		last -= 1
	end
	if first == 1 and last == #value then return value end
	if first > last then return "" end
	return sub(value, first, last)
end
local function scalarEndChecked(data: buffer, bitOffset: number, limit: number): number?
	if bitOffset < 0 or bitOffset + 1 > limit then return nil end
	local headerBits: number = min(7, limit - bitOffset)
	local header: number = bufferReadBits(data, bitOffset, headerBits)
	if band(header, 1) == 0 then
		if headerBits < 7 then return nil end
		if header == SCALAR_F64_SENTINEL then
			local nextBit = bitOffset + 71
			if nextBit > limit then return nil end
			local payloadOffset = bitOffset + 7
			local value
			if band(payloadOffset, 7) == 0 then value = bufferReadF64(data, payloadOffset / 8)
			else
				local temp: buffer = bufferCreate(8)
				bufferWriteBits(temp, 0, 32, bufferReadBits(data, payloadOffset, 32))
				bufferWriteBits(temp, 32, 32, bufferReadBits(data, payloadOffset + 32, 32))
				value = bufferReadF64(temp, 0)
			end
			if value ~= value or value < 0 or value == huge then return nil end
			return nextBit
		end
		local n: number = floor(header / 2)
		if n > 53 then return nil end
		local nextBit = bitOffset + 7 + n
		return nextBit <= limit and nextBit or nil
	end
	local nextBit = bitOffset + SCALAR_APPROX_BITS
	if nextBit > limit then return nil end
	local expCode: number = floor(bufferReadBits(data, bitOffset, 11) / 2)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then return nil end
	return nextBit
end
local function recordEndChecked(data: buffer, bitOffset: number, limit: number?): number?
	local physicalLimit = bufferLen(data) * 8
	local endLimit = limit or physicalLimit
	if endLimit > physicalLimit or bitOffset < 0 or bitOffset + 6 > endLimit then return nil end
	local raw: number = bufferReadBits(data, bitOffset, 6)
	if band(raw, 1) == 0 or band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		return nextBit <= endLimit and nextBit or nil
	end
	if band(raw, 7) == 3 then
		if bitOffset + 9 > endLimit then return nil end
		local header9: number = bufferReadBits(data, bitOffset, 9)
		local n: number = floor(header9 / 16)
		local headerEnd = bitOffset + 9
		if n == 0 then
			if bitOffset + 14 > endLimit then return nil end
			local header14: number = bufferReadBits(data, bitOffset, 14)
			n = 32 + floor(header14 / 512)
			headerEnd = bitOffset + 14
			if n > MAX_INTEGER_MODE_BITS then return nil end
		end
		local nextBit = headerEnd + n
		return nextBit <= endLimit and nextBit or nil
	end
	if bitOffset + 8 <= endLimit then
		local first8: number = bufferReadBits(data, bitOffset, 8)
		if band(first8, 31) == HYPER_LAYER_PREFIX and band(first8, 128) == 0 then
			local topStart = scalarEndChecked(data, bitOffset + 8, endLimit)
			if topStart == nil then return nil end
			return scalarEndChecked(data, topStart, endLimit)
		end
	end
	if band(raw, 15) == 7 then return nil end
	if band(raw, 31) == 15 then
		if isExactLogAt(data, bitOffset, endLimit) then
			local nextBit = bitOffset + EXACT_LOG_BITS
			if nextBit > endLimit then return nil end
			local magnitude = readExactLogMagnitudeAt(data, bitOffset)
			if magnitude ~= magnitude or magnitude < 0 or magnitude == huge then return nil end
			return nextBit
		end
		return scalarEndChecked(data, bitOffset + 7, endLimit)
	end
	if band(raw, 63) == 31 then
		local fieldStart = bitOffset + 8
		if fieldStart + 1 > endLimit then return nil end
		local topStart
		if bufferReadBits(data, fieldStart, 1) == 0 then
			topStart = fieldStart + 6
			if topStart > endLimit then return nil end
		else
			if fieldStart + 2 > endLimit then return nil end
			topStart = scalarEndChecked(data, fieldStart + 2, endLimit)
			if topStart == nil then return nil end
		end
		return scalarEndChecked(data, topStart, endLimit)
	end
	local special: number = bufferReadBits(data, bitOffset + 6, 2)
	local nextBit = bitOffset + (special == SPECIAL_RESERVED and EXACT_F64_BITS or 8)
	return nextBit <= endLimit and nextBit or nil
end
local function decodeAt(data: buffer, bitOffset: number): (DecodedValue, number)
	local totalBits = bufferLen(data) * 8
	if bitOffset < 0 or bitOffset + 6 > totalBits then error("NanoNum: truncated record") end
	local raw: number = bufferReadBits(data, bitOffset, 6)
	if band(raw, 1) == 0 then
		local nextBit = bitOffset + 8
		if nextBit > totalBits then error("NanoNum: truncated tiny") end
		return {Kind = "Integer", Value = bufferReadBits(data, bitOffset + 1, 7), Negative = false}, nextBit
	end
	if band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		if nextBit > totalBits then error("NanoNum: truncated negative small") end
		return {Kind = "Integer", Value = -(bufferReadBits(data, bitOffset + 2, 6) + 1), Negative = true}, nextBit
	end
	if band(raw, 7) == 3 then
		local negative = bufferReadBits(data, bitOffset + 3, 1) == 1
		local n: number = bufferReadBits(data, bitOffset + 4, INTEGER_LEN_BITS)
		local payloadOffset = bitOffset + 9
		if n == 0 then
			n = 32 + bufferReadBits(data, payloadOffset, 5)
			payloadOffset += 5
		end
		if n > MAX_INTEGER_MODE_BITS then error("NanoNum: invalid integer length") end
		local nextBit = payloadOffset + n
		if nextBit > totalBits then error("NanoNum: truncated integer") end
		local magnitude = readUIntExactAtFast(data, payloadOffset, n)
		return {Kind = "Integer", Value = negative and -magnitude or magnitude, Negative = negative}, nextBit
	end
	if bitOffset + 8 <= totalBits then
		local first8: number = bufferReadBits(data, bitOffset, 8)
		if band(first8, 31) == HYPER_LAYER_PREFIX and band(first8, 128) == 0 then
			local negative = band(first8, 32) ~= 0
			local reciprocal = band(first8, 64) ~= 0
			local layerLog10Log10, topOffset = readScalarAtFast(data, bitOffset + 8)
			local top, nextBit = readScalarAtFast(data, topOffset)
			return {
				Kind = "Layer",
				Negative = negative,
				Reciprocal = reciprocal,
				Layer = nil,
				LayerLog10 = nil,
				LayerLog10Log10 = layerLog10Log10,
				LayerIsLog = false,
				LayerIsHyper = true,
				Top = top,
			}, nextBit
		end
	end
	if band(raw, 15) == 7 then error("NanoNum: legacy normal record is not supported") end
	if band(raw, 31) == 15 then
		local negative = bufferReadBits(data, bitOffset + 5, 1) == 1
		local reciprocal = bufferReadBits(data, bitOffset + 6, 1) == 1
		if isExactLogAt(data, bitOffset, totalBits) then
			local nextBit = bitOffset + EXACT_LOG_BITS
			if nextBit > totalBits then error("NanoNum: truncated exact log") end
			local top = readExactLogMagnitudeAt(data, bitOffset)
			if top ~= top or top < 0 or top == huge then error("NanoNum: invalid exact log") end
			return {Kind = "Log", Negative = negative, Reciprocal = reciprocal, Layer = 1, Top = top}, nextBit
		end
		local top, nextBit = readScalarAtFast(data, bitOffset + 7)
		return {Kind = "Log", Negative = negative, Reciprocal = reciprocal, Layer = 1, Top = top}, nextBit
	end
	if band(raw, 63) == 31 then
		local negative = bufferReadBits(data, bitOffset + 6, 1) == 1
		local reciprocal = bufferReadBits(data, bitOffset + 7, 1) == 1
		local layer, layerIsLog, topOffset = readLayerFieldAtFast(data, bitOffset + 8)
		local top, nextBit = readScalarAtFast(data, topOffset)
		return {
			Kind = "Layer",
			Negative = negative,
			Reciprocal = reciprocal,
			Layer = if layerIsLog then nil else layer,
			LayerLog10 = layerIsLog and layer or nil,
			LayerLog10Log10 = nil,
			LayerIsLog = layerIsLog,
			LayerIsHyper = false,
			Top = top,
		}, nextBit
	end
	local special: number = bufferReadBits(data, bitOffset + 6, 2)
	if special == SPECIAL_RESERVED then
		local nextBit = bitOffset + EXACT_F64_BITS
		if nextBit > totalBits then error("NanoNum: truncated exact finite") end
		local value = readExactF64At(data, bitOffset)
		if value ~= value then return {Kind = "NaN", Negative = false}, nextBit end
		if value == huge then return {Kind = "Infinity", Negative = false}, nextBit end
		if value == -huge then return {Kind = "Infinity", Negative = true}, nextBit end
		return {Kind = "Exact", Value = value, Negative = value < 0}, nextBit
	end
	local nextBit = bitOffset + 8
	if special == SPECIAL_POS_INF then return {Kind = "Infinity", Negative = false}, nextBit end
	if special == SPECIAL_NEG_INF then return {Kind = "Infinity", Negative = true}, nextBit end
	if special == SPECIAL_NAN then return {Kind = "NaN", Negative = false}, nextBit end
	return {Kind = "Reserved", Negative = false}, nextBit
end
NanoNum.decodeAt = decodeAt
function NanoNum.tryDecodeAt(data: buffer, bitOffset: number?): (boolean, DecodedValue?, number?)
	if typeof(data) ~= "buffer" then return false, nil, nil end
	local offset: any = bitOffset == nil and 0 or bitOffset
	if typeof(offset) ~= "number" or offset ~= offset or offset ~= floor(offset) or offset < 0 or offset >= bufferLen(data) * 8 then return false, nil, nil end
	local ok, decoded, nextBit = fastPcall(decodeAt, data, offset)
	if not ok then return false, nil, nil end
	return true, decoded, nextBit
end
function NanoNum.isValid(value: buffer): boolean
	if typeof(value) ~= "buffer" then return false end
	local bytes: number = bufferLen(value)
	if bytes < 1 or bytes > MAX_STANDALONE_BYTES then return false end
	local limit = bytes * 8
	local nextBit = recordEndChecked(value, 0, limit)
	if nextBit == nil then return false end
	local raw: number = bufferReadBits(value, 0, 6)
	if band(raw, 63) == 63 and bufferReadBits(value, 6, 2) == SPECIAL_RESERVED then
		if nextBit ~= EXACT_F64_BITS then return false end
		local exact = readExactF64At(value, 0)
		if exact ~= exact or exact == huge or exact == -huge then return false end
	end
	local offset = nextBit
	while offset < limit do
		local count: number = min(32, limit - offset)
		if bufferReadBits(value, offset, count) ~= 0 then return false end
		offset += count
	end
	return true
end
function NanoNum.components(value: buffer): DecodedValue
	local decoded = decodeAt(value, 0)
	return decoded
end
function NanoNum.bitLength(value: buffer): number
	local limit = bufferLen(value) * 8
	local nextBit = recordEndChecked(value, 0, limit)
	if nextBit == nil then error("NanoNum: invalid record") end
	return nextBit
end
NanoNum.byteLength = bufferLen
local function decodeRegBuffer(value: buffer): (number, number, number)
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		local exact: number = bufferReadF64(value, 1)
		if exact ~= exact then return K_NAN, 0, 0 end
		if exact == huge then return K_INF, 0, 0 end
		if exact == -huge then return -K_INF, 0, 0 end
		if exact == 0 then return 0, 0, 0 end
		return exact < 0 and -K_NUM or K_NUM, exact < 0 and -exact or exact, 0
	end
	if band(first, 1) == 0 then
		local magnitude: number = floor(first / 2)
		if magnitude == 0 then return 0, 0, 0 end
		return K_NUM, magnitude, 0
	end
	if band(first, 3) == 1 then return -K_NUM, floor(first / 4) + 1, 0 end
	local raw: number = band(first, 63)
	if band(raw, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
			if n > MAX_INTEGER_MODE_BITS then return K_NAN, 0, 0 end
		end
		local magnitude
		if n <= 32 then magnitude = bufferReadBits(value, offset, n)
		else magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296 end
		return negative and -K_NUM or K_NUM, magnitude, 0
	end
	if band(first, 31) == HYPER_LAYER_PREFIX and band(first, 128) == 0 then
		local negative = band(first, 32) ~= 0
		local reciprocal = band(first, 64) ~= 0
		local layerLog10Log10, nextBit = readScalarAtFast(value, 8)
		local top = readScalarAtFast(value, nextBit)
		local signedLayer = reciprocal and -layerLog10Log10 or layerLog10Log10
		return negative and -K_HYPER_LAYER or K_HYPER_LAYER, signedLayer, top
	end
	if band(raw, 15) == 7 then return K_NAN, 0, 0 end
	if band(raw, 31) == 15 then
		local negative = band(first, 32) ~= 0
		local reciprocal = band(first, 64) ~= 0
		local top
		if isExactLogAt(value, 0) then
			top = readExactLogMagnitudeAt(value, 0)
			if top ~= top or top < 0 or top == huge then return K_NAN, 0, 0 end
		else top = readScalarAtFast(value, 7) end
		return negative and -K_LOG or K_LOG, reciprocal and -top or top, 0
	end
	if raw == 31 then
		local negative = band(first, 64) ~= 0
		local reciprocal = band(first, 128) ~= 0
		local layer, layerIsLog, nextBit = readLayerFieldAtFast(value, 8)
		local top = readScalarAtFast(value, nextBit)
		local signedLayer = reciprocal and -layer or layer
		local kind = layerIsLog and K_LAYER_LOG or K_LAYER
		return negative and -kind or kind, signedLayer, top
	end
	if first == 63 then return K_INF, 0, 0 end
	if first == 127 then return -K_INF, 0, 0 end
	return K_NAN, 0, 0
end
local function regFromNumber(value: number): (number, number, number)
	if value ~= value then return K_NAN, 0, 0 end
	if value == huge then return K_INF, 0, 0 end
	if value == -huge then return -K_INF, 0, 0 end
	if value == 0 then return 0, 0, 0 end
	return value < 0 and -K_NUM or K_NUM, abs(value), 0
end
local function regFromSignedLog(logMagnitude: number, negative: boolean): (number, number, number)
	if logMagnitude ~= logMagnitude then return K_NAN, 0, 0 end
	if logMagnitude == huge then return negative and -K_INF or K_INF, 0, 0 end
	if logMagnitude == -huge then return 0, 0, 0 end
	if logMagnitude >= DIRECT_LOG_MIN and logMagnitude <= DIRECT_LOG_MAX then
		local magnitude = 10 ^ logMagnitude
		if magnitude ~= 0 and magnitude ~= huge then return negative and -K_NUM or K_NUM, magnitude, 0 end
	end
	return negative and -K_LOG or K_LOG, logMagnitude, 0
end
local function regFromSignedLogSum(left: number, right: number, negative: boolean): (number, number, number)
	if left ~= left or right ~= right then return K_NAN, 0, 0 end
	local value = left + right
	if value ~= huge and value ~= -huge then return regFromSignedLog(value, negative) end
	if left == huge or right == huge then
		if left == -huge or right == -huge then return K_NAN, 0, 0 end
		return negative and -K_INF or K_INF, 0, 0
	end
	if left == -huge or right == -huge then return 0, 0, 0 end
	local leftNegative = left < 0
	local rightNegative = right < 0
	if leftNegative ~= rightNegative then return regFromSignedLog(value, negative) end
	local al: number = abs(left)
	local ar: number = abs(right)
	local hi: number = max(al, ar)
	local lo: number = min(al, ar)
	if hi == 0 then return regFromSignedLog(0, negative) end
	local top: number = log10(hi) + log10(1 + lo / hi)
	return negative and -K_LAYER or K_LAYER, leftNegative and -2 or 2, top
end
local function regFromSignedLogProduct(left: number, right: number, negative: boolean): (number, number, number)
	if left ~= left or right ~= right then return K_NAN, 0, 0 end
	if left == 0 or right == 0 then return regFromSignedLog(0, negative) end
	local value = left * right
	if value ~= huge and value ~= -huge then return regFromSignedLog(value, negative) end
	if left == huge or left == -huge or right == huge or right == -huge then
		local reciprocal = (left < 0) ~= (right < 0)
		if reciprocal then return 0, 0, 0 end
		return negative and -K_INF or K_INF, 0, 0
	end
	local reciprocal = (left < 0) ~= (right < 0)
	local top: number = log10(abs(left)) + log10(abs(right))
	return negative and -K_LAYER or K_LAYER, reciprocal and -2 or 2, top
end
local function decodeReg(value: any): (number, number, number)
	local kind = typeof(value)
	if kind == "number" then return regFromNumber(value) end
	if kind == "buffer" then return decodeRegBuffer(value) end
	if kind == "string" then return decodeRegBuffer(NanoNum.fromString(value)) end
	return K_NAN, 0, 0
end
local function encodeReg(kind: number, a: number, b: number): buffer
	if kind ~= kind or a ~= a or b ~= b then return makeSpecial(SPECIAL_NAN) end
	if kind == 0 then return NanoNum.fromNumber(0) end
	local absoluteKind: number = abs(kind)
	local negative = kind < 0
	if absoluteKind == K_NUM then
		if a == huge then return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
		if a < 0 then return NanoNum.fromNumber(negative and a or -a) end
		return NanoNum.fromNumber(negative and -a or a)
	end
	if absoluteKind == K_LOG then return NanoNum.fromLog10(a, negative) end
	if absoluteKind == K_LAYER then return NanoNum.fromLayer(abs(a), b, negative, a < 0) end
	if absoluteKind == K_LAYER_LOG then return NanoNum.fromLayerLog10(abs(a), b, negative, a < 0) end
	if absoluteKind == K_HYPER_LAYER then return NanoNum.fromLayerLog10Log10(abs(a), b, negative, a < 0) end
	if absoluteKind == K_INF then return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	return makeSpecial(SPECIAL_NAN)
end
local function regSign(kind: number): number
	if abs(kind) == K_NAN then return NAN end
	if kind < 0 then return -1 end
	if kind > 0 then return 1 end
	return 0
end
local function regLogAbs(kind: number, a: number): number?
	local absoluteKind: number = abs(kind)
	if absoluteKind == K_NUM then return log10(a) end
	if absoluteKind == K_LOG then return a end
	return nil
end
local function regToNumber(kind: number, a: number, b: number): number
	if kind == 0 then return 0 end
	local absoluteKind: number = abs(kind)
	local negative = kind < 0
	if absoluteKind == K_NUM then return negative and -a or a end
	if absoluteKind == K_LOG then
		if a > DIRECT_LOG_MAX then return negative and -huge or huge end
		if a < DIRECT_LOG_MIN then return negative and -0 or 0 end
		local magnitude = 10 ^ a
		return negative and -magnitude or magnitude
	end
	if absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG or absoluteKind == K_HYPER_LAYER then
		if a < 0 then return negative and -0 or 0 end
		return negative and -huge or huge
	end
	if absoluteKind == K_INF then return negative and -huge or huge end
	return NAN
end
local function regReciprocal(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind: number = abs(kind)
	if absoluteKind == K_NAN then return K_NAN, 0, 0 end
	if kind == 0 then return K_INF, 0, 0 end
	if absoluteKind == K_INF then return 0, 0, 0 end
	if absoluteKind == K_NUM then
		local result = 1 / a
		if result ~= huge and result ~= 0 then return kind, result, 0 end
		return regFromSignedLog(-log10(a), kind < 0)
	end
	if absoluteKind == K_LOG then return kind, -a, 0 end
	if absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG or absoluteKind == K_HYPER_LAYER then return kind, -a, b end
	return K_NAN, 0, 0
end
local function regLayerCompare(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): number
	local aKind: number = abs(ak)
	local bKind: number = abs(bk)
	local aReciprocal = aa < 0
	local bReciprocal = ba < 0
	if aReciprocal ~= bReciprocal then return aReciprocal and -1 or 1 end
	local cmp: number = 0
	if aKind ~= bKind then
		cmp = aKind < bKind and -1 or 1
	else
		local al: number = abs(aa)
		local bl: number = abs(ba)
		if al < bl then cmp = -1 elseif al > bl then cmp = 1 elseif ab < bb then cmp = -1 elseif ab > bb then cmp = 1 end
	end
	return aReciprocal and -cmp or cmp
end
local function regAbsCompare(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): number
	if ak == 0 then return bk == 0 and 0 or -1 end
	if bk == 0 then return 1 end
	local aKind: number = abs(ak)
	local bKind: number = abs(bk)
	if aKind == K_NUM and bKind == K_NUM then return aa < ba and -1 or (aa > ba and 1 or 0) end
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG or aKind == K_HYPER_LAYER
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG or bKind == K_HYPER_LAYER
	if not aLayer and not bLayer then
		local la = regLogAbs(ak, aa)
		local lb = regLogAbs(bk, ba)
		if la == nil or lb == nil then return 0 end
		if la < lb then return -1 end
		if la > lb then return 1 end
		return 0
	end
	if aLayer and not bLayer then return aa < 0 and -1 or 1 end
	if bLayer and not aLayer then return ba < 0 and 1 or -1 end
	return regLayerCompare(ak, aa, ab, bk, ba, bb)
end
local function regCompare(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): number
	local aKind: number = abs(ak)
	local bKind: number = abs(bk)
	if aKind == K_NAN or bKind == K_NAN then return NAN end
	if aKind == K_INF or bKind == K_INF then
		if aKind == K_INF and bKind == K_INF then
			if ak == bk then return 0 end
			return ak < bk and -1 or 1
		end
		if aKind == K_INF then return ak < 0 and -1 or 1 end
		return bk < 0 and 1 or -1
	end
	local sa = regSign(ak)
	local sb = regSign(bk)
	if sa ~= sb then return sa < sb and -1 or 1 end
	if sa == 0 then return 0 end
	local cmp = regAbsCompare(ak, aa, ab, bk, ba, bb)
	return sa < 0 and -cmp or cmp
end
local function regAdd(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	local aKind: number = abs(ak)
	local bKind: number = abs(bk)
	if aKind == K_NAN or bKind == K_NAN then return K_NAN, 0, 0 end
	if aKind == K_INF or bKind == K_INF then
		if aKind == K_INF and bKind == K_INF and (ak < 0) ~= (bk < 0) then return K_NAN, 0, 0 end
		if aKind == K_INF then return ak, aa, ab end
		return bk, ba, bb
	end
	if ak == 0 then return bk, ba, bb end
	if bk == 0 then return ak, aa, ab end
	if aKind == K_NUM and bKind == K_NUM then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		local value = x + y
		if value ~= huge and value ~= -huge then return regFromNumber(value) end
	end
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG or aKind == K_HYPER_LAYER
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG or bKind == K_HYPER_LAYER
	if aLayer or bLayer then
		local cmp = regAbsCompare(ak, aa, ab, bk, ba, bb)
		if (ak < 0) ~= (bk < 0) and cmp == 0 then return 0, 0, 0 end
		if cmp >= 0 then return ak, aa, ab end
		return bk, ba, bb
	end
	local la = regLogAbs(ak, aa)
	local lb = regLogAbs(bk, ba)
	if la == nil or lb == nil then return K_NAN, 0, 0 end
	local negativeA = ak < 0
	local negativeB = bk < 0
	if negativeA == negativeB then
		local hi: number = max(la, lb)
		local lo: number = min(la, lb)
		local delta = hi - lo
		if delta > 18 then return regFromSignedLog(hi, negativeA) end
		return regFromSignedLog(hi + log10(1 + 10 ^ (-delta)), negativeA)
	end
	local cmp = regAbsCompare(ak, aa, ab, bk, ba, bb)
	if cmp == 0 then return 0, 0, 0 end
	local hi = cmp > 0 and la or lb
	local lo = cmp > 0 and lb or la
	local negative = cmp > 0 and negativeA or negativeB
	local delta = hi - lo
	if delta > 18 then return regFromSignedLog(hi, negative) end
	local term = oneMinusPow10Neg(delta)
	if term <= 0 then return 0, 0, 0 end
	return regFromSignedLog(hi + log10(term), negative)
end
local function regSub(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	if bk ~= 0 and abs(bk) ~= K_NAN then bk = -bk end
	return regAdd(ak, aa, ab, bk, ba, bb)
end
local function regMul(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	local aKind: number = abs(ak)
	local bKind: number = abs(bk)
	if aKind == K_NAN or bKind == K_NAN then return K_NAN, 0, 0 end
	if ak == 0 or bk == 0 then
		if aKind == K_INF or bKind == K_INF then return K_NAN, 0, 0 end
		return 0, 0, 0
	end
	local negative = (ak < 0) ~= (bk < 0)
	if aKind == K_INF or bKind == K_INF then return negative and -K_INF or K_INF, 0, 0 end
	if aKind == K_NUM and bKind == K_NUM then
		local value = aa * ba
		if value ~= huge and value ~= 0 then return negative and -K_NUM or K_NUM, value, 0 end
	end
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG or aKind == K_HYPER_LAYER
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG or bKind == K_HYPER_LAYER
	if aLayer and bLayer and aKind == bKind and aa == -ba and ab == bb then
		return negative and -K_NUM or K_NUM, 1, 0
	end
	if not aLayer and not bLayer then
		local la = regLogAbs(ak, aa)
		local lb = regLogAbs(bk, ba)
		if la == nil or lb == nil then return K_NAN, 0, 0 end
		return regFromSignedLogSum(la, lb, negative)
	end
	if aLayer ~= bLayer then
		local lk = aLayer and ak or bk
		local la = aLayer and aa or ba
		local lb = aLayer and ab or bb
		local ok = aLayer and bk or ak
		local oa = aLayer and ba or aa
		local otherLog = regLogAbs(ok, oa)
		if otherLog == nil then return K_NAN, 0, 0 end
		if abs(lk) == K_LAYER and abs(la) == 2 then
			if otherLog == 0 then return negative and -K_LAYER or K_LAYER, la, lb end
			local layerSign = la < 0 and -1 or 1
			local otherSign = otherLog < 0 and -1 or 1
			local otherTop: number = log10(abs(otherLog))
			local top, resultSign
			if layerSign == otherSign then
				local hi, lo = max(lb, otherTop), min(lb, otherTop)
				top = hi + log10(1 + 10 ^ (lo - hi))
				resultSign = layerSign
			else
				if lb == otherTop then return negative and -K_NUM or K_NUM, 1, 0 end
				local hi, lo = max(lb, otherTop), min(lb, otherTop)
				local term = oneMinusPow10Neg(hi - lo)
				if term <= 0 then return negative and -K_NUM or K_NUM, 1, 0 end
				top = hi + log10(term)
				resultSign = lb > otherTop and layerSign or otherSign
			end
			if top <= DIRECT_LOG_MAX then return regFromSignedLog((resultSign < 0 and -1 or 1) * 10 ^ top, negative) end
			return negative and -K_LAYER or K_LAYER, resultSign < 0 and -2 or 2, top
		end
		return negative and -abs(lk) or abs(lk), la, lb
	end
	if aKind == K_LAYER and bKind == K_LAYER and abs(aa) == 2 and abs(ba) == 2 then
		local sa = aa < 0 and -1 or 1
		local sb = ba < 0 and -1 or 1
		if sa == sb then
			local hi: number = max(ab, bb)
			local lo: number = min(ab, bb)
			return negative and -K_LAYER or K_LAYER, sa < 0 and -2 or 2, hi + log10(1 + 10 ^ (lo - hi))
		end
		if ab == bb then return negative and -K_NUM or K_NUM, 1, 0 end
		local hi = ab > bb and ab or bb
		local lo = ab > bb and bb or ab
		local reciprocal = if ab > bb then sa < 0 else sb < 0
		local term = oneMinusPow10Neg(hi - lo)
		if term <= 0 then return negative and -K_NUM or K_NUM, 1, 0 end
		return negative and -K_LAYER or K_LAYER, reciprocal and -2 or 2, hi + log10(term)
	end
	local cmp = regLayerCompare(ak, abs(aa), ab, bk, abs(ba), bb)
	if cmp == 0 then
		if (aa < 0) ~= (ba < 0) then return negative and -K_NUM or K_NUM, 1, 0 end
		return negative and -aKind or aKind, aa, ab
	end
	if cmp > 0 then return negative and -aKind or aKind, aa, ab end
	return negative and -bKind or bKind, ba, bb
end
local function regDiv(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	if abs(ak) == K_NAN or abs(bk) == K_NAN then return K_NAN, 0, 0 end
	if abs(ak) == K_INF and abs(bk) == K_INF then return K_NAN, 0, 0 end
	if abs(ak) == K_NUM and abs(bk) == K_NUM then
		local result = aa / ba
		if result ~= huge and result ~= 0 then return (ak < 0) ~= (bk < 0) and -K_NUM or K_NUM, result, 0 end
		return regFromSignedLog(log10(aa) - log10(ba), (ak < 0) ~= (bk < 0))
	end
	local rk, ra, rb = regReciprocal(bk, ba, bb)
	return regMul(ak, aa, ab, rk, ra, rb)
end
local function regLog10(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind: number = abs(kind)
	if absoluteKind == K_NAN or kind < 0 then return K_NAN, 0, 0 end
	if kind == 0 then return -K_INF, 0, 0 end
	if absoluteKind == K_INF then return K_INF, 0, 0 end
	if absoluteKind == K_NUM then return regFromNumber(log10(a)) end
	if absoluteKind == K_LOG then return regFromNumber(a) end
	if absoluteKind == K_LAYER then
		local reciprocal = a < 0
		local layer: number = abs(a)
		if layer == 2 then return reciprocal and -K_LOG or K_LOG, b, 0 end
		return reciprocal and -K_LAYER or K_LAYER, layer - 1, b
	end
	if absoluteKind == K_LAYER_LOG then return a < 0 and -K_LAYER_LOG or K_LAYER_LOG, abs(a), b end
	if absoluteKind == K_HYPER_LAYER then return a < 0 and -K_HYPER_LAYER or K_HYPER_LAYER, abs(a), b end
	return K_NAN, 0, 0
end
local function regPow10(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind: number = abs(kind)
	if absoluteKind == K_NAN then return K_NAN, 0, 0 end
	if kind == 0 then return K_NUM, 1, 0 end
	if absoluteKind == K_INF then return kind < 0 and 0 or K_INF, 0, 0 end
	if absoluteKind == K_NUM then return regFromSignedLog(kind < 0 and -a or a, false) end
	if absoluteKind == K_LOG then
		local direct = regToNumber(kind, a, b)
		if direct ~= huge and direct ~= -huge then return regFromSignedLog(direct, false) end
		return K_LAYER, kind < 0 and -2 or 2, abs(a)
	end
	if absoluteKind == K_LAYER then
		if a < 0 then return K_NUM, 1, 0 end
		local layer: number = min(abs(a) + 1, NanoNum.MAX_LAYER)
		return K_LAYER, kind < 0 and -layer or layer, b
	end
	if absoluteKind == K_LAYER_LOG then
		if a < 0 then return K_NUM, 1, 0 end
		return K_LAYER_LOG, kind < 0 and -abs(a) or abs(a), b
	end
	if absoluteKind == K_HYPER_LAYER then
		if a < 0 then return K_NUM, 1, 0 end
		return K_HYPER_LAYER, kind < 0 and -abs(a) or abs(a), b
	end
	return K_NAN, 0, 0
end
local function regIsInteger(kind: number, a: number, b: number): boolean
	local absoluteKind: number = abs(kind)
	if kind == 0 then return true end
	if absoluteKind == K_NUM then return a == floor(a) end
	-- Log/layer records do not retain arbitrary integer provenance. Stay conservative:
	-- only return true when the stored canonical coordinates themselves prove integrality.
	if absoluteKind == K_LOG then return a >= 0 and a == floor(a) end
	if absoluteKind == K_LAYER then return a > 0 and a == floor(a) and b >= 0 and b == floor(b) end
	-- A layer-log/hyper-layer descriptor is logarithmic. A fractional descriptor does not
	-- prove that the represented layer count is an integer, so do not invent parity/domain
	-- information from the top coordinate alone.
	if absoluteKind == K_LAYER_LOG or absoluteKind == K_HYPER_LAYER then
		return a > 0 and a == floor(a) and b >= 0 and b == floor(b)
	end
	return false
end
local function regIsOdd(kind: number, a: number, b: number): boolean
	local absoluteKind: number = abs(kind)
	if absoluteKind == K_NUM then return a == floor(a) and a % 2 == 1 end
	if absoluteKind == K_LOG then return a == 0 end
	return false
end
local function regPow(bk: number, ba: number, bb: number, ek: number, ea: number, eb: number): (number, number, number)
	local baseKind: number = abs(bk)
	local exponentKind: number = abs(ek)
	if ek == 0 then return K_NUM, 1, 0 end
	if bk == K_NUM and ba == 1 then return K_NUM, 1, 0 end
	if baseKind == K_NAN or exponentKind == K_NAN then return K_NAN, 0, 0 end
	if bk == 0 then return ek > 0 and 0 or K_INF, 0, 0 end
	if exponentKind == K_INF then
		-- A negative base raised to an infinite exponent has no real-valued parity to resolve.
		if bk < 0 then return K_NAN, 0, 0 end
		if baseKind == K_INF then return ek < 0 and 0 or K_INF, 0, 0 end
		local baseCmpOne = regCompare(abs(bk), ba, bb, K_NUM, 1, 0)
		if baseCmpOne == 0 then return K_NUM, 1, 0 end
		if ek > 0 then return baseCmpOne > 0 and K_INF or 0, 0, 0 end
		return baseCmpOne > 0 and 0 or K_INF, 0, 0
	end
	if baseKind == K_INF then
		-- Check the real-domain restriction before the negative-exponent shortcut.
		-- Otherwise (-Inf)^(-0.5) incorrectly becomes 0 instead of NaN.
		if bk < 0 and not regIsInteger(ek, ea, eb) then return K_NAN, 0, 0 end
		if ek < 0 then return 0, 0, 0 end
		local negativeResult = bk < 0 and regIsOdd(ek, ea, eb)
		return negativeResult and -K_INF or K_INF, 0, 0
	end
	local negativeResult: boolean = false
	if bk < 0 then
		if not regIsInteger(ek, ea, eb) then return K_NAN, 0, 0 end
		negativeResult = regIsOdd(ek, ea, eb)
		bk = -bk
	end
	if ek == K_NUM and ea == 1 then
		if negativeResult and bk ~= 0 then bk = -bk end
		return bk, ba, bb
	end
	if bk == K_NUM and ba == 10 then
		local rk, ra, rb = regPow10(ek, ea, eb)
		if negativeResult and rk ~= 0 and abs(rk) ~= K_NAN then rk = -rk end
		return rk, ra, rb
	end
	if abs(bk) == K_NUM and abs(ek) == K_NUM then
		local exponent = ek < 0 and -ea or ea
		local native = ba ^ exponent
		if native == native and native ~= huge and native ~= 0 then return negativeResult and -K_NUM or K_NUM, native, 0 end
	end
	local baseLog = regLogAbs(bk, ba)
	if baseLog ~= nil then
		local exponent = regToNumber(ek, ea, eb)
		if exponent == exponent and exponent ~= huge and exponent ~= -huge then return regFromSignedLogProduct(baseLog, exponent, negativeResult) end
	end
	local lk, la, lb = regLog10(bk, ba, bb)
	local mk, ma, mb = regMul(ek, ea, eb, lk, la, lb)
	local rk, ra, rb = regPow10(mk, ma, mb)
	if negativeResult and rk ~= 0 and abs(rk) ~= K_NAN then rk = -rk end
	return rk, ra, rb
end
local function directDecode(value: any): (number, number, number)
	local kind = typeof(value)
	if kind == "number" then
		if value ~= value then return K_NAN, 0, 0 end
		if value == huge then return K_INF, 0, 0 end
		if value == -huge then return -K_INF, 0, 0 end
		if value == 0 then return 0, 0, 0 end
		return value < 0 and -K_NUM or K_NUM, value < 0 and -value or value, 0
	end
	if kind == "buffer" then return decodeRegBuffer(value) end
	if kind == "string" then return decodeRegBuffer(NanoNum.fromString(value)) end
	return K_NAN, 0, 0
end
-- FastME-style direct finite bridge for higher-level APIs.
-- Returns nil for log/layer/hyper/special/string inputs so the canonical NanoNum kernel stays the fallback.
local function directFiniteNumber(value: MathValue): number?
	local kind = typeof(value)
	if kind == "number" then
		local x = value :: number
		return x == x and x ~= huge and x ~= -huge and x or nil
	end
	if kind ~= "buffer" then return nil end
	local data = value :: buffer
	local first: number = bufferReadU8(data, 0)
	if first == 255 then
		local x: number = bufferReadF64(data, 1)
		return x == x and x ~= huge and x ~= -huge and x or nil
	end
	if band(first, 1) == 0 then return floor(first / 2) end
	if band(first, 3) == 1 then return -(floor(first / 4) + 1) end
	if band(first, 7) ~= 3 then return nil end
	local negative = band(first, 8) ~= 0
	local n: number = bufferReadBits(data, 4, 5)
	local offset: number = 9
	if n == 0 then n = 32 + bufferReadBits(data, offset, 5); offset = 14 end
	if n > MAX_INTEGER_MODE_BITS then return nil end
	local magnitude
	if n <= 32 then magnitude = bufferReadBits(data, offset, n)
	else magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296 end
	return negative and -magnitude or magnitude
end
local function nativeInverseLerp(a: number, b: number, value: number): number?
	local span = b - a
	if span == 0 then return nil end
	local numerator = value - a
	if span ~= huge and span ~= -huge and numerator ~= huge and numerator ~= -huge then return numerator / span end
	local scale: number = max(max(abs(a), abs(b)), abs(value))
	if scale == 0 then return nil end
	return (value / scale - a / scale) / (b / scale - a / scale)
end
local function nativeLerp(a: number, b: number, t: number): number
	if t == 1 then return b end
	if t == 0 or a == b then return a end
	if t > 0 and t < 1 then return a * (1 - t) + b * t end
	return a + (b - a) * t
end
local function coldAdd(a: MathValue, b: MathValue): buffer
	if a == b then
		local k, x, y = directDecode(a)
		local rk, rx, ry = regAdd(k, x, y, k, x, y)
		return encodeReg(rk, rx, ry)
	end
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end
local function coldSub(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end
local function coldMul(a: MathValue, b: MathValue): buffer
	if a == b then
		local k, x, y = directDecode(a)
		local rk, rx, ry = regMul(k, x, y, k, x, y)
		return encodeReg(rk, rx, ry)
	end
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end
local function coldDiv(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end
local function coldPow(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end
local function coldCompare(a: MathValue, b: MathValue): number
	if a == b then
		local k = directDecode(a)
		if abs(k) == K_NAN then return NAN end
		return 0
	end
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	return regCompare(ak, aa, ab, bk, ba, bb)
end
local function coldSign(value: MathValue): number
	local k = directDecode(value)
	if abs(k) == K_NAN then return NAN end
	if k == 0 then return 0 end
	return k < 0 and -1 or 1
end
local function coldNeg(value: MathValue): buffer
	local k, a, b = directDecode(value)
	if k ~= 0 and abs(k) ~= K_NAN then k = -k end
	return encodeReg(k, a, b)
end
local function coldAbs(value: MathValue): buffer
	local k, a, b = directDecode(value)
	return encodeReg(abs(k), a, b)
end
local function coldReciprocal(value: MathValue): buffer
	local k, a, b = directDecode(value)
	k, a, b = regReciprocal(k, a, b)
	return encodeReg(k, a, b)
end
local function coldToNumber(value: MathValue): number
	local k, a, b = directDecode(value)
	return regToNumber(k, a, b)
end
local function coldLog10(value: MathValue): buffer
	local k, a, b = directDecode(value)
	k, a, b = regLog10(k, a, b)
	return encodeReg(k, a, b)
end
local function coldLn(value: MathValue): buffer
	local k, a, b = directDecode(value)
	k, a, b = regLog10(k, a, b)
	local ck, ca, cb = regFromNumber(LN10)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	return encodeReg(k, a, b)
end
local function coldLog2(value: MathValue): buffer
	local k, a, b = directDecode(value)
	k, a, b = regLog10(k, a, b)
	local ck, ca, cb = regFromNumber(LOG10_2)
	k, a, b = regDiv(k, a, b, ck, ca, cb)
	return encodeReg(k, a, b)
end
local function coldExp(value: MathValue): buffer
	local k, a, b = directDecode(value)
	local ck, ca, cb = regFromNumber(LOG10_E)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end
local function coldExp2(value: MathValue): buffer
	local k, a, b = directDecode(value)
	local ck, ca, cb = regFromNumber(LOG10_2)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end
local function coldSqrt(value: MathValue): buffer
	local k, a, b = directDecode(value)
	if k < 0 then return makeSpecial(SPECIAL_NAN) end
	k, a, b = regPow(k, a, b, K_NUM, 0.5, 0)
	return encodeReg(k, a, b)
end
local function coldCbrt(value: MathValue): buffer
	local k, a, b = directDecode(value)
	local negative = k < 0
	if negative then k = -k end
	k, a, b = regPow(k, a, b, K_NUM, 1 / 3, 0)
	if negative and k ~= 0 and abs(k) ~= K_NAN then k = -k end
	return encodeReg(k, a, b)
end
function NanoNum.add(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then
		ax = a :: number
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then
		local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(av, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(av, offset, n)
				else
					magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296
				end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then
		bx = b :: number
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then
		local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(bv, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(bv, offset, n)
				else
					magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296
				end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		local value = ax + bx
		if value == value and value ~= huge and value ~= -huge then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldAdd(a, b)
end
function NanoNum.sub(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then
		ax = a :: number
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then
		local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(av, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(av, offset, n)
				else
					magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296
				end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then
		bx = b :: number
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then
		local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(bv, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(bv, offset, n)
				else
					magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296
				end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		local value = ax - bx
		if value == value and value ~= huge and value ~= -huge then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldSub(a, b)
end
function NanoNum.mul(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then
		ax = a :: number
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then
		local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(av, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(av, offset, n)
				else
					magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296
				end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then
		bx = b :: number
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then
		local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(bv, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(bv, offset, n)
				else
					magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296
				end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		local value = ax * bx
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0 or bx == 0) then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldMul(a, b)
end
function NanoNum.div(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then
		ax = a :: number
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then
		local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(av, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(av, offset, n)
				else
					magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296
				end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then
		bx = b :: number
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then
		local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(bv, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(bv, offset, n)
				else
					magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296
				end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		if bx ~= 0 then
			local value = ax / bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				local integral: number = floor(value)
				if value == integral then
					if value >= 0 and value <= 127 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, value * 2)
						return data
					end
					if value < 0 and value >= -64 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
						return data
					end
					local negative = value < 0
					local magnitude = negative and -value or value
					if magnitude <= SAFE_INTEGER then
						local n: number = bitsRequired(magnitude)
						if n <= 31 then
							local bits = 9 + n
							local data: buffer = bufferCreate(floor((bits + 7) / 8))
							local header = 3 + (negative and 8 or 0) + n * 16
							if bits <= 32 then
								bufferWriteBits(data, 0, bits, header + magnitude * 512)
							else
								bufferWriteBits(data, 0, 9, header)
								bufferWriteBits(data, 9, n, magnitude)
							end
							return data
						end
						local bits = 14 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
						bufferWriteBits(data, 14, 32, magnitude % 4294967296)
						bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
						return data
					end
				end
				local data: buffer = bufferCreate(EXACT_F64_BYTES)
				bufferWriteU8(data, 0, 255)
				bufferWriteF64(data, 1, value)
				return data
			end
		end
	end
	return coldDiv(a, b)
end
function NanoNum.pow(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then
		ax = a :: number
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then
		local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(av, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(av, offset, n)
				else
					magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296
				end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then
		bx = b :: number
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then
		local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(bv, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(bv, offset, n)
				else
					magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296
				end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		if bx == 0 or ax == 1 then
			local value: number = 1
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
		if ax >= 0 or bx == floor(bx) then
			local value = ax ^ bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				local integral: number = floor(value)
				if value == integral then
					if value >= 0 and value <= 127 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, value * 2)
						return data
					end
					if value < 0 and value >= -64 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
						return data
					end
					local negative = value < 0
					local magnitude = negative and -value or value
					if magnitude <= SAFE_INTEGER then
						local n: number = bitsRequired(magnitude)
						if n <= 31 then
							local bits = 9 + n
							local data: buffer = bufferCreate(floor((bits + 7) / 8))
							local header = 3 + (negative and 8 or 0) + n * 16
							if bits <= 32 then
								bufferWriteBits(data, 0, bits, header + magnitude * 512)
							else
								bufferWriteBits(data, 0, 9, header)
								bufferWriteBits(data, 9, n, magnitude)
							end
							return data
						end
						local bits = 14 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
						bufferWriteBits(data, 14, 32, magnitude % 4294967296)
						bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
						return data
					end
				end
				local data: buffer = bufferCreate(EXACT_F64_BYTES)
				bufferWriteU8(data, 0, 255)
				bufferWriteF64(data, 1, value)
				return data
			end
		end
	end
	return coldPow(a, b)
end
function NanoNum.compare(a: MathValue, b: MathValue): number
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local ax = a :: number
		local bx = b :: number
		if ax ~= ax or bx ~= bx then return NAN end
		if ax < bx then return -1 end
		if ax > bx then return 1 end
		return 0
	end
	if at == "buffer" and bt == "buffer" then
		local av = a :: buffer
		local bv = b :: buffer
		local af: number = bufferReadU8(av, 0)
		local bf: number = bufferReadU8(bv, 0)
		if af == 255 and bf == 255 then
			local ax: number = bufferReadF64(av, 1)
			local bx: number = bufferReadF64(bv, 1)
			if ax ~= ax or bx ~= bx then return NAN end
			if ax < bx then return -1 end
			if ax > bx then return 1 end
			return 0
		end
		local ax, bx
		if band(af, 1) == 0 then ax = floor(af / 2) elseif band(af, 3) == 1 then ax = -(floor(af / 4) + 1) end
		if band(bf, 1) == 0 then bx = floor(bf / 2) elseif band(bf, 3) == 1 then bx = -(floor(bf / 4) + 1) end
		if ax ~= nil and bx ~= nil then
			if ax < bx then return -1 end
			if ax > bx then return 1 end
			return 0
		end
	end
	return coldCompare(a, b)
end
function NanoNum.eq(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; if ax ~= ax then return false end; adirect = ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; if bx ~= bx then return false end; bdirect = bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then return ax == bx end
	local cmp = coldCompare(a, b)
	return cmp == cmp and cmp == 0
end
function NanoNum.lt(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; if ax ~= ax then return false end; adirect = ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; if bx ~= bx then return false end; bdirect = bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then return ax < bx end
	local cmp = coldCompare(a, b)
	return cmp == cmp and cmp < 0
end
function NanoNum.lte(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; if ax ~= ax then return false end; adirect = ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; if bx ~= bx then return false end; bdirect = bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then return ax <= bx end
	local cmp = coldCompare(a, b)
	return cmp == cmp and cmp <= 0
end
function NanoNum.gt(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; if ax ~= ax then return false end; adirect = ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; if bx ~= bx then return false end; bdirect = bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then return ax > bx end
	local cmp = coldCompare(a, b)
	return cmp == cmp and cmp > 0
end
function NanoNum.gte(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; if ax ~= ax then return false end; adirect = ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; if bx ~= bx then return false end; bdirect = bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then return ax >= bx end
	local cmp = coldCompare(a, b)
	return cmp == cmp and cmp >= 0
end
function NanoNum.sign(value: MathValue): number
	local kind = typeof(value)
	if kind == "number" then
		local x = value :: number
		if x ~= x then return NAN end
		if x < 0 then return -1 end
		if x > 0 then return 1 end
		return 0
	end
	if kind == "buffer" then
		local data = value :: buffer
		local x, direct = 0, false
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
		if direct then
			if x < 0 then return -1 end
			if x > 0 then return 1 end
			return 0
		end
	end
	return coldSign(value)
end
function NanoNum.neg(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (true) then
		local result = -x
		if result == result and result ~= huge and result ~= -huge then
			return encodeNumber(result)
		end
	end
	return coldNeg(value)
end
function NanoNum.abs(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (true) then
		local result = x < 0 and -x or x
		if result == result and result ~= huge and result ~= -huge then
			return encodeNumber(result)
		end
	end
	return coldAbs(value)
end
function NanoNum.reciprocal(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct then
		if x == 0 then return makeSpecial(SPECIAL_POS_INF) end
		local result = 1 / x
		if result ~= 0 and result ~= huge and result ~= -huge then
			return encodeNumber(result)
		end
	end
	return coldReciprocal(value)
end
function NanoNum.copySign(value: MathValue, signSource: MathValue): buffer
	local k, a, b = decodeReg(value)
	local sk = decodeReg(signSource)
	if abs(k) == K_NAN or abs(sk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if sk < 0 then k = -abs(k) else k = abs(k) end
	return encodeReg(k, a, b)
end
function NanoNum.toNumber(value: MathValue): number
	local kind = typeof(value)
	if kind == "number" then return value :: number end
	if kind == "buffer" then
		local data = value :: buffer
		local x, direct = 0, false
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
		if direct then return x end
	end
	return coldToNumber(value)
end
function NanoNum.toNumberSafe(value: MathValue): number?
	local k, a, b = directDecode(value)
	local n = regToNumber(k, a, b)
	if n ~= n or n == huge or n == -huge or (n == 0 and k ~= 0) then return nil end
	return n
end
function NanoNum.isNaN(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value ~= value end
	local k = decodeReg(value)
	return abs(k) == K_NAN
end
function NanoNum.isInfinite(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value == huge or value == -huge end
	local k = decodeReg(value)
	return abs(k) == K_INF
end
function NanoNum.isFinite(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value == value and value ~= huge and value ~= -huge end
	local k = decodeReg(value)
	return abs(k) ~= K_NAN and abs(k) ~= K_INF
end
function NanoNum.isZero(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value == 0 end
	local k = decodeReg(value)
	return k == 0
end
function NanoNum.isInteger(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value == value and value ~= huge and value ~= -huge and value == floor(value) end
	local k, a, b = decodeReg(value)
	return regIsInteger(k, a, b)
end
function NanoNum.isOdd(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then if abs(value) <= SAFE_INTEGER then return value == floor(value) and value % 2 ~= 0 end end
	local k, a, b = decodeReg(value)
	return regIsOdd(k, a, b)
end
function NanoNum.isEven(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then if abs(value) <= SAFE_INTEGER then return value == floor(value) and value % 2 == 0 end end
	local k, a, b = decodeReg(value)
	return regIsInteger(k, a, b) and not regIsOdd(k, a, b)
end
function NanoNum.isPositive(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value > 0 and value == value end
	local k = directDecode(value)
	return k > 0 and abs(k) ~= K_NAN
end
function NanoNum.isNegative(value: MathValue): boolean
	-- v2.4.2 primitive fast path: zero allocations and no decoder calls.
	if typeof(value) == "number" then return value < 0 and value == value end
	local k = directDecode(value)
	return k < 0 and abs(k) ~= K_NAN
end
function NanoNum.min(a: MathValue, b: MathValue): buffer
	-- Primitive small-integer fast path: inline one-byte writer, no decode/encode dispatch.
	if typeof(a) == "number" and typeof(b) == "number" then
		local x, y = a :: number, b :: number
		if x == x and y == y and x ~= huge and y ~= huge and x ~= -huge and y ~= -huge then
			local v = a < b and a or b
			if v == floor(v) then
				if v >= 0 and v <= 127 then local data = bufferCreate(1); bufferWriteU8(data, 0, v * 2); return data end
				if v < 0 and v >= -64 then local data = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-v - 1) * 4); return data end
			end
		end
	end
	local at, bt = typeof(a), typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		local value = ax <= bx and ax or bx
		return encodeNumber(value)
	end
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if regCompare(ak, aa, ab, bk, ba, bb) <= 0 then return encodeReg(ak, aa, ab) end
	return encodeReg(bk, ba, bb)
end
function NanoNum.max(a: MathValue, b: MathValue): buffer
	-- Primitive small-integer fast path: inline one-byte writer, no decode/encode dispatch.
	if typeof(a) == "number" and typeof(b) == "number" then
		local x, y = a :: number, b :: number
		if x == x and y == y and x ~= huge and y ~= huge and x ~= -huge and y ~= -huge then
			local v = a > b and a or b
			if v == floor(v) then
				if v >= 0 and v <= 127 then local data = bufferCreate(1); bufferWriteU8(data, 0, v * 2); return data end
				if v < 0 and v >= -64 then local data = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-v - 1) * 4); return data end
			end
		end
	end
	local at, bt = typeof(a), typeof(b)
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	if at == "number" then ax = a :: number; adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif at == "buffer" then local av = a :: buffer
		local first: number = bufferReadU8(av, 0)
		if first == 255 then
			ax = bufferReadF64(av, 1)
			adirect = ax == ax and ax ~= huge and ax ~= -huge
		elseif band(first, 1) == 0 then
			ax = floor(first / 2)
			adirect = true
		elseif band(first, 3) == 1 then
			ax = -(floor(first / 4) + 1)
			adirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(av, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(av, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(av, offset, n)
				else magnitude = bufferReadBits(av, offset, 32) + bufferReadBits(av, offset + 32, n - 32) * 4294967296 end
				ax = negative and -magnitude or magnitude
				adirect = true
			end
		end
	end
	if bt == "number" then bx = b :: number; bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif bt == "buffer" then local bv = b :: buffer
		local first: number = bufferReadU8(bv, 0)
		if first == 255 then
			bx = bufferReadF64(bv, 1)
			bdirect = bx == bx and bx ~= huge and bx ~= -huge
		elseif band(first, 1) == 0 then
			bx = floor(first / 2)
			bdirect = true
		elseif band(first, 3) == 1 then
			bx = -(floor(first / 4) + 1)
			bdirect = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(bv, 4, 5)
			local offset: number = 9
			if n == 0 then n = 32 + bufferReadBits(bv, offset, 5); offset = 14 end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then magnitude = bufferReadBits(bv, offset, n)
				else magnitude = bufferReadBits(bv, offset, 32) + bufferReadBits(bv, offset + 32, n - 32) * 4294967296 end
				bx = negative and -magnitude or magnitude
				bdirect = true
			end
		end
	end
	if adirect and bdirect then
		local value = ax >= bx and ax or bx
		return encodeNumber(value)
	end
	local ak, aa, ab = directDecode(a)
	local bk, ba, bb = directDecode(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if regCompare(ak, aa, ab, bk, ba, bb) >= 0 then return encodeReg(ak, aa, ab) end
	return encodeReg(bk, ba, bb)
end
function NanoNum.clamp(value: MathValue, low: MathValue, high: MathValue): buffer
	local vk, va, vb = decodeReg(value)
	local lk, la, lb = decodeReg(low)
	local hk, ha, hb = decodeReg(high)
	if abs(vk) == K_NAN or abs(lk) == K_NAN or abs(hk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if regCompare(lk, la, lb, hk, ha, hb) > 0 then return makeSpecial(SPECIAL_NAN) end
	if regCompare(vk, va, vb, lk, la, lb) < 0 then return encodeReg(lk, la, lb) end
	if regCompare(vk, va, vb, hk, ha, hb) > 0 then return encodeReg(hk, ha, hb) end
	return encodeReg(vk, va, vb)
end
function NanoNum.clamp01(value: MathValue): buffer return NanoNum.clamp(value, 0, 1) end
function NanoNum.floor(value: MathValue): buffer
	-- Direct finite number kernel: one-byte or exact-f64 encoding without register decoding.
	if typeof(value) == "number" and value == value and value ~= huge and value ~= -huge then
		local n = floor(value)
		if n >= 0 and n <= 127 then local data = bufferCreate(1); bufferWriteU8(data, 0, n * 2); return data end
		if n < 0 and n >= -64 then local data = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-n - 1) * 4); return data end
		return encodeNumber(n)
	end
	local k, a, b = decodeReg(value)
	if abs(k) >= K_LOG and abs(k) <= K_HYPER_LAYER and a < 0 then return NanoNum.fromNumber(k < 0 and -1 or 0) end
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(floor(n)) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER then
		if a < 0 then return NanoNum.fromNumber(k < 0 and -1 or 0) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end
function NanoNum.ceil(value: MathValue): buffer
	-- Direct finite number kernel: one-byte or exact-f64 encoding without register decoding.
	if typeof(value) == "number" and value == value and value ~= huge and value ~= -huge then
		local n = ceil(value)
		if n >= 0 and n <= 127 then local data = bufferCreate(1); bufferWriteU8(data, 0, n * 2); return data end
		if n < 0 and n >= -64 then local data = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-n - 1) * 4); return data end
		return encodeNumber(n)
	end
	local k, a, b = decodeReg(value)
	if abs(k) >= K_LOG and abs(k) <= K_HYPER_LAYER and a < 0 then return NanoNum.fromNumber(k < 0 and 0 or 1) end
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(ceil(n)) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER then
		if a < 0 then return NanoNum.fromNumber(k < 0 and 0 or 1) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end
function NanoNum.trunc(value: MathValue): buffer
	-- Direct finite number kernel: one-byte or exact-f64 encoding without register decoding.
	if typeof(value) == "number" and value == value and value ~= huge and value ~= -huge then
		local n = value < 0 and ceil(value) or floor(value)
		if n >= 0 and n <= 127 then local data = bufferCreate(1); bufferWriteU8(data, 0, n * 2); return data end
		if n < 0 and n >= -64 then local data = bufferCreate(1); bufferWriteU8(data, 0, 1 + (-n - 1) * 4); return data end
		return encodeNumber(n)
	end
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(n < 0 and ceil(n) or floor(n)) end
	if abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if abs(k) == K_INF then return encodeReg(k, a, b) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER then
		if a < 0 then return NanoNum.fromNumber(0) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end
function NanoNum.round(value: MathValue, decimals: number?): buffer
	local places = decimals or 0
	if places ~= floor(places) or places < -308 or places > 308 then return makeSpecial(SPECIAL_NAN) end
	if typeof(value) == "string" then value = NanoNum.fromString(value :: string) end
	local n = directFiniteNumber(value)
	if n ~= nil then
		if n == 0 then return NanoNum.fromNumber(0) end
		if places == 0 then return NanoNum.fromNumber(math.round(n)) end
		if places > 0 then
			local scale = places <= 12 and POW10_DECIMAL[places + 1] or 10 ^ places
			local scaled = n * scale
			if scaled == huge or scaled == -huge then return NanoNum.fromNumber(n) end
			local rounded = math.round(scaled)
			return NanoNum.fromNumber(rounded / scale)
		end
		local digits = -places
		local scale = digits <= 12 and POW10_DECIMAL[digits + 1] or 10 ^ digits
		local scaled = n / scale
		local rounded = math.round(scaled)
		local result = rounded * scale
		if result == huge or result == -huge then return NanoNum.fromLog10(log10(abs(rounded)) - places, rounded < 0) end
		return encodeNumber(result)
	end
	local k, a, b = directDecode(value)
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER then
		if a < 0 then return NanoNum.fromNumber(0) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end
function NanoNum.frac(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	if abs(k) == K_NAN or abs(k) == K_INF then return makeSpecial(SPECIAL_NAN) end
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then
		if n == 0 and k ~= 0 and (abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and a < 0 then return encodeReg(k, a, b) end
		return NanoNum.fromNumber(n - (n < 0 and ceil(n) or floor(n)))
	end
	if regIsInteger(k, a, b) then return NanoNum.fromNumber(0) end
	if (abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and a < 0 then return encodeReg(k, a, b) end
	return makeSpecial(SPECIAL_NAN)
end
local function exactInteger(value: MathValue): number?
	if typeof(value) == "string" then value = NanoNum.fromString(value :: string) end
	local x = directFiniteNumber(value)
	if x ~= nil and x == floor(x) and abs(x) <= SAFE_INTEGER then return x end
	return nil
end
function NanoNum.mod(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN or bk == 0 or abs(ak) == K_INF or abs(bk) == K_INF then return makeSpecial(SPECIAL_NAN) end
	local x = regToNumber(ak, aa, ab)
	local y = regToNumber(bk, ba, bb)
	if x == x and y == y and x ~= huge and x ~= -huge and y ~= huge and y ~= -huge and y ~= 0 then
		return NanoNum.fromNumber(x % y)
	end
	return makeSpecial(SPECIAL_NAN)
end
function NanoNum.fmod(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN or bk == 0 or abs(ak) == K_INF then return makeSpecial(SPECIAL_NAN) end
	if abs(bk) == K_INF then return encodeReg(ak, aa, ab) end
	local x = regToNumber(ak, aa, ab)
	local y = regToNumber(bk, ba, bb)
	if x == x and y == y and x ~= huge and x ~= -huge and y ~= huge and y ~= -huge and y ~= 0 then
		local r = math.fmod(x, y)
		return NanoNum.fromNumber(r)
	end
	return makeSpecial(SPECIAL_NAN)
end
function NanoNum.divmod(a: MathValue, b: MathValue): (buffer, buffer)
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN or bk == 0 or abs(ak) == K_INF or abs(bk) == K_INF then
		local nan = makeSpecial(SPECIAL_NAN)
		return nan, nan
	end
	local x = regToNumber(ak, aa, ab)
	local y = regToNumber(bk, ba, bb)
	if x == x and y == y and x ~= huge and x ~= -huge and y ~= huge and y ~= -huge and y ~= 0 then
		local r = x % y
		local quotient = x / y
		if quotient == huge or quotient == -huge then return NanoNum.floor(NanoNum.div(a, b)), encodeNumber(r) end
		return encodeNumber(floor(quotient)), encodeNumber(r)
	end
	local nan = makeSpecial(SPECIAL_NAN)
	return nan, nan
end
function NanoNum.log10(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (x > 0) then
		local result: number = log10(x)
		if result == result and result ~= huge and result ~= -huge and (result ~= 0 or x == 1) then
			return encodeNumber(result)
		end
	end
	return coldLog10(value)
end
function NanoNum.ln(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (x > 0) then
		local result: number = log(x)
		if result == result and result ~= huge and result ~= -huge and (result ~= 0 or x == 1) then
			return encodeNumber(result)
		end
	end
	return coldLn(value)
end
function NanoNum.log(value: MathValue, base: MathValue?): buffer
	if base == nil then
		local k, a, b = directDecode(value)
		k, a, b = regLog10(k, a, b)
		local ck, ca, cb = regFromNumber(LN10)
		k, a, b = regMul(k, a, b, ck, ca, cb)
		return encodeReg(k, a, b)
	end
	local vk, va, vb = decodeReg(value)
	local bk, ba, bb = decodeReg(base)
	if abs(bk) == K_NAN or abs(bk) == K_INF or regCompare(bk, ba, bb, 0, 0, 0) <= 0 or regCompare(bk, ba, bb, K_NUM, 1, 0) == 0 then return makeSpecial(SPECIAL_NAN) end
	local lk, la, lb = regLog10(vk, va, vb)
	local rk, ra, rb = regLog10(bk, ba, bb)
	lk, la, lb = regDiv(lk, la, lb, rk, ra, rb)
	return encodeReg(lk, la, lb)
end
function NanoNum.log2(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (x > 0) then
		local result: number = log(x, 2)
		if result == result and result ~= huge and result ~= -huge and (result ~= 0 or x == 1) then
			return encodeNumber(result)
		end
	end
	return coldLog2(value)
end
function NanoNum.log1p(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n == 0 and k ~= 0 and (abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and a < 0 then return encodeReg(k, a, b) end
	if n == n and n ~= huge and n ~= -huge then
		if n < -1 then return makeSpecial(SPECIAL_NAN) end
		if n == -1 then return makeSpecial(SPECIAL_NEG_INF) end
		if abs(n) < 1e-5 then
			local n2 = n * n
			local n3 = n2 * n
			local n4 = n3 * n
			local n5 = n4 * n
			local n6 = n5 * n
			return NanoNum.fromNumber(n - n2 / 2 + n3 / 3 - n4 / 4 + n5 / 5 - n6 / 6)
		end
		return NanoNum.fromNumber(log(1 + n))
	end
	return NanoNum.ln(NanoNum.add(1, value))
end
function NanoNum.exp(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (true) then
		local result: number = exp(x)
		if result == result and result ~= huge and result ~= -huge and result ~= 0 then
			return encodeNumber(result)
		end
	end
	return coldExp(value)
end
function NanoNum.exp2(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (true) then
		local result = 2 ^ x
		if result == result and result ~= huge and result ~= -huge and result ~= 0 then
			return encodeNumber(result)
		end
	end
	return coldExp2(value)
end
function NanoNum.expm1(value: MathValue): buffer
	local k, a, b = directDecode(value)
	local n = regToNumber(k, a, b)
	if n == 0 and k ~= 0 and (abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and a < 0 then return encodeReg(k, a, b) end
	if n == n and n ~= huge and n ~= -huge then
		if abs(n) < 1e-5 then
			local n2 = n * n
			local n3 = n2 * n
			local n4 = n3 * n
			local n5 = n4 * n
			local n6 = n5 * n
			return NanoNum.fromNumber(n + n2 / 2 + n3 / 6 + n4 / 24 + n5 / 120 + n6 / 720)
		end
		local native = exp(n) - 1
		if native == native and native ~= huge and native ~= -huge then return NanoNum.fromNumber(native) end
	end
	local ck, ca, cb = regFromNumber(LOG10_E)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	k, a, b = regPow10(k, a, b)
	local oneK, oneA, oneB = K_NUM, 1, 0
	k, a, b = regSub(k, a, b, oneK, oneA, oneB)
	return encodeReg(k, a, b)
end
function NanoNum.pow10(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end
function NanoNum.powInt(base: MathValue, exponent: MathValue): buffer
	local ek, ea, eb = directDecode(exponent)
	if not regIsInteger(ek, ea, eb) then return makeSpecial(SPECIAL_NAN) end
	local bk, ba, bb = directDecode(base)
	bk, ba, bb = regPow(bk, ba, bb, ek, ea, eb)
	return encodeReg(bk, ba, bb)
end
function NanoNum.sqrt(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (x >= 0) then
		local result: number = sqrt(x)
		if result == result and result ~= huge and result ~= -huge and (result ~= 0 or x == 0) then
			return encodeNumber(result)
		end
	end
	return coldSqrt(value)
end
function NanoNum.cbrt(value: MathValue): buffer
	local kind = typeof(value)
	local x, direct = 0, false
	if kind == "number" then
		x = value :: number
		direct = x == x and x ~= huge and x ~= -huge
	elseif kind == "buffer" then
		local data = value :: buffer
		local first: number = bufferReadU8(data, 0)
		if first == 255 then
			x = bufferReadF64(data, 1)
			direct = x == x and x ~= huge and x ~= -huge
		elseif band(first, 1) == 0 then
			x = floor(first / 2)
			direct = true
		elseif band(first, 3) == 1 then
			x = -(floor(first / 4) + 1)
			direct = true
		elseif band(first, 7) == 3 then
			local negative = band(first, 8) ~= 0
			local n: number = bufferReadBits(data, 4, 5)
			local offset: number = 9
			if n == 0 then
				n = 32 + bufferReadBits(data, offset, 5)
				offset = 14
			end
			if n <= MAX_INTEGER_MODE_BITS then
				local magnitude
				if n <= 32 then
					magnitude = bufferReadBits(data, offset, n)
				else
					magnitude = bufferReadBits(data, offset, 32) + bufferReadBits(data, offset + 32, n - 32) * 4294967296
				end
				x = negative and -magnitude or magnitude
				direct = true
			end
		end
	end
	if direct and (true) then
		local result = x < 0 and -((-x) ^ (1 / 3)) or x ^ (1 / 3)
		-- Floating cube roots can miss exact integer cubes by a few ulps. Snap only when the cube is provably exact.
		if x == floor(x) and abs(x) <= SAFE_INTEGER and result == result then
			local nearest: number = floor(abs(result) + 0.001)
			if nearest <= 208063 and nearest * nearest * nearest == abs(x) then result = x < 0 and -nearest or nearest end
		end
		if result == result and result ~= huge and result ~= -huge and (result ~= 0 or x == 0) then
			return encodeNumber(result)
		end
	end
	return coldCbrt(value)
end
function NanoNum.root(value: MathValue, degree: MathValue): buffer
	local vk, va, vb = decodeReg(value)
	local dk, da, db = decodeReg(degree)
	if abs(vk) == K_NAN or abs(dk) == K_NAN or dk == 0 then return makeSpecial(SPECIAL_NAN) end
	if abs(dk) == K_INF then
		if vk < 0 then return makeSpecial(SPECIAL_NAN) end
		if dk > 0 then
			if vk == 0 then return NanoNum.fromNumber(0) end
			if abs(vk) == K_INF then return makeSpecial(SPECIAL_POS_INF) end
			return NanoNum.fromNumber(1)
		end
		if vk == 0 then return makeSpecial(SPECIAL_POS_INF) end
		if abs(vk) == K_INF then return NanoNum.fromNumber(0) end
		return NanoNum.fromNumber(1)
	end
	if vk < 0 and not regIsOdd(dk, da, db) then return makeSpecial(SPECIAL_NAN) end
	local oneK, oneA, oneB = K_NUM, 1, 0
	dk, da, db = regDiv(oneK, oneA, oneB, dk, da, db)
	local negative = vk < 0
	if negative then vk = -vk end
	vk, va, vb = regPow(vk, va, vb, dk, da, db)
	if negative and vk ~= 0 and abs(vk) ~= K_NAN then vk = -vk end
	return encodeReg(vk, va, vb)
end
function NanoNum.square(value: MathValue): buffer
	local x = directFiniteNumber(value)
	if x ~= nil then
		local result = x * x
		if result ~= huge and (result ~= 0 or x == 0) then return NanoNum.fromNumber(result) end
	end
	local k, a, b = decodeReg(value)
	k, a, b = regMul(k, a, b, k, a, b)
	return encodeReg(k, a, b)
end
function NanoNum.cube(value: MathValue): buffer
	local x = directFiniteNumber(value)
	if x ~= nil then
		local result = x * x * x
		if result ~= huge and result ~= -huge and (result ~= 0 or x == 0) then return NanoNum.fromNumber(result) end
	end
	local k, a, b = decodeReg(value)
	local k2, a2, b2 = regMul(k, a, b, k, a, b)
	k, a, b = regMul(k2, a2, b2, k, a, b)
	return encodeReg(k, a, b)
end
function NanoNum.hypot(a: MathValue, b: MathValue): buffer
	local x = directFiniteNumber(a)
	local y = directFiniteNumber(b)
	if x ~= nil and y ~= nil then
		x = abs(x); y = abs(y)
		local m: number = max(x, y)
		if m == 0 then return NanoNum.fromNumber(0) end
		local sx = x / m
		local sy = y / m
		local result = m * sqrt(sx * sx + sy * sy)
		if result ~= huge then return NanoNum.fromNumber(result) end
	end
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if abs(ak) == K_INF or abs(bk) == K_INF then return makeSpecial(SPECIAL_POS_INF) end
	if abs(ak) == K_NAN or abs(bk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	local a2k, a2a, a2b = regMul(ak, aa, ab, ak, aa, ab)
	local b2k, b2a, b2b = regMul(bk, ba, bb, bk, ba, bb)
	local sk, sa, sb = regAdd(a2k, a2a, a2b, b2k, b2a, b2b)
	sk, sa, sb = regPow(sk, sa, sb, K_NUM, 0.5, 0)
	return encodeReg(sk, sa, sb)
end
function NanoNum.lerp(a: MathValue, b: MathValue, t: MathValue): buffer
	local x = directFiniteNumber(a)
	local y = directFiniteNumber(b)
	local f = directFiniteNumber(t)
	if x ~= nil and y ~= nil and f ~= nil then
		local result = nativeLerp(x, y, f)
		if result == result and result ~= huge and result ~= -huge then return NanoNum.fromNumber(result) end
	end
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	local tk, ta, tb = decodeReg(t)
	if abs(ak) == K_NAN or abs(bk) == K_NAN or abs(tk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if tk == 0 then return encodeReg(ak, aa, ab) end
	if regCompare(tk, ta, tb, K_NUM, 1, 0) == 0 then return encodeReg(bk, ba, bb) end
	if regCompare(ak, aa, ab, bk, ba, bb) == 0 then return encodeReg(ak, aa, ab) end
	local dk, da, db = regSub(bk, ba, bb, ak, aa, ab)
	dk, da, db = regMul(dk, da, db, tk, ta, tb)
	ak, aa, ab = regAdd(ak, aa, ab, dk, da, db)
	return encodeReg(ak, aa, ab)
end
function NanoNum.inverseLerp(a: MathValue, b: MathValue, value: MathValue): buffer
	local x = directFiniteNumber(a)
	local y = directFiniteNumber(b)
	local v = directFiniteNumber(value)
	if x ~= nil and y ~= nil and v ~= nil then
		local result = nativeInverseLerp(x, y, v)
		if result == nil then return makeSpecial(SPECIAL_NAN) end
		if result == result and result ~= huge and result ~= -huge then return NanoNum.fromNumber(result) end
	end
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	local vk, va, vb = decodeReg(value)
	local dk, da, db = regSub(bk, ba, bb, ak, aa, ab)
	if dk == 0 then return makeSpecial(SPECIAL_NAN) end
	vk, va, vb = regSub(vk, va, vb, ak, aa, ab)
	vk, va, vb = regDiv(vk, va, vb, dk, da, db)
	return encodeReg(vk, va, vb)
end
function NanoNum.remap(value: MathValue, inMin: MathValue, inMax: MathValue, outMin: MathValue, outMax: MathValue): buffer
	local v = directFiniteNumber(value)
	local a = directFiniteNumber(inMin)
	local b = directFiniteNumber(inMax)
	local c = directFiniteNumber(outMin)
	local d = directFiniteNumber(outMax)
	if v ~= nil and a ~= nil and b ~= nil and c ~= nil and d ~= nil then
		local t = nativeInverseLerp(a, b, v)
		if t == nil then return makeSpecial(SPECIAL_NAN) end
		local result = nativeLerp(c, d, t)
		if result == result and result ~= huge and result ~= -huge then return NanoNum.fromNumber(result) end
	end
	local t = NanoNum.inverseLerp(inMin, inMax, value)
	if NanoNum.isNaN(t) then return t end
	return NanoNum.lerp(outMin, outMax, t)
end
function NanoNum.moveTowards(current: MathValue, target: MathValue, maxDelta: MathValue): buffer
	if NanoNum.isNaN(maxDelta) or NanoNum.lt(maxDelta, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(current, target) then return NanoNum.compile(target) end
	local delta = NanoNum.sub(target, current)
	if NanoNum.lte(NanoNum.abs(delta), maxDelta) then return NanoNum.compile(target) end
	return NanoNum.add(current, NanoNum.mul(maxDelta, NanoNum.sign(delta)))
end
function NanoNum.distance(a: MathValue, b: MathValue): buffer
	local x = directFiniteNumber(a)
	local y = directFiniteNumber(b)
	if x ~= nil and y ~= nil then
		local result: number = abs(x - y)
		if result ~= huge then return NanoNum.fromNumber(result) end
	end
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if abs(ak) == K_NAN or abs(bk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if regCompare(ak, aa, ab, bk, ba, bb) == 0 then return NanoNum.fromNumber(0) end
	ak, aa, ab = regSub(ak, aa, ab, bk, ba, bb)
	ak = abs(ak)
	return encodeReg(ak, aa, ab)
end
function NanoNum.ratio(a: MathValue, b: MathValue): buffer return NanoNum.div(a, b) end
function NanoNum.relativeDifference(a: MathValue, b: MathValue): buffer
	local diff = NanoNum.distance(a, b)
	local scale = NanoNum.max(NanoNum.abs(a), NanoNum.abs(b))
	if NanoNum.isZero(scale) then return NanoNum.fromNumber(0) end
	return NanoNum.div(diff, scale)
end
function NanoNum.approxEq(a: MathValue, b: MathValue, relativeTolerance: MathValue?, absoluteTolerance: MathValue?): boolean
	if NanoNum.isNaN(a) or NanoNum.isNaN(b) then return false end
	if NanoNum.eq(a, b) then return true end
	if NanoNum.isInfinite(a) or NanoNum.isInfinite(b) then return false end
	local rel = relativeTolerance or 1e-9
	local absTol = absoluteTolerance or 0
	if NanoNum.isNaN(rel) or NanoNum.isNaN(absTol) or NanoNum.lt(rel, 0) or NanoNum.lt(absTol, 0) then return false end
	local diff = NanoNum.distance(a, b)
	if NanoNum.lte(diff, absTol) then return true end
	local scale = NanoNum.max(NanoNum.abs(a), NanoNum.abs(b))
	return NanoNum.lte(diff, NanoNum.mul(scale, rel))
end
function NanoNum.orderOfMagnitude(value: MathValue): buffer
	if NanoNum.isZero(value) or NanoNum.isNaN(value) then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.floor(NanoNum.log10(NanoNum.abs(value)))
end
function NanoNum.digitCount(value: MathValue): buffer
	if NanoNum.isNaN(value) or NanoNum.isInfinite(value) then return makeSpecial(SPECIAL_NAN) end
	local magnitude = NanoNum.abs(value)
	if NanoNum.lt(magnitude, 1) then return NanoNum.fromNumber(1) end
	return NanoNum.add(NanoNum.floor(NanoNum.log10(magnitude)), 1)
end
function NanoNum.smoothstep(edge0: MathValue, edge1: MathValue, value: MathValue): buffer
	local a = directFiniteNumber(edge0)
	local b = directFiniteNumber(edge1)
	local v = directFiniteNumber(value)
	if a ~= nil and b ~= nil and v ~= nil and a ~= b then
		local raw = nativeInverseLerp(a, b, v)
		if raw ~= nil then local t: number = clamp(raw, 0, 1); return NanoNum.fromNumber(t * t * (3 - 2 * t)) end
	end
	local t = NanoNum.clamp01(NanoNum.inverseLerp(edge0, edge1, value))
	return NanoNum.mul(NanoNum.mul(t, t), NanoNum.sub(3, NanoNum.mul(2, t)))
end
function NanoNum.smootherstep(edge0: MathValue, edge1: MathValue, value: MathValue): buffer
	local a = directFiniteNumber(edge0)
	local b = directFiniteNumber(edge1)
	local v = directFiniteNumber(value)
	if a ~= nil and b ~= nil and v ~= nil and a ~= b then
		local raw = nativeInverseLerp(a, b, v)
		if raw ~= nil then
			local t: number = clamp(raw, 0, 1)
			local t2 = t * t
			local t3 = t2 * t
			return NanoNum.fromNumber(t3 * (t * (t * 6 - 15) + 10))
		end
	end
	local t = NanoNum.clamp01(NanoNum.inverseLerp(edge0, edge1, value))
	local t2 = NanoNum.mul(t, t)
	local t3 = NanoNum.mul(t2, t)
	return NanoNum.mul(t3, NanoNum.add(NanoNum.mul(t, NanoNum.sub(NanoNum.mul(6, t), 15)), 10))
end
-- Cold overflow path: cancel opposite signs before adding same-sign magnitudes.
-- Keep subtraction residuals so large cancellation does not discard small terms.
local function finiteCancellationSum(values: MathValueArray): buffer?
	local positives, negatives, residuals = {}, {}, {}
	for i = 1, #values do
		local x = directFiniteNumber(values[i])
		if x == nil then return nil end
		if x > 0 then positives[#positives + 1] = x elseif x < 0 then negatives[#negatives + 1] = -x end
	end
	table.sort(positives)
	table.sort(negatives)
	local ip, im = #positives, #negatives
	while ip > 0 and im > 0 do
		local x, y = positives[ip], -negatives[im]
		local sum = x + y
		local residual = abs(x) >= abs(y) and ((x - sum) + y) or ((y - sum) + x)
		if residual ~= 0 then residuals[#residuals + 1] = residual end
		if sum > 0 then positives[ip] = sum; im -= 1
		elseif sum < 0 then negatives[im] = -sum; ip -= 1
		else ip -= 1; im -= 1 end
	end
	for j = 1, ip do residuals[#residuals + 1] = positives[j] end
	for j = 1, im do residuals[#residuals + 1] = -negatives[j] end
	local total, correction = 0, 0
	for j = 1, #residuals do
		local x = residuals[j]
		local nextTotal = total + x
		if nextTotal == huge or nextTotal == -huge then
			local rk, ra, rb = regFromNumber(total)
			local ck, ca, cb = regFromNumber(correction)
			rk, ra, rb = regAdd(rk, ra, rb, ck, ca, cb)
			for n = j, #residuals do
				local vk, va, vb = regFromNumber(residuals[n])
				rk, ra, rb = regAdd(rk, ra, rb, vk, va, vb)
			end
			return encodeReg(rk, ra, rb)
		end
		if abs(total) >= abs(x) then correction += (total - nextTotal) + x else correction += (x - nextTotal) + total end
		total = nextTotal
	end
	local result = total + correction
	if result ~= huge and result ~= -huge then return encodeNumber(result) end
	return NanoNum.add(total, correction)
end
function NanoNum.sum(values: MathValueArray): buffer
	local total, correction = 0, 0
	local direct: boolean = true
	for i = 1, #values do
		local x = directFiniteNumber(values[i])
		if x == nil then direct = false; break end
		local nextTotal = total + x
		if nextTotal == huge or nextTotal == -huge then direct = false; break end
		if abs(total) >= abs(x) then correction += (total - nextTotal) + x else correction += (x - nextTotal) + total end
		total = nextTotal
	end
	if direct then
		local corrected = total + correction
		if corrected == corrected and corrected ~= huge and corrected ~= -huge then return NanoNum.fromNumber(corrected) end
	end
	local finite = finiteCancellationSum(values)
	if finite ~= nil then return finite end
	local rk, ra, rb = 0, 0, 0
	for i = 1, #values do
		local vk, va, vb = decodeReg(values[i])
		rk, ra, rb = regAdd(rk, ra, rb, vk, va, vb)
	end
	return encodeReg(rk, ra, rb)
end
function NanoNum.product(values: MathValueArray): buffer
	local total: number = 1
	local direct: boolean = true
	for i = 1, #values do
		local x = directFiniteNumber(values[i])
		if x == nil then direct = false; break end
		local nextValue = total * x
		if nextValue ~= nextValue or nextValue == huge or nextValue == -huge or (nextValue == 0 and total ~= 0 and x ~= 0) then direct = false; break end
		total = nextValue
	end
	if direct then return NanoNum.fromNumber(total) end
	local rk, ra, rb = K_NUM, 1, 0
	for i = 1, #values do
		local vk, va, vb = decodeReg(values[i])
		rk, ra, rb = regMul(rk, ra, rb, vk, va, vb)
	end
	return encodeReg(rk, ra, rb)
end
function NanoNum.mean(values: MathValueArray): buffer
	local count = #values
	if count == 0 then return makeSpecial(SPECIAL_NAN) end
	local total, correction = 0, 0
	local direct: boolean = true
	for i = 1, count do
		local x = directFiniteNumber(values[i])
		if x == nil then direct = false; break end
		local nextTotal = total + x
		if nextTotal == huge or nextTotal == -huge then direct = false; break end
		if abs(total) >= abs(x) then correction += (total - nextTotal) + x else correction += (x - nextTotal) + total end
		total = nextTotal
	end
	if direct then
		local corrected = total + correction
		local result = corrected / count
		if corrected == corrected and corrected ~= huge and corrected ~= -huge and result == result and result ~= huge and result ~= -huge and (result ~= 0 or corrected == 0) then return NanoNum.fromNumber(result) end
	end
	return NanoNum.div(NanoNum.sum(values), count)
end
function NanoNum.geometricMean(values: MathValueArray): buffer
	if #values == 0 then return makeSpecial(SPECIAL_NAN) end
	local totalK: number = 0
	local totalA: number = 0
	local totalB: number = 0
	local hasZero: boolean = false
	local hasInfinity: boolean = false
	for i = 1, #values do
		local k, a, b = decodeReg(values[i])
		if abs(k) == K_NAN or k < 0 then return makeSpecial(SPECIAL_NAN) end
		if k == 0 then hasZero = true
		elseif abs(k) == K_INF then hasInfinity = true
		else
			k, a, b = regLog10(k, a, b)
			totalK, totalA, totalB = regAdd(totalK, totalA, totalB, k, a, b)
		end
	end
	if hasZero then return hasInfinity and makeSpecial(SPECIAL_NAN) or NanoNum.fromNumber(0) end
	if hasInfinity then return makeSpecial(SPECIAL_POS_INF) end
	local ck, ca, cb = regFromNumber(#values)
	totalK, totalA, totalB = regDiv(totalK, totalA, totalB, ck, ca, cb)
	totalK, totalA, totalB = regPow10(totalK, totalA, totalB)
	return encodeReg(totalK, totalA, totalB)
end
function NanoNum.harmonicMean(values: MathValueArray): buffer
	local count = #values
	if count == 0 then return makeSpecial(SPECIAL_NAN) end
	local reciprocalSum: number = 0
	local direct: boolean = true
	for i = 1, count do
		local x = directFiniteNumber(values[i])
		if x == nil then direct = false; break end
		if x == 0 then direct = false; break end
		reciprocalSum += 1 / x
		if reciprocalSum ~= reciprocalSum or reciprocalSum == huge or reciprocalSum == -huge then direct = false; break end
	end
	if direct then
		if reciprocalSum == 0 then return makeSpecial(SPECIAL_NAN) end
		local result = count / reciprocalSum
		if result == result and result ~= huge and result ~= -huge and result ~= 0 then return NanoNum.fromNumber(result) end
		direct = false
	end
	local totalK, totalA, totalB = 0, 0, 0
	local hasZero: boolean = false
	local onlyInfinite: boolean = true
	local infinitySign: number = 0
	for i = 1, count do
		local k, a, b = decodeReg(values[i])
		if abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
		if k == 0 then hasZero = true end
		if abs(k) == K_INF then
			local sign = k < 0 and -1 or 1
			if infinitySign == 0 then infinitySign = sign elseif infinitySign ~= sign then infinitySign = 2 end
		else
			onlyInfinite = false
		end
		k, a, b = regReciprocal(k, a, b)
		totalK, totalA, totalB = regAdd(totalK, totalA, totalB, k, a, b)
	end
	if hasZero then return NanoNum.fromNumber(0) end
	if totalK == 0 then
		if onlyInfinite and infinitySign == 1 then return makeSpecial(SPECIAL_POS_INF) end
		if onlyInfinite and infinitySign == -1 then return makeSpecial(SPECIAL_NEG_INF) end
		return makeSpecial(SPECIAL_NAN)
	end
	local ck, ca, cb = regFromNumber(count)
	ck, ca, cb = regDiv(ck, ca, cb, totalK, totalA, totalB)
	return encodeReg(ck, ca, cb)
end
local FACTORIAL_NUMBER_CACHE = tableCreate(171)
local LOG_FACTORIAL_CACHE = tableCreate(257)
do
	local factorialValue: number = 1
	local logValue: number = 0
	FACTORIAL_NUMBER_CACHE[1] = 1
	LOG_FACTORIAL_CACHE[1] = 0
	for i = 1, 256 do
		logValue += log10(i)
		LOG_FACTORIAL_CACHE[i + 1] = logValue
		if i <= 170 then factorialValue *= i; FACTORIAL_NUMBER_CACHE[i + 1] = factorialValue end
	end
end
local function factorialLog10(n: number): number
	if n < 2 then return 0 end
	if n <= 256 then return LOG_FACTORIAL_CACHE[n + 1] end
	local inv = 1 / n
	local inv2 = inv * inv
	local inv3 = inv2 * inv
	local inv5 = inv3 * inv2
	local correction = inv / 12 - inv3 / 360 + inv5 / 1260
	return (n + 0.5) * log10(n) - n * LOG10_E + 0.5 * log10(TWO_PI) + correction * LOG10_E
end
function NanoNum.factorial(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	if abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if abs(k) == K_INF then return k > 0 and makeSpecial(SPECIAL_POS_INF) or makeSpecial(SPECIAL_NAN) end
	if k < 0 or not regIsInteger(k, a, b) then return makeSpecial(SPECIAL_NAN) end
	if k == 0 then return NanoNum.fromNumber(1) end
	if abs(k) == K_NUM and a <= SAFE_INTEGER then
		local n = a
		if n <= 1 then return NanoNum.fromNumber(1) end
		if n <= 170 then return NanoNum.fromNumber(FACTORIAL_NUMBER_CACHE[n + 1]) end
		return NanoNum.fromLog10(factorialLog10(n))
	end
	return NanoNum.gamma(NanoNum.add(value, 1))
end
local function nativeGCD(a: number, b: number): number
	a = abs(a); b = abs(b)
	while b ~= 0 do a, b = b, a % b end
	return a
end
local function logGammaDirect(x: number): number
	if x <= 0 then return NAN end
	if x == 1 or x == 2 then return 0 end
	-- Recurrence avoids cancellation in x-1 near zero inside Lanczos.
	if x < 0.5 then return logGammaDirect(x + 1) - log(x) end
	local z = x - 1
	local a: number = 0.99999999999980993
	a += 676.5203681218851 / (z + 1)
	a -= 1259.1392167224028 / (z + 2)
	a += 771.32342877765313 / (z + 3)
	a -= 176.61502916214059 / (z + 4)
	a += 12.507343278686905 / (z + 5)
	a -= 0.13857109526572012 / (z + 6)
	a += 9.9843695780195716e-6 / (z + 7)
	a += 1.5056327351493116e-7 / (z + 8)
	local t = z + 7.5
	return 0.5 * log(TWO_PI) + (z + 0.5) * log(t) - t + log(a)
end
function NanoNum.gammaSign(value: MathValue): number
	local k, a, b = decodeReg(value)
	local absoluteKind: number = abs(k)
	if absoluteKind == K_NAN then return NAN end
	if absoluteKind == K_INF then return k > 0 and 1 or NAN end
	if k == 0 then return 0 end
	if k > 0 then return 1 end
	local n = regToNumber(k, a, b)
	if n == n and n ~= -huge and n ~= 0 then
		if n == floor(n) then return 0 end
		return floor(-n) % 2 == 0 and -1 or 1
	end
	if (absoluteKind == K_LOG or absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG or absoluteKind == K_HYPER_LAYER) and a < 0 then return -1 end
	if regIsInteger(k, a, b) then return 0 end
	return NAN
end
function NanoNum.logGamma(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local absoluteKind: number = abs(k)
	if absoluteKind == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if absoluteKind == K_INF then return k > 0 and makeSpecial(SPECIAL_POS_INF) or makeSpecial(SPECIAL_NAN) end
	if (absoluteKind == K_LOG or absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG or absoluteKind == K_HYPER_LAYER) and a < 0 then
		return NanoNum.neg(NanoNum.ln(NanoNum.abs(encodeReg(k, a, b))))
	end
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then
		if n == 0 or (n < 0 and n == floor(n)) then return makeSpecial(SPECIAL_POS_INF) end
		if abs(n) < 1e-8 then return encodeNumber(-log(abs(n)) - 0.5772156649015329 * n) end
		if n > 0 then
			local native = logGammaDirect(n)
			if native == native and native ~= huge and native ~= -huge then return NanoNum.fromNumber(native) end
		else
			local fraction = n - floor(n)
			local reduced: number = min(fraction, 1 - fraction)
			local sine: number = sin(pi * reduced)
			if sine == 0 then return makeSpecial(SPECIAL_POS_INF) end
			local reflected = logGammaDirect(1 - n)
			if reflected == reflected and reflected ~= huge then return NanoNum.fromNumber(log(pi) - log(sine) - reflected) end
			return makeSpecial(SPECIAL_NAN)
		end
	end
	if k <= 0 then return makeSpecial(SPECIAL_NAN) end
	local x = encodeReg(k, a, b)
	local main = NanoNum.sub(NanoNum.mul(NanoNum.sub(x, 0.5), NanoNum.ln(x)), x)
	local result = NanoNum.add(main, 0.5 * log(TWO_PI))
	if NanoNum.lte(x, 1e12) then
		local inv = NanoNum.reciprocal(x)
		local inv2 = NanoNum.mul(inv, inv)
		local inv3 = NanoNum.mul(inv2, inv)
		local inv5 = NanoNum.mul(inv3, inv2)
		result = NanoNum.add(result, NanoNum.sub(NanoNum.div(inv, 12), NanoNum.div(inv3, 360)))
		result = NanoNum.add(result, NanoNum.div(inv5, 1260))
	end
	return result
end
function NanoNum.gamma(value: MathValue): buffer
	local direct = directFiniteNumber(value)
	if direct ~= nil and direct >= 1 and direct <= 171 and direct == floor(direct) then return encodeNumber(FACTORIAL_NUMBER_CACHE[direct]) end
	local sign = NanoNum.gammaSign(value)
	if sign ~= sign or sign == 0 then return makeSpecial(SPECIAL_NAN) end
	local magnitude = NanoNum.exp(NanoNum.logGamma(value))
	return sign < 0 and NanoNum.neg(magnitude) or magnitude
end
function NanoNum.factorialReal(value: MathValue): buffer return NanoNum.gamma(NanoNum.add(value, 1)) end
local function logFactorialRatio(n: number, r: number): number
	if r == 0 then return 0 end
	if r <= 1024 then
		local total: number = 0
		for i = 0, r - 1 do total += log10(n - i) end
		return total
	end
	local remaining: number = n - r
	if remaining < 256 then return factorialLog10(n) - factorialLog10(remaining) end
	local t: number = r / n
	local logRatio: number
	if t < 1e-4 then
		logRatio = t * (1 + t * (0.5 + t * (1 / 3 + t * (0.25 + t / 5))))
	else
		logRatio = -log(1 - t)
	end
	return r * log10(n) + ((remaining + 0.5) * logRatio - r + (1 / n - 1 / remaining) / 12) * LOG10_E
end
function NanoNum.permutation(nValue: MathValue, rValue: MathValue): buffer
	local n = exactInteger(nValue)
	local r = exactInteger(rValue)
	if n == nil or r == nil or n < 0 or r < 0 or r > n then return makeSpecial(SPECIAL_NAN) end
	if r == 0 then return NanoNum.fromNumber(1) end
	local result: number = 1
	for i = 0, r - 1 do
		local factor = n - i
		if factor ~= 0 and result > SAFE_INTEGER / factor then
			return NanoNum.fromLog10(logFactorialRatio(n, r))
		end
		result *= factor
	end
	return NanoNum.fromNumber(result)
end
function NanoNum.combination(nValue: MathValue, rValue: MathValue): buffer
	local n = exactInteger(nValue)
	local r = exactInteger(rValue)
	if n == nil or r == nil or n < 0 or r < 0 or r > n then return makeSpecial(SPECIAL_NAN) end
	r = min(r, n - r)
	if r == 0 then return NanoNum.fromNumber(1) end
	local result: number = 1
	local fast: boolean = true
	for i = 1, r do
		local numerator = n - r + i
		if result > SAFE_INTEGER / numerator then fast = false; break end
		local product = result * numerator
		if product % i ~= 0 then fast = false; break end
		result = product / i
	end
	if fast then return NanoNum.fromNumber(result) end
	result = 1
	for i = 1, r do
		local numerator = n - r + i
		local denominator = i
		local g = nativeGCD(numerator, denominator)
		numerator /= g
		denominator /= g
		local g2 = nativeGCD(result, denominator)
		result /= g2
		denominator /= g2
		if numerator ~= 0 and result > SAFE_INTEGER / numerator then
			return NanoNum.fromLog10(logFactorialRatio(n, r) - factorialLog10(r))
		end
		result *= numerator
		if denominator ~= 1 then result /= denominator end
		if result > SAFE_INTEGER or result ~= floor(result) then
			return NanoNum.fromLog10(logFactorialRatio(n, r) - factorialLog10(r))
		end
	end
	return NanoNum.fromNumber(result)
end
function NanoNum.gcd(a: MathValue, b: MathValue): buffer
	local x = exactInteger(a)
	local y = exactInteger(b)
	if x == nil or y == nil then return makeSpecial(SPECIAL_NAN) end
	x = abs(x)
	y = abs(y)
	while y ~= 0 do
		x, y = y, x % y
	end
	return NanoNum.fromNumber(x)
end
function NanoNum.lcm(a: MathValue, b: MathValue): buffer
	local x = exactInteger(a)
	local y = exactInteger(b)
	if x == nil or y == nil then return makeSpecial(SPECIAL_NAN) end
	if x == 0 or y == 0 then return NanoNum.fromNumber(0) end
	local g = exactInteger(NanoNum.gcd(x, y))
	if g == nil then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.mul(abs(x / g), abs(y))
end
function NanoNum.arithmeticSeries(first: MathValue, difference: MathValue, countValue: MathValue): buffer
	local count = exactInteger(countValue)
	if count == nil or count < 0 then return makeSpecial(SPECIAL_NAN) end
	if count == 0 then return NanoNum.fromNumber(0) end
	return NanoNum.mul(NanoNum.div(count, 2), NanoNum.add(NanoNum.mul(2, first), NanoNum.mul(count - 1, difference)))
end
function NanoNum.geometricSeries(first: MathValue, ratioValue: MathValue, countValue: MathValue): buffer
	local count = exactInteger(countValue)
	if count == nil or count < 0 then return makeSpecial(SPECIAL_NAN) end
	if count == 0 then return NanoNum.fromNumber(0) end
	if count == 1 then return NanoNum.compile(first) end
	if NanoNum.eq(ratioValue, 1) then return NanoNum.mul(first, count) end
	if NanoNum.isInfinite(ratioValue) then
		if NanoNum.isZero(first) then return makeSpecial(SPECIAL_NAN) end
		if NanoNum.isPositive(ratioValue) or count == 2 then return NanoNum.mul(first, ratioValue) end
		return makeSpecial(SPECIAL_NAN)
	end
	if NanoNum.gt(ratioValue, 0) then
		local delta = NanoNum.sub(ratioValue, 1)
		local growthLog = NanoNum.log1p(delta)
		local numerator = NanoNum.expm1(NanoNum.mul(count, growthLog))
		return NanoNum.mul(first, NanoNum.div(numerator, delta))
	end
	return NanoNum.mul(first, NanoNum.div(NanoNum.sub(NanoNum.pow(ratioValue, count), 1), NanoNum.sub(ratioValue, 1)))
end
function NanoNum.compound(principal: MathValue, rate: MathValue, periods: MathValue): buffer
	-- Preserve tiny rates that disappear when added to 1 in binary64.
	local r = directFiniteNumber(rate)
	if r ~= nil and abs(r) < 1e-5 and r ~= 0 then
		return NanoNum.mul(principal, NanoNum.exp(NanoNum.mul(periods, NanoNum.log1p(r))))
	end
	return NanoNum.mul(principal, NanoNum.pow(NanoNum.add(1, rate), periods))
end
function NanoNum.softcap(value: MathValue, start: MathValue, power: MathValue): buffer
	if NanoNum.isNaN(value) or NanoNum.isNaN(start) or NanoNum.isNaN(power) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(start, 0) or NanoNum.lte(power, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(value, start) then return NanoNum.compile(value) end
	return NanoNum.mul(start, NanoNum.pow(NanoNum.div(value, start), power))
end
function NanoNum.inverseSoftcap(value: MathValue, start: MathValue, power: MathValue): buffer
	if NanoNum.isNaN(value) or NanoNum.isNaN(start) or NanoNum.isNaN(power) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(start, 0) or NanoNum.lte(power, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(value, start) then return NanoNum.compile(value) end
	return NanoNum.mul(start, NanoNum.pow(NanoNum.div(value, start), NanoNum.reciprocal(power)))
end
function NanoNum.diminishingReturns(value: MathValue, scale: MathValue): buffer
	if NanoNum.lte(scale, 0) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isInfinite(scale) then
		if NanoNum.isInfinite(value) then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.compile(value)
	end
	return NanoNum.mul(scale, NanoNum.neg(NanoNum.expm1(NanoNum.neg(NanoNum.div(value, scale)))))
end
function NanoNum.inverseDiminishingReturns(value: MathValue, scale: MathValue): buffer
	if NanoNum.lte(scale, 0) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isInfinite(scale) then
		if NanoNum.isInfinite(value) then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.compile(value)
	end
	if NanoNum.gt(value, scale) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(value, scale) then return makeSpecial(SPECIAL_POS_INF) end
	return NanoNum.neg(NanoNum.mul(scale, NanoNum.log1p(NanoNum.neg(NanoNum.div(value, scale)))))
end
function NanoNum.sigmoid(value: MathValue): buffer
	if NanoNum.gte(value, 0) then return NanoNum.div(1, NanoNum.add(1, NanoNum.exp(NanoNum.neg(value)))) end
	local e = NanoNum.exp(value)
	return NanoNum.div(e, NanoNum.add(1, e))
end
function NanoNum.logit(value: MathValue): buffer
	if NanoNum.lt(value, 0) or NanoNum.gt(value, 1) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(value, 0) then return makeSpecial(SPECIAL_NEG_INF) end
	if NanoNum.eq(value, 1) then return makeSpecial(SPECIAL_POS_INF) end
	return NanoNum.ln(NanoNum.div(value, NanoNum.sub(1, value)))
end
function NanoNum.geometricCost(baseCost: MathValue, growth: MathValue, owned: MathValue, amount: MathValue): buffer
	if NanoNum.isNaN(baseCost) or NanoNum.isNaN(growth) or NanoNum.isNaN(owned) or NanoNum.isNaN(amount) then return makeSpecial(SPECIAL_NAN) end
	local bc = directFiniteNumber(baseCost)
	local gr = directFiniteNumber(growth)
	local ow = directFiniteNumber(owned)
	local am = directFiniteNumber(amount)
	if bc ~= nil and gr ~= nil and ow ~= nil and am ~= nil then
		if bc == bc and gr == gr and ow == ow and am == am and bc > 0 and gr >= 1 and ow >= 0 and am >= 0 and bc ~= huge and gr ~= huge and ow ~= huge and am ~= huge then
			if am == 0 then return NanoNum.fromNumber(0) end
			local current = bc * gr ^ ow
			if current ~= huge and current ~= 0 then
				if am == 1 then return NanoNum.fromNumber(current) end
				if gr == floor(gr) and am == floor(am) and am <= 64 and current == floor(current) and current <= SAFE_INTEGER then
					local power = gr ^ am
					if gr > 1 and power <= SAFE_INTEGER then
						local series = (power - 1) / (gr - 1)
						local exact = current * series
						if exact <= SAFE_INTEGER then return encodeNumber(exact) end
					end
				end
				if gr == 1 then
					local native = current * am
					if native ~= huge and native ~= 0 then return NanoNum.fromNumber(native) end
					-- Overflow/underflow must fall through to NanoNum multiplication, not collapse to Inf/0.
				else
					local d = gr - 1
					local gl
					if d < 0.0001 then local d2 = d * d; gl = d - d2 * 0.5 + d2 * d / 3 - d2 * d2 * 0.25 + d2 * d2 * d * 0.2 else gl = log(gr) end
					local z = am * gl
					local numerator
					if z < 0.0001 then local z2 = z * z; numerator = z + z2 * 0.5 + z2 * z / 6 + z2 * z2 / 24 + z2 * z2 * z / 120 else numerator = exp(z) - 1 end
					local native = current * numerator / d
					if native == native and native ~= huge and native ~= 0 then return NanoNum.fromNumber(native) end
				end
			end
		end
	end
	if NanoNum.lte(baseCost, 0) or NanoNum.lt(owned, 0) or NanoNum.lt(amount, 0) or NanoNum.lt(growth, 1) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isZero(amount) then return NanoNum.fromNumber(0) end
	local currentCost = NanoNum.mul(baseCost, NanoNum.pow(growth, owned))
	if NanoNum.eq(amount, 1) then return currentCost end
	if NanoNum.eq(growth, 1) then return NanoNum.mul(currentCost, amount) end
	if NanoNum.isInfinite(growth) then
		if NanoNum.isZero(currentCost) then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.mul(currentCost, growth)
	end
	local delta = NanoNum.sub(growth, 1)
	local growthLog = NanoNum.log1p(delta)
	local numerator = NanoNum.expm1(NanoNum.mul(amount, growthLog))
	return NanoNum.mul(currentCost, NanoNum.div(numerator, delta))
end
function NanoNum.maxAffordableGeometric(currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?): buffer
	if NanoNum.isNaN(currency) or NanoNum.isNaN(baseCost) or NanoNum.isNaN(growth) or NanoNum.isNaN(owned or 0) then return makeSpecial(SPECIAL_NAN) end
	local levelsOwned = owned or 0
	if NanoNum.lt(currency, 0) or NanoNum.lte(baseCost, 0) or NanoNum.lt(levelsOwned, 0) or NanoNum.lt(growth, 1) then return makeSpecial(SPECIAL_NAN) end
	local currentCost = NanoNum.mul(baseCost, NanoNum.pow(growth, levelsOwned))
	if NanoNum.lt(currency, currentCost) then return NanoNum.fromNumber(0) end
	if NanoNum.eq(growth, 1) then return NanoNum.floor(NanoNum.div(currency, currentCost)) end
	if NanoNum.isInfinite(growth) then
		if NanoNum.isInfinite(currentCost) then return NanoNum.isInfinite(currency) and makeSpecial(SPECIAL_POS_INF) or NanoNum.fromNumber(0) end
		return NanoNum.fromNumber(1)
	end
	local delta = NanoNum.sub(growth, 1)
	local term = NanoNum.div(NanoNum.mul(currency, delta), currentCost)
	local estimate = NanoNum.floor(NanoNum.div(NanoNum.log1p(term), NanoNum.log1p(delta)))
	if NanoNum.isNaN(estimate) or NanoNum.lt(estimate, 0) then return NanoNum.fromNumber(0) end
	local amount = estimate
	for _ = 1, 8 do
		local cost = NanoNum.geometricCost(baseCost, growth, levelsOwned, amount)
		if NanoNum.lte(cost, currency) then break end
		if NanoNum.lte(amount, 0) then return NanoNum.fromNumber(0) end
		amount = NanoNum.sub(amount, 1)
	end
	for _ = 1, 8 do
		local nextAmount = NanoNum.add(amount, 1)
		local nextCost = NanoNum.geometricCost(baseCost, growth, levelsOwned, nextAmount)
		if NanoNum.gt(nextCost, currency) then break end
		amount = nextAmount
	end
	return NanoNum.floor(amount)
end
function NanoNum.bulkBuyGeometric(currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?): (buffer, buffer, buffer)
	local amount = NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned)
	if NanoNum.isNaN(amount) then
		local nan = makeSpecial(SPECIAL_NAN)
		return nan, nan, nan
	end
	local cost = NanoNum.geometricCost(baseCost, growth, owned or 0, amount)
	local remaining = NanoNum.sub(currency, cost)
	if NanoNum.lt(remaining, 0) then
		local error = NanoNum.relativeDifference(cost, currency)
		if NanoNum.lte(error, 1e-10) then remaining = NanoNum.fromNumber(0) end
	end
	return amount, cost, remaining
end
function NanoNum.nextGeometricCost(baseCost: MathValue, growth: MathValue, owned: MathValue): buffer
	if NanoNum.lte(baseCost, 0) or NanoNum.lt(growth, 1) or NanoNum.lt(owned, 0) then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.mul(baseCost, NanoNum.pow(growth, owned))
end
function NanoNum.iteratedExp10(value: MathValue, timesValue: MathValue): buffer
	local times = exactInteger(timesValue)
	if times == nil or times < 0 or times > NanoNum.MAX_LAYER then return makeSpecial(SPECIAL_NAN) end
	local k, a, b = decodeReg(value)
	if times == 0 then return encodeReg(k, a, b) end
	if abs(k) == K_LAYER and k > 0 and a > 0 then
		local layer: number = abs(a)
		local sum = layer + times
		if sum ~= huge and sum <= NanoNum.MAX_LAYER then return NanoNum.fromLayer(sum, b) end
		local hi: number = max(layer, times)
		local lo: number = min(layer, times)
		local layerLog10: number = log10(hi) + log10(1 + lo / hi)
		return NanoNum.fromLayerLog10(layerLog10, b)
	end
	if abs(k) == K_LAYER_LOG and k > 0 and a > 0 then return NanoNum.fromLayerLog10(a, b) end
	if abs(k) == K_HYPER_LAYER and k > 0 and a > 0 then return NanoNum.fromLayerLog10Log10(a, b) end
	local remaining = times
	while remaining > 0 do
		k, a, b = regPow10(k, a, b)
		remaining -= 1
		if abs(k) == K_NAN or abs(k) == K_INF then break end
		if remaining > 0 and abs(k) == K_LAYER and k > 0 and a > 0 then
			local layer: number = abs(a)
			local sum = layer + remaining
			if sum ~= huge and sum <= NanoNum.MAX_LAYER then return NanoNum.fromLayer(sum, b) end
			local hi: number = max(layer, remaining)
			local lo: number = min(layer, remaining)
			return NanoNum.fromLayerLog10(log10(hi) + log10(1 + lo / hi), b)
		end
	end
	return encodeReg(k, a, b)
end
function NanoNum.iteratedLog10(value: MathValue, timesValue: MathValue): buffer
	local times = exactInteger(timesValue)
	if times == nil or times < 0 or times > NanoNum.MAX_LAYER then return makeSpecial(SPECIAL_NAN) end
	local k, a, b = decodeReg(value)
	if times == 0 then return encodeReg(k, a, b) end
	if abs(k) == K_LAYER and k > 0 and a > 0 then
		if times <= a then return NanoNum.fromLayer(a - times, b) end
		times -= a
		k, a, b = regFromNumber(b)
	end
	if (abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and k > 0 and a > 0 then return encodeReg(k, a, b) end
	while times > 0 do
		k, a, b = regLog10(k, a, b)
		times -= 1
		if abs(k) == K_NAN or abs(k) == K_INF then break end
		if times > 0 and abs(k) == K_LAYER and k > 0 and a > 0 then
			if times <= a then return NanoNum.fromLayer(a - times, b) end
			times -= a
			k, a, b = regFromNumber(b)
		end
		if times > 8 and abs(k) == K_NUM then
			local n = regToNumber(k, a, b)
			if n <= 0 or n ~= n then break end
		end
	end
	return encodeReg(k, a, b)
end
function NanoNum.tetrate10(heightValue: MathValue, payload: MathValue?): buffer
	local hk, ha, hb = decodeReg(heightValue)
	local heightKind: number = abs(hk)
	if heightKind == K_NAN or heightKind == K_INF then return makeSpecial(SPECIAL_NAN) end
	-- For an enormous positive height H stored as K_LOG, `ha` is log10(H).
	-- The tower result has layer depth H, so storing log10(layerDepth)=ha preserves
	-- arbitrary giant mantissas too (for example 2e1503, not only 1e1503).
	if payload == nil and hk > 0 and heightKind == K_LOG and ha >= 0 and ha <= NanoNum.MAX_LAYER_LOG10 then
		return NanoNum.fromLayerLog10(ha, 1)
	end
	-- A layer-2 height H has log10(log10(H)) = hb. This remains representable as a
	-- hyper-layer depth even when hb is fractional.
	if payload == nil and hk > 0 and heightKind == K_LAYER and ha == 2 and hb >= 0 then
		return NanoNum.fromLayerLog10Log10(hb, 1)
	end
	if payload == nil and hk > 0 and ha > 0 and (heightKind == K_LAYER or heightKind == K_LAYER_LOG or heightKind == K_HYPER_LAYER) then
		return makeSpecial(SPECIAL_POS_INF)
	end
	local height = regToNumber(hk, ha, hb)
	if height ~= height or height == huge or height == -huge then return makeSpecial(SPECIAL_NAN) end
	if payload ~= nil then
		if height < 0 or height ~= floor(height) then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.iteratedExp10(payload, height)
	end
	if height < -1 then return makeSpecial(SPECIAL_NAN) end
	if height < 0 then return NanoNum.fromNumber(height + 1) end
	local whole: number = floor(height)
	local fraction = height - whole
	local seed = 10 ^ fraction
	if whole == 0 then return NanoNum.fromNumber(seed) end
	if whole == 1 then return NanoNum.fromLog10(seed) end
	return NanoNum.fromLayer(whole, seed)
end
function NanoNum.tetrate(baseValue: MathValue, heightValue: MathValue, payload: MathValue?): buffer
	if NanoNum.eq(baseValue, 10) then return NanoNum.tetrate10(heightValue, payload) end
	local height = NanoNum.toNumber(heightValue)
	if height ~= height or height < 0 or height > 256 or height ~= floor(height) then return makeSpecial(SPECIAL_NAN) end
	local result = payload == nil and NanoNum.fromNumber(1) or NanoNum.compile(payload)
	local whole = height
	for _ = 1, whole do
		result = NanoNum.pow(baseValue, result)
		if NanoNum.isNaN(result) then return result end
	end
	return result
end
function NanoNum.tetrateInteger(baseValue: MathValue, heightValue: MathValue, payload: MathValue?): buffer
	local height = exactInteger(heightValue)
	if height == nil or height < 0 then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.tetrate(baseValue, height, payload)
end
function NanoNum.tetrate10Integer(heightValue: MathValue, payload: MathValue?): buffer
	local height = exactInteger(heightValue)
	if height == nil or height < 0 then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.tetrate10(height, payload)
end
local function scalarSlog10(value: number): number
	if value <= 0 then return NAN end
	local count: number = 0
	local x = value
	while x > 10 and count < 1024 do
		x = log10(x)
		count += 1
	end
	if x >= 1 then return count + log10(x) end
	while x > 0 and x < 1 and count > -1024 do
		x = 10 ^ x
		count -= 1
		if x >= 1 then break end
	end
	return count + log10(x)
end
function NanoNum.slog10(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	if k == 0 then return NanoNum.fromNumber(-1) end
	if k < 0 or abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if abs(k) == K_INF then return makeSpecial(SPECIAL_POS_INF) end
	if (abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG or abs(k) == K_HYPER_LAYER) and a < 0 then return NanoNum.fromNumber(-1) end
	if abs(k) == K_LAYER then return NanoNum.add(abs(a), scalarSlog10(b)) end
	if abs(k) == K_LAYER_LOG then return NanoNum.add(NanoNum.fromLog10(abs(a)), scalarSlog10(b)) end
	if abs(k) == K_HYPER_LAYER then return NanoNum.add(NanoNum.fromLayer(2, abs(a)), scalarSlog10(b)) end
	if abs(k) == K_LOG then return NanoNum.fromNumber(1 + scalarSlog10(abs(a))) end
	return NanoNum.fromNumber(scalarSlog10(a))
end
function NanoNum.slog(value: MathValue, baseValue: MathValue?): buffer
	local base = baseValue or 10
	if NanoNum.isNaN(value) or NanoNum.isNaN(base) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(base, 10) then return NanoNum.slog10(value) end
	if NanoNum.lte(base, 1) or NanoNum.isInfinite(base) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isInfinite(value) then return NanoNum.isPositive(value) and makeSpecial(SPECIAL_POS_INF) or makeSpecial(SPECIAL_NAN) end
	if NanoNum.isZero(value) then return NanoNum.fromNumber(-1) end
	local x = NanoNum.compile(value)
	local count: number = 0
	while NanoNum.gt(x, base) and count < 256 do
		x = NanoNum.log(x, base)
		count += 1
	end
	if count >= 256 then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.add(count, NanoNum.log(x, base))
end
function NanoNum.betaSign(a: MathValue, b: MathValue): number
	local sa = NanoNum.gammaSign(a)
	local sb = NanoNum.gammaSign(b)
	local ss = NanoNum.gammaSign(NanoNum.add(a, b))
	if sa ~= sa or sb ~= sb or ss ~= ss or sa == 0 or sb == 0 or ss == 0 then return NAN end
	return sa * sb * ss
end
local function stirlingCorrection(inverse: number): number
	local square = inverse * inverse
	return inverse * (1 / 12 + square * (-1 / 360 + square * (1 / 1260 + square * (-1 / 1680 + square * (1 / 1188 - square * 691 / 360360)))))
end
function NanoNum.logBeta(a: MathValue, b: MathValue): buffer
	local x, y = directFiniteNumber(a), directFiniteNumber(b)
	if x ~= nil and y ~= nil and x > 0 and y > 0 then
		if x > y then x, y = y, x end
		if x == 1 then return encodeNumber(-log(y)) end
		local shift = 0
		-- B(x,y) = (x+y)/x * B(x+1,y); raise small arguments before Stirling.
		while x < 8 do
			shift += log(x + y) - log(x)
			x += 1
		end
		while y < 8 do
			shift += log(x + y) - log(y)
			y += 1
		end
		if x > y then x, y = y, x end
		local ratio = x / y
		local logRatio = log(ratio)
		local l1p
		if ratio < 1e-4 then
			l1p = ratio * (1 + ratio * (-0.5 + ratio * (1 / 3 + ratio * (-0.25 + ratio * 0.2))))
		else l1p = log(1 + ratio) end
		local left = (x - 0.5) * (logRatio - l1p)
		local right = -(y - 0.5) * l1p
		local correction = 0.5 * (log(TWO_PI) - log(y) - l1p) + stirlingCorrection(1 / x) + stirlingCorrection(1 / y) - stirlingCorrection((1 / y) / (1 + ratio)) + shift
		local result = left + right + correction
		if result ~= -huge then return encodeNumber(result) end
		return NanoNum.add(NanoNum.add(left, right), correction)
	end
	local sign = NanoNum.betaSign(a, b)
	if sign ~= sign then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(a, 1) then return NanoNum.neg(NanoNum.ln(NanoNum.abs(b))) end
	if NanoNum.eq(b, 1) then return NanoNum.neg(NanoNum.ln(NanoNum.abs(a))) end
	return NanoNum.sub(NanoNum.add(NanoNum.logGamma(a), NanoNum.logGamma(b)), NanoNum.logGamma(NanoNum.add(a, b)))
end
function NanoNum.beta(a: MathValue, b: MathValue): buffer
	local sign = NanoNum.betaSign(a, b)
	if sign ~= sign then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.eq(a, 1) then return NanoNum.reciprocal(b) end
	if NanoNum.eq(b, 1) then return NanoNum.reciprocal(a) end
	local magnitude = NanoNum.exp(NanoNum.logBeta(a, b))
	return sign < 0 and NanoNum.neg(magnitude) or magnitude
end
function NanoNum.compile(value: MathValue): buffer
	local kind = typeof(value)
	if kind == "buffer" then return value end
	if kind == "number" then return NanoNum.fromNumber(value) end
	if kind == "string" then return NanoNum.fromString(value) end
	return makeSpecial(SPECIAL_NAN)
end
-- EN slots are {sign, layer, exponent}; slot 4 extends EN losslessly past its numeric-layer ceiling.
function NanoNum.toEN(value: MathValue): EN
	local k, a, b = decodeReg(value)
	local kind: number = abs(k)
	if kind == K_NAN then return {1, -1, 1} end
	if k == 0 then return {0, 0, 0} end
	local sign = k < 0 and -1 or 1
	if kind == K_INF then return {sign, huge, 1} end
	if kind == K_NUM then return {sign, 0, a} end
	if kind == K_LOG then return {sign, 1, a} end
	local top = a < 0 and -b or b
	if kind == K_LAYER then return {sign, abs(a), top} end
	if kind == K_LAYER_LOG then return {sign, abs(a), top, 1} end
	return {sign, abs(a), top, 2}
end
function NanoNum.fromEN(value: EN): buffer
	if typeof(value) ~= "table" then return makeSpecial(SPECIAL_NAN) end
	local s, l, e, mode = value[1], value[2], value[3], value[4]
	if typeof(s) ~= "number" or typeof(l) ~= "number" or typeof(e) ~= "number" then return makeSpecial(SPECIAL_NAN) end
	if s ~= s or l ~= l or e ~= e then return makeSpecial(SPECIAL_NAN) end
	if s == 0 then return NanoNum.fromNumber(0) end
	if mode ~= nil and mode ~= 1 and mode ~= 2 then return makeSpecial(SPECIAL_NAN) end
	if l < 0 then return makeSpecial(SPECIAL_NAN) end
	if mode == 1 then return NanoNum.fromLayerLog10(l, abs(e), s < 0, e < 0) end
	if mode == 2 then return NanoNum.fromLayerLog10Log10(l, abs(e), s < 0, e < 0) end
	if l == huge then return makeSpecial(s < 0 and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if l == 0 then return NanoNum.fromNumber((s < 0 and -1 or 1) * e) end
	if l == 1 then return NanoNum.fromLog10(e, s < 0) end
	return NanoNum.fromLayer(l, abs(e), s < 0, e < 0)
end
(function()
	local function scalarText(value: number): string
		if value ~= value then return "NaN" end
		if value == huge then return "Inf" end
		if value == -huge then return "-Inf" end
		if value == 0 then return "0" end
		return format("%.17g", value)
	end
	function NanoNum.toString(value: MathValue): string
		local k, a, b = decodeReg(value)
		local kind: number = abs(k)
		if kind == K_NAN then return "NaN" end
		if k == 0 then return "0" end
		local prefix = k < 0 and "-" or ""
		if kind == K_INF then return prefix .. "Inf" end
		if kind == K_NUM then return scalarText(k < 0 and -a or a) end
		if kind == K_LOG then
			if abs(a) <= SAFE_INTEGER then
				local exponent: number = floor(a)
				local mantissa = 10 ^ (a - exponent)
				if mantissa >= 10 then mantissa = 1; exponent += 1 end
				return prefix .. scalarText(mantissa) .. "e" .. format("%.0f", exponent)
			end
			return prefix .. "10^(" .. scalarText(a) .. ")"
		end
		local body
		if kind == K_LAYER then body = "L" .. scalarText(abs(a)) .. " " .. scalarText(b)
		elseif kind == K_LAYER_LOG then body = "LE" .. scalarText(abs(a)) .. " " .. scalarText(b)
		else body = "LEE" .. scalarText(abs(a)) .. " " .. scalarText(b) end
		return prefix .. (a < 0 and "1/" or "") .. body
	end
	function NanoNum.toStringEN(value: MathValue): string
		local k, a, b = decodeReg(value)
		local kind: number = abs(k)
		if kind == K_NAN then return "NaN" end
		if k == 0 then return "0;0" end
		local prefix = k < 0 and "-" or ""
		if kind == K_INF then return prefix .. "Inf" end
		if kind == K_NUM then return prefix .. "0;" .. scalarText(a) end
		if kind == K_LOG then return prefix .. "1;" .. scalarText(a) end
		local top = a < 0 and -b or b
		if kind == K_LAYER then return prefix .. scalarText(floor(abs(a) + 0.001)) .. ";" .. scalarText(top) end
		if kind == K_LAYER_LOG then return prefix .. "ENL;" .. scalarText(abs(a)) .. ";" .. scalarText(top) end
		return prefix .. "ENLL;" .. scalarText(abs(a)) .. ";" .. scalarText(top)
	end
end)()
function NanoNum.canonicalize(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	return encodeReg(k, a, b)
end
function NanoNum.isCanonical(value: MathValue): boolean
	if typeof(value) ~= "buffer" then return false end
	local source = value :: buffer
	if not NanoNum.isValid(source) then return false end
	local k, a, b = decodeRegBuffer(source)
	local canonical = encodeReg(k, a, b)
	local sourceBytes: number = bufferLen(source)
	local canonicalBytes: number = bufferLen(canonical)
	if sourceBytes ~= canonicalBytes then return false end
	for i = 0, sourceBytes - 1 do
		if buffer.readu8(source, i) ~= bufferReadU8(canonical, i) then return false end
	end
	return true
end
function NanoNum.log10Abs(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	if abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if k < 0 then k = -k end
	k, a, b = regLog10(k, a, b)
	return encodeReg(k, a, b)
end
function NanoNum.scale10(value: MathValue, exponent: MathValue): buffer
	local vk, va, vb = decodeReg(value)
	local ek, ea, eb = decodeReg(exponent)
	if abs(vk) == K_NAN or abs(ek) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if vk == 0 then return NanoNum.fromNumber(0) end
	local pk, pa, pb = regPow10(ek, ea, eb)
	vk, va, vb = regMul(vk, va, vb, pk, pa, pb)
	return encodeReg(vk, va, vb)
end
function NanoNum.fromScientific(mantissa: MathValue, exponent: MathValue): buffer
	return NanoNum.scale10(mantissa, exponent)
end
function NanoNum.layerDepth(value: MathValue): buffer
	local k, a = decodeReg(value)
	local kind: number = abs(k)
	if kind == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if kind == K_INF then return makeSpecial(SPECIAL_POS_INF) end
	if kind == K_LAYER then return NanoNum.fromNumber(abs(a)) end
	if kind == K_LAYER_LOG then return NanoNum.fromLog10(abs(a)) end
	if kind == K_HYPER_LAYER then return NanoNum.fromLayer(2, abs(a)) end
	if kind == K_LOG then return NanoNum.fromNumber(1) end
	return NanoNum.fromNumber(0)
end
function NanoNum.rangeClass(value: MathValue): string
	local k = decodeReg(value)
	local kind: number = abs(k)
	if kind == K_NAN then return "nan" end
	if kind == K_INF then return "infinity" end
	if kind == K_HYPER_LAYER then return "hyper-layer" end
	if kind == K_LAYER_LOG then return "layer-log" end
	if kind == K_LAYER then return "layer" end
	if kind == K_LOG then return "log" end
	if k == 0 then return "zero" end
	return "finite"
end
local TYPE_CODE = {number = "N", buffer = "B", string = "S"}
NanoNum.fast = {} :: {[string]: any}
NanoNum.fast.pow10B = function(value: buffer): buffer
	local x, direct = 0, false
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		x = bufferReadF64(value, 1)
		direct = x == x and x ~= huge and x ~= -huge
	elseif band(first, 1) == 0 then
		x = floor(first / 2)
		direct = true
	elseif band(first, 3) == 1 then
		x = -(floor(first / 4) + 1)
		direct = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(value, offset, n)
			else
				magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296
			end
			x = negative and -magnitude or magnitude
			direct = true
		end
	end
	if direct and x >= DIRECT_LOG_MIN and x <= DIRECT_LOG_MAX then
		local result = 10 ^ x
		if result ~= 0 and result ~= huge then
			return encodeNumber(result)
		end
	end
	if direct then return makeLog(x, false) end
	local k, a, b = decodeRegBuffer(value)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end
NanoNum.fast.log10B = function(value: buffer): buffer
	local x, direct = 0, false
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		x = bufferReadF64(value, 1)
		direct = x == x and x ~= huge and x ~= -huge
	elseif band(first, 1) == 0 then
		x = floor(first / 2)
		direct = true
	elseif band(first, 3) == 1 then
		x = -(floor(first / 4) + 1)
		direct = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(value, offset, n)
			else
				magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296
			end
			x = negative and -magnitude or magnitude
			direct = true
		end
	end
	if direct then
		if x < 0 then return makeSpecial(SPECIAL_NAN) end
		if x == 0 then return makeSpecial(SPECIAL_NEG_INF) end
		local result: number = log10(x)
		return encodeNumber(result)
	end
	local k, a, b = decodeRegBuffer(value)
	k, a, b = regLog10(k, a, b)
	return encodeReg(k, a, b)
end
NanoNum.fast.negB = function(value: buffer): buffer
	local x, direct = 0, false
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		x = bufferReadF64(value, 1)
		direct = x == x and x ~= huge and x ~= -huge
	elseif band(first, 1) == 0 then
		x = floor(first / 2)
		direct = true
	elseif band(first, 3) == 1 then
		x = -(floor(first / 4) + 1)
		direct = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(value, offset, n)
			else
				magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296
			end
			x = negative and -magnitude or magnitude
			direct = true
		end
	end
	if direct then
		local result = -x
		return encodeNumber(result)
	end
	local k, a, b = decodeRegBuffer(value)
	if k ~= 0 and abs(k) ~= K_NAN then k = -k end
	return encodeReg(k, a, b)
end
NanoNum.fast.absB = function(value: buffer): buffer
	local x, direct = 0, false
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		x = bufferReadF64(value, 1)
		direct = x == x and x ~= huge and x ~= -huge
	elseif band(first, 1) == 0 then
		x = floor(first / 2)
		direct = true
	elseif band(first, 3) == 1 then
		x = -(floor(first / 4) + 1)
		direct = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(value, offset, n)
			else
				magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296
			end
			x = negative and -magnitude or magnitude
			direct = true
		end
	end
	if direct then
		local result = x < 0 and -x or x
		return encodeNumber(result)
	end
	local k, a, b = decodeRegBuffer(value)
	return encodeReg(abs(k), a, b)
end
NanoNum.fast.reciprocalB = function(value: buffer): buffer
	local x, direct = 0, false
	local first: number = bufferReadU8(value, 0)
	if first == 255 then
		x = bufferReadF64(value, 1)
		direct = x == x and x ~= huge and x ~= -huge
	elseif band(first, 1) == 0 then
		x = floor(first / 2)
		direct = true
	elseif band(first, 3) == 1 then
		x = -(floor(first / 4) + 1)
		direct = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(value, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(value, offset, n)
			else
				magnitude = bufferReadBits(value, offset, 32) + bufferReadBits(value, offset + 32, n - 32) * 4294967296
			end
			x = negative and -magnitude or magnitude
			direct = true
		end
	end
	if direct then
		if x == 0 then return makeSpecial(SPECIAL_POS_INF) end
		local result = 1 / x
		if result ~= 0 and result ~= huge and result ~= -huge then
			return encodeNumber(result)
		end
	end
	local k, a, b = decodeRegBuffer(value)
	k, a, b = regReciprocal(k, a, b)
	return encodeReg(k, a, b)
end
NanoNum.fast.addBB = function(a: buffer, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax + bx
		if value == value and value ~= huge and value ~= -huge then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldAdd(a, b)
end
NanoNum.fast.subBB = function(a: buffer, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax - bx
		if value == value and value ~= huge and value ~= -huge then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldSub(a, b)
end
NanoNum.fast.mulBB = function(a: buffer, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax * bx
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0 or bx == 0) then
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
	end
	return coldMul(a, b)
end
NanoNum.fast.divBB = function(a: buffer, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if bx ~= 0 then
			local value = ax / bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				local integral: number = floor(value)
				if value == integral then
					if value >= 0 and value <= 127 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, value * 2)
						return data
					end
					if value < 0 and value >= -64 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
						return data
					end
					local negative = value < 0
					local magnitude = negative and -value or value
					if magnitude <= SAFE_INTEGER then
						local n: number = bitsRequired(magnitude)
						if n <= 31 then
							local bits = 9 + n
							local data: buffer = bufferCreate(floor((bits + 7) / 8))
							local header = 3 + (negative and 8 or 0) + n * 16
							if bits <= 32 then
								bufferWriteBits(data, 0, bits, header + magnitude * 512)
							else
								bufferWriteBits(data, 0, 9, header)
								bufferWriteBits(data, 9, n, magnitude)
							end
							return data
						end
						local bits = 14 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
						bufferWriteBits(data, 14, 32, magnitude % 4294967296)
						bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
						return data
					end
				end
				local data: buffer = bufferCreate(EXACT_F64_BYTES)
				bufferWriteU8(data, 0, 255)
				bufferWriteF64(data, 1, value)
				return data
			end
		end
	end
	return coldDiv(a, b)
end
NanoNum.fast.powBB = function(a: buffer, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if bx == 0 or ax == 1 then
			local value: number = 1
			local integral: number = floor(value)
			if value == integral then
				if value >= 0 and value <= 127 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, value * 2)
					return data
				end
				if value < 0 and value >= -64 then
					local data: buffer = bufferCreate(1)
					bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
					return data
				end
				local negative = value < 0
				local magnitude = negative and -value or value
				if magnitude <= SAFE_INTEGER then
					local n: number = bitsRequired(magnitude)
					if n <= 31 then
						local bits = 9 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						local header = 3 + (negative and 8 or 0) + n * 16
						if bits <= 32 then
							bufferWriteBits(data, 0, bits, header + magnitude * 512)
						else
							bufferWriteBits(data, 0, 9, header)
							bufferWriteBits(data, 9, n, magnitude)
						end
						return data
					end
					local bits = 14 + n
					local data: buffer = bufferCreate(floor((bits + 7) / 8))
					bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
					bufferWriteBits(data, 14, 32, magnitude % 4294967296)
					bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
					return data
				end
			end
			local data: buffer = bufferCreate(EXACT_F64_BYTES)
			bufferWriteU8(data, 0, 255)
			bufferWriteF64(data, 1, value)
			return data
		end
		if ax >= 0 or bx == floor(bx) then
			local value = ax ^ bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				local integral: number = floor(value)
				if value == integral then
					if value >= 0 and value <= 127 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, value * 2)
						return data
					end
					if value < 0 and value >= -64 then
						local data: buffer = bufferCreate(1)
						bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
						return data
					end
					local negative = value < 0
					local magnitude = negative and -value or value
					if magnitude <= SAFE_INTEGER then
						local n: number = bitsRequired(magnitude)
						if n <= 31 then
							local bits = 9 + n
							local data: buffer = bufferCreate(floor((bits + 7) / 8))
							local header = 3 + (negative and 8 or 0) + n * 16
							if bits <= 32 then
								bufferWriteBits(data, 0, bits, header + magnitude * 512)
							else
								bufferWriteBits(data, 0, 9, header)
								bufferWriteBits(data, 9, n, magnitude)
							end
							return data
						end
						local bits = 14 + n
						local data: buffer = bufferCreate(floor((bits + 7) / 8))
						bufferWriteBits(data, 0, 14, 3 + (negative and 8 or 0) + (n - 32) * 512)
						bufferWriteBits(data, 14, 32, magnitude % 4294967296)
						bufferWriteBits(data, 46, n - 32, floor(magnitude / 4294967296))
						return data
					end
				end
				local data: buffer = bufferCreate(EXACT_F64_BYTES)
				bufferWriteU8(data, 0, 255)
				bufferWriteF64(data, 1, value)
				return data
			end
		end
	end
	return coldPow(a, b)
end
NanoNum.fast.compareBB = function(a: buffer, b: buffer): number
	local af: number = bufferReadU8(a, 0)
	local bf: number = bufferReadU8(b, 0)
	if af == 255 and bf == 255 then
		local ax: number = bufferReadF64(a, 1)
		local bx: number = bufferReadF64(b, 1)
		if ax ~= ax or bx ~= bx then return NAN end
		if ax < bx then return -1 elseif ax > bx then return 1 else return 0 end
	end
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first = af
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	first = bf
	if first == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(first, 1) == 0 then
		bx = floor(first / 2)
		bdirect = true
	elseif band(first, 3) == 1 then
		bx = -(floor(first / 4) + 1)
		bdirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if ax < bx then return -1 elseif ax > bx then return 1 else return 0 end
	end
	return coldCompare(a, b)
end
NanoNum.fast.addNN = function(a: number, b: number): buffer
	local value = a + b
	if value == value and value ~= huge and value ~= -huge then
		return encodeNumber(value)
	end
	return coldAdd(a, b)
end
NanoNum.fast.subNN = function(a: number, b: number): buffer
	local value = a - b
	if value == value and value ~= huge and value ~= -huge then
		return encodeNumber(value)
	end
	return coldSub(a, b)
end
NanoNum.fast.mulNN = function(a: number, b: number): buffer
	local value = a * b
	if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0 or b == 0) then
		return encodeNumber(value)
	end
	return coldMul(a, b)
end
NanoNum.fast.divNN = function(a: number, b: number): buffer
	if b ~= 0 then
		local value = a / b
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0) then
			return encodeNumber(value)
		end
	end
	return coldDiv(a, b)
end
NanoNum.fast.powNN = function(a: number, b: number): buffer
	if a == a and b == b then
		if b == 0 or a == 1 then
			local value: number = 1
			return encodeNumber(value)
		end
		if a >= 0 or b == floor(b) then
			local value = a ^ b
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0) then
				return encodeNumber(value)
			end
		end
	end
	return coldPow(a, b)
end
NanoNum.fast.compareNN = function(a: number, b: number): number
	if a ~= a or b ~= b then return NAN end
	if a < b then return -1 elseif a > b then return 1 else return 0 end
end
NanoNum.fast.addBN = function(a: buffer, b: number): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		local value = ax + bx
		if value == value and value ~= huge and value ~= -huge then
			return encodeNumber(value)
		end
	end
	return coldAdd(a, b)
end
NanoNum.fast.addNB = function(a: number, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax + bx
		if value == value and value ~= huge and value ~= -huge then
			return encodeNumber(value)
		end
	end
	return coldAdd(a, b)
end
NanoNum.fast.addSS = function(a: string, b: string): buffer return NanoNum.fast.addBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.addSB = function(a: string, b: buffer): buffer return NanoNum.fast.addBB(NanoNum.fromString(a), b) end
NanoNum.fast.addBS = function(a: buffer, b: string): buffer return NanoNum.fast.addBB(a, NanoNum.fromString(b)) end
NanoNum.fast.addSN = function(a: string, b: number): buffer return NanoNum.fast.addBN(NanoNum.fromString(a), b) end
NanoNum.fast.addNS = function(a: number, b: string): buffer return NanoNum.fast.addNB(a, NanoNum.fromString(b)) end
NanoNum.fast.subBN = function(a: buffer, b: number): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		local value = ax - bx
		if value == value and value ~= huge and value ~= -huge then
			return encodeNumber(value)
		end
	end
	return coldSub(a, b)
end
NanoNum.fast.subNB = function(a: number, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax - bx
		if value == value and value ~= huge and value ~= -huge then
			return encodeNumber(value)
		end
	end
	return coldSub(a, b)
end
NanoNum.fast.subSS = function(a: string, b: string): buffer return NanoNum.fast.subBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.subSB = function(a: string, b: buffer): buffer return NanoNum.fast.subBB(NanoNum.fromString(a), b) end
NanoNum.fast.subBS = function(a: buffer, b: string): buffer return NanoNum.fast.subBB(a, NanoNum.fromString(b)) end
NanoNum.fast.subSN = function(a: string, b: number): buffer return NanoNum.fast.subBN(NanoNum.fromString(a), b) end
NanoNum.fast.subNS = function(a: number, b: string): buffer return NanoNum.fast.subNB(a, NanoNum.fromString(b)) end
NanoNum.fast.mulBN = function(a: buffer, b: number): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		local value = ax * bx
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0 or bx == 0) then
			return encodeNumber(value)
		end
	end
	return coldMul(a, b)
end
NanoNum.fast.mulNB = function(a: number, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		local value = ax * bx
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0 or bx == 0) then
			return encodeNumber(value)
		end
	end
	return coldMul(a, b)
end
NanoNum.fast.mulSS = function(a: string, b: string): buffer return NanoNum.fast.mulBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.mulSB = function(a: string, b: buffer): buffer return NanoNum.fast.mulBB(NanoNum.fromString(a), b) end
NanoNum.fast.mulBS = function(a: buffer, b: string): buffer return NanoNum.fast.mulBB(a, NanoNum.fromString(b)) end
NanoNum.fast.mulSN = function(a: string, b: number): buffer return NanoNum.fast.mulBN(NanoNum.fromString(a), b) end
NanoNum.fast.mulNS = function(a: number, b: string): buffer return NanoNum.fast.mulNB(a, NanoNum.fromString(b)) end
NanoNum.fast.divBN = function(a: buffer, b: number): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		if bx ~= 0 then
			local value = ax / bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				return encodeNumber(value)
			end
		end
	end
	return coldDiv(a, b)
end
NanoNum.fast.divNB = function(a: number, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if bx ~= 0 then
			local value = ax / bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				return encodeNumber(value)
			end
		end
	end
	return coldDiv(a, b)
end
NanoNum.fast.divSS = function(a: string, b: string): buffer return NanoNum.fast.divBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.divSB = function(a: string, b: buffer): buffer return NanoNum.fast.divBB(NanoNum.fromString(a), b) end
NanoNum.fast.divBS = function(a: buffer, b: string): buffer return NanoNum.fast.divBB(a, NanoNum.fromString(b)) end
NanoNum.fast.divSN = function(a: string, b: number): buffer return NanoNum.fast.divBN(NanoNum.fromString(a), b) end
NanoNum.fast.divNS = function(a: number, b: string): buffer return NanoNum.fast.divNB(a, NanoNum.fromString(b)) end
NanoNum.fast.powBN = function(a: buffer, b: number): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		if bx == 0 or ax == 1 then
			local value: number = 1
			return encodeNumber(value)
		end
		if ax >= 0 or bx == floor(bx) then
			local value = ax ^ bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				return encodeNumber(value)
			end
		end
	end
	return coldPow(a, b)
end
NanoNum.fast.powNB = function(a: number, b: buffer): buffer
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if bx == 0 or ax == 1 then
			local value: number = 1
			return encodeNumber(value)
		end
		if ax >= 0 or bx == floor(bx) then
			local value = ax ^ bx
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or ax == 0) then
				return encodeNumber(value)
			end
		end
	end
	return coldPow(a, b)
end
NanoNum.fast.powSS = function(a: string, b: string): buffer return NanoNum.fast.powBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.powSB = function(a: string, b: buffer): buffer return NanoNum.fast.powBB(NanoNum.fromString(a), b) end
NanoNum.fast.powBS = function(a: buffer, b: string): buffer return NanoNum.fast.powBB(a, NanoNum.fromString(b)) end
NanoNum.fast.powSN = function(a: string, b: number): buffer return NanoNum.fast.powBN(NanoNum.fromString(a), b) end
NanoNum.fast.powNS = function(a: number, b: string): buffer return NanoNum.fast.powNB(a, NanoNum.fromString(b)) end
NanoNum.fast.compareBN = function(a: buffer, b: number): number
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	local first: number = bufferReadU8(a, 0)
	if first == 255 then
		ax = bufferReadF64(a, 1)
		adirect = ax == ax and ax ~= huge and ax ~= -huge
	elseif band(first, 1) == 0 then
		ax = floor(first / 2)
		adirect = true
	elseif band(first, 3) == 1 then
		ax = -(floor(first / 4) + 1)
		adirect = true
	elseif band(first, 7) == 3 then
		local negative = band(first, 8) ~= 0
		local n: number = bufferReadBits(a, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(a, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(a, offset, n)
			else
				magnitude = bufferReadBits(a, offset, 32) + bufferReadBits(a, offset + 32, n - 32) * 4294967296
			end
			ax = negative and -magnitude or magnitude
			adirect = true
		end
	end
	bx = b
	bdirect = bx == bx and bx ~= huge and bx ~= -huge
	if adirect and bdirect then
		if ax < bx then return -1 elseif ax > bx then return 1 else return 0 end
	end
	return coldCompare(a, b)
end
NanoNum.fast.compareNB = function(a: number, b: buffer): number
	local ax, bx = 0, 0
	local adirect, bdirect = false, false
	ax = a
	adirect = ax == ax and ax ~= huge and ax ~= -huge
	local second: number = bufferReadU8(b, 0)
	if second == 255 then
		bx = bufferReadF64(b, 1)
		bdirect = bx == bx and bx ~= huge and bx ~= -huge
	elseif band(second, 1) == 0 then
		bx = floor(second / 2)
		bdirect = true
	elseif band(second, 3) == 1 then
		bx = -(floor(second / 4) + 1)
		bdirect = true
	elseif band(second, 7) == 3 then
		local negative = band(second, 8) ~= 0
		local n: number = bufferReadBits(b, 4, 5)
		local offset: number = 9
		if n == 0 then
			n = 32 + bufferReadBits(b, offset, 5)
			offset = 14
		end
		if n <= MAX_INTEGER_MODE_BITS then
			local magnitude
			if n <= 32 then
				magnitude = bufferReadBits(b, offset, n)
			else
				magnitude = bufferReadBits(b, offset, 32) + bufferReadBits(b, offset + 32, n - 32) * 4294967296
			end
			bx = negative and -magnitude or magnitude
			bdirect = true
		end
	end
	if adirect and bdirect then
		if ax < bx then return -1 elseif ax > bx then return 1 else return 0 end
	end
	return coldCompare(a, b)
end
NanoNum.fast.compareSS = function(a: string, b: string): number return NanoNum.fast.compareBB(NanoNum.fromString(a), NanoNum.fromString(b)) end
NanoNum.fast.compareSB = function(a: string, b: buffer): number return NanoNum.fast.compareBB(NanoNum.fromString(a), b) end
NanoNum.fast.compareBS = function(a: buffer, b: string): number return NanoNum.fast.compareBB(a, NanoNum.fromString(b)) end
NanoNum.fast.compareSN = function(a: string, b: number): number return NanoNum.fast.compareBN(NanoNum.fromString(a), b) end
NanoNum.fast.compareNS = function(a: number, b: string): number return NanoNum.fast.compareNB(a, NanoNum.fromString(b)) end
function NanoNum.bindBinary(operation: BindOperation, leftType: DirectValueType, rightType: DirectValueType): BoundBinaryFunction?
	local leftCode = TYPE_CODE[leftType] or leftType
	local rightCode = TYPE_CODE[rightType] or rightType
	if (leftCode ~= "N" and leftCode ~= "B" and leftCode ~= "S") or (rightCode ~= "N" and rightCode ~= "B" and rightCode ~= "S") then return nil end
	local prefix = operation
	local fn = NanoNum.fast[prefix .. leftCode .. rightCode]
	return fn
end
function NanoNum.bindRight(operation: MathBinaryOperation, constant: MathValue, leftType: DirectValueType?): BoundUnaryFunction?
	local constantKind = typeof(constant)
	if constantKind ~= "number" and constantKind ~= "string" and constantKind ~= "buffer" then return nil end
	local compiled = constantKind == "string" and NanoNum.fromString(constant) or constant
	local rightCode = constantKind == "number" and "N" or "B"
	local leftCode = if leftType == nil then nil else (TYPE_CODE[leftType] or leftType)
	if leftCode ~= nil and leftCode ~= "N" and leftCode ~= "B" and leftCode ~= "S" then return nil end
	if leftCode ~= nil then
		local fn = NanoNum.fast[operation .. leftCode .. rightCode]
		if fn == nil then return nil end
		return function(value) return fn(value, compiled) end
	end
	local fn = NanoNum[operation]
	if fn == nil then return nil end
	return function(value) return fn(value, compiled) end
end
function NanoNum.isMathValue(value: any): boolean
	local kind = typeof(value)
	if kind == "number" or kind == "string" then return true end
	if kind == "buffer" then return NanoNum.isValid(value) end
	return false
end
function NanoNum.tryCompile(value: any): (boolean, buffer?)
	if not NanoNum.isMathValue(value) then return false, nil end
	local ok, result = fastPcall(NanoNum.compile, value)
	if not ok or typeof(result) ~= "buffer" or not NanoNum.isValid(result) then return false, nil end
	return not NanoNum.isNaN(result), result
end
function NanoNum.tryMath(operation: MathBinaryOperation, a: any, b: any): (boolean, buffer?)
	local fn = NanoNum[operation]
	if fn == nil or (operation :: string) == "compare" or not NanoNum.isMathValue(a) or not NanoNum.isMathValue(b) then return false, nil end
	local ok, result = fastPcall(fn, a, b)
	if not ok or typeof(result) ~= "buffer" or not NanoNum.isValid(result) or NanoNum.isNaN(result) then return false, nil end
	return true, result
end
function NanoNum.tryCompare(a: any, b: any): (boolean, number?)
	if not NanoNum.isMathValue(a) or not NanoNum.isMathValue(b) then return false, nil end
	local ok, result = fastPcall(NanoNum.compare, a, b)
	if not ok or typeof(result) ~= "number" or result ~= result then return false, nil end
	return true, result
end
function NanoNum.engineInfo()
	return {
		Version = NanoNum.VERSION,
		BinaryFormatVersion = NanoNum.BINARY_FORMAT_VERSION,
		CanonicalVersion = NanoNum.CANONICAL_VERSION,
		RangePromotionVersion = NanoNum.RANGE_PROMOTION_VERSION,
		PowerVersion = NanoNum.POWER_VERSION,
		CanonicalApiVersion = NanoNum.CANONICAL_API_VERSION,
		ScientificApiVersion = NanoNum.SCIENTIFIC_API_VERSION,
		FastUnaryVersion = NanoNum.FAST_UNARY_VERSION,
		CompactKernelVersion = NanoNum.COMPACT_KERNEL_VERSION,
		LegacyNormalRecords = false,
		MaxLayer = NanoNum.MAX_LAYER,
		MaxLayerLog10 = NanoNum.MAX_LAYER_LOG10,
		MaxLayerLog10Log10 = NanoNum.MAX_LAYER_LOG10_LOG10,
		HyperLayer = true,
		HyperLayerVersion = NanoNum.HYPER_LAYER_VERSION,
		StringParserVersion = NanoNum.STRING_PARSER_VERSION,
		InlineMathVersion = NanoNum.INLINE_MATH_VERSION,
		ColdFallbackVersion = NanoNum.COLD_FALLBACK_VERSION,
		ExactFinite = true,
		HugePowerPromotion = true,
		HugeFactorialApproximation = true,
	}
end
function NanoNum.mathPerfInfo(): MathPerfInfo
	return {
		Version = NanoNum.MATH_PERF_VERSION,
		PathVersion = NanoNum.MATH_PATH_VERSION,
		DefaultPath = 0,
		Path0 = "NanoNum 2.4.1 finite kernel; 32-bit integer codec chunks; shared exact finite encoder",
		Path1 = "canonical log/layer/hyper-layer fallback kernel; cached combinatorics; compact source under 10k lines",
		TemporaryDecodeTablesOnPath0 = 0,
	}
end
function NanoNum.callPerfInfo(): CallPerfInfo
	return {
		Version = NanoNum.CALL_VERSION,
		DirectCallVersion = NanoNum.DIRECT_CALL_VERSION,
		BindVersion = NanoNum.BIND_VERSION,
		CompileVersion = NanoNum.COMPILE_VERSION,
		MathPerfVersion = NanoNum.MATH_PERF_VERSION,
		MathPathVersion = NanoNum.MATH_PATH_VERSION,
		FlexibleTypeChecksPerBinaryCall = 2,
		DirectTypeChecksPerBinaryCall = 0,
		StringParsingCanBeEliminatedByCompile = true,
	}
end
local FIXED_FORMATS = {"%.0f", "%.1f", "%.2f", "%.3f", "%.4f", "%.5f", "%.6f", "%.7f", "%.8f", "%.9f", "%.10f", "%.11f", "%.12f"}
-- Formatter/time internals use a dedicated function frame for independent register allocation.
(function()
	local ROMAN_VALUES = {1000,900,500,400,100,90,50,40,10,9,5,4,1}
	local ROMAN_SYMBOLS = {"M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"}
	local function trimZeros(value: string): string
		local n = #value
		local dot: number = 0
		for i = 1, n do if byte(value, i) == 46 then dot = i; break end end
		if dot == 0 then return value end
		local last = n
		while last > dot and byte(value, last) == 48 do last -= 1 end
		if last == dot then last -= 1 end
		if last == n then return value end
		local result = sub(value, 1, last)
		return result == "-0" and "0" or result
	end
	local function shortNumber(value: number, decimalPlaces: number): string
		local decimals: number = clamp(floor(decimalPlaces), 0, 12)
		local text = trimZeros(format(FIXED_FORMATS[decimals + 1], value))
		return text == "-0" and "0" or text
	end
	local function roundedPositive(value: number, decimalPlaces: number): number
		local decimals: number = clamp(floor(decimalPlaces), 0, 12)
		local scale = POW10_DECIMAL[decimals + 1]
		return math.round(value * scale) / scale
	end
	local function commaFiniteText(value: number, decimalPlaces: number): string?
		local rounded = roundedPositive(value, decimalPlaces)
		if rounded >= 1000000 then return nil end
		local text = shortNumber(rounded, decimalPlaces)
		local dot: number = 0
		for i = 1, #text do if byte(text, i) == 46 then dot = i; break end end
		local integerEnd = dot == 0 and #text or dot - 1
		local cut = integerEnd - 3
		if cut <= 0 then return text end
		return sub(text, 1, cut) .. "," .. sub(text, cut + 1)
	end
	local function groupedFiniteText(value: number, decimalPlaces: number): string
		if value ~= value then return "NaN" end
		if value == huge then return "inf" end
		if value == -huge then return "-inf" end
		local text = shortNumber(value, decimalPlaces)
		local negative = byte(text, 1) == 45
		local firstDigit = negative and 2 or 1
		local dot: number = 0
		for i = firstDigit, #text do if byte(text, i) == 46 then dot = i; break end end
		local integerEnd = dot == 0 and #text or dot - 1
		local integerDigits = integerEnd - firstDigit + 1
		if integerDigits <= 3 then return text end
		local firstGroup = integerDigits % 3
		if firstGroup == 0 then firstGroup = 3 end
		local out = tableCreate(floor((integerDigits - 1) / 3) + 4)
		local count: number = 0
		if negative then count += 1; out[count] = "-" end
		local pos = firstDigit
		count += 1; out[count] = sub(text, pos, pos + firstGroup - 1)
		pos += firstGroup
		while pos <= integerEnd do
			count += 1; out[count] = ","
			count += 1; out[count] = sub(text, pos, pos + 2)
			pos += 3
		end
		if dot ~= 0 then count += 1; out[count] = sub(text, dot) end
		return concat(out, "", 1, count)
	end
	-- Format the coefficient of standard E and L descriptors with the SAME
	-- k/m/b/... family used by ordinary standard numbers. Do not round an
	-- exponent containing a meaningful fractional correction into a suffix.
	local function standardInnerScale(value: number, precision: number): string?
		-- Exponent DESCRIPTORS are magnitudes, not precise integer counters.
		-- Applying SAFE_INTEGER here discarded suffix formatting for e32 and beyond.
		if value ~= value or value == huge or value < 1000 then return nil end
		local power = floor(log10(value))
		local index = floor(power / 3)
		local suffix = STANDARD_SUFFIXES[index]
		if suffix == nil then return nil end
		local scaled = value / 10 ^ (index * 3)
		local rounded = roundedPositive(scaled, precision)
		if rounded >= 1000 then
			local nextSuffix = STANDARD_SUFFIXES[index + 1]
			if nextSuffix == nil then return nil end
			rounded /= 1000
			suffix = nextSuffix
		end
		return shortNumber(rounded, precision) .. suffix
	end
	local function groupedEFromLog(logExponent: number, precision: number): string
		if logExponent ~= logExponent then return "NaN" end
		if logExponent == huge then return "Einf" end
		if logExponent == -huge then return "0" end
		local integerExponent: number = floor(logExponent)
		local mantissa = 10 ^ (logExponent - integerExponent)
		local roundedMantissa = roundedPositive(mantissa, precision)
		if roundedMantissa >= 10 then
			roundedMantissa /= 10
			integerExponent += 1
		end
		-- Preserve the part lost by rounding the mantissa as a small fractional
		-- correction on the E exponent. Exact powers of ten therefore stay clean
		-- (1E3,126), while other values can render like 1.23E3,000.03.
		local exponentCorrection: number = 0
		if roundedMantissa > 0 then exponentCorrection = logExponent - integerExponent - log10(roundedMantissa) end
		local displayExponent = integerExponent + exponentCorrection
		-- Standard E retains readable suffixes in the INNER exponent: 2E3k,
		-- 1E10M, etc. When a correction is material, keep its decimal form.
		local inner = standardInnerScale(displayExponent, precision)
		return shortNumber(roundedMantissa, precision) .. "E" .. (inner or groupedFiniteText(displayExponent, precision))
	end
	local function plainFiniteText(value: number, decimalPlaces: number): string
		if value == 0 then return "0" end
		local magnitude: number = abs(value)
		if magnitude >= 1 then return shortNumber(value, decimalPlaces) end
		local exponent: number = floor(log10(magnitude))
		if exponent < -12 then
			local mantissa = magnitude / 10 ^ exponent
			local rounded = roundedPositive(mantissa, decimalPlaces)
			if rounded >= 10 then rounded /= 10; exponent += 1 end
			local text = shortNumber(rounded, decimalPlaces) .. "e" .. toString(exponent)
			return value < 0 and "-" .. text or text
		end
		local decimals: number = max(decimalPlaces, -exponent + decimalPlaces)
		return shortNumber(value, min(decimals, 12))
	end
	local function scientificText(mantissa: number, exponent: number, decimalPlaces: number): string
		if mantissa <= 0 or mantissa ~= mantissa then return "NaN" end
		while mantissa >= 10 do mantissa /= 10; exponent += 1 end
		while mantissa < 1 do mantissa *= 10; exponent -= 1 end
		mantissa = roundedPositive(mantissa, decimalPlaces)
		if mantissa >= 10 then mantissa /= 10; exponent += 1 end
		return shortNumber(mantissa, decimalPlaces) .. "e" .. toString(exponent)
	end
	local function engineeringText(mantissa: number, exponent: number, decimalPlaces: number): string
		local engineeringExponent = floor(exponent / 3) * 3
		local scaled = mantissa * 10 ^ (exponent - engineeringExponent)
		scaled = roundedPositive(scaled, decimalPlaces)
		if scaled >= 1000 then scaled /= 1000; engineeringExponent += 3 end
		return shortNumber(scaled, decimalPlaces) .. "e" .. toString(engineeringExponent)
	end
	local function exponentText(mantissa: number, exponent: number, decimalPlaces: number): string
		while mantissa >= 10 do mantissa /= 10; exponent += 1 end
		while mantissa < 1 do mantissa *= 10; exponent -= 1 end
		mantissa = roundedPositive(mantissa, decimalPlaces)
		if mantissa >= 10 then mantissa /= 10; exponent += 1 end
		return shortNumber(mantissa, decimalPlaces) .. "E" .. toString(exponent)
	end
	local function formatNormalParts(mantissa: number, exponent: number, precision: number, kind: string): string
		if kind == "scientific" then return scientificText(mantissa, exponent, precision) end
		if kind == "engineering" then return engineeringText(mantissa, exponent, precision) end
		if kind == "exponent" then return exponentText(mantissa, exponent, precision) end
		if exponent < 3 and exponent >= 0 then
			local direct = roundedPositive(mantissa * 10 ^ exponent, precision)
			if direct >= 1000 then return formatNormalParts(1, 3, precision, kind) end
			return shortNumber(direct, precision)
		end
		if exponent >= 3 then
			local index: number = floor(exponent / 3)
			local scaled = mantissa * 10 ^ (exponent - index * 3)
			scaled = roundedPositive(scaled, precision)
			if scaled >= 1000 then scaled /= 1000; index += 1 end
			local suffix = suffixForIndex(index, kind)
			if suffix ~= nil then return shortNumber(scaled, precision) .. suffix end
		end
		if exponent < 0 then
			local inverseMantissa = 10 / mantissa
			local inverseExponent = -exponent - 1
			return "1/" .. formatNormalParts(inverseMantissa, inverseExponent, precision, kind)
		end
		return scientificText(mantissa, exponent, precision)
	end
	local function formatDisplayScalar(value: number, precision: number): string
		if value ~= value then return "NaN" end
		if value == huge then return "inf" end
		if value == -huge then return "-inf" end
		if value == 0 then return "0" end
		local negative = value < 0
		local magnitude = negative and -value or value
		local text
		if magnitude < 1 then
			text = plainFiniteText(magnitude, precision)
		else
			local exponent: number = floor(log10(magnitude))
			local mantissa = magnitude / 10 ^ exponent
			text = formatNormalParts(mantissa, exponent, precision, "standard")
			if exponent >= NanoNum.E_NOTATION_START then text = groupedEFromLog(log10(magnitude), precision) end
		end
		return negative and "-" .. text or text
	end
	local function formatLayerDisplay(layer: number, top: number, precision: number): string
		return "L" .. formatDisplayScalar(layer, precision) .. " " .. formatDisplayScalar(top, precision)
	end
	local function formatLayerLogDisplay(layerLog10: number, top: number, precision: number): string
		return "LE" .. formatDisplayScalar(layerLog10, precision) .. " " .. formatDisplayScalar(top, precision)
	end
	local function formatHyperLayerDisplay(layerLog10Log10: number, top: number, precision: number): string
		return "LEE" .. formatDisplayScalar(layerLog10Log10, precision) .. " " .. formatDisplayScalar(top, precision)
	end
	local function formatLayer2AsE(top: number, precision: number, reciprocal: boolean): string?
		-- A layer-2 value is 10^(10^top). Keep displaying it in the E family
		-- while the exponent 10^top still fits the configured standard suffix
		-- range. Only after that ceiling do we expose L2.
		if top < 0 or top > NanoNum.E_LAYER_TOP_MAX then return nil end
		local exponentInteger: number = floor(top)
		local exponentMantissa = 10 ^ (top - exponentInteger)
		local descriptor = formatNormalParts(exponentMantissa, exponentInteger, precision, "standard")
		return "1E" .. (reciprocal and "-" or "") .. descriptor
	end
	local function romanClassical(value: number): string
		local out = tableCreate(16)
		local count: number = 0
		for i = 1, #ROMAN_VALUES do
			while value >= ROMAN_VALUES[i] do
				value -= ROMAN_VALUES[i]
				count += 1
				out[count] = ROMAN_SYMBOLS[i]
			end
		end
		return concat(out, "", 1, count)
	end
	local function romanExtended(value: number): string
		if value <= 3999 then return romanClassical(value) end
		local groups = {}
		local depth: number = 0
		while value > 0 do
			local nextValue: number = floor(value / 1000)
			local group = value - nextValue * 1000
			if group > 0 then
				local text = romanClassical(group)
				if depth > 0 then text = rep("(", depth) .. text .. rep(")", depth) end
				table.insert(groups, 1, text)
			end
			value = nextValue
			depth += 1
		end
		return concat(groups)
	end
	local function formatRomanInteger(value: number, extended: boolean): string?
		if value ~= floor(value) or abs(value) > SAFE_INTEGER then return nil end
		if value == 0 then return "N" end
		local negative = value < 0
		local magnitude: number = abs(value)
		if not extended and magnitude > 3999 then return nil end
		local text = extended and romanExtended(magnitude) or romanClassical(magnitude)
		return negative and "-" .. text or text
	end
	-- Approximate compact exponent presentation. Exponent decimal text is
	-- retained only for original parsed buffers; computed results cannot recover
	-- digits discarded by floating-point logarithmic arithmetic.
	local function compactExponentText(exponent: string, precision: number): string
		local negative = string.byte(exponent, 1) == 45
		local digits = (negative or string.byte(exponent, 1) == 43) and string.sub(exponent, 2) or exponent
		local embedded = string.match(digits, "^[%d%.]+[eE][+%-]?%d+$")
		if embedded ~= nil then return (negative and "-" or "") .. digits end
		digits = string.gsub(digits, "^0+", "")
		if digits == "" then return "0" end
		if #digits <= 15 then return (negative and "-" or "") .. digits end
		local leading = tonumber(string.sub(digits, 1, math.min(#digits, 15)))
		if leading == nil then return "NaN" end
		local leadingDigits = math.min(#digits, 15)
		local descriptor = leading / 10 ^ (leadingDigits - 1)
		local rounded = tonumber(format(FIXED_FORMATS[precision + 1], descriptor)) or descriptor
		local power = #digits - 1
		if rounded >= 10 then rounded = 1; power += 1 end
		return (negative and "-" or "") .. shortNumber(rounded, precision) .. "e" .. toString(power)
	end
	local function compactOriginal(value: buffer, precision: number, kind: string): string?
		local original = COMPACT_DISPLAY[value]
		if original == nil then return nil end
		local m = tonumber(original.mantissa)
		if m == nil or m == 0 then return nil end
		local sign = m < 0 and "-" or ""
		local absolute = math.abs(m)
		local exponent = original.exponent
		-- Already compressed input retains its exponent expression as supplied.
		local exponentText = compactExponentText(exponent, precision)
		if kind == "standard" then
			-- Keep using standard suffixes regardless of exponent size, including
			-- exponents too large to convert to an IEEE-754 finite number.
			local digits = exponent
			local negativeExponent = byte(digits, 1) == 45
			if negativeExponent or byte(digits, 1) == 43 then digits = sub(digits, 2) end
			local descriptor: string? = nil
			if #digits > 0 then
				local isIntegerDigits = true
				for i = 1, #digits do
					local digit = byte(digits, i)
					if digit < 48 or digit > 57 then isIntegerDigits = false; break end
				end
				if isIntegerDigits then
					local first = 1
					while first < #digits and byte(digits, first) == 48 do first += 1 end
					local count = #digits - first + 1
					if count < 309 then
						local numeric = toNumber(sub(digits, first))
						if numeric ~= nil then descriptor = standardInnerScale(numeric, precision) end
					elseif count <= 2998 then
						-- Build the standard suffix directly from decimal leading digits;
						-- never convert a thousand-digit exponent through tonumber.
						local power = count - 1
						local index = floor(power / 3)
						local suffix = STANDARD_SUFFIXES[index]
						if suffix ~= nil then
							local leadCount = math.min(count, 15)
							local lead = toNumber(sub(digits, first, first + leadCount - 1))
							if lead ~= nil then
								local scaled = lead / 10 ^ (leadCount - 1 - power % 3)
								local rounded = roundedPositive(scaled, precision)
								if rounded >= 1000 and STANDARD_SUFFIXES[index + 1] ~= nil then
									rounded /= 1000; suffix = STANDARD_SUFFIXES[index + 1]
								end
								descriptor = shortNumber(rounded, precision) .. suffix
							end
						end
					end
				else
					local numeric = toNumber(exponent)
					if numeric ~= nil then descriptor = standardInnerScale(math.abs(numeric), precision) end
				end
			end
			if descriptor ~= nil then exponentText = (negativeExponent and "-" or "") .. descriptor end
		end
		-- Standard's scale is intentional: commas/suffixes first, uppercase
		-- E beginning at e3000, and L when the exponent itself outgrows
		-- the layer-2 E display window. Do not apply these thresholds to
		-- explicitly selected notation families.
		if kind == "standard" or kind == "extended" then
			local numericExponent = toNumber(exponent)
			if numericExponent ~= nil and numericExponent == numericExponent and numericExponent >= 0 and numericExponent < NanoNum.E_NOTATION_START then
				-- A metadata-bearing input may contain many leading zeroes.
				-- Preserve its coefficient while using the correct suffix family.
				local normalExponent = floor(numericExponent)
				if normalExponent == numericExponent and absolute >= 1 and absolute < 10 then
					return sign .. formatNormalParts(absolute, normalExponent, precision, kind)
				end
			end
			-- Decimal strings longer than ~2998 significant digits describe
			-- an exponent outside the configured E -> L boundary. Its exact
			-- coefficient cannot be encoded into legacy K_LAYER2; the layer
			-- display is necessarily approximate.
			if #exponent >= 2999 and byte(exponent, 1) ~= 45 then
				local leadingText = sub(exponent, 1, 15)
				local leading = toNumber(leadingText)
				if leading ~= nil and leading > 0 then
					local top = #exponent - 1 + log10(leading / (10 ^ (#leadingText - 1)))
					return sign .. formatLayerDisplay(2, top, precision)
				end
			end
		end
		-- Format selection is intentional: nil selects DEFAULT_SUFFIX_TYPE
		-- (standard), which retains its uppercase E fallback; only the
		-- explicit scientific/hybrid forms use lowercase e here.
		-- Suffix families have a finite useful range. For these huge inputs
		-- use that FAMILY's documented overflow fallback rather than
		-- manufacturing a nonexistent suffix or overriding the user's choice.
		local marker = (kind == "standard" or kind == "extended" or kind == "metric"
			or kind == "exponent" or kind == "roman" or kind == "romanextended") and "E" or "e"
		return sign .. shortNumber(absolute, precision) .. marker .. exponentText
	end
	local function formatCore(value: buffer, precision: number, kind: string): string
		local preserved = compactOriginal(value, precision, kind)
		if preserved ~= nil then return preserved end
		local k, a, b = decodeRegBuffer(value)
		if k == 0 then return "0" end
		local absoluteKind: number = abs(k)
		local negative = k < 0
		if absoluteKind == K_NAN then return "NaN" end
		if absoluteKind == K_INF then return negative and "-Inf" or "Inf" end
		if absoluteKind == K_NUM then
			local n = negative and -a or a
			if kind == "roman" or kind == "romanextended" then
				local roman = formatRomanInteger(n, kind == "romanextended")
				if roman ~= nil then return roman end
				kind = "standard"
			end
			local magnitude: number = abs(n)
			if magnitude == 0 then return "0" end
			local exponent: number = floor(log10(magnitude))
			local mantissa = magnitude / 10 ^ exponent
			local text
			if kind == "scientific" then text = scientificText(mantissa, exponent, precision)
			elseif kind == "engineering" then text = engineeringText(mantissa, exponent, precision)
			elseif kind == "exponent" then text = exponentText(mantissa, exponent, precision)
			elseif kind == "standard" then
				if magnitude < 0.001 then text = formatNormalParts(mantissa, exponent, precision, kind)
				elseif magnitude < 1000 then text = shortNumber(roundedPositive(magnitude, precision), precision)
				elseif magnitude < 1000000 then
					local grouped = commaFiniteText(magnitude, precision)
					text = grouped or formatNormalParts(1, 6, precision, kind)
				else text = formatNormalParts(mantissa, exponent, precision, kind) end
			elseif magnitude < 1 then text = plainFiniteText(magnitude, precision)
			else text = formatNormalParts(mantissa, exponent, precision, kind) end
			return negative and "-" .. text or text
		end
		if absoluteKind == K_LOG then
			local explicit = kind == "scientific" or kind == "engineering" or kind == "exponent"
			local scalarKind = kind
			if scalarKind == "roman" or scalarKind == "romanextended" then scalarKind = "standard" end
			local text
			if abs(a) > SAFE_INTEGER and abs(a) < huge then
				-- Computed K_LOG values have no exact decimal mantissa metadata.
				-- Compact their approximate exponent without implying restored precision.
				local exponentSign = a < 0 and "-" or ""
				local magnitude = abs(a)
				local power = floor(log10(magnitude))
				local descriptor = magnitude / 10 ^ power
				local rounded = roundedPositive(descriptor, precision)
				if rounded >= 10 then rounded = 1; power += 1 end
				local symbol = (kind == "standard" or kind == "extended" or kind == "metric"
					or kind == "exponent" or kind == "roman" or kind == "romanextended") and "E" or "e"
				local inner = kind == "standard" and standardInnerScale(magnitude, precision) or nil
				local body = "1" .. symbol .. exponentSign .. (inner or (shortNumber(rounded, precision) .. "e" .. toString(power)))
				return negative and "-" .. body or body
			end
			if explicit and abs(a) <= SAFE_INTEGER then
				local integerExponent: number = floor(a)
				local mantissa = 10 ^ (a - integerExponent)
				text = formatNormalParts(mantissa, integerExponent, precision, kind)
			elseif (scalarKind == "standard" or scalarKind == "extended" or scalarKind == "metric") and abs(a) >= NanoNum.E_NOTATION_START then
				-- K_LOG stays E-notation. Never promote to L2 based on output length;
				-- L2 is reserved for actual K_LAYER values.
				text = groupedEFromLog(a, precision)
			else
				local integerExponent: number = floor(a)
				local mantissa = 10 ^ (a - integerExponent)
				text = formatNormalParts(mantissa, integerExponent, precision, scalarKind)
			end
			return negative and "-" .. text or text
		end
		local reciprocal = a < 0
		local layer: number = abs(a)
		local text
		if absoluteKind == K_LAYER and layer == 2 then
			-- Standard notation alone owns the E -> L transition.
			-- Other selected styles retain their existing layer rendering.
			if kind == "standard" then text = formatLayer2AsE(b, precision, reciprocal) end
			if text == nil then
				text = formatLayerDisplay(layer, b, precision)
				if reciprocal then text = "1/" .. text end
			end
		elseif absoluteKind == K_HYPER_LAYER then
			text = formatHyperLayerDisplay(layer, b, precision)
			if reciprocal then text = "1/" .. text end
		elseif absoluteKind == K_LAYER_LOG then
			text = formatLayerLogDisplay(layer, b, precision)
			if reciprocal then text = "1/" .. text end
		else
			text = formatLayerDisplay(layer, b, precision)
			if reciprocal then text = "1/" .. text end
		end
		return negative and "-" .. text or text
	end
	local function resolvePrecision(value: number?): number
		return value == nil and NanoNum.DEFAULT_PRECISION or clamp(floor(value), 0, NanoNum.MAX_PRECISION)
	end
	function NanoNum.format(value: buffer, decimalPlaces: number?, suffixType: SuffixName?): string return formatCore(value, resolvePrecision(decimalPlaces), normalizeSuffixType(suffixType)) end
	function NanoNum.formatStandard(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "standard") end
	function NanoNum.formatExtended(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "extended") end
	function NanoNum.formatExponent(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "exponent") end
	function NanoNum.formatHybrid(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "hybrid") end
	function NanoNum.formatAlphabetic(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "alphabetic") end
	function NanoNum.formatMetric(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "metric") end
	function NanoNum.formatScientific(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "scientific") end
	function NanoNum.formatEngineering(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "engineering") end
	function NanoNum.formatRoman(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "roman") end
	function NanoNum.formatRomanExtended(value: buffer, decimalPlaces: number?): string return formatCore(value, resolvePrecision(decimalPlaces), "romanextended") end
	local function fixedTrim(value: number, precision: number): string
		local text
		if precision <= 0 then text = format("%.0f", value)
		else
			text = format("%." .. toString(precision) .. "f", value)
			text = gsub(text, "0+$", "")
			text = gsub(text, "%.$", "")
		end
		return text == "-0" and "0" or text
	end
	function NanoNum.formatTime(value: MathValue, style: TimeStyle?, precision: number?, maxParts: number?): string
		local valueKind = typeof(value)
		local compiled
		local n
		local negative
		if valueKind == "number" then
			n = value :: number
			if n ~= n then return "NaN" end
			negative = n < 0
		elseif valueKind == "buffer" then
			compiled = value :: buffer
			n = NanoNum.toNumber(compiled)
			if n ~= n then return "NaN" end
			negative = NanoNum.isNegative(compiled)
		elseif valueKind == "string" then
			compiled = NanoNum.fromString(value :: string)
			n = NanoNum.toNumber(compiled)
			if n ~= n then return "NaN" end
			negative = NanoNum.isNegative(compiled)
		else
			return "NaN"
		end
		if precision ~= nil and (typeof(precision) ~= "number" or precision ~= precision or precision == huge or precision == -huge) then return "NaN" end
		if maxParts ~= nil and (typeof(maxParts) ~= "number" or maxParts ~= maxParts or maxParts == huge or maxParts == -huge) then return "NaN" end
		local p = precision == nil and 2 or clamp(floor(precision), 0, 6)
		local mode = lower(style or "compact")
		if mode ~= "compact" and mode ~= "long" and mode ~= "clock" and mode ~= "seconds" then mode = "compact" end
		local partsLimit = maxParts == nil and 4 or max(1, floor(maxParts))
		if n == huge or n == -huge then
			if valueKind == "number" or compiled == nil or NanoNum.isInfinite(compiled) then return negative and "-inf" or "inf" end
			local magnitude = NanoNum.abs(compiled)
			if mode == "seconds" or mode == "clock" then
				local result = NanoNum.format(magnitude, p) .. "s"
				return negative and "-" .. result or result
			end
			local years = NanoNum.div(magnitude, 31557600)
			local amount = NanoNum.format(years, p)
			local result = mode == "long" and amount .. " years" or amount .. "y"
			return negative and "-" .. result or result
		end
		local total: number = abs(n)
		if total == 0 then
			if mode == "clock" then
				local secondsText = p > 0 and "00." .. rep("0", p) or "00"
				return "0:00:" .. secondsText
			end
			if mode == "seconds" then return "0s" end
			return mode == "long" and "0 seconds" or "0s"
		end
		if mode == "seconds" then
			local result = fixedTrim(total, p) .. "s"
			return negative and "-" .. result or result
		end
		if mode ~= "clock" and total < 1 then
			local milliseconds = total * 1000
			local amount = fixedTrim(milliseconds, p)
			if toNumber(amount) == 0 then amount = format("%.6g", milliseconds) end
			local result
			if mode == "long" then
				local exactOne = abs(milliseconds - 1) <= 1e-12
				result = amount .. (exactOne and " millisecond" or " milliseconds")
			else
				result = amount .. " ms"
			end
			return negative and "-" .. result or result
		end
		local scale = 10 ^ p
		local whole
		local fractionTicks: number = 0
		if total <= SAFE_INTEGER / scale then
			local ticks = math.round(total * scale)
			whole = floor(ticks / scale)
			fractionTicks = ticks - whole * scale
		else
			whole = floor(total)
		end
		if mode == "clock" then
			local days: number = floor(whole / 86400)
			local rem = whole - days * 86400
			local hours: number = floor(rem / 3600)
			rem -= hours * 3600
			local minutes: number = floor(rem / 60)
			local seconds = rem - minutes * 60
			local secondsText
			if p > 0 then
				secondsText = format("%02d", seconds) .. "." .. format("%0" .. toString(p) .. "d", fractionTicks)
			else
				secondsText = format("%02d", seconds)
			end
			local result
			if days > 0 then result = format("%dd %02d:%02d:%s", days, hours, minutes, secondsText)
			else result = format("%d:%02d:%s", hours, minutes, secondsText) end
			return negative and "-" .. result or result
		end
		local rem = whole
		local years: number = floor(rem / 31557600)
		rem -= years * 31557600
		local weeks: number = floor(rem / 604800)
		rem -= weeks * 604800
		local days: number = floor(rem / 86400)
		rem -= days * 86400
		local hours: number = floor(rem / 3600)
		rem -= hours * 3600
		local minutes: number = floor(rem / 60)
		rem -= minutes * 60
		local seconds = rem + (p > 0 and fractionTicks / scale or 0)
		local result = {}
		local function addPart(amount: number, compactUnit: string, singular: string, plural: string)
			if #result >= partsLimit or amount == 0 then return end
			if mode == "long" then
				result[#result + 1] = toString(amount) .. " " .. (amount == 1 and singular or plural)
			else
				result[#result + 1] = toString(amount) .. compactUnit
			end
		end
		addPart(years, "y", "year", "years")
		addPart(weeks, "w", "week", "weeks")
		addPart(days, "d", "day", "days")
		addPart(hours, "h", "hour", "hours")
		addPart(minutes, "m", "minute", "minutes")
		if #result < partsLimit and (seconds ~= 0 or #result == 0) then
			local amount = fixedTrim(seconds, p)
			if mode == "long" then result[#result + 1] = amount .. " " .. (abs(seconds - 1) <= 1e-12 and "second" or "seconds")
			else result[#result + 1] = amount .. "s" end
		end
		local resultText = concat(result, mode == "long" and ", " or " ")
		return negative and "-" .. resultText or resultText
	end
	function NanoNum.formatClock(value: MathValue, precision: number?): string
		return NanoNum.formatTime(value, "clock", precision, 4)
	end
	function NanoNum.parseTime(text: string): buffer
		local clean = trimText(text)
		if clean == "" then return makeSpecial(SPECIAL_NAN) end
		local negative: boolean = false
		local first = sub(clean, 1, 1)
		if first == "-" then negative = true; clean = trimText(sub(clean, 2))
		elseif first == "+" then clean = trimText(sub(clean, 2)) end
		if clean == "" then return makeSpecial(SPECIAL_NAN) end
		if find(clean, ":", 1, true) then
			local daySeconds: number = 0
			local hasDayPrefix: boolean = false
			local dayText, clockText = match(clean, "^(%d+)%s*[dD]%s+(.+)$")
			if dayText ~= nil then
				local days = toNumber(dayText)
				if days == nil or days < 0 or days ~= floor(days) then return makeSpecial(SPECIAL_NAN) end
				daySeconds = days * 86400
				clean = clockText
				hasDayPrefix = true
			end
			local fields = split(clean, ":")
			if #fields < 2 or #fields > 3 then return makeSpecial(SPECIAL_NAN) end
			local a = toNumber(trimText(fields[1]))
			local b = toNumber(trimText(fields[2]))
			local c = #fields == 3 and toNumber(trimText(fields[3])) or nil
			if a == nil or b == nil or a < 0 or b < 0 or a ~= a or b ~= b then return makeSpecial(SPECIAL_NAN) end
			if a ~= floor(a) or b ~= floor(b) then return makeSpecial(SPECIAL_NAN) end
			local total
			if #fields == 2 then
				if b >= 60 then return makeSpecial(SPECIAL_NAN) end
				total = daySeconds + a * 60 + b
			else
				if c == nil or c < 0 or c ~= c or b >= 60 or c >= 60 then return makeSpecial(SPECIAL_NAN) end
				if hasDayPrefix and a >= 24 then return makeSpecial(SPECIAL_NAN) end
				total = daySeconds + a * 3600 + b * 60 + c
			end
			return NanoNum.fromNumber(negative and -total or total)
		end
		clean = gsub(clean, ",", "")
		clean = gsub(clean, "µ", "u")
		clean = gsub(clean, "μ", "u")
		local units = {
			ns = 1e-9, nanosecond = 1e-9, nanoseconds = 1e-9,
			us = 1e-6, microsecond = 1e-6, microseconds = 1e-6,
			ms = 0.001, msec = 0.001, msecs = 0.001, millisecond = 0.001, milliseconds = 0.001,
			s = 1, sec = 1, secs = 1, second = 1, seconds = 1,
			m = 60, min = 60, mins = 60, minute = 60, minutes = 60,
			h = 3600, hr = 3600, hrs = 3600, hour = 3600, hours = 3600,
			d = 86400, day = 86400, days = 86400,
			w = 604800, week = 604800, weeks = 604800,
			y = 31557600, yr = 31557600, yrs = 31557600, year = 31557600, years = 31557600,
		}
		local total: number = 0
		local matched: number = 0
		local invalid: boolean = false
		local residue = gsub(lower(clean), "([%d]*%.?[%d]+)%s*([%a]+)", function(numberText, unitText)
			local amount = toNumber(numberText)
			local multiplier = units[unitText]
			if amount == nil or amount ~= amount or multiplier == nil then invalid = true; return "!" end
			matched += 1
			total += amount * multiplier
			return ""
		end)
		residue = gsub(residue, "[%s]+", "")
		if invalid or matched == 0 or residue ~= "" then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.fromNumber(negative and -total or total)
	end
	function NanoNum.formatRate(value: MathValue, unit: string?, decimalPlaces: number?, suffixType: SuffixName?): string
		return NanoNum.format(NanoNum.compile(value), decimalPlaces, suffixType) .. "/" .. (unit or "s")
	end
	function NanoNum.formatBytes(value: MathValue, precision: number?, binary: boolean?): string
		local compiled = NanoNum.compile(value)
		local n = NanoNum.toNumber(compiled)
		if n ~= n then return "NaN" end
		if precision ~= nil and (typeof(precision) ~= "number" or precision ~= precision or precision == huge or precision == -huge) then return "NaN" end
		local p = precision == nil and 2 or clamp(floor(precision), 0, 6)
		local negative = NanoNum.isNegative(compiled)
		local base = binary and 1024 or 1000
		local units = binary and {"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"} or {"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
		if n == huge or n == -huge then
			if NanoNum.isInfinite(compiled) then return negative and "-inf B" or "inf B" end
			local divisor = base ^ (#units - 1)
			local scaled = NanoNum.div(NanoNum.abs(compiled), divisor)
			local text = NanoNum.format(scaled, p) .. " " .. units[#units]
			return negative and "-" .. text or text
		end
		local magnitude: number = abs(n)
		local index: number = 1
		while magnitude >= base and index < #units do magnitude /= base; index += 1 end
		local displayMagnitude = roundedPositive(magnitude, p)
		if displayMagnitude >= base and index < #units then displayMagnitude /= base; index += 1 end
		local text = fixedTrim(displayMagnitude, p) .. " " .. units[index]
		return negative and "-" .. text or text
	end
	function NanoNum.formatOrdinal(value: MathValue): string
		local compiled = NanoNum.compile(value)
		local n = NanoNum.toNumber(compiled)
		if n ~= n or NanoNum.isInfinite(compiled) then return NanoNum.format(compiled) end
		if n == huge or n == -huge then
			if NanoNum.isInteger(compiled) then return NanoNum.format(compiled) .. "th" end
			return NanoNum.format(compiled)
		end
		if n ~= floor(n) then return NanoNum.format(compiled) end
		local magnitude: number = abs(n)
		local mod100 = magnitude % 100
		local suffix: string = "th"
		if mod100 < 11 or mod100 > 13 then
			local mod10 = magnitude % 10
			if mod10 == 1 then suffix = "st" elseif mod10 == 2 then suffix = "nd" elseif mod10 == 3 then suffix = "rd" end
		end
		return toString(n) .. suffix
	end
	function NanoNum.formatSigned(value: MathValue, precision: number?, suffixType: SuffixName?): string
		local b = NanoNum.compile(value)
		local text = NanoNum.format(b, precision, suffixType)
		if NanoNum.gt(b, 0) then return "+" .. text end
		return text
	end
end)()
local function copyBits(target: buffer, targetBit: number, source: buffer, sourceBit: number, count: number)
	if count <= 0 then return end
	if band(targetBit, 7) == 0 and band(sourceBit, 7) == 0 and count >= 8 then
		local bytes: number = floor(count / 8)
		if bytes > 0 then
			bufferCopy(target, targetBit / 8, source, sourceBit / 8, bytes)
			local copied = bytes * 8
			targetBit += copied
			sourceBit += copied
			count -= copied
		end
	end
	while count > 32 do
		bufferWriteBits(target, targetBit, 32, bufferReadBits(source, sourceBit, 32))
		targetBit += 32
		sourceBit += 32
		count -= 32
	end
	if count > 0 then bufferWriteBits(target, targetBit, count, bufferReadBits(source, sourceBit, count)) end
end
function NanoNum.packMany(values: {buffer}): (buffer, number)
	local totalBits: number = 0
	for i = 1, #values do totalBits += NanoNum.bitLength(values[i]) end
	local packed: buffer = bufferCreate(ceilBytes(totalBits))
	local offset: number = 0
	for i = 1, #values do
		local bits = NanoNum.bitLength(values[i])
		copyBits(packed, offset, values[i], 0, bits)
		offset += bits
	end
	return packed, totalBits
end
function NanoNum.unpackMany(packed: buffer, count: number, totalBits: number?): {buffer}
	local limit = totalBits or bufferLen(packed) * 8
	if count ~= count or count ~= floor(count) or count < 0 or limit ~= limit or limit ~= floor(limit) or limit < 0 or limit > bufferLen(packed) * 8 or count > floor(limit / 8) then error("NanoNum: invalid packed count/limit") end
	local result = tableCreate(count)
	local offset: number = 0
	for i = 1, count do
		local nextBit = recordEndChecked(packed, offset, limit)
		if nextBit == nil then error("NanoNum: invalid packed stream") end
		local bits = nextBit - offset
		local out: buffer = bufferCreate(ceilBytes(bits))
		copyBits(out, 0, packed, offset, bits)
		result[i] = out
		offset = nextBit
	end
	-- An explicitly supplied bit count describes the entire encoded message,
	-- not a prefix. Reject a wrong item count instead of silently dropping data.
	if totalBits ~= nil and offset ~= limit then error("NanoNum: packed count and bit length disagree") end
	return result
end
function NanoNum.tryUnpackMany(packed: buffer, count: number, totalBits: number?): (boolean, {buffer}?)
	if typeof(packed) ~= "buffer" or typeof(count) ~= "number" or count < 0 or count ~= floor(count) then return false, nil end
	local limit = totalBits or bufferLen(packed) * 8
	if typeof(limit) ~= "number" or limit ~= limit or limit ~= floor(limit) or limit < 0 or limit > bufferLen(packed) * 8 or count > floor(limit / 8) then return false, nil end
	local ok, result = fastPcall(NanoNum.unpackMany, packed, count, limit)
	if not ok then return false, nil end
	return true, result
end
function NanoNum.inspect(value: buffer): InspectInfo
	local data, bits = decodeAt(value, 0)
	return {Version = NanoNum.VERSION, Bits = bits, Bytes = bufferLen(value), PaddingBits = bufferLen(value) * 8 - bits, Data = data}
end
-- Leaderboard codec -----------------------------------------------------------
--
-- LB is intentionally separate from NanoNum's compact buffer serialization.
-- The buffer codec minimizes bytes; LB maps a value to a monotonic, signed,
-- 53-bit-safe integer that can be used as an OrderedDataStore / ranking key.
--
-- This is NanoNum's own codec generation. It is not wire-compatible with
-- StrongNum LB7/LB8 even though it follows the same safe-integer envelope.
NanoNum.LB_SCOPE_VERSION = 3
-- LB internals live in their own function frame so their constants/helpers
-- cannot consume the module chunk's 200-local Luau register budget.
-- A plain `do ... end` block is not sufficient because it shares the same
-- function register frame; this IIFE creates an actual register boundary.
(function()
	local function installLB(LB_VERSION: number)
		local LB_APPROX_BITS: number = 31
		local LB_MANT_MAX: number = 65535
		local LB_MAX: number = 9007199254740991
		local LB_FINITE_MAX = LB_MAX - 1
		local LB_ONE: number = 4503599627370496
		local LB_POSITIVE_SPAN: number = min(LB_ONE - 1, LB_FINITE_MAX - LB_ONE)
		NanoNum.LB_VERSION = LB_VERSION
		NanoNum.LB_MAX = LB_MAX
		NanoNum.LB_FINITE_MAX = LB_FINITE_MAX
		NanoNum.LB_ONE = LB_ONE
		NanoNum.LB_POSITIVE_SPAN = LB_POSITIVE_SPAN
		NanoNum.LB_ORDINARY_EXACT_MAX = 10000000000000
		NanoNum.LB_ORDINARY_SUBSLOTS = 16
		NanoNum.LB_ORDINARY_LOG_SHARE = 0.05
		NanoNum.LB_HUGE_LOG_SHARE = 0.15
		NanoNum.LB_LOW_LAYER_MAX = 1000000000000
		NanoNum.LB_LAYER_TOP_BUCKETS = 256
		NanoNum.LB_HIGH_LAYER_SHARE = 0.25
		local LB_ORDINARY_EXACT_LOG10: number = log10(NanoNum.LB_ORDINARY_EXACT_MAX)
		local LB_ORDINARY_EXACT_SPAN: number = floor((NanoNum.LB_ORDINARY_EXACT_MAX - 1) * NanoNum.LB_ORDINARY_SUBSLOTS)
		local LB_ORDINARY_LOG_SPAN: number = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_ORDINARY_LOG_SHARE))
		local LB_HUGE_LOG_SPAN: number = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_HUGE_LOG_SHARE))
		local LB_LOW_LAYER_COUNT = NanoNum.LB_LOW_LAYER_MAX - 1
		local LB_LOW_LAYER_SPAN = LB_LOW_LAYER_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS
		local LB_HIGH_LAYER_RESERVED_SPAN: number = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_HIGH_LAYER_SHARE))
		local LB_HIGH_LAYER_BUCKET_COUNT: number = max(1, floor(LB_HIGH_LAYER_RESERVED_SPAN / NanoNum.LB_LAYER_TOP_BUCKETS))
		local LB_HIGH_LAYER_SPAN = LB_HIGH_LAYER_BUCKET_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS
		local LB_ORDINARY_EXACT_END = LB_ORDINARY_EXACT_SPAN
		local LB_ORDINARY_LOG_START = LB_ORDINARY_EXACT_END + 1
		local LB_ORDINARY_LOG_END = LB_ORDINARY_LOG_START + LB_ORDINARY_LOG_SPAN - 1
		local LB_HUGE_LOG_START = LB_ORDINARY_LOG_END + 1
		local LB_HUGE_LOG_END = LB_HUGE_LOG_START + LB_HUGE_LOG_SPAN - 1
		local LB_LOW_LAYER_START = LB_HUGE_LOG_END + 1
		local LB_LOW_LAYER_END = LB_LOW_LAYER_START + LB_LOW_LAYER_SPAN - 1
		local LB_HIGH_LAYER_START = LB_LOW_LAYER_END + 1
		local LB_HIGH_LAYER_END = LB_HIGH_LAYER_START + LB_HIGH_LAYER_SPAN - 1
		local LB_LOG_LAYER_START = LB_HIGH_LAYER_END + 1
		local LB_LAYER_REMAINDER: number = max(2 * NanoNum.LB_LAYER_TOP_BUCKETS, NanoNum.LB_POSITIVE_SPAN - LB_LOG_LAYER_START + 1)
		local LB_HYPER_RESERVED: number = max(NanoNum.LB_LAYER_TOP_BUCKETS, floor(LB_LAYER_REMAINDER * 0.25))
		local LB_LOG_LAYER_SPAN: number = max(NanoNum.LB_LAYER_TOP_BUCKETS, LB_LAYER_REMAINDER - LB_HYPER_RESERVED)
		local LB_LOG_LAYER_BUCKET_COUNT: number = max(1, floor(LB_LOG_LAYER_SPAN / NanoNum.LB_LAYER_TOP_BUCKETS))
		local LB_LOG_LAYER_USED_SPAN = LB_LOG_LAYER_BUCKET_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS
		local LB_LOG_LAYER_END = LB_LOG_LAYER_START + LB_LOG_LAYER_USED_SPAN - 1
		local LB_HYPER_LAYER_START = LB_LOG_LAYER_END + 1
		local LB_HYPER_LAYER_SPAN: number = max(NanoNum.LB_LAYER_TOP_BUCKETS, NanoNum.LB_POSITIVE_SPAN - LB_HYPER_LAYER_START + 1)
		local LB_HYPER_LAYER_BUCKET_COUNT: number = max(1, floor(LB_HYPER_LAYER_SPAN / NanoNum.LB_LAYER_TOP_BUCKETS))
		local LB_HYPER_LAYER_USED_SPAN = LB_HYPER_LAYER_BUCKET_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS
		local LB_HYPER_LAYER_END = LB_HYPER_LAYER_START + LB_HYPER_LAYER_USED_SPAN - 1
		local LB_ORDINARY_LOG_MIN = LB_ORDINARY_EXACT_LOG10 + (LB_VERSION == 2 and 1 or 0)
		local LB_ORDINARY_LOG_DENOM = 308 - LB_ORDINARY_LOG_MIN
		local LB_HUGE_LOG_MIN = LB_VERSION == 2 and 309 or 308
		local LB_HUGE_LOG_DENOM: number = log10(1e308 / LB_HUGE_LOG_MIN)
		local LB_HIGH_LAYER_LOG_MIN: number = log10(NanoNum.LB_LOW_LAYER_MAX) + (LB_VERSION == 2 and 1 or 0)
		local LB_HIGH_LAYER_LOG_DENOM = 308 - LB_HIGH_LAYER_LOG_MIN
		local LB_LOG_LAYER_MIN = LB_VERSION == 2 and 309 or 308
		local LB_LOG_LAYER_DENOM: number = log10(1e308 / LB_LOG_LAYER_MIN)
		local LB_HYPER_LAYER_MIN = LB_VERSION == 2 and 309 or 308
		local LB_HYPER_LAYER_DENOM: number = log10(1e308 / LB_HYPER_LAYER_MIN)
		local LB_TOP_LOG_DENOM: number = 308
		local LB_DIRECT_TOP_MIN = LB_VERSION == 2 and 309 or DIRECT_LOG_MAX
		local LB_DIRECT_TOP_LOG_MIN: number = log10(LB_DIRECT_TOP_MIN)
		local LB_DIRECT_TOP_LOG_DENOM = 308 - LB_DIRECT_TOP_LOG_MIN
		local function lbClampUnit(value: number): number
			if value < 0 then
				return 0
			elseif value > 1 then
				return 1
			end
			return value
		end
		local function lbQuantizeUnit(unit: number, slots: number): number
			if slots <= 1 then
				return 0
			end
			return clamp(floor(lbClampUnit(unit) * (slots - 1) + (LB_VERSION == 2 and 0.001 or 0.5)), 0, slots - 1)
		end
		local function lbUnitFromSlot(slot: number, slots: number): number
			if slots <= 1 then
				return 0
			end
			return clamp(slot, 0, slots - 1) / (slots - 1)
		end
		local function lbDirectTopBucket(top: number): number
			if top <= LB_DIRECT_TOP_MIN then
				return 0
			end
			local unit = (log10(min(top, 1e308)) - LB_DIRECT_TOP_LOG_MIN) / LB_DIRECT_TOP_LOG_DENOM
			return lbQuantizeUnit(unit, NanoNum.LB_LAYER_TOP_BUCKETS)
		end
		local function lbDirectTopFromBucket(bucket: number): number
			local unit = lbUnitFromSlot(bucket, NanoNum.LB_LAYER_TOP_BUCKETS)
			if unit >= 1 then
				return 1e308
			end
			local top = 10 ^ (LB_DIRECT_TOP_LOG_MIN + unit * LB_DIRECT_TOP_LOG_DENOM)
			return LB_VERSION == 3 and max(top, 308.2547155599168) or top
		end
		local function lbLogLayerTopBucket(top: number): number
			if top <= 0 then
				return 0
			end
			local unit = log10(1 + min(top, 1e308)) / LB_TOP_LOG_DENOM
			return lbQuantizeUnit(unit, NanoNum.LB_LAYER_TOP_BUCKETS)
		end
		local function lbLogLayerTopFromBucket(bucket: number): number
			local unit = lbUnitFromSlot(bucket, NanoNum.LB_LAYER_TOP_BUCKETS)
			if unit >= 1 then
				return 1e308
			end
			return (10 ^ (unit * LB_TOP_LOG_DENOM)) - 1
		end
		local function lbCoerce(value: any): buffer
			local t = typeof(value)
			if t == "buffer" then
				return value
			elseif t == "number" then
				return NanoNum.fromNumber(value)
			elseif t == "string" then
				return NanoNum.fromString(value)
			end
			return makeSpecial(SPECIAL_NAN)
		end
		local function lbDescriptor(encodedValue: buffer)
			local data = decodeAt(encodedValue, 0)
			if data.Kind == "NaN" or data.Kind == "Reserved" then
				return {Kind = "NaN"}
			end
			if data.Kind == "Infinity" then
				return {Kind = "Infinity", Negative = data.Negative}
			end
			if data.Kind == "Integer" then
				if data.Value == 0 then
					return {Kind = "Zero", Negative = false}
				end
				local magnitude: number = abs(data.Value)
				local logMagnitude
				if exactIntegerRecordBits(data.Value) <= LB_APPROX_BITS then
					logMagnitude = log10(magnitude)
				else
					local lg: number = log10(magnitude)
					local exponent: number = floor(lg)
					local mantissa = 10 ^ (lg - exponent)
					local mantCode = quantizeMantissa(mantissa, LB_MANT_MAX)
					logMagnitude = exponent + log10(decodeMantissa(mantCode, LB_MANT_MAX))
				end
				return {
					Kind = "Magnitude",
					Negative = data.Value < 0,
					Reciprocal = false,
					Layer = 0,
					LogScale = logMagnitude,
				}
			end
			if data.Kind == "Exact" then
				local value = data.Value
				if value == 0 then return {Kind = "Zero", Negative = false} end
				local magnitude: number = abs(value)
				local lg: number = log10(magnitude)
				local exponent: number = floor(lg)
				local mantissa = 10 ^ (lg - exponent)
				local mantCode = quantizeMantissa(mantissa, LB_MANT_MAX)
				local legacyLog = exponent + log10(decodeMantissa(mantCode, LB_MANT_MAX))
				return {Kind = "Magnitude", Negative = value < 0, Reciprocal = legacyLog < 0, Layer = 0, LogScale = abs(legacyLog)}
			end
			if data.Kind == "Log" then
				return {
					Kind = "Magnitude",
					Negative = data.Negative,
					Reciprocal = data.Reciprocal,
					Layer = 1,
					LogScale = data.Top,
				}
			end
			if data.LayerIsHyper then
				local layerLog10Log10 = data.LayerLog10Log10
				if layerLog10Log10 == nil then return {Kind = "NaN"} end
				return {
					Kind = "Layer",
					Negative = data.Negative,
					Reciprocal = data.Reciprocal,
					LayerLog10Log10 = layerLog10Log10,
					LayerIsHyper = true,
					LayerIsLog = false,
					Top = data.Top,
				}
			end
			if data.LayerIsLog then
				local layerLog10 = data.LayerLog10
				if layerLog10 == nil then
					return {Kind = "NaN"}
				end
				return {
					Kind = "Layer",
					Negative = data.Negative,
					Reciprocal = data.Reciprocal,
					LayerLog10 = layerLog10,
					LayerIsLog = true,
					Top = data.Top,
				}
			end
			local layer, top = normalizeLayerInput(data.Layer, data.Top, false)
			if layer < 2 then
				return {
					Kind = "Magnitude",
					Negative = data.Negative,
					Reciprocal = data.Reciprocal,
					Layer = 1,
					LogScale = top,
				}
			end
			return {
				Kind = "Layer",
				Negative = data.Negative,
				Reciprocal = data.Reciprocal,
				Layer = layer,
				LayerIsLog = false,
				Top = top,
			}
		end
		local function lbEncodeOrdinaryLog(logScale: number): number
			if logScale <= LB_ORDINARY_EXACT_LOG10 then
				local magnitude = 10 ^ logScale
				local slot: number = floor((magnitude - 1) * NanoNum.LB_ORDINARY_SUBSLOTS + (LB_VERSION == 2 and 0.001 or 0.5))
				return clamp(slot, 0, LB_ORDINARY_EXACT_END)
			end
			if logScale <= 308 then
				local unit = (logScale - LB_ORDINARY_LOG_MIN) / LB_ORDINARY_LOG_DENOM
				return LB_ORDINARY_LOG_START + lbQuantizeUnit(unit, LB_ORDINARY_LOG_SPAN)
			end
			local capped: number = min(logScale, 1e308)
			local unit = log10(capped / LB_HUGE_LOG_MIN) / LB_HUGE_LOG_DENOM
			return LB_HUGE_LOG_START + lbQuantizeUnit(unit, LB_HUGE_LOG_SPAN)
		end
		local function lbEncodeLayer(layer: number, top: number): number
			if layer <= NanoNum.LB_LOW_LAYER_MAX then
				local layerIndex: number = max(0, floor(layer + 0.001) - 2)
				local topBucket = lbDirectTopBucket(top)
				return LB_LOW_LAYER_START + layerIndex * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
			end
			local unit = (log10(min(layer, 1e308)) - LB_HIGH_LAYER_LOG_MIN) / LB_HIGH_LAYER_LOG_DENOM
			local layerSlot = lbQuantizeUnit(unit, LB_HIGH_LAYER_BUCKET_COUNT)
			local topBucket = LB_VERSION == 2 and lbDirectTopBucket(top) or 0
			return LB_HIGH_LAYER_START + layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
		end
		local function lbEncodeLogLayer(layerLog10: number, top: number): number
			local capped: number = min(max(layerLog10, LB_LOG_LAYER_MIN), 1e308)
			local unit = log10(capped / LB_LOG_LAYER_MIN) / LB_LOG_LAYER_DENOM
			local layerSlot = lbQuantizeUnit(unit, LB_LOG_LAYER_BUCKET_COUNT)
			local topBucket = LB_VERSION == 2 and lbLogLayerTopBucket(top) or 0
			return LB_LOG_LAYER_START + layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
		end
		local function lbEncodeHyperLayer(layerLog10Log10: number, top: number): number
			local capped: number = min(max(layerLog10Log10, LB_HYPER_LAYER_MIN), 1e308)
			local unit = log10(capped / LB_HYPER_LAYER_MIN) / LB_HYPER_LAYER_DENOM
			local layerSlot = lbQuantizeUnit(unit, LB_HYPER_LAYER_BUCKET_COUNT)
			local topBucket = LB_VERSION == 2 and lbLogLayerTopBucket(top) or 0
			return LB_HYPER_LAYER_START + layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
		end
		local function lbPositiveDeltaDescriptor(descriptor): (number?, boolean?, boolean?)
			if descriptor.Kind == "NaN" then
				return nil, nil, nil
			end
			if descriptor.Kind == "Zero" then
				return 0, false, false
			end
			if descriptor.Kind == "Infinity" then
				return LB_POSITIVE_SPAN + 1, descriptor.Negative, false
			end
			local delta
			if descriptor.Kind == "Magnitude" then
				delta = lbEncodeOrdinaryLog(descriptor.LogScale)
			elseif descriptor.LayerIsHyper then
				delta = lbEncodeHyperLayer(descriptor.LayerLog10Log10, descriptor.Top)
			elseif descriptor.LayerIsLog then
				delta = lbEncodeLogLayer(descriptor.LayerLog10, descriptor.Top)
			else
				delta = lbEncodeLayer(descriptor.Layer, descriptor.Top)
			end
			if delta < 0 then
				delta = 0
			elseif delta > LB_POSITIVE_SPAN then
				delta = LB_POSITIVE_SPAN
			end
			return floor(delta), descriptor.Negative, descriptor.Reciprocal
		end
		local function lbFinalizeFiniteCode(delta: number, negative: boolean, reciprocal: boolean): number
			if delta <= 0 then
				return negative and -LB_ONE or LB_ONE
			end
			if delta > LB_POSITIVE_SPAN then
				return negative and -LB_MAX or LB_MAX
			end
			local positiveCode = reciprocal and (LB_ONE - delta) or (LB_ONE + delta)
			if positiveCode < 1 then
				positiveCode = 1
			elseif positiveCode > LB_FINITE_MAX then
				positiveCode = LB_FINITE_MAX
			end
			positiveCode = floor(positiveCode)
			return negative and -positiveCode or positiveCode
		end
		local function lbCodeFromDescriptor(descriptor): number
			local delta, negative, reciprocal = lbPositiveDeltaDescriptor(descriptor)
			if delta == nil then
				return 0
			end
			if descriptor.Kind == "Zero" then
				return 0
			end
			return lbFinalizeFiniteCode(delta, negative == true, reciprocal == true)
		end
		local function lbCodeFromBufferFast(value: buffer): (number, boolean)
			if LB_VERSION == 3 then
				local finite = directFiniteNumber(value)
				if finite ~= nil then
					if finite == 0 then return 0, true end
					local magnitude: number = abs(finite)
					local reciprocal = magnitude < 1
					local distance = reciprocal and 1 / magnitude or magnitude
					local delta
					if distance <= NanoNum.LB_ORDINARY_EXACT_MAX then
						delta = math.round((distance - 1) * NanoNum.LB_ORDINARY_SUBSLOTS)
					else
						delta = lbEncodeOrdinaryLog(abs(log10(magnitude)))
					end
					return lbFinalizeFiniteCode(delta, finite < 0, reciprocal), true
				end
			end
			-- Direct prefix dispatch avoids allocating the Reader table and decoded-data
			-- table used by the public decodeAt()/components() API.
			local raw: number = bufferReadBits(value, 0, 6)
			if band(raw, 1) == 0 then
				local integer: number = bufferReadBits(value, 1, 7)
				if integer == 0 then
					return 0, true
				end
				local delta = lbEncodeOrdinaryLog(log10(integer))
				return lbFinalizeFiniteCode(delta, false, false), true
			end
			if band(raw, 3) == 1 then
				local magnitude = bufferReadBits(value, 2, 6) + 1
				local delta = lbEncodeOrdinaryLog(log10(magnitude))
				return lbFinalizeFiniteCode(delta, true, false), true
			end
			if band(raw, 7) == 3 then
				local negative = bufferReadBits(value, 3, 1) == 1
				local n: number = bufferReadBits(value, 4, INTEGER_LEN_BITS)
				local payloadOffset = 4 + INTEGER_LEN_BITS
				if n == 0 then
					n = 32 + bufferReadBits(value, payloadOffset, 5)
					payloadOffset += 5
					if n > MAX_INTEGER_MODE_BITS then
						error("NanoNum: invalid extended integer bit length")
					end
				end
				local magnitude = readUIntExactAtFast(value, payloadOffset, n)
				if magnitude == 0 then return 0, true end
				local logMagnitude
				local signed = negative and -magnitude or magnitude
				if exactIntegerRecordBits(signed) <= LB_APPROX_BITS then
					logMagnitude = log10(magnitude)
				else
					local lg: number = log10(magnitude)
					local exponent: number = floor(lg)
					local mantissa = 10 ^ (lg - exponent)
					local mantCode = quantizeMantissa(mantissa, LB_MANT_MAX)
					logMagnitude = exponent + log10(decodeMantissa(mantCode, LB_MANT_MAX))
				end
				local delta = lbEncodeOrdinaryLog(logMagnitude)
				return lbFinalizeFiniteCode(delta, negative, false), true
			end
			local firstByte: number = bufferReadU8(value, 0)
			if band(firstByte, 31) == HYPER_LAYER_PREFIX and band(firstByte, 128) == 0 then
				local negative = band(firstByte, 32) ~= 0
				local reciprocal = band(firstByte, 64) ~= 0
				local hyper, nextBit = readScalarAtFast(value, 8)
				local top = readScalarAtFast(value, nextBit)
				local delta = lbEncodeHyperLayer(hyper, top)
				return lbFinalizeFiniteCode(delta, negative, reciprocal), true
			end
			if band(raw, 15) == 7 then return 0, false end
			if band(raw, 31) == 15 then
				local negative = bufferReadBits(value, 5, 1) == 1
				local reciprocal = bufferReadBits(value, 6, 1) == 1
				local top
				if isExactLogAt(value, 0) then top = readExactLogMagnitudeAt(value, 0)
				else top = readScalarAtFast(value, 7) end
				local delta = lbEncodeOrdinaryLog(top)
				return lbFinalizeFiniteCode(delta, negative, reciprocal), true
			end
			if band(raw, 63) == 31 then
				local negative = bufferReadBits(value, 6, 1) == 1
				local reciprocal = bufferReadBits(value, 7, 1) == 1
				local layer, layerIsLog, nextBit = readLayerFieldAtFast(value, 8)
				local top = readScalarAtFast(value, nextBit)
				if layerIsLog then
					if layer <= 308 then
						layer, top = normalizeLayerInput(10 ^ layer, top, false)
						if layer < 2 then
							local delta = lbEncodeOrdinaryLog(top)
							return lbFinalizeFiniteCode(delta, negative, reciprocal), true
						end
						local delta = lbEncodeLayer(layer, top)
						return lbFinalizeFiniteCode(delta, negative, reciprocal), true
					end
					local delta = lbEncodeLogLayer(layer, top)
					return lbFinalizeFiniteCode(delta, negative, reciprocal), true
				end
				layer, top = normalizeLayerInput(layer, top, false)
				if layer < 2 then
					local delta = lbEncodeOrdinaryLog(top)
					return lbFinalizeFiniteCode(delta, negative, reciprocal), true
				end
				local delta = lbEncodeLayer(layer, top)
				return lbFinalizeFiniteCode(delta, negative, reciprocal), true
			end
			local special: number = bufferReadBits(value, 6, 2)
			if special == SPECIAL_RESERVED then
				local exact: number = bufferReadF64(value, 1)
				if exact ~= exact or exact == huge or exact == -huge then return 0, false end
				if exact == 0 then return 0, true end
				local negative = exact < 0
				local magnitude = negative and -exact or exact
				local lg: number = log10(magnitude)
				local exponent: number = floor(lg)
				local mantissa = 10 ^ (lg - exponent)
				local mantCode = quantizeMantissa(mantissa, LB_MANT_MAX)
				local legacyLog = exponent + log10(decodeMantissa(mantCode, LB_MANT_MAX))
				local reciprocal = legacyLog < 0
				local delta = lbEncodeOrdinaryLog(abs(legacyLog))
				return lbFinalizeFiniteCode(delta, negative, reciprocal), true
			end
			if special == SPECIAL_POS_INF then
				return LB_MAX, true
			elseif special == SPECIAL_NEG_INF then
				return -LB_MAX, true
			end
			return 0, false
		end
		local function isLBCodeFast(encoded: number): boolean
			-- Order the guards so NaN/Inf/out-of-range values return before floor().
			if encoded ~= encoded or encoded > LB_MAX or encoded < -LB_MAX then
				return false
			end
			if encoded ~= floor(encoded) then
				return false
			end
			local code = encoded < 0 and -encoded or encoded
			if code == 0 or code == LB_MAX then
				return true
			end
			if code > LB_FINITE_MAX then
				return false
			end
			local delta = code - LB_ONE
			if delta < 0 then
				delta = -delta
			end
			return delta <= LB_HYPER_LAYER_END
		end
		NanoNum.isLBCode = isLBCodeFast
		function NanoNum.tryLBEncode(value: any): (boolean, number)
			local kind = typeof(value)
			if kind ~= "buffer" and kind ~= "number" and kind ~= "string" then return false, 0 end
			if kind == "buffer" and not NanoNum.isValid(value) then return false, 0 end
			-- Both coercion and encoding are guarded; a malformed input never throws.
			local coerceOK, coerced = fastPcall(lbCoerce, value)
			if not coerceOK then return false, 0 end
			local ok, code, valid = fastPcall(lbCodeFromBufferFast, coerced)
			if not ok or not valid then return false, 0 end
			return true, code
		end
		function NanoNum.lbencode(value: MathValue): number
			if typeof(value) == "buffer" then
				local code = lbCodeFromBufferFast(value)
				return code
			end
			local code = lbCodeFromBufferFast(lbCoerce(value))
			return code
		end
		local function lbDecodePositiveDelta(delta: number): (number, number, number)
			delta = clamp(floor(delta), 1, NanoNum.LB_POSITIVE_SPAN)
			if delta <= LB_ORDINARY_EXACT_END then
				local magnitude = 1 + delta / NanoNum.LB_ORDINARY_SUBSLOTS
				return 0, log10(magnitude), 0
			end
			if delta <= LB_ORDINARY_LOG_END then
				local slot = delta - LB_ORDINARY_LOG_START
				local unit = lbUnitFromSlot(slot, LB_ORDINARY_LOG_SPAN)
				return 0, LB_ORDINARY_LOG_MIN + unit * LB_ORDINARY_LOG_DENOM, 0
			end
			if delta <= LB_HUGE_LOG_END then
				local slot = delta - LB_HUGE_LOG_START
				local unit = lbUnitFromSlot(slot, LB_HUGE_LOG_SPAN)
				local logScale = LB_HUGE_LOG_MIN * (10 ^ (unit * LB_HUGE_LOG_DENOM))
				if LB_VERSION == 3 and logScale <= 308 then logScale = 308.00000000000006 end
				if logScale > 1e308 then
					logScale = 1e308
				end
				return 0, logScale, 0
			end
			if delta <= LB_LOW_LAYER_END then
				local offset = delta - LB_LOW_LAYER_START
				local layerIndex: number = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
				local topBucket = offset - layerIndex * NanoNum.LB_LAYER_TOP_BUCKETS
				return 1, layerIndex + 2, lbDirectTopFromBucket(topBucket)
			end
			if delta <= LB_HIGH_LAYER_END then
				local offset = delta - LB_HIGH_LAYER_START
				local layerSlot: number = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
				local topBucket = offset - layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS
				local unit = lbUnitFromSlot(layerSlot, LB_HIGH_LAYER_BUCKET_COUNT)
				local layerLog10 = LB_HIGH_LAYER_LOG_MIN + unit * LB_HIGH_LAYER_LOG_DENOM
				local layer = 10 ^ layerLog10
				if LB_VERSION == 3 and layer <= NanoNum.LB_LOW_LAYER_MAX then layer = NanoNum.LB_LOW_LAYER_MAX + 1 end
				if layer > 1e308 then
					layer = 1e308
				end
				return 1, layer, lbDirectTopFromBucket(topBucket)
			end
			if delta <= LB_LOG_LAYER_END then
				local offset: number = clamp(delta - LB_LOG_LAYER_START, 0, LB_LOG_LAYER_USED_SPAN - 1)
				local layerSlot: number = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
				local topBucket = offset - layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS
				local unit = lbUnitFromSlot(layerSlot, LB_LOG_LAYER_BUCKET_COUNT)
				local layerLog10 = LB_LOG_LAYER_MIN * (10 ^ (unit * LB_LOG_LAYER_DENOM))
				if layerLog10 > 1e308 then layerLog10 = 1e308 end
				if LB_VERSION == 3 and layerLog10 <= 308 then layerLog10 = 308.00000000000006 end
				return 2, layerLog10, lbLogLayerTopFromBucket(topBucket)
			end
			local offset: number = clamp(delta - LB_HYPER_LAYER_START, 0, LB_HYPER_LAYER_USED_SPAN - 1)
			local layerSlot: number = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
			local topBucket = offset - layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS
			local unit = lbUnitFromSlot(layerSlot, LB_HYPER_LAYER_BUCKET_COUNT)
			local hyper = LB_HYPER_LAYER_MIN * (10 ^ (unit * LB_HYPER_LAYER_DENOM))
			if hyper > 1e308 then hyper = 1e308 end
			if LB_VERSION == 3 and hyper <= 308 then hyper = 308.00000000000006 end
			return 3, hyper, lbLogLayerTopFromBucket(topBucket)
		end
		function NanoNum.lbdecode(encoded: number): buffer
			if not isLBCodeFast(encoded) then
				return makeSpecial(SPECIAL_NAN)
			end
			if encoded == 0 then
				return NanoNum.fromNumber(0)
			end
			if encoded == LB_MAX then
				return makeSpecial(SPECIAL_POS_INF)
			end
			if encoded == -LB_MAX then
				return makeSpecial(SPECIAL_NEG_INF)
			end
			local negative = encoded < 0
			local code = negative and -encoded or encoded
			if code == LB_ONE then
				return NanoNum.fromNumber(negative and -1 or 1)
			end
			local reciprocal = code < LB_ONE
			local delta = reciprocal and (LB_ONE - code) or (code - LB_ONE)
			if LB_VERSION == 3 and delta <= LB_ORDINARY_EXACT_END then
				local magnitude = 1 + delta / NanoNum.LB_ORDINARY_SUBSLOTS
				if reciprocal then magnitude = 1 / magnitude end
				return NanoNum.fromNumber(negative and -magnitude or magnitude)
			end
			local decodedKind, decodedA, decodedB = lbDecodePositiveDelta(delta)
			if decodedKind == 0 then
				-- Stay in the ordinary buffer mode whenever the reconstructed value fits
				-- in a Luau number. This preserves more NanoNum precision than routing
				-- every LB ordinary bucket through the layer-1 scalar codec.
				if decodedA <= 308 then
					local magnitude = 10 ^ decodedA
					if reciprocal then
						magnitude = 1 / magnitude
					end
					if negative then
						magnitude = -magnitude
					end
					return NanoNum.fromNumber(magnitude)
				end
				local exponent = reciprocal and -decodedA or decodedA
				return NanoNum.fromLog10(exponent, negative)
			end
			if decodedKind == 3 then return NanoNum.fromLayerLog10Log10(decodedA, decodedB, negative, reciprocal) end
			if decodedKind == 2 then return NanoNum.fromLayerLog10(decodedA, decodedB, negative, reciprocal) end
			return NanoNum.fromLayer(decodedA, decodedB, negative, reciprocal)
		end
		function NanoNum.lbcodecVersion(): number
			return LB_VERSION
		end
		local function lbBandFromDelta(delta: number): string
			if delta == 0 then
				return "one"
			elseif delta <= LB_ORDINARY_EXACT_END then
				return "ordinary-exact"
			elseif delta <= LB_ORDINARY_LOG_END then
				return "ordinary-log"
			elseif delta <= LB_HUGE_LOG_END then
				return "huge-log"
			elseif delta <= LB_LOW_LAYER_END then
				return "low-layer-exact"
			elseif delta <= LB_HIGH_LAYER_END then
				return "high-layer"
			elseif delta <= LB_LOG_LAYER_END then
				return "log-layer"
			end
			return "hyper-layer"
		end
		function NanoNum.lbinfo(value: MathValue): LBInfo
			local v = if typeof(value) == "buffer" then value else lbCoerce(value)
			if LB_VERSION == 3 then
				local code, valid = lbCodeFromBufferFast(v)
				local delta: number = abs(abs(code) - LB_ONE)
				return {version=LB_VERSION, code=code, band=not valid and "nan" or (code==0 and "zero" or (abs(code)==LB_MAX and "infinity" or lbBandFromDelta(delta))), negative=code<0, reciprocal=code~=0 and abs(code)<LB_ONE, distanceFromOne=delta}
			end
			local descriptor = lbDescriptor(v)
			if descriptor.Kind == "NaN" then
				return {
					version = LB_VERSION,
					code = 0,
					band = "nan",
					negative = false,
					reciprocal = false,
					distanceFromOne = 0,
				}
			end
			if descriptor.Kind == "Zero" then
				return {
					version = LB_VERSION,
					code = 0,
					band = "zero",
					negative = false,
					reciprocal = false,
					distanceFromOne = NanoNum.LB_ONE,
				}
			end
			if descriptor.Kind == "Infinity" then
				local code = descriptor.Negative and -NanoNum.LB_MAX or NanoNum.LB_MAX
				return {
					version = LB_VERSION,
					code = code,
					band = "infinity",
					negative = descriptor.Negative,
					reciprocal = false,
					distanceFromOne = LB_POSITIVE_SPAN,
				}
			end
			local code = lbCodeFromDescriptor(descriptor)
			local absCode: number = abs(code)
			local delta: number = abs(absCode - LB_ONE)
			return {
				version = LB_VERSION,
				code = code,
				band = lbBandFromDelta(delta),
				negative = descriptor.Negative,
				reciprocal = descriptor.Reciprocal,
				distanceFromOne = delta,
			}
		end
		function NanoNum.lbquantize(value: MathValue): buffer
			local code
			if typeof(value) == "buffer" then
				code = lbCodeFromBufferFast(value)
			else
				code = lbCodeFromBufferFast(lbCoerce(value))
			end
			if NanoNum.isNaN(value) then return makeSpecial(SPECIAL_NAN) end
			return NanoNum.lbdecode(code)
		end
		function NanoNum.lbSameBucket(a: MathValue, b: MathValue): boolean
			local ca
			local cb
			if typeof(a) == "buffer" then
				ca = lbCodeFromBufferFast(a)
			else
				ca = lbCodeFromBufferFast(lbCoerce(a))
			end
			if typeof(b) == "buffer" then
				cb = lbCodeFromBufferFast(b)
			else
				cb = lbCodeFromBufferFast(lbCoerce(b))
			end
			return not NanoNum.isNaN(a) and not NanoNum.isNaN(b) and ca == cb
		end
		function NanoNum.lbRoundTripStable(value: MathValue): boolean
			local code, valid
			if typeof(value) == "buffer" then
				code, valid = lbCodeFromBufferFast(value)
			else
				code, valid = lbCodeFromBufferFast(lbCoerce(value))
			end
			if not valid then
				return false
			end
			local decoded = NanoNum.lbdecode(code)
			local roundTrip = lbCodeFromBufferFast(decoded)
			return roundTrip == code
		end
		function NanoNum.lbCompare(a: MathValue, b: MathValue): number
			local ca, validA
			local cb, validB
			if typeof(a) == "buffer" then
				ca, validA = lbCodeFromBufferFast(a)
			else
				ca, validA = lbCodeFromBufferFast(lbCoerce(a))
			end
			if typeof(b) == "buffer" then
				cb, validB = lbCodeFromBufferFast(b)
			else
				cb, validB = lbCodeFromBufferFast(lbCoerce(b))
			end
			if not validA or not validB then
				return 0 / 0
			end
			if ca < cb then
				return -1
			elseif ca > cb then
				return 1
			end
			return 0
		end
	end
	installLB(2)
	local decodeV2 = NanoNum.lbdecode
	local encodeV2 = NanoNum.lbencode
	installLB(3)
	NanoNum.lbdecodeV2 = decodeV2
	NanoNum.lbencodeV2 = encodeV2
end)()
local TYPECHECKED_NANONUM = NanoNum;

-- NanoNum exact-decimal math v2.4.0: opt-in arbitrary exponent and coefficient arithmetic.
-- Binary format 6 is unchanged; LB3 has explicit LB2 migration functions. ExactDecimal is a
-- separate representation; lossy operations report Approximate=true explicitly.
(function()
	local B: (string, number?, number?) -> ...number = string.byte
	local S: (string, number, number?) -> string = string.sub
	local C: (...number) -> string = string.char
	local F: (number) -> number = math.floor
	local function trim(a: string): string
		local p: number = 1
		while p < #a and B(a,p) == 48 do p += 1 end
		return S(a,p)
	end
	local function magCmp(a: string,b: string): number
		if #a ~= #b then return #a > #b and 1 or -1 end
		if a == b then return 0 end
		return a > b and 1 or -1
	end
	local function magAdd(a: string,b: string): string
		local i,j,carry=#a,#b,0
		local width=math.max(i,j)+1
		local result=table.create(width)
		for p=width,1,-1 do
			local d=carry
			if i>0 then d+=B(a,i)-48;i-=1 end
			if j>0 then d+=B(b,j)-48;j-=1 end
			result[p]=C(48+d%10);carry=F(d/10)
		end
		return table.concat(result,"",result[1]=="0" and 2 or 1)
	end
	-- Requires a >= b.
	local function magSub(a: string,b: string): string
		local j,borrow=#b,0
		local result=table.create(#a)
		for i=#a,1,-1 do
			local d=B(a,i)-48-borrow
			if j>0 then d-=B(b,j)-48;j-=1 end
			borrow=d<0 and 1 or 0
			if borrow~=0 then d+=10 end
			result[i]=C(d+48)
		end
		local first=1
		while first<#result and result[first]=="0" do first+=1 end
		return table.concat(result,"",first)
	end
	local function unpackSigned(v: string): (number,string)
		local sign: number=1
		if S(v,1,1)=="-" then sign=-1;v=S(v,2)
		elseif S(v,1,1)=="+" then v=S(v,2) end
		if #v==0 then error("NanoNum: empty integer") end
		for i=1,#v do local d=B(v,i);if d<48 or d>57 then error("NanoNum: invalid decimal integer") end end
		v=trim(v)
		return v=="0" and 0 or sign,v
	end
	local function integerAdd(a: string,b: string): string
		local sa,ma=unpackSigned(a)
		local sb,mb=unpackSigned(b)
		if sa==0 then return sb<0 and "-"..mb or mb end
		if sb==0 then return sa<0 and "-"..ma or ma end
		if sa==sb then local d=magAdd(ma,mb);return sa<0 and "-"..d or d end
		local comparison=magCmp(ma,mb)
		if comparison==0 then return "0" end
		local d=comparison>0 and magSub(ma,mb) or magSub(mb,ma)
		local sign=comparison>0 and sa or sb
		return sign<0 and "-"..d or d
	end
	local function integerNeg(v: string): string
		local sign,mag=unpackSigned(v)
		return sign==0 and "0" or (sign<0 and mag or "-"..mag)
	end
	local function integerCompare(a: string,b: string): number
		local sa,ma=unpackSigned(a)
		local sb,mb=unpackSigned(b)
		if sa~=sb then return sa>sb and 1 or -1 end
		if sa==0 then return 0 end
		return magCmp(ma,mb)*sa
	end
	local function canonical(sign: number,digits: string,exponent: string,approximate: boolean?): ExactDecimal
		local nonzero=string.find(digits,"[1-9]")
		if nonzero==nil then return {Sign=0,Digits="0",Exponent="0",Approximate=approximate==true} end
		if nonzero>1 then exponent=integerAdd(exponent,"-"..tostring(nonzero-1));digits=S(digits,nonzero) end
		digits=string.gsub(digits,"0+$","")
		local es,em=unpackSigned(exponent)
		return {Sign=sign<0 and -1 or 1,Digits=digits,Exponent=es<0 and "-"..em or em,Approximate=approximate==true}
	end
	local function parse(text: string): ExactDecimal
		text = string.gsub(text, "^(%s*[%+%-]?)%.", "%10.")
		local sign,whole,fraction,exponent=string.match(text,"^%s*([%+%-]?)(%d+)%.?(%d*)[eE]([%+%-]?%d+)%s*$")
		if whole==nil then
			sign,whole,fraction=string.match(text,"^%s*([%+%-]?)(%d+)%.?(%d*)%s*$")
			exponent="0"
		end
		if whole==nil then error("NanoNum: invalid exact decimal string") end
		local digits=whole..fraction
		local first=string.find(digits,"[1-9]")
		if first==nil then return {Sign=0,Digits="0",Exponent="0",Approximate=false} end
		-- Normalized scientific exponent = supplied exponent + integer digits - first nonzero index.
		return canonical(sign=="-" and -1 or 1,S(digits,first),integerAdd(exponent,tostring(#whole-first)),false)
	end
	local function validate(v: ExactDecimal): ExactDecimal
		if type(v)~="table" or (v.Sign~=0 and v.Sign~=1 and v.Sign~=-1) or type(v.Digits)~="string" or type(v.Exponent)~="string" then
			error("NanoNum: expected ExactDecimal record")
		end
		unpackSigned(v.Exponent)
		for i=1,#v.Digits do local d=B(v.Digits,i);if d<48 or d>57 then error("NanoNum: invalid exact digits") end end
		if #v.Digits==0 then error("NanoNum: empty exact digits") end
		if v.Approximate~=nil and type(v.Approximate)~="boolean" then error("NanoNum: invalid approximation flag") end
		if v.Sign==0 and string.find(v.Digits,"[1-9]") then error("NanoNum: zero sign with nonzero coefficient") end
		return canonical(v.Sign,v.Digits,v.Exponent,v.Approximate)
	end
	local function formatExact(v: ExactDecimal,places: number?): string
		v=validate(v)
		if v.Sign==0 then return "0" end
		if places~=nil and (places~=places or places==math.huge or places==-math.huge) then error("NanoNum: invalid precision") end
		local decimals: number=clamp(F(places or 2),0,100)
		local need=decimals+1
		local chars: {number}={}
		for i=1,need do chars[i]=i<=#v.Digits and B(v.Digits,i)-48 or 0 end
		local exp=v.Exponent
		if #v.Digits>need and B(v.Digits,need+1)>=53 then
			local carry: number=1
			for i=need,1,-1 do
				local x=chars[i]+carry;chars[i]=x%10;carry=F(x/10)
				if carry==0 then break end
			end
			if carry==1 then exp=integerAdd(exp,"1");chars[1]=1;for i=2,need do chars[i]=0 end end
		end
		local digits={}
		for i=1,need do digits[i]=C(chars[i]+48) end
		local mantissa=digits[1]
		if decimals>0 then mantissa..="."..table.concat(digits,"",2) end
		return (v.Sign<0 and "-" or "")..mantissa.."e"..exp
	end
	local function multiplyDigits(a: string,b: string): string
		local values=table.create(#a+#b,0)
		for i=#a,1,-1 do
			local carry: number=0
			local da=B(a,i)-48
			for j=#b,1,-1 do
				local index=i+j
				local x=values[index]+da*(B(b,j)-48)+carry
				values[index]=x%10;carry=F(x/10)
			end
			values[i]+=carry
		end
		local result={}
		for i=1,#values do result[i]=C(values[i]+48) end
		return trim(table.concat(result))
	end
	local function mulExact(a: ExactDecimal,b: ExactDecimal): ExactDecimal
		a=validate(a);b=validate(b)
		if a.Sign==0 or b.Sign==0 then return canonical(0,"0","0",a.Approximate or b.Approximate) end
		local digits=multiplyDigits(a.Digits,b.Digits)
		local exponent=integerAdd(a.Exponent,b.Exponent)
		exponent=integerAdd(exponent,tostring(#digits-#a.Digits-#b.Digits+1))
		return canonical(a.Sign*b.Sign,digits,exponent,a.Approximate or b.Approximate)
	end
	local function compareExact(a: ExactDecimal,b: ExactDecimal): number
		a=validate(a);b=validate(b)
		if a.Sign~=b.Sign then return a.Sign>b.Sign and 1 or -1 end
		if a.Sign==0 then return 0 end
		local comparison=integerCompare(a.Exponent,b.Exponent)
		if comparison==0 then
			local width=math.max(#a.Digits,#b.Digits)
			for i=1,width do
				local ad=i<=#a.Digits and B(a.Digits,i) or 48
				local bd=i<=#b.Digits and B(b.Digits,i) or 48
				if ad~=bd then comparison=ad>bd and 1 or -1;break end
			end
		end
		return comparison*a.Sign
	end
	local MAX_SHIFT=100000 -- exact addition can require output proportional to exponent separation.
	local function integerAsLimitedNumber(v: string,limit: number): number?
		local s,m=unpackSigned(v)
		if #m>6 then return nil end
		local n=tonumber(m) :: number
		return n<=limit and n*s or nil
	end
	local function addExact(a: ExactDecimal,b: ExactDecimal): ExactDecimal
		a=validate(a);b=validate(b)
		if a.Sign==0 then b.Approximate=a.Approximate or b.Approximate;return b end
		if b.Sign==0 then a.Approximate=a.Approximate or b.Approximate;return a end
		-- Rewrite each operand as integer coefficient * 10^(scientific exponent - digits+1).
		local ae=integerAdd(a.Exponent,tostring(1-#a.Digits))
		local be=integerAdd(b.Exponent,tostring(1-#b.Digits))
		local cmp=integerCompare(ae,be)
		local smallest=cmp<=0 and ae or be
		local da=integerAsLimitedNumber(integerAdd(ae,integerNeg(smallest)),MAX_SHIFT)
		local db=integerAsLimitedNumber(integerAdd(be,integerNeg(smallest)),MAX_SHIFT)
		if da==nil or db==nil then error("NanoNum: exact add exceeds MAX_EXACT_SHIFT; use legacy approximate add or increase the limit") end
		local ma=a.Digits..string.rep("0",da)
		local mb=b.Digits..string.rep("0",db)
		local sign=a.Sign
		local digits
		if a.Sign==b.Sign then digits=magAdd(ma,mb)
		else
			local mag=magCmp(ma,mb)
			if mag==0 then return canonical(0,"0","0",a.Approximate or b.Approximate) end
			digits=mag>0 and magSub(ma,mb) or magSub(mb,ma)
			sign=mag>0 and a.Sign or b.Sign
		end
		return canonical(sign,digits,integerAdd(smallest,tostring(#digits-1)),a.Approximate or b.Approximate)
	end
	local function subExact(a: ExactDecimal,b: ExactDecimal): ExactDecimal
		b=validate(b)
		return addExact(a,{Sign=-b.Sign,Digits=b.Digits,Exponent=b.Exponent,Approximate=b.Approximate})
	end
	-- Decimal long division. Exactly divides terminating quotients when within precision;
	-- marks repeating/truncated quotients as approximate rather than pretending exactness.
	local function divExact(a: ExactDecimal,b: ExactDecimal,precision: number?): ExactDecimal
		a=validate(a);b=validate(b)
		if b.Sign==0 then error("NanoNum: division by zero") end
		if a.Sign==0 then return canonical(0,"0","0",a.Approximate or b.Approximate) end
		if precision~=nil and (precision~=precision or precision==math.huge or precision==-math.huge) then error("NanoNum: invalid precision") end
		local p: number=clamp(F(precision or 40),1,10000)
		local numerator=a.Digits
		local denominator=b.Digits
		local quotient: {string}={}
		local remainder: string="0"
		local sourcePosition: number=1
		-- Get significant quotient digits via long division without binary floating point.
		local started: boolean=false
		local decimalPosition: number=0
		local steps: number=0
		while #quotient<p+1 do
			local digit=sourcePosition<=#numerator and S(numerator,sourcePosition,sourcePosition) or "0"
			sourcePosition+=1;steps+=1
			remainder=trim(remainder..digit)
			local q: number=0
			while magCmp(remainder,denominator)>=0 do remainder=magSub(remainder,denominator);q+=1 end
			if q>9 then error("NanoNum: long division internal error") end
			if started or q~=0 then
				if not started then decimalPosition=sourcePosition-1;started=true end
				quotient[#quotient+1]=C(q+48)
			end
			if started and remainder=="0" and sourcePosition>#numerator then break end
			if steps>p+#numerator+#denominator+4 then error("NanoNum: long division iteration limit") end
		end
		local rounded: boolean=false
		if #quotient>p then
			rounded=true
			local nextDigit=B(quotient[p+1])-48
			quotient[p+1]=nil
			if nextDigit>=5 then
				local carry: number=1
				for i=p,1,-1 do local x=B(quotient[i])-48+carry;quotient[i]=C(48+x%10);carry=F(x/10);if carry==0 then break end end
				if carry==1 then table.insert(quotient,1,"1");decimalPosition-=1;quotient[#quotient]=nil end
			end
		end
		local exponent=integerAdd(integerAdd(a.Exponent,integerNeg(b.Exponent)),tostring(#b.Digits-decimalPosition))
		return canonical(a.Sign*b.Sign,table.concat(quotient),exponent,a.Approximate or b.Approximate or remainder~="0" or rounded)
	end
	local function powIntExact(a: ExactDecimal,power: number): ExactDecimal
		a=validate(a)
		if power~=F(power) or math.abs(power)>1000000 then error("NanoNum: exact power requires integer exponent <= 1,000,000") end
		if power<0 then return divExact(parse("1"),powIntExact(a,-power)) end
		if power==0 then return parse("1") end
		local answer=parse("1")
		while power>0 do
			if power%2==1 then answer=mulExact(answer,a) end
			power=F(power/2)
			if power>0 then a=mulExact(a,a) end
		end
		return answer
	end
	-- Correct scalar classification: never assert arbitrary logarithmic/layer values are integers.
	NanoNum.fromStringExact=parse
	NanoNum.formatExact=formatExact
	NanoNum.addExact=addExact
	NanoNum.subExact=subExact
	NanoNum.mulExact=mulExact
	NanoNum.divExact=divExact
	NanoNum.powIntExact=powIntExact
	NanoNum.compareExact=compareExact
	NanoNum.exponentAddExact=integerAdd
	NanoNum.exponentCompareExact=integerCompare
	NanoNum.EXACT_MAX_SHIFT=MAX_SHIFT
	NanoNum.EXACT_SCIENTIFIC_VERSION=3
	NanoNum.lbencodeChecked=function(v: MathValue): (number,boolean)
		local ok,code=NanoNum.tryLBEncode(v)
		if not ok then return code,false end
		local original=NanoNum.compile(v)
		return code,NanoNum.eq(original,NanoNum.lbdecode(code))
	end
	NanoNum.lbdecodeChecked=function(code: number): (boolean,buffer?)
		if not NanoNum.isLBCode(code) then return false,nil end
		return true,NanoNum.lbdecode(code)
	end
end)()

return TYPECHECKED_NANONUM :: NanoNumAPI