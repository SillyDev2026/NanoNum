--!native
--!optimize 2

local NanoNum = {}

-- NanoNum v1.9.0 accurate-finite rebuild: ordinary finite values use an exact f64 record.
-- Legacy compact normals remain decodable; log/layer/special values keep the huge-number kernel.

export type MathValue = number | string | buffer
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
export type DecodedLayer = {Kind: "Layer", Negative: boolean, Reciprocal: boolean, Layer: number?, LayerLog10: number?, LayerIsLog: boolean, Top: number}
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
NanoNum.VERSION = "1.9.0"
NanoNum.REGISTER_SCOPE_VERSION = 3
NanoNum.MAX_LAYER = 1e308
NanoNum.MAX_LAYER_LOG10 = 1e308
NanoNum.NORMAL_SIGNIFICAND_BITS = 16
NanoNum.SCALAR_SIGNIFICAND_BITS = 14
NanoNum.PARSER_VERSION = 6
NanoNum.NOTATION_VERSION = 7
NanoNum.PERF_VERSION = 10
NanoNum.PATH_VERSION = 4
NanoNum.DEFAULT_PATH = 0
NanoNum.MATH_SCOPE_VERSION = 4
NanoNum.MATH_VERSION = 19
NanoNum.MATH_CLEANUP_VERSION = 5
NanoNum.CALL_VERSION = 6
NanoNum.DIRECT_CALL_VERSION = 6
NanoNum.BIND_VERSION = 6
NanoNum.COMPILE_VERSION = 6
NanoNum.MATH_PERF_VERSION = 7
NanoNum.MATH_PATH_VERSION = 2
NanoNum.MATH_DEFAULT_PATH = 0
NanoNum.MATH_CORRECTNESS_VERSION = 9
NanoNum.TETRATION_VERSION = 5
NanoNum.SLOG_VERSION = 4
NanoNum.GAMMA_VERSION = 4
NanoNum.MATH_SAFETY_VERSION = 5

local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp
local log = math.log
local log10 = math.log10
local sqrt = math.sqrt
local exp = math.exp
local sin = math.sin
local huge = math.huge
local pi = math.pi
local format = string.format
local byte = string.byte
local sub = string.sub
local lower = string.lower
local find = string.find
local gsub = string.gsub
local match = string.match
local split = string.split
local rep = string.rep
local char = string.char
local concat = table.concat
local tableCreate = table.create
local bufferCreate = buffer.create
local bufferReadBits = buffer.readbits
local bufferWriteBits = buffer.writebits
local bufferWriteU8 = buffer.writeu8
local bufferReadF64 = buffer.readf64
local bufferWriteF64 = buffer.writef64
local bufferLen = buffer.len
local bufferCopy = buffer.copy
local band = bit32.band
local toNumber = tonumber
local toString = tostring
local fastPcall = pcall

local LN2 = log(2)
local LN10 = log(10)
local LOG10_2 = log10(2)
local LOG10_E = log10(exp(1))
local TWO_PI = 2 * pi
local SAFE_INTEGER = 9007199254740991
local DIRECT_LOG_MAX = 308.25471555991675
local DIRECT_LOG_MIN = -323.3062153431158
local NAN = 0 / 0

local PREFIX_TINY = 0
local PREFIX_NEG_SMALL = 1
local PREFIX_INTEGER = 2
local PREFIX_NORMAL = 3
local PREFIX_LOG = 4
local PREFIX_LAYER = 5
local PREFIX_SPECIAL = 6

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
local NORMAL_BITS = 31

local SCALAR_EXP_BITS = 10
local SCALAR_EXP_BIAS = 324
local SCALAR_EXP_MIN = -324
local SCALAR_EXP_MAX = 308
local SCALAR_MANT_BITS = 14
local SCALAR_MANT_MAX = 16383
local SCALAR_APPROX_BITS = 25

local EXACT_LEN_BITS = 6
local INTEGER_LEN_BITS = 5
local MAX_INTEGER_MODE_BITS = 53
local MAX_STANDALONE_BYTES = 9
local EXACT_F64_BITS = 72
local EXACT_F64_BYTES = 9
local DIRECT_LAYER_LOG10_MAX = 308

local K_NUM = 1
local K_LOG = 2
local K_LAYER = 3
local K_LAYER_LOG = 4
local K_INF = 5
local K_NAN = 6

NanoNum.SUFFIX_VERSION = 5
NanoNum.ROMAN_VERSION = 1
NanoNum.TIME_VERSION = 1
NanoNum.UTILITY_FORMAT_VERSION = 3
NanoNum.FORMAT_SCOPE_VERSION = 2
NanoNum.UTILITY_SCOPE_VERSION = 2
NanoNum.PACK_SCOPE_VERSION = 2
NanoNum.LB_SCOPE_VERSION = 1
NanoNum.ROMAN_CLASSICAL_MAX = 3999
NanoNum.ROMAN_EXTENDED_MAX = SAFE_INTEGER
NanoNum.STANDARD_SUFFIX_MAX_INDEX = 101
NanoNum.METRIC_SUFFIX_MAX_INDEX = 10
NanoNum.DEFAULT_SUFFIX_TYPE = "standard"
NanoNum.DEFAULT_PRECISION = 2
NanoNum.MAX_PRECISION = 8
NanoNum.FORMAT_PRECISION_MODE = "decimal-places"
NanoNum.E_NOTATION_START = 3000
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

local STANDARD_SUFFIXES = {
	"k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
}
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
	local baseIndex = family[1]
	STANDARD_SUFFIXES[baseIndex] = family[2]
	local tail = family[3]
	for unit = 1, 9 do
		STANDARD_SUFFIXES[baseIndex + unit] = STANDARD_UNIT_PREFIXES[unit] .. tail
	end
end

STANDARD_SUFFIXES[101] = "Ce"

local METRIC_SUFFIXES = {"k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q"}
local STANDARD_SUFFIX_TO_INDEX = {}
local METRIC_SUFFIX_TO_INDEX = {}
local ALPHABETIC_SUFFIX_CACHE = {}

for i, suffix in STANDARD_SUFFIXES do
	STANDARD_SUFFIX_TO_INDEX[suffix] = i
end

for i, suffix in METRIC_SUFFIXES do
	METRIC_SUFFIX_TO_INDEX[suffix] = i
end

STANDARD_SUFFIX_TO_INDEX.K = 1
METRIC_SUFFIX_TO_INDEX.K = 1

local function bitsRequired(value: number): number
	if value <= 0 then return 0 end
	return floor(log(value) / LN2) + 1
end

local function isSafeInteger(value: number): boolean
	return value >= 0 and value <= SAFE_INTEGER and value == floor(value)
end

local function ceilBytes(bits: number): number
	return max(1, floor((bits + 7) / 8))
end

local function quantizeMantissa(mantissa: number, maxCode: number): number
	return clamp(floor(((mantissa - 1) / 9) * maxCode + 0.5), 0, maxCode)
end

local function decodeMantissa(code: number, maxCode: number): number
	return 1 + code / maxCode * 9
end

local function scalarExactBits(value: number): number
	if not isSafeInteger(value) then return huge end
	local n = bitsRequired(value)
	if n > 53 then return huge end
	return 1 + EXACT_LEN_BITS + n
end

local function scalarBits(value: number): number
	local exact = scalarExactBits(value)
	if exact <= SCALAR_APPROX_BITS then return exact end
	return SCALAR_APPROX_BITS
end

local function integerLengthFieldBits(bitLength: number): number
	if bitLength <= 31 then return INTEGER_LEN_BITS end
	return INTEGER_LEN_BITS + 5
end

local function exactIntegerRecordBits(value: number): number
	local magnitude = abs(value)
	if not isSafeInteger(magnitude) then return huge end
	local n = bitsRequired(magnitude)
	if n == 0 or n > MAX_INTEGER_MODE_BITS then return huge end
	return 3 + 1 + integerLengthFieldBits(n) + n
end

local function logRecordBits(exponentMagnitude: number): number
	return 7 + scalarBits(exponentMagnitude)
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

local function readUIntExactAtFast(data: buffer, bitOffset: number, count: number): number
	if count <= 0 then return 0 end
	if count <= 26 then return bufferReadBits(data, bitOffset, count) end
	local value = bufferReadBits(data, bitOffset, 26)
	local remaining = count - 26
	if remaining <= 26 then return value + bufferReadBits(data, bitOffset + 26, remaining) * 67108864 end
	value += bufferReadBits(data, bitOffset + 26, 26) * 67108864
	return value + bufferReadBits(data, bitOffset + 52, remaining - 26) * 4503599627370496
end

local function writeScalarAtFast(data: buffer, bitOffset: number, value: number)
	value = abs(value)
	local exactBits = scalarExactBits(value)
	if exactBits <= SCALAR_APPROX_BITS then
		local n = bitsRequired(value)
		bufferWriteBits(data, bitOffset, 7, n * 2)
		writeUIntExactAtFast(data, bitOffset + 7, value, n)
		return
	end
	local lg = log10(value)
	local exponent = clamp(floor(lg), SCALAR_EXP_MIN, SCALAR_EXP_MAX)
	local mantissa = 10 ^ (lg - exponent)
	local mantCode = quantizeMantissa(mantissa, SCALAR_MANT_MAX)
	local expCode = exponent + SCALAR_EXP_BIAS
	local packed = 1 + expCode * 2 + mantCode * 2048
	bufferWriteBits(data, bitOffset, SCALAR_APPROX_BITS, packed)
end

local function readScalarAtFast(data: buffer, bitOffset: number): (number, number)
	local approximate = bufferReadBits(data, bitOffset, 1)
	if approximate == 0 then
		local n = bufferReadBits(data, bitOffset + 1, EXACT_LEN_BITS)
		if n > 53 then error("NanoNum: invalid exact scalar bit length") end
		return readUIntExactAtFast(data, bitOffset + 7, n), bitOffset + 7 + n
	end
	local expCode = bufferReadBits(data, bitOffset + 1, SCALAR_EXP_BITS)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then error("NanoNum: invalid scalar exponent code") end
	local mantCode = bufferReadBits(data, bitOffset + 1 + SCALAR_EXP_BITS, SCALAR_MANT_BITS)
	local exponent = expCode - SCALAR_EXP_BIAS
	return decodeMantissa(mantCode, SCALAR_MANT_MAX) * (10 ^ exponent), bitOffset + SCALAR_APPROX_BITS
end

local function readExactF64At(data: buffer, bitOffset: number): number
	if band(bitOffset, 7) == 0 then
		return bufferReadF64(data, bitOffset / 8 + 1)
	end
	local temp = bufferCreate(8)
	bufferWriteBits(temp, 0, 32, bufferReadBits(data, bitOffset + 8, 32))
	bufferWriteBits(temp, 32, 32, bufferReadBits(data, bitOffset + 40, 32))
	return bufferReadF64(temp, 0)
end

local function makeExactNumber(value: number): buffer
	local data = bufferCreate(EXACT_F64_BYTES)
	bufferWriteU8(data, 0, 255)
	bufferWriteF64(data, 1, value)
	return data
end

local function makeSpecial(code: number): buffer
	local data = bufferCreate(1)
	bufferWriteU8(data, 0, 63 + code * 64)
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
	local packed = 7 + (negative and 16 or 0) + expCode * 32 + mantCode * 32768
	bufferWriteBits(data, 0, NORMAL_BITS, packed)
	return data
end

local function makeLog(exponent: number, negative: boolean): buffer
	local reciprocal = exponent < 0
	local magnitude = abs(exponent)
	local bits = logRecordBits(magnitude)
	local data = bufferCreate(ceilBytes(bits))
	bufferWriteBits(data, 0, 7, 15 + (negative and 32 or 0) + (reciprocal and 64 or 0))
	writeScalarAtFast(data, 7, magnitude)
	return data
end

local function layerFieldBits(layer: number, layerIsLog: boolean): number
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then return 6 end
	return 2 + scalarBits(layer)
end

local function makeLayer(layer: number, top: number, negative: boolean, reciprocal: boolean, layerIsLog: boolean): buffer
	if top < 0 then top = 0 end
	if layerIsLog then
		layer = clamp(layer, 0, NanoNum.MAX_LAYER_LOG10)
	else
		layer = clamp(layer, 2, NanoNum.MAX_LAYER)
	end
	top = clamp(top, 0, 1e308)
	local bits = 8 + layerFieldBits(layer, layerIsLog) + scalarBits(top)
	local data = bufferCreate(ceilBytes(bits))
	bufferWriteU8(data, 0, 31 + (negative and 64 or 0) + (reciprocal and 128 or 0))
	local bitOffset = 8
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then
		bufferWriteBits(data, bitOffset, 6, (layer - 2) * 2)
		bitOffset += 6
	else
		bufferWriteBits(data, bitOffset, 2, 1 + (layerIsLog and 2 or 0))
		bitOffset += 2
		writeScalarAtFast(data, bitOffset, layer)
		bitOffset += scalarBits(layer)
	end
	writeScalarAtFast(data, bitOffset, top)
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
		while layer >= 2 and top <= 308 and layer <= SAFE_INTEGER do
			top = top < -324 and 0 or 10 ^ top
			layer -= 1
		end
	end
	return layer, top, layerIsLog
end

function NanoNum.fromNumber(value: number): buffer
	if value ~= value then return makeSpecial(SPECIAL_NAN) end
	if value == huge then return makeSpecial(SPECIAL_POS_INF) end
	if value == -huge then return makeSpecial(SPECIAL_NEG_INF) end
	if value >= 0 and value <= 127 and value == floor(value) then
		local data = bufferCreate(1)
		bufferWriteU8(data, 0, value * 2)
		return data
	end
	if value < 0 and value >= -64 and value == floor(value) then
		local data = bufferCreate(1)
		bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
		return data
	end
	if value == floor(value) and abs(value) <= SAFE_INTEGER then
		return makeInteger(value)
	end
	return makeExactNumber(value)
end

function NanoNum.fromLog10(exponent: number, negative: boolean?): buffer
	if exponent ~= exponent then return makeSpecial(SPECIAL_NAN) end
	if exponent == huge then return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
	if exponent == -huge then return NanoNum.fromNumber(0) end
	if exponent == 0 then return NanoNum.fromNumber(negative and -1 or 1) end
	if exponent >= DIRECT_LOG_MIN and exponent <= DIRECT_LOG_MAX then
		local magnitude = 10 ^ exponent
		if magnitude ~= 0 and magnitude ~= huge then return NanoNum.fromNumber(negative and -magnitude or magnitude) end
	end
	return makeLog(exponent, negative == true)
end

function NanoNum.fromLayer(layer: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layer ~= layer or top ~= top then return makeSpecial(SPECIAL_NAN) end
	if layer == huge then return NanoNum.fromLayerLog10(308, top, negative, reciprocal) end
	local normalizedLayer, normalizedTop = normalizeLayerInput(layer, top, false)
	if normalizedLayer <= 0 then
		local value = normalizedTop
		if reciprocal then
			if value == 0 then return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF) end
			value = 1 / value
		end
		if negative then value = -value end
		return NanoNum.fromNumber(value)
	end
	if normalizedLayer < 2 then
		return NanoNum.fromLog10(reciprocal and -abs(normalizedTop) or normalizedTop, negative)
	end
	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, false)
end

function NanoNum.fromLayerLog10(layerLog10: number, top: number, negative: boolean?, reciprocal: boolean?): buffer
	if layerLog10 ~= layerLog10 or top ~= top then return makeSpecial(SPECIAL_NAN) end
	if layerLog10 == huge then layerLog10 = NanoNum.MAX_LAYER_LOG10 end
	local normalizedLayer, normalizedTop, layerIsLog = normalizeLayerInput(clamp(layerLog10, 0, NanoNum.MAX_LAYER_LOG10), top, true)
	if not layerIsLog then return NanoNum.fromLayer(normalizedLayer, normalizedTop, negative, reciprocal) end
	return makeLayer(normalizedLayer, normalizedTop, negative == true, reciprocal == true, true)
end

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
	local length = 2
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
	local n = 0
	for i = 1, length do
		local c = byte(text, i)
		if c < 97 or c > 122 then return nil end
		n = n * 26 + c - 97
	end
	local offset = 0
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
		if index <= 101 then return STANDARD_SUFFIXES[index] end
		if index < 1000 then return alphabeticSuffix(index - 101) end
		return nil
	end
	if suffixType == "hybrid" then
		if index <= 101 then return STANDARD_SUFFIXES[index] end
		return alphabeticSuffix(index - 101)
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
	if kind == "extended" or kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then return standard end
		local alpha = alphabeticSuffixIndex(suffix)
		if alpha == nil then return nil end
		local index = alpha + 101
		if kind == "extended" and index >= 1000 then return nil end
		return index
	end
	return nil
end

local function trimText(value: string): string
	return match(value, "^%s*(.-)%s*$") or ""
end

function NanoNum.fromString(value: string, suffixType: SuffixName?): buffer
	local length = #value
	local first = 1
	local last = length

	while first <= last do
		local c = byte(value, first)

		if c == 32 or c == 9 or c == 10 or c == 13 then
			first += 1
		else
			break
		end
	end

	while last >= first do
		local c = byte(value, last)

		if c == 32 or c == 9 or c == 10 or c == 13 then
			last -= 1
		else
			break
		end
	end

	if first > last then
		return makeSpecial(SPECIAL_NAN)
	end

	local negative = false
	local reciprocal = false
	local c = byte(value, first)

	if c == 45 then
		negative = true
		first += 1
	elseif c == 43 then
		first += 1
	end

	if first > last then
		return makeSpecial(SPECIAL_NAN)
	end

	if first + 1 <= last and byte(value, first) == 49 and byte(value, first + 1) == 47 then
		reciprocal = true
		first += 2

		if first > last then
			return makeSpecial(SPECIAL_NAN)
		end
	end

	local coreLength = last - first + 1

	if coreLength == 3 then
		local a = byte(value, first)
		local b = byte(value, first + 1)
		local c2 = byte(value, first + 2)

		if (a == 110 or a == 78)
			and (b == 97 or b == 65)
			and (c2 == 110 or c2 == 78)
		then
			return makeSpecial(SPECIAL_NAN)
		end

		if (a == 105 or a == 73)
			and (b == 110 or b == 78)
			and (c2 == 102 or c2 == 70)
		then
			if reciprocal then
				return NanoNum.fromNumber(negative and -0 or 0)
			end

			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		end
	elseif coreLength == 8 then
		local a = byte(value, first)
		local b = byte(value, first + 1)
		local c2 = byte(value, first + 2)
		local d = byte(value, first + 3)
		local e = byte(value, first + 4)
		local f = byte(value, first + 5)
		local g = byte(value, first + 6)
		local h = byte(value, first + 7)

		if (a == 105 or a == 73)
			and (b == 110 or b == 78)
			and (c2 == 102 or c2 == 70)
			and (d == 105 or d == 73)
			and (e == 110 or e == 78)
			and (f == 105 or f == 73)
			and (g == 116 or g == 84)
			and (h == 121 or h == 89)
		then
			if reciprocal then
				return NanoNum.fromNumber(negative and -0 or 0)
			end

			return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
		end
	end

	local scientificEPos = 0

	if first + 2 <= last then
		local second = byte(value, first + 1)

		if second == 101 or second == 69 then
			local firstByte = byte(value, first)

			if firstByte >= 48 and firstByte <= 57 then
				scientificEPos = first + 1
			end
		else
			local lowerE = find(value, "e", first, true)
			local upperE = find(value, "E", first, true)

			if lowerE ~= nil and lowerE <= last then
				scientificEPos = lowerE
			end

			if upperE ~= nil and upperE <= last and (scientificEPos == 0 or upperE < scientificEPos) then
				scientificEPos = upperE
			end
		end
	end

	if scientificEPos > first and scientificEPos < last then
		local exponentStart = scientificEPos + 1
		local exponentNegative = false
		local exponentStartByte = byte(value, exponentStart)

		if exponentStartByte == 45 then
			exponentNegative = true
			exponentStart += 1
		elseif exponentStartByte == 43 then
			exponentStart += 1
		end

		if exponentStart <= last then
			local mantissaLog
			local mantissaZero = false
			local mantissaValid = true

			if scientificEPos == first + 1 then
				local digit = byte(value, first) - 48

				if digit >= 0 and digit <= 9 then
					if digit == 0 then
						mantissaZero = true
						mantissaLog = -huge
					elseif digit == 1 then
						mantissaLog = 0
					else
						mantissaLog = log10(digit)
					end
				else
					mantissaValid = false
				end
			else
				local mantissa = toNumber(sub(value, first, scientificEPos - 1))

				if mantissa == nil or mantissa ~= mantissa or mantissa < 0 or mantissa == huge then
					mantissaValid = false
				elseif mantissa == 0 then
					mantissaZero = true
					mantissaLog = -huge
				else
					mantissaLog = log10(mantissa)
				end
			end

			if mantissaValid and mantissaLog ~= nil then
				local exponent = 0
				local exponentDigits = 0
				local significantDigits = 0
				local leading = 0
				local leadingDigits = 0
				local seenNonZero = false
				local exponentTooLarge = false
				local exponentValid = true
				local p = exponentStart

				while p <= last do
					local ch = byte(value, p)

					if ch >= 48 and ch <= 57 then
						local digit = ch - 48
						exponentDigits += 1

						if digit ~= 0 or seenNonZero then
							seenNonZero = true
							significantDigits += 1

							if leadingDigits < 15 then
								leading = leading * 10 + digit
								leadingDigits += 1
							end
						end

						if not exponentTooLarge then
							if exponent > 1e307 then
								exponentTooLarge = true
							else
								exponent = exponent * 10 + digit

								if exponent == huge then
									exponentTooLarge = true
								end
							end
						end
					elseif ch ~= 44 then
						exponentValid = false
						break
					end

					p += 1
				end

				if exponentValid and exponentDigits > 0 then
					if mantissaZero then
						if reciprocal then
							return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
						end

						return NanoNum.fromNumber(negative and -0 or 0)
					end

					if exponentTooLarge then
						if not seenNonZero or leading <= 0 then
							if reciprocal then
								return NanoNum.fromNumber(negative and -1 or 1)
							end

							return NanoNum.fromNumber(negative and -1 or 1)
						end

						local exponentLog10 = log10(leading) + significantDigits - leadingDigits
						local isReciprocal = exponentNegative

						if reciprocal then
							isReciprocal = not isReciprocal
						end

						return NanoNum.fromLayer(2, exponentLog10, negative, isReciprocal)
					end

					if exponentNegative then
						exponent = -exponent
					end

					local totalLog = exponent + mantissaLog

					if reciprocal then
						totalLog = -totalLog
					end

					if totalLog > DIRECT_LOG_MAX or totalLog < DIRECT_LOG_MIN then
						return makeLog(totalLog, negative)
					end

					local magnitude = 10 ^ totalLog

					if magnitude == 0 then
						return makeLog(totalLog, negative)
					end

					return NanoNum.fromNumber(negative and -magnitude or magnitude)
				end
			end
		end
	end

	local core

	if first == 1 and last == length then
		core = value
	else
		core = sub(value, first, last)
	end

	local direct = toNumber(core)

	if direct ~= nil and direct == direct and direct ~= huge and direct ~= -huge then
		if reciprocal then
			if direct == 0 then
				return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
			end

			direct = 1 / direct
		end

		if negative then
			direct = -direct
		end

		return NanoNum.fromNumber(direct)
	end

	c = byte(value, first)

	if c == 108 or c == 76 then
		local p = first + 1

		if p <= last and byte(value, p) == 40 then
			if p + 3 <= last
				and byte(value, p + 1) == 49
				and byte(value, p + 2) == 48
				and byte(value, p + 3) == 94
			then
				local layerStart = p + 4
				local close = layerStart

				while close <= last and byte(value, close) ~= 41 do
					close += 1
				end

				if close <= last and close > layerStart then
					local layer = toNumber(sub(value, layerStart, close - 1))

					p = close + 1

					while p <= last do
						local ws = byte(value, p)

						if ws == 32 or ws == 9 or ws == 10 or ws == 13 then
							p += 1
						else
							break
						end
					end

					if layer ~= nil and p <= last then
						local top = toNumber(sub(value, p, last))

						if top ~= nil then
							return NanoNum.fromLayerLog10(
								layer,
								top,
								negative,
								reciprocal
							)
						end
					end
				end
			end
		else
			local layerStart = p

			while p <= last do
				local ch = byte(value, p)

				if ch == 32 or ch == 9 or ch == 10 or ch == 13 then
					break
				end

				p += 1
			end

			if p > layerStart and p <= last then
				local layer = toNumber(sub(value, layerStart, p - 1))

				while p <= last do
					local ws = byte(value, p)

					if ws == 32 or ws == 9 or ws == 10 or ws == 13 then
						p += 1
					else
						break
					end
				end

				if layer ~= nil and p <= last then
					local top = toNumber(sub(value, p, last))

					if top ~= nil then
						return NanoNum.fromLayer(
							layer,
							top,
							negative,
							reciprocal
						)
					end
				end
			end
		end
	end

	if c == 101 or c == 69 then
		local p = first
		local repeated = 0

		while p <= last do
			local ch = byte(value, p)

			if ch == 101 or ch == 69 then
				repeated += 1
				p += 1
			else
				break
			end
		end

		if repeated >= 2 and p <= last then
			local top = toNumber(sub(value, p, last))

			if top ~= nil then
				return NanoNum.fromLayer(
					repeated,
					top,
					negative,
					reciprocal
				)
			end
		end

		if repeated == 1 and p <= last and byte(value, p) == 94 then
			p += 1

			local layerStart = p

			while p <= last do
				local ch = byte(value, p)

				if ch == 32 or ch == 9 or ch == 10 or ch == 13 then
					break
				end

				p += 1
			end

			if p > layerStart and p <= last then
				local layer = toNumber(sub(value, layerStart, p - 1))

				while p <= last do
					local ws = byte(value, p)

					if ws == 32 or ws == 9 or ws == 10 or ws == 13 then
						p += 1
					else
						break
					end
				end

				if layer ~= nil and p <= last then
					local top = toNumber(sub(value, p, last))

					if top ~= nil then
						return NanoNum.fromLayer(
							layer,
							top,
							negative,
							reciprocal
						)
					end
				end
			end
		end
	end


	local suffixStart = 0

	for i = first, last do
		local ch = byte(value, i)

		if (ch >= 65 and ch <= 90)
			or (ch >= 97 and ch <= 122)
		then
			suffixStart = i
			break
		end
	end

	if suffixStart > first then
		local validSuffix = true

		for i = suffixStart, last do
			local ch = byte(value, i)

			if not (
				(ch >= 65 and ch <= 90)
					or (ch >= 97 and ch <= 122)
				) then
				validSuffix = false
				break
			end
		end

		if validSuffix then
			local mantissa = toNumber(
				sub(value, first, suffixStart - 1)
			)

			if mantissa ~= nil and mantissa > 0 then
				local kind = suffixType

				if kind == nil then
					kind = NanoNum.DEFAULT_SUFFIX_TYPE
				elseif NanoNum.SUFFIX_TYPES[kind] ~= true then
					kind = lower(kind)

					if NanoNum.SUFFIX_TYPES[kind] ~= true then
						kind = NanoNum.DEFAULT_SUFFIX_TYPE
					end
				end

				if kind ~= "scientific"
					and kind ~= "engineering"
					and kind ~= "exponent"
					and kind ~= "roman"
					and kind ~= "romanextended"
				then
					local suffix = sub(value, suffixStart, last)
					local index

					if kind == "standard" then
						index = STANDARD_SUFFIX_TO_INDEX[suffix]
					elseif kind == "metric" then
						index = METRIC_SUFFIX_TO_INDEX[suffix]
					else
						index = STANDARD_SUFFIX_TO_INDEX[suffix]

						if index == nil or kind == "alphabetic" then
							local suffixLength = last - suffixStart + 1

							if suffixLength >= 2 and suffixLength <= 11 then
								local n = 0
								local alphaValid = true

								for i = suffixStart, last do
									local ch = byte(value, i)

									if ch >= 65 and ch <= 90 then
										ch += 32
									end

									if ch < 97 or ch > 122 then
										alphaValid = false
										break
									end

									n = n * 26 + ch - 97
								end

								if alphaValid then
									local offset = 0
									local power = 676

									for _ = 2, suffixLength - 1 do
										offset += power
										power *= 26
									end

									local alphaIndex = offset + n + 1

									if alphaIndex <= SAFE_INTEGER then
										if kind == "alphabetic" then
											index = alphaIndex
										else
											index = alphaIndex + 101

											if kind == "extended"
												and index >= 1000
											then
												index = nil
											end
										end
									end
								end
							end
						end
					end

					if index ~= nil then
						local totalLog = log10(mantissa) + index * 3

						if reciprocal then
							totalLog = -totalLog
						end

						return NanoNum.fromLog10(
							totalLog,
							negative
						)
					end
				end
			end
		end
	end

	return makeSpecial(SPECIAL_NAN)
end

local function scalarEndChecked(data: buffer, bitOffset: number, limit: number): number?
	if bitOffset < 0 or bitOffset + 1 > limit then return nil end
	local headerBits = min(7, limit - bitOffset)
	local header = bufferReadBits(data, bitOffset, headerBits)
	if band(header, 1) == 0 then
		if headerBits < 7 then return nil end
		local n = floor(header / 2)
		if n > 53 then return nil end
		local nextBit = bitOffset + 7 + n
		return nextBit <= limit and nextBit or nil
	end
	local nextBit = bitOffset + SCALAR_APPROX_BITS
	if nextBit > limit then return nil end
	local expCode = floor(bufferReadBits(data, bitOffset, 11) / 2)
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then return nil end
	return nextBit
end

local function recordEndChecked(data: buffer, bitOffset: number, limit: number?): number?
	local physicalLimit = bufferLen(data) * 8
	local endLimit = limit or physicalLimit
	if endLimit > physicalLimit or bitOffset < 0 or bitOffset + 6 > endLimit then return nil end
	local raw = bufferReadBits(data, bitOffset, 6)
	if band(raw, 1) == 0 or band(raw, 3) == 1 then
		local nextBit = bitOffset + 8
		return nextBit <= endLimit and nextBit or nil
	end
	if band(raw, 7) == 3 then
		if bitOffset + 9 > endLimit then return nil end
		local header9 = bufferReadBits(data, bitOffset, 9)
		local n = floor(header9 / 16)
		local headerEnd = bitOffset + 9
		if n == 0 then
			if bitOffset + 14 > endLimit then return nil end
			local header14 = bufferReadBits(data, bitOffset, 14)
			n = 32 + floor(header14 / 512)
			headerEnd = bitOffset + 14
			if n > MAX_INTEGER_MODE_BITS then return nil end
		end
		local nextBit = headerEnd + n
		return nextBit <= endLimit and nextBit or nil
	end
	if band(raw, 15) == 7 then
		local nextBit = bitOffset + NORMAL_BITS
		if nextBit > endLimit then return nil end
		local expCode = floor(bufferReadBits(data, bitOffset, 15) / 32)
		return expCode <= NORMAL_EXP_MAX + NORMAL_EXP_BIAS and nextBit or nil
	end
	if band(raw, 31) == 15 then return scalarEndChecked(data, bitOffset + 7, endLimit) end
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
	local special = bufferReadBits(data, bitOffset + 6, 2)
	local nextBit = bitOffset + (special == SPECIAL_RESERVED and EXACT_F64_BITS or 8)
	return nextBit <= endLimit and nextBit or nil
end

local function decodeAt(data: buffer, bitOffset: number): (DecodedValue, number)
	local totalBits = bufferLen(data) * 8
	if bitOffset < 0 or bitOffset + 6 > totalBits then error("NanoNum: truncated record") end
	local raw = bufferReadBits(data, bitOffset, 6)
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
		local n = bufferReadBits(data, bitOffset + 4, INTEGER_LEN_BITS)
		local payloadOffset = bitOffset + 9
		if n == 0 then
			n = 32 + bufferReadBits(data, payloadOffset, 5)
			payloadOffset += 5
		end
		local nextBit = payloadOffset + n
		if nextBit > totalBits then error("NanoNum: truncated integer") end
		local magnitude = readUIntExactAtFast(data, payloadOffset, n)
		return {Kind = "Integer", Value = negative and -magnitude or magnitude, Negative = negative}, nextBit
	end
	if band(raw, 15) == 7 then
		local negative = bufferReadBits(data, bitOffset + 4, 1) == 1
		local expCode = bufferReadBits(data, bitOffset + 5, NORMAL_EXP_BITS)
		local mantCode = bufferReadBits(data, bitOffset + 15, NORMAL_MANT_BITS)
		return {Kind = "Normal", Negative = negative, Exponent = expCode - NORMAL_EXP_BIAS, Mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX)}, bitOffset + NORMAL_BITS
	end
	if band(raw, 31) == 15 then
		local negative = bufferReadBits(data, bitOffset + 5, 1) == 1
		local reciprocal = bufferReadBits(data, bitOffset + 6, 1) == 1
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
			Layer = layerIsLog and nil or layer,
			LayerLog10 = layerIsLog and layer or nil,
			LayerIsLog = layerIsLog,
			Top = top,
		}, nextBit
	end
	local special = bufferReadBits(data, bitOffset + 6, 2)
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
	local bytes = bufferLen(value)
	if bytes < 1 or bytes > MAX_STANDALONE_BYTES then return false end
	local limit = bytes * 8
	local nextBit = recordEndChecked(value, 0, limit)
	if nextBit == nil then return false end
	local raw = bufferReadBits(value, 0, 6)
	if band(raw, 63) == 63 and bufferReadBits(value, 6, 2) == SPECIAL_RESERVED then
		if nextBit ~= EXACT_F64_BITS then return false end
		local exact = readExactF64At(value, 0)
		if exact ~= exact or exact == huge or exact == -huge then return false end
	end
	local offset = nextBit
	while offset < limit do
		local count = min(32, limit - offset)
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
	local raw = bufferReadBits(value, 0, 6)
	if band(raw, 1) == 0 then
		local magnitude = bufferReadBits(value, 1, 7)
		if magnitude == 0 then return 0, 0, 0 end
		return K_NUM, magnitude, 0
	end
	if band(raw, 3) == 1 then return -K_NUM, bufferReadBits(value, 2, 6) + 1, 0 end
	if band(raw, 7) == 3 then
		local negative = bufferReadBits(value, 3, 1) == 1
		local n = bufferReadBits(value, 4, INTEGER_LEN_BITS)
		local offset = 9
		if n == 0 then
			n = 32 + bufferReadBits(value, offset, 5)
			offset += 5
		end
		local magnitude = readUIntExactAtFast(value, offset, n)
		return negative and -K_NUM or K_NUM, magnitude, 0
	end
	if band(raw, 15) == 7 then
		local negative = bufferReadBits(value, 4, 1) == 1
		local exponent = bufferReadBits(value, 5, NORMAL_EXP_BITS) - NORMAL_EXP_BIAS
		local mantissa = decodeMantissa(bufferReadBits(value, 15, NORMAL_MANT_BITS), NORMAL_MANT_MAX)
		local logMagnitude = exponent + log10(mantissa)
		if logMagnitude >= DIRECT_LOG_MIN and logMagnitude <= DIRECT_LOG_MAX then
			local magnitude = 10 ^ logMagnitude
			if magnitude ~= 0 and magnitude ~= huge then return negative and -K_NUM or K_NUM, magnitude, 0 end
		end
		return negative and -K_LOG or K_LOG, logMagnitude, 0
	end
	if band(raw, 31) == 15 then
		local negative = bufferReadBits(value, 5, 1) == 1
		local reciprocal = bufferReadBits(value, 6, 1) == 1
		local top = readScalarAtFast(value, 7)
		return negative and -K_LOG or K_LOG, reciprocal and -top or top, 0
	end
	if band(raw, 63) == 31 then
		local negative = bufferReadBits(value, 6, 1) == 1
		local reciprocal = bufferReadBits(value, 7, 1) == 1
		local layer, layerIsLog, nextBit = readLayerFieldAtFast(value, 8)
		local top = readScalarAtFast(value, nextBit)
		local signedLayer = reciprocal and -layer or layer
		local kind = layerIsLog and K_LAYER_LOG or K_LAYER
		return negative and -kind or kind, signedLayer, top
	end
	local special = bufferReadBits(value, 6, 2)
	if special == SPECIAL_RESERVED then
		local exact = bufferReadF64(value, 1)
		if exact ~= exact then return K_NAN, 0, 0 end
		if exact == huge then return K_INF, 0, 0 end
		if exact == -huge then return -K_INF, 0, 0 end
		if exact == 0 then return 0, 0, 0 end
		return exact < 0 and -K_NUM or K_NUM, exact < 0 and -exact or exact, 0
	end
	if special == SPECIAL_POS_INF then return K_INF, 0, 0 end
	if special == SPECIAL_NEG_INF then return -K_INF, 0, 0 end
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

local function decodeReg(value: any): (number, number, number)
	local kind = typeof(value)
	if kind == "number" then return regFromNumber(value) end
	if kind == "buffer" then return decodeRegBuffer(value) end
	if kind == "string" then return decodeRegBuffer(NanoNum.fromString(value)) end
	return K_NAN, 0, 0
end

local function encodeReg(kind: number, a: number, b: number): buffer
	if kind == 0 then return NanoNum.fromNumber(0) end
	local absoluteKind = abs(kind)
	local negative = kind < 0
	if absoluteKind == K_NUM then return NanoNum.fromNumber(negative and -a or a) end
	if absoluteKind == K_LOG then return NanoNum.fromLog10(a, negative) end
	if absoluteKind == K_LAYER then return NanoNum.fromLayer(abs(a), b, negative, a < 0) end
	if absoluteKind == K_LAYER_LOG then return NanoNum.fromLayerLog10(abs(a), b, negative, a < 0) end
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
	local absoluteKind = abs(kind)
	if absoluteKind == K_NUM then return log10(a) end
	if absoluteKind == K_LOG then return a end
	return nil
end

local function regToNumber(kind: number, a: number, b: number): number
	if kind == 0 then return 0 end
	local absoluteKind = abs(kind)
	local negative = kind < 0
	if absoluteKind == K_NUM then return negative and -a or a end
	if absoluteKind == K_LOG then
		if a > DIRECT_LOG_MAX then return negative and -huge or huge end
		if a < DIRECT_LOG_MIN then return negative and -0 or 0 end
		local magnitude = 10 ^ a
		return negative and -magnitude or magnitude
	end
	if absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG then
		if a < 0 then return negative and -0 or 0 end
		return negative and -huge or huge
	end
	if absoluteKind == K_INF then return negative and -huge or huge end
	return NAN
end

local function regNeg(kind: number, a: number, b: number): (number, number, number)
	if kind == 0 or abs(kind) == K_NAN then return kind, a, b end
	return -kind, a, b
end

local function regAbs(kind: number, a: number, b: number): (number, number, number)
	return abs(kind), a, b
end

local function regReciprocal(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind = abs(kind)
	if absoluteKind == K_NAN then return K_NAN, 0, 0 end
	if kind == 0 then return K_INF, 0, 0 end
	if absoluteKind == K_INF then return 0, 0, 0 end
	if absoluteKind == K_NUM then return regFromSignedLog(-log10(a), kind < 0) end
	if absoluteKind == K_LOG then return kind, -a, 0 end
	if absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG then return kind, -a, b end
	return K_NAN, 0, 0
end

local function regLayerCompare(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): number
	local aKind = abs(ak)
	local bKind = abs(bk)
	local aReciprocal = aa < 0
	local bReciprocal = ba < 0
	if aReciprocal ~= bReciprocal then return aReciprocal and -1 or 1 end
	local cmp = 0
	if aKind ~= bKind then
		cmp = aKind == K_LAYER_LOG and 1 or -1
	else
		local al = abs(aa)
		local bl = abs(ba)
		if al < bl then cmp = -1 elseif al > bl then cmp = 1 elseif ab < bb then cmp = -1 elseif ab > bb then cmp = 1 end
	end
	return aReciprocal and -cmp or cmp
end

local function regAbsCompare(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): number
	if ak == 0 then return bk == 0 and 0 or -1 end
	if bk == 0 then return 1 end
	local aKind = abs(ak)
	local bKind = abs(bk)
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG
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
	local aKind = abs(ak)
	local bKind = abs(bk)
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
	local aKind = abs(ak)
	local bKind = abs(bk)
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
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG
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
		local hi = max(la, lb)
		local lo = min(la, lb)
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
	local term = 1 - 10 ^ (-delta)
	if term <= 0 then return 0, 0, 0 end
	return regFromSignedLog(hi + log10(term), negative)
end

local function regSub(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	if bk ~= 0 and abs(bk) ~= K_NAN then bk = -bk end
	return regAdd(ak, aa, ab, bk, ba, bb)
end

local function regMul(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	local aKind = abs(ak)
	local bKind = abs(bk)
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
	local aLayer = aKind == K_LAYER or aKind == K_LAYER_LOG
	local bLayer = bKind == K_LAYER or bKind == K_LAYER_LOG
	if not aLayer and not bLayer then
		local la = regLogAbs(ak, aa)
		local lb = regLogAbs(bk, ba)
		if la == nil or lb == nil then return K_NAN, 0, 0 end
		return regFromSignedLog(la + lb, negative)
	end
	if aLayer ~= bLayer then
		local lk = aLayer and ak or bk
		local la = aLayer and aa or ba
		local lb = aLayer and ab or bb
		local ok = aLayer and bk or ak
		local oa = aLayer and ba or aa
		local otherLog = regLogAbs(ok, oa)
		if otherLog == nil then return K_NAN, 0, 0 end
		if abs(lk) == K_LAYER and abs(la) == 2 and lb <= DIRECT_LOG_MAX then
			local tower = 10 ^ lb
			if la < 0 then tower = -tower end
			return regFromSignedLog(tower + otherLog, negative)
		end
		return negative and -abs(lk) or abs(lk), la, lb
	end
	if aKind == K_LAYER and bKind == K_LAYER and abs(aa) == 2 and abs(ba) == 2 then
		local sa = aa < 0 and -1 or 1
		local sb = ba < 0 and -1 or 1
		if sa == sb then
			local hi = max(ab, bb)
			local lo = min(ab, bb)
			return negative and -K_LAYER or K_LAYER, sa < 0 and -2 or 2, hi + log10(1 + 10 ^ (lo - hi))
		end
		if ab == bb then return negative and -K_NUM or K_NUM, 1, 0 end
		local hi = ab > bb and ab or bb
		local lo = ab > bb and bb or ab
		local reciprocal = ab > bb and sa < 0 or sb < 0
		local term = 1 - 10 ^ (lo - hi)
		if term <= 0 then return negative and -K_NUM or K_NUM, 1, 0 end
		return negative and -K_LAYER or K_LAYER, reciprocal and -2 or 2, hi + log10(term)
	end
	local cmp = regLayerCompare(ak, aa, ab, bk, ba, bb)
	if cmp == 0 then
		if (aa < 0) ~= (ba < 0) then return negative and -K_NUM or K_NUM, 1, 0 end
		return negative and -aKind or aKind, aa, ab
	end
	if cmp > 0 then return negative and -aKind or aKind, aa, ab end
	return negative and -bKind or bKind, ba, bb
end

local function regDiv(ak: number, aa: number, ab: number, bk: number, ba: number, bb: number): (number, number, number)
	local rk, ra, rb = regReciprocal(bk, ba, bb)
	return regMul(ak, aa, ab, rk, ra, rb)
end

local function regLog10(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind = abs(kind)
	if absoluteKind == K_NAN or kind < 0 then return K_NAN, 0, 0 end
	if kind == 0 then return -K_INF, 0, 0 end
	if absoluteKind == K_INF then return K_INF, 0, 0 end
	if absoluteKind == K_NUM then return regFromNumber(log10(a)) end
	if absoluteKind == K_LOG then return regFromNumber(a) end
	if absoluteKind == K_LAYER then
		local reciprocal = a < 0
		local layer = abs(a)
		if layer == 2 then return reciprocal and -K_LOG or K_LOG, b, 0 end
		return reciprocal and -K_LAYER or K_LAYER, layer - 1, b
	end
	if absoluteKind == K_LAYER_LOG then return a < 0 and -K_LAYER_LOG or K_LAYER_LOG, abs(a), b end
	return K_NAN, 0, 0
end

local function regPow10(kind: number, a: number, b: number): (number, number, number)
	local absoluteKind = abs(kind)
	if absoluteKind == K_NAN then return K_NAN, 0, 0 end
	if kind == 0 then return K_NUM, 1, 0 end
	if absoluteKind == K_INF then return kind < 0 and 0 or K_INF, 0, 0 end
	if absoluteKind == K_NUM then return regFromSignedLog(kind < 0 and -a or a, false) end
	if absoluteKind == K_LOG then
		local direct = regToNumber(kind, a, b)
		if direct ~= huge and direct ~= -huge then return regFromSignedLog(direct, false) end
		return K_LAYER, kind < 0 and -2 or 2, abs(a)
	end
	if absoluteKind == K_LAYER or absoluteKind == K_LAYER_LOG then
		if a < 0 then return K_NUM, 1, 0 end
		if absoluteKind == K_LAYER_LOG then return K_LAYER_LOG, a, b end
		return K_LAYER, min(a + 1, NanoNum.MAX_LAYER), b
	end
	return K_NAN, 0, 0
end

local function regIsInteger(kind: number, a: number, b: number): boolean
	local absoluteKind = abs(kind)
	if absoluteKind == K_NUM then return a == floor(a) end
	if absoluteKind == K_LOG then return a >= 0 and a == floor(a) end
	if absoluteKind == K_LAYER then return a > 0 and b >= 0 and b == floor(b) end
	return false
end

local function regIsOdd(kind: number, a: number, b: number): boolean
	local absoluteKind = abs(kind)
	if absoluteKind == K_NUM then return a == floor(a) and a % 2 == 1 end
	if absoluteKind == K_LOG then return a == 0 end
	return false
end

local function regPow(bk: number, ba: number, bb: number, ek: number, ea: number, eb: number): (number, number, number)
	local baseKind = abs(bk)
	local exponentKind = abs(ek)
	if baseKind == K_NAN or exponentKind == K_NAN then return K_NAN, 0, 0 end
	if ek == 0 then return K_NUM, 1, 0 end
	if bk == 0 then
		if ek > 0 then return 0, 0, 0 end
		return K_INF, 0, 0
	end
	local negativeResult = false
	if bk < 0 then
		if not regIsInteger(ek, ea, eb) then return K_NAN, 0, 0 end
		negativeResult = regIsOdd(ek, ea, eb)
		bk = -bk
	end
	if abs(bk) == K_NUM and abs(ek) == K_NUM then
		local exponent = ek < 0 and -ea or ea
		local native = ba ^ exponent
		if native == native and native ~= huge and native ~= 0 then return negativeResult and -K_NUM or K_NUM, native, 0 end
	end
	local baseLog = regLogAbs(bk, ba)
	if baseLog ~= nil then
		local exponent = regToNumber(ek, ea, eb)
		if exponent == exponent and exponent ~= huge and exponent ~= -huge then
			local rk, ra, rb = regFromSignedLog(baseLog * exponent, negativeResult)
			return rk, ra, rb
		end
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

function NanoNum.add(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local x = a :: number
		local y = b :: number
		local value = x + y
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		local value = x + y
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

function NanoNum.sub(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local value = (a :: number) - (b :: number)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

function NanoNum.mul(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local x = a :: number
		local y = b :: number
		local value = x * y
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or x == 0 or y == 0) then return NanoNum.fromNumber(value) end
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

function NanoNum.div(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local x = a :: number
		local y = b :: number
		if y ~= 0 then
			local value = x / y
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or x == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

function NanoNum.pow(a: MathValue, b: MathValue): buffer
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local x = a :: number
		local y = b :: number
		if x >= 0 or y == floor(y) then
			local value = x ^ y
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or x == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

function NanoNum.compare(a: MathValue, b: MathValue): number
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then
		local x = a :: number
		local y = b :: number
		if x ~= x or y ~= y then return NAN end
		if x < y then return -1 end
		if x > y then return 1 end
		return 0
	end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 end
		if x > y then return 1 end
		return 0
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

function NanoNum.eq(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then return (a :: number) == (b :: number) end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		return (ak < 0 and -aa or aa) == (bk < 0 and -ba or ba)
	end
	return regCompare(ak, aa, ab, bk, ba, bb) == 0
end

function NanoNum.lt(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then return (a :: number) < (b :: number) end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then return (ak < 0 and -aa or aa) < (bk < 0 and -ba or ba) end
	return regCompare(ak, aa, ab, bk, ba, bb) < 0
end

function NanoNum.lte(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then return (a :: number) <= (b :: number) end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then return (ak < 0 and -aa or aa) <= (bk < 0 and -ba or ba) end
	return regCompare(ak, aa, ab, bk, ba, bb) <= 0
end

function NanoNum.gt(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then return (a :: number) > (b :: number) end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then return (ak < 0 and -aa or aa) > (bk < 0 and -ba or ba) end
	return regCompare(ak, aa, ab, bk, ba, bb) > 0
end

function NanoNum.gte(a: MathValue, b: MathValue): boolean
	local at = typeof(a)
	local bt = typeof(b)
	if at == "number" and bt == "number" then return (a :: number) >= (b :: number) end
	local ak, aa, ab
	local bk, ba, bb
	if at == "buffer" then ak, aa, ab = decodeRegBuffer(a :: buffer)
	elseif at == "number" then
		local x = a :: number
		if x ~= x then ak, aa, ab = K_NAN, 0, 0
		elseif x == huge then ak, aa, ab = K_INF, 0, 0
		elseif x == -huge then ak, aa, ab = -K_INF, 0, 0
		elseif x == 0 then ak, aa, ab = 0, 0, 0
		else ak, aa, ab = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else ak, aa, ab = directDecode(a) end
	if bt == "buffer" then bk, ba, bb = decodeRegBuffer(b :: buffer)
	elseif bt == "number" then
		local x = b :: number
		if x ~= x then bk, ba, bb = K_NAN, 0, 0
		elseif x == huge then bk, ba, bb = K_INF, 0, 0
		elseif x == -huge then bk, ba, bb = -K_INF, 0, 0
		elseif x == 0 then bk, ba, bb = 0, 0, 0
		else bk, ba, bb = x < 0 and -K_NUM or K_NUM, x < 0 and -x or x, 0 end
	else bk, ba, bb = directDecode(b) end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then return (ak < 0 and -aa or aa) >= (bk < 0 and -ba or ba) end
	return regCompare(ak, aa, ab, bk, ba, bb) >= 0
end

function NanoNum.sign(value: MathValue): number
	local kind = decodeReg(value)
	return regSign(kind)
end

function NanoNum.neg(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regNeg(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.abs(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regAbs(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.reciprocal(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regReciprocal(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.copySign(value: MathValue, signSource: MathValue): buffer
	local k, a, b = decodeReg(value)
	local sk = decodeReg(signSource)
	if abs(k) == K_NAN or abs(sk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if sk < 0 then k = -abs(k) else k = abs(k) end
	return encodeReg(k, a, b)
end

function NanoNum.toNumber(value: MathValue): number
	local k, a, b = decodeReg(value)
	return regToNumber(k, a, b)
end

function NanoNum.toNumberSafe(value: MathValue): number?
	local k, a, b = directDecode(value)
	local n = regToNumber(k, a, b)
	if n ~= n or n == huge or n == -huge then return nil end
	return n
end

function NanoNum.isNaN(value: MathValue): boolean
	local k = decodeReg(value)
	return abs(k) == K_NAN
end

function NanoNum.isInfinite(value: MathValue): boolean
	local k = decodeReg(value)
	return abs(k) == K_INF
end

function NanoNum.isFinite(value: MathValue): boolean
	local k = decodeReg(value)
	return abs(k) ~= K_NAN and abs(k) ~= K_INF
end

function NanoNum.isZero(value: MathValue): boolean
	local k = decodeReg(value)
	return k == 0
end

function NanoNum.isInteger(value: MathValue): boolean
	local k, a, b = decodeReg(value)
	return regIsInteger(k, a, b)
end

function NanoNum.isOdd(value: MathValue): boolean
	local k, a, b = decodeReg(value)
	return regIsOdd(k, a, b)
end

function NanoNum.isEven(value: MathValue): boolean
	local k, a, b = decodeReg(value)
	return regIsInteger(k, a, b) and not regIsOdd(k, a, b)
end

function NanoNum.isPositive(value: MathValue): boolean
	local k = directDecode(value)
	return k > 0 and abs(k) ~= K_NAN
end
function NanoNum.isNegative(value: MathValue): boolean
	local k = directDecode(value)
	return k < 0 and abs(k) ~= K_NAN
end

function NanoNum.min(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if regCompare(ak, aa, ab, bk, ba, bb) <= 0 then return encodeReg(ak, aa, ab) end
	return encodeReg(bk, ba, bb)
end

function NanoNum.max(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	if regCompare(ak, aa, ab, bk, ba, bb) >= 0 then return encodeReg(ak, aa, ab) end
	return encodeReg(bk, ba, bb)
end

function NanoNum.clamp(value: MathValue, low: MathValue, high: MathValue): buffer
	local vk, va, vb = decodeReg(value)
	local lk, la, lb = decodeReg(low)
	local hk, ha, hb = decodeReg(high)
	if regCompare(lk, la, lb, hk, ha, hb) > 0 then return makeSpecial(SPECIAL_NAN) end
	if regCompare(vk, va, vb, lk, la, lb) < 0 then return encodeReg(lk, la, lb) end
	if regCompare(vk, va, vb, hk, ha, hb) > 0 then return encodeReg(hk, ha, hb) end
	return encodeReg(vk, va, vb)
end

function NanoNum.clamp01(value: MathValue): buffer return NanoNum.clamp(value, 0, 1) end

function NanoNum.floor(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(floor(n)) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG then
		if a < 0 then return NanoNum.fromNumber(k < 0 and -1 or 0) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end

function NanoNum.ceil(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(ceil(n)) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG then
		if a < 0 then return NanoNum.fromNumber(k < 0 and 0 or 1) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end

function NanoNum.trunc(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then return NanoNum.fromNumber(n < 0 and ceil(n) or floor(n)) end
	if abs(k) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if abs(k) == K_INF then return encodeReg(k, a, b) end
	if abs(k) == K_LOG or abs(k) == K_LAYER or abs(k) == K_LAYER_LOG then
		if a < 0 then return NanoNum.fromNumber(0) end
		return encodeReg(k, a, b)
	end
	return encodeReg(k, a, b)
end

function NanoNum.round(value: MathValue, decimals: number?): buffer
	local places = decimals or 0
	if places ~= floor(places) or places < -308 or places > 308 then return makeSpecial(SPECIAL_NAN) end
	local k, a, b = directDecode(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge then
		local scale = 10 ^ places
		local scaled = n * scale
		local rounded = scaled >= 0 and floor(scaled + 0.5) or ceil(scaled - 0.5)
		return NanoNum.fromNumber(rounded / scale)
	end
	return encodeReg(k, a, b)
end

function NanoNum.frac(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
	if n ~= n or n == huge or n == -huge then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.fromNumber(n - (n < 0 and ceil(n) or floor(n)))
end

local function exactInteger(value: MathValue): number?
	local k, a, b = decodeReg(value)
	if abs(k) == K_NUM and a == floor(a) and a <= SAFE_INTEGER then return k < 0 and -a or a end
	return nil
end

function NanoNum.mod(a: MathValue, b: MathValue): buffer
	local x = exactInteger(a)
	local y = exactInteger(b)
	if x == nil or y == nil or y == 0 then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.fromNumber(x % y)
end

function NanoNum.fmod(a: MathValue, b: MathValue): buffer
	local x = exactInteger(a)
	local y = exactInteger(b)
	if x == nil or y == nil or y == 0 then return makeSpecial(SPECIAL_NAN) end
	local r = x % y
	if r ~= 0 and ((r < 0) ~= (x < 0)) then r -= y end
	return NanoNum.fromNumber(r)
end

function NanoNum.divmod(a: MathValue, b: MathValue): (buffer, buffer)
	local x = exactInteger(a)
	local y = exactInteger(b)
	if x == nil or y == nil or y == 0 then
		local nan = makeSpecial(SPECIAL_NAN)
		return nan, nan
	end
	local r = x % y
	local q = (x - r) / y
	return NanoNum.fromNumber(q), NanoNum.fromNumber(r)
end

function NanoNum.log10(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regLog10(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.ln(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regLog10(k, a, b)
	local ck, ca, cb = regFromNumber(LN10)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	return encodeReg(k, a, b)
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
	local lk, la, lb = regLog10(vk, va, vb)
	local rk, ra, rb = regLog10(bk, ba, bb)
	lk, la, lb = regDiv(lk, la, lb, rk, ra, rb)
	return encodeReg(lk, la, lb)
end

function NanoNum.log2(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regLog10(k, a, b)
	local ck, ca, cb = regFromNumber(LOG10_2)
	k, a, b = regDiv(k, a, b, ck, ca, cb)
	return encodeReg(k, a, b)
end

function NanoNum.log1p(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local n = regToNumber(k, a, b)
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
	local k, a, b = decodeReg(value)
	local ck, ca, cb = regFromNumber(LOG10_E)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.exp2(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local ck, ca, cb = regFromNumber(LOG10_2)
	k, a, b = regMul(k, a, b, ck, ca, cb)
	k, a, b = regPow10(k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.expm1(value: MathValue): buffer
	local k, a, b = directDecode(value)
	local n = regToNumber(k, a, b)
	if n == n and n ~= huge and n ~= -huge and abs(n) < 1e-5 then
		local n2 = n * n
		local n3 = n2 * n
		local n4 = n3 * n
		local n5 = n4 * n
		local n6 = n5 * n
		return NanoNum.fromNumber(n + n2 / 2 + n3 / 6 + n4 / 24 + n5 / 120 + n6 / 720)
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
	local k, a, b = decodeReg(value)
	local ek, ea, eb = regFromNumber(0.5)
	k, a, b = regPow(k, a, b, ek, ea, eb)
	return encodeReg(k, a, b)
end

function NanoNum.cbrt(value: MathValue): buffer
	local k, a, b = directDecode(value)
	if k < 0 then
		k = -k
		local ek, ea, eb = K_NUM, 1 / 3, 0
		k, a, b = regPow(k, a, b, ek, ea, eb)
		if k ~= 0 and abs(k) ~= K_NAN then k = -k end
		return encodeReg(k, a, b)
	end
	local ek, ea, eb = K_NUM, 1 / 3, 0
	k, a, b = regPow(k, a, b, ek, ea, eb)
	return encodeReg(k, a, b)
end

function NanoNum.root(value: MathValue, degree: MathValue): buffer
	local vk, va, vb = decodeReg(value)
	local dk, da, db = decodeReg(degree)
	if dk == 0 or abs(vk) == K_NAN or abs(dk) == K_NAN then return makeSpecial(SPECIAL_NAN) end
	if vk < 0 and not regIsOdd(dk, da, db) then return makeSpecial(SPECIAL_NAN) end
	local oneK, oneA, oneB = regFromNumber(1)
	dk, da, db = regDiv(oneK, oneA, oneB, dk, da, db)
	local negative = vk < 0
	if negative then vk = -vk end
	vk, va, vb = regPow(vk, va, vb, dk, da, db)
	if negative and vk ~= 0 then vk = -vk end
	return encodeReg(vk, va, vb)
end

function NanoNum.square(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	k, a, b = regMul(k, a, b, k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.cube(value: MathValue): buffer
	local k, a, b = decodeReg(value)
	local k2, a2, b2 = regMul(k, a, b, k, a, b)
	k, a, b = regMul(k2, a2, b2, k, a, b)
	return encodeReg(k, a, b)
end

function NanoNum.hypot(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	local a2k, a2a, a2b = regMul(ak, aa, ab, ak, aa, ab)
	local b2k, b2a, b2b = regMul(bk, ba, bb, bk, ba, bb)
	local sk, sa, sb = regAdd(a2k, a2a, a2b, b2k, b2a, b2b)
	local ek, ea, eb = regFromNumber(0.5)
	sk, sa, sb = regPow(sk, sa, sb, ek, ea, eb)
	return encodeReg(sk, sa, sb)
end

function NanoNum.lerp(a: MathValue, b: MathValue, t: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
	local tk, ta, tb = decodeReg(t)
	local dk, da, db = regSub(bk, ba, bb, ak, aa, ab)
	dk, da, db = regMul(dk, da, db, tk, ta, tb)
	ak, aa, ab = regAdd(ak, aa, ab, dk, da, db)
	return encodeReg(ak, aa, ab)
end

function NanoNum.inverseLerp(a: MathValue, b: MathValue, value: MathValue): buffer
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
	local t = NanoNum.inverseLerp(inMin, inMax, value)
	if NanoNum.isNaN(t) then return t end
	return NanoNum.lerp(outMin, outMax, t)
end

function NanoNum.moveTowards(current: MathValue, target: MathValue, maxDelta: MathValue): buffer
	if NanoNum.lt(maxDelta, 0) then return makeSpecial(SPECIAL_NAN) end
	local delta = NanoNum.sub(target, current)
	if NanoNum.lte(NanoNum.abs(delta), maxDelta) then return NanoNum.compile(target) end
	return NanoNum.add(current, NanoNum.mul(maxDelta, NanoNum.sign(delta)))
end

function NanoNum.distance(a: MathValue, b: MathValue): buffer
	local ak, aa, ab = decodeReg(a)
	local bk, ba, bb = decodeReg(b)
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
	if NanoNum.eq(a, b) then return true end
	local rel = relativeTolerance or 1e-9
	local absTol = absoluteTolerance or 0
	if NanoNum.lt(rel, 0) or NanoNum.lt(absTol, 0) then return false end
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
	local t = NanoNum.clamp01(NanoNum.inverseLerp(edge0, edge1, value))
	return NanoNum.mul(NanoNum.mul(t, t), NanoNum.sub(3, NanoNum.mul(2, t)))
end

function NanoNum.smootherstep(edge0: MathValue, edge1: MathValue, value: MathValue): buffer
	local t = NanoNum.clamp01(NanoNum.inverseLerp(edge0, edge1, value))
	local t2 = NanoNum.mul(t, t)
	local t3 = NanoNum.mul(t2, t)
	return NanoNum.mul(t3, NanoNum.add(NanoNum.mul(t, NanoNum.sub(NanoNum.mul(6, t), 15)), 10))
end

function NanoNum.sum(values: MathValueArray): buffer
	local rk = 0
	local ra = 0
	local rb = 0
	for i = 1, #values do
		local vk, va, vb = decodeReg(values[i])
		rk, ra, rb = regAdd(rk, ra, rb, vk, va, vb)
	end
	return encodeReg(rk, ra, rb)
end

function NanoNum.product(values: MathValueArray): buffer
	local rk = K_NUM
	local ra = 1
	local rb = 0
	for i = 1, #values do
		local vk, va, vb = decodeReg(values[i])
		rk, ra, rb = regMul(rk, ra, rb, vk, va, vb)
	end
	return encodeReg(rk, ra, rb)
end

function NanoNum.mean(values: MathValueArray): buffer
	if #values == 0 then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.div(NanoNum.sum(values), #values)
end

function NanoNum.geometricMean(values: MathValueArray): buffer
	if #values == 0 then return makeSpecial(SPECIAL_NAN) end
	local totalK = 0
	local totalA = 0
	local totalB = 0
	for i = 1, #values do
		local k, a, b = decodeReg(values[i])
		if regCompare(k, a, b, 0, 0, 0) <= 0 then return makeSpecial(SPECIAL_NAN) end
		k, a, b = regLog10(k, a, b)
		totalK, totalA, totalB = regAdd(totalK, totalA, totalB, k, a, b)
	end
	local ck, ca, cb = regFromNumber(#values)
	totalK, totalA, totalB = regDiv(totalK, totalA, totalB, ck, ca, cb)
	totalK, totalA, totalB = regPow10(totalK, totalA, totalB)
	return encodeReg(totalK, totalA, totalB)
end

function NanoNum.harmonicMean(values: MathValueArray): buffer
	if #values == 0 then return makeSpecial(SPECIAL_NAN) end
	local totalK = 0
	local totalA = 0
	local totalB = 0
	for i = 1, #values do
		local k, a, b = decodeReg(values[i])
		if k == 0 then return NanoNum.fromNumber(0) end
		k, a, b = regReciprocal(k, a, b)
		totalK, totalA, totalB = regAdd(totalK, totalA, totalB, k, a, b)
	end
	local ck, ca, cb = regFromNumber(#values)
	ck, ca, cb = regDiv(ck, ca, cb, totalK, totalA, totalB)
	return encodeReg(ck, ca, cb)
end

local function factorialLog10(n: number): number
	if n < 2 then return 0 end
	if n <= 256 then
		local total = 0
		for i = 2, n do total += log10(i) end
		return total
	end
	local inv = 1 / n
	local correction = inv / 12 - inv ^ 3 / 360 + inv ^ 5 / 1260
	return (n + 0.5) * log10(n) - n * LOG10_E + 0.5 * log10(TWO_PI) + correction * LOG10_E
end

function NanoNum.factorial(value: MathValue): buffer
	local n = exactInteger(value)
	if n == nil or n < 0 then return makeSpecial(SPECIAL_NAN) end
	if n <= 1 then return NanoNum.fromNumber(1) end
	if n <= 20 then
		local result = 1
		for i = 2, n do result *= i end
		return NanoNum.fromNumber(result)
	end
	return NanoNum.fromLog10(factorialLog10(n))
end

local LANCZOS = {
	676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059,
	12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7,
}

local function logGammaDirect(x: number): number
	if x <= 0 then return NAN end
	local z = x - 1
	local a = 0.99999999999980993
	for i = 1, #LANCZOS do a += LANCZOS[i] / (z + i) end
	local t = z + 7.5
	return 0.5 * log(TWO_PI) + (z + 0.5) * log(t) - t + log(a)
end

function NanoNum.gammaSign(value: MathValue): number
	local n = NanoNum.toNumber(value)
	if n ~= n then return NAN end
	if n == huge then return 1 end
	if n == -huge then return NAN end
	if n > 0 then return 1 end
	if n == floor(n) then return 0 end
	local s = sin(pi * n)
	if s > 0 then return 1 end
	if s < 0 then return -1 end
	return 0
end

function NanoNum.logGamma(value: MathValue): buffer
	local n = NanoNum.toNumber(value)
	if n ~= n then return makeSpecial(SPECIAL_NAN) end
	if n == huge then return makeSpecial(SPECIAL_POS_INF) end
	if n == 0 or n == floor(n) and n < 0 then return makeSpecial(SPECIAL_POS_INF) end
	if n > 0 and n < 1e6 then return NanoNum.fromNumber(logGammaDirect(n)) end
	if n < 0 and abs(n) < 1e6 then
		local s = sin(pi * n)
		if s == 0 then return makeSpecial(SPECIAL_POS_INF) end
		return NanoNum.fromNumber(log(pi) - log(abs(s)) - logGammaDirect(1 - n))
	end
	if n > 0 then
		local x = n
		local inv = 1 / x
		local valueLog = (x - 0.5) * log(x) - x + 0.5 * log(TWO_PI) + inv / 12 - inv ^ 3 / 360 + inv ^ 5 / 1260
		return NanoNum.fromNumber(valueLog)
	end
	return makeSpecial(SPECIAL_NAN)
end

function NanoNum.gamma(value: MathValue): buffer
	local sign = NanoNum.gammaSign(value)
	if sign ~= sign or sign == 0 then return makeSpecial(SPECIAL_NAN) end
	local magnitude = NanoNum.exp(NanoNum.logGamma(value))
	return sign < 0 and NanoNum.neg(magnitude) or magnitude
end

function NanoNum.factorialReal(value: MathValue): buffer return NanoNum.gamma(NanoNum.add(value, 1)) end

function NanoNum.permutation(nValue: MathValue, rValue: MathValue): buffer
	local n = exactInteger(nValue)
	local r = exactInteger(rValue)
	if n == nil or r == nil or n < 0 or r < 0 or r > n then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.div(NanoNum.factorial(n), NanoNum.factorial(n - r))
end

function NanoNum.combination(nValue: MathValue, rValue: MathValue): buffer
	local n = exactInteger(nValue)
	local r = exactInteger(rValue)
	if n == nil or r == nil or n < 0 or r < 0 or r > n then return makeSpecial(SPECIAL_NAN) end
	r = min(r, n - r)
	if r == 0 then return NanoNum.fromNumber(1) end
	local result = 1
	for i = 1, r do
		local candidate = result * (n - r + i) / i
		if candidate > SAFE_INTEGER then
			return NanoNum.fromLog10(factorialLog10(n) - factorialLog10(r) - factorialLog10(n - r))
		end
		result = floor(candidate + 0.5)
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
	if NanoNum.eq(ratioValue, 1) then return NanoNum.mul(first, count) end
	return NanoNum.mul(first, NanoNum.div(NanoNum.sub(NanoNum.pow(ratioValue, count), 1), NanoNum.sub(ratioValue, 1)))
end

function NanoNum.compound(principal: MathValue, rate: MathValue, periods: MathValue): buffer
	return NanoNum.mul(principal, NanoNum.pow(NanoNum.add(1, rate), periods))
end

function NanoNum.softcap(value: MathValue, start: MathValue, power: MathValue): buffer
	if NanoNum.lte(start, 0) or NanoNum.lte(power, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(value, start) then return NanoNum.compile(value) end
	return NanoNum.mul(start, NanoNum.pow(NanoNum.div(value, start), power))
end

function NanoNum.inverseSoftcap(value: MathValue, start: MathValue, power: MathValue): buffer
	if NanoNum.lte(start, 0) or NanoNum.lte(power, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.lte(value, start) then return NanoNum.compile(value) end
	return NanoNum.mul(start, NanoNum.pow(NanoNum.div(value, start), NanoNum.reciprocal(power)))
end

function NanoNum.diminishingReturns(value: MathValue, scale: MathValue): buffer
	if NanoNum.lte(scale, 0) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.mul(scale, NanoNum.neg(NanoNum.expm1(NanoNum.neg(NanoNum.div(value, scale)))))
end

function NanoNum.inverseDiminishingReturns(value: MathValue, scale: MathValue): buffer
	if NanoNum.lte(scale, 0) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
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
	if NanoNum.lte(baseCost, 0) or NanoNum.lt(owned, 0) or NanoNum.lt(amount, 0) or NanoNum.lt(growth, 1) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isZero(amount) then return NanoNum.fromNumber(0) end
	local currentCost = NanoNum.mul(baseCost, NanoNum.pow(growth, owned))
	if NanoNum.eq(growth, 1) then return NanoNum.mul(currentCost, amount) end
	return NanoNum.mul(currentCost, NanoNum.div(NanoNum.sub(NanoNum.pow(growth, amount), 1), NanoNum.sub(growth, 1)))
end

function NanoNum.maxAffordableGeometric(currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?): buffer
	local levelsOwned = owned or 0
	if NanoNum.lt(currency, 0) or NanoNum.lte(baseCost, 0) or NanoNum.lt(levelsOwned, 0) or NanoNum.lt(growth, 1) then return makeSpecial(SPECIAL_NAN) end
	local currentCost = NanoNum.mul(baseCost, NanoNum.pow(growth, levelsOwned))
	if NanoNum.lt(currency, currentCost) then return NanoNum.fromNumber(0) end
	if NanoNum.eq(growth, 1) then return NanoNum.floor(NanoNum.div(currency, currentCost)) end
	local inside = NanoNum.add(1, NanoNum.div(NanoNum.mul(currency, NanoNum.sub(growth, 1)), currentCost))
	return NanoNum.floor(NanoNum.log(inside, growth))
end

function NanoNum.bulkBuyGeometric(currency: MathValue, baseCost: MathValue, growth: MathValue, owned: MathValue?): (buffer, buffer, buffer)
	local amount = NanoNum.maxAffordableGeometric(currency, baseCost, growth, owned)
	if NanoNum.isNaN(amount) then
		local nan = makeSpecial(SPECIAL_NAN)
		return nan, nan, nan
	end
	local cost = NanoNum.geometricCost(baseCost, growth, owned or 0, amount)
	local remaining = NanoNum.sub(currency, cost)
	if NanoNum.lt(remaining, 0) and NanoNum.approxEq(remaining, 0, 1e-10, 0) then remaining = NanoNum.fromNumber(0) end
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
	if abs(k) == K_LAYER and k > 0 and a > 0 then return NanoNum.fromLayer(min(a + times, NanoNum.MAX_LAYER), b) end
	for _ = 1, min(times, 32) do
		k, a, b = regPow10(k, a, b)
		if abs(k) == K_NAN or abs(k) == K_INF then break end
		if abs(k) == K_LAYER and a > 0 and times > 32 then
			a = min(a + times - 32, NanoNum.MAX_LAYER)
			break
		end
	end
	return encodeReg(k, a, b)
end

function NanoNum.iteratedLog10(value: MathValue, timesValue: MathValue): buffer
	local times = exactInteger(timesValue)
	if times == nil or times < 0 or times > NanoNum.MAX_LAYER then return makeSpecial(SPECIAL_NAN) end
	local k, a, b = decodeReg(value)
	if times == 0 then return encodeReg(k, a, b) end
	if abs(k) == K_LAYER and a > 0 and times < a then return NanoNum.fromLayer(a - times, b, k < 0, false) end
	for _ = 1, min(times, 64) do
		k, a, b = regLog10(k, a, b)
		if abs(k) == K_NAN or abs(k) == K_INF then break end
	end
	return encodeReg(k, a, b)
end

function NanoNum.tetrate10(heightValue: MathValue, payload: MathValue?): buffer
	local height = NanoNum.toNumber(heightValue)
	if height ~= height or height == huge or height == -huge then return makeSpecial(SPECIAL_NAN) end
	if payload ~= nil then
		if height < 0 then return makeSpecial(SPECIAL_NAN) end
		return NanoNum.iteratedExp10(payload, floor(height))
	end
	if height < -1 then return makeSpecial(SPECIAL_NAN) end
	if height < 0 then return NanoNum.fromNumber(height + 1) end
	local whole = floor(height)
	local fraction = height - whole
	local seed = 10 ^ fraction
	if whole == 0 then return NanoNum.fromNumber(seed) end
	if whole == 1 then return NanoNum.fromLog10(seed) end
	return NanoNum.fromLayer(whole, seed)
end

function NanoNum.tetrate(baseValue: MathValue, heightValue: MathValue, payload: MathValue?): buffer
	if NanoNum.eq(baseValue, 10) then return NanoNum.tetrate10(heightValue, payload) end
	local height = NanoNum.toNumber(heightValue)
	if height ~= height or height < 0 or height > 256 then return makeSpecial(SPECIAL_NAN) end
	local result = payload == nil and NanoNum.fromNumber(1) or NanoNum.compile(payload)
	local whole = floor(height)
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
	local count = 0
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
	if abs(k) == K_LAYER then return NanoNum.add(abs(a), scalarSlog10(b)) end
	if abs(k) == K_LAYER_LOG then return NanoNum.add(NanoNum.fromLog10(abs(a)), scalarSlog10(b)) end
	if abs(k) == K_LOG then return NanoNum.fromNumber(1 + scalarSlog10(abs(a))) end
	return NanoNum.fromNumber(scalarSlog10(a))
end

function NanoNum.slog(value: MathValue, baseValue: MathValue?): buffer
	local base = baseValue or 10
	if NanoNum.eq(base, 10) then return NanoNum.slog10(value) end
	if NanoNum.lte(base, 1) or NanoNum.lt(value, 0) then return makeSpecial(SPECIAL_NAN) end
	if NanoNum.isZero(value) then return NanoNum.fromNumber(-1) end
	local x = NanoNum.compile(value)
	local count = 0
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

function NanoNum.logBeta(a: MathValue, b: MathValue): buffer
	local sign = NanoNum.betaSign(a, b)
	if sign ~= sign then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.sub(NanoNum.add(NanoNum.logGamma(a), NanoNum.logGamma(b)), NanoNum.logGamma(NanoNum.add(a, b)))
end

function NanoNum.beta(a: MathValue, b: MathValue): buffer
	local sign = NanoNum.betaSign(a, b)
	if sign ~= sign then return makeSpecial(SPECIAL_NAN) end
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

local TYPE_CODE = {number = "N", buffer = "B", string = "S"}

NanoNum.fast = {}

local function fastDecodeN(value: number): (number, number, number)
	if value ~= value then return K_NAN, 0, 0 end
	if value == huge then return K_INF, 0, 0 end
	if value == -huge then return -K_INF, 0, 0 end
	if value == 0 then return 0, 0, 0 end
	return value < 0 and -K_NUM or K_NUM, value < 0 and -value or value, 0
end

local function fastDecodeS(value: string): (number, number, number)
	return decodeRegBuffer(NanoNum.fromString(value))
end

NanoNum.fast.addBB = function(a: buffer, b: buffer): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subBB = function(a: buffer, b: buffer): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulBB = function(a: buffer, b: buffer): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divBB = function(a: buffer, b: buffer): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powBB = function(a: buffer, b: buffer): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.compareBB = function(a: buffer, b: buffer): number
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.addNN = function(a: number, b: number): buffer
	local value = a + b
	if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	local ak, aa, ab = fastDecodeN(a)
	local bk, ba, bb = fastDecodeN(b)
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subNN = function(a: number, b: number): buffer
	local value = a - b
	if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	local ak, aa, ab = fastDecodeN(a)
	local bk, ba, bb = fastDecodeN(b)
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulNN = function(a: number, b: number): buffer
	local value = a * b
	if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0 or b == 0) then return NanoNum.fromNumber(value) end
	local ak, aa, ab = fastDecodeN(a)
	local bk, ba, bb = fastDecodeN(b)
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divNN = function(a: number, b: number): buffer
	if b ~= 0 then
		local value = a / b
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0) then return NanoNum.fromNumber(value) end
	end
	local ak, aa, ab = fastDecodeN(a)
	local bk, ba, bb = fastDecodeN(b)
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powNN = function(a: number, b: number): buffer
	if a >= 0 or b == floor(b) then
		local value = a ^ b
		if value == value and value ~= huge and value ~= -huge and (value ~= 0 or a == 0) then return NanoNum.fromNumber(value) end
	end
	local ak, aa, ab = fastDecodeN(a)
	local bk, ba, bb = fastDecodeN(b)
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.compareNN = function(a: number, b: number): number
	if a ~= a or b ~= b then return NAN end
	if a < b then return -1 elseif a > b then return 1 else return 0 end
end

NanoNum.fast.addBN = function(a: buffer, b: number): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addNB = function(a: number, b: buffer): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addSS = function(a: string, b: string): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addSB = function(a: string, b: buffer): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addBS = function(a: buffer, b: string): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addSN = function(a: string, b: number): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.addNS = function(a: number, b: string): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) + (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regAdd(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subBN = function(a: buffer, b: number): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subNB = function(a: number, b: buffer): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subSS = function(a: string, b: string): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subSB = function(a: string, b: buffer): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subBS = function(a: buffer, b: string): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subSN = function(a: string, b: number): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.subNS = function(a: number, b: string): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local value = (ak < 0 and -aa or aa) - (bk < 0 and -ba or ba)
		if value == value and value ~= huge and value ~= -huge then return NanoNum.fromNumber(value) end
	end
	local k, x, y = regSub(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulBN = function(a: buffer, b: number): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulNB = function(a: number, b: buffer): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulSS = function(a: string, b: string): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulSB = function(a: string, b: buffer): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulBS = function(a: buffer, b: string): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulSN = function(a: string, b: number): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.mulNS = function(a: number, b: string): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if ak == 0 or bk == 0 then return NanoNum.fromNumber(0) end
		local value = aa * ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regMul(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divBN = function(a: buffer, b: number): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divNB = function(a: number, b: buffer): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divSS = function(a: string, b: string): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divSB = function(a: string, b: buffer): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divBS = function(a: buffer, b: string): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divSN = function(a: string, b: number): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.divNS = function(a: number, b: string): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		if bk == 0 then return makeSpecial(ak == 0 and SPECIAL_NAN or ((ak < 0) and SPECIAL_NEG_INF or SPECIAL_POS_INF)) end
		if ak == 0 then return NanoNum.fromNumber(0) end
		local value = aa / ba
		if value ~= huge and value ~= 0 then return NanoNum.fromNumber((ak < 0) ~= (bk < 0) and -value or value) end
	end
	local k, x, y = regDiv(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powBN = function(a: buffer, b: number): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powNB = function(a: number, b: buffer): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powSS = function(a: string, b: string): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powSB = function(a: string, b: buffer): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powBS = function(a: buffer, b: string): buffer
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powSN = function(a: string, b: number): buffer
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.powNS = function(a: number, b: string): buffer
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local base = ak < 0 and -aa or aa
		local exponent = bk < 0 and -ba or ba
		if base >= 0 or exponent == floor(exponent) then
			local value = base ^ exponent
			if value == value and value ~= huge and value ~= -huge and (value ~= 0 or base == 0) then return NanoNum.fromNumber(value) end
		end
	end
	local k, x, y = regPow(ak, aa, ab, bk, ba, bb)
	return encodeReg(k, x, y)
end

NanoNum.fast.compareBN = function(a: buffer, b: number): number
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareNB = function(a: number, b: buffer): number
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareSS = function(a: string, b: string): number
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareSB = function(a: string, b: buffer): number
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb = decodeRegBuffer(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareBS = function(a: buffer, b: string): number
	local ak, aa, ab = decodeRegBuffer(a)
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareSN = function(a: string, b: number): number
	local ak, aa, ab = fastDecodeS(a)
	local bk, ba, bb
	if b ~= b then bk, ba, bb = K_NAN, 0, 0
	elseif b == huge then bk, ba, bb = K_INF, 0, 0
	elseif b == -huge then bk, ba, bb = -K_INF, 0, 0
	elseif b == 0 then bk, ba, bb = 0, 0, 0
	else bk, ba, bb = b < 0 and -K_NUM or K_NUM, b < 0 and -b or b, 0 end
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end

NanoNum.fast.compareNS = function(a: number, b: string): number
	local ak, aa, ab
	if a ~= a then ak, aa, ab = K_NAN, 0, 0
	elseif a == huge then ak, aa, ab = K_INF, 0, 0
	elseif a == -huge then ak, aa, ab = -K_INF, 0, 0
	elseif a == 0 then ak, aa, ab = 0, 0, 0
	else ak, aa, ab = a < 0 and -K_NUM or K_NUM, a < 0 and -a or a, 0 end
	local bk, ba, bb = fastDecodeS(b)
	if (ak == K_NUM or ak == -K_NUM or ak == 0) and (bk == K_NUM or bk == -K_NUM or bk == 0) then
		local x = ak < 0 and -aa or aa
		local y = bk < 0 and -ba or ba
		if x < y then return -1 elseif x > y then return 1 else return 0 end
	end
	return regCompare(ak, aa, ab, bk, ba, bb)
end



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
	local leftCode = leftType == nil and nil or (TYPE_CODE[leftType] or leftType)
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
	if fn == nil or operation == "compare" or not NanoNum.isMathValue(a) or not NanoNum.isMathValue(b) then return false, nil end
	local ok, result = fastPcall(fn, a, b)
	if not ok or typeof(result) ~= "buffer" or not NanoNum.isValid(result) then return false, nil end
	return true, result
end

function NanoNum.tryCompare(a: any, b: any): (boolean, number?)
	if not NanoNum.isMathValue(a) or not NanoNum.isMathValue(b) then return false, nil end
	local ok, result = fastPcall(NanoNum.compare, a, b)
	if not ok or typeof(result) ~= "number" or result ~= result then return false, nil end
	return true, result
end

function NanoNum.mathPerfInfo(): MathPerfInfo
	return {
		Version = NanoNum.MATH_PERF_VERSION,
		PathVersion = NanoNum.MATH_PATH_VERSION,
		DefaultPath = 0,
		Path0 = "NanoNum 1.9 exact-f64 finite kernel; direct native math, layered fallback only",
		Path1 = "layer/log fallback register kernel",
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

local function trimZeros(value: string): string
	local dot = find(value, ".", 1, true)
	if dot == nil then return value end
	local i = #value
	while i > dot and byte(value, i) == 48 do i -= 1 end
	if i == dot then i -= 1 end
	return sub(value, 1, i)
end

local function shortNumber(value: number, decimalPlaces: number): string
	local decimals = clamp(floor(decimalPlaces), 0, 12)
	return trimZeros(format(FIXED_FORMATS[decimals + 1], value))
end

local function scientificText(mantissa: number, exponent: number, decimalPlaces: number): string
	if mantissa >= 10 then
		mantissa /= 10
		exponent += 1
	elseif mantissa > 0 and mantissa < 1 then
		mantissa *= 10
		exponent -= 1
	end
	return shortNumber(mantissa, decimalPlaces) .. "e" .. toString(exponent)
end

local function engineeringText(mantissa: number, exponent: number, decimalPlaces: number): string
	local engineeringExponent = floor(exponent / 3) * 3
	local scaled = mantissa * 10 ^ (exponent - engineeringExponent)
	return shortNumber(scaled, decimalPlaces) .. "e" .. toString(engineeringExponent)
end

local function formatNormalParts(mantissa: number, exponent: number, precision: number, kind: string): string
	if kind == "scientific" then return scientificText(mantissa, exponent, precision) end
	if kind == "engineering" then return engineeringText(mantissa, exponent, precision) end
	if kind == "exponent" then return shortNumber(mantissa, precision) .. "E" .. toString(exponent) end
	if exponent < 3 and exponent >= 0 then return shortNumber(mantissa * 10 ^ exponent, precision) end
	if exponent >= 3 then
		local index = floor(exponent / 3)
		local suffix = suffixForIndex(index, kind)
		if suffix ~= nil then
			local scaled = mantissa * 10 ^ (exponent - index * 3)
			return shortNumber(scaled, precision) .. suffix
		end
	end
	if exponent < 0 then
		local inverseMantissa = 10 / mantissa
		local inverseExponent = -exponent - 1
		return "1/" .. formatNormalParts(inverseMantissa, inverseExponent, precision, kind)
	end
	return scientificText(mantissa, exponent, precision)
end

local ROMAN_VALUES = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1}
local ROMAN_SYMBOLS = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"}

local function romanClassical(value: number): string
	local out = tableCreate(16)
	local count = 0
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
	local depth = 0
	while value > 0 do
		local nextValue = floor(value / 1000)
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
	local magnitude = abs(value)
	if not extended and magnitude > 3999 then return nil end
	local text = extended and romanExtended(magnitude) or romanClassical(magnitude)
	return negative and "-" .. text or text
end

local function formatCore(value: buffer, precision: number, kind: string): string
	local k, a, b = decodeRegBuffer(value)
	if k == 0 then return "0" end
	local absoluteKind = abs(k)
	local negative = k < 0
	if absoluteKind == K_NAN then return "NaN" end
	if absoluteKind == K_INF then return negative and "-inf" or "inf" end
	if absoluteKind == K_NUM then
		local n = negative and -a or a
		if kind == "roman" or kind == "romanextended" then
			local roman = formatRomanInteger(n, kind == "romanextended")
			if roman ~= nil then return roman end
			kind = "standard"
		end
		local magnitude = abs(n)
		if magnitude < 1000 then return toString(n) end
		local exponent = floor(log10(magnitude))
		local mantissa = magnitude / 10 ^ exponent
		local text = formatNormalParts(mantissa, exponent, precision, kind)
		return negative and "-" .. text or text
	end
	if absoluteKind == K_LOG then
		local exponent = a
		local reciprocal = exponent < 0
		exponent = abs(exponent)
		local integerExponent = floor(exponent)
		local mantissa = 10 ^ (exponent - integerExponent)
		local scalarKind = kind
		if scalarKind == "roman" or scalarKind == "romanextended" then scalarKind = "standard" end
		local text = formatNormalParts(mantissa, integerExponent, precision, scalarKind)
		if reciprocal then text = "1/" .. text end
		return negative and "-" .. text or text
	end
	local reciprocal = a < 0
	local layer = abs(a)
	local text
	if absoluteKind == K_LAYER_LOG then
		text = "L(10^" .. shortNumber(layer, precision) .. ") " .. shortNumber(b, precision)
	elseif layer == 2 then
		text = "ee" .. shortNumber(b, precision)
	elseif layer == 3 then
		text = "eee" .. shortNumber(b, precision)
	else
		text = "L" .. shortNumber(layer, precision) .. " " .. shortNumber(b, precision)
	end
	if reciprocal then text = "1/" .. text end
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
	if precision <= 0 then return format("%.0f", value) end
	local text = format("%." .. toString(precision) .. "f", value)
	text = gsub(text, "0+$", "")
	text = gsub(text, "%.$", "")
	return text
end

function NanoNum.formatTime(value: MathValue, style: TimeStyle?, precision: number?, maxParts: number?): string
	local n = NanoNum.toNumber(value)
	if n ~= n then return "NaN" end
	if n == huge then return "inf" end
	if n == -huge then return "-inf" end
	local p = precision == nil and 2 or clamp(floor(precision), 0, 6)
	local mode = lower(style or "compact")
	local partsLimit = maxParts == nil and 4 or max(1, floor(maxParts))
	local negative = n < 0
	local total = abs(n)
	if mode == "seconds" then
		local text = fixedTrim(total, p) .. "s"
		return negative and "-" .. text or text
	end
	local whole = floor(total)
	local fraction = total - whole
	local days = floor(whole / 86400)
	local rem = whole - days * 86400
	local hours = floor(rem / 3600)
	rem -= hours * 3600
	local minutes = floor(rem / 60)
	local seconds = rem - minutes * 60 + fraction
	if mode == "clock" then
		local text = days > 0 and format("%dd %02d:%02d:%05.2f", days, hours, minutes, seconds) or format("%d:%02d:%05.2f", hours, minutes, seconds)
		return negative and "-" .. text or text
	end
	local years = floor(whole / 31557600)
	local weeks = floor((whole - years * 31557600) / 604800)
	local out = {}
	if years > 0 then table.insert(out, toString(years) .. (mode == "long" and " years" or "y")) end
	if weeks > 0 then table.insert(out, toString(weeks) .. (mode == "long" and " weeks" or "w")) end
	if days > 0 then table.insert(out, toString(days) .. (mode == "long" and " days" or "d")) end
	if hours > 0 then table.insert(out, toString(hours) .. (mode == "long" and " hours" or "h")) end
	if minutes > 0 then table.insert(out, toString(minutes) .. (mode == "long" and " minutes" or "m")) end
	if #out < partsLimit then table.insert(out, fixedTrim(seconds, p) .. (mode == "long" and " seconds" or "s")) end
	while #out > partsLimit do table.remove(out) end
	local text = concat(out, mode == "long" and ", " or " ")
	return negative and "-" .. text or text
end

function NanoNum.formatClock(value: MathValue, precision: number?): string return NanoNum.formatTime(value, "clock", precision, 4) end

function NanoNum.parseTime(text: string): buffer
	local clean = trimText(text)
	if clean == "" then return makeSpecial(SPECIAL_NAN) end
	local negative = false
	if sub(clean, 1, 1) == "-" then
		negative = true
		clean = trimText(sub(clean, 2))
	end
	if find(clean, ":", 1, true) then
		local fields = split(clean, ":")
		if #fields < 2 or #fields > 4 then return makeSpecial(SPECIAL_NAN) end
		local numbers = {}
		for i = 1, #fields do
			local n = toNumber(trimText(fields[i]))
			if n == nil or n < 0 then return makeSpecial(SPECIAL_NAN) end
			numbers[i] = n
		end
		local total = 0
		if #fields == 2 then total = numbers[1] * 60 + numbers[2]
		elseif #fields == 3 then total = numbers[1] * 3600 + numbers[2] * 60 + numbers[3]
		else total = numbers[1] * 86400 + numbers[2] * 3600 + numbers[3] * 60 + numbers[4] end
		return NanoNum.fromNumber(negative and -total or total)
	end
	local units = {ms = 0.001, s = 1, sec = 1, secs = 1, m = 60, min = 60, mins = 60, h = 3600, hr = 3600, hrs = 3600, d = 86400, day = 86400, days = 86400, w = 604800, week = 604800, weeks = 604800, y = 31557600, yr = 31557600, yrs = 31557600}
	local total = 0
	local matched = 0
	local residue = gsub(lower(clean), "([%d]*%.?[%d]+)%s*([%a]+)", function(numberText, unitText)
		local n = toNumber(numberText)
		local multiplier = units[unitText]
		if n == nil or multiplier == nil then return "!" end
		matched += 1
		total += n * multiplier
		return ""
	end)
	residue = gsub(residue, "%s+", "")
	if matched == 0 or residue ~= "" then return makeSpecial(SPECIAL_NAN) end
	return NanoNum.fromNumber(negative and -total or total)
end

function NanoNum.formatRate(value: MathValue, unit: string?, decimalPlaces: number?, suffixType: SuffixName?): string
	return NanoNum.format(NanoNum.compile(value), decimalPlaces, suffixType) .. "/" .. (unit or "s")
end

function NanoNum.formatBytes(value: MathValue, precision: number?, binary: boolean?): string
	local n = NanoNum.toNumber(value)
	if n ~= n then return "NaN" end
	if n == huge then return "inf B" end
	if n == -huge then return "-inf B" end
	local p = precision == nil and 2 or clamp(floor(precision), 0, 6)
	local negative = n < 0
	local magnitude = abs(n)
	local base = binary and 1024 or 1000
	local units = binary and {"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"} or {"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
	local index = 1
	while magnitude >= base and index < #units do
		magnitude /= base
		index += 1
	end
	local text = fixedTrim(magnitude, p) .. " " .. units[index]
	return negative and "-" .. text or text
end

function NanoNum.formatOrdinal(value: MathValue): string
	local n = NanoNum.toNumber(value)
	if n ~= n or n == huge or n == -huge or n ~= floor(n) then return NanoNum.format(NanoNum.compile(value)) end
	local magnitude = abs(n)
	local mod100 = magnitude % 100
	local suffix = "th"
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

local function copyBits(target: buffer, targetBit: number, source: buffer, sourceBit: number, count: number)
	if count <= 0 then return end
	if band(targetBit, 7) == 0 and band(sourceBit, 7) == 0 and count >= 8 then
		local bytes = floor(count / 8)
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
	local totalBits = 0
	for i = 1, #values do totalBits += NanoNum.bitLength(values[i]) end
	local packed = bufferCreate(ceilBytes(totalBits))
	local offset = 0
	for i = 1, #values do
		local bits = NanoNum.bitLength(values[i])
		copyBits(packed, offset, values[i], 0, bits)
		offset += bits
	end
	return packed, totalBits
end

function NanoNum.unpackMany(packed: buffer, count: number, totalBits: number?): {buffer}
	local limit = totalBits or bufferLen(packed) * 8
	local result = tableCreate(count)
	local offset = 0
	for i = 1, count do
		local nextBit = recordEndChecked(packed, offset, limit)
		if nextBit == nil then error("NanoNum: invalid packed stream") end
		local bits = nextBit - offset
		local out = bufferCreate(ceilBytes(bits))
		copyBits(out, 0, packed, offset, bits)
		result[i] = out
		offset = nextBit
	end
	return result
end

function NanoNum.tryUnpackMany(packed: buffer, count: number, totalBits: number?): (boolean, {buffer}?)
	if typeof(packed) ~= "buffer" or typeof(count) ~= "number" or count < 0 or count ~= floor(count) then return false, nil end
	local limit = totalBits or bufferLen(packed) * 8
	if limit < 0 or limit > bufferLen(packed) * 8 then return false, nil end
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
NanoNum.LB_SCOPE_VERSION = 1

-- LB internals live in their own function frame so their constants/helpers
-- cannot consume the module chunk's 200-local Luau register budget.
-- A plain `do ... end` block is not sufficient because it shares the same
-- function register frame; this IIFE creates an actual register boundary.
(function()
	local LB_VERSION = 1
	local LB_MAX = 9007199254740991
	local LB_FINITE_MAX = LB_MAX - 1
	local LB_ONE = 4503599627370496
	local LB_POSITIVE_SPAN = min(LB_ONE - 1, LB_FINITE_MAX - LB_ONE)

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

	local LB_ORDINARY_EXACT_LOG10 = log10(NanoNum.LB_ORDINARY_EXACT_MAX)
	local LB_ORDINARY_EXACT_SPAN = floor((NanoNum.LB_ORDINARY_EXACT_MAX - 1) * NanoNum.LB_ORDINARY_SUBSLOTS)

	local LB_ORDINARY_LOG_SPAN = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_ORDINARY_LOG_SHARE))
	local LB_HUGE_LOG_SPAN = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_HUGE_LOG_SHARE))

	local LB_LOW_LAYER_COUNT = NanoNum.LB_LOW_LAYER_MAX - 1
	local LB_LOW_LAYER_SPAN = LB_LOW_LAYER_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS

	local LB_HIGH_LAYER_RESERVED_SPAN = max(1, floor(NanoNum.LB_POSITIVE_SPAN * NanoNum.LB_HIGH_LAYER_SHARE))
	local LB_HIGH_LAYER_BUCKET_COUNT = max(1, floor(LB_HIGH_LAYER_RESERVED_SPAN / NanoNum.LB_LAYER_TOP_BUCKETS))
	local LB_HIGH_LAYER_SPAN = LB_HIGH_LAYER_BUCKET_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS

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
	local LB_LOG_LAYER_SPAN = max(1, NanoNum.LB_POSITIVE_SPAN - LB_LOG_LAYER_START + 1)
	local LB_LOG_LAYER_BUCKET_COUNT = max(1, floor(LB_LOG_LAYER_SPAN / NanoNum.LB_LAYER_TOP_BUCKETS))
	local LB_LOG_LAYER_USED_SPAN = LB_LOG_LAYER_BUCKET_COUNT * NanoNum.LB_LAYER_TOP_BUCKETS
	local LB_LOG_LAYER_END = LB_LOG_LAYER_START + LB_LOG_LAYER_USED_SPAN - 1

	local LB_ORDINARY_LOG_DENOM = 308 - LB_ORDINARY_EXACT_LOG10
	local LB_HUGE_LOG_MIN = 308
	local LB_HUGE_LOG_DENOM = log10(1e308 / LB_HUGE_LOG_MIN)
	local LB_HIGH_LAYER_LOG_MIN = log10(NanoNum.LB_LOW_LAYER_MAX)
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
		return clamp(floor(lbClampUnit(unit) * (slots - 1) + 0.001), 0, slots - 1)
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
		return 10 ^ (LB_DIRECT_TOP_LOG_MIN + unit * LB_DIRECT_TOP_LOG_DENOM)
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
			local logMagnitude
			if exactIntegerRecordBits(data.Value) <= NORMAL_BITS then
				logMagnitude = log10(magnitude)
			else
				local lg = log10(magnitude)
				local exponent = floor(lg)
				local mantissa = 10 ^ (lg - exponent)
				local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
				logMagnitude = exponent + log10(decodeMantissa(mantCode, NORMAL_MANT_MAX))
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
			local magnitude = abs(value)
			local lg = log10(magnitude)
			local exponent = floor(lg)
			local mantissa = 10 ^ (lg - exponent)
			local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
			local legacyLog = exponent + log10(decodeMantissa(mantCode, NORMAL_MANT_MAX))
			return {Kind = "Magnitude", Negative = value < 0, Reciprocal = legacyLog < 0, Layer = 0, LogScale = abs(legacyLog)}
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
			local slot = floor((magnitude - 1) * NanoNum.LB_ORDINARY_SUBSLOTS + 0.001)
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
		if layer <= NanoNum.LB_LOW_LAYER_MAX then
			local layerIndex = max(0, floor(layer + 0.001) - 2)
			local topBucket = lbDirectTopBucket(top)
			return LB_LOW_LAYER_START + layerIndex * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
		end

		local unit = (log10(min(layer, 1e308)) - LB_HIGH_LAYER_LOG_MIN) / LB_HIGH_LAYER_LOG_DENOM
		local layerSlot = lbQuantizeUnit(unit, LB_HIGH_LAYER_BUCKET_COUNT)
		local topBucket = lbDirectTopBucket(top)
		return LB_HIGH_LAYER_START + layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
	end

	local function lbEncodeLogLayer(layerLog10: number, top: number): number
		local capped = min(max(layerLog10, LB_LOG_LAYER_MIN), 1e308)
		local unit = log10(capped / LB_LOG_LAYER_MIN) / LB_LOG_LAYER_DENOM
		local layerSlot = lbQuantizeUnit(unit, LB_LOG_LAYER_BUCKET_COUNT)
		local topBucket = lbLogLayerTopBucket(top)
		return LB_LOG_LAYER_START + layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS + topBucket
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
					error("NanoNum: invalid extended integer bit length")
				end
			end
			local magnitude = readUIntExactAtFast(value, payloadOffset, n)
			if magnitude == 0 then return 0, true end
			local logMagnitude
			local signed = negative and -magnitude or magnitude
			if exactIntegerRecordBits(signed) <= NORMAL_BITS then
				logMagnitude = log10(magnitude)
			else
				local lg = log10(magnitude)
				local exponent = floor(lg)
				local mantissa = 10 ^ (lg - exponent)
				local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
				logMagnitude = exponent + log10(decodeMantissa(mantCode, NORMAL_MANT_MAX))
			end
			local delta = lbEncodeOrdinaryLog(logMagnitude)
			return lbFinalizeFiniteCode(delta, negative, false), true
		end

		if band(raw, 15) == 7 then
			local negative = bufferReadBits(value, 4, 1) == 1
			local expCode = bufferReadBits(value, 5, NORMAL_EXP_BITS)
			if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
				error("NanoNum: invalid normal exponent code")
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
		if special == SPECIAL_RESERVED then
			local exact = bufferReadF64(value, 1)
			if exact ~= exact or exact == huge or exact == -huge then return 0, false end
			if exact == 0 then return 0, true end
			local negative = exact < 0
			local magnitude = negative and -exact or exact
			local lg = log10(magnitude)
			local exponent = floor(lg)
			local mantissa = 10 ^ (lg - exponent)
			local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
			local legacyLog = exponent + log10(decodeMantissa(mantCode, NORMAL_MANT_MAX))
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
		return delta <= LB_LOG_LAYER_END
	end

	NanoNum.isLBCode = isLBCodeFast

	function NanoNum.tryLBEncode(value: any): (boolean, number)
		-- Direct: leaderboard hot paths overwhelmingly receive NanoNum buffers.
		if typeof(value) == "buffer" then
			local code, valid = lbCodeFromBufferFast(value)
			return valid, code
		end
		local code, valid = lbCodeFromBufferFast(lbCoerce(value))
		return valid, code
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
			local layerIndex = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
			local topBucket = offset - layerIndex * NanoNum.LB_LAYER_TOP_BUCKETS
			return 1, layerIndex + 2, lbDirectTopFromBucket(topBucket)
		end

		if delta <= LB_HIGH_LAYER_END then
			local offset = delta - LB_HIGH_LAYER_START
			local layerSlot = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
			local topBucket = offset - layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS
			local unit = lbUnitFromSlot(layerSlot, LB_HIGH_LAYER_BUCKET_COUNT)
			local layerLog10 = LB_HIGH_LAYER_LOG_MIN + unit * LB_HIGH_LAYER_LOG_DENOM
			local layer = 10 ^ layerLog10
			if layer > 1e308 then
				layer = 1e308
			end
			return 1, layer, lbDirectTopFromBucket(topBucket)
		end

		local offset = clamp(delta - LB_LOG_LAYER_START, 0, LB_LOG_LAYER_USED_SPAN - 1)
		local layerSlot = floor(offset / NanoNum.LB_LAYER_TOP_BUCKETS)
		local topBucket = offset - layerSlot * NanoNum.LB_LAYER_TOP_BUCKETS
		local unit = lbUnitFromSlot(layerSlot, LB_LOG_LAYER_BUCKET_COUNT)
		local layerLog10 = LB_LOG_LAYER_MIN * (10 ^ (unit * LB_LOG_LAYER_DENOM))
		if layerLog10 > 1e308 then
			layerLog10 = 1e308
		end
		return 2, layerLog10, lbLogLayerTopFromBucket(topBucket)
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

		if decodedKind == 2 then
			return NanoNum.fromLayerLog10(decodedA, decodedB, negative, reciprocal)
		end

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
		end
		return "log-layer"
	end

	function NanoNum.lbinfo(value: MathValue): LBInfo
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

	function NanoNum.lbquantize(value: MathValue): buffer
		local code
		if typeof(value) == "buffer" then
			code = lbCodeFromBufferFast(value)
		else
			code = lbCodeFromBufferFast(lbCoerce(value))
		end
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
		return ca == cb
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

end)()

local TYPECHECKED_NANONUM = NanoNum
return TYPECHECKED_NANONUM
