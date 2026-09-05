--!native
--!optimize 2

local NanoFormat = {}

export type MathValue = number | string | buffer
export type MathBinaryOperation = "add" | "sub" | "mul" | "div" | "pow"
export type MathCompareOperation = "compare" | "eq" | "lt" | "lte" | "gt" | "gte"
export type BindOperation = MathBinaryOperation | "compare"
export type DirectValueType = "number" | "buffer" | "string" | "N" | "B" | "S"
export type MathValueArray = {MathValue}

export type SuffixType =
	"standard" | "extended" | "hybrid" | "alphabetic" | "metric"
| "exponent" | "scientific" | "engineering" | "roman" | "romanextended"
export type SuffixName = SuffixType
| "short" | "ext" | "compact" | "mixed" | "alpha" | "letters"
| "si" | "exp" | "enotation" | "sci" | "eng"
| "romanx" | "roman_ext"
export type TimeStyle =
	"compact" | "long" | "clock" | "seconds"
| "raw" | "timer" | "words"

export type DecodedInteger = {
	Kind: "Integer",
	Value: number,
	Negative: boolean,
}
export type DecodedNormal = {
	Kind: "Normal",
	Negative: boolean,
	Exponent: number,
	Mantissa: number,
}
export type DecodedLog = {
	Kind: "Log",
	Negative: boolean,
	Reciprocal: boolean,
	Layer: number,
	Top: number,
}
export type DecodedLayer = {
	Kind: "Layer",
	Negative: boolean,
	Reciprocal: boolean,
	Layer: number?,
	LayerLog10: number?,
	LayerIsLog: boolean,
	Top: number,
}
export type DecodedInfinity = {Kind: "Infinity", Negative: boolean}
export type DecodedNaN = {Kind: "NaN", Negative: boolean}
export type DecodedReserved = {Kind: "Reserved", Negative: boolean}
export type DecodedValue =
	DecodedInteger | DecodedNormal | DecodedLog | DecodedLayer
| DecodedInfinity | DecodedNaN | DecodedReserved

export type InspectInfo = {
	Version: string,
	Bits: number,
	Bytes: number,
	PaddingBits: number,
	Data: DecodedValue,
}

export type LBPacket = {v: number, c: number}
export type LBLegacyPacket = {version: number, code: number}
export type LBPacketInput = LBPacket | LBLegacyPacket
export type LBInfo = {
	version: number,
	code: number,
	band: string,
	negative: boolean,
	reciprocal: boolean,
	distanceFromOne: number,
}

export type MathPerfInfo = {
	Version: number,
	PathVersion: number,
	DefaultPath: number,
	Path0: string,
	Path1: string,
	TemporaryDecodeTablesOnPath0: number,
}
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

export type FastMath = {
	addNN: (number, number) -> buffer,
	addBB: (buffer, buffer) -> buffer,
	addBN: (buffer, number) -> buffer,
	addNB: (number, buffer) -> buffer,
	addSS: (string, string) -> buffer,
	addSB: (string, buffer) -> buffer,
	addBS: (buffer, string) -> buffer,
	addSN: (string, number) -> buffer,
	addNS: (number, string) -> buffer,

	subNN: (number, number) -> buffer,
	subBB: (buffer, buffer) -> buffer,
	subBN: (buffer, number) -> buffer,
	subNB: (number, buffer) -> buffer,
	subSS: (string, string) -> buffer,
	subSB: (string, buffer) -> buffer,
	subBS: (buffer, string) -> buffer,
	subSN: (string, number) -> buffer,
	subNS: (number, string) -> buffer,

	mulNN: (number, number) -> buffer,
	mulBB: (buffer, buffer) -> buffer,
	mulBN: (buffer, number) -> buffer,
	mulNB: (number, buffer) -> buffer,
	mulSS: (string, string) -> buffer,
	mulSB: (string, buffer) -> buffer,
	mulBS: (buffer, string) -> buffer,
	mulSN: (string, number) -> buffer,
	mulNS: (number, string) -> buffer,

	divNN: (number, number) -> buffer,
	divBB: (buffer, buffer) -> buffer,
	divBN: (buffer, number) -> buffer,
	divNB: (number, buffer) -> buffer,
	divSS: (string, string) -> buffer,
	divSB: (string, buffer) -> buffer,
	divBS: (buffer, string) -> buffer,
	divSN: (string, number) -> buffer,
	divNS: (number, string) -> buffer,

	powNN: (number, number) -> buffer,
	powBB: (buffer, buffer) -> buffer,
	powBN: (buffer, number) -> buffer,
	powNB: (number, buffer) -> buffer,
	powSS: (string, string) -> buffer,
	powSB: (string, buffer) -> buffer,
	powBS: (buffer, string) -> buffer,
	powSN: (string, number) -> buffer,
	powNS: (number, string) -> buffer,

	compareNN: (number, number) -> number,
	compareBB: (buffer, buffer) -> number,
	compareBN: (buffer, number) -> number,
	compareNB: (number, buffer) -> number,
	compareSS: (string, string) -> number,
	compareSB: (string, buffer) -> number,
	compareBS: (buffer, string) -> number,
	compareSN: (string, number) -> number,
	compareNS: (number, string) -> number,
}

export type NanoNumCore = {
	isSuffixType: (string) -> boolean,
	setDefaultSuffixType: (string) -> boolean,
	getSuffix: (number, string?) -> string?,
	suffixIndex: (string, string?) -> number?,
	fromNumber: (number) -> buffer,
	fromLog10: (number, boolean?) -> buffer,
	fromLayer: (number, number, boolean?, boolean?) -> buffer,
	fromLayerLog10: (number, number, boolean?, boolean?) -> buffer,
	fromString: (string, SuffixName?) -> buffer,
	decodeAt: (buffer, number) -> (DecodedValue, number),
	tryDecodeAt: (buffer, number?) -> (boolean, DecodedValue?, number?),
	isValid: (buffer) -> boolean,
	components: (buffer) -> DecodedValue,
	bitLength: (buffer) -> number,
	byteLength: (buffer) -> number,
}

export type NanoNumFormatting = {
	format: (buffer, number?, SuffixName?) -> string,
	formatStandard: (buffer, number?) -> string,
	formatExtended: (buffer, number?) -> string,
	formatExponent: (buffer, number?) -> string,
	formatHybrid: (buffer, number?) -> string,
	formatAlphabetic: (buffer, number?) -> string,
	formatMetric: (buffer, number?) -> string,
	formatScientific: (buffer, number?) -> string,
	formatEngineering: (buffer, number?) -> string,
	formatRoman: (buffer, number?) -> string,
	formatRomanExtended: (buffer, number?) -> string,
	toNumberSafe: (MathValue) -> number?,
	formatTime: (MathValue, TimeStyle?, number?, number?) -> string,
	formatDuration: (MathValue, TimeStyle?, number?, number?) -> string,
	formatClock: (MathValue, number?) -> string,
	parseTime: (string) -> buffer,
	fromTime: (string) -> buffer,
	parseDuration: (string) -> buffer,
	formatRate: (MathValue, string?, number?, SuffixName?) -> string,
	formatBytes: (MathValue, number?, boolean?) -> string,
	formatOrdinal: (MathValue) -> string,
	formatSigned: (MathValue, number?, SuffixName?) -> string,
}

export type NanoNumPacking = {
	packMany: ({buffer}) -> (buffer, number),
	unpackMany: (buffer, number, number?) -> {buffer},
	tryUnpackMany: (buffer, number, number?) -> (boolean, {buffer}?),
	inspect: (buffer) -> InspectInfo,
}

export type NanoNumLeaderboard = {
	isLBCode: (number) -> boolean,
	tryLBEncode: (any) -> (boolean, number),
	lbencode: (MathValue) -> number,
	lbencodeV1: (MathValue) -> number,
	lbdecode: (number, number?) -> buffer,
	lbdecodeV1: (number, number?) -> buffer,
	lbcodecVersion: () -> number,
	lbpack: (MathValue) -> LBPacket,
	lbunpack: (LBPacketInput) -> buffer,
	lbinfo: (MathValue) -> LBInfo,
	lbquantize: (MathValue) -> buffer,
	lbSameBucket: (MathValue, MathValue) -> boolean,
	lbRoundTripStable: (MathValue) -> boolean,
	lbCompare: (MathValue, MathValue) -> number,
	LBEncode: (MathValue) -> number,
	LBDecode: (number, number?) -> buffer,
	LBEncodeV1: (MathValue) -> number,
	LBDecodeV1: (number, number?) -> buffer,
	LBCompare: (MathValue, MathValue) -> number,
	LBRoundTripStable: (MathValue) -> boolean,
}

export type NanoNumMath = {
	-- Core arithmetic / comparison
	add: MathBinaryFunction,
	sub: MathBinaryFunction,
	mul: MathBinaryFunction,
	div: MathBinaryFunction,
	pow: MathBinaryFunction,
	compare: MathCompareFunction,
	eq: MathPredicateFunction,
	lt: MathPredicateFunction,
	lte: MathPredicateFunction,
	gt: MathPredicateFunction,
	gte: MathPredicateFunction,
	subtract: MathBinaryFunction,
	multiply: MathBinaryFunction,
	divide: MathBinaryFunction,
	power: MathBinaryFunction,
	equal: MathPredicateFunction,
	lessThan: MathPredicateFunction,
	lessThanOrEqual: MathPredicateFunction,
	greaterThan: MathPredicateFunction,
	greaterThanOrEqual: MathPredicateFunction,

	-- Signs / classification / conversion
	sign: (MathValue) -> number,
	neg: (MathValue) -> buffer,
	negative: (MathValue) -> buffer,
	abs: (MathValue) -> buffer,
	reciprocal: (MathValue) -> buffer,
	inverse: (MathValue) -> buffer,
	copySign: (MathValue, MathValue) -> buffer,
	toNumber: (MathValue) -> number,
	isNaN: (MathValue) -> boolean,
	isInfinite: (MathValue) -> boolean,
	isFinite: (MathValue) -> boolean,
	isZero: (MathValue) -> boolean,
	isInteger: (MathValue) -> boolean,
	isOdd: (MathValue) -> boolean,
	isEven: (MathValue) -> boolean,
	isPositive: (MathValue) -> boolean,
	isNegative: (MathValue) -> boolean,

	-- Ordering / rounding / remainders
	min: (MathValue, MathValue) -> buffer,
	max: (MathValue, MathValue) -> buffer,
	clamp: (MathValue, MathValue, MathValue) -> buffer,
	clamp01: (MathValue) -> buffer,
	floor: (MathValue) -> buffer,
	ceil: (MathValue) -> buffer,
	trunc: (MathValue) -> buffer,
	round: (MathValue, number?) -> buffer,
	frac: (MathValue) -> buffer,
	mod: (MathValue, MathValue) -> buffer,
	fmod: (MathValue, MathValue) -> buffer,
	divmod: (MathValue, MathValue) -> (buffer, buffer),

	-- Log / exponent / roots
	log10: (MathValue) -> buffer,
	ln: (MathValue) -> buffer,
	log: (MathValue, MathValue?) -> buffer,
	log2: (MathValue) -> buffer,
	log1p: (MathValue) -> buffer,
	exp: (MathValue) -> buffer,
	exp2: (MathValue) -> buffer,
	expm1: (MathValue) -> buffer,
	pow10: (MathValue) -> buffer,
	powInt: (MathValue, MathValue) -> buffer,
	sqrt: (MathValue) -> buffer,
	cbrt: (MathValue) -> buffer,
	root: (MathValue, MathValue) -> buffer,
	nthRoot: (MathValue, MathValue) -> buffer,
	square: (MathValue) -> buffer,
	cube: (MathValue) -> buffer,
	hypot: (MathValue, MathValue) -> buffer,

	-- Interpolation / differences
	lerp: (MathValue, MathValue, MathValue) -> buffer,
	inverseLerp: (MathValue, MathValue, MathValue) -> buffer,
	remap: (MathValue, MathValue, MathValue, MathValue, MathValue) -> buffer,
	moveTowards: (MathValue, MathValue, MathValue) -> buffer,
	distance: (MathValue, MathValue) -> buffer,
	ratio: (MathValue, MathValue) -> buffer,
	relativeDifference: (MathValue, MathValue) -> buffer,
	approxEq: (MathValue, MathValue, MathValue?, MathValue?) -> boolean,
	almostEqual: (MathValue, MathValue, MathValue?, MathValue?) -> boolean,
	orderOfMagnitude: (MathValue) -> buffer,
	digitCount: (MathValue) -> buffer,
	smoothstep: (MathValue, MathValue, MathValue) -> buffer,
	smootherstep: (MathValue, MathValue, MathValue) -> buffer,

	-- Aggregate / integer math
	sum: (MathValueArray) -> buffer,
	product: (MathValueArray) -> buffer,
	mean: (MathValueArray) -> buffer,
	geometricMean: (MathValueArray) -> buffer,
	harmonicMean: (MathValueArray) -> buffer,
	factorial: (MathValue) -> buffer,
	factorialReal: (MathValue) -> buffer,
	permutation: (MathValue, MathValue) -> buffer,
	combination: (MathValue, MathValue) -> buffer,
	gcd: (MathValue, MathValue) -> buffer,
	lcm: (MathValue, MathValue) -> buffer,

	-- Series / simulator economy
	arithmeticSeries: (MathValue, MathValue, MathValue) -> buffer,
	geometricSeries: (MathValue, MathValue, MathValue) -> buffer,
	seriesArithmetic: (MathValue, MathValue, MathValue) -> buffer,
	seriesGeometric: (MathValue, MathValue, MathValue) -> buffer,
	compound: (MathValue, MathValue, MathValue) -> buffer,
	softcap: (MathValue, MathValue, MathValue) -> buffer,
	inverseSoftcap: (MathValue, MathValue, MathValue) -> buffer,
	diminishingReturns: (MathValue, MathValue) -> buffer,
	inverseDiminishingReturns: (MathValue, MathValue) -> buffer,
	inverseDiminishing: (MathValue, MathValue) -> buffer,
	sigmoid: (MathValue) -> buffer,
	logit: (MathValue) -> buffer,
	geometricCost: (MathValue, MathValue, MathValue, MathValue) -> buffer,
	maxAffordableGeometric: (MathValue, MathValue, MathValue, MathValue?) -> buffer,
	bulkBuyGeometric: (MathValue, MathValue, MathValue, MathValue?) -> (buffer, buffer, buffer),
	nextGeometricCost: (MathValue, MathValue, MathValue) -> buffer,
	geometricBulkCost: (MathValue, MathValue, MathValue, MathValue) -> buffer,
	affordableGeometric: (MathValue, MathValue, MathValue, MathValue?) -> buffer,

	-- Iteration / hyper operations
	iteratedExp10: (MathValue, MathValue) -> buffer,
	iteratedLog10: (MathValue, MathValue) -> buffer,
	tetrate: (MathValue, MathValue, MathValue?) -> buffer,
	tetr: (MathValue, MathValue, MathValue?) -> buffer,
	tetrateDecimal: (MathValue, MathValue, MathValue?) -> buffer,
	tetrateContinuous: (MathValue, MathValue, MathValue?) -> buffer,
	tetrate10: (MathValue, MathValue?) -> buffer,
	tetrate10Decimal: (MathValue, MathValue?) -> buffer,
	tetrateInteger: (MathValue, MathValue, MathValue?) -> buffer,
	tetrate10Integer: (MathValue, MathValue?) -> buffer,
	slog: (MathValue, MathValue?) -> buffer,
	superLog: (MathValue, MathValue?) -> buffer,
	slog10: (MathValue) -> buffer,

	-- Gamma / beta
	gammaSign: (MathValue) -> number,
	logGamma: (MathValue) -> buffer,
	logAbsGamma: (MathValue) -> buffer,
	gamma: (MathValue) -> buffer,
	betaSign: (MathValue, MathValue) -> number,
	logBeta: (MathValue, MathValue) -> buffer,
	logAbsBeta: (MathValue, MathValue) -> buffer,
	beta: (MathValue, MathValue) -> buffer,

	-- Compiled / direct-call math
	compile: (MathValue) -> buffer,
	constant: (MathValue) -> buffer,
	bindBinary: (BindOperation, DirectValueType, DirectValueType) -> BoundBinaryFunction?,
	bindRight: (MathBinaryOperation, MathValue, DirectValueType?) -> BoundUnaryFunction?,
	mathPerfInfo: () -> MathPerfInfo,
	callPerfInfo: () -> CallPerfInfo,
	fast: FastMath,

	-- Safe dynamic boundary
	isMathValue: (any) -> boolean,
	tryCompile: (any) -> (boolean, buffer?),
	tryMath: (MathBinaryOperation, any, any) -> (boolean, buffer?),
	tryCompare: (any, any) -> (boolean, number?),
}

export type NanoNumAliases = {
	modulo: (MathValue, MathValue) -> buffer,
	remainder: (MathValue, MathValue) -> buffer,
	average: (MathValueArray) -> buffer,
	choose: (MathValue, MathValue) -> buffer,
	nCr: (MathValue, MathValue) -> buffer,
	nPr: (MathValue, MathValue) -> buffer,
	slog10Approx: (MathValue) -> buffer,
	saturate: (MathValue) -> buffer,
	growth: (MathValue, MathValue, MathValue) -> buffer,
	lnGamma: (MathValue) -> buffer,
}

export type NanoNumMetadata = {
	TYPECHECK_VERSION: number,
	VERSION: string,
	MAX_LAYER: number,
	MAX_LAYER_LOG10: number,
	NORMAL_SIGNIFICAND_BITS: number,
	SCALAR_SIGNIFICAND_BITS: number,
	PARSER_VERSION: number,
	NOTATION_VERSION: number,
	PERF_VERSION: number,
	PATH_VERSION: number,
	DEFAULT_PATH: number,
	SUFFIX_VERSION: number,
	ROMAN_VERSION: number,
	TIME_VERSION: number,
	UTILITY_FORMAT_VERSION: number,
	FORMAT_SCOPE_VERSION: number,
	UTILITY_SCOPE_VERSION: number,
	PACK_SCOPE_VERSION: number,
	ROMAN_CLASSICAL_MAX: number,
	ROMAN_EXTENDED_MAX: number,
	STANDARD_SUFFIX_MAX_INDEX: number,
	METRIC_SUFFIX_MAX_INDEX: number,
	DEFAULT_SUFFIX_TYPE: string,
	E_NOTATION_START: number,
	SUFFIX_TYPES: {[string]: boolean},
	LB_VERSION: number,
	LB_SCOPE_VERSION: number,
	REGISTER_SCOPE_VERSION: number,
	LB_MAX: number,
	LB_FINITE_MAX: number,
	LB_ONE: number,
	LB_POSITIVE_SPAN: number,
	LB_ORDINARY_EXACT_MAX: number,
	LB_ORDINARY_SUBSLOTS: number,
	LB_ORDINARY_LOG_SHARE: number,
	LB_HUGE_LOG_SHARE: number,
	LB_LOW_LAYER_MAX: number,
	LB_LAYER_TOP_BUCKETS: number,
	LB_HIGH_LAYER_SHARE: number,
	MATH_SCOPE_VERSION: number,
	MATH_VERSION: number,
	MATH_CLEANUP_VERSION: number,
	CALL_VERSION: number,
	DIRECT_CALL_VERSION: number,
	BIND_VERSION: number,
	COMPILE_VERSION: number,
	MATH_PERF_VERSION: number,
	MATH_PATH_VERSION: number,
	MATH_DEFAULT_PATH: number,
	MATH_CORRECTNESS_VERSION: number,
	TETRATION_VERSION: number,
	DECIMAL_TETRATION_VERSION: number,
	SLOG_VERSION: number,
	GAMMA_VERSION: number,
	MATH_SAFETY_VERSION: number,
}

export type NanoNumModule =
	NanoNumCore
& NanoNumFormatting
& NanoNumPacking
& NanoNumLeaderboard
& NanoNumMath
& NanoNumAliases
& NanoNumMetadata


NanoFormat.TYPECHECK_VERSION = 2

NanoFormat.VERSION = "0.5.0"
NanoFormat.REGISTER_SCOPE_VERSION = 1
NanoFormat.MAX_LAYER = 1e308
NanoFormat.MAX_LAYER_LOG10 = 1e308
NanoFormat.NORMAL_SIGNIFICAND_BITS = 16
NanoFormat.SCALAR_SIGNIFICAND_BITS = 14
NanoFormat.PARSER_VERSION = 5
NanoFormat.NOTATION_VERSION = 4
NanoFormat.PERF_VERSION = 5
NanoFormat.PATH_VERSION = 1
NanoFormat.DEFAULT_PATH = 0

local floor = math.floor
local abs = math.abs
local log10 = math.log10
local huge = math.huge
local clamp = math.clamp
local min = math.min
local max = math.max
local format = string.format
local byte = string.byte
local sub = string.sub
local lower = string.lower
local find = string.find
local bufferCreate = buffer.create
local bufferReadBits = buffer.readbits
local bufferWriteBits = buffer.writebits
local bufferWriteU8 = buffer.writeu8
local bufferLen = buffer.len
local band = bit32.band
local fastPcall = pcall
local toNumber = tonumber
local toString = tostring

local BIT_LENGTH_CACHE = setmetatable({}, {__mode = "k"})

local PREFIX_TINY = 0 -- 0
local PREFIX_NEG_SMALL = 1 -- 10 (LSB-first through writePrefix)
local PREFIX_INTEGER = 2 -- 110
local PREFIX_NORMAL = 3 -- 1110
local PREFIX_LOG = 4 -- 11110
local PREFIX_LAYER = 5 -- 111110
local PREFIX_SPECIAL = 6 -- 111111

local SPECIAL_POS_INF = 0
local SPECIAL_NEG_INF = 1
local SPECIAL_NAN = 2
local SPECIAL_RESERVED = 3

local NORMAL_EXP_MIN = -324
local NORMAL_EXP_MAX = 308
local NORMAL_EXP_BIAS = 324
local NORMAL_EXP_BITS = 10
local NORMAL_MANT_BITS = 16
local NORMAL_MANT_MAX = 65535
local NORMAL_BITS = 4 + 1 + NORMAL_EXP_BITS + NORMAL_MANT_BITS -- 31

local SCALAR_EXP_BITS = 10
local SCALAR_EXP_BIAS = 324
local SCALAR_EXP_MIN = -324
local SCALAR_EXP_MAX = 308
local SCALAR_MANT_BITS = 14
local SCALAR_MANT_MAX = 16383
local SCALAR_APPROX_BITS = 1 + SCALAR_EXP_BITS + SCALAR_MANT_BITS -- 25

local EXACT_LEN_BITS = 6
local INTEGER_LEN_BITS = 5
local MAX_INTEGER_MODE_BITS = 53

local LN2 = math.log(2)
local EPS_POWER10 = 1e-11
local DIGIT_LOG10 = {
	[1] = 0,
	[2] = 0.3010299956639812,
	[3] = 0.47712125471966244,
	[4] = 0.6020599913279624,
	[5] = 0.6989700043360189,
	[6] = 0.7781512503836436,
	[7] = 0.8450980400142568,
	[8] = 0.9030899869919435,
	[9] = 0.9542425094393249,
}

-- Suffix system ---------------------------------------------------------------
--
-- "standard"   short-scale incremental-game suffixes through centillion.
-- "extended"   standard through centillion, alphabetic through 10^2997, then E3,000 notation.
-- "hybrid"     standard through centillion, then alphabetic suffixes without an E cutoff.
-- "alphabetic" aa, ab, ... zz, aaa, ... (unbounded while the index is safe).
-- "metric"     SI-style k, M, G, T, P, E, Z, Y, R, Q.
-- "exponent"   compact E3,000 / 1.25E3,006 exponent notation.
-- "scientific" 1.234e123.
-- "engineering" exponent is always a multiple of three.
NanoFormat.SUFFIX_VERSION = 3
NanoFormat.ROMAN_VERSION = 1
NanoFormat.TIME_VERSION = 1
NanoFormat.UTILITY_FORMAT_VERSION = 1
NanoFormat.ROMAN_CLASSICAL_MAX = 3999
NanoFormat.ROMAN_EXTENDED_MAX = 9007199254740991
NanoFormat.STANDARD_SUFFIX_MAX_INDEX = 101
NanoFormat.METRIC_SUFFIX_MAX_INDEX = 10
NanoFormat.DEFAULT_SUFFIX_TYPE = "standard"
NanoFormat.E_NOTATION_START = 3000
NanoFormat.SUFFIX_TYPES = {
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

local STANDARD_SUFFIXES = {
	"k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
}

-- 10^63..10^300. The base member of each family is followed by
-- un-/duo-/tre-/.../novem-style compact prefixes, matching the existing Vg
-- spellings V0.4 already used.
local STANDARD_FAMILIES = {
	{21, "Vg", "vg"},
	{31, "Tg", "tg"},
	{41, "Qag", "qag"},
	{51, "Qig", "qig"},
	{61, "Sxg", "sxg"},
	{71, "Spg", "spg"},
	{81, "Og", "og"},
	{91, "Ng", "ng"},
}
local STANDARD_UNIT_PREFIXES = {"U", "D", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"}

for _, family in STANDARD_FAMILIES do
	local baseIndex = family[1] :: number
	STANDARD_SUFFIXES[baseIndex] = family[2] :: string
	local tail = family[3] :: string
	for unit = 1, 9 do
		STANDARD_SUFFIXES[baseIndex + unit] = STANDARD_UNIT_PREFIXES[unit] .. tail
	end
end
STANDARD_SUFFIXES[101] = "Ce"

-- Coordinate suffix extension -------------------------------------------------
-- Public Standard formatting deliberately keeps the V0.5.x suffix table and
-- STANDARD_SUFFIX_MAX_INDEX=101 for compatibility. E/L coordinates, however,
-- are native Luau scalars and can reach 1e308. The one additional group needed
-- to keep the full scalar envelope compact is 10^306 => UCe, so 1e308 renders
-- as 100UCe instead of raw 1e+308.
local COORDINATE_SUFFIX_MAX_INDEX = 102
local COORDINATE_SUFFIX_102 = "UCe"

local function coordinateSuffixForIndex(index: number): string?
	if index >= 1 and index <= NanoFormat.STANDARD_SUFFIX_MAX_INDEX then
		return STANDARD_SUFFIXES[index]
	end
	if index == COORDINATE_SUFFIX_MAX_INDEX then
		return COORDINATE_SUFFIX_102
	end
	return nil
end

local METRIC_SUFFIXES = {
	"k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q",
}

local STANDARD_SUFFIX_TO_INDEX = {}
for i, suffix in STANDARD_SUFFIXES do
	STANDARD_SUFFIX_TO_INDEX[suffix] = i
end
-- Common capitalization alias; output remains lowercase k.
STANDARD_SUFFIX_TO_INDEX["K"] = 1

local METRIC_SUFFIX_TO_INDEX = {}
for i, suffix in METRIC_SUFFIXES do
	METRIC_SUFFIX_TO_INDEX[suffix] = i
end
METRIC_SUFFIX_TO_INDEX["K"] = 1

local SUFFIX_TYPE_ALIASES = {
	short = "standard",
	ext = "extended",
	compact = "extended",
	mixed = "hybrid",
	alpha = "alphabetic",
	letters = "alphabetic",
	si = "metric",
	exp = "exponent",
	enotation = "exponent",
	sci = "scientific",
	eng = "engineering",
	romanx = "romanextended",
	roman_ext = "romanextended",
	romanextended = "romanextended",
}

local function normalizeSuffixType(suffixType: string?): string
	if suffixType == nil then
		return NanoFormat.DEFAULT_SUFFIX_TYPE
	end

	-- All formatter/parser hot paths pass the canonical lowercase names. Avoid
	-- allocating a lowercased copy unless the caller actually used mixed case.
	if NanoFormat.SUFFIX_TYPES[suffixType] then
		return suffixType
	end
	local directAlias = SUFFIX_TYPE_ALIASES[suffixType]
	if directAlias ~= nil then
		return directAlias
	end

	local kind = lower(suffixType)
	kind = SUFFIX_TYPE_ALIASES[kind] or kind
	if NanoFormat.SUFFIX_TYPES[kind] then
		return kind
	end
	return NanoFormat.DEFAULT_SUFFIX_TYPE
end

local ALPHABETIC_SUFFIX_CACHE = {}

local function alphabeticSuffix(index: number): string?
	if index < 1 or index ~= floor(index) or index > 9007199254740991 then
		return nil
	end

	-- Alphabetic formatting frequently revisits the same suffix indices (for
	-- example 1e300 always asks for index 100). Cache the useful low range and
	-- keep the generator unbounded for larger safe indices.
	if index <= 4096 then
		local cached = ALPHABETIC_SUFFIX_CACHE[index]
		if cached ~= nil then
			return cached
		end
	end

	local n = index - 1
	local length = 2
	local block = 26 ^ length
	while n >= block do
		n -= block
		length += 1
		-- A suffix longer than 11 chars would already exceed the exact integer
		-- range used by NanoFormat's normal exponent indices.
		if length > 11 then
			return nil
		end
		block = 26 ^ length
	end

	local chars = table.create(length, "a")
	for pos = length, 1, -1 do
		local digit = n % 26
		chars[pos] = string.char(97 + digit)
		n = floor(n / 26)
	end
	local result = table.concat(chars)
	if index <= 4096 then
		ALPHABETIC_SUFFIX_CACHE[index] = result
	end
	return result
end

local function alphabeticSuffixIndex(suffix: string): number?
	local length = #suffix
	if length < 2 or length > 11 then
		return nil
	end

	local n = 0
	for i = 1, length do
		local c = byte(suffix, i)
		if c < 97 or c > 122 then
			return nil
		end
		n = n * 26 + (c - 97)
	end

	local offset = 0
	for l = 2, length - 1 do
		offset += 26 ^ l
	end
	local index = offset + n + 1
	if index > 9007199254740991 then
		return nil
	end
	return index
end

local function suffixForIndex(index: number, suffixType: string): string?
	if index < 1 or index ~= floor(index) then
		return nil
	end
	if suffixType == "standard" then
		return STANDARD_SUFFIXES[index]
	elseif suffixType == "extended" then
		if index <= 101 then
			return STANDARD_SUFFIXES[index]
		elseif index < 1000 then
			return alphabeticSuffix(index - 101)
		end
		return nil
	elseif suffixType == "hybrid" then
		if index <= 101 then
			return STANDARD_SUFFIXES[index]
		end
		return alphabeticSuffix(index - 101)
	elseif suffixType == "alphabetic" then
		return alphabeticSuffix(index)
	elseif suffixType == "metric" then
		return METRIC_SUFFIXES[index]
	end
	return nil
end

-- Path-zero public suffix APIs -------------------------------------------------
-- Canonical/default calls stay entirely in the public function.  Alias/case
-- normalization is a fallback only, matching GammaNum's direct hot-path style.
function NanoFormat.isSuffixType(suffixType: string): boolean
	-- PATH 0: canonical suffix names.
	if NanoFormat.SUFFIX_TYPES[suffixType] == true then
		return true
	end
	-- PATH 1: aliases / mixed case.
	if SUFFIX_TYPE_ALIASES[suffixType] ~= nil then
		return true
	end
	local kind = lower(suffixType)
	kind = SUFFIX_TYPE_ALIASES[kind] or kind
	return NanoFormat.SUFFIX_TYPES[kind] == true
end

function NanoFormat.setDefaultSuffixType(suffixType: string): boolean
	-- PATH 0: canonical suffix name.
	if NanoFormat.SUFFIX_TYPES[suffixType] == true then
		NanoFormat.DEFAULT_SUFFIX_TYPE = suffixType
		return true
	end
	-- PATH 1: alias / mixed case.
	local kind = SUFFIX_TYPE_ALIASES[suffixType]
	if kind == nil then
		kind = lower(suffixType)
		kind = SUFFIX_TYPE_ALIASES[kind] or kind
	end
	if NanoFormat.SUFFIX_TYPES[kind] ~= true then
		return false
	end
	NanoFormat.DEFAULT_SUFFIX_TYPE = kind
	return true
end

function NanoFormat.getSuffix(index: number, suffixType: string?): string?
	local i = floor(index)
	-- PATH 0: the default and canonical modes avoid normalizeSuffixType().
	local kind = suffixType
	if kind == nil then
		kind = NanoFormat.DEFAULT_SUFFIX_TYPE
	end
	if kind == "standard" then
		return STANDARD_SUFFIXES[i]
	elseif kind == "metric" then
		return METRIC_SUFFIXES[i]
	elseif kind == "alphabetic" then
		return alphabeticSuffix(i)
	elseif kind == "extended" then
		if i <= 101 then
			return STANDARD_SUFFIXES[i]
		elseif i < 1000 then
			return alphabeticSuffix(i - 101)
		end
		return nil
	elseif kind == "hybrid" then
		if i <= 101 then
			return STANDARD_SUFFIXES[i]
		end
		return alphabeticSuffix(i - 101)
	elseif kind == "exponent" or kind == "scientific" or kind == "engineering"
		or kind == "roman" or kind == "romanextended" then
		return nil
	end
	-- PATH 1: aliases / mixed-case suffix type.
	return suffixForIndex(i, normalizeSuffixType(kind))
end

function NanoFormat.suffixIndex(suffix: string, suffixType: string?): number?
	local kind = suffixType
	if kind == nil then
		kind = NanoFormat.DEFAULT_SUFFIX_TYPE
	end

	-- PATH 0: canonical modes.
	if kind == "standard" then
		return STANDARD_SUFFIX_TO_INDEX[suffix]
	elseif kind == "metric" then
		return METRIC_SUFFIX_TO_INDEX[suffix]
	elseif kind == "alphabetic" then
		return alphabeticSuffixIndex(lower(suffix))
	elseif kind == "extended" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndex(lower(suffix))
		local index = alpha and (alpha + 101) or nil
		return index and index < 1000 and index or nil
	elseif kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndex(lower(suffix))
		return alpha and (alpha + 101) or nil
	elseif kind == "exponent" or kind == "scientific" or kind == "engineering"
		or kind == "roman" or kind == "romanextended" then
		return nil
	end

	-- PATH 1: alias / mixed-case suffix type.
	kind = normalizeSuffixType(kind)
	if kind == "standard" then
		return STANDARD_SUFFIX_TO_INDEX[suffix]
	elseif kind == "metric" then
		return METRIC_SUFFIX_TO_INDEX[suffix]
	elseif kind == "alphabetic" then
		return alphabeticSuffixIndex(lower(suffix))
	elseif kind == "extended" or kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndex(lower(suffix))
		if alpha == nil then
			return nil
		end
		local index = alpha + 101
		if kind == "extended" and index >= 1000 then
			return nil
		end
		return index
	end
	return nil
end


local function bitsRequired(value: number): number
	if value <= 0 then
		return 0
	end
	return floor(math.log(value) / LN2) + 1
end

local function isSafeInteger(value: number): boolean
	return value >= 0
		and value <= 9007199254740991
		and value == floor(value)
end

local function ceilBytes(bits: number): number
	return max(1, floor((bits + 7) / 8))
end

-- Integer lengths 1..31 keep the original 5-bit header. Code 0 is an
-- extension escape for lengths 32..53, so small integers do not get larger.
local function integerLengthFieldBits(bitLength: number): number
	return if bitLength <= 31 then INTEGER_LEN_BITS else INTEGER_LEN_BITS + 5
end


local function quantizeMantissa(mantissa: number, maxCode: number): number
	local t = (mantissa - 1) / 9
	return clamp(floor(t * maxCode + 0.5), 0, maxCode)
end

local function decodeMantissa(code: number, maxCode: number): number
	return 1 + (code / maxCode) * 9
end

local function scalarExactBits(value: number): number
	if not isSafeInteger(value) then
		return huge
	end
	local n = bitsRequired(value)
	if n > 53 then
		return huge
	end
	return 1 + EXACT_LEN_BITS + n
end

local function scalarBits(value: number): number
	local exact = scalarExactBits(value)
	if exact <= SCALAR_APPROX_BITS then
		return exact
	end
	return SCALAR_APPROX_BITS
end


local function exactIntegerRecordBits(value: number): number
	local magnitude = abs(value)
	if not isSafeInteger(magnitude) then
		return huge
	end
	local n = bitsRequired(magnitude)
	if n == 0 or n > MAX_INTEGER_MODE_BITS then
		return huge
	end
	return 3 + 1 + integerLengthFieldBits(n) + n
end

local function isPower10Like(value: number): (boolean, number)
	if value <= 0 then
		return false, 0
	end

	local lg = log10(value)
	local rounded = floor(lg + 0.5)

	if abs(lg - rounded) <= EPS_POWER10 then
		return true, rounded
	end

	return false, lg
end

local function logRecordBits(exponentMagnitude: number): number
	return 5 + 1 + 1 + scalarBits(exponentMagnitude)
end

local function writeUIntExactAtFast(data: buffer, bitOffset: number, value: number, count: number)
	local remaining = count
	local shift = 0
	while remaining > 0 do
		local chunk = min(26, remaining)
		local part = floor(value / (2 ^ shift)) % (2 ^ chunk)
		bufferWriteBits(data, bitOffset, chunk, part)
		bitOffset += chunk
		shift += chunk
		remaining -= chunk
	end
end

local function writeScalarAtFast(data: buffer, bitOffset: number, value: number)
	value = abs(value)
	local exactBits = scalarExactBits(value)

	if exactBits <= SCALAR_APPROX_BITS then
		local n = bitsRequired(value)
		-- approximate bit 0 + six-bit exact length in one write.
		bufferWriteBits(data, bitOffset, 1 + EXACT_LEN_BITS, n * 2)
		writeUIntExactAtFast(data, bitOffset + 1 + EXACT_LEN_BITS, value, n)
		return
	end

	local lg = log10(value)
	local exponent = clamp(floor(lg), SCALAR_EXP_MIN, SCALAR_EXP_MAX)
	local mantissa = 10 ^ (lg - exponent)
	local mantCode = quantizeMantissa(mantissa, SCALAR_MANT_MAX)
	local expCode = exponent + SCALAR_EXP_BIAS

	-- approximate bit + exponent + mantissa are exactly 25 bits, so emit the
	-- entire approximate scalar in one operation.
	local packed = 1 + expCode * 2 + mantCode * 2048
	bufferWriteBits(data, bitOffset, SCALAR_APPROX_BITS, packed)
end

local function makeSpecial(code: number): buffer
	local data = bufferCreate(1)
	-- Prefix 111111 occupies bits 0..5; special code occupies bits 6..7.
	bufferWriteU8(data, 0, 63 + code * 64)
	return data
end

local function makeTiny(value: number): buffer
	local data = bufferCreate(1)
	-- Tiny prefix is bit 0 = 0; payload starts at bit 1.
	bufferWriteU8(data, 0, value * 2)
	return data
end

local function makeNegSmall(magnitude: number): buffer
	local data = bufferCreate(1)
	-- Negative-small prefix is bits 1,0 followed by the 6-bit payload.
	bufferWriteU8(data, 0, 1 + (magnitude - 1) * 4)
	return data
end

local function makeInteger(value: number): buffer
	local negative = value < 0
	local magnitude = abs(value)
	local n = bitsRequired(magnitude)
	local bits = 3 + 1 + integerLengthFieldBits(n) + n
	local data = bufferCreate(ceilBytes(bits))

	if n <= 31 then
		local header = 3 + (negative and 8 or 0) + n * 16
		if bits <= 32 then
			-- Prefix + sign + length + payload all fit in one write.
			bufferWriteBits(data, 0, bits, header + magnitude * 512)
		else
			bufferWriteBits(data, 0, 9, header)
			writeUIntExactAtFast(data, 9, magnitude, n)
		end
	else
		local header = 3 + (negative and 8 or 0) + (n - 32) * 512
		bufferWriteBits(data, 0, 14, header)
		writeUIntExactAtFast(data, 14, magnitude, n)
	end

	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

local function makeNormal(value: number): buffer
	local negative = value < 0
	local magnitude = abs(value)
	local lg = log10(magnitude)
	local exponent = floor(lg)
	local mantissa = 10 ^ (lg - exponent)
	local expCode = exponent + NORMAL_EXP_BIAS
	local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
	local data = bufferCreate(4)

	-- 4-bit prefix + sign + 10-bit exponent + 16-bit mantissa = 31 bits.
	local packed = 7
		+ (negative and 16 or 0)
		+ expCode * 32
		+ mantCode * 32768
	bufferWriteBits(data, 0, NORMAL_BITS, packed)

	BIT_LENGTH_CACHE[data] = NORMAL_BITS
	return data
end

local function makeLog(exponent: number, negative: boolean): buffer
	local reciprocal = exponent < 0
	local magnitude = abs(exponent)
	local bits = logRecordBits(magnitude)
	local data = bufferCreate(ceilBytes(bits))

	-- Prefix + number sign + reciprocal direction occupy seven bits.
	bufferWriteBits(
		data,
		0,
		7,
		15 + (negative and 32 or 0) + (reciprocal and 64 or 0)
	)
	writeScalarAtFast(data, 7, magnitude)

	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

local function layerFieldBits(layer: number, layerIsLog: boolean): number
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then
		return 1 + 5
	end
	-- Escape bit + representation bit (direct/log10) + adaptive scalar.
	return 2 + scalarBits(layer)
end


local function makeLayer(layer: number, top: number, negative: boolean, reciprocal: boolean, layerIsLog: boolean?): buffer
	-- Public constructors canonicalize negative/small tops before reaching this
	-- point. A negative top is not the same thing as a reciprocal for layer >= 2.
	if top < 0 then
		top = 0
	end

	local logLayer = layerIsLog == true
	if logLayer then
		layer = clamp(layer, 0, NanoFormat.MAX_LAYER_LOG10)
	else
		layer = clamp(layer, 2, NanoFormat.MAX_LAYER)
	end
	top = clamp(top, 0, 1e308)

	local bits = 6 + 1 + 1 + layerFieldBits(layer, logLayer) + scalarBits(top)
	local data = bufferCreate(ceilBytes(bits))

	-- Six-bit layer prefix + sign + reciprocal fill the first byte exactly.
	bufferWriteU8(data, 0, 31 + (negative and 64 or 0) + (reciprocal and 128 or 0))
	local bitOffset = 8

	if not logLayer and layer == floor(layer) and layer >= 2 and layer <= 33 then
		-- escape=0 plus five-bit direct layer code.
		bufferWriteBits(data, bitOffset, 6, (layer - 2) * 2)
		bitOffset += 6
	else
		-- escape=1 plus representation bit.
		bufferWriteBits(data, bitOffset, 2, 1 + (logLayer and 2 or 0))
		bitOffset += 2
		writeScalarAtFast(data, bitOffset, layer)
		bitOffset += scalarBits(layer)
	end

	writeScalarAtFast(data, bitOffset, top)
	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

local DIRECT_LAYER_LOG10_MAX = 308

local function normalizeLayerInput(layer: number, top: number, layerIsLog: boolean): (number, number, boolean)
	-- Log-height values that still fit inside the direct layer envelope are
	-- canonicalized back to a direct layer count. This prevents two different
	-- encodings for the same height and keeps leaderboard ordering stable.
	if layerIsLog and layer <= DIRECT_LAYER_LOG10_MAX then
		local directLayer = 10 ^ layer
		if directLayer < 2 then
			directLayer = 2
		elseif directLayer > NanoFormat.MAX_LAYER then
			directLayer = NanoFormat.MAX_LAYER
		end
		layer = directLayer
		layerIsLog = false
	end

	if not layerIsLog then
		if layer < 0 then
			layer = 0
		end
		layer = floor(layer + 0.5)

		-- e^N(top) can be reduced one layer whenever 10^top still fits in the
		-- scalar envelope. This fixes cases such as ee5, which is just 1e100000,
		-- rather than incorrectly ranking above every layer-1 value.
		while layer >= 2 and top <= 308 and layer <= 9007199254740991 do
			if top < -324 then
				top = 0
			else
				top = 10 ^ top
			end
			layer -= 1
		end
	end

	return layer, top, layerIsLog
end

-- Path-zero constructors -------------------------------------------------------
-- Common finite/canonical values are emitted directly in the public constructor.
-- Rare powers/special/canonicalization cases may fall back to the specialized
-- helpers.  No runtime "path number" is stored; PATH 0 is purely structural.
function NanoFormat.fromNumber(value: number): buffer
	-- PATH S: special IEEE values.
	if value ~= value then
		return makeSpecial(SPECIAL_NAN)
	elseif value == huge then
		return makeSpecial(SPECIAL_POS_INF)
	elseif value == -huge then
		return makeSpecial(SPECIAL_NEG_INF)
	end

	-- PATH 0A: zero / tiny positive integer. One allocation + one byte write.
	if value >= 0 and value <= 127 and value == floor(value) then
		local data = bufferCreate(1)
		bufferWriteU8(data, 0, value * 2)
		return data
	end

	-- PATH 0B: tiny negative integer.
	if value < 0 and value >= -64 and value == floor(value) then
		local data = bufferCreate(1)
		bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
		return data
	end

	local integerBits = exactIntegerRecordBits(value)
	local usePower, exponent = isPower10Like(abs(value))
	local powerBits = huge
	if usePower and exponent ~= 0 then
		powerBits = logRecordBits(abs(exponent))
	end

	-- PATH 1: exact power-of-ten is smaller as a log record.
	if powerBits < integerBits and powerBits < NORMAL_BITS then
		return makeLog(exponent, value < 0)
	end

	-- PATH 0C: ordinary exact integer, emitted inline.
	if integerBits < NORMAL_BITS then
		local negative = value < 0
		local magnitude = abs(value)
		local n = bitsRequired(magnitude)
		local data = bufferCreate(ceilBytes(integerBits))
		if n <= 31 then
			local header = 3 + (negative and 8 or 0) + n * 16
			if integerBits <= 32 then
				bufferWriteBits(data, 0, integerBits, header + magnitude * 512)
			else
				bufferWriteBits(data, 0, 9, header)
				writeUIntExactAtFast(data, 9, magnitude, n)
			end
		else
			local header = 3 + (negative and 8 or 0) + (n - 32) * 512
			bufferWriteBits(data, 0, 14, header)
			writeUIntExactAtFast(data, 14, magnitude, n)
		end
		if band(integerBits, 7) ~= 0 then
			BIT_LENGTH_CACHE[data] = integerBits
		end
		return data
	end

	-- PATH 0D: ordinary finite decimal/large value. Emit the 31-bit normal
	-- record directly rather than routing through makeNormal().
	local negative = value < 0
	local magnitude = abs(value)
	local lg = log10(magnitude)
	local exponentNormal = floor(lg)
	local mantissa = 10 ^ (lg - exponentNormal)
	local expCode = exponentNormal + NORMAL_EXP_BIAS
	local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
	local data = bufferCreate(4)
	local packed = 7
		+ (negative and 16 or 0)
		+ expCode * 32
		+ mantCode * 32768
	bufferWriteBits(data, 0, NORMAL_BITS, packed)
	BIT_LENGTH_CACHE[data] = NORMAL_BITS
	return data
end

function NanoFormat.fromLog10(exponent: number, negative: boolean?): buffer
	-- PATH S: specials.
	if exponent ~= exponent then
		return makeSpecial(SPECIAL_NAN)
	elseif exponent == huge then
		return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
	elseif exponent == -huge then
		exponent = -1e308
	elseif exponent == 0 then
		-- This is one of the rare cases where canonical layer-0 encoding is better.
		return NanoFormat.fromNumber(negative and -1 or 1)
	end

	-- PATH 0: direct log record.
	local reciprocal = exponent < 0
	local magnitude = abs(exponent)
	local bits = logRecordBits(magnitude)
	local data = bufferCreate(ceilBytes(bits))
	bufferWriteBits(
		data,
		0,
		7,
		15 + (negative == true and 32 or 0) + (reciprocal and 64 or 0)
	)
	writeScalarAtFast(data, 7, magnitude)
	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

function NanoFormat.fromLayer(layer: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	-- PATH S: invalid/special layer.
	if layer ~= layer or top ~= top then
		return makeSpecial(SPECIAL_NAN)
	elseif layer == huge then
		return NanoFormat.fromLayerLog10(308, top, negative, reciprocal)
	end

	-- PATH 0: already-canonical direct layers.  Most formatted huge values enter
	-- here.  A single safe reduction is also handled inline (e.g. e^1000 5).
	if layer >= 2 and layer <= NanoFormat.MAX_LAYER and layer == floor(layer) then
		if top > 308 then
			return makeLayer(layer, top, negative == true, reciprocal == true, false)
		elseif top > 2.4885507165004443 then -- log10(308)
			local reducedTop = 10 ^ top
			local reducedLayer = layer - 1
			if reducedLayer < 2 then
				local exp = reciprocal and -abs(reducedTop) or reducedTop
				return NanoFormat.fromLog10(exp, negative)
			end
			return makeLayer(reducedLayer, reducedTop, negative == true, reciprocal == true, false)
		end
	end

	-- PATH 1: values that need full canonicalization.
	local normalizedLayer, normalizedTop =
		normalizeLayerInput(layer, top, false)

	if normalizedLayer <= 0 then
		local v = normalizedTop
		if reciprocal then
			if v == 0 then
				return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
			end
			v = 1 / v
		end
		if negative then
			v = -v
		end
		return NanoFormat.fromNumber(v)
	end

	if normalizedLayer < 2 then
		local exp = reciprocal and -abs(normalizedTop) or normalizedTop
		return NanoFormat.fromLog10(exp, negative)
	end

	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, false)
end

function NanoFormat.fromLayerLog10(layerLog10: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layerLog10 ~= layerLog10 or top ~= top then
		return makeSpecial(SPECIAL_NAN)
	end
	if layerLog10 == huge then
		layerLog10 = NanoFormat.MAX_LAYER_LOG10
	end

	-- PATH 0: genuinely logarithmic heights never need conversion back to a
	-- direct layer count.
	if layerLog10 > DIRECT_LAYER_LOG10_MAX then
		return makeLayer(
			clamp(layerLog10, 0, NanoFormat.MAX_LAYER_LOG10),
			top,
			negative == true,
			reciprocal == true,
			true
		)
	end

	-- PATH 1: small log-heights canonicalize to the direct-layer representation.
	local normalizedLayer, normalizedTop, layerIsLog =
		normalizeLayerInput(clamp(layerLog10, 0, NanoFormat.MAX_LAYER_LOG10), top, true)

	if not layerIsLog then
		return NanoFormat.fromLayer(normalizedLayer, normalizedTop, negative, reciprocal)
	end

	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, true)
end

local function isWhitespaceByte(c: number?): boolean
	return c == 32 or c == 9 or c == 10 or c == 11 or c == 12 or c == 13
end

local function asciiLowerByte(c: number): number
	if c >= 65 and c <= 90 then
		return c + 32
	end
	return c
end

local function rangeEqualsCI(value: string, first: number, last: number, literal: string): boolean
	local length = last - first + 1
	if length ~= #literal then
		return false
	end
	for i = 1, length do
		if asciiLowerByte(byte(value, first + i - 1)) ~= byte(literal, i) then
			return false
		end
	end
	return true
end

local function trimRange(value: string): (number, number)
	local first = 1
	local last = #value
	while first <= last and isWhitespaceByte(byte(value, first)) do
		first += 1
	end
	while last >= first and isWhitespaceByte(byte(value, last)) do
		last -= 1
	end
	return first, last
end

-- Decimal scanner used by the slow/symbolic path. It performs no substring
-- allocations and returns the decimal logarithm even when the value itself is
-- outside IEEE-754 range.
local function parseDecimalRange(
	value: string,
	first: number,
	last: number,
	reconstructDirect: boolean?
): (boolean, boolean, boolean, number?, number?)
	if first > last then
		return false, false, false, nil, nil
	end

	local negative = false
	local c = byte(value, first)
	if c == 43 or c == 45 then
		negative = c == 45
		first += 1
		if first > last then
			return false, false, false, nil, nil
		end
	end

	local digitIndex = 0
	local digitsBeforeDecimal = -1
	local firstNonZero = 0
	local leading = 0
	local leadingCount = 0
	local sawDigit = false
	local sawDot = false

	for i = first, last do
		c = byte(value, i)
		if c >= 48 and c <= 57 then
			sawDigit = true
			digitIndex += 1
			local digit = c - 48
			if firstNonZero == 0 then
				if digit ~= 0 then
					firstNonZero = digitIndex
					leading = digit
					leadingCount = 1
				end
			elseif leadingCount < 17 then
				leading = leading * 10 + digit
				leadingCount += 1
			end
		elseif c == 46 and not sawDot then
			sawDot = true
			digitsBeforeDecimal = digitIndex
		else
			return false, false, false, nil, nil
		end
	end

	if not sawDigit then
		return false, false, false, nil, nil
	end
	if firstNonZero == 0 then
		return true, negative, true, 0, -huge
	end
	if digitsBeforeDecimal < 0 then
		digitsBeforeDecimal = digitIndex
	end

	local decimalExponent = digitsBeforeDecimal - firstNonZero
	local mantissa = leading / (10 ^ (leadingCount - 1))
	local logAbs = decimalExponent + log10(mantissa)
	local directAbs = nil

	-- Reconstruct only while the result is representable. Keeping the logarithm
	-- separately prevents huge values becoming inf and tiny values becoming 0.
	if reconstructDirect ~= false
		and logAbs <= 308.25471555991675
		and logAbs >= -323.3062153431158
	then
		local candidate = 10 ^ logAbs
		if candidate ~= 0 and candidate ~= huge then
			directAbs = candidate
		end
	end

	return true, negative, false, directAbs, logAbs
end

-- Exponents in scientific notation are integers. Small/normal exponents are
-- accumulated directly; enormous exponent strings return log10(abs(exp)) so
-- the caller can promote the value to a higher NanoFormat layer.
local function parseScientificExponentRange(
	value: string,
	first: number,
	last: number
): (number?, number?, number?)
	if first > last then
		return nil, nil, nil
	end

	local sign = 1
	local c = byte(value, first)
	if c == 43 or c == 45 then
		sign = if c == 45 then -1 else 1
		first += 1
		if first > last then
			return nil, nil, nil
		end
	end

	local significantDigits = 0
	local lead = 0
	local leadCount = 0
	local magnitude = 0
	local sawNonZero = false
	local sawComma = false
	local groupDigits = 0
	local firstGroup = true

	for i = first, last do
		c = byte(value, i)
		if c >= 48 and c <= 57 then
			local digit = c - 48
			groupDigits += 1
			if digit ~= 0 or sawNonZero then
				sawNonZero = true
				significantDigits += 1
				if significantDigits <= 309 then
					magnitude = magnitude * 10 + digit
				end
				if leadCount < 17 then
					lead = lead * 10 + digit
					leadCount += 1
				end
			end
		elseif c == 44 then
			sawComma = true
			if groupDigits < 1 then
				return nil, nil, nil
			end
			if firstGroup then
				if groupDigits > 3 then
					return nil, nil, nil
				end
				firstGroup = false
			elseif groupDigits ~= 3 then
				return nil, nil, nil
			end
			groupDigits = 0
		else
			return nil, nil, nil
		end
	end

	if sawComma and (firstGroup or groupDigits ~= 3) then
		return nil, nil, nil
	end
	if not sawNonZero then
		return 0, nil, nil
	end
	if significantDigits <= 309 and magnitude ~= huge then
		return magnitude * sign, nil, nil
	end

	local leadMantissa = lead / (10 ^ (leadCount - 1))
	return nil, sign, (significantDigits - 1) + log10(leadMantissa)
end

-- Parses a finite numeric token used by NanoFormat's own layered text output.
-- Scientific notation is supported because formatLargeScalar() emits it.
local function parseFiniteNumericRange(
	value: string,
	first: number,
	last: number
): (boolean, number?, number?)
	if first > last then
		return false, nil, nil
	end

	-- Fast exact-integer token path used heavily by e^N top / eeTop syntax.
	-- It avoids decimal-log reconstruction for values such as "1000" and "5".
	local p = first
	local negative = false
	local c = byte(value, p)
	if c == 43 or c == 45 then
		negative = c == 45
		p += 1
	end
	if p <= last and last - p + 1 <= 15 then
		local integer = 0
		local allDigits = true
		for i = p, last do
			c = byte(value, i)
			if c < 48 or c > 57 then
				allDigits = false
				break
			end
			integer = integer * 10 + (c - 48)
		end
		if allDigits then
			return true, negative and -integer or integer, nil
		end
	end

	local ePos = 0
	for i = first, last do
		local c = byte(value, i)
		if c == 101 or c == 69 then
			if ePos ~= 0 then
				return false, nil, nil
			end
			ePos = i
		end
	end

	local mantissaLast = if ePos == 0 then last else ePos - 1
	local valid = true
	local mantissaNegative = negative
	local zero = false
	local decimalLog: number? = nil

	if ePos ~= 0 and ePos == p + 1 then
		local digitByte = byte(value, p)
		if digitByte >= 48 and digitByte <= 57 then
			local digit = digitByte - 48
			if digit == 0 then
				zero = true
				decimalLog = -huge
			else
				decimalLog = DIGIT_LOG10[digit]
			end
		else
			valid = false
		end
	else
		local parsedValid, parsedNegative, parsedZero, _, parsedLog =
			parseDecimalRange(value, first, mantissaLast, false)
		valid = parsedValid
		mantissaNegative = parsedNegative
		zero = parsedZero
		decimalLog = parsedLog
	end

	if not valid or decimalLog == nil then
		return false, nil, nil
	end
	if zero then
		return true, 0, -huge
	end

	local finalLog = decimalLog
	if ePos ~= 0 then
		local exponent = parseScientificExponentRange(value, ePos + 1, last)
		if exponent == nil then
			return false, nil, nil
		end
		finalLog += exponent
	end

	if finalLog > 308.25471555991675 then
		return true, nil, finalLog
	end
	if finalLog < -323.3062153431158 then
		return true, 0, finalLog
	end

	local magnitude = 10 ^ finalLog
	if magnitude == huge then
		return true, nil, finalLog
	end
	if magnitude == 0 then
		return true, 0, finalLog
	end
	return true, mantissaNegative and -magnitude or magnitude, finalLog
end

local function alphabeticSuffixIndexRange(value: string, first: number, last: number): number?
	local length = last - first + 1
	if length < 2 or length > 11 then
		return nil
	end

	local n = 0
	for i = first, last do
		local c = asciiLowerByte(byte(value, i))
		if c < 97 or c > 122 then
			return nil
		end
		n = n * 26 + (c - 97)
	end

	local offset = 0
	for l = 2, length - 1 do
		offset += 26 ^ l
	end
	local index = offset + n + 1
	if index > 9007199254740991 then
		return nil
	end
	return index
end

local function shortSuffixKeyString(suffix: string): number?
	local length = #suffix
	if length < 1 or length > 7 then
		return nil
	end
	local key = 0
	for i = 1, length do
		key = key * 128 + byte(suffix, i)
	end
	return key
end

local FAST_STANDARD_SUFFIX_TO_INDEX = {}
for suffix, index in STANDARD_SUFFIX_TO_INDEX do
	local key = shortSuffixKeyString(suffix)
	if key ~= nil then
		FAST_STANDARD_SUFFIX_TO_INDEX[key] = index
	end
end

local FAST_METRIC_SUFFIX_TO_INDEX = {}
for suffix, index in METRIC_SUFFIX_TO_INDEX do
	local key = shortSuffixKeyString(suffix)
	if key ~= nil then
		FAST_METRIC_SUFFIX_TO_INDEX[key] = index
	end
end

local function shortSuffixKeyRange(value: string, first: number, last: number): number?
	local length = last - first + 1
	if length < 1 or length > 7 then
		return nil
	end
	local key = 0
	for i = first, last do
		key = key * 128 + byte(value, i)
	end
	return key
end

local function suffixIndexRange(
	value: string,
	first: number,
	last: number,
	suffixType: string
): number?
	if suffixType == "alphabetic" then
		return alphabeticSuffixIndexRange(value, first, last)
	end

	-- Standard/metric suffixes fit in a small exact numeric key, so parsing them
	-- requires no substring allocation at all.
	local key = shortSuffixKeyRange(value, first, last)
	if suffixType == "standard" then
		return key and FAST_STANDARD_SUFFIX_TO_INDEX[key] or nil
	elseif suffixType == "extended" then
		local standard = key and FAST_STANDARD_SUFFIX_TO_INDEX[key] or nil
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndexRange(value, first, last)
		local index = alpha and (alpha + 101) or nil
		return index and index < 1000 and index or nil
	elseif suffixType == "metric" then
		return key and FAST_METRIC_SUFFIX_TO_INDEX[key] or nil
	elseif suffixType == "hybrid" then
		local standard = key and FAST_STANDARD_SUFFIX_TO_INDEX[key] or nil
		if standard ~= nil then
			return standard
		end
		return alphabeticSuffixIndexRange(value, first, last)
	end
	return nil
end

local function parseGroupedDecimalRange(value: string, first: number, last: number): number?
	if first > last then
		return nil
	end

	local sign = 1
	local c = byte(value, first)
	if c == 43 or c == 45 then
		sign = if c == 45 then -1 else 1
		first += 1
		if first > last then
			return nil
		end
	end

	local result = 0
	local fractionScale = 1
	local sawDigit = false
	local sawDot = false
	local sawComma = false
	local digitsInGroup = 0
	local groupCount = 0

	for i = first, last do
		c = byte(value, i)
		if c >= 48 and c <= 57 then
			sawDigit = true
			local digit = c - 48
			if sawDot then
				fractionScale *= 10
				result += digit / fractionScale
			else
				result = result * 10 + digit
				digitsInGroup += 1
			end
		elseif c == 44 then
			if sawDot or not sawDigit or digitsInGroup == 0 then
				return nil
			end
			if groupCount == 0 then
				if digitsInGroup > 3 then
					return nil
				end
			elseif digitsInGroup ~= 3 then
				return nil
			end
			sawComma = true
			groupCount += 1
			digitsInGroup = 0
		elseif c == 46 then
			if sawDot or digitsInGroup == 0 then
				return nil
			end
			if sawComma and digitsInGroup ~= 3 then
				return nil
			end
			sawDot = true
		else
			return nil
		end
	end

	if not sawDigit then
		return nil
	end
	if sawComma and not sawDot and digitsInGroup ~= 3 then
		return nil
	end

	result *= sign
	if result == huge or result == -huge then
		return nil
	end
	return result
end

-- Coordinate suffix parser used by E/L notation. Public suffixIndex("standard")
-- remains unchanged; this adds only UCe as the compact 10^306 coordinate group.
local function coordinateSuffixIndexRange(value: string, first: number, last: number): number?
	local standard = suffixIndexRange(value, first, last, "standard")
	if standard ~= nil then
		return standard
	end

	if last - first + 1 == 3 and rangeEqualsCI(value, first, last, "uce") then
		return COORDINATE_SUFFIX_MAX_INDEX
	end

	return nil
end

-- Parses the exponent coordinate emitted by exponentCompactText:
-- 3,000 / 1M / 100UCe / 1e+308 (legacy fallback).
local function parseCompactExponentRange(value: string, first: number, last: number): number?
	if first > last then
		return nil
	end

	local plain = parseGroupedDecimalRange(value, first, last)
	if plain ~= nil then
		return plain
	end

	local suffixStart = last + 1
	local i = last
	while i >= first do
		local c = byte(value, i)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
			suffixStart = i
			i -= 1
		else
			break
		end
	end

	if suffixStart > first and suffixStart <= last then
		local scalar = parseGroupedDecimalRange(value, first, suffixStart - 1)
		local index = coordinateSuffixIndexRange(value, suffixStart, last)
		if scalar ~= nil and index ~= nil then
			local exponent = scalar * (10 ^ (index * 3))
			if exponent ~= huge and exponent ~= -huge then
				return exponent
			end
		end
	end

	-- Compatibility with V0.5.3 output such as E1e+308.
	local finite, direct = parseFiniteNumericRange(value, first, last)
	if finite and direct ~= nil and direct ~= huge and direct ~= -huge then
		return direct
	end

	return nil
end

-- Parses the compact scalar grammar used on both sides of L notation:
-- 3, 1k, 1M, 100UCe, and legacy 1e+308.
local function parseCompactLayerScalarRange(value: string, first: number, last: number): number?
	local plain = parseGroupedDecimalRange(value, first, last)
	if plain ~= nil then
		return plain
	end

	local suffixStart = last + 1
	local i = last
	while i >= first do
		local c = byte(value, i)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
			suffixStart = i
			i -= 1
		else
			break
		end
	end

	if suffixStart > first and suffixStart <= last then
		local index = coordinateSuffixIndexRange(value, suffixStart, last)
		local scalar = parseGroupedDecimalRange(value, first, suffixStart - 1)
		if index ~= nil and scalar ~= nil then
			local result = scalar * (10 ^ (index * 3))
			if result ~= huge and result ~= -huge then
				return result
			end
		end
	end

	-- Compatibility with V0.5.3 L output such as L3 1e+308.
	local finite, direct = parseFiniteNumericRange(value, first, last)
	if finite and direct ~= nil and direct ~= huge and direct ~= -huge then
		return direct
	end

	return nil
end

local function fromSignedLogSmart(logMagnitude: number, negative: boolean): buffer
	-- Prefer the regular constructor whenever the mathematical value still fits
	-- in a Luau number. This gives finite suffix/reciprocal inputs the same
	-- precision/storage decisions as fromNumber(), while retaining symbolic log
	-- storage only for true overflow/underflow cases.
	if logMagnitude <= 308.25471555991675 and logMagnitude >= -323.3062153431158 then
		local magnitude = 10 ^ logMagnitude
		if magnitude ~= 0 and magnitude ~= huge then
			return NanoFormat.fromNumber(negative and -magnitude or magnitude)
		end
	end
	return NanoFormat.fromLog10(logMagnitude, negative)
end

local function scientificExponentNeedsSymbolic(
	value: string,
	ePos: number,
	last: number
): boolean
	local p = ePos + 1
	if p > last then
		return false
	end

	local negativeExponent = false
	local c = byte(value, p)
	if c == 43 or c == 45 then
		negativeExponent = c == 45
		p += 1
		if p > last then
			return false
		end
	end

	while p <= last and byte(value, p) == 48 do
		p += 1
	end
	if p > last then
		return false
	end

	local digits = last - p + 1
	if digits > 3 then
		return true
	end
	if digits < 3 then
		return false
	end

	local exponent = 0
	for i = p, last do
		c = byte(value, i)
		if c < 48 or c > 57 then
			return false
		end
		exponent = exponent * 10 + (c - 48)
	end

	return exponent > (negativeExponent and 323 or 308)
end

local function classifyDirectStringFast(value: string): (boolean, number)
	local length = #value
	if length == 0 then
		return false, 0
	end

	local firstByte = byte(value, 1)
	local lastByte = byte(value, length)

	-- Suffix/special tokens should not pay for a guaranteed failed tonumber().
	if (lastByte >= 65 and lastByte <= 90) or (lastByte >= 97 and lastByte <= 122) then
		return false, 0
	end

	-- Very long plain decimals are either overflow candidates or long tiny
	-- decimals. Keep them symbolic instead of asking tonumber() to scan them.
	if length > 309 then
		return false, 0
	end

	local p = 1
	if firstByte == 43 or firstByte == 45 then
		p = 2
	end

	if p <= length then
		local c = byte(value, p)

		-- Reciprocal and layered syntax are NanoFormat-specific.
		if c == 49 and p < length and byte(value, p + 1) == 47 then
			return false, 0
		end
		if asciiLowerByte(c) == 108 and p < length then -- L notation
			return false, 0
		end
		if asciiLowerByte(c) == 101 and p < length then
			local c2 = byte(value, p + 1)
			if c2 == 94 or asciiLowerByte(c2) == 101 then
				return false, 0
			end
		end
	end

	local ePos = find(value, "e", 1, true)
	if ePos == nil then
		ePos = find(value, "E", 1, true)
	end

	if ePos ~= nil and scientificExponentNeedsSymbolic(value, ePos, length) then
		return false, ePos
	end

	return true, ePos or 0
end

function NanoFormat.fromString(value: string, suffixType: SuffixName?): buffer
	-- V0.5.4 keeps the dispatch-before-tonumber parser. Symbolic forms, suffixes, and
	-- scientific exponents that cannot fit IEEE-754 no longer pay for a failed
	-- C-number parse before the real NanoFormat parser starts.
	local tryDirect, hintedEPos = classifyDirectStringFast(value)
	if tryDirect then
		local direct = toNumber(value)
		if direct ~= nil and direct ~= huge and direct ~= -huge then
			return NanoFormat.fromNumber(direct)
		end
	end

	local first, last = trimRange(value)
	if first > last then
		return makeSpecial(SPECIAL_NAN)
	end

	local negative = false
	local c = byte(value, first)
	if c == 43 or c == 45 then
		negative = c == 45
		first += 1
		if first > last then
			return makeSpecial(SPECIAL_NAN)
		end
	end

	-- Special values are rare. Numeric/suffix/layer inputs should not pay for
	-- three case-insensitive range checks on every parse.
	local firstLower = asciiLowerByte(byte(value, first))
	if firstLower == 105 then -- i
		if rangeEqualsCI(value, first, last, "inf") or rangeEqualsCI(value, first, last, "infinity") then
			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		end
	elseif firstLower == 110 then -- n
		if rangeEqualsCI(value, first, last, "nan") then
			return makeSpecial(SPECIAL_NAN)
		end
	end

	local reciprocal = false
	if last - first + 1 >= 2 and byte(value, first) == 49 and byte(value, first + 1) == 47 then
		reciprocal = true
		first += 2
		if first > last then
			return makeSpecial(SPECIAL_NAN)
		end
	end

	-- L notation ---------------------------------------------------------------
	-- Canonical: L<layer> <top> / L(10^<layerLog10>) <top>
	-- Compatibility: ':' may replace the separating space.
	-- Examples: L3 1k, L3:1k, L1M 1k, L(10^1M) 1k.
	if asciiLowerByte(byte(value, first)) == 108 and first < last then
		local tokenStart = first + 1

		if byte(value, tokenStart) == 40 then
			if tokenStart + 3 <= last
				and byte(value, tokenStart + 1) == 49
				and byte(value, tokenStart + 2) == 48
				and byte(value, tokenStart + 3) == 94
			then
				local layerStart = tokenStart + 4
				local close = 0
				for i = layerStart, last do
					if byte(value, i) == 41 then
						close = i
						break
					end
				end

				if close ~= 0 and layerStart <= close - 1 then
					local topStart = close + 1
					while topStart <= last do
						local tc = byte(value, topStart)
						if isWhitespaceByte(tc) or tc == 58 then
							topStart += 1
						else
							break
						end
					end

					if topStart <= last then
						local layerLog =
							parseCompactLayerScalarRange(value, layerStart, close - 1)
						local top =
							parseCompactLayerScalarRange(value, topStart, last)
						if layerLog ~= nil and top ~= nil then
							return NanoFormat.fromLayerLog10(
								layerLog, top, negative, reciprocal
							)
						end
					end
				end
			end
		else
			local split = 0
			for i = tokenStart, last do
				local sc = byte(value, i)
				if isWhitespaceByte(sc) or sc == 58 then
					split = i
					break
				end
			end

			if split ~= 0 and tokenStart <= split - 1 then
				local topStart = split + 1
				while topStart <= last do
					local tc = byte(value, topStart)
					if isWhitespaceByte(tc) or tc == 58 then
						topStart += 1
					else
						break
					end
				end

				if topStart <= last then
					local layer =
						parseCompactLayerScalarRange(value, tokenStart, split - 1)
					local top =
						parseCompactLayerScalarRange(value, topStart, last)
					if layer ~= nil and top ~= nil then
						return NanoFormat.fromLayer(
							layer, top, negative, reciprocal
						)
					end
				end
			end
		end
		return makeSpecial(SPECIAL_NAN)
	end

	-- Compact display-E syntax -----------------------------------------------
	-- Handles the flat coordinate grammar emitted by the formatter:
	-- E3,000 / E1M / E100UCe / 1.25E3,006.
	-- Uppercase E is reserved for this display form; lowercase e continues to
	-- use the scientific/legacy layer grammar below.
	local displayEPos = 0
	for i = first, last do
		if byte(value, i) == 69 then
			displayEPos = i
			break
		end
	end

	if displayEPos ~= 0 then
		local exponent = parseCompactExponentRange(value, displayEPos + 1, last)
		if exponent ~= nil then
			local mantissaLog = 0
			local mantissaNegative = false
			local zero = false

			if displayEPos > first then
				local valid, innerNegative, innerZero, _, innerLog =
					parseDecimalRange(value, first, displayEPos - 1, false)
				if not valid or innerLog == nil then
					return makeSpecial(SPECIAL_NAN)
				end
				mantissaNegative = innerNegative
				zero = innerZero
				mantissaLog = innerLog
			end

			local finalNegative = negative ~= mantissaNegative
			if zero then
				return makeTiny(0)
			end

			local totalLog = exponent + mantissaLog
			if reciprocal then
				totalLog = -totalLog
			end
			return fromSignedLogSmart(totalLog, finalNegative)
		end
	end

	-- Compact exponent syntax: E3,000 == 1e3000. It also accepts a mantissa
	-- through the regular scientific path, e.g. 1.25E3,006.
	if asciiLowerByte(byte(value, first)) == 101 and first < last then
		local nextByte = byte(value, first + 1)
		if (nextByte >= 48 and nextByte <= 57) or nextByte == 43 or nextByte == 45 then
			local directExponent, exponentSign, exponentLog10 =
				parseScientificExponentRange(value, first + 1, last)
			if directExponent ~= nil then
				local totalLog = reciprocal and -directExponent or directExponent
				return fromSignedLogSmart(totalLog, negative)
			elseif exponentSign ~= nil and exponentLog10 ~= nil then
				local isReciprocal = exponentSign < 0
				if reciprocal then
					isReciprocal = not isReciprocal
				end
				return NanoFormat.fromLayer(2, exponentLog10, negative, isReciprocal)
			end
			return makeSpecial(SPECIAL_NAN)
		end
	end

	-- NanoFormat layer syntax --------------------------------------------------
	-- e^(10^X) Y
	-- e^X Y
	-- eeY / eeeY / ...
	if asciiLowerByte(byte(value, first)) == 101 then
		local second = if first < last then byte(value, first + 1) else nil
		if second == 94 then
			local tokenStart = first + 2
			if tokenStart <= last and byte(value, tokenStart) == 40 then
				-- Logarithmic layer height: e^(10^X) Y
				tokenStart += 1
				while tokenStart <= last and isWhitespaceByte(byte(value, tokenStart)) do
					tokenStart += 1
				end
				if tokenStart + 2 <= last
					and byte(value, tokenStart) == 49
					and byte(value, tokenStart + 1) == 48
					and byte(value, tokenStart + 2) == 94
				then
					local layerStart = tokenStart + 3
					local close = 0
					for i = layerStart, last do
						if byte(value, i) == 41 then
							close = i
							break
						end
					end
					if close ~= 0 then
						local topStart = close + 1
						local hadSpace = false
						while topStart <= last and isWhitespaceByte(byte(value, topStart)) do
							hadSpace = true
							topStart += 1
						end
						if hadSpace and layerStart <= close - 1 and topStart <= last then
							local layerOk, layerLog = parseFiniteNumericRange(value, layerStart, close - 1)
							local topOk, top = parseFiniteNumericRange(value, topStart, last)
							if layerOk and topOk and layerLog ~= nil and top ~= nil then
								return NanoFormat.fromLayerLog10(layerLog, top, negative, reciprocal)
							end
						end
					end
				end
			else
				-- Direct layer count: e^X Y
				local split = 0
				for i = tokenStart, last do
					if isWhitespaceByte(byte(value, i)) then
						split = i
						break
					end
				end
				if split ~= 0 and tokenStart <= split - 1 then
					local topStart = split
					while topStart <= last and isWhitespaceByte(byte(value, topStart)) do
						topStart += 1
					end
					if topStart <= last then
						local layerOk, layer, layerLog = parseFiniteNumericRange(value, tokenStart, split - 1)
						local topOk, top = parseFiniteNumericRange(value, topStart, last)
						if layerOk and topOk and top ~= nil then
							if layer ~= nil and layer ~= huge then
								return NanoFormat.fromLayer(layer, top, negative, reciprocal)
							elseif layerLog ~= nil then
								return NanoFormat.fromLayerLog10(layerLog, top, negative, reciprocal)
							end
						end
					end
				end
			end
		else
			-- Repeated-e syntax is only valid with at least two e's.
			local p = first
			while p <= last and asciiLowerByte(byte(value, p)) == 101 do
				p += 1
			end
			local layer = p - first
			if layer >= 2 and p <= last then
				local topOk, top = parseFiniteNumericRange(value, p, last)
				if topOk and top ~= nil then
					return NanoFormat.fromLayer(layer, top, negative, reciprocal)
				end
			end
		end
	end

	-- Suffix syntax. If the fast dispatcher already found a scientific exponent
	-- marker, skip suffix normalization/scanning entirely.
	if hintedEPos == 0 then
		local suffixKind = normalizeSuffixType(suffixType)
		if suffixKind ~= "scientific" and suffixKind ~= "engineering" then
			local suffixStart = last + 1
			local i = last
			while i >= first do
				c = byte(value, i)
				if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
					suffixStart = i
					i -= 1
				else
					break
				end
			end

			if suffixStart <= last and suffixStart > first then
				local index = suffixIndexRange(value, suffixStart, last, suffixKind)
				if index ~= nil then
					local valid, mantissaNegative, zero, _, mantissaLog =
						parseDecimalRange(value, first, suffixStart - 1, false)
					if valid and mantissaLog ~= nil then
						local finalNegative = negative ~= mantissaNegative
						if zero then
							if reciprocal then
								return makeSpecial(finalNegative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
							end
							return makeTiny(0)
						end
						local signedLog = index * 3 + mantissaLog
						if reciprocal then
							signedLog = -signedLog
						end
						return fromSignedLogSmart(signedLog, finalNegative)
					end
				end
			end
		end
	end

	-- Scientific syntax. Reuse the pre-dispatch exponent position when one was
	-- already found so huge/tiny scientific strings are not scanned twice.
	local ePos = hintedEPos
	if ePos == 0 or ePos < first or ePos > last then
		ePos = 0
		for i = first, last do
			c = byte(value, i)
			if c == 101 or c == 69 then
				if ePos ~= 0 then
					return makeSpecial(SPECIAL_NAN)
				end
				ePos = i
			end
		end
	else
		-- parseScientificExponentRange() validates every exponent byte, so a
		-- second e/E will be rejected there without a second pre-scan.
	end

	if ePos ~= 0 then
		local valid = true
		local mantissaNegative = false
		local zero = false
		local mantissaLog: number? = nil

		-- The overwhelmingly common symbolic scientific case is "1e...".
		-- Avoid the general decimal scanner for a one-digit mantissa.
		if ePos == first + 1 then
			local digitByte = byte(value, first)
			if digitByte >= 48 and digitByte <= 57 then
				local digit = digitByte - 48
				if digit == 0 then
					zero = true
					mantissaLog = -huge
				else
					mantissaLog = DIGIT_LOG10[digit]
				end
			else
				valid = false
			end
		else
			local parsedValid, parsedNegative, parsedZero, _, parsedLog =
				parseDecimalRange(value, first, ePos - 1, false)
			valid = parsedValid
			mantissaNegative = parsedNegative
			zero = parsedZero
			mantissaLog = parsedLog
		end

		if not valid or mantissaLog == nil then
			return makeSpecial(SPECIAL_NAN)
		end
		local finalNegative = negative ~= mantissaNegative
		if zero then
			if reciprocal then
				return makeSpecial(finalNegative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
			end
			return makeTiny(0)
		end

		local directExponent, exponentSign, exponentLog10 =
			parseScientificExponentRange(value, ePos + 1, last)

		if directExponent ~= nil then
			local totalLog = directExponent + mantissaLog
			if reciprocal then
				totalLog = -totalLog
			end
			return fromSignedLogSmart(totalLog, finalNegative)
		end

		if exponentSign ~= nil and exponentLog10 ~= nil then
			local isReciprocal = exponentSign < 0
			if reciprocal then
				isReciprocal = not isReciprocal
			end
			return NanoFormat.fromLayer(2, exponentLog10, finalNegative, isReciprocal)
		end

		return makeSpecial(SPECIAL_NAN)
	end

	-- Plain decimal fallback. Unlike tonumber(), this preserves values beyond
	-- normal floating-point range by converting them to a logarithmic record.
	local valid, innerNegative, zero, directAbs, decimalLog =
		parseDecimalRange(value, first, last)
	if not valid or decimalLog == nil then
		return makeSpecial(SPECIAL_NAN)
	end

	local finalNegative = negative ~= innerNegative
	if zero then
		if reciprocal then
			return makeSpecial(finalNegative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		end
		return makeTiny(0)
	end

	if not reciprocal and directAbs ~= nil then
		return NanoFormat.fromNumber(finalNegative and -directAbs or directAbs)
	end

	local signedLog = reciprocal and -decimalLog or decimalLog
	return fromSignedLogSmart(signedLog, finalNegative)
end

local function scalarEndFast(data: buffer, bitOffset: number, limit: number): number
	if bitOffset < 0 or bitOffset + 1 > limit then
		error("NanoFormat: truncated scalar")
	end

	-- Exact scalar headers are seven bits total: approximate flag + 6-bit
	-- payload length. Reading them together avoids two buffer.readbits calls.
	local headerBits = min(7, limit - bitOffset)
	local header = bufferReadBits(data, bitOffset, headerBits)

	if band(header, 1) == 0 then
		if headerBits < 7 then
			error("NanoFormat: truncated exact scalar")
		end
		local n = floor(header / 2)
		if n > 53 then
			error("NanoFormat: invalid exact scalar bit length")
		end
		local nextBit = bitOffset + 7 + n
		if nextBit > limit then
			error("NanoFormat: truncated exact scalar payload")
		end
		return nextBit
	end

	local nextBit = bitOffset + SCALAR_APPROX_BITS
	if nextBit > limit then
		error("NanoFormat: truncated approximate scalar")
	end

	-- approximate flag + 10-bit exponent can also be read in one operation.
	local head11 = bufferReadBits(data, bitOffset, 11)
	local expCode = floor(head11 / 2)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then
		error("NanoFormat: invalid scalar exponent code")
	end
	return nextBit
end
local function recordEndFast(data: buffer, bitOffset: number, limit: number?): number
	local physicalLimit = bufferLen(data) * 8
	local endLimit = limit or physicalLimit
	if endLimit > physicalLimit or bitOffset < 0 or bitOffset + 6 > endLimit then
		error("NanoFormat: truncated record")
	end

	local raw = bufferReadBits(data, bitOffset, 6)

	if band(raw, 1) == 0 then
		local nextBit = bitOffset + 8
		if nextBit > endLimit then error("NanoFormat: truncated tiny record") end
		return nextBit
	end

	if band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		if nextBit > endLimit then error("NanoFormat: truncated negative-small record") end
		return nextBit
	end

	if band(raw, 7) == 3 then
		-- Prefix(3) + sign(1) + five-bit length fit in nine bits. Pull the
		-- entire header in one read instead of reading the length separately.
		if bitOffset + 9 > endLimit then
			error("NanoFormat: truncated integer length")
		end
		local header9 = bufferReadBits(data, bitOffset, 9)
		local n = floor(header9 / 16)
		local headerEnd = bitOffset + 9
		if n == 0 then
			if bitOffset + 14 > endLimit then
				error("NanoFormat: truncated extended integer length")
			end
			local header14 = bufferReadBits(data, bitOffset, 14)
			n = 32 + floor(header14 / 512)
			headerEnd = bitOffset + 14
			if n > MAX_INTEGER_MODE_BITS then
				error("NanoFormat: invalid extended integer bit length")
			end
		end
		local nextBit = headerEnd + n
		if nextBit > endLimit then
			error("NanoFormat: truncated integer payload")
		end
		return nextBit
	end

	if band(raw, 15) == 7 then
		local nextBit = bitOffset + NORMAL_BITS
		if nextBit > endLimit then
			error("NanoFormat: truncated normal record")
		end
		-- Prefix(4) + sign + exponent fit in 15 bits.
		local header15 = bufferReadBits(data, bitOffset, 15)
		local expCode = floor(header15 / 32)
		if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
			error("NanoFormat: invalid normal exponent code")
		end
		return nextBit
	end

	if band(raw, 31) == 15 then
		return scalarEndFast(data, bitOffset + 7, endLimit)
	end

	if band(raw, 63) == 31 then
		local fieldStart = bitOffset + 8
		if fieldStart + 1 > endLimit then
			error("NanoFormat: truncated layer field")
		end

		local topStart
		if bufferReadBits(data, fieldStart, 1) == 0 then
			topStart = fieldStart + 6
			if topStart > endLimit then
				error("NanoFormat: truncated direct layer field")
			end
		else
			if fieldStart + 2 > endLimit then
				error("NanoFormat: truncated extended layer field")
			end
			topStart = scalarEndFast(data, fieldStart + 2, endLimit)
		end

		return scalarEndFast(data, topStart, endLimit)
	end

	local nextBit = bitOffset + 8
	if nextBit > endLimit then
		error("NanoFormat: truncated special record")
	end
	return nextBit
end
-- Non-throwing structural scanner used by safety APIs.  This is intentionally
-- separate from recordEndFast(): normal APIs keep the throwing/direct path,
-- while try*/validation APIs avoid pcall on well-formed data.
local function scalarEndChecked(data: buffer, bitOffset: number, limit: number): number?
	if bitOffset < 0 or bitOffset + 1 > limit then
		return nil
	end

	local headerBits = min(7, limit - bitOffset)
	local header = bufferReadBits(data, bitOffset, headerBits)
	if band(header, 1) == 0 then
		if headerBits < 7 then
			return nil
		end
		local n = floor(header / 2)
		if n > 53 then
			return nil
		end
		local nextBit = bitOffset + 7 + n
		return nextBit <= limit and nextBit or nil
	end

	local nextBit = bitOffset + SCALAR_APPROX_BITS
	if nextBit > limit then
		return nil
	end
	local head11 = bufferReadBits(data, bitOffset, 11)
	local expCode = floor(head11 / 2)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then
		return nil
	end
	return nextBit
end

local function recordEndChecked(data: buffer, bitOffset: number, limit: number?): number?
	local physicalLimit = bufferLen(data) * 8
	local endLimit = limit or physicalLimit
	if endLimit > physicalLimit or bitOffset < 0 or bitOffset + 6 > endLimit then
		return nil
	end

	local raw = bufferReadBits(data, bitOffset, 6)
	if band(raw, 1) == 0 or band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		return nextBit <= endLimit and nextBit or nil
	end

	if band(raw, 7) == 3 then
		if bitOffset + 9 > endLimit then
			return nil
		end
		local header9 = bufferReadBits(data, bitOffset, 9)
		local n = floor(header9 / 16)
		local headerEnd = bitOffset + 9
		if n == 0 then
			if bitOffset + 14 > endLimit then
				return nil
			end
			local header14 = bufferReadBits(data, bitOffset, 14)
			n = 32 + floor(header14 / 512)
			headerEnd = bitOffset + 14
			if n > MAX_INTEGER_MODE_BITS then
				return nil
			end
		end
		local nextBit = headerEnd + n
		return nextBit <= endLimit and nextBit or nil
	end

	if band(raw, 15) == 7 then
		local nextBit = bitOffset + NORMAL_BITS
		if nextBit > endLimit then
			return nil
		end
		local header15 = bufferReadBits(data, bitOffset, 15)
		local expCode = floor(header15 / 32)
		return expCode <= NORMAL_EXP_MAX + NORMAL_EXP_BIAS and nextBit or nil
	end

	if band(raw, 31) == 15 then
		return scalarEndChecked(data, bitOffset + 7, endLimit)
	end

	if band(raw, 63) == 31 then
		local fieldStart = bitOffset + 8
		if fieldStart + 1 > endLimit then
			return nil
		end

		local topStart
		if bufferReadBits(data, fieldStart, 1) == 0 then
			topStart = fieldStart + 6
			if topStart > endLimit then
				return nil
			end
		else
			if fieldStart + 2 > endLimit then
				return nil
			end
			topStart = scalarEndChecked(data, fieldStart + 2, endLimit)
			if topStart == nil then
				return nil
			end
		end
		return scalarEndChecked(data, topStart, endLimit)
	end

	local nextBit = bitOffset + 8
	return nextBit <= endLimit and nextBit or nil
end

local function readUIntExactAtFast(data: buffer, bitOffset: number, count: number): number
	if count <= 0 then
		return 0
	end
	if count <= 26 then
		return bufferReadBits(data, bitOffset, count)
	end

	local value = bufferReadBits(data, bitOffset, 26)
	local remaining = count - 26
	if remaining <= 26 then
		return value + bufferReadBits(data, bitOffset + 26, remaining) * 67108864
	end

	value += bufferReadBits(data, bitOffset + 26, 26) * 67108864
	return value + bufferReadBits(data, bitOffset + 52, remaining - 26) * 4503599627370496
end

local function readScalarAtFast(data: buffer, bitOffset: number): (number, number)
	local approximate = bufferReadBits(data, bitOffset, 1)
	if approximate == 0 then
		local n = bufferReadBits(data, bitOffset + 1, EXACT_LEN_BITS)
		if n > 53 then
			error("NanoFormat: invalid exact scalar bit length")
		end
		return readUIntExactAtFast(data, bitOffset + 1 + EXACT_LEN_BITS, n),
			bitOffset + 1 + EXACT_LEN_BITS + n
	end

	local expCode = bufferReadBits(data, bitOffset + 1, SCALAR_EXP_BITS)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then
		error("NanoFormat: invalid scalar exponent code")
	end
	local mantCode = bufferReadBits(data, bitOffset + 1 + SCALAR_EXP_BITS, SCALAR_MANT_BITS)
	local exponent = expCode - SCALAR_EXP_BIAS
	return decodeMantissa(mantCode, SCALAR_MANT_MAX) * (10 ^ exponent),
		bitOffset + SCALAR_APPROX_BITS
end

local function readLayerFieldAtFast(data: buffer, bitOffset: number): (number, boolean, number)
	if bufferReadBits(data, bitOffset, 1) == 0 then
		return bufferReadBits(data, bitOffset + 1, 5) + 2, false, bitOffset + 6
	end

	local layerIsLog = bufferReadBits(data, bitOffset + 1, 1) == 1
	local layer, nextBit = readScalarAtFast(data, bitOffset + 2)
	return layer, layerIsLog, nextBit
end

local function decodeAt(data: buffer, bitOffset: number): (DecodedValue, number)
	local totalBits = bufferLen(data) * 8
	if bitOffset < 0 or bitOffset + 6 > totalBits then
		error("NanoFormat: truncated record")
	end

	local raw = bufferReadBits(data, bitOffset, 6)

	if band(raw, 1) == 0 then
		local nextBit = bitOffset + 8
		if nextBit > totalBits then error("NanoFormat: truncated tiny record") end
		return {Kind = "Integer", Value = bufferReadBits(data, bitOffset + 1, 7), Negative = false}, nextBit
	end

	if band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		if nextBit > totalBits then error("NanoFormat: truncated negative-small record") end
		return {Kind = "Integer", Value = -(bufferReadBits(data, bitOffset + 2, 6) + 1), Negative = true}, nextBit
	end

	if band(raw, 7) == 3 then
		if bitOffset + 9 > totalBits then error("NanoFormat: truncated integer length") end
		local header9 = bufferReadBits(data, bitOffset, 9)
		local negative = band(header9, 8) ~= 0
		local n = floor(header9 / 16)
		local payloadOffset = bitOffset + 9
		if n == 0 then
			if bitOffset + 14 > totalBits then error("NanoFormat: truncated extended integer length") end
			local header14 = bufferReadBits(data, bitOffset, 14)
			n = 32 + floor(header14 / 512)
			payloadOffset = bitOffset + 14
			if n > MAX_INTEGER_MODE_BITS then
				error("NanoFormat: invalid extended integer bit length")
			end
		end
		local nextBit = payloadOffset + n
		if nextBit > totalBits then error("NanoFormat: truncated integer payload") end
		local magnitude = readUIntExactAtFast(data, payloadOffset, n)
		return {Kind = "Integer", Value = negative and -magnitude or magnitude, Negative = negative}, nextBit
	end

	if band(raw, 15) == 7 then
		local nextBit = bitOffset + NORMAL_BITS
		if nextBit > totalBits then error("NanoFormat: truncated normal record") end
		local header15 = bufferReadBits(data, bitOffset, 15)
		local negative = band(header15, 16) ~= 0
		local expCode = floor(header15 / 32)
		if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
			error("NanoFormat: invalid normal exponent code")
		end
		local mantCode = bufferReadBits(data, bitOffset + 15, NORMAL_MANT_BITS)
		return {
			Kind = "Normal", Negative = negative,
			Exponent = expCode - NORMAL_EXP_BIAS,
			Mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX),
		}, nextBit
	end

	if band(raw, 31) == 15 then
		if bitOffset + 7 > totalBits then error("NanoFormat: truncated log header") end
		local header7 = bufferReadBits(data, bitOffset, 7)
		local negative = band(header7, 32) ~= 0
		local reciprocal = band(header7, 64) ~= 0
		local top, nextBit = readScalarAtFast(data, bitOffset + 7)
		if nextBit > totalBits then error("NanoFormat: truncated log scalar") end
		return {Kind = "Log", Negative = negative, Reciprocal = reciprocal, Layer = 1, Top = top}, nextBit
	end

	if band(raw, 63) == 31 then
		if bitOffset + 9 > totalBits then error("NanoFormat: truncated layer header") end
		local header8 = bufferReadBits(data, bitOffset, 8)
		local negative = band(header8, 64) ~= 0
		local reciprocal = band(header8, 128) ~= 0
		local fieldOffset = bitOffset + 8
		local firstFieldBit = bufferReadBits(data, fieldOffset, 1)
		local layer, layerIsLog, topOffset
		if firstFieldBit == 0 then
			if fieldOffset + 6 > totalBits then error("NanoFormat: truncated direct layer field") end
			local field6 = bufferReadBits(data, fieldOffset, 6)
			layer = floor(field6 / 2) + 2
			layerIsLog = false
			topOffset = fieldOffset + 6
		else
			if fieldOffset + 2 > totalBits then error("NanoFormat: truncated extended layer field") end
			local field2 = bufferReadBits(data, fieldOffset, 2)
			layerIsLog = band(field2, 2) ~= 0
			layer, topOffset = readScalarAtFast(data, fieldOffset + 2)
			if topOffset > totalBits then error("NanoFormat: truncated layer scalar") end
		end
		local top, nextBit = readScalarAtFast(data, topOffset)
		if nextBit > totalBits then error("NanoFormat: truncated layer top") end
		return {
			Kind = "Layer", Negative = negative, Reciprocal = reciprocal,
			Layer = layerIsLog and nil or layer,
			LayerLog10 = layerIsLog and layer or nil,
			LayerIsLog = layerIsLog, Top = top,
		}, nextBit
	end

	local nextBit = bitOffset + 8
	if nextBit > totalBits then error("NanoFormat: truncated special record") end
	local special = bufferReadBits(data, bitOffset + 6, 2)
	if special == SPECIAL_POS_INF then
		return {Kind = "Infinity", Negative = false}, nextBit
	elseif special == SPECIAL_NEG_INF then
		return {Kind = "Infinity", Negative = true}, nextBit
	elseif special == SPECIAL_NAN then
		return {Kind = "NaN", Negative = false}, nextBit
	end
	return {Kind = "Reserved", Negative = false}, nextBit
end

NanoFormat.decodeAt = decodeAt

function NanoFormat.tryDecodeAt(data: buffer, bitOffset: number?): (boolean, DecodedValue?, number?)
	if typeof(data) ~= "buffer" then
		return false, nil, nil
	end
	local offset: any = if bitOffset == nil then 0 else bitOffset
	-- V0.5.2: try* APIs must never throw just because a dynamically-typed caller
	-- supplied a bad offset. Reject NaN/fractional/non-number offsets up front.
	if typeof(offset) ~= "number" or offset ~= offset or offset ~= floor(offset)
		or offset < 0 or offset >= bufferLen(data) * 8
	then
		return false, nil, nil
	end
	local ok, decoded, nextBit = fastPcall(decodeAt, data, offset)
	if not ok then
		return false, nil, nil
	end
	return true, decoded, nextBit
end

local function zeroPadding(value: buffer, startBit: number): boolean
	local totalBits = bufferLen(value) * 8
	local remaining = totalBits - startBit
	local offset = startBit
	while remaining > 0 do
		local chunk = min(32, remaining)
		if bufferReadBits(value, offset, chunk) ~= 0 then
			return false
		end
		offset += chunk
		remaining -= chunk
	end
	return true
end

function NanoFormat.isValid(value: buffer): boolean
	if typeof(value) ~= "buffer" then
		return false
	end

	-- PATH 0: validate the structure directly; do not decode/allocate a component
	-- table and do not enter pcall for ordinary valid buffers.
	local physicalBits = bufferLen(value) * 8
	local nextBit = recordEndChecked(value, 0, physicalBits)
	if nextBit == nil then
		return false
	end

	local raw = bufferReadBits(value, 0, 6)
	if band(raw, 63) == 63 and bufferReadBits(value, 6, 2) == SPECIAL_RESERVED then
		return false
	end
	return zeroPadding(value, nextBit)
end

function NanoFormat.components(value: buffer): DecodedValue
	local data = decodeAt(value, 0)
	return data
end

function NanoFormat.bitLength(value: buffer): number
	local cached = BIT_LENGTH_CACHE[value]
	if cached ~= nil then
		return cached
	end
	local physicalBits = bufferLen(value) * 8
	if physicalBits == 8 then
		return 8
	end
	local bits = recordEndFast(value, 0, physicalBits)
	if bits ~= physicalBits then
		BIT_LENGTH_CACHE[value] = bits
	end
	return bits
end

NanoFormat.byteLength = bufferLen

local FIXED_FORMATS = {
	"%.0f", "%.1f", "%.2f", "%.3f", "%.4f", "%.5f", "%.6f",
	"%.7f", "%.8f", "%.9f", "%.10f", "%.11f", "%.12f",
}

local function trimZeros(value: string): string
	local dot = string.find(value, ".", 1, true)
	if not dot then
		return value
	end

	local i = #value
	while i > dot and byte(value, i) == 48 do
		i -= 1
	end
	if i == dot then
		i -= 1
	end
	return sub(value, 1, i)
end

NanoFormat.FORMAT_SCOPE_VERSION = 1

-- Formatter internals are isolated in a dedicated register frame.
-- Public NanoFormat.format* functions are installed from inside this scope.
(function()
	local function shortNumber(value: number, precision: number): string
		if value == 0 then
			return "0"
		end
		local exponent = floor(log10(abs(value)))
		local decimals = clamp(precision - exponent - 1, 0, 12)
		return trimZeros(format(FIXED_FORMATS[decimals + 1], value))
	end

	local function scientificText(mantissa: number, exponent: number, precision: number): string
		if mantissa >= 10 then
			mantissa /= 10
			exponent += 1
		elseif mantissa > 0 and mantissa < 1 then
			mantissa *= 10
			exponent -= 1
		end
		return shortNumber(mantissa, precision) .. "e" .. toString(exponent)
	end

	local function roundsTo1000(value: number, precision: number): boolean
		-- shortNumber() uses significant-digit-style fixed formatting. Determine
		-- promotion numerically so suffix/engineering formatting does not allocate a
		-- string and immediately feed it back through tonumber().
		if value < 999 then
			return false
		end
		local exponent = floor(log10(value))
		local decimals = clamp(precision - exponent - 1, 0, 12)
		return value >= 1000 - 0.5 * (10 ^ -decimals)
	end

	local function engineeringText(mantissa: number, exponent: number, precision: number): string
		local engineeringExponent = floor(exponent / 3) * 3
		local scaled = mantissa * (10 ^ (exponent - engineeringExponent))
		if roundsTo1000(scaled, precision) then
			scaled /= 1000
			engineeringExponent += 3
		end
		return shortNumber(scaled, precision) .. "e" .. toString(engineeringExponent)
	end

	local function commaIntegerText(value: number): string
		if value ~= floor(value) or abs(value) > 9007199254740991 then
			return toString(value)
		end
		local negative = value < 0
		local text = toString(abs(value))
		local length = #text
		if length <= 3 then
			return negative and ("-" .. text) or text
		end
		local firstGroup = length % 3
		if firstGroup == 0 then firstGroup = 3 end
		local out = sub(text, 1, firstGroup)
		local i = firstGroup + 1
		while i <= length do
			out ..= "," .. sub(text, i, i + 2)
			i += 3
		end
		return negative and ("-" .. out) or out
	end

	local function compactExponentValueText(exponent: number, precision: number): string
		local negative = exponent < 0
		local magnitude = abs(exponent)

		if magnitude < 1e6 then
			return commaIntegerText(exponent)
		end

		if magnitude > 0 and magnitude <= 1e308 then
			local decimalExponent = floor(log10(magnitude))
			local group = floor(decimalExponent / 3)
			local suffix = coordinateSuffixForIndex(group)

			if suffix ~= nil then
				local scaled = magnitude / (10 ^ (group * 3))
				local rendered = shortNumber(scaled, clamp(precision, 3, 8))
				return (negative and "-" or "") .. rendered .. suffix
			end
		end

		return commaIntegerText(exponent)
	end

	local function exponentCompactText(mantissa: number, exponent: number, precision: number): string
		if mantissa >= 10 then
			mantissa /= 10
			exponent += 1
		elseif mantissa > 0 and mantissa < 1 then
			mantissa *= 10
			exponent -= 1
		end

		local rendered = shortNumber(mantissa, precision)
		if rendered == "10" then
			rendered = "1"
			exponent += 1
		end

		return (rendered == "1" and "" or rendered)
			.. "E"
			.. compactExponentValueText(exponent, precision)
	end

	local function suffixText(
		mantissa: number,
		exponent: number,
		precision: number,
		suffixType: string
	): string?
		if exponent < 3 then
			return nil
		end

		local index = floor(exponent / 3)
		local suffix = suffixForIndex(index, suffixType)
		if suffix == nil then
			return nil
		end

		local scaled = mantissa * (10 ^ (exponent - index * 3))

		-- Formatting can round 999.99k to 1000k. Promote before formatting, avoiding
		-- the previous shortNumber -> tonumber -> shortNumber round trip.
		if roundsTo1000(scaled, precision) then
			local nextSuffix = suffixForIndex(index + 1, suffixType)
			if nextSuffix ~= nil then
				return shortNumber(scaled / 1000, precision) .. nextSuffix
			end
			local promotedExponent = (index + 1) * 3
			if suffixType == "extended" and promotedExponent >= NanoFormat.E_NOTATION_START then
				return exponentCompactText(scaled / 1000, promotedExponent, precision)
			end
			return scientificText(scaled / 1000, promotedExponent, precision)
		end

		return shortNumber(scaled, precision) .. suffix
	end

	local function formatPower10(exponent: number, precision: number, suffixType: string): string
		if suffixType == "exponent" then
			local integerExponent = floor(exponent)
			return exponentCompactText(10 ^ (exponent - integerExponent), integerExponent, precision)
		elseif (suffixType == "standard" or suffixType == "extended") and exponent >= NanoFormat.E_NOTATION_START then
			local integerExponent = floor(exponent)
			return exponentCompactText(10 ^ (exponent - integerExponent), integerExponent, precision)
		elseif suffixType == "scientific" then
			if exponent == floor(exponent) then
				return "1e" .. toString(floor(exponent))
			end
			local integerExponent = floor(exponent)
			return scientificText(10 ^ (exponent - integerExponent), integerExponent, precision)
		elseif suffixType == "engineering" then
			local integerExponent = floor(exponent)
			return engineeringText(10 ^ (exponent - integerExponent), integerExponent, precision)
		end

		if exponent == floor(exponent) then
			local ie = floor(exponent)
			if ie >= 0 and ie <= 2 then
				return toString(10 ^ ie)
			end
			if ie >= 3 then
				local rendered = suffixText(1, ie, precision, suffixType)
				if rendered ~= nil then
					return rendered
				end
			end
			return "1e" .. toString(ie)
		end

		local integerExponent = floor(exponent)
		local mantissa = 10 ^ (exponent - integerExponent)
		local rendered = suffixText(mantissa, integerExponent, precision, suffixType)
		if rendered ~= nil then
			return rendered
		end
		return scientificText(mantissa, integerExponent, precision)
	end

	local function formatNormalParts(
		mantissa: number,
		exponent: number,
		precision: number,
		suffixType: string
	): string
		if suffixType == "exponent" then
			return exponentCompactText(mantissa, exponent, precision)
		elseif (suffixType == "standard" or suffixType == "extended") and exponent >= NanoFormat.E_NOTATION_START then
			return exponentCompactText(mantissa, exponent, precision)
		elseif suffixType == "scientific" then
			return scientificText(mantissa, exponent, precision)
		elseif suffixType == "engineering" then
			return engineeringText(mantissa, exponent, precision)
		end

		if exponent < 0 then
			local positiveExponent = -exponent
			local inverseMantissa = 10 / mantissa
			local inverseExponent = positiveExponent - 1
			if inverseExponent >= 0 then
				return "1/" .. formatNormalParts(inverseMantissa, inverseExponent, precision, suffixType)
			end
		end

		if exponent >= 0 and exponent < 3 then
			return shortNumber(mantissa * (10 ^ exponent), precision)
		end

		if exponent >= 3 then
			local rendered = suffixText(mantissa, exponent, precision, suffixType)
			if rendered ~= nil then
				return rendered
			end
		end

		return scientificText(mantissa, exponent, precision)
	end

	local function formatLargeScalar(value: number, precision: number): string
		if value < 1e6 then
			if value == floor(value) then
				return toString(value)
			end
			return shortNumber(value, precision)
		end
		local exponent = floor(log10(value))
		local mantissa = value / (10 ^ exponent)
		return scientificText(mantissa, exponent, precision)
	end


	-- Compact scalar rendering used by L notation. It intentionally uses the
	-- Standard suffix table for the coordinates regardless of the outer formatter
	-- mode, preserving the original flat L3 1k / L1M 1k representation.
	local function compactLayerScalarText(value: number, precision: number): string
		if value == 0 then
			return "0"
		end

		local negative = value < 0
		local magnitude = abs(value)

		if magnitude < 1000 then
			local body = if magnitude == floor(magnitude)
				then toString(magnitude)
				else shortNumber(magnitude, precision)
			return negative and ("-" .. body) or body
		end

		local exponent = floor(log10(magnitude))
		local index = floor(exponent / 3)
		local suffix = coordinateSuffixForIndex(index)

		if suffix ~= nil then
			local scaled = magnitude / (10 ^ (index * 3))
			if roundsTo1000(scaled, precision) then
				local nextSuffix = coordinateSuffixForIndex(index + 1)
				if nextSuffix ~= nil then
					local body = shortNumber(scaled / 1000, precision) .. nextSuffix
					return negative and ("-" .. body) or body
				end
			end

			local body = shortNumber(scaled, precision) .. suffix
			return negative and ("-" .. body) or body
		end

		local body = scientificText(
			magnitude / (10 ^ exponent), exponent, precision
		)
		return negative and ("-" .. body) or body
	end

	local function layerNotationText(
		layer: number,
		layerIsLog: boolean,
		top: number,
		precision: number
	): string
		local topText = compactLayerScalarText(top, precision)

		if layerIsLog then
			return "L(10^"
				.. compactLayerScalarText(layer, precision)
				.. ") "
				.. topText
		end

		return "L"
			.. compactLayerScalarText(layer, precision)
			.. " "
			.. topText
	end


	-- Roman numeral formatter -----------------------------------------------------
	-- Roman V1 is display-only. It does not alter NanoFormat's binary codec,
	-- parser, leaderboard mapping, or arithmetic representation.
	--
	-- "roman"         : classical Roman numerals for |n| <= 3999.
	-- "romanextended" : parenthesized x1000 groups up to MAX_SAFE_INTEGER.
	--                     Example: 4,000 -> (IV), 1,000,000 -> ((I)).
	--
	-- Zero is rendered as N (nulla). Negative integers use a leading '-'.
	-- Non-integers and values outside the selected Roman range fall back to the
	-- existing standard NanoFormat formatter.
	local formatRomanInteger

	do
		local VALUES = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1}
		local SYMBOLS = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"}

		local function classicalPositive(value: number): string
			local parts = table.create(16)
			local count = 0
			local remaining = value

			for i = 1, #VALUES do
				local unit = VALUES[i]
				while remaining >= unit do
					remaining -= unit
					count += 1
					parts[count] = SYMBOLS[i]
				end
				if remaining == 0 then
					break
				end
			end

			return table.concat(parts, "", 1, count)
		end

		local function extendedPositive(value: number): string
			if value <= NanoFormat.ROMAN_CLASSICAL_MAX then
				return classicalPositive(value)
			end

			-- Canonical extended notation uses base-1000 Roman groups. Each pair of
			-- parentheses multiplies that group by another 1000:
			--   4,000 -> (IV), 1,000,000 -> ((I)), 4,999 -> (IV)CMXCIX.
			local groups = table.create(6)
			local count = 0
			local remaining = value
			local depth = 0

			while remaining > 0 do
				local nextValue = floor(remaining / 1000)
				local group = remaining - nextValue * 1000

				if group ~= 0 then
					local rendered = classicalPositive(group)
					if depth > 0 then
						local open = string.rep("(", depth)
						local close = string.rep(")", depth)
						rendered = open .. rendered .. close
					end
					count += 1
					groups[count] = rendered
				end

				remaining = nextValue
				depth += 1
			end

			-- Groups were produced from least-significant to most-significant.
			local ordered = table.create(count)
			for i = 1, count do
				ordered[i] = groups[count - i + 1]
			end
			return table.concat(ordered, "", 1, count)
		end

		formatRomanInteger = function(integer: number, extended: boolean): string?
			if integer ~= floor(integer) or abs(integer) > NanoFormat.ROMAN_EXTENDED_MAX then
				return nil
			end

			if integer == 0 then
				return "N"
			end

			local negative = integer < 0
			local magnitude = negative and -integer or integer

			if not extended and magnitude > NanoFormat.ROMAN_CLASSICAL_MAX then
				return nil
			end

			local rendered = if extended
				then extendedPositive(magnitude)
				else classicalPositive(magnitude)

			return negative and ("-" .. rendered) or rendered
		end
	end

	local function formatIntegerValue(integer: number, precision: number, suffixKind: string): string
		if suffixKind == "roman" or suffixKind == "romanextended" then
			local roman = formatRomanInteger(integer, suffixKind == "romanextended")
			if roman ~= nil then
				return roman
			end
			-- Roman is intentionally display-only. Unsupported values retain the
			-- established NanoFormat behavior instead of producing invalid numerals.
			suffixKind = "standard"
		end

		local magnitude = abs(integer)
		if magnitude == 0 then
			return "0"
		end
		if magnitude < 1000 and suffixKind ~= "scientific" and suffixKind ~= "engineering" and suffixKind ~= "exponent" then
			return toString(integer)
		end
		local exponent = floor(log10(magnitude))
		local mantissa = magnitude / (10 ^ exponent)
		local rendered = formatNormalParts(mantissa, exponent, precision, suffixKind)
		return integer < 0 and ("-" .. rendered) or rendered
	end

	local function formatCoreFast(value: buffer, precision: number, suffixKind: string): string
		-- Direct prefix dispatch avoids Reader/data table allocation on formatting
		-- hot paths while preserving the public decodeAt()/components() behavior.
		local raw = bufferReadBits(value, 0, 6)

		if band(raw, 1) == 0 then
			return formatIntegerValue(bufferReadBits(value, 1, 7), precision, suffixKind)
		end

		if band(raw, 3) == 1 then
			return formatIntegerValue(-(bufferReadBits(value, 2, 6) + 1), precision, suffixKind)
		end

		if band(raw, 7) == 3 then
			local negative = bufferReadBits(value, 3, 1) == 1
			local n = bufferReadBits(value, 4, INTEGER_LEN_BITS)
			local payloadOffset = 4 + INTEGER_LEN_BITS
			if n == 0 then
				n = 32 + bufferReadBits(value, payloadOffset, 5)
				payloadOffset += 5
				if n > MAX_INTEGER_MODE_BITS then
					error("NanoFormat: invalid extended integer bit length")
				end
			end
			local magnitude = readUIntExactAtFast(value, payloadOffset, n)
			return formatIntegerValue(negative and -magnitude or magnitude, precision, suffixKind)
		end

		if band(raw, 15) == 7 then
			local negative = bufferReadBits(value, 4, 1) == 1
			local expCode = bufferReadBits(value, 5, NORMAL_EXP_BITS)
			if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
				error("NanoFormat: invalid normal exponent code")
			end
			local mantCode = bufferReadBits(value, 5 + NORMAL_EXP_BITS, NORMAL_MANT_BITS)
			local exponent = expCode - NORMAL_EXP_BIAS
			local mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX)

			if suffixKind == "roman" or suffixKind == "romanextended" then
				local numeric = mantissa * (10 ^ exponent)
				if negative then
					numeric = -numeric
				end
				local roman = formatRomanInteger(numeric, suffixKind == "romanextended")
				if roman ~= nil then
					return roman
				end
			end

			local scalarSuffix = if suffixKind == "roman" or suffixKind == "romanextended" then "standard" else suffixKind
			local rendered = formatNormalParts(mantissa, exponent, precision, scalarSuffix)
			return negative and ("-" .. rendered) or rendered
		end

		if band(raw, 31) == 15 then
			local negative = bufferReadBits(value, 5, 1) == 1
			local reciprocal = bufferReadBits(value, 6, 1) == 1
			local top = readScalarAtFast(value, 7)

			if not reciprocal and (suffixKind == "roman" or suffixKind == "romanextended") then
				local numeric = 10 ^ top
				if negative then
					numeric = -numeric
				end
				local roman = formatRomanInteger(numeric, suffixKind == "romanextended")
				if roman ~= nil then
					return roman
				end
			end

			local scalarSuffix = if suffixKind == "roman" or suffixKind == "romanextended" then "standard" else suffixKind
			local rendered
			if reciprocal and (scalarSuffix == "scientific" or scalarSuffix == "engineering") then
				rendered = formatPower10(-top, precision, scalarSuffix)
			else
				rendered = formatPower10(top, precision, scalarSuffix)
				if reciprocal then
					rendered = "1/" .. rendered
				end
			end
			return negative and ("-" .. rendered) or rendered
		end

		if band(raw, 63) == 31 then
			local negative = bufferReadBits(value, 6, 1) == 1
			local reciprocal = bufferReadBits(value, 7, 1) == 1
			local layer, layerIsLog, nextBit = readLayerFieldAtFast(value, 8)
			local top = readScalarAtFast(value, nextBit)
			local rendered

			if suffixKind == "standard"
				or suffixKind == "extended"
				or suffixKind == "exponent"
			then
				rendered = layerNotationText(layer, layerIsLog, top, precision)
			elseif layerIsLog then
				rendered = "e^(10^" .. formatLargeScalar(layer, precision) .. ") " .. formatLargeScalar(top, precision)
			elseif layer == 2 then
				rendered = "ee" .. formatLargeScalar(top, precision)
			elseif layer == 3 then
				rendered = "eee" .. formatLargeScalar(top, precision)
			else
				rendered = "e^" .. formatLargeScalar(layer, precision) .. " " .. formatLargeScalar(top, precision)
			end

			if reciprocal then
				rendered = "1/" .. rendered
			end
			return negative and ("-" .. rendered) or rendered
		end

		local special = bufferReadBits(value, 6, 2)
		if special == SPECIAL_POS_INF then
			return "inf"
		elseif special == SPECIAL_NEG_INF then
			return "-inf"
		elseif special == SPECIAL_NAN then
			return "NaN"
		end
		return "Reserved"
	end

	-- Path-zero formatter wrappers ------------------------------------------------
	-- Default/canonical calls avoid normalization and precision clamping entirely.
	function NanoFormat.format(value: buffer, precision: number?, suffixType: SuffixName?): string
		-- PATH 0: the overwhelmingly common format(value) call.
		if precision == nil and suffixType == nil then
			return formatCoreFast(value, 4, NanoFormat.DEFAULT_SUFFIX_TYPE)
		end

		local p = if precision == nil then 4 else clamp(floor(precision), 1, 8)
		if suffixType == nil then
			return formatCoreFast(value, p, NanoFormat.DEFAULT_SUFFIX_TYPE)
		end
		if NanoFormat.SUFFIX_TYPES[suffixType] == true then
			return formatCoreFast(value, p, suffixType)
		end

		-- PATH 1: alias / mixed-case suffix selection.
		return formatCoreFast(value, p, normalizeSuffixType(suffixType))
	end

	function NanoFormat.formatStandard(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "standard")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "standard")
	end

	function NanoFormat.formatExtended(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "extended")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "extended")
	end

	function NanoFormat.formatExponent(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "exponent")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "exponent")
	end

	function NanoFormat.formatHybrid(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "hybrid")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "hybrid")
	end

	function NanoFormat.formatAlphabetic(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "alphabetic")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "alphabetic")
	end

	function NanoFormat.formatMetric(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "metric")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "metric")
	end

	function NanoFormat.formatScientific(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "scientific")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "scientific")
	end

	function NanoFormat.formatEngineering(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "engineering")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "engineering")
	end


	function NanoFormat.formatRoman(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "roman")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "roman")
	end

	function NanoFormat.formatRomanExtended(value: buffer, precision: number?): string
		if precision == nil then
			return formatCoreFast(value, 4, "romanextended")
		end
		return formatCoreFast(value, clamp(floor(precision), 1, 8), "romanextended")
	end


end)()

-- Utility Formatting V1 -------------------------------------------------------
-- These are display/convenience APIs only. They do not change NanoNum's
-- adaptive buffer codec, suffix codec, or leaderboard ordering.
NanoFormat.UTILITY_SCOPE_VERSION = 1

(function()
	local function ordinaryNumber(value: any): number?
		local kind = typeof(value)
		if kind == "number" then
			return if value == value then value else nil
		elseif kind == "string" then
			return ordinaryNumber(NanoFormat.fromString(value))
		elseif kind ~= "buffer" then
			return nil
		end

		local ok, data = NanoFormat.tryDecodeAt(value, 0)
		if not ok or data == nil then
			return nil
		end
		if data.Kind == "Integer" then
			return data.Value
		elseif data.Kind == "Normal" then
			local magnitude = data.Mantissa * (10 ^ data.Exponent)
			return data.Negative and -magnitude or magnitude
		elseif data.Kind == "Log" and data.Top <= 308 then
			local exponent = data.Reciprocal and -data.Top or data.Top
			local magnitude = 10 ^ exponent
			return data.Negative and -magnitude or magnitude
		elseif data.Kind == "Infinity" then
			return data.Negative and -huge or huge
		end
		return nil
	end

	local function coerceBuffer(value: any): buffer?
		local kind = typeof(value)
		if kind == "buffer" then
			return value
		elseif kind == "number" then
			return NanoFormat.fromNumber(value)
		elseif kind == "string" then
			return NanoFormat.fromString(value)
		end
		return nil
	end

	local function fixedTrim(value: number, precision: number): string
		if precision <= 0 then
			return format("%.0f", value)
		end
		local text = format("%." .. toString(precision) .. "f", value)
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
		return text
	end

	local TIME_UNIT_SECONDS = {
		ms = 0.001,
		s = 1, sec = 1, secs = 1, second = 1, seconds = 1,
		m = 60, min = 60, mins = 60, minute = 60, minutes = 60,
		h = 3600, hr = 3600, hrs = 3600, hour = 3600, hours = 3600,
		d = 86400, day = 86400, days = 86400,
		w = 604800, week = 604800, weeks = 604800,
		y = 31557600, yr = 31557600, yrs = 31557600, year = 31557600, years = 31557600,
	}

	local function plural(value: number, singular: string, pluralWord: string): string
		return value == 1 and singular or pluralWord
	end

	-- Convert a NanoNum/string/number back to an ordinary Luau number only when
	-- its current representation can be represented by IEEE-754.
	function NanoFormat.toNumberSafe(value: MathValue): number?
		local n = ordinaryNumber(value)
		if n == nil or n ~= n or n == huge or n == -huge then
			return nil
		end
		return n
	end

	-- Format seconds as a game-friendly duration.
	-- Styles: compact (default), clock, long, seconds.
	-- Examples: 3661 -> "1h 1m 1s"; clock -> "1:01:01".
	function NanoFormat.formatTime(value: MathValue, style: TimeStyle?, precision: number?, maxParts: number?): string
		local n = ordinaryNumber(value)
		local p = if precision == nil then 2 else clamp(floor(precision), 0, 6)
		local mode = lower(style or "compact")
		local partsLimit = if maxParts == nil then 4 else max(1, floor(maxParts))

		if n == nil then
			local b = coerceBuffer(value)
			return b and (NanoFormat.format(b, 4) .. "s") or "NaN"
		elseif n ~= n then
			return "NaN"
		elseif n == huge then
			return "inf"
		elseif n == -huge then
			return "-inf"
		end

		local negative = n < 0
		local total = abs(n)
		if mode == "seconds" or mode == "raw" then
			local rendered = fixedTrim(total, p) .. "s"
			return negative and ("-" .. rendered) or rendered
		end

		local whole = floor(total)
		local fraction = total - whole
		local days = floor(whole / 86400)
		local rem = whole - days * 86400
		local hours = floor(rem / 3600)
		rem -= hours * 3600
		local minutes = floor(rem / 60)
		local seconds = rem - minutes * 60 + fraction

		if mode == "clock" or mode == "timer" then
			local roundedSeconds = tonumber(fixedTrim(seconds, p)) or seconds
			if roundedSeconds >= 60 then
				roundedSeconds -= 60
				minutes += 1
				if minutes >= 60 then
					minutes = 0
					hours += 1
					if hours >= 24 and days > 0 then
						hours -= 24
						days += 1
					end
				end
			end
			local secText
			if p == 0 then
				secText = format("%02d", roundedSeconds)
			else
				secText = format("%0" .. toString(p + 3) .. "." .. toString(p) .. "f", roundedSeconds)
			end
			local clock
			if days > 0 then
				clock = toString(days) .. "d " .. format("%02d:%02d:%s", hours, minutes, secText)
			elseif hours > 0 then
				clock = format("%d:%02d:%s", hours, minutes, secText)
			else
				clock = format("%d:%s", minutes, secText)
			end
			return negative and ("-" .. clock) or clock
		end

		-- Compact/long styles use larger calendar-like units so very long playtime
		-- does not degrade into thousands of days. One year matches parseTime's
		-- 365.25-day duration constant.
		local years = floor(whole / 31557600)
		local smartRem = whole - years * 31557600
		local weeks = floor(smartRem / 604800)
		smartRem -= weeks * 604800
		days = floor(smartRem / 86400)
		smartRem -= days * 86400
		hours = floor(smartRem / 3600)
		smartRem -= hours * 3600
		minutes = floor(smartRem / 60)
		seconds = smartRem - minutes * 60 + fraction

		local out = table.create(6)
		local count = 0
		local function push(text: string)
			if count < partsLimit then
				count += 1
				out[count] = text
			end
		end

		if mode == "long" or mode == "words" then
			if years > 0 then push(toString(years) .. " " .. plural(years, "year", "years")) end
			if weeks > 0 then push(toString(weeks) .. " " .. plural(weeks, "week", "weeks")) end
			if days > 0 then push(toString(days) .. " " .. plural(days, "day", "days")) end
			if hours > 0 then push(toString(hours) .. " " .. plural(hours, "hour", "hours")) end
			if minutes > 0 then push(toString(minutes) .. " " .. plural(minutes, "minute", "minutes")) end
			if seconds > 0 or count == 0 then
				local sec = fixedTrim(seconds, p)
				push(sec .. " " .. plural(seconds, "second", "seconds"))
			end
			local rendered = table.concat(out, ", ", 1, count)
			return negative and ("-" .. rendered) or rendered
		end

		if years > 0 then push(toString(years) .. "y") end
		if weeks > 0 then push(toString(weeks) .. "w") end
		if days > 0 then push(toString(days) .. "d") end
		if hours > 0 then push(toString(hours) .. "h") end
		if minutes > 0 then push(toString(minutes) .. "m") end
		if count < partsLimit and (seconds > 0 or count == 0) then
			if total < 1 and total > 0 and p <= 3 then
				push(fixedTrim(total * 1000, max(0, p - 1)) .. "ms")
			else
				push(fixedTrim(seconds, p) .. "s")
			end
		end
		local rendered = table.concat(out, " ", 1, count)
		return negative and ("-" .. rendered) or rendered
	end

	NanoFormat.formatDuration = NanoFormat.formatTime

	function NanoFormat.formatClock(value: MathValue, precision: number?): string
		return NanoFormat.formatTime(value, "clock", precision, 4)
	end

	-- Parse duration text into NanoNum seconds. Supported examples:
	-- "1d 2h 3m 4.5s", "250ms", "01:30", "1:02:03", "2:03:04:05".
	function NanoFormat.parseTime(text: string): buffer
		if typeof(text) ~= "string" then
			return makeSpecial(SPECIAL_NAN)
		end
		local clean = string.match(text, "^%s*(.-)%s*$")
		if clean == nil or clean == "" then
			return makeSpecial(SPECIAL_NAN)
		end

		local negative = false
		local first = string.sub(clean, 1, 1)
		if first == "+" or first == "-" then
			negative = first == "-"
			clean = string.match(string.sub(clean, 2), "^%s*(.-)%s*$") or ""
			if clean == "" then return makeSpecial(SPECIAL_NAN) end
		end

		if string.find(clean, ":", 1, true) then
			local fields = string.split(clean, ":")
			if #fields < 2 or #fields > 4 then
				return makeSpecial(SPECIAL_NAN)
			end
			local numbers = table.create(#fields)
			for i = 1, #fields do
				local n = tonumber(string.match(fields[i], "^%s*(.-)%s*$"))
				if n == nil or n ~= n or n < 0 then
					return makeSpecial(SPECIAL_NAN)
				end
				numbers[i] = n
			end
			-- Rightmost seconds/minutes are base-60. Four fields use d:h:m:s,
			-- so the hour field is additionally constrained to 0..23.
			if numbers[#fields] >= 60 or (#fields >= 3 and numbers[#fields - 1] >= 60)
				or (#fields == 4 and numbers[2] >= 24)
			then
				return makeSpecial(SPECIAL_NAN)
			end
			local total = 0
			if #fields == 2 then
				total = numbers[1] * 60 + numbers[2]
			elseif #fields == 3 then
				total = numbers[1] * 3600 + numbers[2] * 60 + numbers[3]
			else
				total = numbers[1] * 86400 + numbers[2] * 3600 + numbers[3] * 60 + numbers[4]
			end
			return NanoFormat.fromNumber(negative and -total or total)
		end

		local total = 0
		local matched = 0
		local invalid = false
		local lowered = lower(clean)
		local residue = string.gsub(lowered, "([%d]*%.?[%d]+)%s*([%a]+)", function(numberText, unitText)
			local n = tonumber(numberText)
			local multiplier = TIME_UNIT_SECONDS[unitText]
			if n == nil or multiplier == nil then
				invalid = true
				return "!"
			end
			matched += 1
			total += n * multiplier
			return ""
		end)
		residue = string.gsub(residue, "%s+", "")
		if invalid or matched == 0 or residue ~= "" then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.fromNumber(negative and -total or total)
	end

	NanoFormat.fromTime = NanoFormat.parseTime
	NanoFormat.parseDuration = NanoFormat.parseTime

	-- Format an arbitrary NanoNum as a throughput/rate label without decoding it.
	function NanoFormat.formatRate(value: MathValue, unit: string?, precision: number?, suffixType: SuffixName?): string
		local b = coerceBuffer(value)
		if b == nil then return "NaN" end
		local name = unit or "s"
		return NanoFormat.format(b, precision, suffixType) .. "/" .. name
	end

	-- Human-readable memory/data-size formatting. `binary=true` uses KiB/MiB.
	function NanoFormat.formatBytes(value: MathValue, precision: number?, binary: boolean?): string
		local n = ordinaryNumber(value)
		local p = if precision == nil then 2 else clamp(floor(precision), 0, 6)
		if n == nil then
			local b = coerceBuffer(value)
			return b and (NanoFormat.format(b, 4) .. " B") or "NaN"
		elseif n ~= n then
			return "NaN"
		elseif n == huge then
			return "inf B"
		elseif n == -huge then
			return "-inf B"
		end

		local negative = n < 0
		local magnitude = abs(n)
		local base = binary and 1024 or 1000
		local units = if binary
			then {"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}
			else {"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
		local index = 1
		while magnitude >= base and index < #units do
			magnitude /= base
			index += 1
		end
		local text = fixedTrim(magnitude, p) .. " " .. units[index]
		return negative and ("-" .. text) or text
	end

	-- Exact ordinal labels for ordinary safe integers: 1st, 2nd, 3rd, 11th.
	function NanoFormat.formatOrdinal(value: MathValue): string
		local n = ordinaryNumber(value)
		if n == nil or n ~= n or n == huge or n == -huge or n ~= floor(n) then
			local b = coerceBuffer(value)
			return b and NanoFormat.format(b) or "NaN"
		end
		local magnitude = abs(n)
		local mod100 = magnitude % 100
		local suffix = "th"
		if mod100 < 11 or mod100 > 13 then
			local mod10 = magnitude % 10
			if mod10 == 1 then suffix = "st"
			elseif mod10 == 2 then suffix = "nd"
			elseif mod10 == 3 then suffix = "rd" end
		end
		return toString(n) .. suffix
	end

	-- Signed delta display for upgrades, income changes, and stat comparisons.
	function NanoFormat.formatSigned(value: MathValue, precision: number?, suffixType: SuffixName?): string
		local b = coerceBuffer(value)
		if b == nil then return "NaN" end
		local text = NanoFormat.format(b, precision, suffixType)
		local n = ordinaryNumber(b)
		if n ~= nil then
			if n > 0 then return "+" .. text end
			return text
		end
		if text == "NaN" or text == "Reserved" or string.sub(text, 1, 1) == "-" then
			return text
		end
		return "+" .. text
	end
end)()


NanoFormat.PACK_SCOPE_VERSION = 1

-- Packing helpers also get an isolated frame so future codec helpers cannot
-- push the module chunk back toward Luau's local-register ceiling.
(function()
	local function copyBits(target: buffer, targetBit: number, source: buffer, sourceBit: number, count: number)
		if count <= 0 then
			return
		end

		-- When both sides are byte-aligned, let buffer.copy move the whole-byte
		-- prefix and only use bit operations for the final partial byte. This is
		-- especially common at the beginning of packed streams.
		if band(targetBit, 7) == 0 and band(sourceBit, 7) == 0 and count >= 8 then
			local wholeBytes = floor(count / 8)
			if wholeBytes > 0 then
				buffer.copy(target, targetBit / 8, source, sourceBit / 8, wholeBytes)
				local copiedBits = wholeBytes * 8
				targetBit += copiedBits
				sourceBit += copiedBits
				count -= copiedBits
				if count == 0 then
					return
				end
			end
		end

		-- Most remaining NanoFormat records are <= 32 useful bits.
		if count <= 32 then
			bufferWriteBits(target, targetBit, count, bufferReadBits(source, sourceBit, count))
			return
		end

		local remaining = count
		local src = sourceBit
		local dst = targetBit

		while remaining > 32 do
			bufferWriteBits(target, dst, 32, bufferReadBits(source, src, 32))
			src += 32
			dst += 32
			remaining -= 32
		end

		if remaining > 0 then
			bufferWriteBits(target, dst, remaining, bufferReadBits(source, src, remaining))
		end
	end

	local function usefulBitLengthFast(value: buffer): number
		local physicalBits = bufferLen(value) * 8
		if physicalBits == 8 then
			return 8
		end
		local cached = BIT_LENGTH_CACHE[value]
		if cached ~= nil then
			return cached
		end
		local bits = recordEndFast(value, 0, physicalBits)
		if bits ~= physicalBits then
			BIT_LENGTH_CACHE[value] = bits
		end
		return bits
	end

	function NanoFormat.packMany(values: {buffer}): (buffer, number)
		local count = #values
		local totalBits = 0

		-- First pass only computes the final allocation size. Useful bit lengths are
		-- cached on NanoFormat-produced buffers, so a second lookup is cheaper than
		-- allocating/filling a temporary lengths table on every pack.
		for i = 1, count do
			totalBits += usefulBitLengthFast(values[i])
		end

		local packed = bufferCreate(ceilBytes(totalBits))
		local offset = 0

		for i = 1, count do
			local value = values[i]
			local bits = usefulBitLengthFast(value)
			copyBits(packed, offset, value, 0, bits)
			offset += bits
		end

		return packed, totalBits
	end
	local function unpackManyCore(packed: buffer, count: number, limit: number): {buffer}
		local result = table.create(count)
		local offset = 0

		for i = 1, count do
			if offset >= limit then
				error("NanoFormat: packed stream ended before requested value count")
			end
			local nextBit = recordEndFast(packed, offset, limit)
			local bits = nextBit - offset
			local out = bufferCreate(floor((bits + 7) / 8))
			if bits <= 32 then
				bufferWriteBits(out, 0, bits, bufferReadBits(packed, offset, bits))
			else
				copyBits(out, 0, packed, offset, bits)
			end
			if band(bits, 7) ~= 0 then
				BIT_LENGTH_CACHE[out] = bits
			end
			result[i] = out
			offset = nextBit
		end

		return result
	end

	local function tryUnpackManyCore(packed: buffer, count: number, limit: number): {buffer}?
		local result = table.create(count)
		local offset = 0

		for i = 1, count do
			if offset >= limit then
				return nil
			end
			local nextBit = recordEndChecked(packed, offset, limit)
			if nextBit == nil then
				return nil
			end
			local bits = nextBit - offset
			local out = bufferCreate(floor((bits + 7) / 8))
			if bits <= 32 then
				bufferWriteBits(out, 0, bits, bufferReadBits(packed, offset, bits))
			else
				copyBits(out, 0, packed, offset, bits)
			end
			if band(bits, 7) ~= 0 then
				BIT_LENGTH_CACHE[out] = bits
			end
			result[i] = out
			offset = nextBit
		end

		return result
	end

	function NanoFormat.unpackMany(packed: buffer, count: number, totalBits: number?): {buffer}
		local physicalBits = bufferLen(packed) * 8
		local limit = totalBits or physicalBits
		if limit < 0 or limit > physicalBits then
			error("NanoFormat: invalid packed bit length")
		end
		if count < 0 or count ~= floor(count) then
			error("NanoFormat: invalid packed value count")
		end
		return unpackManyCore(packed, count, limit)
	end

	function NanoFormat.tryUnpackMany(packed: buffer, count: number, totalBits: number?): (boolean, {buffer}?)
		-- V0.5.2 runtime hardening: this remains non-throwing even when called
		-- through an `any` value with malformed arguments.
		if typeof(packed) ~= "buffer" or typeof(count) ~= "number"
			or count ~= count or count < 0 or count ~= floor(count)
		then
			return false, nil
		end
		local physicalBits = bufferLen(packed) * 8
		local limit: any = if totalBits == nil then physicalBits else totalBits
		if typeof(limit) ~= "number" or limit ~= limit or limit ~= floor(limit)
			or limit < 0 or limit > physicalBits
		then
			return false, nil
		end

		-- PATH 0: one-pass non-throwing unpack. Malformed input returns nil from the
		-- structural scanner instead of paying for pcall around the whole operation.
		local result = tryUnpackManyCore(packed, count, limit)
		if result == nil then
			return false, nil
		end
		return true, result
	end
end)()

function NanoFormat.inspect(value: buffer): InspectInfo
	local data, bits = decodeAt(value, 0)
	return {
		Version = NanoFormat.VERSION,
		Bits = bits,
		Bytes = bufferLen(value),
		PaddingBits = bufferLen(value) * 8 - bits,
		Data = data,
	}
end


-- Leaderboard codec -----------------------------------------------------------
--
-- LB is intentionally separate from NanoFormat's compact buffer serialization.
-- The buffer codec minimizes bytes; LB maps a value to a monotonic, signed,
-- 53-bit-safe integer that can be used as an OrderedDataStore / ranking key.
--
-- This is NanoFormat's own codec generation. It is not wire-compatible with
-- StrongNum LB7/LB8 even though it follows the same safe-integer envelope.
NanoFormat.LB_SCOPE_VERSION = 1

-- LB internals live in their own function frame so their constants/helpers
-- cannot consume the module chunk's 200-local Luau register budget.
-- A plain `do ... end` block is not sufficient because it shares the same
-- function register frame; this IIFE creates an actual register boundary.
(function()
	local LB_VERSION = 1
	local LB_MAX = 9007199254740991
	local LB_FINITE_MAX = LB_MAX - 1
	local LB_ONE = 4503599627370496
	local LB_POSITIVE_SPAN = min(
		LB_ONE - 1,
		LB_FINITE_MAX - LB_ONE
	)

	NanoFormat.LB_VERSION = LB_VERSION
	NanoFormat.LB_MAX = LB_MAX
	NanoFormat.LB_FINITE_MAX = LB_FINITE_MAX
	NanoFormat.LB_ONE = LB_ONE
	NanoFormat.LB_POSITIVE_SPAN = LB_POSITIVE_SPAN

	NanoFormat.LB_ORDINARY_EXACT_MAX = 10000000000000
	NanoFormat.LB_ORDINARY_SUBSLOTS = 16
	NanoFormat.LB_ORDINARY_LOG_SHARE = 0.05
	NanoFormat.LB_HUGE_LOG_SHARE = 0.15
	NanoFormat.LB_LOW_LAYER_MAX = 1000000000000
	NanoFormat.LB_LAYER_TOP_BUCKETS = 256
	NanoFormat.LB_HIGH_LAYER_SHARE = 0.25

	local LB_ORDINARY_EXACT_LOG10 = log10(NanoFormat.LB_ORDINARY_EXACT_MAX)
	local LB_ORDINARY_EXACT_SPAN =
		floor((NanoFormat.LB_ORDINARY_EXACT_MAX - 1) * NanoFormat.LB_ORDINARY_SUBSLOTS)

	local LB_ORDINARY_LOG_SPAN =
		max(1, floor(NanoFormat.LB_POSITIVE_SPAN * NanoFormat.LB_ORDINARY_LOG_SHARE))
	local LB_HUGE_LOG_SPAN =
		max(1, floor(NanoFormat.LB_POSITIVE_SPAN * NanoFormat.LB_HUGE_LOG_SHARE))

	local LB_LOW_LAYER_COUNT = NanoFormat.LB_LOW_LAYER_MAX - 1
	local LB_LOW_LAYER_SPAN =
		LB_LOW_LAYER_COUNT * NanoFormat.LB_LAYER_TOP_BUCKETS

	local LB_HIGH_LAYER_RESERVED_SPAN =
		max(1, floor(NanoFormat.LB_POSITIVE_SPAN * NanoFormat.LB_HIGH_LAYER_SHARE))
	local LB_HIGH_LAYER_BUCKET_COUNT =
		max(1, floor(LB_HIGH_LAYER_RESERVED_SPAN / NanoFormat.LB_LAYER_TOP_BUCKETS))
	local LB_HIGH_LAYER_SPAN =
		LB_HIGH_LAYER_BUCKET_COUNT * NanoFormat.LB_LAYER_TOP_BUCKETS

	local LB_ORDINARY_EXACT_START = 1
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
	local LB_LOG_LAYER_SPAN =
		max(1, NanoFormat.LB_POSITIVE_SPAN - LB_LOG_LAYER_START + 1)
	local LB_LOG_LAYER_BUCKET_COUNT =
		max(1, floor(LB_LOG_LAYER_SPAN / NanoFormat.LB_LAYER_TOP_BUCKETS))
	local LB_LOG_LAYER_USED_SPAN =
		LB_LOG_LAYER_BUCKET_COUNT * NanoFormat.LB_LAYER_TOP_BUCKETS
	local LB_LOG_LAYER_END = LB_LOG_LAYER_START + LB_LOG_LAYER_USED_SPAN - 1

	local LB_ORDINARY_LOG_DENOM = 308 - LB_ORDINARY_EXACT_LOG10
	local LB_HUGE_LOG_MIN = 308
	local LB_HUGE_LOG_DENOM = log10(1e308 / LB_HUGE_LOG_MIN)
	local LB_HIGH_LAYER_LOG_MIN = log10(NanoFormat.LB_LOW_LAYER_MAX)
	local LB_HIGH_LAYER_LOG_DENOM = 308 - LB_HIGH_LAYER_LOG_MIN
	local LB_LOG_LAYER_MIN = 308
	local LB_LOG_LAYER_DENOM = log10(1e308 / LB_LOG_LAYER_MIN)
	local LB_TOP_LOG_DENOM = 308
	local LB_DIRECT_TOP_MIN = 309
	local LB_DIRECT_TOP_LOG_MIN = log10(LB_DIRECT_TOP_MIN)
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
		return clamp(floor(lbClampUnit(unit) * (slots - 1) + 0.5), 0, slots - 1)
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
		return lbQuantizeUnit(unit, NanoFormat.LB_LAYER_TOP_BUCKETS)
	end

	local function lbDirectTopFromBucket(bucket: number): number
		local unit = lbUnitFromSlot(bucket, NanoFormat.LB_LAYER_TOP_BUCKETS)
		if unit >= 1 then
			return 1e308
		end
		return 10 ^ (LB_DIRECT_TOP_LOG_MIN + unit * LB_DIRECT_TOP_LOG_DENOM)
	end

	local function lbLogLayerTopBucket(top: number): number
		if top <= 0 then
			return 0
		end
		local unit = log10(1 + min(top, 1e308)) / LB_TOP_LOG_DENOM
		return lbQuantizeUnit(unit, NanoFormat.LB_LAYER_TOP_BUCKETS)
	end

	local function lbLogLayerTopFromBucket(bucket: number): number
		local unit = lbUnitFromSlot(bucket, NanoFormat.LB_LAYER_TOP_BUCKETS)
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
			return NanoFormat.fromNumber(value)
		elseif t == "string" then
			return NanoFormat.fromString(value)
		end
		return makeSpecial(SPECIAL_NAN)
	end

	local function lbDescriptor(value: buffer)
		local data = decodeAt(value, 0)

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
			local magnitude = abs(data.Value)
			return {
				Kind = "Magnitude",
				Negative = data.Value < 0,
				Reciprocal = false,
				Layer = 0,
				LogScale = log10(magnitude),
			}
		end
		if data.Kind == "Normal" then
			local logMagnitude = data.Exponent + log10(data.Mantissa)
			local reciprocal = logMagnitude < 0
			return {
				Kind = "Magnitude",
				Negative = data.Negative,
				Reciprocal = reciprocal,
				Layer = 0,
				LogScale = abs(logMagnitude),
			}
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

		if data.LayerIsLog then
			-- Old/non-canonical V0.3 buffers may use a log-height <= 308. Convert
			-- those back to a direct height and canonicalize the top before ranking.
			if data.LayerLog10 <= 308 then
				local layer, top = normalizeLayerInput(10 ^ data.LayerLog10, data.Top, false)
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
			return {
				Kind = "Layer",
				Negative = data.Negative,
				Reciprocal = data.Reciprocal,
				LayerLog10 = data.LayerLog10,
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
			local slot = floor((magnitude - 1) * NanoFormat.LB_ORDINARY_SUBSLOTS + 0.5)
			return clamp(slot, 0, LB_ORDINARY_EXACT_END)
		end

		if logScale <= 308 then
			local unit = (logScale - LB_ORDINARY_EXACT_LOG10) / LB_ORDINARY_LOG_DENOM
			return LB_ORDINARY_LOG_START + lbQuantizeUnit(unit, LB_ORDINARY_LOG_SPAN)
		end

		local capped = min(logScale, 1e308)
		local unit = log10(capped / LB_HUGE_LOG_MIN) / LB_HUGE_LOG_DENOM
		return LB_HUGE_LOG_START + lbQuantizeUnit(unit, LB_HUGE_LOG_SPAN)
	end

	local function lbEncodeLayer(layer: number, top: number): number
		if layer <= NanoFormat.LB_LOW_LAYER_MAX then
			local layerIndex = max(0, floor(layer + 0.5) - 2)
			local topBucket = lbDirectTopBucket(top)
			return LB_LOW_LAYER_START
				+ layerIndex * NanoFormat.LB_LAYER_TOP_BUCKETS
				+ topBucket
		end

		local unit = (log10(min(layer, 1e308)) - LB_HIGH_LAYER_LOG_MIN) / LB_HIGH_LAYER_LOG_DENOM
		local layerSlot = lbQuantizeUnit(unit, LB_HIGH_LAYER_BUCKET_COUNT)
		local topBucket = lbDirectTopBucket(top)
		return LB_HIGH_LAYER_START
			+ layerSlot * NanoFormat.LB_LAYER_TOP_BUCKETS
			+ topBucket
	end

	local function lbEncodeLogLayer(layerLog10: number, top: number): number
		local capped = min(max(layerLog10, LB_LOG_LAYER_MIN), 1e308)
		local unit = log10(capped / LB_LOG_LAYER_MIN) / LB_LOG_LAYER_DENOM
		local layerSlot = lbQuantizeUnit(unit, LB_LOG_LAYER_BUCKET_COUNT)
		local topBucket = lbLogLayerTopBucket(top)
		return LB_LOG_LAYER_START
			+ layerSlot * NanoFormat.LB_LAYER_TOP_BUCKETS
			+ topBucket
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
		-- Direct prefix dispatch avoids allocating the Reader table and decoded-data
		-- table used by the public decodeAt()/components() API.
		local raw = bufferReadBits(value, 0, 6)

		if band(raw, 1) == 0 then
			local integer = bufferReadBits(value, 1, 7)
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
			local n = bufferReadBits(value, 4, INTEGER_LEN_BITS)
			local payloadOffset = 4 + INTEGER_LEN_BITS
			if n == 0 then
				n = 32 + bufferReadBits(value, payloadOffset, 5)
				payloadOffset += 5
				if n > MAX_INTEGER_MODE_BITS then
					error("NanoFormat: invalid extended integer bit length")
				end
			end
			local magnitude = readUIntExactAtFast(value, payloadOffset, n)
			if magnitude == 0 then
				return 0, true
			end
			local delta = lbEncodeOrdinaryLog(log10(magnitude))
			return lbFinalizeFiniteCode(delta, negative, false), true
		end

		if band(raw, 15) == 7 then
			local negative = bufferReadBits(value, 4, 1) == 1
			local expCode = bufferReadBits(value, 5, NORMAL_EXP_BITS)
			if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
				error("NanoFormat: invalid normal exponent code")
			end
			local mantCode = bufferReadBits(value, 5 + NORMAL_EXP_BITS, NORMAL_MANT_BITS)
			local exponent = expCode - NORMAL_EXP_BIAS
			local mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX)
			local logMagnitude = exponent + log10(mantissa)
			local reciprocal = logMagnitude < 0
			local delta = lbEncodeOrdinaryLog(abs(logMagnitude))
			return lbFinalizeFiniteCode(delta, negative, reciprocal), true
		end

		if band(raw, 31) == 15 then
			local negative = bufferReadBits(value, 5, 1) == 1
			local reciprocal = bufferReadBits(value, 6, 1) == 1
			local top = readScalarAtFast(value, 7)
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

		local special = bufferReadBits(value, 6, 2)
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
		return delta <= LB_LOG_LAYER_END
	end

	NanoFormat.isLBCode = isLBCodeFast

	function NanoFormat.tryLBEncode(value: any): (boolean, number)
		-- PATH 0: leaderboard hot paths overwhelmingly receive NanoFormat buffers.
		if typeof(value) == "buffer" then
			local code, valid = lbCodeFromBufferFast(value)
			return valid, code
		end
		local code, valid = lbCodeFromBufferFast(lbCoerce(value))
		return valid, code
	end

	function NanoFormat.lbencode(value: MathValue): number
		if typeof(value) == "buffer" then
			local code = lbCodeFromBufferFast(value)
			return code
		end
		local code = lbCodeFromBufferFast(lbCoerce(value))
		return code
	end

	NanoFormat.lbencodeV1 = NanoFormat.lbencode

	local function lbDecodePositiveDelta(delta: number): (number, number, number)
		delta = clamp(floor(delta), 1, NanoFormat.LB_POSITIVE_SPAN)

		if delta <= LB_ORDINARY_EXACT_END then
			local magnitude = 1 + delta / NanoFormat.LB_ORDINARY_SUBSLOTS
			return 0, log10(magnitude), 0
		end

		if delta <= LB_ORDINARY_LOG_END then
			local slot = delta - LB_ORDINARY_LOG_START
			local unit = lbUnitFromSlot(slot, LB_ORDINARY_LOG_SPAN)
			return 0, LB_ORDINARY_EXACT_LOG10 + unit * LB_ORDINARY_LOG_DENOM, 0
		end

		if delta <= LB_HUGE_LOG_END then
			local slot = delta - LB_HUGE_LOG_START
			local unit = lbUnitFromSlot(slot, LB_HUGE_LOG_SPAN)
			local logScale = LB_HUGE_LOG_MIN * (10 ^ (unit * LB_HUGE_LOG_DENOM))
			if logScale > 1e308 then
				logScale = 1e308
			end
			return 0, logScale, 0
		end

		if delta <= LB_LOW_LAYER_END then
			local offset = delta - LB_LOW_LAYER_START
			local layerIndex = floor(offset / NanoFormat.LB_LAYER_TOP_BUCKETS)
			local topBucket = offset - layerIndex * NanoFormat.LB_LAYER_TOP_BUCKETS
			return 1, layerIndex + 2, lbDirectTopFromBucket(topBucket)
		end

		if delta <= LB_HIGH_LAYER_END then
			local offset = delta - LB_HIGH_LAYER_START
			local layerSlot = floor(offset / NanoFormat.LB_LAYER_TOP_BUCKETS)
			local topBucket = offset - layerSlot * NanoFormat.LB_LAYER_TOP_BUCKETS
			local unit = lbUnitFromSlot(layerSlot, LB_HIGH_LAYER_BUCKET_COUNT)
			local layerLog10 = LB_HIGH_LAYER_LOG_MIN + unit * LB_HIGH_LAYER_LOG_DENOM
			local layer = 10 ^ layerLog10
			if layer > 1e308 then
				layer = 1e308
			end
			return 1, layer, lbDirectTopFromBucket(topBucket)
		end

		local offset = clamp(delta - LB_LOG_LAYER_START, 0, LB_LOG_LAYER_USED_SPAN - 1)
		local layerSlot = floor(offset / NanoFormat.LB_LAYER_TOP_BUCKETS)
		local topBucket = offset - layerSlot * NanoFormat.LB_LAYER_TOP_BUCKETS
		local unit = lbUnitFromSlot(layerSlot, LB_LOG_LAYER_BUCKET_COUNT)
		local layerLog10 = LB_LOG_LAYER_MIN * (10 ^ (unit * LB_LOG_LAYER_DENOM))
		if layerLog10 > 1e308 then
			layerLog10 = 1e308
		end
		return 2, layerLog10, lbLogLayerTopFromBucket(topBucket)
	end

	function NanoFormat.lbdecode(encoded: number, version: number?): buffer
		if version ~= nil and version ~= LB_VERSION then
			return makeSpecial(SPECIAL_NAN)
		end
		if not isLBCodeFast(encoded) then
			return makeSpecial(SPECIAL_NAN)
		end
		if encoded == 0 then
			return NanoFormat.fromNumber(0)
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
			return NanoFormat.fromNumber(negative and -1 or 1)
		end

		local reciprocal = code < LB_ONE
		local delta = reciprocal and (LB_ONE - code) or (code - LB_ONE)
		local decodedKind, decodedA, decodedB = lbDecodePositiveDelta(delta)

		if decodedKind == 0 then
			-- Stay in the ordinary buffer mode whenever the reconstructed value fits
			-- in a Luau number. This preserves more NanoFormat precision than routing
			-- every LB ordinary bucket through the layer-1 scalar codec.
			if decodedA <= 308 then
				local magnitude = 10 ^ decodedA
				if reciprocal then
					magnitude = 1 / magnitude
				end
				if negative then
					magnitude = -magnitude
				end
				return NanoFormat.fromNumber(magnitude)
			end

			local exponent = reciprocal and -decodedA or decodedA
			return NanoFormat.fromLog10(exponent, negative)
		end

		if decodedKind == 2 then
			return NanoFormat.fromLayerLog10(decodedA, decodedB, negative, reciprocal)
		end

		return NanoFormat.fromLayer(decodedA, decodedB, negative, reciprocal)
	end

	NanoFormat.lbdecodeV1 = NanoFormat.lbdecode

	function NanoFormat.lbcodecVersion(): number
		return 1
	end

	function NanoFormat.lbpack(value: MathValue): LBPacket
		local code
		if typeof(value) == "buffer" then
			code = lbCodeFromBufferFast(value)
		else
			code = lbCodeFromBufferFast(lbCoerce(value))
		end
		return {
			v = LB_VERSION,
			c = code,
		}
	end

	function NanoFormat.lbunpack(data: LBPacketInput): buffer
		if typeof(data) ~= "table" then
			return makeSpecial(SPECIAL_NAN)
		end
		local version = toNumber((data :: any).v or (data :: any).version)
		local code = toNumber((data :: any).c or (data :: any).code)
		if version == nil or code == nil then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.lbdecode(code, version)
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
		end
		return "log-layer"
	end

	function NanoFormat.lbinfo(value: MathValue): LBInfo
		local v = if typeof(value) == "buffer" then value else lbCoerce(value)
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
				distanceFromOne = NanoFormat.LB_ONE,
			}
		end
		if descriptor.Kind == "Infinity" then
			local code = descriptor.Negative and -NanoFormat.LB_MAX or NanoFormat.LB_MAX
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
		local absCode = abs(code)
		local delta = abs(absCode - LB_ONE)
		return {
			version = LB_VERSION,
			code = code,
			band = lbBandFromDelta(delta),
			negative = descriptor.Negative,
			reciprocal = descriptor.Reciprocal,
			distanceFromOne = delta,
		}
	end

	function NanoFormat.lbquantize(value: MathValue): buffer
		local code
		if typeof(value) == "buffer" then
			code = lbCodeFromBufferFast(value)
		else
			code = lbCodeFromBufferFast(lbCoerce(value))
		end
		return NanoFormat.lbdecode(code)
	end

	function NanoFormat.lbSameBucket(a: MathValue, b: MathValue): boolean
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
		return ca == cb
	end

	function NanoFormat.lbRoundTripStable(value: MathValue): boolean
		local code, valid
		if typeof(value) == "buffer" then
			code, valid = lbCodeFromBufferFast(value)
		else
			code, valid = lbCodeFromBufferFast(lbCoerce(value))
		end
		if not valid then
			return false
		end
		local decoded = NanoFormat.lbdecode(code)
		local roundTrip = lbCodeFromBufferFast(decoded)
		return roundTrip == code
	end

	function NanoFormat.lbCompare(a: MathValue, b: MathValue): number
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

end)()

NanoFormat.MATH_SCOPE_VERSION = 1

(function()

	NanoFormat.MATH_VERSION = 7
	NanoFormat.MATH_CLEANUP_VERSION = 1

	local MATH_DIRECT_LOG_MAX = 308.25471555991675
	local MATH_DIRECT_LOG_MIN = -323.3062153431158
	local MATH_LN10 = math.log(10)
	local MATH_NAN = 0 / 0

	local function mathCoerce(value: any): buffer
		local kind = typeof(value)

		if kind == "buffer" then
			return value
		elseif kind == "number" then
			return NanoFormat.fromNumber(value)
		elseif kind == "string" then
			return NanoFormat.fromString(value)
		end

		return makeSpecial(SPECIAL_NAN)
	end

	local function mathDecode(value: any): (buffer, any)
		local data = mathCoerce(value)
		if typeof(data) ~= "buffer" or not NanoFormat.isValid(data) then
			local nan = makeSpecial(SPECIAL_NAN)
			return nan, {Kind = "NaN", Negative = false}
		end
		return data, decodeAt(data, 0)
	end

	local function mathIsZeroData(data): boolean
		return data.Kind == "Integer" and data.Value == 0
	end

	local function mathNegativeData(data): boolean
		if data.Kind == "Integer" then
			return data.Value < 0
		end
		return data.Negative == true
	end

	local function mathSignData(data): number
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return 0
		end
		if mathIsZeroData(data) then
			return 0
		end
		return mathNegativeData(data) and -1 or 1
	end

	local function mathAbsLogData(data): number?
		if data.Kind == "Integer" then
			if data.Value == 0 then return nil end
			return log10(abs(data.Value))
		elseif data.Kind == "Normal" then
			return data.Exponent + log10(data.Mantissa)
		elseif data.Kind == "Log" then
			return data.Reciprocal and -data.Top or data.Top
		end
		return nil
	end

	local function mathFiniteNumberData(data): number?
		if data.Kind == "Integer" then
			return data.Value
		elseif data.Kind == "Normal" then
			local lg = data.Exponent + log10(data.Mantissa)
			if lg > MATH_DIRECT_LOG_MAX then return nil end
			if lg < MATH_DIRECT_LOG_MIN then return 0 end
			local magnitude = 10 ^ lg
			if magnitude == huge then return nil end
			return data.Negative and -magnitude or magnitude
		elseif data.Kind == "Log" then
			local exponent = data.Reciprocal and -data.Top or data.Top
			if exponent > MATH_DIRECT_LOG_MAX then return nil end
			if exponent < MATH_DIRECT_LOG_MIN then return 0 end
			local magnitude = 10 ^ exponent
			if magnitude == huge then return nil end
			return data.Negative and -magnitude or magnitude
		elseif data.Kind == "Infinity" then
			return data.Negative and -huge or huge
		end
		return nil
	end

	local function mathFromSignedLog(logMagnitude: number, negative: boolean): buffer
		if logMagnitude ~= logMagnitude then
			return makeSpecial(SPECIAL_NAN)
		end
		if logMagnitude == huge then
			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		elseif logMagnitude == -huge then
			return NanoFormat.fromNumber(0)
		end

		if logMagnitude <= MATH_DIRECT_LOG_MAX
			and logMagnitude >= MATH_DIRECT_LOG_MIN
		then
			local magnitude = 10 ^ logMagnitude
			if magnitude ~= 0 and magnitude ~= huge then
				return NanoFormat.fromNumber(negative and -magnitude or magnitude)
			end
		end

		return NanoFormat.fromLog10(logMagnitude, negative)
	end

	local function mathScalarAdd(
		a: number,
		b: number
	): (number?, number?, boolean?)
		local direct = a + b
		if direct ~= huge and direct ~= -huge then
			return direct, nil, nil
		end

		local negative = a < 0
		local aa = abs(a)
		local bb = abs(b)
		local hi = max(aa, bb)
		local lo = min(aa, bb)
		local top = log10(hi) + log10(1 + lo / hi)
		return nil, top, negative
	end

	local function mathResultFromLogScalar(
		direct: number?,
		top: number?,
		scalarNegative: boolean?,
		numberNegative: boolean
	): buffer
		if direct ~= nil then
			return mathFromSignedLog(direct, numberNegative)
		end

		return NanoFormat.fromLayer(
			2,
			top or 0,
			numberNegative,
			scalarNegative == true
		)
	end

	local function mathLayerTowerCompare(a, b): number
		if a.LayerIsLog ~= b.LayerIsLog then
			return a.LayerIsLog and 1 or -1
		end

		if a.LayerIsLog then
			if a.LayerLog10 < b.LayerLog10 then return -1 end
			if a.LayerLog10 > b.LayerLog10 then return 1 end
		else
			if a.Layer < b.Layer then return -1 end
			if a.Layer > b.Layer then return 1 end
		end

		if a.Top < b.Top then return -1 end
		if a.Top > b.Top then return 1 end
		return 0
	end

	local function mathAbsCompareData(a, b): number
		local aLayer = a.Kind == "Layer"
		local bLayer = b.Kind == "Layer"

		if not aLayer and not bLayer then
			local la = mathAbsLogData(a)
			local lb = mathAbsLogData(b)

			if la == nil then
				return lb == nil and 0 or -1
			elseif lb == nil then
				return 1
			end

			if la < lb then return -1 end
			if la > lb then return 1 end
			return 0
		end

		if aLayer and not bLayer then
			return a.Reciprocal and -1 or 1
		elseif bLayer and not aLayer then
			return b.Reciprocal and 1 or -1
		end

		if a.Reciprocal ~= b.Reciprocal then
			return a.Reciprocal and -1 or 1
		end

		local tower = mathLayerTowerCompare(a, b)
		return a.Reciprocal and -tower or tower
	end

	local function mathBuildLayer(data, negative: boolean, reciprocal: boolean?): buffer
		local r = if reciprocal == nil then data.Reciprocal == true else reciprocal

		if data.LayerIsLog then
			return NanoFormat.fromLayerLog10(
				data.LayerLog10,
				data.Top,
				negative,
				r
			)
		end

		return NanoFormat.fromLayer(
			data.Layer,
			data.Top,
			negative,
			r
		)
	end

	local function mathWithSignData(data, negative: boolean): buffer
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		elseif data.Kind == "Integer" then
			return NanoFormat.fromNumber(negative and -abs(data.Value) or abs(data.Value))
		elseif data.Kind == "Normal" then
			return mathFromSignedLog(
				data.Exponent + log10(data.Mantissa),
				negative
			)
		elseif data.Kind == "Log" then
			local exponent = data.Reciprocal and -data.Top or data.Top
			return NanoFormat.fromLog10(exponent, negative)
		elseif data.Kind == "Layer" then
			return mathBuildLayer(data, negative)
		end
		return makeSpecial(SPECIAL_NAN)
	end

	local function mathReciprocalData(data): buffer
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			return NanoFormat.fromNumber(0)
		elseif mathIsZeroData(data) then
			return makeSpecial(SPECIAL_POS_INF)
		elseif data.Kind == "Integer" or data.Kind == "Normal" then
			local lg = mathAbsLogData(data)
			return mathFromSignedLog(-(lg or 0), mathNegativeData(data))
		elseif data.Kind == "Log" then
			local exponent = data.Reciprocal and data.Top or -data.Top
			return NanoFormat.fromLog10(exponent, data.Negative)
		elseif data.Kind == "Layer" then
			return mathBuildLayer(data, data.Negative, not data.Reciprocal)
		end
		return makeSpecial(SPECIAL_NAN)
	end

	local function mathCompareData(a, b): number
		if a.Kind == "NaN" or a.Kind == "Reserved"
			or b.Kind == "NaN" or b.Kind == "Reserved"
		then
			return MATH_NAN
		end

		if a.Kind == "Infinity" or b.Kind == "Infinity" then
			if a.Kind == "Infinity" and b.Kind == "Infinity" then
				if a.Negative == b.Negative then return 0 end
				return a.Negative and -1 or 1
			end
			if a.Kind == "Infinity" then
				return a.Negative and -1 or 1
			end
			return b.Negative and 1 or -1
		end

		local sa = mathSignData(a)
		local sb = mathSignData(b)

		if sa ~= sb then
			return sa < sb and -1 or 1
		end
		if sa == 0 then return 0 end

		local cmp = mathAbsCompareData(a, b)
		return sa < 0 and -cmp or cmp
	end

	local function mathSlowToNumber(value: any): number
		local _, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return MATH_NAN
		elseif data.Kind == "Infinity" then
			return data.Negative and -huge or huge
		end

		local direct = mathFiniteNumberData(data)
		if direct ~= nil then return direct end

		if data.Kind == "Layer" then
			if data.Reciprocal then
				return 0
			end
			return data.Negative and -huge or huge
		elseif data.Kind == "Log" then
			if data.Reciprocal then
				return 0
			end
			return data.Negative and -huge or huge
		end

		return MATH_NAN
	end

	local function mathSlowCompare(a: any, b: any): number
		local _, da = mathDecode(a)
		local _, db = mathDecode(b)
		return mathCompareData(da, db)
	end

	local function mathSlowNeg(value: any): buffer
		local _, data = mathDecode(value)
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		end
		return mathWithSignData(data, not mathNegativeData(data))
	end

	local function mathSlowAbs(value: any): buffer
		local _, data = mathDecode(value)
		return mathWithSignData(data, false)
	end

	local function mathSlowReciprocal(value: any): buffer
		local _, data = mathDecode(value)
		return mathReciprocalData(data)
	end

	local function mathSlowAdd(a: any, b: any): buffer
		local ba, da = mathDecode(a)
		local bb, db = mathDecode(b)

		if da.Kind == "NaN" or da.Kind == "Reserved"
			or db.Kind == "NaN" or db.Kind == "Reserved"
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if da.Kind == "Infinity" or db.Kind == "Infinity" then
			if da.Kind == "Infinity" and db.Kind == "Infinity"
				and da.Negative ~= db.Negative
			then
				return makeSpecial(SPECIAL_NAN)
			end
			if da.Kind == "Infinity" then return ba end
			return bb
		end

		if mathIsZeroData(da) then return bb end
		if mathIsZeroData(db) then return ba end

		local sa = mathSignData(da)
		local sb = mathSignData(db)
		local aLayer = da.Kind == "Layer"
		local bLayer = db.Kind == "Layer"

		if aLayer or bLayer then
			local cmpAbs = mathAbsCompareData(da, db)

			if sa ~= sb and cmpAbs == 0 then
				return NanoFormat.fromNumber(0)
			end

			local dominant
			if cmpAbs >= 0 then
				dominant = da
			else
				dominant = db
			end
			return mathWithSignData(dominant, mathNegativeData(dominant))
		end

		local la = mathAbsLogData(da)
		local lb = mathAbsLogData(db)
		if la == nil then return bb end
		if lb == nil then return ba end

		if sa == sb then
			local hi = max(la, lb)
			local lo = min(la, lb)
			local delta = hi - lo
			if delta > 18 then
				return mathFromSignedLog(hi, sa < 0)
			end

			local resultLog = hi + log10(1 + 10 ^ (-delta))
			return mathFromSignedLog(resultLog, sa < 0)
		end

		local cmpAbs = mathAbsCompareData(da, db)
		if cmpAbs == 0 then
			return NanoFormat.fromNumber(0)
		end

		local hi
		local lo
		local negative

		if cmpAbs > 0 then
			hi = la
			lo = lb
			negative = sa < 0
		else
			hi = lb
			lo = la
			negative = sb < 0
		end

		local delta = hi - lo
		if delta > 18 then
			return mathFromSignedLog(hi, negative)
		end

		local term = 1 - 10 ^ (-delta)
		if term <= 0 then
			return NanoFormat.fromNumber(0)
		end

		return mathFromSignedLog(hi + log10(term), negative)
	end

	local function mathSlowSub(a: any, b: any): buffer
		return NanoFormat.add(a, NanoFormat.neg(b))
	end

	local function mathMulLayerAndLog(
		layerData,
		otherLog: number,
		negative: boolean
	): buffer

		if not layerData.LayerIsLog
			and layerData.Layer == 2
			and layerData.Top <= MATH_DIRECT_LOG_MAX
		then
			local towerExponent = 10 ^ layerData.Top
			if layerData.Reciprocal then
				towerExponent = -towerExponent
			end

			local direct, top, scalarNegative =
				mathScalarAdd(towerExponent, otherLog)

			return mathResultFromLogScalar(
				direct,
				top,
				scalarNegative,
				negative
			)
		end

		return mathBuildLayer(layerData, negative)
	end

	local function mathSlowMul(a: any, b: any): buffer
		local _, da = mathDecode(a)
		local _, db = mathDecode(b)

		if da.Kind == "NaN" or da.Kind == "Reserved"
			or db.Kind == "NaN" or db.Kind == "Reserved"
		then
			return makeSpecial(SPECIAL_NAN)
		end

		local zeroA = mathIsZeroData(da)
		local zeroB = mathIsZeroData(db)

		if da.Kind == "Infinity" or db.Kind == "Infinity" then
			if zeroA or zeroB then
				return makeSpecial(SPECIAL_NAN)
			end

			local negative = mathNegativeData(da) ~= mathNegativeData(db)
			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		end

		if zeroA or zeroB then
			return NanoFormat.fromNumber(0)
		end

		local negative = mathNegativeData(da) ~= mathNegativeData(db)
		local aLayer = da.Kind == "Layer"
		local bLayer = db.Kind == "Layer"

		if not aLayer and not bLayer then
			local la = mathAbsLogData(da)
			local lb = mathAbsLogData(db)
			if la == nil or lb == nil then
				return makeSpecial(SPECIAL_NAN)
			end

			local direct, top, scalarNegative = mathScalarAdd(la, lb)
			return mathResultFromLogScalar(
				direct, top, scalarNegative, negative
			)
		end

		if aLayer and not bLayer then
			return mathMulLayerAndLog(
				da,
				mathAbsLogData(db) or 0,
				negative
			)
		elseif bLayer and not aLayer then
			return mathMulLayerAndLog(
				db,
				mathAbsLogData(da) or 0,
				negative
			)
		end

		if not da.LayerIsLog and not db.LayerIsLog
			and da.Layer == 2 and db.Layer == 2
		then
			local ta = da.Top
			local tb = db.Top
			local sa = da.Reciprocal and -1 or 1
			local sb = db.Reciprocal and -1 or 1

			if sa == sb then
				local hi = max(ta, tb)
				local lo = min(ta, tb)
				local top = hi + log10(1 + 10 ^ (lo - hi))
				return NanoFormat.fromLayer(2, top, negative, sa < 0)
			end

			if ta == tb then
				return NanoFormat.fromNumber(negative and -1 or 1)
			end

			local hi
			local lo
			local scalarNegative
			if ta > tb then
				hi, lo, scalarNegative = ta, tb, sa < 0
			else
				hi, lo, scalarNegative = tb, ta, sb < 0
			end

			local term = 1 - 10 ^ (lo - hi)
			if term <= 0 then
				return NanoFormat.fromNumber(negative and -1 or 1)
			end

			local top = hi + log10(term)
			return NanoFormat.fromLayer(2, top, negative, scalarNegative)
		end

		local towerCmp = mathLayerTowerCompare(da, db)

		if towerCmp == 0 then
			if da.Reciprocal ~= db.Reciprocal then
				return NanoFormat.fromNumber(negative and -1 or 1)
			end
			return mathBuildLayer(da, negative)
		end

		local dominant = towerCmp > 0 and da or db

		if da.Reciprocal == db.Reciprocal then
			return mathBuildLayer(dominant, negative, da.Reciprocal)
		end

		return mathBuildLayer(dominant, negative, dominant.Reciprocal)
	end

	local function mathSlowDiv(a: any, b: any): buffer
		return NanoFormat.mul(a, NanoFormat.reciprocal(b))
	end

	local function mathSlowLog10(value: any): buffer
		local _, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			if data.Negative then return makeSpecial(SPECIAL_NAN) end
			return makeSpecial(SPECIAL_POS_INF)
		elseif mathIsZeroData(data) then
			return makeSpecial(SPECIAL_NEG_INF)
		elseif mathNegativeData(data) then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Integer" or data.Kind == "Normal" then
			return NanoFormat.fromNumber(mathAbsLogData(data) or -huge)
		elseif data.Kind == "Log" then
			return NanoFormat.fromNumber(
				data.Reciprocal and -data.Top or data.Top
			)
		elseif data.Kind == "Layer" then
			if data.LayerIsLog then

				return NanoFormat.fromLayerLog10(
					data.LayerLog10,
					data.Top,
					data.Reciprocal,
					false
				)
			end

			if data.Layer == 2 then
				return NanoFormat.fromLog10(
					data.Top,
					data.Reciprocal
				)
			end

			return NanoFormat.fromLayer(
				data.Layer - 1,
				data.Top,
				data.Reciprocal,
				false
			)
		end

		return makeSpecial(SPECIAL_NAN)
	end

	function NanoFormat.ln(value: MathValue): buffer
		return NanoFormat.mul(NanoFormat.log10(value), MATH_LN10)
	end

	function NanoFormat.log(value: MathValue, base: MathValue?): buffer
		if NanoFormat.isNaN(value) or NanoFormat.lte(value, 0) then
			return makeSpecial(SPECIAL_NAN)
		end

		if base == nil then
			return NanoFormat.ln(value)
		end

		if NanoFormat.isNaN(base)
			or NanoFormat.lte(base, 0)
			or NanoFormat.eq(base, 1)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.div(
			NanoFormat.log10(value),
			NanoFormat.log10(base)
		)
	end

	local function mathSlowPow10(value: any): buffer
		local _, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			return data.Negative
				and NanoFormat.fromNumber(0)
				or makeSpecial(SPECIAL_POS_INF)
		end

		local direct = mathFiniteNumberData(data)
		if direct ~= nil then
			if direct == 0 then
				return NanoFormat.fromNumber(1)
			end
			return NanoFormat.fromLog10(direct, false)
		end

		if data.Kind == "Log" then

			if data.Reciprocal then
				return NanoFormat.fromNumber(1)
			end

			return NanoFormat.fromLayer(
				2,
				data.Top,
				false,
				data.Negative
			)
		elseif data.Kind == "Layer" then

			if data.Reciprocal then
				return NanoFormat.fromNumber(1)
			end

			if data.LayerIsLog then
				return NanoFormat.fromLayerLog10(
					data.LayerLog10,
					data.Top,
					false,
					data.Negative
				)
			end

			local nextLayer = data.Layer + 1
			if nextLayer == huge or nextLayer > NanoFormat.MAX_LAYER then
				nextLayer = NanoFormat.MAX_LAYER
			end

			return NanoFormat.fromLayer(
				nextLayer,
				data.Top,
				false,
				data.Negative
			)
		end

		return makeSpecial(SPECIAL_NAN)
	end

	function NanoFormat.sqrt(value: MathValue): buffer
		return NanoFormat.pow(value, 0.5)
	end

	local MATH_SAFE_INTEGER = 9007199254740991
	local MATH_LOG10_2 = log10(2)
	local MATH_LOG10_E = log10(math.exp(1))
	local MATH_TWO_PI = 2 * math.pi

	local function mathExactSafeInteger(value: any): number?
		if typeof(value) == "number" then
			if value == value
				and value ~= huge
				and value ~= -huge
				and value == floor(value)
				and abs(value) <= MATH_SAFE_INTEGER
			then
				return value
			end
			return nil
		end

		local _, data = mathDecode(value)

		if data.Kind == "Integer" then
			local n = data.Value
			if abs(n) <= MATH_SAFE_INTEGER and n == floor(n) then
				return n
			end
			return nil
		end

		if data.Kind == "Log"
			and not data.Reciprocal
			and data.Top >= 0
			and data.Top == floor(data.Top)
			and data.Top <= 15
		then
			local n = 10 ^ data.Top
			if n <= MATH_SAFE_INTEGER then
				return data.Negative and -n or n
			end
		end

		return nil
	end

	function NanoFormat.root(value: MathValue, degree: MathValue): buffer
		if NanoFormat.isNaN(value)
			or NanoFormat.isNaN(degree)
			or NanoFormat.eq(degree, 0)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.lt(value, 0) then
			local integerDegree = mathExactSafeInteger(degree)
			if integerDegree == nil
				or integerDegree == 0
				or abs(integerDegree) % 2 == 0
			then
				return makeSpecial(SPECIAL_NAN)
			end

			return NanoFormat.neg(
				NanoFormat.pow(
					NanoFormat.abs(value),
					NanoFormat.div(1, degree)
				)
			)
		end

		return NanoFormat.pow(value, NanoFormat.div(1, degree))
	end

	function NanoFormat.min(a: MathValue, b: MathValue): buffer
		local cmp = NanoFormat.compare(a, b)
		if cmp ~= cmp then return makeSpecial(SPECIAL_NAN) end
		return mathCoerce(cmp <= 0 and a or b)
	end

	function NanoFormat.max(a: MathValue, b: MathValue): buffer
		local cmp = NanoFormat.compare(a, b)
		if cmp ~= cmp then return makeSpecial(SPECIAL_NAN) end
		return mathCoerce(cmp >= 0 and a or b)
	end

	local function mathSlowIsNaN(value: any): boolean
		local _, data = mathDecode(value)
		return data.Kind == "NaN" or data.Kind == "Reserved"
	end

	local function mathSlowIsInfinite(value: any): boolean
		local _, data = mathDecode(value)
		return data.Kind == "Infinity"
	end

	local function mathSlowIsFinite(value: any): boolean
		local _, data = mathDecode(value)
		return data.Kind ~= "Infinity"
			and data.Kind ~= "NaN"
			and data.Kind ~= "Reserved"
	end

	local function mathSlowIsZero(value: any): boolean
		local _, data = mathDecode(value)
		return mathIsZeroData(data)
	end

	local function mathCopyBuffer(value: any): buffer
		return mathCoerce(value)
	end

	local function mathSlowSign(value: any): number
		local _, data = mathDecode(value)
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return MATH_NAN
		end
		return mathSignData(data)
	end

	function NanoFormat.copySign(value: MathValue, signSource: MathValue): buffer
		local _, data = mathDecode(value)
		local _, source = mathDecode(signSource)

		if data.Kind == "NaN" or data.Kind == "Reserved"
			or source.Kind == "NaN" or source.Kind == "Reserved"
		then
			return makeSpecial(SPECIAL_NAN)
		end

		return mathWithSignData(data, mathSignData(source) < 0)
	end

	function NanoFormat.trunc(value: MathValue): buffer
		local original, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			return original
		elseif data.Kind == "Integer" then
			return original
		end

		local direct = mathFiniteNumberData(data)
		if direct ~= nil then
			local n = if direct < 0 then math.ceil(direct) else floor(direct)
			return NanoFormat.fromNumber(n)
		end

		local oneData = decodeAt(NanoFormat.fromNumber(1), 0)
		if mathAbsCompareData(data, oneData) >= 0 then
			return original
		end

		return NanoFormat.fromNumber(0)
	end

	function NanoFormat.round(value: MathValue, decimals: number?): buffer
		local places = decimals or 0

		if places ~= floor(places) or places < -308 or places > 308 then
			return makeSpecial(SPECIAL_NAN)
		end

		if places == 0 then
			local direct = NanoFormat.toNumber(value)

			if direct == direct and direct ~= huge and direct ~= -huge then
				local rounded =
					if direct >= 0
					then floor(direct + 0.5)
					else math.ceil(direct - 0.5)

				return NanoFormat.fromNumber(rounded)
			end

			return mathCopyBuffer(value)
		end

		local scale = NanoFormat.pow10(places)
		local scaled = NanoFormat.mul(value, scale)
		local rounded = NanoFormat.round(scaled, 0)

		return NanoFormat.div(rounded, scale)
	end

	function NanoFormat.frac(value: MathValue): buffer
		return NanoFormat.sub(value, NanoFormat.trunc(value))
	end

	local function mathExactModuloInputs(a: any, b: any): (number?, number?)
		local ai = mathExactSafeInteger(a)
		local bi = mathExactSafeInteger(b)

		if ai == nil or bi == nil or bi == 0 then
			return nil, nil
		end

		return ai, bi
	end

	function NanoFormat.mod(a: MathValue, b: MathValue): buffer
		local ai, bi = mathExactModuloInputs(a, b)

		if ai == nil or bi == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.fromNumber(ai % bi)
	end

	function NanoFormat.log2(value: MathValue): buffer
		return NanoFormat.div(NanoFormat.log10(value), MATH_LOG10_2)
	end

	function NanoFormat.exp(value: MathValue): buffer
		return NanoFormat.pow10(NanoFormat.mul(value, MATH_LOG10_E))
	end

	function NanoFormat.exp2(value: MathValue): buffer
		return NanoFormat.pow10(NanoFormat.mul(value, MATH_LOG10_2))
	end

	function NanoFormat.cbrt(value: MathValue): buffer
		return NanoFormat.root(value, 3)
	end

	function NanoFormat.hypot(a: MathValue, b: MathValue): buffer
		local aa = NanoFormat.mul(a, a)
		local bb = NanoFormat.mul(b, b)

		return NanoFormat.sqrt(NanoFormat.add(aa, bb))
	end

	function NanoFormat.lerp(a: MathValue, b: MathValue, t: MathValue): buffer
		return NanoFormat.add(
			a,
			NanoFormat.mul(
				NanoFormat.sub(b, a),
				t
			)
		)
	end

	function NanoFormat.inverseLerp(a: MathValue, b: MathValue, value: MathValue): buffer
		if NanoFormat.eq(a, b) then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.div(
			NanoFormat.sub(value, a),
			NanoFormat.sub(b, a)
		)
	end

	function NanoFormat.remap(
		value: MathValue,
		inMin: MathValue,
		inMax: MathValue,
		outMin: MathValue,
		outMax: MathValue
	): buffer
		local t = NanoFormat.inverseLerp(inMin, inMax, value)

		if NanoFormat.isNaN(t) then
			return t
		end

		return NanoFormat.lerp(outMin, outMax, t)
	end

	function NanoFormat.sum(values: MathValueArray): buffer
		local total = NanoFormat.fromNumber(0)

		for i = 1, #values do
			total = NanoFormat.add(total, values[i])
		end

		return total
	end

	function NanoFormat.product(values: MathValueArray): buffer
		local total = NanoFormat.fromNumber(1)

		for i = 1, #values do
			total = NanoFormat.mul(total, values[i])
		end

		return total
	end

	function NanoFormat.mean(values: MathValueArray): buffer
		local count = #values

		if count == 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.div(NanoFormat.sum(values), count)
	end

	local function mathFactorialLog10(n: number): number
		if n < 2 then
			return 0
		end

		if n <= 256 then
			local total = 0

			for i = 2, n do
				total += log10(i)
			end

			return total
		end

		local inv = 1 / n
		local correction =
			inv / 12
		- (inv ^ 3) / 360
			+ (inv ^ 5) / 1260

		return (n + 0.5) * log10(n)
		- n * MATH_LOG10_E
			+ 0.5 * log10(MATH_TWO_PI)
			+ correction * MATH_LOG10_E
	end

	function NanoFormat.permutation(nValue: MathValue, rValue: MathValue): buffer
		local n = mathExactSafeInteger(nValue)
		local r = mathExactSafeInteger(rValue)

		if n == nil or r == nil or n < 0 or r < 0 or r > n then
			return makeSpecial(SPECIAL_NAN)
		end
		if r == 0 then
			return NanoFormat.fromNumber(1)
		end

		if r <= 4096 then
			local exact = 1
			local exactSafe = true
			local logResult = 0

			for i = 0, r - 1 do
				local term = n - i
				logResult += log10(term)

				if exactSafe then
					if term == 0 or exact > MATH_SAFE_INTEGER / term then
						exactSafe = false
					else
						exact *= term
					end
				end
			end

			if exactSafe then
				return NanoFormat.fromNumber(exact)
			end
			return mathFromSignedLog(logResult, false)
		end

		return mathFromSignedLog(
			mathFactorialLog10(n) - mathFactorialLog10(n - r),
			false
		)
	end

	function NanoFormat.combination(nValue: MathValue, rValue: MathValue): buffer
		local n = mathExactSafeInteger(nValue)
		local r = mathExactSafeInteger(rValue)

		if n == nil or r == nil or n < 0 or r < 0 or r > n then
			return makeSpecial(SPECIAL_NAN)
		end

		r = min(r, n - r)
		if r == 0 then
			return NanoFormat.fromNumber(1)
		end

		if r <= 4096 then
			local exact = 1
			local exactSafe = true
			local logResult = 0

			for i = 1, r do
				local numerator = n - r + i
				logResult += log10(numerator) - log10(i)

				if exactSafe then
					local candidate = exact * numerator / i
					local rounded = floor(candidate + 0.5)

					if candidate > MATH_SAFE_INTEGER
						or abs(candidate - rounded) > 1e-7
					then
						exactSafe = false
					else
						exact = rounded
					end
				end
			end

			if exactSafe then
				return NanoFormat.fromNumber(exact)
			end
			return mathFromSignedLog(logResult, false)
		end

		return mathFromSignedLog(
			mathFactorialLog10(n)
			- mathFactorialLog10(r)
			- mathFactorialLog10(n - r),
			false
		)
	end

	local function mathScalarSlog10(value: number): number
		if value <= 0 then
			return MATH_NAN
		end

		local count = 0
		local x = value

		while x > 10 and count < 1024 do
			x = log10(x)
			count += 1
		end

		if x >= 1 then
			return count + log10(x)
		end

		while x > 0 and x < 1 and count > -1024 do
			x = 10 ^ x
			count -= 1

			if x >= 1 then
				break
			end
		end

		return count + log10(x)
	end

	function NanoFormat.isPositive(value: MathValue): boolean
		return NanoFormat.gt(value, 0)
	end

	function NanoFormat.isNegative(value: MathValue): boolean
		return NanoFormat.lt(value, 0)
	end

	local function mathSlowIsOdd(value: any): boolean
		local n = mathExactSafeInteger(value)
		if n ~= nil then
			return abs(n) % 2 == 1
		end

		local _, data = mathDecode(value)
		if data.Kind == "Log"
			and not data.Reciprocal
			and data.Top >= 0
			and data.Top == floor(data.Top)
		then
			return data.Top == 0
		end

		return false
	end

	function NanoFormat.gcd(a: MathValue, b: MathValue): buffer
		local x = mathExactSafeInteger(a)
		local y = mathExactSafeInteger(b)

		if x == nil or y == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		x = abs(x)
		y = abs(y)

		while y ~= 0 do
			x, y = y, x % y
		end

		return NanoFormat.fromNumber(x)
	end

	function NanoFormat.lcm(a: MathValue, b: MathValue): buffer
		local x = mathExactSafeInteger(a)
		local y = mathExactSafeInteger(b)

		if x == nil or y == nil then
			return makeSpecial(SPECIAL_NAN)
		end
		if x == 0 or y == 0 then
			return NanoFormat.fromNumber(0)
		end

		local g = NanoFormat.toNumber(NanoFormat.gcd(x, y))
		local ax = abs(x / g)
		local ay = abs(y)

		if ax <= MATH_SAFE_INTEGER / ay then
			return NanoFormat.fromNumber(ax * ay)
		end

		return mathFromSignedLog(log10(ax) + log10(ay), false)
	end

	function NanoFormat.square(value: MathValue): buffer
		return NanoFormat.mul(value, value)
	end

	function NanoFormat.cube(value: MathValue): buffer
		return NanoFormat.mul(NanoFormat.mul(value, value), value)
	end

	function NanoFormat.expm1(value: MathValue): buffer
		local direct = NanoFormat.toNumber(value)

		if direct == direct
			and direct ~= huge
			and direct ~= -huge
			and abs(direct) < 1e-5
		then
			local x = direct
			local x2 = x * x
			local x3 = x2 * x
			local x4 = x3 * x
			local x5 = x4 * x
			local x6 = x5 * x

			return NanoFormat.fromNumber(
				x + x2 / 2 + x3 / 6 + x4 / 24 + x5 / 120 + x6 / 720
			)
		end

		return NanoFormat.sub(NanoFormat.exp(value), 1)
	end

	function NanoFormat.distance(a: MathValue, b: MathValue): buffer
		return NanoFormat.abs(NanoFormat.sub(a, b))
	end

	function NanoFormat.ratio(a: MathValue, b: MathValue): buffer
		return NanoFormat.div(a, b)
	end

	function NanoFormat.orderOfMagnitude(value: MathValue): buffer
		if NanoFormat.isZero(value) or NanoFormat.isNaN(value) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.floor(NanoFormat.log10(NanoFormat.abs(value)))
	end

	function NanoFormat.digitCount(value: MathValue): buffer
		if NanoFormat.isNaN(value) or NanoFormat.isInfinite(value) then
			return makeSpecial(SPECIAL_NAN)
		end

		local magnitude = NanoFormat.abs(value)
		if NanoFormat.lt(magnitude, 1) then
			return NanoFormat.fromNumber(1)
		end

		return NanoFormat.add(
			NanoFormat.floor(NanoFormat.log10(magnitude)),
			1
		)
	end

	function NanoFormat.clamp01(value: MathValue): buffer
		return NanoFormat.clamp(value, 0, 1)
	end

	function NanoFormat.smoothstep(edge0: MathValue, edge1: MathValue, value: MathValue): buffer
		local t = NanoFormat.clamp01(NanoFormat.inverseLerp(edge0, edge1, value))
		return NanoFormat.mul(
			NanoFormat.mul(t, t),
			NanoFormat.sub(3, NanoFormat.mul(2, t))
		)
	end

	function NanoFormat.smootherstep(edge0: MathValue, edge1: MathValue, value: MathValue): buffer
		local t = NanoFormat.clamp01(NanoFormat.inverseLerp(edge0, edge1, value))
		local t2 = NanoFormat.mul(t, t)
		local t3 = NanoFormat.mul(t2, t)

		return NanoFormat.mul(
			t3,
			NanoFormat.add(
				NanoFormat.mul(t, NanoFormat.sub(NanoFormat.mul(6, t), 15)),
				10
			)
		)
	end

	function NanoFormat.moveTowards(current: MathValue, target: MathValue, maxDelta: MathValue): buffer
		if NanoFormat.lt(maxDelta, 0) then
			return makeSpecial(SPECIAL_NAN)
		end

		local delta = NanoFormat.sub(target, current)
		if NanoFormat.lte(NanoFormat.abs(delta), maxDelta) then
			return mathCopyBuffer(target)
		end

		return NanoFormat.add(
			current,
			NanoFormat.mul(maxDelta, NanoFormat.sign(delta))
		)
	end

	function NanoFormat.geometricMean(values: MathValueArray): buffer
		local count = #values
		if count == 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		local logTotal = NanoFormat.fromNumber(0)
		for i = 1, count do
			if NanoFormat.lte(values[i], 0) then
				return makeSpecial(SPECIAL_NAN)
			end
			logTotal = NanoFormat.add(logTotal, NanoFormat.log10(values[i]))
		end

		return NanoFormat.pow10(NanoFormat.div(logTotal, count))
	end

	function NanoFormat.harmonicMean(values: MathValueArray): buffer
		local count = #values
		if count == 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		local reciprocalSum = NanoFormat.fromNumber(0)
		for i = 1, count do
			if NanoFormat.isZero(values[i]) then
				return NanoFormat.fromNumber(0)
			end
			reciprocalSum = NanoFormat.add(
				reciprocalSum,
				NanoFormat.reciprocal(values[i])
			)
		end

		return NanoFormat.div(count, reciprocalSum)
	end

	function NanoFormat.arithmeticSeries(first: MathValue, difference: MathValue, countValue: MathValue): buffer
		local count = mathExactSafeInteger(countValue)
		if count == nil or count < 0 then
			return makeSpecial(SPECIAL_NAN)
		end
		if count == 0 then
			return NanoFormat.fromNumber(0)
		end

		return NanoFormat.mul(
			NanoFormat.div(count, 2),
			NanoFormat.add(
				NanoFormat.mul(2, first),
				NanoFormat.mul(count - 1, difference)
			)
		)
	end

	function NanoFormat.geometricSeries(first: MathValue, ratioValue: MathValue, countValue: MathValue): buffer
		local count = mathExactSafeInteger(countValue)
		if count == nil or count < 0 then
			return makeSpecial(SPECIAL_NAN)
		end
		if count == 0 then
			return NanoFormat.fromNumber(0)
		elseif NanoFormat.eq(ratioValue, 1) then
			return NanoFormat.mul(first, count)
		end

		return NanoFormat.mul(
			first,
			NanoFormat.div(
				NanoFormat.sub(NanoFormat.pow(ratioValue, count), 1),
				NanoFormat.sub(ratioValue, 1)
			)
		)
	end

	function NanoFormat.compound(principal: MathValue, rate: MathValue, periods: MathValue): buffer
		return NanoFormat.mul(
			principal,
			NanoFormat.pow(NanoFormat.add(1, rate), periods)
		)
	end

	function NanoFormat.softcap(value: MathValue, start: MathValue, power: MathValue): buffer
		if NanoFormat.lte(start, 0)
			or NanoFormat.lte(power, 0)
			or NanoFormat.isNaN(value)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.lte(value, start) then
			return mathCopyBuffer(value)
		end

		return NanoFormat.mul(
			start,
			NanoFormat.pow(NanoFormat.div(value, start), power)
		)
	end

	function NanoFormat.inverseSoftcap(value: MathValue, start: MathValue, power: MathValue): buffer
		if NanoFormat.lte(start, 0) or NanoFormat.lte(power, 0) then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.lte(value, start) then
			return mathCopyBuffer(value)
		end

		return NanoFormat.mul(
			start,
			NanoFormat.pow(
				NanoFormat.div(value, start),
				NanoFormat.reciprocal(power)
			)
		)
	end

	function NanoFormat.diminishingReturns(value: MathValue, scale: MathValue): buffer
		if NanoFormat.lte(scale, 0) or NanoFormat.lt(value, 0) then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.mul(
			scale,
			NanoFormat.neg(
				NanoFormat.expm1(NanoFormat.neg(NanoFormat.div(value, scale)))
			)
		)
	end

	local MATH_LANCZOS = {
		676.5203681218851,
		-1259.1392167224028,
		771.32342877765313,
		-176.61502916214059,
		12.507343278686905,
		-0.13857109526572012,
		9.9843695780195716e-6,
		1.5056327351493116e-7,
	}

	local function mathLogGammaDirect(x: number): number
		if x <= 0 then
			return MATH_NAN
		end

		local z = x - 1
		local a = 0.99999999999980993

		for i = 1, #MATH_LANCZOS do
			a += MATH_LANCZOS[i] / (z + i)
		end

		local t = z + 7.5
		return 0.5 * math.log(2 * math.pi)
			+ (z + 0.5) * math.log(t)
		- t
			+ math.log(a)
	end

	function NanoFormat.sigmoid(value: MathValue): buffer
		if NanoFormat.gte(value, 0) then
			return NanoFormat.div(
				1,
				NanoFormat.add(1, NanoFormat.exp(NanoFormat.neg(value)))
			)
		end

		local e = NanoFormat.exp(value)
		return NanoFormat.div(e, NanoFormat.add(1, e))
	end

	local function mathV4IsActualZero(data): boolean
		return mathIsZeroData(data)
	end

	local function mathV4IsPositiveInfinityData(data): boolean
		return data.Kind == "Infinity" and not data.Negative
	end

	local function mathSlowFloor(value: any): buffer
		local original, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" or data.Kind == "Integer" then
			return original
		end

		local direct = mathFiniteNumberData(data)

		if direct ~= nil then
			if direct == 0 and not mathV4IsActualZero(data) then
				return NanoFormat.fromNumber(
					mathNegativeData(data) and -1 or 0
				)
			end

			return NanoFormat.fromNumber(floor(direct))
		end

		if data.Kind == "Log" or data.Kind == "Layer" then
			if data.Reciprocal then
				return NanoFormat.fromNumber(
					mathNegativeData(data) and -1 or 0
				)
			end

			return original
		end

		return original
	end

	local function mathSlowCeil(value: any): buffer
		local original, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" or data.Kind == "Integer" then
			return original
		end

		local direct = mathFiniteNumberData(data)

		if direct ~= nil then
			if direct == 0 and not mathV4IsActualZero(data) then
				return NanoFormat.fromNumber(
					mathNegativeData(data) and 0 or 1
				)
			end

			return NanoFormat.fromNumber(math.ceil(direct))
		end

		if data.Kind == "Log" or data.Kind == "Layer" then
			if data.Reciprocal then
				return NanoFormat.fromNumber(
					mathNegativeData(data) and 0 or 1
				)
			end

			return original
		end

		return original
	end

	function NanoFormat.fmod(a: MathValue, b: MathValue): buffer
		local ai, bi = mathExactModuloInputs(a, b)

		if ai == nil or bi == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		local remainder = ai % bi

		if remainder ~= 0
			and ((remainder < 0) ~= (ai < 0))
		then
			remainder -= bi
		end

		return NanoFormat.fromNumber(remainder)
	end

	function NanoFormat.divmod(a: MathValue, b: MathValue): (buffer, buffer)
		local ai, bi = mathExactModuloInputs(a, b)

		if ai == nil or bi == nil then
			local nan = makeSpecial(SPECIAL_NAN)
			return nan, nan
		end

		local remainder = ai % bi
		local quotient = (ai - remainder) / bi

		return NanoFormat.fromNumber(quotient),	NanoFormat.fromNumber(remainder)
	end

	function NanoFormat.clamp(value: MathValue, low: MathValue, high: MathValue): buffer
		if NanoFormat.isNaN(value)
			or NanoFormat.isNaN(low)
			or NanoFormat.isNaN(high)
			or NanoFormat.gt(low, high)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.lt(value, low) then
			return mathCoerce(low)
		elseif NanoFormat.gt(value, high) then
			return mathCoerce(high)
		end

		return mathCoerce(value)
	end

	local function mathSlowIsInteger(value: any): boolean
		if mathExactSafeInteger(value) ~= nil then
			return true
		end

		local _, data = mathDecode(value)

		if data.Kind == "Log" then
			return not data.Reciprocal
				and data.Top >= 0
				and data.Top == floor(data.Top)
		elseif data.Kind == "Layer" then
			return not data.LayerIsLog
				and not data.Reciprocal
				and data.Top >= 0
				and data.Top == floor(data.Top)
		end

		return false
	end

	local function mathSlowPow(base: any, exponent: any): buffer
		local _, db = mathDecode(base)
		local _, de = mathDecode(exponent)

		if db.Kind == "NaN" or db.Kind == "Reserved"
			or de.Kind == "NaN" or de.Kind == "Reserved"
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if mathIsZeroData(de) then
			return NanoFormat.fromNumber(1)
		end

		if mathIsZeroData(db) then
			local zeroData = decodeAt(NanoFormat.fromNumber(0), 0)
			local cmp = mathCompareData(de, zeroData)

			if cmp > 0 then
				return NanoFormat.fromNumber(0)
			elseif cmp < 0 then
				return makeSpecial(SPECIAL_POS_INF)
			end

			return NanoFormat.fromNumber(1)
		end

		local baseNegative = mathNegativeData(db)
		local positiveBase = NanoFormat.abs(base)

		if not baseNegative and NanoFormat.eq(positiveBase, 1) then
			return NanoFormat.fromNumber(1)
		end

		local negativeResult = false

		if baseNegative then
			if not NanoFormat.isInteger(exponent) then
				return makeSpecial(SPECIAL_NAN)
			end

			negativeResult = NanoFormat.isOdd(exponent)

			if NanoFormat.eq(positiveBase, 1) then
				return NanoFormat.fromNumber(
					negativeResult and -1 or 1
				)
			end
		end

		local logarithm = NanoFormat.log10(positiveBase)
		local scaled = NanoFormat.mul(exponent, logarithm)
		local result = NanoFormat.pow10(scaled)

		if negativeResult then
			return NanoFormat.neg(result)
		end

		return result
	end

	function NanoFormat.relativeDifference(a: MathValue, b: MathValue): buffer
		if NanoFormat.isNaN(a) or NanoFormat.isNaN(b) then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.eq(a, b) then
			return NanoFormat.fromNumber(0)
		end

		if NanoFormat.isInfinite(a) or NanoFormat.isInfinite(b) then
			return makeSpecial(SPECIAL_NAN)
		end

		local scale = NanoFormat.max(
			NanoFormat.abs(a),
			NanoFormat.abs(b)
		)

		if NanoFormat.isZero(scale) then
			return NanoFormat.fromNumber(0)
		end

		return NanoFormat.div(
			NanoFormat.distance(a, b),
			scale
		)
	end

	function NanoFormat.approxEq(
		a: MathValue,
		b: MathValue,
		relativeTolerance: MathValue?,
		absoluteTolerance: MathValue?
	): boolean
		if NanoFormat.isNaN(a) or NanoFormat.isNaN(b) then
			return false
		end

		local rel = relativeTolerance or 1e-9
		local absTol = absoluteTolerance or 0

		if NanoFormat.isNaN(rel)
			or NanoFormat.isNaN(absTol)
			or NanoFormat.lt(rel, 0)
			or NanoFormat.lt(absTol, 0)
		then
			return false
		end

		if NanoFormat.eq(a, b) then
			return true
		end

		if NanoFormat.isInfinite(a) or NanoFormat.isInfinite(b) then
			return false
		end

		local diff = NanoFormat.distance(a, b)

		if NanoFormat.lte(diff, absTol) then
			return true
		end

		local scale = NanoFormat.max(
			NanoFormat.abs(a),
			NanoFormat.abs(b)
		)

		return NanoFormat.lte(
			diff,
			NanoFormat.mul(scale, rel)
		)
	end

	local function mathV7OldSlog10(value: any): buffer
		local _, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved"
			or mathNegativeData(data)
			or mathIsZeroData(data)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if data.Kind == "Infinity" then
			return data.Negative
				and makeSpecial(SPECIAL_NAN)
				or makeSpecial(SPECIAL_POS_INF)
		end

		if data.Kind == "Layer" then
			local topPart = mathScalarSlog10(data.Top)

			if topPart ~= topPart then
				return makeSpecial(SPECIAL_NAN)
			end

			local height

			if data.LayerIsLog then
				height = NanoFormat.fromLog10(data.LayerLog10)
			else
				height = NanoFormat.fromNumber(data.Layer)
			end

			if data.Reciprocal then
				height = NanoFormat.neg(height)
			end

			return NanoFormat.add(height, topPart)
		end

		if data.Kind == "Log" then
			if data.Reciprocal then
				local direct = NanoFormat.toNumber(value)

				if direct > 0 then
					return NanoFormat.fromNumber(
						mathScalarSlog10(direct)
					)
				end

				return NanoFormat.fromNumber(-1)
			end

			local inner = mathScalarSlog10(data.Top)

			if inner ~= inner then
				return makeSpecial(SPECIAL_NAN)
			end

			return NanoFormat.fromNumber(1 + inner)
		end

		local direct = NanoFormat.toNumber(value)

		if direct <= 0 or direct == huge then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.fromNumber(
			mathScalarSlog10(direct)
		)
	end

	function NanoFormat.factorial(value: MathValue): buffer
		local _, data = mathDecode(value)

		if data.Kind == "NaN" or data.Kind == "Reserved"
			or mathNegativeData(data)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if mathV4IsPositiveInfinityData(data) then
			return makeSpecial(SPECIAL_POS_INF)
		end

		if not NanoFormat.isInteger(value) then
			return makeSpecial(SPECIAL_NAN)
		end

		local n = mathExactSafeInteger(value)

		if n ~= nil then
			if n <= 1 then
				return NanoFormat.fromNumber(1)
			elseif n <= 20 then
				local result = 1

				for i = 2, n do
					result *= i
				end

				return NanoFormat.fromNumber(result)
			end

			return mathFromSignedLog(
				mathFactorialLog10(n),
				false
			)
		end

		return NanoFormat.factorialReal(value)
	end

	local MATH0_INFINITY = 4
	local MATH0_NAN = 5

	local function mathIntegerBuffer0(value: buffer, knownHeader8: number?): (boolean, number)
		local header8 = knownHeader8
		if header8 == nil then
			header8 = bufferReadBits(value, 0, 8)
		end

		if band(header8, 1) == 0 then
			return true, floor(header8 / 2)
		end

		if band(header8, 3) == 1 then
			return true, -(floor(header8 / 4) + 1)
		end

		if band(header8, 7) ~= 3 then
			return false, 0
		end

		local header9 = bufferReadBits(value, 0, 9)
		local negative = band(header9, 8) ~= 0
		local n = floor(header9 / 16)
		local payloadOffset = 9

		if n == 0 then
			local header14 = bufferReadBits(value, 0, 14)
			n = 32 + floor(header14 / 512)
			payloadOffset = 14
		end

		local magnitude = readUIntExactAtFast(value, payloadOffset, n)
		return true, negative and -magnitude or magnitude
	end

	local function mathSignedLogBuffer0(
		value: buffer
	): (boolean, boolean, number, boolean)
		local header8 = bufferReadBits(value, 0, 8)

		if band(header8, 1) == 0 then
			local n = floor(header8 / 2)
			if n == 0 then
				return true, false, 0, true
			end
			return true, false, log10(n), false
		end

		if band(header8, 3) == 1 then
			local magnitude = floor(header8 / 4) + 1
			return true, true, log10(magnitude), false
		end

		if band(header8, 7) == 3 then
			local ok, n = mathIntegerBuffer0(value, header8)
			if not ok or n == 0 then
				return ok, false, 0, n == 0
			end
			return true, n < 0, log10(abs(n)), false
		end

		if band(header8, 15) == 7 then
			local header15 = bufferReadBits(value, 0, 15)
			local negative = band(header15, 16) ~= 0
			local expCode = floor(header15 / 32)
			local mantCode = bufferReadBits(value, 15, NORMAL_MANT_BITS)
			local mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX)
			return true,negative,(expCode - NORMAL_EXP_BIAS) + log10(mantissa), false
		end

		if band(header8, 31) == 15 then
			local negative = band(header8, 32) ~= 0
			local reciprocal = band(header8, 64) ~= 0
			local top = readScalarAtFast(value, 7)
			return true,negative,reciprocal and -top or top,false
		end

		return false, false, 0, false
	end

	local function mathLayerBuffer0(
		value: buffer
	): (boolean, boolean, boolean, number, boolean, number)
		local header8 = bufferReadBits(value, 0, 8)
		if band(header8, 63) ~= 31 then
			return false, false, false, 0, false, 0
		end

		local negative = band(header8, 64) ~= 0
		local reciprocal = band(header8, 128) ~= 0
		local layer, layerIsLog, topOffset = readLayerFieldAtFast(value, 8)
		local top = readScalarAtFast(value, topOffset)
		return true, negative, reciprocal, layer, layerIsLog, top
	end

	local function mathSpecialBuffer0(value: buffer): (boolean, number, boolean)
		local header8 = bufferReadBits(value, 0, 8)
		if band(header8, 63) ~= 63 then
			return false, -1, false
		end

		local special = floor(header8 / 64)
		if special == SPECIAL_POS_INF then
			return true, MATH0_INFINITY, false
		elseif special == SPECIAL_NEG_INF then
			return true, MATH0_INFINITY, true
		end
		return true, MATH0_NAN, false
	end

	local function mathAddLogs0(
		a: buffer,
		b: buffer,
		subtractB: boolean
	): buffer?
		local okA, negA, logA, zeroA = mathSignedLogBuffer0(a)
		local okB, negB, logB, zeroB = mathSignedLogBuffer0(b)

		if not okA or not okB then
			return nil
		end

		if subtractB and not zeroB then
			negB = not negB
		end

		if zeroA then
			if zeroB then
				return NanoFormat.fromNumber(0)
			end

			return mathFromSignedLog(logB, negB)
		elseif zeroB then
			return mathFromSignedLog(logA, negA)
		end

		if negA == negB then
			local hi = max(logA, logB)
			local lo = min(logA, logB)
			local delta = hi - lo

			if delta > 18 then
				return mathFromSignedLog(hi, negA)
			end

			return mathFromSignedLog(
				hi + log10(1 + 10 ^ (-delta)),
				negA
			)
		end

		if logA == logB then
			return NanoFormat.fromNumber(0)
		end

		local hi
		local lo
		local negative

		if logA > logB then
			hi = logA
			lo = logB
			negative = negA
		else
			hi = logB
			lo = logA
			negative = negB
		end

		local delta = hi - lo

		if delta > 18 then
			return mathFromSignedLog(hi, negative)
		end

		local term = 1 - 10 ^ (-delta)

		if term <= 0 then
			return NanoFormat.fromNumber(0)
		end

		return mathFromSignedLog(
			hi + log10(term),
			negative
		)
	end

	local function mathMulLogs0(
		a: buffer,
		b: buffer,
		divide: boolean
	): buffer?
		local okA, negA, logA, zeroA = mathSignedLogBuffer0(a)
		local okB, negB, logB, zeroB = mathSignedLogBuffer0(b)

		if not okA or not okB then
			return nil
		end

		if divide then
			if zeroB then
				return nil
			elseif zeroA then
				return NanoFormat.fromNumber(0)
			end
		else
			if zeroA or zeroB then
				return NanoFormat.fromNumber(0)
			end
		end

		local negative = negA ~= negB
		local direct
		local top
		local scalarNegative

		if divide then
			direct, top, scalarNegative = mathScalarAdd(logA, -logB)
		else
			direct, top, scalarNegative = mathScalarAdd(logA, logB)
		end

		return mathResultFromLogScalar(
			direct,
			top,
			scalarNegative,
			negative
		)
	end

	local function mathCompareBuffer0(a: buffer, b: buffer): number?
		local okA, negA, logA, zeroA = mathSignedLogBuffer0(a)
		local okB, negB, logB, zeroB = mathSignedLogBuffer0(b)

		if not okA or not okB then
			return nil
		end

		if zeroA then
			if zeroB then
				return 0
			end

			return negB and 1 or -1
		elseif zeroB then
			return negA and -1 or 1
		end

		if negA ~= negB then
			return negA and -1 or 1
		end

		if logA < logB then
			return negA and 1 or -1
		elseif logA > logB then
			return negA and -1 or 1
		end

		return 0
	end

	function NanoFormat.sign(value: MathValue): number
		if typeof(value) == "number" then
			if value ~= value then
				return MATH_NAN
			elseif value < 0 then
				return -1
			elseif value > 0 then
				return 1
			end

			return 0
		end

		if typeof(value) == "buffer" then
			local ok, negative, _, zero = mathSignedLogBuffer0(value)

			if ok then
				if zero then
					return 0
				end

				return negative and -1 or 1
			end

			local isSpecial, kind, specialNegative = mathSpecialBuffer0(value)

			if isSpecial then
				if kind == MATH0_NAN then
					return MATH_NAN
				end

				return specialNegative and -1 or 1
			end

			local isLayer, layerNegative =
				mathLayerBuffer0(value)

			if isLayer then
				return layerNegative and -1 or 1
			end
		end

		return mathSlowSign(value)
	end

	function NanoFormat.neg(value: MathValue): buffer
		if typeof(value) == "number" then
			return NanoFormat.fromNumber(-value)
		end

		if typeof(value) == "buffer" then
			local exact, integer = mathIntegerBuffer0(value)

			if exact then
				return NanoFormat.fromNumber(-integer)
			end

			local ok, negative, logMagnitude, zero =
				mathSignedLogBuffer0(value)

			if ok then
				if zero then
					return NanoFormat.fromNumber(0)
				end

				return mathFromSignedLog(
					logMagnitude,
					not negative
				)
			end

			local isLayer, negativeLayer, reciprocal, layer, layerIsLog, top =
				mathLayerBuffer0(value)

			if isLayer then
				if layerIsLog then
					return NanoFormat.fromLayerLog10(
						layer,
						top,
						not negativeLayer,
						reciprocal
					)
				end

				return NanoFormat.fromLayer(
					layer,
					top,
					not negativeLayer,
					reciprocal
				)
			end
		end

		return mathSlowNeg(value)
	end

	function NanoFormat.abs(value: MathValue): buffer
		if typeof(value) == "number" then
			return NanoFormat.fromNumber(abs(value))
		end

		if typeof(value) == "buffer" then
			if NanoFormat.sign(value) >= 0 then
				return value
			end

			return NanoFormat.neg(value)
		end

		return mathSlowAbs(value)
	end

	function NanoFormat.reciprocal(value: MathValue): buffer
		if typeof(value) == "number" then
			if value == 0 then
				return makeSpecial(SPECIAL_POS_INF)
			end

			local result = 1 / value

			if result ~= 0
				and result ~= huge
				and result ~= -huge
			then
				return NanoFormat.fromNumber(result)
			end
		end

		if typeof(value) == "buffer" then
			local ok, negative, logMagnitude, zero =
				mathSignedLogBuffer0(value)

			if ok then
				if zero then
					return makeSpecial(SPECIAL_POS_INF)
				end

				return mathFromSignedLog(
					-logMagnitude,
					negative
				)
			end

			local isLayer, layerNegative, reciprocal, layer, layerIsLog, top =
				mathLayerBuffer0(value)

			if isLayer then
				if layerIsLog then
					return NanoFormat.fromLayerLog10(
						layer,
						top,
						layerNegative,
						not reciprocal
					)
				end

				return NanoFormat.fromLayer(
					layer,
					top,
					layerNegative,
					not reciprocal
				)
			end
		end

		return mathSlowReciprocal(value)
	end

	function NanoFormat.log10(value: MathValue): buffer
		if typeof(value) == "number" then
			if value < 0 or value ~= value then
				return makeSpecial(SPECIAL_NAN)
			elseif value == 0 then
				return makeSpecial(SPECIAL_NEG_INF)
			elseif value == huge then
				return makeSpecial(SPECIAL_POS_INF)
			end

			return NanoFormat.fromNumber(log10(value))
		end

		if typeof(value) == "buffer" then
			local ok, negative, logMagnitude, zero =
				mathSignedLogBuffer0(value)

			if ok then
				if negative then
					return makeSpecial(SPECIAL_NAN)
				elseif zero then
					return makeSpecial(SPECIAL_NEG_INF)
				end

				return NanoFormat.fromNumber(logMagnitude)
			end

			local isLayer, layerNegative, reciprocal, layer, layerIsLog, top =
				mathLayerBuffer0(value)

			if isLayer then
				if layerNegative then
					return makeSpecial(SPECIAL_NAN)
				end

				if layerIsLog then
					return NanoFormat.fromLayerLog10(
						layer,
						top,
						reciprocal,
						false
					)
				elseif layer == 2 then
					return NanoFormat.fromLog10(
						top,
						reciprocal
					)
				end

				return NanoFormat.fromLayer(
					layer - 1,
					top,
					reciprocal,
					false
				)
			end
		end

		return mathSlowLog10(value)
	end

	function NanoFormat.toNumber(value: MathValue): number
		local kind = typeof(value)
		if kind == "number" then
			return value
		end

		if kind == "buffer" then
			local header8 = bufferReadBits(value, 0, 8)

			if band(header8, 7) == 3 or band(header8, 3) == 1 or band(header8, 1) == 0 then
				local exact, integer = mathIntegerBuffer0(value, header8)
				if exact then
					return integer
				end
			end

			if band(header8, 15) == 7 then
				local header15 = bufferReadBits(value, 0, 15)
				local negative = band(header15, 16) ~= 0
				local expCode = floor(header15 / 32)
				local mantCode = bufferReadBits(value, 15, NORMAL_MANT_BITS)
				local magnitude =
					decodeMantissa(mantCode, NORMAL_MANT_MAX)
					* (10 ^ (expCode - NORMAL_EXP_BIAS))
				return negative and -magnitude or magnitude
			elseif band(header8, 31) == 15 then
				local negative = band(header8, 32) ~= 0
				local reciprocal = band(header8, 64) ~= 0
				local top = readScalarAtFast(value, 7)
				local exponent = reciprocal and -top or top

				if exponent > MATH_DIRECT_LOG_MAX then
					return negative and -huge or huge
				elseif exponent < MATH_DIRECT_LOG_MIN then
					return negative and -0 or 0
				end

				local magnitude = 10 ^ exponent
				return negative and -magnitude or magnitude
			elseif band(header8, 63) == 31 then
				local negative = band(header8, 64) ~= 0
				local reciprocal = band(header8, 128) ~= 0
				if reciprocal then
					return negative and -0 or 0
				end
				return negative and -huge or huge
			elseif band(header8, 63) == 63 then
				local special = floor(header8 / 64)
				if special == SPECIAL_POS_INF then
					return huge
				elseif special == SPECIAL_NEG_INF then
					return -huge
				end
				return MATH_NAN
			end
		end

		return mathSlowToNumber(value)
	end

	function NanoFormat.isNaN(value: MathValue): boolean
		if typeof(value) == "number" then
			return value ~= value
		elseif typeof(value) == "buffer" then
			local raw = bufferReadBits(value, 0, 6)

			return band(raw, 63) == 63
				and bufferReadBits(value, 6, 2) >= SPECIAL_NAN
		end

		return mathSlowIsNaN(value)
	end

	function NanoFormat.isInfinite(value: MathValue): boolean
		if typeof(value) == "number" then
			return value == huge or value == -huge
		elseif typeof(value) == "buffer" then
			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 63) ~= 63 then
				return false
			end

			local special = bufferReadBits(value, 6, 2)
			return special == SPECIAL_POS_INF
				or special == SPECIAL_NEG_INF
		end

		return mathSlowIsInfinite(value)
	end

	function NanoFormat.isFinite(value: MathValue): boolean
		if typeof(value) == "number" then
			return value == value
				and value ~= huge
				and value ~= -huge
		elseif typeof(value) == "buffer" then
			return not NanoFormat.isNaN(value)
				and not NanoFormat.isInfinite(value)
		end

		return mathSlowIsFinite(value)
	end

	function NanoFormat.isZero(value: MathValue): boolean
		if typeof(value) == "number" then
			return value == 0
		elseif typeof(value) == "buffer" then
			local raw = bufferReadBits(value, 0, 6)

			return band(raw, 1) == 0
				and bufferReadBits(value, 1, 7) == 0
		end

		return mathSlowIsZero(value)
	end

	function NanoFormat.isInteger(value: MathValue): boolean
		if typeof(value) == "number" then
			return value == value
				and value ~= huge
				and value ~= -huge
				and value == floor(value)
		elseif typeof(value) == "buffer" then
			local exact = mathIntegerBuffer0(value)

			if exact then
				return true
			end

			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 31) == 15 then
				local header7 = bufferReadBits(value, 0, 7)
				local reciprocal = band(header7, 64) ~= 0

				if reciprocal then
					return false
				end

				local top = readScalarAtFast(value, 7)
				return top >= 0 and top == floor(top)
			elseif band(raw, 63) == 31 then
				local header8 = bufferReadBits(value, 0, 8)
				local reciprocal = band(header8, 128) ~= 0

				if reciprocal then
					return false
				end

				local layer, layerIsLog, topOffset =
					readLayerFieldAtFast(value, 8)

				if layerIsLog then
					return false
				end

				local top = readScalarAtFast(value, topOffset)

				return top >= 0
					and top == floor(top)
					and layer >= 2
			end

			return false
		end

		return mathSlowIsInteger(value)
	end

	function NanoFormat.isOdd(value: MathValue): boolean
		if typeof(value) == "number" then
			return value == floor(value)
				and abs(value) <= MATH_SAFE_INTEGER
				and abs(value) % 2 == 1
		elseif typeof(value) == "buffer" then
			local exact, integer = mathIntegerBuffer0(value)

			if exact then
				return abs(integer) % 2 == 1
			end

			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 31) == 15 then
				local header7 = bufferReadBits(value, 0, 7)
				local reciprocal = band(header7, 64) ~= 0
				local top = readScalarAtFast(value, 7)

				return not reciprocal and top == 0
			end

			return false
		end

		return mathSlowIsOdd(value)
	end

	function NanoFormat.isEven(value: MathValue): boolean
		if not NanoFormat.isInteger(value) then
			return false
		end

		return not NanoFormat.isOdd(value)
	end

	function NanoFormat.pow10(value: MathValue): buffer
		if typeof(value) == "number" then
			if value ~= value then
				return makeSpecial(SPECIAL_NAN)
			elseif value == huge then
				return makeSpecial(SPECIAL_POS_INF)
			elseif value == -huge then
				return NanoFormat.fromNumber(0)
			end

			return NanoFormat.fromLog10(value)
		end

		if typeof(value) == "buffer" then
			local exact, integer = mathIntegerBuffer0(value)

			if exact then
				return NanoFormat.fromLog10(integer)
			end

			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 15) == 7 then
				local direct = NanoFormat.toNumber(value)
				return NanoFormat.fromLog10(direct)
			elseif band(raw, 31) == 15 then
				local header7 = bufferReadBits(value, 0, 7)
				local negative = band(header7, 32) ~= 0
				local reciprocal = band(header7, 64) ~= 0
				local top = readScalarAtFast(value, 7)

				if reciprocal then
					return NanoFormat.fromNumber(1)
				end

				return NanoFormat.fromLayer(
					2,
					top,
					false,
					negative
				)
			end
		end

		return mathSlowPow10(value)
	end

	function NanoFormat.floor(value: MathValue): buffer
		if typeof(value) == "number" then
			return NanoFormat.fromNumber(floor(value))
		elseif typeof(value) == "buffer" then
			local exact = mathIntegerBuffer0(value)

			if exact then
				return value
			end

			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 31) == 15 then
				local header7 = bufferReadBits(value, 0, 7)
				local negative = band(header7, 32) ~= 0
				local reciprocal = band(header7, 64) ~= 0

				if reciprocal then
					return NanoFormat.fromNumber(
						negative and -1 or 0
					)
				end

				return value
			elseif band(raw, 63) == 31 then
				local header8 = bufferReadBits(value, 0, 8)
				local negative = band(header8, 64) ~= 0
				local reciprocal = band(header8, 128) ~= 0

				if reciprocal then
					return NanoFormat.fromNumber(
						negative and -1 or 0
					)
				end

				return value
			elseif band(raw, 15) == 7 then
				return NanoFormat.fromNumber(
					floor(NanoFormat.toNumber(value))
				)
			end
		end

		return mathSlowFloor(value)
	end

	function NanoFormat.ceil(value: MathValue): buffer
		if typeof(value) == "number" then
			return NanoFormat.fromNumber(math.ceil(value))
		elseif typeof(value) == "buffer" then
			local exact = mathIntegerBuffer0(value)

			if exact then
				return value
			end

			local raw = bufferReadBits(value, 0, 6)

			if band(raw, 31) == 15 then
				local header7 = bufferReadBits(value, 0, 7)
				local negative = band(header7, 32) ~= 0
				local reciprocal = band(header7, 64) ~= 0

				if reciprocal then
					return NanoFormat.fromNumber(
						negative and 0 or 1
					)
				end

				return value
			elseif band(raw, 63) == 31 then
				local header8 = bufferReadBits(value, 0, 8)
				local negative = band(header8, 64) ~= 0
				local reciprocal = band(header8, 128) ~= 0

				if reciprocal then
					return NanoFormat.fromNumber(
						negative and 0 or 1
					)
				end

				return value
			elseif band(raw, 15) == 7 then
				return NanoFormat.fromNumber(
					math.ceil(NanoFormat.toNumber(value))
				)
			end
		end

		return mathSlowCeil(value)
	end

	function NanoFormat.geometricCost(
		baseCost: MathValue,
		growth: MathValue,
		owned: MathValue,
		amount: MathValue
	): buffer
		if NanoFormat.lte(baseCost, 0)
			or NanoFormat.lt(owned, 0)
			or NanoFormat.lt(amount, 0)
			or NanoFormat.lt(growth, 1)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.isZero(amount) then
			return NanoFormat.fromNumber(0)
		end

		local currentCost = NanoFormat.mul(
			baseCost,
			NanoFormat.pow(growth, owned)
		)

		if NanoFormat.eq(growth, 1) then
			return NanoFormat.mul(currentCost, amount)
		end

		return NanoFormat.mul(
			currentCost,
			NanoFormat.div(
				NanoFormat.sub(
					NanoFormat.pow(growth, amount),
					1
				),
				NanoFormat.sub(growth, 1)
			)
		)
	end

	function NanoFormat.maxAffordableGeometric(
		currency: MathValue,
		baseCost: MathValue,
		growth: MathValue,
		owned: MathValue?
	): buffer
		local levelsOwned = owned or 0

		if NanoFormat.lt(currency, 0)
			or NanoFormat.lte(baseCost, 0)
			or NanoFormat.lt(levelsOwned, 0)
			or NanoFormat.lt(growth, 1)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		local currentCost = NanoFormat.mul(
			baseCost,
			NanoFormat.pow(growth, levelsOwned)
		)

		if NanoFormat.lt(currency, currentCost) then
			return NanoFormat.fromNumber(0)
		end

		if NanoFormat.eq(growth, 1) then
			return NanoFormat.floor(
				NanoFormat.div(currency, currentCost)
			)
		end

		local inside = NanoFormat.add(
			1,
			NanoFormat.div(
				NanoFormat.mul(
					currency,
					NanoFormat.sub(growth, 1)
				),
				currentCost
			)
		)

		return NanoFormat.floor(
			NanoFormat.log(inside, growth)
		)
	end

	function NanoFormat.bulkBuyGeometric(
		currency: MathValue,
		baseCost: MathValue,
		growth: MathValue,
		owned: MathValue?
	): (buffer, buffer, buffer)
		local amount = NanoFormat.maxAffordableGeometric(
			currency,
			baseCost,
			growth,
			owned
		)

		if NanoFormat.isNaN(amount) then
			local nan = makeSpecial(SPECIAL_NAN)
			return nan, nan, nan
		end

		local cost = NanoFormat.geometricCost(
			baseCost,
			growth,
			owned or 0,
			amount
		)

		local remaining = NanoFormat.sub(currency, cost)

		if NanoFormat.lt(remaining, 0)
			and NanoFormat.approxEq(remaining, 0, 1e-10, 0)
		then
			remaining = NanoFormat.fromNumber(0)
		end

		return amount, cost, remaining
	end

	function NanoFormat.nextGeometricCost(
		baseCost: MathValue,
		growth: MathValue,
		owned: MathValue
	): buffer
		if NanoFormat.lte(baseCost, 0)
			or NanoFormat.lt(growth, 1)
			or NanoFormat.lt(owned, 0)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.mul(
			baseCost,
			NanoFormat.pow(growth, owned)
		)
	end

	function NanoFormat.mathPerfInfo(): MathPerfInfo
		return {
			Version = NanoFormat.MATH_PERF_VERSION,
			PathVersion = NanoFormat.MATH_PATH_VERSION,
			DefaultPath = NanoFormat.MATH_DEFAULT_PATH,
			Path0 = "canonical buffer / native-number fast path",
			Path1 = "mixed, symbolic, special, or deep-layer fallback",
			TemporaryDecodeTablesOnPath0 = 0,
		}
	end

	NanoFormat.CALL_VERSION = 1
	NanoFormat.DIRECT_CALL_VERSION = 1
	NanoFormat.BIND_VERSION = 1
	NanoFormat.COMPILE_VERSION = 1
	NanoFormat.MATH_PERF_VERSION = 2
	NanoFormat.MATH_PATH_VERSION = 3
	NanoFormat.MATH_DEFAULT_PATH = 0

	local mathV6FallbackAdd = mathSlowAdd
	local mathV6FallbackSub = mathSlowSub
	local mathV6FallbackMul = mathSlowMul
	local mathV6FallbackDiv = mathSlowDiv
	local mathV6FallbackCompare = mathSlowCompare
	local mathV6FallbackPow = mathSlowPow

	local function mathV6AddSignedLogs(
		logA: number,
		negativeA: boolean,
		zeroA: boolean,
		logB: number,
		negativeB: boolean,
		zeroB: boolean
	): buffer
		if zeroA then
			if zeroB then
				return NanoFormat.fromNumber(0)
			end

			return mathFromSignedLog(logB, negativeB)
		elseif zeroB then
			return mathFromSignedLog(logA, negativeA)
		end

		if negativeA == negativeB then
			local hi = max(logA, logB)
			local lo = min(logA, logB)
			local delta = hi - lo

			if delta > 18 then
				return mathFromSignedLog(hi, negativeA)
			end

			return mathFromSignedLog(
				hi + log10(1 + 10 ^ (-delta)),
				negativeA
			)
		end

		if logA == logB then
			return NanoFormat.fromNumber(0)
		end

		local hi
		local lo
		local negative

		if logA > logB then
			hi = logA
			lo = logB
			negative = negativeA
		else
			hi = logB
			lo = logA
			negative = negativeB
		end

		local delta = hi - lo

		if delta > 18 then
			return mathFromSignedLog(hi, negative)
		end

		local term = 1 - 10 ^ (-delta)

		if term <= 0 then
			return NanoFormat.fromNumber(0)
		end

		return mathFromSignedLog(
			hi + log10(term),
			negative
		)
	end

	local function mathV6NumberSignedLog(
		value: number
	): (boolean, number, boolean)
		if value == 0 then
			return false, 0, true
		end

		return value < 0, log10(abs(value)), false
	end

	local function mathV6AddBN(
		a: buffer,
		b: number,
		subtractB: boolean
	): buffer
		if b ~= b or b == huge or b == -huge then
			return subtractB
				and mathV6FallbackSub(a, b)
				or mathV6FallbackAdd(a, b)
		end

		local okA, negativeA, logA, zeroA = mathSignedLogBuffer0(a)

		if not okA then
			return subtractB
				and mathV6FallbackSub(a, b)
				or mathV6FallbackAdd(a, b)
		end

		local negativeB, logB, zeroB = mathV6NumberSignedLog(b)

		if subtractB and not zeroB then
			negativeB = not negativeB
		end

		return mathV6AddSignedLogs(
			logA,
			negativeA,
			zeroA,
			logB,
			negativeB,
			zeroB
		)
	end

	local function mathV6AddNB(
		a: number,
		b: buffer,
		subtractB: boolean
	): buffer
		if a ~= a or a == huge or a == -huge then
			return subtractB
				and mathV6FallbackSub(a, b)
				or mathV6FallbackAdd(a, b)
		end

		local okB, negativeB, logB, zeroB = mathSignedLogBuffer0(b)

		if not okB then
			return subtractB
				and mathV6FallbackSub(a, b)
				or mathV6FallbackAdd(a, b)
		end

		local negativeA, logA, zeroA = mathV6NumberSignedLog(a)

		if subtractB and not zeroB then
			negativeB = not negativeB
		end

		return mathV6AddSignedLogs(
			logA,
			negativeA,
			zeroA,
			logB,
			negativeB,
			zeroB
		)
	end

	local function mathV6MulBN(
		a: buffer,
		b: number,
		divide: boolean
	): buffer
		if b ~= b or b == huge or b == -huge then
			return divide
				and mathV6FallbackDiv(a, b)
				or mathV6FallbackMul(a, b)
		end

		if divide and b == 0 then
			return mathV6FallbackDiv(a, b)
		end

		if not divide and b == 0 then
			local special, _, _ = mathSpecialBuffer0(a)

			if special then
				return mathV6FallbackMul(a, b)
			end

			return NanoFormat.fromNumber(0)
		end

		if b == 1 then
			return a
		elseif not divide and b == -1 then
			return NanoFormat.neg(a)
		end

		local exactA, integerA = mathIntegerBuffer0(a)

		if exactA then
			if divide then
				return NanoFormat.fromNumber(integerA / b)
			end

			local result = integerA * b

			if result == result
				and result ~= huge
				and result ~= -huge
				and (result ~= 0 or integerA == 0)
			then
				return NanoFormat.fromNumber(result)
			end
		end

		local okA, negativeA, logA, zeroA = mathSignedLogBuffer0(a)

		if okA then
			if zeroA then
				return NanoFormat.fromNumber(0)
			end

			local negativeB = b < 0
			local logB = log10(abs(b))
			local negative = negativeA ~= negativeB
			local direct
			local top
			local scalarNegative

			if divide then
				direct, top, scalarNegative =
					mathScalarAdd(logA, -logB)
			else
				direct, top, scalarNegative =
					mathScalarAdd(logA, logB)
			end

			return mathResultFromLogScalar(
				direct,
				top,
				scalarNegative,
				negative
			)
		end

		local isLayer, layerNegative, reciprocal, layer, layerIsLog, top =
			mathLayerBuffer0(a)

		if isLayer then
			local resultNegative = layerNegative ~= (b < 0)

			if not layerIsLog and layer == 2 and top <= MATH_DIRECT_LOG_MAX then
				local towerExponent = 10 ^ top

				if reciprocal then
					towerExponent = -towerExponent
				end

				local logB = log10(abs(b))
				local direct
				local resultTop
				local scalarNegative

				if divide then
					direct, resultTop, scalarNegative =
						mathScalarAdd(towerExponent, -logB)
				else
					direct, resultTop, scalarNegative =
						mathScalarAdd(towerExponent, logB)
				end

				return mathResultFromLogScalar(
					direct,
					resultTop,
					scalarNegative,
					resultNegative
				)
			end

			if layerIsLog then
				return NanoFormat.fromLayerLog10(
					layer,
					top,
					resultNegative,
					reciprocal
				)
			end

			return NanoFormat.fromLayer(
				layer,
				top,
				resultNegative,
				reciprocal
			)
		end

		return divide
			and mathV6FallbackDiv(a, b)
			or mathV6FallbackMul(a, b)
	end

	local function mathV6DivNB(
		a: number,
		b: buffer
	): buffer
		if a ~= a or a == huge or a == -huge then
			return mathV6FallbackDiv(a, b)
		end

		if a == 0 then
			local special, _, _ = mathSpecialBuffer0(b)

			if special then
				return mathV6FallbackDiv(a, b)
			end

			return NanoFormat.fromNumber(0)
		end

		local okB, negativeB, logB, zeroB = mathSignedLogBuffer0(b)

		if okB then
			if zeroB then
				return mathV6FallbackDiv(a, b)
			end

			local negativeA, logA, _ = mathV6NumberSignedLog(a)
			local direct, top, scalarNegative =
				mathScalarAdd(logA, -logB)

			return mathResultFromLogScalar(
				direct,
				top,
				scalarNegative,
				negativeA ~= negativeB
			)
		end

		return mathV6FallbackDiv(a, b)
	end

	local function mathV6CompareBN(a: buffer, b: number): number
		if b ~= b then
			return MATH_NAN
		end

		local okA, negativeA, logA, zeroA = mathSignedLogBuffer0(a)

		if not okA then
			return mathV6FallbackCompare(a, b)
		end

		local negativeB, logB, zeroB = mathV6NumberSignedLog(b)

		if zeroA then
			if zeroB then
				return 0
			end

			return negativeB and 1 or -1
		elseif zeroB then
			return negativeA and -1 or 1
		elseif negativeA ~= negativeB then
			return negativeA and -1 or 1
		end

		if logA < logB then
			return negativeA and 1 or -1
		elseif logA > logB then
			return negativeA and -1 or 1
		end

		return 0
	end

	local function mathV6CompareNB(a: number, b: buffer): number
		local result = mathV6CompareBN(b, a)

		if result ~= result then
			return result
		end

		return -result
	end

	NanoFormat.fast = NanoFormat.fast or {}
	local Fast = NanoFormat.fast

	function Fast.addNN(a: number, b: number): buffer
		local result = a + b

		if result == result and result ~= huge and result ~= -huge then
			return NanoFormat.fromNumber(result)
		end

		return mathV6FallbackAdd(a, b)
	end

	function Fast.subNN(a: number, b: number): buffer
		local result = a - b

		if result == result and result ~= huge and result ~= -huge then
			return NanoFormat.fromNumber(result)
		end

		return mathV6FallbackSub(a, b)
	end

	function Fast.mulNN(a: number, b: number): buffer
		local result = a * b

		if result == result
			and result ~= huge
			and result ~= -huge
			and (result ~= 0 or a == 0 or b == 0)
		then
			return NanoFormat.fromNumber(result)
		end

		return mathV6FallbackMul(a, b)
	end

	function Fast.divNN(a: number, b: number): buffer
		if b ~= 0 then
			local result = a / b

			if result == result
				and result ~= huge
				and result ~= -huge
				and (result ~= 0 or a == 0)
			then
				return NanoFormat.fromNumber(result)
			end
		end

		return mathV6FallbackDiv(a, b)
	end

	function Fast.compareNN(a: number, b: number): number
		if a ~= a or b ~= b then
			return MATH_NAN
		elseif a < b then
			return -1
		elseif a > b then
			return 1
		end

		return 0
	end

	function Fast.powNN(a: number, b: number): buffer
		if a == 1 or b == 0 then
			return NanoFormat.fromNumber(1)
		end

		local result = a ^ b

		if result == result
			and result ~= huge
			and result ~= -huge
			and result ~= 0
		then
			return NanoFormat.fromNumber(result)
		end

		return mathV6FallbackPow(a, b)
	end

	function Fast.addBB(a: buffer, b: buffer): buffer
		local exactA, integerA = mathIntegerBuffer0(a)
		local exactB, integerB = mathIntegerBuffer0(b)

		if exactA and exactB then
			local result = integerA + integerB

			if abs(result) <= MATH_SAFE_INTEGER then
				return NanoFormat.fromNumber(result)
			end
		end

		local result = mathAddLogs0(a, b, false)
		return result or mathV6FallbackAdd(a, b)
	end

	function Fast.subBB(a: buffer, b: buffer): buffer
		local exactA, integerA = mathIntegerBuffer0(a)
		local exactB, integerB = mathIntegerBuffer0(b)

		if exactA and exactB then
			local result = integerA - integerB

			if abs(result) <= MATH_SAFE_INTEGER then
				return NanoFormat.fromNumber(result)
			end
		end

		local result = mathAddLogs0(a, b, true)
		return result or mathV6FallbackSub(a, b)
	end

	function Fast.mulBB(a: buffer, b: buffer): buffer
		local exactA, integerA = mathIntegerBuffer0(a)
		local exactB, integerB = mathIntegerBuffer0(b)

		if exactA and exactB then
			local magnitudeA = abs(integerA)
			local magnitudeB = abs(integerB)

			if integerA == 0 or integerB == 0 then
				return NanoFormat.fromNumber(0)
			elseif magnitudeA <= MATH_SAFE_INTEGER / magnitudeB then
				return NanoFormat.fromNumber(integerA * integerB)
			end
		end

		local result = mathMulLogs0(a, b, false)
		return result or mathV6FallbackMul(a, b)
	end

	function Fast.divBB(a: buffer, b: buffer): buffer
		local exactA, integerA = mathIntegerBuffer0(a)
		local exactB, integerB = mathIntegerBuffer0(b)

		if exactA and exactB and integerB ~= 0 then
			return NanoFormat.fromNumber(integerA / integerB)
		end

		local result = mathMulLogs0(a, b, true)
		return result or mathV6FallbackDiv(a, b)
	end

	function Fast.compareBB(a: buffer, b: buffer): number
		local exactA, integerA = mathIntegerBuffer0(a)
		local exactB, integerB = mathIntegerBuffer0(b)

		if exactA and exactB then
			if integerA < integerB then
				return -1
			elseif integerA > integerB then
				return 1
			end

			return 0
		end

		local result = mathCompareBuffer0(a, b)
		return result == nil
			and mathV6FallbackCompare(a, b)
			or result
	end

	function Fast.powBB(a: buffer, b: buffer): buffer
		local exact, integer = mathIntegerBuffer0(a)

		if exact and integer == 10 then
			return NanoFormat.pow10(b)
		end

		return mathV6FallbackPow(a, b)
	end

	function Fast.addBN(a: buffer, b: number): buffer
		return mathV6AddBN(a, b, false)
	end

	function Fast.addNB(a: number, b: buffer): buffer
		return mathV6AddNB(a, b, false)
	end

	function Fast.subBN(a: buffer, b: number): buffer
		return mathV6AddBN(a, b, true)
	end

	function Fast.subNB(a: number, b: buffer): buffer
		return mathV6AddNB(a, b, true)
	end

	function Fast.mulBN(a: buffer, b: number): buffer
		return mathV6MulBN(a, b, false)
	end

	function Fast.mulNB(a: number, b: buffer): buffer
		return mathV6MulBN(b, a, false)
	end

	function Fast.divBN(a: buffer, b: number): buffer
		return mathV6MulBN(a, b, true)
	end

	function Fast.divNB(a: number, b: buffer): buffer
		return mathV6DivNB(a, b)
	end

	function Fast.compareBN(a: buffer, b: number): number
		return mathV6CompareBN(a, b)
	end

	function Fast.compareNB(a: number, b: buffer): number
		return mathV6CompareNB(a, b)
	end

	function Fast.powBN(a: buffer, b: number): buffer
		return mathV6FallbackPow(a, b)
	end

	function Fast.powNB(a: number, b: buffer): buffer
		if a == 10 then
			return NanoFormat.pow10(b)
		end

		return mathV6FallbackPow(a, b)
	end

	function Fast.addSS(a: string, b: string): buffer
		return Fast.addBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.addSB(a: string, b: buffer): buffer
		return Fast.addBB(NanoFormat.fromString(a), b)
	end

	function Fast.addBS(a: buffer, b: string): buffer
		return Fast.addBB(a, NanoFormat.fromString(b))
	end

	function Fast.addSN(a: string, b: number): buffer
		return Fast.addBN(NanoFormat.fromString(a), b)
	end

	function Fast.addNS(a: number, b: string): buffer
		return Fast.addNB(a, NanoFormat.fromString(b))
	end

	function Fast.subSS(a: string, b: string): buffer
		return Fast.subBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.subSB(a: string, b: buffer): buffer
		return Fast.subBB(NanoFormat.fromString(a), b)
	end

	function Fast.subBS(a: buffer, b: string): buffer
		return Fast.subBB(a, NanoFormat.fromString(b))
	end

	function Fast.subSN(a: string, b: number): buffer
		return Fast.subBN(NanoFormat.fromString(a), b)
	end

	function Fast.subNS(a: number, b: string): buffer
		return Fast.subNB(a, NanoFormat.fromString(b))
	end

	function Fast.mulSS(a: string, b: string): buffer
		return Fast.mulBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.mulSB(a: string, b: buffer): buffer
		return Fast.mulBB(NanoFormat.fromString(a), b)
	end

	function Fast.mulBS(a: buffer, b: string): buffer
		return Fast.mulBB(a, NanoFormat.fromString(b))
	end

	function Fast.mulSN(a: string, b: number): buffer
		return Fast.mulBN(NanoFormat.fromString(a), b)
	end

	function Fast.mulNS(a: number, b: string): buffer
		return Fast.mulNB(a, NanoFormat.fromString(b))
	end

	function Fast.divSS(a: string, b: string): buffer
		return Fast.divBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.divSB(a: string, b: buffer): buffer
		return Fast.divBB(NanoFormat.fromString(a), b)
	end

	function Fast.divBS(a: buffer, b: string): buffer
		return Fast.divBB(a, NanoFormat.fromString(b))
	end

	function Fast.divSN(a: string, b: number): buffer
		return Fast.divBN(NanoFormat.fromString(a), b)
	end

	function Fast.divNS(a: number, b: string): buffer
		return Fast.divNB(a, NanoFormat.fromString(b))
	end

	function Fast.compareSS(a: string, b: string): number
		return Fast.compareBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.compareSB(a: string, b: buffer): number
		return Fast.compareBB(NanoFormat.fromString(a), b)
	end

	function Fast.compareBS(a: buffer, b: string): number
		return Fast.compareBB(a, NanoFormat.fromString(b))
	end

	function Fast.compareSN(a: string, b: number): number
		return Fast.compareBN(NanoFormat.fromString(a), b)
	end

	function Fast.compareNS(a: number, b: string): number
		return Fast.compareNB(a, NanoFormat.fromString(b))
	end

	function Fast.powSS(a: string, b: string): buffer
		return Fast.powBB(NanoFormat.fromString(a), NanoFormat.fromString(b))
	end

	function Fast.powSB(a: string, b: buffer): buffer
		return Fast.powBB(NanoFormat.fromString(a), b)
	end

	function Fast.powBS(a: buffer, b: string): buffer
		return Fast.powBB(a, NanoFormat.fromString(b))
	end

	function Fast.powSN(a: string, b: number): buffer
		return Fast.powBN(NanoFormat.fromString(a), b)
	end

	function Fast.powNS(a: number, b: string): buffer
		return Fast.powNB(a, NanoFormat.fromString(b))
	end

	function NanoFormat.compile(value: MathValue): buffer
		local kind = typeof(value)

		if kind == "buffer" then
			if NanoFormat.isValid(value) then
				return value
			end

			return makeSpecial(SPECIAL_NAN)
		elseif kind == "number" then
			return NanoFormat.fromNumber(value)
		elseif kind == "string" then
			return NanoFormat.fromString(value)
		end

		return makeSpecial(SPECIAL_NAN)
	end

	local DIRECT_BINARY = {
		add = {
			NN = Fast.addNN, BB = Fast.addBB, BN = Fast.addBN, NB = Fast.addNB,
			SS = Fast.addSS, SB = Fast.addSB, BS = Fast.addBS, SN = Fast.addSN, NS = Fast.addNS,
		},
		sub = {
			NN = Fast.subNN, BB = Fast.subBB, BN = Fast.subBN, NB = Fast.subNB,
			SS = Fast.subSS, SB = Fast.subSB, BS = Fast.subBS, SN = Fast.subSN, NS = Fast.subNS,
		},
		mul = {
			NN = Fast.mulNN, BB = Fast.mulBB, BN = Fast.mulBN, NB = Fast.mulNB,
			SS = Fast.mulSS, SB = Fast.mulSB, BS = Fast.mulBS, SN = Fast.mulSN, NS = Fast.mulNS,
		},
		div = {
			NN = Fast.divNN, BB = Fast.divBB, BN = Fast.divBN, NB = Fast.divNB,
			SS = Fast.divSS, SB = Fast.divSB, BS = Fast.divBS, SN = Fast.divSN, NS = Fast.divNS,
		},
		compare = {
			NN = Fast.compareNN, BB = Fast.compareBB, BN = Fast.compareBN, NB = Fast.compareNB,
			SS = Fast.compareSS, SB = Fast.compareSB, BS = Fast.compareBS, SN = Fast.compareSN, NS = Fast.compareNS,
		},
		pow = {
			NN = Fast.powNN, BB = Fast.powBB, BN = Fast.powBN, NB = Fast.powNB,
			SS = Fast.powSS, SB = Fast.powSB, BS = Fast.powBS, SN = Fast.powSN, NS = Fast.powNS,
		},
	}

	local TYPE_CODE = {
		number = "N",
		buffer = "B",
		string = "S",
	}

	local BIND_FALLBACK = {
		add = mathV6FallbackAdd,
		sub = mathV6FallbackSub,
		mul = mathV6FallbackMul,
		div = mathV6FallbackDiv,
		compare = mathV6FallbackCompare,
		pow = mathV6FallbackPow,
	}

	function NanoFormat.bindBinary(
		operation: BindOperation,
		leftType: DirectValueType,
		rightType: DirectValueType
	): BoundBinaryFunction?
		local operationMap = DIRECT_BINARY[operation]

		if operationMap == nil then
			return nil
		end

		local leftCode = TYPE_CODE[leftType] or leftType
		local rightCode = TYPE_CODE[rightType] or rightType

		return operationMap[leftCode .. rightCode]
	end

	function NanoFormat.bindRight(
		operation: MathBinaryOperation,
		constant: MathValue,
		leftType: DirectValueType?
	): BoundUnaryFunction?
		local operationMap = DIRECT_BINARY[operation]
		local fallback = BIND_FALLBACK[operation]

		if operationMap == nil or fallback == nil then
			return nil
		end

		local constantType = typeof(constant)
		local rightCode = TYPE_CODE[constantType]

		if rightCode == nil then
			return nil
		end

		local compiledConstant = constant

		if constantType == "string" then
			compiledConstant = NanoFormat.fromString(constant)
			rightCode = "B"
		end

		if leftType ~= nil then
			local leftCode = TYPE_CODE[leftType] or leftType
			local fn = operationMap[leftCode .. rightCode]

			if fn == nil then
				return nil
			end

			return function(value)
				return fn(value, compiledConstant)
			end
		end

		return function(value)
			local kind = typeof(value)

			if kind == "buffer" then
				local fn = operationMap["B" .. rightCode]

				if fn ~= nil then
					return fn(value, compiledConstant)
				end

				return fallback(value, compiledConstant)
			elseif kind == "number" then
				local fn = operationMap["N" .. rightCode]

				if fn ~= nil then
					return fn(value, compiledConstant)
				end

				return fallback(value, compiledConstant)
			elseif kind == "string" then
				local parsed = NanoFormat.fromString(value)
				local fn = operationMap["B" .. rightCode]

				if fn ~= nil then
					return fn(parsed, compiledConstant)
				end

				return fallback(parsed, compiledConstant)
			end

			return makeSpecial(SPECIAL_NAN)
		end
	end

	function NanoFormat.add(a: MathValue, b: MathValue): buffer
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.addBB(a, b) end
			if tb == "number" then return Fast.addBN(a, b) end
			if tb == "string" then return Fast.addBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.addNB(a, b) end
			if tb == "number" then return Fast.addNN(a, b) end
			if tb == "string" then return Fast.addNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.addSB(a, b) end
			if tb == "number" then return Fast.addSN(a, b) end
			if tb == "string" then return Fast.addSS(a, b) end
		end

		return mathV6FallbackAdd(a, b)
	end

	function NanoFormat.sub(a: MathValue, b: MathValue): buffer
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.subBB(a, b) end
			if tb == "number" then return Fast.subBN(a, b) end
			if tb == "string" then return Fast.subBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.subNB(a, b) end
			if tb == "number" then return Fast.subNN(a, b) end
			if tb == "string" then return Fast.subNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.subSB(a, b) end
			if tb == "number" then return Fast.subSN(a, b) end
			if tb == "string" then return Fast.subSS(a, b) end
		end

		return mathV6FallbackSub(a, b)
	end

	function NanoFormat.mul(a: MathValue, b: MathValue): buffer
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.mulBB(a, b) end
			if tb == "number" then return Fast.mulBN(a, b) end
			if tb == "string" then return Fast.mulBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.mulNB(a, b) end
			if tb == "number" then return Fast.mulNN(a, b) end
			if tb == "string" then return Fast.mulNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.mulSB(a, b) end
			if tb == "number" then return Fast.mulSN(a, b) end
			if tb == "string" then return Fast.mulSS(a, b) end
		end

		return mathV6FallbackMul(a, b)
	end

	function NanoFormat.div(a: MathValue, b: MathValue): buffer
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.divBB(a, b) end
			if tb == "number" then return Fast.divBN(a, b) end
			if tb == "string" then return Fast.divBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.divNB(a, b) end
			if tb == "number" then return Fast.divNN(a, b) end
			if tb == "string" then return Fast.divNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.divSB(a, b) end
			if tb == "number" then return Fast.divSN(a, b) end
			if tb == "string" then return Fast.divSS(a, b) end
		end

		return mathV6FallbackDiv(a, b)
	end

	function NanoFormat.compare(a: MathValue, b: MathValue): number
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.compareBB(a, b) end
			if tb == "number" then return Fast.compareBN(a, b) end
			if tb == "string" then return Fast.compareBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.compareNB(a, b) end
			if tb == "number" then return Fast.compareNN(a, b) end
			if tb == "string" then return Fast.compareNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.compareSB(a, b) end
			if tb == "number" then return Fast.compareSN(a, b) end
			if tb == "string" then return Fast.compareSS(a, b) end
		end

		return mathV6FallbackCompare(a, b)
	end

	function NanoFormat.pow(a: MathValue, b: MathValue): buffer
		local ta = typeof(a)
		local tb = typeof(b)

		if ta == "buffer" then
			if tb == "buffer" then return Fast.powBB(a, b) end
			if tb == "number" then return Fast.powBN(a, b) end
			if tb == "string" then return Fast.powBS(a, b) end
		elseif ta == "number" then
			if tb == "buffer" then return Fast.powNB(a, b) end
			if tb == "number" then return Fast.powNN(a, b) end
			if tb == "string" then return Fast.powNS(a, b) end
		elseif ta == "string" then
			if tb == "buffer" then return Fast.powSB(a, b) end
			if tb == "number" then return Fast.powSN(a, b) end
			if tb == "string" then return Fast.powSS(a, b) end
		end

		return mathV6FallbackPow(a, b)
	end

	function NanoFormat.eq(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) == 0
	end

	function NanoFormat.lt(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) < 0
	end

	function NanoFormat.lte(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) <= 0
	end

	function NanoFormat.gt(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) > 0
	end

	function NanoFormat.gte(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) >= 0
	end

	function NanoFormat.callPerfInfo(): CallPerfInfo
		return {
			Version = NanoFormat.CALL_VERSION,
			DirectCallVersion = NanoFormat.DIRECT_CALL_VERSION,
			BindVersion = NanoFormat.BIND_VERSION,
			CompileVersion = NanoFormat.COMPILE_VERSION,
			MathPerfVersion = NanoFormat.MATH_PERF_VERSION,
			MathPathVersion = NanoFormat.MATH_PATH_VERSION,
			FlexibleTypeChecksPerBinaryCall = 2,
			DirectTypeChecksPerBinaryCall = 0,
			StringParsingCanBeEliminatedByCompile = true,
		}
	end

	NanoFormat.MATH_CORRECTNESS_VERSION = 2
	NanoFormat.TETRATION_VERSION = 3
	NanoFormat.DECIMAL_TETRATION_VERSION = 1
	NanoFormat.SLOG_VERSION = 2
	NanoFormat.GAMMA_VERSION = 2

	local function mathV7FiniteScalar(value: any): number?
		if typeof(value) == "number" then
			if value == value and value ~= huge and value ~= -huge then
				return value
			end
			return nil
		end

		local n = NanoFormat.toNumber(value)
		if n == n and n ~= huge and n ~= -huge then
			return n
		end
		return nil
	end

	local function mathV7NonnegativeInteger(value: any): number?
		local n = mathV7FiniteScalar(value)
		if n == nil or n < 0 or n ~= floor(n) then
			return nil
		end
		return n
	end

	local function mathV7PositiveBase(base: any): boolean
		return not NanoFormat.isNaN(base) and NanoFormat.gt(base, 0)
	end

	function NanoFormat.log1p(value: MathValue): buffer
		local cmp = NanoFormat.compare(value, -1)
		if cmp ~= cmp or cmp < 0 then
			return makeSpecial(SPECIAL_NAN)
		elseif cmp == 0 then
			return makeSpecial(SPECIAL_NEG_INF)
		end

		local direct = NanoFormat.toNumber(value)
		if direct == direct and direct ~= huge and direct ~= -huge then
			if abs(direct) < 1e-5 then
				local x = direct
				local x2 = x * x
				local x3 = x2 * x
				local x4 = x3 * x
				local x5 = x4 * x
				local x6 = x5 * x
				return NanoFormat.fromNumber(
					x - x2 / 2 + x3 / 3 - x4 / 4 + x5 / 5 - x6 / 6
				)
			end
			return NanoFormat.fromNumber(math.log(1 + direct))
		end

		return NanoFormat.ln(NanoFormat.add(1, value))
	end

	function NanoFormat.inverseDiminishingReturns(value: MathValue, scale: MathValue): buffer
		if NanoFormat.lte(scale, 0) or NanoFormat.lt(value, 0) then
			return makeSpecial(SPECIAL_NAN)
		end

		local cmp = NanoFormat.compare(value, scale)
		if cmp ~= cmp or cmp > 0 then
			return makeSpecial(SPECIAL_NAN)
		elseif cmp == 0 then
			return makeSpecial(SPECIAL_POS_INF)
		end

		return NanoFormat.neg(
			NanoFormat.mul(
				scale,
				NanoFormat.log1p(
					NanoFormat.neg(NanoFormat.div(value, scale))
				)
			)
		)
	end

	function NanoFormat.logit(value: MathValue): buffer
		local c0 = NanoFormat.compare(value, 0)
		local c1 = NanoFormat.compare(value, 1)
		if c0 ~= c0 or c1 ~= c1 or c0 < 0 or c1 > 0 then
			return makeSpecial(SPECIAL_NAN)
		elseif c0 == 0 then
			return makeSpecial(SPECIAL_NEG_INF)
		elseif c1 == 0 then
			return makeSpecial(SPECIAL_POS_INF)
		end

		return NanoFormat.ln(
			NanoFormat.div(value, NanoFormat.sub(1, value))
		)
	end

	function NanoFormat.powInt(base: MathValue, exponent: MathValue): buffer
		if not NanoFormat.isInteger(exponent) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.pow(base, exponent)
	end

	function NanoFormat.iteratedExp10(value: MathValue, timesValue: MathValue): buffer
		local times = mathV7NonnegativeInteger(timesValue)
		if times == nil or times > NanoFormat.MAX_LAYER then
			return makeSpecial(SPECIAL_NAN)
		elseif times == 0 then
			return mathCopyBuffer(value)
		end

		local result, data = mathDecode(value)
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			if data.Negative then

				result = NanoFormat.fromNumber(0)
				times -= 1
				if times == 0 then return result end
			else
				return makeSpecial(SPECIAL_POS_INF)
			end
		end

		if data.Kind == "Layer"
			and not data.Negative
			and not data.Reciprocal
		then
			if data.LayerIsLog then

				return result
			end

			local nextLayer = data.Layer + times
			if nextLayer == huge or nextLayer > NanoFormat.MAX_LAYER then
				nextLayer = NanoFormat.MAX_LAYER
			end
			return NanoFormat.fromLayer(nextLayer, data.Top, false, false)
		end

		local direct = NanoFormat.toNumber(result)
		if direct == direct and direct ~= huge and direct ~= -huge and direct >= 0 then
			if times == 1 then
				return NanoFormat.pow10(result)
			end
			return NanoFormat.fromLayer(times, direct, false, false)
		end

		result = NanoFormat.pow10(result)
		times -= 1
		if times == 0 then return result end
		return NanoFormat.iteratedExp10(result, times)
	end

	function NanoFormat.iteratedLog10(value: MathValue, timesValue: MathValue): buffer
		local times = mathV7NonnegativeInteger(timesValue)
		if times == nil or times > NanoFormat.MAX_LAYER then
			return makeSpecial(SPECIAL_NAN)
		elseif times == 0 then
			return mathCopyBuffer(value)
		end

		local result, data = mathDecode(value)
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return makeSpecial(SPECIAL_NAN)
		elseif data.Kind == "Infinity" then
			return data.Negative and makeSpecial(SPECIAL_NAN) or result
		elseif mathSignData(data) <= 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		if data.Kind == "Layer" then
			if data.Reciprocal then
				if times == 1 then return NanoFormat.log10(result) end
				return makeSpecial(SPECIAL_NAN)
			end

			if data.LayerIsLog then
				return result
			end

			if times < data.Layer then
				return NanoFormat.fromLayer(
					data.Layer - times,
					data.Top,
					false,
					false
				)
			end

			result = NanoFormat.fromNumber(data.Top)
			times -= data.Layer
		end

		while times > 0 do
			result = NanoFormat.log10(result)
			times -= 1
			if NanoFormat.isNaN(result) or NanoFormat.isInfinite(result) then
				return result
			end
		end
		return result
	end

	local function mathV7Tetrate10Standard(height: number): buffer
		if height < -1 then
			return makeSpecial(SPECIAL_NAN)
		elseif height < 0 then
			return NanoFormat.fromNumber(height + 1)
		end

		local whole = floor(height)
		local fraction = height - whole
		local seed = 10 ^ fraction

		if whole == 0 then
			return NanoFormat.fromNumber(seed)
		elseif whole == 1 then
			return NanoFormat.fromLog10(seed)
		end

		return NanoFormat.fromLayer(whole, seed, false, false)
	end

	local function mathV7Tetrate10Payload(
		height: number,
		payload: buffer
	): buffer
		if height < 0 then
			return makeSpecial(SPECIAL_NAN)
		elseif height == 0 then
			return payload
		end

		local whole = floor(height)
		local fraction = height - whole
		local seed = payload

		if fraction ~= 0 then
			if NanoFormat.lte(payload, 0) then
				return makeSpecial(SPECIAL_NAN)
			end

			local seedLog = NanoFormat.add(
				NanoFormat.mul(NanoFormat.log10(payload), 1 - fraction),
				NanoFormat.mul(payload, fraction)
			)
			seed = NanoFormat.pow10(seedLog)
		end

		return NanoFormat.iteratedExp10(seed, whole)
	end

	function NanoFormat.tetrate10(heightValue: MathValue, payload: MathValue?): buffer
		local height = mathV7FiniteScalar(heightValue)
		if height == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		if payload == nil then
			return mathV7Tetrate10Standard(height)
		end

		return mathV7Tetrate10Payload(height, NanoFormat.compile(payload))
	end

	function NanoFormat.tetrate(
		baseValue: MathValue,
		heightValue: MathValue,
		payload: MathValue?
	): buffer
		if NanoFormat.eq(baseValue, 10) then
			return NanoFormat.tetrate10(heightValue, payload)
		end

		local height = mathV7FiniteScalar(heightValue)
		if height == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		local standardPayload = payload == nil
		local start = standardPayload
			and NanoFormat.fromNumber(1)
			or NanoFormat.compile(payload)

		if standardPayload and height < 0 then
			if height < -1 then
				return makeSpecial(SPECIAL_NAN)
			end
			if not mathV7PositiveBase(baseValue) or NanoFormat.eq(baseValue, 1) then
				return makeSpecial(SPECIAL_NAN)
			end
			return NanoFormat.fromNumber(height + 1)
		elseif not standardPayload and height < 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		if height == 0 then
			return start
		end

		local whole = floor(height)
		local fraction = height - whole

		if fraction == 0 then
			if whole > 256 then
				return makeSpecial(SPECIAL_NAN)
			end
			local result = start
			for _ = 1, whole do
				result = NanoFormat.pow(baseValue, result)
				if NanoFormat.isNaN(result) then return result end
			end
			return result
		end

		if not mathV7PositiveBase(baseValue) then
			return makeSpecial(SPECIAL_NAN)
		end

		local seed
		if standardPayload then
			seed = NanoFormat.pow(baseValue, fraction)
		else
			if NanoFormat.lte(start, 0) then
				return makeSpecial(SPECIAL_NAN)
			end

			local seedLn = NanoFormat.add(
				NanoFormat.mul(NanoFormat.ln(start), 1 - fraction),
				NanoFormat.mul(
					NanoFormat.mul(start, NanoFormat.ln(baseValue)),
					fraction
				)
			)
			seed = NanoFormat.exp(seedLn)
		end

		if whole > 256 then
			return makeSpecial(SPECIAL_NAN)
		end

		local result = seed
		for _ = 1, whole do
			result = NanoFormat.pow(baseValue, result)
			if NanoFormat.isNaN(result) then return result end
		end
		return result
	end

	function NanoFormat.tetrateInteger(
		baseValue: MathValue,
		heightValue: MathValue,
		payload: MathValue?
	): buffer
		local height = mathV7FiniteScalar(heightValue)
		if height == nil or height < 0 or height ~= floor(height) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.tetrate(baseValue, height, payload)
	end

	function NanoFormat.tetrate10Integer(heightValue: MathValue, payload: MathValue?): buffer
		local height = mathV7FiniteScalar(heightValue)
		if height == nil or height < 0 or height ~= floor(height) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.tetrate10(height, payload)
	end

	function NanoFormat.slog10(value: MathValue): buffer
		if NanoFormat.isNaN(value) or NanoFormat.lt(value, 0) then
			return makeSpecial(SPECIAL_NAN)
		elseif NanoFormat.isZero(value) then
			return NanoFormat.fromNumber(-1)
		end
		return mathV7OldSlog10(value)
	end

	function NanoFormat.slog(value: MathValue, baseValue: MathValue?): buffer
		local base = baseValue or 10
		if NanoFormat.eq(base, 10) then
			return NanoFormat.slog10(value)
		end

		if NanoFormat.lte(base, 1) or NanoFormat.lt(value, 0)
			or NanoFormat.isNaN(base) or NanoFormat.isNaN(value)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.isZero(value) then
			return NanoFormat.fromNumber(-1)
		elseif NanoFormat.lt(value, 1) then
			return NanoFormat.sub(value, 1)
		end

		local x = mathCopyBuffer(value)
		local count = 0
		while NanoFormat.gt(x, base) and count < 256 do
			x = NanoFormat.log(x, base)
			if NanoFormat.isNaN(x) then return x end
			count += 1
		end

		if NanoFormat.gt(x, base) then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.add(count, NanoFormat.log(x, base))
	end

	local function mathV7GammaSignDirect(x: number): number
		if x > 0 then return 1 end
		if x == floor(x) then return 0 end
		local s = math.sin(math.pi * x)
		if s > 0 then return 1 elseif s < 0 then return -1 end
		return 0
	end

	local function mathV7LogAbsGammaDirect(x: number): number
		if x > 0 then
			return mathLogGammaDirect(x)
		end
		if x == floor(x) then
			return huge
		end
		local sinpx = math.sin(math.pi * x)
		if sinpx == 0 then return huge end
		return math.log(math.pi)
		- math.log(abs(sinpx))
		- mathLogGammaDirect(1 - x)
	end

	function NanoFormat.gammaSign(value: MathValue): number
		if NanoFormat.isNaN(value) then return MATH_NAN end
		if NanoFormat.isInfinite(value) then
			return NanoFormat.gt(value, 0) and 1 or MATH_NAN
		end
		if NanoFormat.isZero(value) then return 0 end
		if NanoFormat.gt(value, 0) then return 1 end

		local direct = NanoFormat.toNumber(value)
		if direct == 0 then

			return -1
		elseif direct == -huge or direct ~= direct or abs(direct) > 1e6 then

			return MATH_NAN
		end
		return mathV7GammaSignDirect(direct)
	end

	function NanoFormat.logGamma(value: MathValue): buffer
		if NanoFormat.isNaN(value) then
			return makeSpecial(SPECIAL_NAN)
		elseif NanoFormat.isInfinite(value) then
			return NanoFormat.gt(value, 0)
				and makeSpecial(SPECIAL_POS_INF)
				or makeSpecial(SPECIAL_NAN)
		elseif NanoFormat.isZero(value) then
			return makeSpecial(SPECIAL_POS_INF)
		end

		if NanoFormat.gt(value, 0) then
			local direct = NanoFormat.toNumber(value)
			if direct == 0 then
				return NanoFormat.neg(NanoFormat.ln(value))
			elseif direct == direct and direct ~= huge and direct < 1e6 then
				return NanoFormat.fromNumber(mathLogGammaDirect(direct))
			end

			local x = mathCopyBuffer(value)
			local inv = NanoFormat.reciprocal(x)
			local inv2 = NanoFormat.square(inv)
			local inv3 = NanoFormat.mul(inv2, inv)
			local inv5 = NanoFormat.mul(inv3, inv2)
			local main = NanoFormat.sub(
				NanoFormat.mul(NanoFormat.sub(x, 0.5), NanoFormat.ln(x)),
				x
			)
			main = NanoFormat.add(main, 0.5 * math.log(2 * math.pi))
			local correction = NanoFormat.add(
				NanoFormat.sub(NanoFormat.div(inv, 12), NanoFormat.div(inv3, 360)),
				NanoFormat.div(inv5, 1260)
			)
			return NanoFormat.add(main, correction)
		end

		if NanoFormat.isInteger(value) then
			return makeSpecial(SPECIAL_POS_INF)
		end

		local direct = NanoFormat.toNumber(value)
		if direct == 0 then
			return NanoFormat.neg(NanoFormat.ln(NanoFormat.abs(value)))
		elseif direct == -huge or direct ~= direct or abs(direct) > 1e6 then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.fromNumber(mathV7LogAbsGammaDirect(direct))
	end

	function NanoFormat.gamma(value: MathValue): buffer
		local sign = NanoFormat.gammaSign(value)
		if sign ~= sign or sign == 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		local magnitude = NanoFormat.exp(NanoFormat.logGamma(value))
		return sign < 0 and NanoFormat.neg(magnitude) or magnitude
	end

	function NanoFormat.factorialReal(value: MathValue): buffer
		return NanoFormat.gamma(NanoFormat.add(value, 1))
	end

	function NanoFormat.betaSign(a: MathValue, b: MathValue): number
		local sa = NanoFormat.gammaSign(a)
		local sb = NanoFormat.gammaSign(b)
		local sum = NanoFormat.add(a, b)
		local ss = NanoFormat.gammaSign(sum)
		if sa ~= sa or sb ~= sb or ss ~= ss or sa == 0 or sb == 0 or ss == 0 then
			return MATH_NAN
		end
		return sa * sb * ss
	end

	function NanoFormat.logBeta(a: MathValue, b: MathValue): buffer
		if NanoFormat.isNaN(a) or NanoFormat.isNaN(b) then
			return makeSpecial(SPECIAL_NAN)
		end

		if NanoFormat.gt(a, 0) and NanoFormat.gt(b, 0)
			and (NanoFormat.isInfinite(a) or NanoFormat.isInfinite(b))
		then
			return makeSpecial(SPECIAL_NEG_INF)
		end

		local sign = NanoFormat.betaSign(a, b)
		if sign ~= sign then return makeSpecial(SPECIAL_NAN) end

		return NanoFormat.sub(
			NanoFormat.add(NanoFormat.logGamma(a), NanoFormat.logGamma(b)),
			NanoFormat.logGamma(NanoFormat.add(a, b))
		)
	end

	function NanoFormat.beta(a: MathValue, b: MathValue): buffer
		local sign = NanoFormat.betaSign(a, b)
		if sign ~= sign then

			if NanoFormat.gt(a, 0) and NanoFormat.gt(b, 0)
				and (NanoFormat.isInfinite(a) or NanoFormat.isInfinite(b))
			then
				return NanoFormat.fromNumber(0)
			end
			return makeSpecial(SPECIAL_NAN)
		end

		local magnitude = NanoFormat.exp(NanoFormat.logBeta(a, b))
		return sign < 0 and NanoFormat.neg(magnitude) or magnitude
	end

	NanoFormat.modulo = NanoFormat.mod
	NanoFormat.remainder = NanoFormat.fmod
	NanoFormat.average = NanoFormat.mean
	NanoFormat.choose = NanoFormat.combination
	NanoFormat.nCr = NanoFormat.combination
	NanoFormat.nPr = NanoFormat.permutation
	NanoFormat.tetr = NanoFormat.tetrate
	NanoFormat.slog10Approx = NanoFormat.slog10
	NanoFormat.saturate = NanoFormat.clamp01
	NanoFormat.growth = NanoFormat.compound
	NanoFormat.lnGamma = NanoFormat.logGamma
	NanoFormat.nthRoot = NanoFormat.root
	NanoFormat.almostEqual = NanoFormat.approxEq
	NanoFormat.seriesArithmetic = NanoFormat.arithmeticSeries
	NanoFormat.seriesGeometric = NanoFormat.geometricSeries
	NanoFormat.geometricBulkCost = NanoFormat.geometricCost
	NanoFormat.affordableGeometric = NanoFormat.maxAffordableGeometric
	NanoFormat.constant = NanoFormat.compile
	NanoFormat.subtract = NanoFormat.sub
	NanoFormat.multiply = NanoFormat.mul
	NanoFormat.divide = NanoFormat.div
	NanoFormat.power = NanoFormat.pow
	NanoFormat.equal = NanoFormat.eq
	NanoFormat.lessThan = NanoFormat.lt
	NanoFormat.lessThanOrEqual = NanoFormat.lte
	NanoFormat.greaterThan = NanoFormat.gt
	NanoFormat.greaterThanOrEqual = NanoFormat.gte
	NanoFormat.logAbsGamma = NanoFormat.logGamma
	NanoFormat.logAbsBeta = NanoFormat.logBeta
	NanoFormat.tetrateDecimal = NanoFormat.tetrate
	NanoFormat.tetrateContinuous = NanoFormat.tetrate
	NanoFormat.tetrate10Decimal = NanoFormat.tetrate10
	NanoFormat.superLog = NanoFormat.slog
	NanoFormat.inverseDiminishing = NanoFormat.inverseDiminishingReturns
	NanoFormat.negative = NanoFormat.neg
	NanoFormat.inverse = NanoFormat.reciprocal

end)()



-- Math V8 / Safe Typed Public Dispatch ----------------------------------------
-- Math V7 remains the arithmetic engine. V8 fixes the public boundary:
--   * malformed/truncated buffers no longer enter Fast.* and throw
--   * unsupported runtime types produce NaN/false instead of a buffer read error
--   * flexible binary functions expose MathValue signatures under --!strict
-- Fast.* keeps its zero-dispatch contract and assumes valid typed arguments.
NanoFormat.MATH_VERSION = 8
NanoFormat.MATH_CORRECTNESS_VERSION = 3
NanoFormat.MATH_SAFETY_VERSION = 1

(function()
	local oldAdd = NanoFormat.add
	local oldSub = NanoFormat.sub
	local oldMul = NanoFormat.mul
	local oldDiv = NanoFormat.div
	local oldPow = NanoFormat.pow
	local oldCompare = NanoFormat.compare
	local oldFactorial = NanoFormat.factorial
	local oldSign = NanoFormat.sign
	local oldNeg = NanoFormat.neg
	local oldReciprocal = NanoFormat.reciprocal
	local oldLog10 = NanoFormat.log10
	local oldToNumber = NanoFormat.toNumber
	local oldIsNaN = NanoFormat.isNaN
	local oldIsInfinite = NanoFormat.isInfinite
	local oldIsZero = NanoFormat.isZero
	local oldIsInteger = NanoFormat.isInteger
	local oldIsOdd = NanoFormat.isOdd
	local oldPow10 = NanoFormat.pow10
	local oldFloor = NanoFormat.floor
	local oldCeil = NanoFormat.ceil

	local function validMathValue(value: any): boolean
		local kind = typeof(value)
		if kind == "number" or kind == "string" then
			return true
		elseif kind == "buffer" then
			return NanoFormat.isValid(value)
		end
		return false
	end

	local function invalidResult(): buffer
		return makeSpecial(SPECIAL_NAN)
	end

	function NanoFormat.isMathValue(value: any): boolean
		return validMathValue(value)
	end

	function NanoFormat.tryCompile(value: any): (boolean, buffer?)
		if not validMathValue(value) then
			return false, nil
		end
		local ok, result = pcall(NanoFormat.compile, value)
		if not ok or typeof(result) ~= "buffer" or not NanoFormat.isValid(result) then
			return false, nil
		end
		if NanoFormat.isNaN(result) then
			return false, result
		end
		return true, result
	end

	function NanoFormat.add(a: MathValue, b: MathValue): buffer
		if not validMathValue(a) or not validMathValue(b) then return invalidResult() end
		return oldAdd(a, b)
	end

	function NanoFormat.sub(a: MathValue, b: MathValue): buffer
		if not validMathValue(a) or not validMathValue(b) then return invalidResult() end
		return oldSub(a, b)
	end

	function NanoFormat.mul(a: MathValue, b: MathValue): buffer
		if not validMathValue(a) or not validMathValue(b) then return invalidResult() end
		return oldMul(a, b)
	end

	function NanoFormat.div(a: MathValue, b: MathValue): buffer
		if not validMathValue(a) or not validMathValue(b) then return invalidResult() end
		return oldDiv(a, b)
	end

	function NanoFormat.pow(a: MathValue, b: MathValue): buffer
		if not validMathValue(a) or not validMathValue(b) then return invalidResult() end
		return oldPow(a, b)
	end

	function NanoFormat.compare(a: MathValue, b: MathValue): number
		if not validMathValue(a) or not validMathValue(b) then return 0 / 0 end
		return oldCompare(a, b)
	end

	function NanoFormat.eq(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) == 0
	end

	function NanoFormat.lt(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) < 0
	end

	function NanoFormat.lte(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) <= 0
	end

	function NanoFormat.gt(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) > 0
	end

	function NanoFormat.gte(a: MathValue, b: MathValue): boolean
		return NanoFormat.compare(a, b) >= 0
	end

	-- The V7 PATH-0 unary implementations intentionally read canonical buffers
	-- directly. Public V8 checks structural validity first so malformed external
	-- buffers cannot reach buffer.readbits through those optimized paths.
	function NanoFormat.factorial(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldFactorial(value)
	end

	function NanoFormat.sign(value: MathValue): number
		if not validMathValue(value) then return 0 / 0 end
		return oldSign(value)
	end

	function NanoFormat.neg(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldNeg(value)
	end

	function NanoFormat.reciprocal(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldReciprocal(value)
	end

	function NanoFormat.log10(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldLog10(value)
	end

	function NanoFormat.toNumber(value: MathValue): number
		if not validMathValue(value) then return 0 / 0 end
		return oldToNumber(value)
	end

	function NanoFormat.isNaN(value: MathValue): boolean
		if not validMathValue(value) then return true end
		return oldIsNaN(value)
	end

	function NanoFormat.isInfinite(value: MathValue): boolean
		if not validMathValue(value) then return false end
		return oldIsInfinite(value)
	end

	function NanoFormat.isZero(value: MathValue): boolean
		if not validMathValue(value) then return false end
		return oldIsZero(value)
	end

	function NanoFormat.isInteger(value: MathValue): boolean
		if not validMathValue(value) then return false end
		return oldIsInteger(value)
	end

	function NanoFormat.isOdd(value: MathValue): boolean
		if not validMathValue(value) then return false end
		return oldIsOdd(value)
	end

	function NanoFormat.pow10(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldPow10(value)
	end

	function NanoFormat.floor(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldFloor(value)
	end

	function NanoFormat.ceil(value: MathValue): buffer
		if not validMathValue(value) then return invalidResult() end
		return oldCeil(value)
	end

	local BINARY: {[string]: (MathValue, MathValue) -> buffer} = {
		add = NanoFormat.add,
		sub = NanoFormat.sub,
		mul = NanoFormat.mul,
		div = NanoFormat.div,
		pow = NanoFormat.pow,
	}

	function NanoFormat.tryMath(
		operation: MathBinaryOperation,
		a: any,
		b: any
	): (boolean, buffer?)
		local fn = BINARY[operation]
		if fn == nil or not validMathValue(a) or not validMathValue(b) then
			return false, nil
		end
		local ok, result = pcall(fn, a, b)
		if not ok or typeof(result) ~= "buffer" or not NanoFormat.isValid(result) then
			return false, nil
		end
		return true, result
	end

	function NanoFormat.tryCompare(a: any, b: any): (boolean, number?)
		if not validMathValue(a) or not validMathValue(b) then
			return false, nil
		end
		local ok, result = pcall(NanoFormat.compare, a, b)
		if not ok or typeof(result) ~= "number" or result ~= result then
			return false, nil
		end
		return true, result
	end

	NanoFormat.subtract = NanoFormat.sub
	NanoFormat.multiply = NanoFormat.mul
	NanoFormat.divide = NanoFormat.div
	NanoFormat.power = NanoFormat.pow
	NanoFormat.equal = NanoFormat.eq
	NanoFormat.lessThan = NanoFormat.lt
	NanoFormat.lessThanOrEqual = NanoFormat.lte
	NanoFormat.greaterThan = NanoFormat.gt
	NanoFormat.greaterThanOrEqual = NanoFormat.gte
	NanoFormat.negative = NanoFormat.neg
	NanoFormat.inverse = NanoFormat.reciprocal
end)()

NanoFormat.LBEncode = NanoFormat.lbencode
NanoFormat.LBDecode = NanoFormat.lbdecode
NanoFormat.LBEncodeV1 = NanoFormat.lbencode
NanoFormat.LBDecodeV1 = NanoFormat.lbdecode
NanoFormat.LBCompare = NanoFormat.lbCompare
NanoFormat.LBRoundTripStable = NanoFormat.lbRoundTripStable


local TYPECHECKED_NANONUM: NanoNumModule = NanoFormat
return TYPECHECKED_NANONUM
