--!native
--!optimize 2

local NanoFormat = {}

NanoFormat.VERSION = "0.4.8"
NanoFormat.MAX_LAYER = 1e308
NanoFormat.MAX_LAYER_LOG10 = 1e308
NanoFormat.NORMAL_SIGNIFICAND_BITS = 16
NanoFormat.SCALAR_SIGNIFICAND_BITS = 14
NanoFormat.PARSER_VERSION = 3
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

-- V0.4.8 keeps a weak side-cache of useful bit lengths for buffers produced by
-- NanoFormat itself. This does not change the wire format and external/copied
-- buffers still fall back to structural scanning.
local BIT_LENGTH_CACHE = setmetatable({}, {__mode = "k"})

local PREFIX_TINY = 0        -- 0
local PREFIX_NEG_SMALL = 1   -- 10 (LSB-first through writePrefix)
local PREFIX_INTEGER = 2     -- 110
local PREFIX_NORMAL = 3      -- 1110
local PREFIX_LOG = 4         -- 11110
local PREFIX_LAYER = 5       -- 111110
local PREFIX_SPECIAL = 6     -- 111111

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

function normalizeSuffixType(suffixType: string?): string
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

function alphabeticSuffix(index: number): string?
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

function alphabeticSuffixIndex(suffix: string): number?
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

function suffixForIndex(index: number, suffixType: string): string?
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


function bitsRequired(value: number): number
	if value <= 0 then
		return 0
	end
	return floor(math.log(value) / LN2) + 1
end

function isSafeInteger(value: number): boolean
	return value >= 0
		and value <= 9007199254740991
		and value == floor(value)
end

function ceilBytes(bits: number): number
	return max(1, floor((bits + 7) / 8))
end

-- Integer lengths 1..31 keep the original 5-bit header. Code 0 is an
-- extension escape for lengths 32..53, so small integers do not get larger.
function integerLengthFieldBits(bitLength: number): number
	return if bitLength <= 31 then INTEGER_LEN_BITS else INTEGER_LEN_BITS + 5
end


function quantizeMantissa(mantissa: number, maxCode: number): number
	local t = (mantissa - 1) / 9
	return clamp(floor(t * maxCode + 0.5), 0, maxCode)
end

function decodeMantissa(code: number, maxCode: number): number
	return 1 + (code / maxCode) * 9
end

function scalarExactBits(value: number): number
	if not isSafeInteger(value) then
		return huge
	end
	local n = bitsRequired(value)
	if n > 53 then
		return huge
	end
	return 1 + EXACT_LEN_BITS + n
end

function scalarBits(value: number): number
	local exact = scalarExactBits(value)
	if exact <= SCALAR_APPROX_BITS then
		return exact
	end
	return SCALAR_APPROX_BITS
end


function exactIntegerRecordBits(value: number): number
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

function isPower10Like(value: number): (boolean, number)
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

function logRecordBits(exponentMagnitude: number): number
	return 5 + 1 + 1 + scalarBits(exponentMagnitude)
end

function writeUIntExactAtFast(data: buffer, bitOffset: number, value: number, count: number)
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

function writeScalarAtFast(data: buffer, bitOffset: number, value: number)
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

function makeSpecial(code: number): buffer
	local data = bufferCreate(1)
	-- Prefix 111111 occupies bits 0..5; special code occupies bits 6..7.
	bufferWriteU8(data, 0, 63 + code * 64)
	return data
end

function makeTiny(value: number): buffer
	local data = bufferCreate(1)
	-- Tiny prefix is bit 0 = 0; payload starts at bit 1.
	bufferWriteU8(data, 0, value * 2)
	return data
end

function makeNegSmall(magnitude: number): buffer
	local data = bufferCreate(1)
	-- Negative-small prefix is bits 1,0 followed by the 6-bit payload.
	bufferWriteU8(data, 0, 1 + (magnitude - 1) * 4)
	return data
end

function makeInteger(value: number): buffer
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

function makeNormal(value: number): buffer
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

function makeLog(exponent: number, negative: boolean): buffer
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

function layerFieldBits(layer: number, layerIsLog: boolean): number
	if not layerIsLog and layer == floor(layer) and layer >= 2 and layer <= 33 then
		return 1 + 5
	end
	-- Escape bit + representation bit (direct/log10) + adaptive scalar.
	return 2 + scalarBits(layer)
end


function makeLayer(layer: number, top: number, negative: boolean, reciprocal: boolean, layerIsLog: boolean?): buffer
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

function normalizeLayerInput(layer: number, top: number, layerIsLog: boolean): (number, number, boolean)
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

function isWhitespaceByte(c: number?): boolean
	return c == 32 or c == 9 or c == 10 or c == 11 or c == 12 or c == 13
end

function asciiLowerByte(c: number): number
	if c >= 65 and c <= 90 then
		return c + 32
	end
	return c
end

function rangeEqualsCI(value: string, first: number, last: number, literal: string): boolean
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

function trimRange(value: string): (number, number)
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
function parseDecimalRange(
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
function parseScientificExponentRange(
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
function parseFiniteNumericRange(
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

function alphabeticSuffixIndexRange(value: string, first: number, last: number): number?
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

function shortSuffixKeyString(suffix: string): number?
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

function shortSuffixKeyRange(value: string, first: number, last: number): number?
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

function suffixIndexRange(
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

function fromSignedLogSmart(logMagnitude: number, negative: boolean): buffer
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

function scientificExponentNeedsSymbolic(
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

function classifyDirectStringFast(value: string): (boolean, number)
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

function NanoFormat.fromString(value: string, suffixType: string?): buffer
	-- V0.4.8 keeps the dispatch-before-tonumber parser. Symbolic forms, suffixes, and
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

function scalarEndFast(data: buffer, bitOffset: number, limit: number): number
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
function recordEndFast(data: buffer, bitOffset: number, limit: number?): number
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
function scalarEndChecked(data: buffer, bitOffset: number, limit: number): number?
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

function recordEndChecked(data: buffer, bitOffset: number, limit: number?): number?
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

function readUIntExactAtFast(data: buffer, bitOffset: number, count: number): number
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

function readScalarAtFast(data: buffer, bitOffset: number): (number, number)
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

function readLayerFieldAtFast(data: buffer, bitOffset: number): (number, boolean, number)
	if bufferReadBits(data, bitOffset, 1) == 0 then
		return bufferReadBits(data, bitOffset + 1, 5) + 2, false, bitOffset + 6
	end

	local layerIsLog = bufferReadBits(data, bitOffset + 1, 1) == 1
	local layer, nextBit = readScalarAtFast(data, bitOffset + 2)
	return layer, layerIsLog, nextBit
end

function decodeAt(data: buffer, bitOffset: number)
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

function NanoFormat.tryDecodeAt(data: buffer, bitOffset: number?): (boolean, any, number?)
	if typeof(data) ~= "buffer" then
		return false, nil, nil
	end
	local offset = bitOffset or 0
	if offset < 0 or offset >= bufferLen(data) * 8 then
		return false, nil, nil
	end
	local ok, decoded, nextBit = fastPcall(decodeAt, data, offset)
	if not ok then
		return false, nil, nil
	end
	return true, decoded, nextBit
end

function zeroPadding(value: buffer, startBit: number): boolean
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

function NanoFormat.components(value: buffer)
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

function trimZeros(value: string): string
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

function shortNumber(value: number, precision: number): string
	if value == 0 then
		return "0"
	end
	local exponent = floor(log10(abs(value)))
	local decimals = clamp(precision - exponent - 1, 0, 12)
	return trimZeros(format(FIXED_FORMATS[decimals + 1], value))
end

function scientificText(mantissa: number, exponent: number, precision: number): string
	if mantissa >= 10 then
		mantissa /= 10
		exponent += 1
	elseif mantissa > 0 and mantissa < 1 then
		mantissa *= 10
		exponent -= 1
	end
	return shortNumber(mantissa, precision) .. "e" .. toString(exponent)
end

function roundsTo1000(value: number, precision: number): boolean
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

function engineeringText(mantissa: number, exponent: number, precision: number): string
	local engineeringExponent = floor(exponent / 3) * 3
	local scaled = mantissa * (10 ^ (exponent - engineeringExponent))
	if roundsTo1000(scaled, precision) then
		scaled /= 1000
		engineeringExponent += 3
	end
	return shortNumber(scaled, precision) .. "e" .. toString(engineeringExponent)
end

function commaIntegerText(value: number): string
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

function exponentCompactText(mantissa: number, exponent: number, precision: number): string
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
	return (rendered == "1" and "" or rendered) .. "E" .. commaIntegerText(exponent)
end

function suffixText(
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

function formatPower10(exponent: number, precision: number, suffixType: string): string
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

function formatNormalParts(
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

function formatLargeScalar(value: number, precision: number): string
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

	function classicalPositive(value: number): string
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

	function extendedPositive(value: number): string
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

function formatIntegerValue(integer: number, precision: number, suffixKind: string): string
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

function formatCoreFast(value: buffer, precision: number, suffixKind: string): string
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

		if layerIsLog then
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
function NanoFormat.format(value: buffer, precision: number?, suffixType: string?): string
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


function copyBits(target: buffer, targetBit: number, source: buffer, sourceBit: number, count: number)
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

function usefulBitLengthFast(value: buffer): number
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
function unpackManyCore(packed: buffer, count: number, limit: number): {buffer}
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

function tryUnpackManyCore(packed: buffer, count: number, limit: number): {buffer}?
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
	if typeof(packed) ~= "buffer" or count < 0 or count ~= floor(count) then
		return false, nil
	end
	local physicalBits = bufferLen(packed) * 8
	local limit = totalBits or physicalBits
	if limit < 0 or limit > physicalBits then
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
function NanoFormat.inspect(value: buffer)
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

function lbClampUnit(value: number): number
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

function lbQuantizeUnit(unit: number, slots: number): number
	if slots <= 1 then
		return 0
	end
	return clamp(floor(lbClampUnit(unit) * (slots - 1) + 0.5), 0, slots - 1)
end

function lbUnitFromSlot(slot: number, slots: number): number
	if slots <= 1 then
		return 0
	end
	return clamp(slot, 0, slots - 1) / (slots - 1)
end

function lbDirectTopBucket(top: number): number
	if top <= LB_DIRECT_TOP_MIN then
		return 0
	end
	local unit = (log10(min(top, 1e308)) - LB_DIRECT_TOP_LOG_MIN) / LB_DIRECT_TOP_LOG_DENOM
	return lbQuantizeUnit(unit, NanoFormat.LB_LAYER_TOP_BUCKETS)
end

function lbDirectTopFromBucket(bucket: number): number
	local unit = lbUnitFromSlot(bucket, NanoFormat.LB_LAYER_TOP_BUCKETS)
	if unit >= 1 then
		return 1e308
	end
	return 10 ^ (LB_DIRECT_TOP_LOG_MIN + unit * LB_DIRECT_TOP_LOG_DENOM)
end

function lbLogLayerTopBucket(top: number): number
	if top <= 0 then
		return 0
	end
	local unit = log10(1 + min(top, 1e308)) / LB_TOP_LOG_DENOM
	return lbQuantizeUnit(unit, NanoFormat.LB_LAYER_TOP_BUCKETS)
end

function lbLogLayerTopFromBucket(bucket: number): number
	local unit = lbUnitFromSlot(bucket, NanoFormat.LB_LAYER_TOP_BUCKETS)
	if unit >= 1 then
		return 1e308
	end
	return (10 ^ (unit * LB_TOP_LOG_DENOM)) - 1
end

function lbCoerce(value: any): buffer
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

function lbDescriptor(value: buffer)
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

function lbEncodeOrdinaryLog(logScale: number): number
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

function lbEncodeLayer(layer: number, top: number): number
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

function lbEncodeLogLayer(layerLog10: number, top: number): number
	local capped = min(max(layerLog10, LB_LOG_LAYER_MIN), 1e308)
	local unit = log10(capped / LB_LOG_LAYER_MIN) / LB_LOG_LAYER_DENOM
	local layerSlot = lbQuantizeUnit(unit, LB_LOG_LAYER_BUCKET_COUNT)
	local topBucket = lbLogLayerTopBucket(top)
	return LB_LOG_LAYER_START
		+ layerSlot * NanoFormat.LB_LAYER_TOP_BUCKETS
		+ topBucket
end

function lbPositiveDeltaDescriptor(descriptor): (number?, boolean?, boolean?)
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

function lbFinalizeFiniteCode(delta: number, negative: boolean, reciprocal: boolean): number
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

function lbCodeFromDescriptor(descriptor): number
	local delta, negative, reciprocal = lbPositiveDeltaDescriptor(descriptor)

	if delta == nil then
		return 0
	end
	if descriptor.Kind == "Zero" then
		return 0
	end
	return lbFinalizeFiniteCode(delta, negative == true, reciprocal == true)
end



function lbCodeFromBufferFast(value: buffer): (number, boolean)
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

function isLBCodeFast(encoded: number): boolean
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

function NanoFormat.lbencode(value: any): number
	if typeof(value) == "buffer" then
		local code = lbCodeFromBufferFast(value)
		return code
	end
	local code = lbCodeFromBufferFast(lbCoerce(value))
	return code
end

NanoFormat.lbencodeV1 = NanoFormat.lbencode

function lbDecodePositiveDelta(delta: number): (number, number, number)
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

function NanoFormat.lbpack(value: any): {[string]: number}
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

function NanoFormat.lbunpack(data: any): buffer
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

function lbBandFromDelta(delta: number): string
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

function NanoFormat.lbinfo(value: any)
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

function NanoFormat.lbquantize(value: any): buffer
	local code
	if typeof(value) == "buffer" then
		code = lbCodeFromBufferFast(value)
	else
		code = lbCodeFromBufferFast(lbCoerce(value))
	end
	return NanoFormat.lbdecode(code)
end

function NanoFormat.lbSameBucket(a: any, b: any): boolean
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

function NanoFormat.lbRoundTripStable(value: any): boolean
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

function NanoFormat.lbCompare(a: any, b: any): number
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

NanoFormat.LBEncode = NanoFormat.lbencode
NanoFormat.LBDecode = NanoFormat.lbdecode
NanoFormat.LBEncodeV1 = NanoFormat.lbencode
NanoFormat.LBDecodeV1 = NanoFormat.lbdecode
NanoFormat.LBCompare = NanoFormat.lbCompare
NanoFormat.LBRoundTripStable = NanoFormat.lbRoundTripStable

return NanoFormat
