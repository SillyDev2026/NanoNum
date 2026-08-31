--!native
--!optimize 2

local NanoFormat = {}

NanoFormat.VERSION = "0.3.3"
NanoFormat.MAX_LAYER = 1e308
NanoFormat.MAX_LAYER_LOG10 = 1e308
NanoFormat.NORMAL_SIGNIFICAND_BITS = 16
NanoFormat.SCALAR_SIGNIFICAND_BITS = 14
NanoFormat.PARSER_VERSION = 9
NanoFormat.PERF_VERSION = 7
NanoFormat.PATH_VERSION = 4
NanoFormat.DEFAULT_PATH = 0
NanoFormat.NOTATION_VERSION = 2

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
local NORMAL_BITS = 4 + 1 + NORMAL_EXP_BITS + NORMAL_MANT_BITS

local SCALAR_EXP_BITS = 10
local SCALAR_EXP_BIAS = 324
local SCALAR_EXP_MIN = -324
local SCALAR_EXP_MAX = 308
local SCALAR_MANT_BITS = 14
local SCALAR_MANT_MAX = 16383
local SCALAR_APPROX_BITS = 1 + SCALAR_EXP_BITS + SCALAR_MANT_BITS

local EXACT_LEN_BITS = 6
local INTEGER_LEN_BITS = 5
local MAX_INTEGER_MODE_BITS = 53
local SCALAR_EXACT_VALUE_MAX = 262143

local SAFE_INTEGER_POWER10_EXP = {
	[1e3] = 3,
	[1e4] = 4,
	[1e5] = 5,
	[1e6] = 6,
	[1e7] = 7,
	[1e8] = 8,
	[1e9] = 9,
	[1e10] = 10,
	[1e11] = 11,
	[1e12] = 12,
	[1e13] = 13,
	[1e14] = 14,
	[1e15] = 15,
}

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

NanoFormat.SUFFIX_VERSION = 5
NanoFormat.STANDARD_SUFFIX_MAX_INDEX = 999
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
}

local ILLION_FIRST = {"", "U", "D", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No"}
local ILLION_SECOND = {"", "De", "Vt", "Tg", "qg", "Qg", "sg", "Sg", "Og", "Ng"}
local ILLION_THIRD = {"", "Ce", "Du", "Tr", "Qa", "Qi", "Se", "Si", "Ot", "Ni"}

local STANDARD_SUFFIXES = table.create(1000)
STANDARD_SUFFIXES[1] = "k"
STANDARD_SUFFIXES[2] = "M"
STANDARD_SUFFIXES[3] = "B"

for index = 4, NanoFormat.STANDARD_SUFFIX_MAX_INDEX do
	local i = index - 1
	STANDARD_SUFFIXES[index] =
		ILLION_FIRST[i % 10 + 1]
		.. ILLION_SECOND[(i // 10) % 10 + 1]
		.. ILLION_THIRD[(i // 100) % 10 + 1]
end

local METRIC_SUFFIXES = {
	"k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q",
}

local STANDARD_SUFFIX_TO_INDEX = {}
for i, suffix in STANDARD_SUFFIXES do
	STANDARD_SUFFIX_TO_INDEX[suffix] = i
end

STANDARD_SUFFIX_TO_INDEX["K"] = 1
STANDARD_SUFFIX_TO_INDEX["m"] = 2
STANDARD_SUFFIX_TO_INDEX["b"] = 3

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
}

local function normalizeSuffixType(suffixType: string?): string
	if suffixType == nil then
		return NanoFormat.DEFAULT_SUFFIX_TYPE
	end

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

	if suffixType == "standard" or suffixType == "extended" then
		return STANDARD_SUFFIXES[index]
	elseif suffixType == "hybrid" then
		if index <= NanoFormat.STANDARD_SUFFIX_MAX_INDEX then
			return STANDARD_SUFFIXES[index]
		end
		return alphabeticSuffix(index - NanoFormat.STANDARD_SUFFIX_MAX_INDEX)
	elseif suffixType == "alphabetic" then
		return alphabeticSuffix(index)
	elseif suffixType == "metric" then
		return METRIC_SUFFIXES[index]
	end

	return nil
end

function NanoFormat.isSuffixType(suffixType: string): boolean

	if NanoFormat.SUFFIX_TYPES[suffixType] == true then
		return true
	end

	if SUFFIX_TYPE_ALIASES[suffixType] ~= nil then
		return true
	end
	local kind = lower(suffixType)
	kind = SUFFIX_TYPE_ALIASES[kind] or kind
	return NanoFormat.SUFFIX_TYPES[kind] == true
end

function NanoFormat.setDefaultSuffixType(suffixType: string): boolean

	if NanoFormat.SUFFIX_TYPES[suffixType] == true then
		NanoFormat.DEFAULT_SUFFIX_TYPE = suffixType
		return true
	end

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
	local kind = suffixType
	if kind == nil then
		kind = NanoFormat.DEFAULT_SUFFIX_TYPE
	end

	if kind == "standard" or kind == "extended" then
		return STANDARD_SUFFIXES[i]
	elseif kind == "metric" then
		return METRIC_SUFFIXES[i]
	elseif kind == "alphabetic" then
		return alphabeticSuffix(i)
	elseif kind == "hybrid" then
		if i <= NanoFormat.STANDARD_SUFFIX_MAX_INDEX then
			return STANDARD_SUFFIXES[i]
		end
		return alphabeticSuffix(i - NanoFormat.STANDARD_SUFFIX_MAX_INDEX)
	elseif kind == "exponent" or kind == "scientific" or kind == "engineering" then
		return nil
	end

	return suffixForIndex(i, normalizeSuffixType(kind))
end
function NanoFormat.suffixIndex(suffix: string, suffixType: string?): number?
	local kind = suffixType
	if kind == nil then
		kind = NanoFormat.DEFAULT_SUFFIX_TYPE
	end

	if kind == "standard" or kind == "extended" then
		return STANDARD_SUFFIX_TO_INDEX[suffix]
	elseif kind == "metric" then
		return METRIC_SUFFIX_TO_INDEX[suffix]
	elseif kind == "alphabetic" then
		return alphabeticSuffixIndex(lower(suffix))
	elseif kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndex(lower(suffix))
		return alpha and (alpha + NanoFormat.STANDARD_SUFFIX_MAX_INDEX) or nil
	elseif kind == "exponent" or kind == "scientific" or kind == "engineering" then
		return nil
	end

	kind = normalizeSuffixType(kind)
	if kind == "standard" or kind == "extended" then
		return STANDARD_SUFFIX_TO_INDEX[suffix]
	elseif kind == "metric" then
		return METRIC_SUFFIX_TO_INDEX[suffix]
	elseif kind == "alphabetic" then
		return alphabeticSuffixIndex(lower(suffix))
	elseif kind == "hybrid" then
		local standard = STANDARD_SUFFIX_TO_INDEX[suffix]
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndex(lower(suffix))
		return alpha and (alpha + NanoFormat.STANDARD_SUFFIX_MAX_INDEX) or nil
	end
	return nil
end

local function bitsRequired(value: number): number
	if value <= 0 then
		return 0
	end
	return floor(math.log(value) / LN2) + 1
end

local function ceilBytes(bits: number): number
	return max(1, floor((bits + 7) / 8))
end

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

local function scalarPlan(value: number): (number, number)

	if value >= 0 and value <= SCALAR_EXACT_VALUE_MAX and value == floor(value) then
		local n = bitsRequired(value)
		return 1 + EXACT_LEN_BITS + n, n
	end
	return SCALAR_APPROX_BITS, -1
end

local function logRecordBits(exponentMagnitude: number): number
	local scalarBitCount = scalarPlan(exponentMagnitude)
	return 5 + 1 + 1 + scalarBitCount
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

local function writeScalarAtFast(data: buffer, bitOffset: number, value: number, plannedExactBits: number?)
	value = abs(value)
	local n = plannedExactBits
	if n == nil then
		local _, plannedN = scalarPlan(value)
		n = plannedN
	end

	if n >= 0 then

		bufferWriteBits(data, bitOffset, 1 + EXACT_LEN_BITS, n * 2)
		writeUIntExactAtFast(data, bitOffset + 1 + EXACT_LEN_BITS, value, n)
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

local function makeSpecial(code: number): buffer
	local data = bufferCreate(1)

	bufferWriteU8(data, 0, 63 + code * 64)
	return data
end

local function makeTiny(value: number): buffer
	local data = bufferCreate(1)

	bufferWriteU8(data, 0, value * 2)
	return data
end

local function makeNegSmall(magnitude: number): buffer
	local data = bufferCreate(1)

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
	local scalarBitCount, scalarExactN = scalarPlan(magnitude)
	local bits = 7 + scalarBitCount
	local data = bufferCreate(ceilBytes(bits))

	bufferWriteBits(
		data,
		0,
		7,
		15 + (negative and 32 or 0) + (reciprocal and 64 or 0)
	)
	writeScalarAtFast(data, 7, magnitude, scalarExactN)

	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

local function makeLayer(layer: number, top: number, negative: boolean, reciprocal: boolean, layerIsLog: boolean?): buffer

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

	local directLayer = not logLayer and layer == floor(layer) and layer >= 2 and layer <= 33
	local layerScalarBits = 0
	local layerExactN = -1
	local layerBits = 6
	if not directLayer then
		layerScalarBits, layerExactN = scalarPlan(layer)
		layerBits = 2 + layerScalarBits
	end
	local topScalarBits, topExactN = scalarPlan(top)
	local bits = 8 + layerBits + topScalarBits
	local data = bufferCreate(ceilBytes(bits))

	bufferWriteU8(data, 0, 31 + (negative and 64 or 0) + (reciprocal and 128 or 0))
	local bitOffset = 8

	if directLayer then

		bufferWriteBits(data, bitOffset, 6, (layer - 2) * 2)
		bitOffset += 6
	else

		bufferWriteBits(data, bitOffset, 2, 1 + (logLayer and 2 or 0))
		bitOffset += 2
		writeScalarAtFast(data, bitOffset, layer, layerExactN)
		bitOffset += layerScalarBits
	end

	writeScalarAtFast(data, bitOffset, top, topExactN)
	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

local DIRECT_LAYER_LOG10_MAX = 308

local function normalizeLayerInput(layer: number, top: number, layerIsLog: boolean): (number, number, boolean)

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

function NanoFormat.fromNumber(value: number): buffer
	if value == 0 then
		local data = bufferCreate(1)
		bufferWriteU8(data, 0, 0)
		return data
	end

	if value > 0 then
		if value <= 127 and value == floor(value) then
			local data = bufferCreate(1)
			bufferWriteU8(data, 0, value * 2)
			return data
		end
	elseif value < 0 then
		if value >= -64 and value == floor(value) then
			local data = bufferCreate(1)
			bufferWriteU8(data, 0, 1 + (-value - 1) * 4)
			return data
		end
	else
		return makeSpecial(SPECIAL_NAN)
	end

	if value == huge then
		return makeSpecial(SPECIAL_POS_INF)
	elseif value == -huge then
		return makeSpecial(SPECIAL_NEG_INF)
	end

	local negative = value < 0
	local magnitude = negative and -value or value

	if magnitude <= 9007199254740991 then
		local integerMagnitude = floor(magnitude)
		if magnitude == integerMagnitude then
			local powerExponent = SAFE_INTEGER_POWER10_EXP[magnitude]
			if magnitude <= 2097151 then
				local integerN = 32 - bit32.countlz(magnitude)
				local integerBits = 9 + integerN
				if powerExponent ~= nil then
					local powerBits = logRecordBits(powerExponent)
					if powerBits < integerBits then
						return makeLog(powerExponent, negative)
					end
				end
				local data = bufferCreate(ceilBytes(integerBits))
				local header = 3 + (negative and 8 or 0) + integerN * 16
				bufferWriteBits(data, 0, integerBits, header + magnitude * 512)
				if band(integerBits, 7) ~= 0 then
					BIT_LENGTH_CACHE[data] = integerBits
				end
				return data
			end
			if powerExponent ~= nil then
				local powerBits = logRecordBits(powerExponent)
				if powerBits < NORMAL_BITS then
					return makeLog(powerExponent, negative)
				end
			end
		end
	end

	local lg = log10(magnitude)
	local rounded = floor(lg + 0.5)
	if rounded ~= 0 and abs(lg - rounded) <= EPS_POWER10 then
		local powerBits = logRecordBits(abs(rounded))
		if powerBits < NORMAL_BITS then
			return makeLog(rounded, negative)
		end
	end

	local exponentNormal = floor(lg)
	local mantissa = 10 ^ (lg - exponentNormal)
	local t = (mantissa - 1) / 9
	local mantCode = floor(t * NORMAL_MANT_MAX + 0.5)
	if mantCode < 0 then
		mantCode = 0
	elseif mantCode > NORMAL_MANT_MAX then
		mantCode = NORMAL_MANT_MAX
	end
	local expCode = exponentNormal + NORMAL_EXP_BIAS
	local data = bufferCreate(4)
	local packed = 7 + (negative and 16 or 0) + expCode * 32 + mantCode * 32768
	bufferWriteBits(data, 0, NORMAL_BITS, packed)
	BIT_LENGTH_CACHE[data] = NORMAL_BITS
	return data
end

function NanoFormat.fromLog10(exponent: number, negative: boolean?): buffer

	if exponent ~= exponent then
		return makeSpecial(SPECIAL_NAN)
	elseif exponent == huge then
		return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
	elseif exponent == -huge then
		exponent = -1e308
	elseif exponent == 0 then

		return NanoFormat.fromNumber(negative and -1 or 1)
	end

	local reciprocal = exponent < 0
	local magnitude = abs(exponent)
	local scalarBitCount, scalarExactN = scalarPlan(magnitude)
	local bits = 7 + scalarBitCount
	local data = bufferCreate(ceilBytes(bits))
	bufferWriteBits(
		data,
		0,
		7,
		15 + (negative == true and 32 or 0) + (reciprocal and 64 or 0)
	)
	writeScalarAtFast(data, 7, magnitude, scalarExactN)
	if band(bits, 7) ~= 0 then
		BIT_LENGTH_CACHE[data] = bits
	end
	return data
end

function NanoFormat.fromLayer(layer: number, top: number, negative: boolean?, reciprocal: boolean?): buffer

	if layer ~= layer or top ~= top then
		return makeSpecial(SPECIAL_NAN)
	elseif layer == huge then
		return NanoFormat.fromLayerLog10(308, top, negative, reciprocal)
	end

	if layer >= 2 and layer <= NanoFormat.MAX_LAYER and layer == floor(layer) then
		if top > 308 then
			return makeLayer(layer, top, negative == true, reciprocal == true, false)
		elseif top > 2.4885507165004443 then
			local reducedTop = 10 ^ top
			local reducedLayer = layer - 1
			if reducedLayer < 2 then
				local exp = reciprocal and -abs(reducedTop) or reducedTop
				return NanoFormat.fromLog10(exp, negative)
			end
			return makeLayer(reducedLayer, reducedTop, negative == true, reciprocal == true, false)
		end
	end

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

	if layerLog10 > DIRECT_LAYER_LOG10_MAX then
		return makeLayer(
			clamp(layerLog10, 0, NanoFormat.MAX_LAYER_LOG10),
			top,
			negative == true,
			reciprocal == true,
			true
		)
	end

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

local function parseFiniteNumericRange(
	value: string,
	first: number,
	last: number
): (boolean, number?, number?)
	if first > last then
		return false, nil, nil
	end

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

	local key = shortSuffixKeyRange(value, first, last)
	if suffixType == "standard" or suffixType == "extended" then
		return key and FAST_STANDARD_SUFFIX_TO_INDEX[key] or nil
	elseif suffixType == "metric" then
		return key and FAST_METRIC_SUFFIX_TO_INDEX[key] or nil
	elseif suffixType == "hybrid" then
		local standard = key and FAST_STANDARD_SUFFIX_TO_INDEX[key] or nil
		if standard ~= nil then
			return standard
		end
		local alpha = alphabeticSuffixIndexRange(value, first, last)
		return alpha and (alpha + NanoFormat.STANDARD_SUFFIX_MAX_INDEX) or nil
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
		if first > last then return nil end
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
			if sawDot or not sawDigit or digitsInGroup == 0 then return nil end
			if groupCount == 0 then
				if digitsInGroup > 3 then return nil end
			elseif digitsInGroup ~= 3 then
				return nil
			end
			sawComma = true
			groupCount += 1
			digitsInGroup = 0
		elseif c == 46 then
			if sawDot or digitsInGroup == 0 then return nil end
			if sawComma and digitsInGroup ~= 3 then return nil end
			sawDot = true
		else
			return nil
		end
	end

	if not sawDigit then return nil end
	if sawComma and not sawDot and digitsInGroup ~= 3 then return nil end

	result *= sign
	if result == huge or result == -huge then return nil end
	return result
end

local function parseCompactExponentRange(value: string, first: number, last: number): number?
	if first > last then return nil end

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

	local scalarLast = suffixStart - 1
	if scalarLast < first then return nil end

	local scalar = parseGroupedDecimalRange(value, first, scalarLast)
	if scalar == nil then return nil end

	if suffixStart <= last then
		local index = suffixIndexRange(value, suffixStart, last, "standard")
		if index == nil then return nil end
		local exponent = scalar * (10 ^ (index * 3))
		if exponent == huge or exponent == -huge then return nil end
		return exponent
	end
	return scalar
end

local function parseCompactLayerScalarRange(value: string, first: number, last: number): number?
	local plain = parseGroupedDecimalRange(value, first, last)
	if plain ~= nil then return plain end

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

	if suffixStart <= first or suffixStart > last then return nil end

	local index = suffixIndexRange(value, suffixStart, last, "standard")
	if index == nil then return nil end

	local scalar = parseGroupedDecimalRange(value, first, suffixStart - 1)
	if scalar == nil then return nil end

	local result = scalar * (10 ^ (index * 3))
	if result == huge or result == -huge then return nil end
	return result
end

local function fromSignedLogSmart(logMagnitude: number, negative: boolean): buffer

	if logMagnitude <= 308.25471555991675 and logMagnitude >= -323.3062153431158 then
		local magnitude = 10 ^ logMagnitude
		if magnitude ~= 0 and magnitude ~= huge then
			return NanoFormat.fromNumber(negative and -magnitude or magnitude)
		end
	end
	return NanoFormat.fromLog10(logMagnitude, negative)
end

(function()
	local function fromStringSlow(value: string, suffixType: string?): buffer
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

		local firstLower = asciiLowerByte(byte(value, first))
		if firstLower == 105 then
			if rangeEqualsCI(value, first, last, "inf") or rangeEqualsCI(value, first, last, "infinity") then
				return makeSpecial(negative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
			end
		elseif firstLower == 110 then
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
				if zero then return makeTiny(0) end

				local totalLog = exponent + mantissaLog
				if reciprocal then totalLog = -totalLog end
				return fromSignedLogSmart(totalLog, finalNegative)
			end
		end

		if asciiLowerByte(byte(value, first)) == 101 then
			local second = if first < last then byte(value, first + 1) else nil
			if second == 94 then
				local tokenStart = first + 2
				if tokenStart <= last and byte(value, tokenStart) == 40 then

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

		do
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

		local ePos = 0
		for i = first, last do
			c = byte(value, i)
			if c == 101 or c == 69 then
				if ePos ~= 0 then
					return makeSpecial(SPECIAL_NAN)
				end
				ePos = i
			end
		end

		if ePos ~= 0 then
			local valid = true
			local mantissaNegative = false
			local zero = false
			local mantissaLog: number? = nil

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

	local function fastSignedIntegerRange(value: string, first: number, last: number): number?
		if first > last then
			return nil
		end
		local sign = 1
		local c = byte(value, first)
		if c == 43 then
			first += 1
		elseif c == 45 then
			sign = -1
			first += 1
		end
		if first > last or last - first >= 15 then
			return nil
		end
		local n = 0
		for i = first, last do
			c = byte(value, i)
			if c < 48 or c > 57 then
				return nil
			end
			n = n * 10 + c - 48
		end
		return n * sign
	end

	local function nestedDecimalValueRange(value: string, first: number, last: number): buffer?
		local valid, negative, zero, directAbs, logAbs =
			parseDecimalRange(value, first, last)
		if not valid or logAbs == nil then
			return nil
		end
		if zero then
			return makeTiny(0)
		end
		if directAbs ~= nil then
			return NanoFormat.fromNumber(negative and -directAbs or directAbs)
		end
		return fromSignedLogSmart(logAbs, negative)
	end

	local function nestedScientificValueRange(value: string, first: number, last: number): buffer?
		local rightE = 0
		for i = last, first, -1 do
			local c = byte(value, i)
			if c == 101 or c == 69 then
				rightE = i
				break
			end
		end
		if rightE == 0 or rightE >= last then
			return nil
		end

		local result = nestedDecimalValueRange(value, rightE + 1, last)
		if result == nil then
			return nil
		end

		local segmentEnd = rightE - 1
		local steps = 0

		while segmentEnd >= first do
			local previousE = 0
			for i = segmentEnd, first, -1 do
				local c = byte(value, i)
				if c == 101 or c == 69 then
					previousE = i
					break
				end
			end

			local segmentStart = previousE == 0 and first or previousE + 1
			if segmentStart > segmentEnd then
				return nil
			end

			local mantissa = nestedDecimalValueRange(value, segmentStart, segmentEnd)
			if mantissa == nil then
				return nil
			end

			result = NanoFormat.mul(mantissa, NanoFormat.pow10(result))
			steps += 1

			if previousE == 0 then
				return result
			end
			if steps >= 256 then
				return nil
			end

			segmentEnd = previousE - 1
		end

		return nil
	end

	local function fastEFamily(value: string, first: number, last: number, negative: boolean, reciprocal: boolean): buffer?
		local ePos = 0
		for i = first, last do
			local c = byte(value, i)
			if c == 101 or c == 69 then
				ePos = i
				break
			end
		end
		if ePos == 0 then
			return nil
		end
		local eEnd = ePos + 1
		while eEnd <= last do
			local c = byte(value, eEnd)
			if c ~= 101 and c ~= 69 then
				break
			end
			eEnd += 1
		end
		if eEnd > last then
			return nil
		end
		local eCount = eEnd - ePos
		local mantissaNegative = false
		local zero = false
		local mantissaLog = 0
		if ePos > first then
			if ePos == first + 1 then
				local d = byte(value, first) - 48
				if d < 0 or d > 9 then
					return nil
				end
				if d == 0 then
					zero = true
					mantissaLog = -huge
				else
					mantissaLog = DIGIT_LOG10[d]
				end
			else
				local valid, innerNegative, innerZero, _, innerLog = parseDecimalRange(value, first, ePos - 1, false)
				if not valid or innerLog == nil then
					return nil
				end
				mantissaNegative = innerNegative
				zero = innerZero
				mantissaLog = innerLog
			end
		end
		local finalNegative = negative ~= mantissaNegative
		if zero then
			if reciprocal then
				return makeSpecial(finalNegative and SPECIAL_NEG_INF or SPECIAL_POS_INF)
			end
			return makeTiny(0)
		end
		if eCount == 1 then
			local exponent = fastSignedIntegerRange(value, eEnd, last)
			if exponent ~= nil then
				local totalLog = exponent + mantissaLog
				if reciprocal then
					totalLog = -totalLog
				end
				return fromSignedLogSmart(totalLog, finalNegative)
			end
			local directExponent, exponentSign, exponentLog10 = parseScientificExponentRange(value, eEnd, last)
			if directExponent ~= nil then
				local totalLog = directExponent + mantissaLog
				if reciprocal then
					totalLog = -totalLog
				end
				return fromSignedLogSmart(totalLog, finalNegative)
			end
			if exponentSign ~= nil and exponentLog10 ~= nil then
				local exponentReciprocal = exponentSign < 0
				if reciprocal then
					exponentReciprocal = not exponentReciprocal
				end
				return NanoFormat.fromLayer(2, exponentLog10, finalNegative, exponentReciprocal)
			end

			local nestedOk, nestedDirect, nestedLog =
				parseFiniteNumericRange(value, eEnd, last)

			if nestedOk then
				if nestedDirect ~= nil then
					local totalLog = nestedDirect + mantissaLog
					if reciprocal then
						totalLog = -totalLog
					end
					return fromSignedLogSmart(totalLog, finalNegative)
				elseif nestedLog ~= nil then
					local exponentNegative = byte(value, eEnd) == 45
					local nestedReciprocal = exponentNegative
					if reciprocal then
						nestedReciprocal = not nestedReciprocal
					end
					return NanoFormat.fromLayer(
						2,
						nestedLog,
						finalNegative,
						nestedReciprocal
					)
				end
			end

			local nestedExponent =
				nestedScientificValueRange(value, eEnd, last)

			if nestedExponent ~= nil then
				local result = NanoFormat.pow10(nestedExponent)

				if mantissaLog ~= 0 then
					result = NanoFormat.mul(
						result,
						fromSignedLogSmart(mantissaLog, false)
					)
				end

				if finalNegative then
					result = NanoFormat.neg(result)
				end
				if reciprocal then
					result = NanoFormat.reciprocal(result)
				end

				return result
			end

			return nil
		end
		local topOk, top = parseFiniteNumericRange(value, eEnd, last)
		if not topOk or top == nil then
			return nil
		end
		if mantissaLog == 0 then
			return NanoFormat.fromLayer(eCount, top, finalNegative, reciprocal)
		end
		local normalizedLayer, normalizedTop = normalizeLayerInput(eCount, top, false)
		if normalizedLayer <= 0 then
			if normalizedTop == 0 then
				return makeTiny(0)
			end
			local totalLog = log10(abs(normalizedTop)) + mantissaLog
			if reciprocal then
				totalLog = -totalLog
			end
			return fromSignedLogSmart(totalLog, finalNegative)
		elseif normalizedLayer < 2 then
			local totalLog = normalizedTop + mantissaLog
			if reciprocal then
				totalLog = -totalLog
			end
			return fromSignedLogSmart(totalLog, finalNegative)
		end
		return NanoFormat.fromLayer(normalizedLayer, normalizedTop, finalNegative, reciprocal)
	end

	local function fastRawEFamily(value: string, length: number): buffer?
		if length == 0 then
			return nil
		end
		local first = 1
		local last = length
		local negative = false
		local reciprocal = false
		local c = byte(value, first)
		if c == 43 or c == 45 then
			negative = c == 45
			first += 1
			if first > last then
				return nil
			end
		end
		if first + 1 <= last and byte(value, first) == 49 and byte(value, first + 1) == 47 then
			reciprocal = true
			first += 2
			if first > last then
				return nil
			end
		end
		return fastEFamily(value, first, last, negative, reciprocal)
	end

	function NanoFormat.fromString(value: string, suffixType: string?): buffer
		local length = #value
		if length == 0 then
			return makeSpecial(SPECIAL_NAN)
		end
		local c1 = byte(value, 1)
		local c2 = length >= 2 and byte(value, 2) or nil
		local c3 = length >= 3 and byte(value, 3) or nil
		local immediateE = false
		if c1 == 101 or c1 == 69 then
			immediateE = true
		elseif c1 == 43 or c1 == 45 then
			if c2 == 101 or c2 == 69 then
				immediateE = true
			elseif c2 ~= nil and c2 >= 48 and c2 <= 57 and (c3 == 101 or c3 == 69) then
				immediateE = true
			end
		elseif c1 >= 48 and c1 <= 57 and (c2 == 101 or c2 == 69) then
			immediateE = true
		end
		if immediateE then
			local result = fastRawEFamily(value, length)
			if result ~= nil then
				return result
			end
		end
		local lastByte = byte(value, length)
		if not ((lastByte >= 65 and lastByte <= 90) or (lastByte >= 97 and lastByte <= 122)) then
			local direct = toNumber(value)
			if direct ~= nil and direct ~= huge and direct ~= -huge then
				return NanoFormat.fromNumber(direct)
			end
		end
		if not immediateE and lastByte >= 48 and lastByte <= 57 then
			local result = fastRawEFamily(value, length)
			if result ~= nil then
				return result
			end
		end
		return fromStringSlow(value, suffixType)
	end
end)()

local function scalarEndFast(data: buffer, bitOffset: number, limit: number): number
	if bitOffset < 0 or bitOffset + 1 > limit then
		error("NanoFormat: truncated scalar")
	end

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

	local header7 = bufferReadBits(data, bitOffset, 7)
	if band(header7, 1) == 0 then
		local n = floor(header7 / 2)
		if n > 53 then
			error("NanoFormat: invalid exact scalar bit length")
		end
		return readUIntExactAtFast(data, bitOffset + 1 + EXACT_LEN_BITS, n),
			bitOffset + 1 + EXACT_LEN_BITS + n
	end

	local tail18 = bufferReadBits(data, bitOffset + 7, 18)
	local expCode = floor(header7 / 2) + band(tail18, 15) * 64
	if expCode > SCALAR_EXP_MAX + SCALAR_EXP_BIAS then
		error("NanoFormat: invalid scalar exponent code")
	end
	local mantCode = floor(tail18 / 16)
	local exponent = expCode - SCALAR_EXP_BIAS
	return decodeMantissa(mantCode, SCALAR_MANT_MAX) * (10 ^ exponent),
		bitOffset + SCALAR_APPROX_BITS
end

local function readLayerFieldAtFast(data: buffer, bitOffset: number): (number, boolean, number)

	local header6 = bufferReadBits(data, bitOffset, 6)
	if band(header6, 1) == 0 then
		return floor(header6 / 2) + 2, false, bitOffset + 6
	end

	local layerIsLog = band(header6, 2) ~= 0
	local layer, nextBit = readScalarAtFast(data, bitOffset + 2)
	return layer, layerIsLog, nextBit
end

local function decodeAt(data: buffer, bitOffset: number)
	local totalBits = bufferLen(data) * 8
	if bitOffset < 0 or bitOffset + 8 > totalBits then
		error("NanoFormat: truncated record")
	end

	local header8 = bufferReadBits(data, bitOffset, 8)

	if band(header8, 1) == 0 then
		local nextBit = bitOffset + 8
		return {Kind = "Integer", Value = floor(header8 / 2), Negative = false}, nextBit
	end

	if band(header8, 3) == 1 then
		local nextBit = bitOffset + 8
		return {Kind = "Integer", Value = -(floor(header8 / 4) + 1), Negative = true}, nextBit
	end

	if band(header8, 7) == 3 then
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

	if band(header8, 15) == 7 then
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

	if band(header8, 31) == 15 then
		local negative = band(header8, 32) ~= 0
		local reciprocal = band(header8, 64) ~= 0
		local top, nextBit = readScalarAtFast(data, bitOffset + 7)
		if nextBit > totalBits then error("NanoFormat: truncated log scalar") end
		return {Kind = "Log", Negative = negative, Reciprocal = reciprocal, Layer = 1, Top = top}, nextBit
	end

	if band(header8, 63) == 31 then
		local negative = band(header8, 64) ~= 0
		local reciprocal = band(header8, 128) ~= 0
		local fieldOffset = bitOffset + 8
		if fieldOffset + 6 > totalBits then error("NanoFormat: truncated layer field") end
		local layer, layerIsLog, topOffset = readLayerFieldAtFast(data, fieldOffset)
		if topOffset > totalBits then error("NanoFormat: truncated layer scalar") end
		local top, nextBit = readScalarAtFast(data, topOffset)
		if nextBit > totalBits then error("NanoFormat: truncated layer top") end
		return {
			Kind = "Layer", Negative = negative, Reciprocal = reciprocal,
			Layer = layerIsLog:: any and nil:: any or layer:: any,
			LayerLog10 = layerIsLog and layer or nil,
			LayerIsLog = layerIsLog, Top = top,
		}, nextBit
	end

	local nextBit = bitOffset + 8
	local special = floor(header8 / 64)
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
		local suffix = STANDARD_SUFFIXES[group]
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

local function compactLayerScalarText(value: number, precision: number): string
	if value == 0 then return "0" end

	local negative = value < 0
	local magnitude = abs(value)

	if magnitude < 1000 then
		local body =
			if magnitude == floor(magnitude)
			then toString(magnitude)
			else shortNumber(magnitude, precision)
		return negative and ("-" .. body) or body
	end

	local exponent = floor(log10(magnitude))
	local index = floor(exponent / 3)
	local suffix = STANDARD_SUFFIXES[index]

	if suffix ~= nil then
		local scaled = magnitude / (10 ^ (index * 3))
		if roundsTo1000(scaled, precision) then
			local nextSuffix = STANDARD_SUFFIXES[index + 1]
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

local function layerNotationText(layer: number,layerIsLog: boolean,top: number,precision: number): string
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

	if roundsTo1000(scaled, precision) then
		local nextSuffix = suffixForIndex(index + 1, suffixType)
		if nextSuffix ~= nil then
			return shortNumber(scaled / 1000, precision) .. nextSuffix
		end
		local promotedExponent = (index + 1) * 3
		if (suffixType == "standard" or suffixType == "extended") and promotedExponent >= NanoFormat.E_NOTATION_START then
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

local function formatIntegerValue(integer: number, precision: number, suffixKind: string): string
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

	local header8 = bufferReadBits(value, 0, 8)

	if band(header8, 1) == 0 then
		return formatIntegerValue(floor(header8 / 2), precision, suffixKind)
	end

	if band(header8, 3) == 1 then
		return formatIntegerValue(-(floor(header8 / 4) + 1), precision, suffixKind)
	end

	if band(header8, 7) == 3 then
		local header9 = bufferReadBits(value, 0, 9)
		local negative = band(header9, 8) ~= 0
		local n = floor(header9 / 16)
		local payloadOffset = 9
		if n == 0 then
			local header14 = bufferReadBits(value, 0, 14)
			n = 32 + floor(header14 / 512)
			payloadOffset = 14
			if n > MAX_INTEGER_MODE_BITS then
				error("NanoFormat: invalid extended integer bit length")
			end
		end
		local magnitude = readUIntExactAtFast(value, payloadOffset, n)
		return formatIntegerValue(negative and -magnitude or magnitude, precision, suffixKind)
	end

	if band(header8, 15) == 7 then
		local header15 = bufferReadBits(value, 0, 15)
		local negative = band(header15, 16) ~= 0
		local expCode = floor(header15 / 32)
		if expCode > NORMAL_EXP_MAX + NORMAL_EXP_BIAS then
			error("NanoFormat: invalid normal exponent code")
		end
		local mantCode = bufferReadBits(value, 15, NORMAL_MANT_BITS)
		local exponent = expCode - NORMAL_EXP_BIAS
		local mantissa = decodeMantissa(mantCode, NORMAL_MANT_MAX)
		local rendered = formatNormalParts(mantissa, exponent, precision, suffixKind)
		return negative and ("-" .. rendered) or rendered
	end

	if band(header8, 31) == 15 then
		local negative = band(header8, 32) ~= 0
		local reciprocal = band(header8, 64) ~= 0
		local top = readScalarAtFast(value, 7)
		local rendered
		if reciprocal and (suffixKind == "scientific" or suffixKind == "engineering") then
			rendered = formatPower10(-top, precision, suffixKind)
		else
			rendered = formatPower10(top, precision, suffixKind)
			if reciprocal then
				rendered = "1/" .. rendered
			end
		end
		return negative and ("-" .. rendered) or rendered
	end

	if band(header8, 63) == 31 then
		local negative = band(header8, 64) ~= 0
		local reciprocal = band(header8, 128) ~= 0
		local layer, layerIsLog, nextBit = readLayerFieldAtFast(value, 8)
		local top = readScalarAtFast(value, nextBit)
		local rendered

		if suffixKind == "standard"
			or suffixKind == "extended"
			or suffixKind == "exponent"
		then
			rendered = layerNotationText(layer, layerIsLog, top, precision)
		elseif layerIsLog then
			rendered = "e^(10^"
				.. formatLargeScalar(layer, precision)
				.. ") "
				.. formatLargeScalar(top, precision)
		elseif layer == 2 then
			rendered = "ee" .. formatLargeScalar(top, precision)
		elseif layer == 3 then
			rendered = "eee" .. formatLargeScalar(top, precision)
		else
			rendered = "e^"
				.. formatLargeScalar(layer, precision)
				.. " "
				.. formatLargeScalar(top, precision)
		end

		if reciprocal then rendered = "1/" .. rendered end
		return negative and ("-" .. rendered) or rendered
	end

	local special = floor(header8 / 64)
	if special == SPECIAL_POS_INF then
		return "inf"
	elseif special == SPECIAL_NEG_INF then
		return "-inf"
	elseif special == SPECIAL_NAN then
		return "NaN"
	end
	return "Reserved"
end

function NanoFormat.format(value: buffer, precision: number?, suffixType: string?): string

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

local function copyBits(target: buffer, targetBit: number, source: buffer, sourceBit: number, count: number)
	if count <= 0 then
		return
	end

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
	if typeof(packed) ~= "buffer" or count < 0 or count ~= floor(count) then
		return false, nil
	end
	local physicalBits = bufferLen(packed) * 8
	local limit = totalBits or physicalBits
	if limit < 0 or limit > physicalBits then
		return false, nil
	end

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

NanoFormat.LB_SCOPE_VERSION = 2

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

end)();

(function()
	local LB2_VERSION = 2
	local LB2_MAX = NanoFormat.LB_MAX
	local LB2_FINITE_MAX = NanoFormat.LB_FINITE_MAX
	local LB2_ONE = NanoFormat.LB_ONE
	local LB2_POSITIVE_SPAN = NanoFormat.LB_POSITIVE_SPAN
	local LB2_MAX_FINITE_NUMBER = 1.7976931348623157e308
	local LB2_FINITE_LOG_MAX = log10(LB2_MAX_FINITE_NUMBER)
	local LB2_INTEGER_EXACT_MAX = 2097151
	local LB2_SCALAR_EXACT_MAX = SCALAR_EXACT_VALUE_MAX
	local LB2_NORMAL_STRIDE = NORMAL_MANT_MAX + 1
	local LB2_SCALAR_STRIDE = SCALAR_MANT_MAX + 1
	local LB2_NORMAL_LAST_MANT = floor(
		((LB2_MAX_FINITE_NUMBER / 1e308 - 1) / 9) * NORMAL_MANT_MAX
	)
	local LB2_SCALAR_LAST_MANT = floor(
		((LB2_MAX_FINITE_NUMBER / 1e308 - 1) / 9) * SCALAR_MANT_MAX
	)
	local LB2_NORMAL_FULL_EXP_COUNT = 308
	local LB2_SCALAR_FULL_EXP_COUNT = SCALAR_EXP_MAX - SCALAR_EXP_MIN
	local LB2_NORMAL_APPROX_COUNT =
		LB2_NORMAL_FULL_EXP_COUNT * LB2_NORMAL_STRIDE + LB2_NORMAL_LAST_MANT + 1
	local LB2_SCALAR_APPROX_COUNT =
		LB2_SCALAR_FULL_EXP_COUNT * LB2_SCALAR_STRIDE + LB2_SCALAR_LAST_MANT + 1
	local LB2_FINITE_CAP = LB2_NORMAL_APPROX_COUNT + LB2_INTEGER_EXACT_MAX + 4
	local LB2_SCALAR_CAP = LB2_SCALAR_APPROX_COUNT + LB2_SCALAR_EXACT_MAX + 4
	local LB2_LOG_OFFSET = LB2_FINITE_CAP
	local LB2_LAYER_OFFSET = LB2_LOG_OFFSET + LB2_SCALAR_CAP
	local LB2_LAYER_CAP = LB2_SCALAR_CAP * LB2_SCALAR_CAP
	local LB2_LOG_LAYER_OFFSET = LB2_LAYER_OFFSET + LB2_LAYER_CAP
	local LB2_LOG_LAYER_CAP = LB2_LAYER_CAP
	local LB2_USED_END = LB2_LOG_LAYER_OFFSET + LB2_LOG_LAYER_CAP - 1

	if LB2_USED_END > LB2_POSITIVE_SPAN then
		error("NanoFormat: LB V2 layout exceeds exact integer range")
	end

	NanoFormat.LB_VERSION = LB2_VERSION
	NanoFormat.LB_SCOPE_VERSION = 2
	NanoFormat.LB_V2_FINITE_CAP = LB2_FINITE_CAP
	NanoFormat.LB_V2_SCALAR_CAP = LB2_SCALAR_CAP
	NanoFormat.LB_V2_USED_SPAN = LB2_USED_END
	NanoFormat.LB_V2_REVERSIBLE = true

	local function lb2Coerce(value: any): buffer
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

	local function lb2NormalValueFromIndex(index: number): number?
		if index < 0 or index >= LB2_NORMAL_APPROX_COUNT then
			return nil
		end
		local full = LB2_NORMAL_FULL_EXP_COUNT * LB2_NORMAL_STRIDE
		local exponent
		local mantCode
		if index < full then
			exponent = floor(index / LB2_NORMAL_STRIDE)
			mantCode = index - exponent * LB2_NORMAL_STRIDE
		else
			exponent = 308
			mantCode = index - full
			if mantCode > LB2_NORMAL_LAST_MANT then
				return nil
			end
		end
		return decodeMantissa(mantCode, NORMAL_MANT_MAX) * (10 ^ exponent)
	end

	local function lb2NormalIndexFromValue(value: number): number?
		if value < 1 or value > LB2_MAX_FINITE_NUMBER or value ~= value then
			return nil
		end
		local exponent = floor(log10(value))
		if exponent < 0 or exponent > 308 then
			return nil
		end
		local mantissa = value / (10 ^ exponent)
		local mantCode = quantizeMantissa(mantissa, NORMAL_MANT_MAX)
		if exponent == 308 and mantCode > LB2_NORMAL_LAST_MANT then
			return nil
		end
		return exponent * LB2_NORMAL_STRIDE + mantCode
	end

	local function lb2NormalLowerBound(value: number): number
		local lo = 0
		local hi = LB2_NORMAL_APPROX_COUNT
		while lo < hi do
			local mid = floor((lo + hi) / 2)
			local candidate = lb2NormalValueFromIndex(mid)
			if candidate ~= nil and candidate < value then
				lo = mid + 1
			else
				hi = mid
			end
		end
		return lo
	end

	local function lb2FiniteRank(value: number): number?
		if value < 1 or value > LB2_MAX_FINITE_NUMBER or value ~= value then
			return nil
		end
		if value <= LB2_INTEGER_EXACT_MAX and value == floor(value) then
			return lb2NormalLowerBound(value) + value - 1
		end
		local index = lb2NormalIndexFromValue(value)
		if index == nil then
			return nil
		end
		local exactLE = min(LB2_INTEGER_EXACT_MAX, floor(value))
		return index + exactLE
	end

	local function lb2FiniteApproxRank(index: number): (number?, number?)
		local value = lb2NormalValueFromIndex(index)
		if value == nil then
			return nil, nil
		end
		local exactLE = min(LB2_INTEGER_EXACT_MAX, floor(value))
		return index + exactLE, value
	end

	local function lb2FiniteValueFromRank(rank: number): number?
		if rank < 0 or rank >= LB2_FINITE_CAP then
			return nil
		end
		local lo = 0
		local hi = LB2_NORMAL_APPROX_COUNT
		while lo < hi do
			local mid = floor((lo + hi) / 2)
			local approxRank = lb2FiniteApproxRank(mid)
			if approxRank ~= nil and approxRank < rank then
				lo = mid + 1
			else
				hi = mid
			end
		end
		local index = lo
		if index < LB2_NORMAL_APPROX_COUNT then
			local approxRank, value = lb2FiniteApproxRank(index)
			if approxRank == rank and value ~= nil then
				local canonical = lb2FiniteRank(value)
				if canonical == rank then
					return value
				end
			end
		end
		local integer = rank - index + 1
		if integer >= 1 and integer <= LB2_INTEGER_EXACT_MAX then
			local canonical = lb2FiniteRank(integer)
			if canonical == rank then
				return integer
			end
		end
		return nil
	end

	local function lb2ScalarValueFromIndex(index: number): number?
		if index < 0 or index >= LB2_SCALAR_APPROX_COUNT then
			return nil
		end
		local full = LB2_SCALAR_FULL_EXP_COUNT * LB2_SCALAR_STRIDE
		local exponent
		local mantCode
		if index < full then
			local expIndex = floor(index / LB2_SCALAR_STRIDE)
			exponent = SCALAR_EXP_MIN + expIndex
			mantCode = index - expIndex * LB2_SCALAR_STRIDE
		else
			exponent = 308
			mantCode = index - full
			if mantCode > LB2_SCALAR_LAST_MANT then
				return nil
			end
		end
		return decodeMantissa(mantCode, SCALAR_MANT_MAX) * (10 ^ exponent)
	end

	local function lb2ScalarIndexFromValue(value: number): number?
		if value <= 0 or value > LB2_MAX_FINITE_NUMBER or value ~= value then
			return nil
		end
		local lg = log10(value)
		local exponent = floor(lg)
		if exponent < SCALAR_EXP_MIN then
			exponent = SCALAR_EXP_MIN
		elseif exponent > 308 then
			return nil
		end
		local mantissa = 10 ^ (lg - exponent)
		local mantCode = quantizeMantissa(mantissa, SCALAR_MANT_MAX)
		if exponent == 308 and mantCode > LB2_SCALAR_LAST_MANT then
			return nil
		end
		return (exponent - SCALAR_EXP_MIN) * LB2_SCALAR_STRIDE + mantCode
	end

	local function lb2ScalarLowerBound(value: number): number
		local lo = 0
		local hi = LB2_SCALAR_APPROX_COUNT
		while lo < hi do
			local mid = floor((lo + hi) / 2)
			local candidate = lb2ScalarValueFromIndex(mid)
			if candidate ~= nil and candidate < value then
				lo = mid + 1
			else
				hi = mid
			end
		end
		return lo
	end

	local function lb2ScalarRank(value: number): number?
		if value < 0 or value > LB2_MAX_FINITE_NUMBER or value ~= value then
			return nil
		end
		if value <= LB2_SCALAR_EXACT_MAX and value == floor(value) then
			return lb2ScalarLowerBound(value) + value
		end
		local index = lb2ScalarIndexFromValue(value)
		if index == nil then
			return nil
		end
		local exactLE = min(LB2_SCALAR_EXACT_MAX + 1, floor(value) + 1)
		return index + exactLE
	end

	local function lb2ScalarApproxRank(index: number): (number?, number?)
		local value = lb2ScalarValueFromIndex(index)
		if value == nil then
			return nil, nil
		end
		local exactLE = min(LB2_SCALAR_EXACT_MAX + 1, floor(value) + 1)
		return index + exactLE, value
	end

	local function lb2ScalarValueFromRank(rank: number): number?
		if rank < 0 or rank >= LB2_SCALAR_CAP then
			return nil
		end
		local lo = 0
		local hi = LB2_SCALAR_APPROX_COUNT
		while lo < hi do
			local mid = floor((lo + hi) / 2)
			local approxRank = lb2ScalarApproxRank(mid)
			if approxRank ~= nil and approxRank < rank then
				lo = mid + 1
			else
				hi = mid
			end
		end
		local index = lo
		if index < LB2_SCALAR_APPROX_COUNT then
			local approxRank, value = lb2ScalarApproxRank(index)
			if approxRank == rank and value ~= nil then
				local canonical = lb2ScalarRank(value)
				if canonical == rank then
					return value
				end
			end
		end
		local integer = rank - index
		if integer >= 0 and integer <= LB2_SCALAR_EXACT_MAX then
			local canonical = lb2ScalarRank(integer)
			if canonical == rank then
				return integer
			end
		end
		return nil
	end

	local function lb2DeltaFromLogDistance(top: number): number?
		if top ~= top or top < 0 then
			return nil
		end
		if top <= LB2_FINITE_LOG_MAX then
			local distance = 10 ^ top
			if distance ~= huge and distance <= LB2_MAX_FINITE_NUMBER then
				return lb2FiniteRank(distance)
			end
		end
		local scalarRank = lb2ScalarRank(top)
		if scalarRank == nil then
			return nil
		end
		return LB2_LOG_OFFSET + scalarRank
	end

	local function lb2LayerPairRank(layer: number, top: number): number?
		local layerRank = lb2ScalarRank(layer)
		local topRank = lb2ScalarRank(top)
		if layerRank == nil or topRank == nil then
			return nil
		end
		return layerRank * LB2_SCALAR_CAP + topRank
	end

	local function lb2Finalize(delta: number, negative: boolean, reciprocal: boolean): number?
		if delta < 0 or delta > LB2_USED_END then
			return nil
		end
		if delta == 0 then
			return negative and -LB2_ONE or LB2_ONE
		end
		local code = reciprocal and (LB2_ONE - delta) or (LB2_ONE + delta)
		if code < 1 or code > LB2_FINITE_MAX then
			return nil
		end
		code = floor(code)
		return negative and -code or code
	end

	local function lb2EncodeBuffer(value: buffer): (number, boolean, string)
		local data = decodeAt(value, 0)
		if data.Kind == "NaN" or data.Kind == "Reserved" then
			return 0, false, "nan"
		end
		if data.Kind == "Infinity" then
			return data.Negative and -LB2_MAX or LB2_MAX, true, "infinity"
		end
		if data.Kind == "Integer" and data.Value == 0 then
			return 0, true, "zero"
		end

		local negative = false
		local reciprocal = false
		local delta
		local band = "finite"

		if data.Kind == "Integer" then
			negative = data.Value < 0
			local magnitude = abs(data.Value)
			delta = lb2FiniteRank(magnitude)
		elseif data.Kind == "Normal" then
			negative = data.Negative == true
			local magnitude = data.Mantissa * (10 ^ data.Exponent)
			if magnitude == 0 then
				return 0, true, "zero"
			end
			if magnitude < 1 then
				reciprocal = true
				local distance = 1 / magnitude
				if distance ~= huge and distance <= LB2_MAX_FINITE_NUMBER then
					delta = lb2FiniteRank(distance)
				else
					delta = lb2DeltaFromLogDistance(-log10(magnitude))
					band = "log"
				end
			else
				delta = lb2FiniteRank(magnitude)
			end
		elseif data.Kind == "Log" then
			negative = data.Negative == true
			reciprocal = data.Reciprocal == true
			delta = lb2DeltaFromLogDistance(data.Top)
			band = data.Top <= LB2_FINITE_LOG_MAX and "finite" or "log"
		elseif data.Kind == "Layer" then
			negative = data.Negative == true
			reciprocal = data.Reciprocal == true
			if data.LayerIsLog then
				if data.LayerLog10 <= 308 then
					local layer, top = normalizeLayerInput(10 ^ data.LayerLog10, data.Top, false)
					if layer < 2 then
						delta = lb2DeltaFromLogDistance(top)
						band = "log"
					else
						local pair = lb2LayerPairRank(layer, top)
						delta = pair and (LB2_LAYER_OFFSET + pair) or nil
						band = "layer"
					end
				else
					local pair = lb2LayerPairRank(data.LayerLog10, data.Top)
					delta = pair and (LB2_LOG_LAYER_OFFSET + pair) or nil
					band = "log-layer"
				end
			else
				local layer, top = normalizeLayerInput(data.Layer, data.Top, false)
				if layer < 2 then
					delta = lb2DeltaFromLogDistance(top)
					band = "log"
				else
					local pair = lb2LayerPairRank(layer, top)
					delta = pair and (LB2_LAYER_OFFSET + pair) or nil
					band = "layer"
				end
			end
		else
			return 0, false, "nan"
		end

		if delta == nil then
			return 0, false, band
		end
		local code = lb2Finalize(delta, negative, reciprocal)
		if code == nil then
			return 0, false, band
		end
		return code, true, band
	end

	local function lb2DecodeFinite(rank: number, reciprocal: boolean, negative: boolean): buffer?
		local distance = lb2FiniteValueFromRank(rank)
		if distance == nil then
			return nil
		end
		local magnitude = reciprocal and (1 / distance) or distance
		if magnitude == 0 then
			local top = log10(distance)
			return NanoFormat.fromLog10(-top, negative)
		end
		return NanoFormat.fromNumber(negative and -magnitude or magnitude)
	end

	local function lb2DecodeLog(rank: number, reciprocal: boolean, negative: boolean): buffer?
		local top = lb2ScalarValueFromRank(rank)
		if top == nil or top <= LB2_FINITE_LOG_MAX then
			return nil
		end
		return NanoFormat.fromLog10(reciprocal and -top or top, negative)
	end

	local function lb2DecodePair(pair: number, layerIsLog: boolean, reciprocal: boolean, negative: boolean): buffer?
		if pair < 0 or pair >= LB2_LAYER_CAP then
			return nil
		end
		local layerRank = floor(pair / LB2_SCALAR_CAP)
		local topRank = pair - layerRank * LB2_SCALAR_CAP
		local layer = lb2ScalarValueFromRank(layerRank)
		local top = lb2ScalarValueFromRank(topRank)
		if layer == nil or top == nil then
			return nil
		end
		if layerIsLog then
			if layer <= 308 then
				return nil
			end
			return NanoFormat.fromLayerLog10(layer, top, negative, reciprocal)
		end
		if layer < 2 then
			return nil
		end
		return NanoFormat.fromLayer(layer, top, negative, reciprocal)
	end

	local function lb2DecodeCore(encoded: number): buffer
		if encoded ~= encoded or encoded > LB2_MAX or encoded < -LB2_MAX or encoded ~= floor(encoded) then
			return makeSpecial(SPECIAL_NAN)
		end
		if encoded == 0 then
			return NanoFormat.fromNumber(0)
		end
		if encoded == LB2_MAX then
			return makeSpecial(SPECIAL_POS_INF)
		elseif encoded == -LB2_MAX then
			return makeSpecial(SPECIAL_NEG_INF)
		end

		local negative = encoded < 0
		local code = negative and -encoded or encoded
		if code < 1 or code > LB2_FINITE_MAX then
			return makeSpecial(SPECIAL_NAN)
		end
		if code == LB2_ONE then
			return NanoFormat.fromNumber(negative and -1 or 1)
		end

		local reciprocal = code < LB2_ONE
		local delta = reciprocal and (LB2_ONE - code) or (code - LB2_ONE)
		if delta < 0 or delta > LB2_USED_END then
			return makeSpecial(SPECIAL_NAN)
		end

		local result
		if delta < LB2_LOG_OFFSET then
			result = lb2DecodeFinite(delta, reciprocal, negative)
		elseif delta < LB2_LAYER_OFFSET then
			result = lb2DecodeLog(delta - LB2_LOG_OFFSET, reciprocal, negative)
		elseif delta < LB2_LOG_LAYER_OFFSET then
			result = lb2DecodePair(delta - LB2_LAYER_OFFSET, false, reciprocal, negative)
		else
			result = lb2DecodePair(delta - LB2_LOG_LAYER_OFFSET, true, reciprocal, negative)
		end
		if result == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		local roundCode, valid = lb2EncodeBuffer(result)
		if not valid or roundCode ~= encoded then
			return makeSpecial(SPECIAL_NAN)
		end
		return result
	end

	local function lb2IsCode(encoded: number): boolean
		local decoded = lb2DecodeCore(encoded)
		local data = decodeAt(decoded, 0)
		return data.Kind ~= "NaN" and data.Kind ~= "Reserved"
	end

	function NanoFormat.tryLBEncode(value: any): (boolean, number)
		local source = lb2Coerce(value)
		local ok, code, valid = fastPcall(lb2EncodeBuffer, source)
		if not ok or not valid then
			return false, 0
		end
		return true, code
	end

	function NanoFormat.lbencodeV2(value: any): number
		local code = lb2EncodeBuffer(lb2Coerce(value))
		return code
	end

	function NanoFormat.lbdecodeV2(encoded: number): buffer
		return lb2DecodeCore(encoded)
	end

	function NanoFormat.lbencode(value: any): number
		return NanoFormat.lbencodeV2(value)
	end

	function NanoFormat.lbdecode(encoded: number, version: number?): buffer
		if version == 1 then
			return NanoFormat.lbdecodeV1(encoded)
		end
		if version ~= nil and version ~= LB2_VERSION then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.lbdecodeV2(encoded)
	end

	function NanoFormat.lbcodecVersion(): number
		return LB2_VERSION
	end

	NanoFormat.isLBCode = lb2IsCode

	function NanoFormat.lbpack(value: any): {[string]: number}
		return {
			v = LB2_VERSION,
			c = NanoFormat.lbencodeV2(value),
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

	function NanoFormat.lbinfo(value: any)
		local code, valid, band = lb2EncodeBuffer(lb2Coerce(value))
		if not valid then
			return {
				version = LB2_VERSION,
				code = 0,
				band = "nan",
				negative = false,
				reciprocal = false,
				distanceFromOne = 0,
				reversible = false,
			}
		end
		if code == 0 then
			return {
				version = LB2_VERSION,
				code = 0,
				band = "zero",
				negative = false,
				reciprocal = false,
				distanceFromOne = LB2_ONE,
				reversible = true,
			}
		end
		if code == LB2_MAX or code == -LB2_MAX then
			return {
				version = LB2_VERSION,
				code = code,
				band = "infinity",
				negative = code < 0,
				reciprocal = false,
				distanceFromOne = LB2_POSITIVE_SPAN,
				reversible = true,
			}
		end
		local absCode = abs(code)
		return {
			version = LB2_VERSION,
			code = code,
			band = band,
			negative = code < 0,
			reciprocal = absCode < LB2_ONE,
			distanceFromOne = abs(absCode - LB2_ONE),
			reversible = true,
		}
	end

	function NanoFormat.lbquantize(value: any): buffer
		local ok, code = NanoFormat.tryLBEncode(value)
		if not ok then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.lbdecodeV2(code)
	end

	function NanoFormat.lbSameBucket(a: any, b: any): boolean
		local okA, codeA = NanoFormat.tryLBEncode(a)
		local okB, codeB = NanoFormat.tryLBEncode(b)
		return okA and okB and codeA == codeB
	end

	function NanoFormat.lbRoundTripStable(value: any): boolean
		local ok, code = NanoFormat.tryLBEncode(value)
		if not ok then
			return false
		end
		local decoded = NanoFormat.lbdecodeV2(code)
		local ok2, code2 = NanoFormat.tryLBEncode(decoded)
		return ok2 and code2 == code
	end

	function NanoFormat.lbCompare(a: any, b: any): number
		local okA, codeA = NanoFormat.tryLBEncode(a)
		local okB, codeB = NanoFormat.tryLBEncode(b)
		if not okA or not okB then
			return 0 / 0
		end
		if codeA < codeB then
			return -1
		elseif codeA > codeB then
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

	function NanoFormat.ln(value: any): buffer
		return NanoFormat.mul(NanoFormat.log10(value), MATH_LN10)
	end

	function NanoFormat.log(value: any, base: any?): buffer
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

	function NanoFormat.sqrt(value: any): buffer
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

	function NanoFormat.root(value: any, degree: any): buffer
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

	function NanoFormat.min(a: any, b: any): buffer
		local cmp = NanoFormat.compare(a, b)
		if cmp ~= cmp then return makeSpecial(SPECIAL_NAN) end
		return mathCoerce(cmp <= 0 and a or b)
	end

	function NanoFormat.max(a: any, b: any): buffer
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

	function NanoFormat.copySign(value: any, signSource: any): buffer
		local _, data = mathDecode(value)
		local _, source = mathDecode(signSource)

		if data.Kind == "NaN" or data.Kind == "Reserved"
			or source.Kind == "NaN" or source.Kind == "Reserved"
		then
			return makeSpecial(SPECIAL_NAN)
		end

		return mathWithSignData(data, mathSignData(source) < 0)
	end

	function NanoFormat.trunc(value: any): buffer
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

	function NanoFormat.round(value: any, decimals: number?): buffer
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

	function NanoFormat.frac(value: any): buffer
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

	function NanoFormat.mod(a: any, b: any): buffer
		local ai, bi = mathExactModuloInputs(a, b)

		if ai == nil or bi == nil then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.fromNumber(ai % bi)
	end

	function NanoFormat.log2(value: any): buffer
		return NanoFormat.div(NanoFormat.log10(value), MATH_LOG10_2)
	end

	function NanoFormat.exp(value: any): buffer
		return NanoFormat.pow10(NanoFormat.mul(value, MATH_LOG10_E))
	end

	function NanoFormat.exp2(value: any): buffer
		return NanoFormat.pow10(NanoFormat.mul(value, MATH_LOG10_2))
	end

	function NanoFormat.cbrt(value: any): buffer
		return NanoFormat.root(value, 3)
	end

	function NanoFormat.hypot(a: any, b: any): buffer
		local aa = NanoFormat.mul(a, a)
		local bb = NanoFormat.mul(b, b)

		return NanoFormat.sqrt(NanoFormat.add(aa, bb))
	end

	function NanoFormat.lerp(a: any, b: any, t: any): buffer
		return NanoFormat.add(
			a,
			NanoFormat.mul(
				NanoFormat.sub(b, a),
				t
			)
		)
	end

	function NanoFormat.inverseLerp(a: any, b: any, value: any): buffer
		if NanoFormat.eq(a, b) then
			return makeSpecial(SPECIAL_NAN)
		end

		return NanoFormat.div(
			NanoFormat.sub(value, a),
			NanoFormat.sub(b, a)
		)
	end

	function NanoFormat.remap(
		value: any,
		inMin: any,
		inMax: any,
		outMin: any,
		outMax: any
	): buffer
		local t = NanoFormat.inverseLerp(inMin, inMax, value)

		if NanoFormat.isNaN(t) then
			return t
		end

		return NanoFormat.lerp(outMin, outMax, t)
	end

	function NanoFormat.sum(values: {any}): buffer
		local total = NanoFormat.fromNumber(0)

		for i = 1, #values do
			total = NanoFormat.add(total, values[i])
		end

		return total
	end

	function NanoFormat.product(values: {any}): buffer
		local total = NanoFormat.fromNumber(1)

		for i = 1, #values do
			total = NanoFormat.mul(total, values[i])
		end

		return total
	end

	function NanoFormat.mean(values: {any}): buffer
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

	function NanoFormat.permutation(nValue: any, rValue: any): buffer
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

	function NanoFormat.combination(nValue: any, rValue: any): buffer
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

	function NanoFormat.isPositive(value: any): boolean
		return NanoFormat.gt(value, 0)
	end

	function NanoFormat.isNegative(value: any): boolean
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

	function NanoFormat.gcd(a: any, b: any): buffer
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

	function NanoFormat.lcm(a: any, b: any): buffer
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

	function NanoFormat.square(value: any): buffer
		return NanoFormat.mul(value, value)
	end

	function NanoFormat.cube(value: any): buffer
		return NanoFormat.mul(NanoFormat.mul(value, value), value)
	end

	function NanoFormat.expm1(value: any): buffer
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

	function NanoFormat.distance(a: any, b: any): buffer
		return NanoFormat.abs(NanoFormat.sub(a, b))
	end

	function NanoFormat.ratio(a: any, b: any): buffer
		return NanoFormat.div(a, b)
	end

	function NanoFormat.orderOfMagnitude(value: any): buffer
		if NanoFormat.isZero(value) or NanoFormat.isNaN(value) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.floor(NanoFormat.log10(NanoFormat.abs(value)))
	end

	function NanoFormat.digitCount(value: any): buffer
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

	function NanoFormat.clamp01(value: any): buffer
		return NanoFormat.clamp(value, 0, 1)
	end

	function NanoFormat.smoothstep(edge0: any, edge1: any, value: any): buffer
		local t = NanoFormat.clamp01(NanoFormat.inverseLerp(edge0, edge1, value))
		return NanoFormat.mul(
			NanoFormat.mul(t, t),
			NanoFormat.sub(3, NanoFormat.mul(2, t))
		)
	end

	function NanoFormat.smootherstep(edge0: any, edge1: any, value: any): buffer
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

	function NanoFormat.moveTowards(current: any, target: any, maxDelta: any): buffer
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

	function NanoFormat.geometricMean(values: {any}): buffer
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

	function NanoFormat.harmonicMean(values: {any}): buffer
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

	function NanoFormat.arithmeticSeries(first: any, difference: any, countValue: any): buffer
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

	function NanoFormat.geometricSeries(first: any, ratioValue: any, countValue: any): buffer
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

	function NanoFormat.compound(principal: any, rate: any, periods: any): buffer
		return NanoFormat.mul(
			principal,
			NanoFormat.pow(NanoFormat.add(1, rate), periods)
		)
	end

	function NanoFormat.softcap(value: any, start: any, power: any): buffer
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

	function NanoFormat.inverseSoftcap(value: any, start: any, power: any): buffer
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

	function NanoFormat.diminishingReturns(value: any, scale: any): buffer
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

	function NanoFormat.sigmoid(value: any): buffer
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

	function NanoFormat.fmod(a: any, b: any): buffer
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

	function NanoFormat.divmod(a: any, b: any): (buffer, buffer)
		local ai, bi = mathExactModuloInputs(a, b)

		if ai == nil or bi == nil then
			local nan = makeSpecial(SPECIAL_NAN)
			return nan, nan
		end

		local remainder = ai % bi
		local quotient = (ai - remainder) / bi

		return NanoFormat.fromNumber(quotient),	NanoFormat.fromNumber(remainder)
	end

	function NanoFormat.clamp(value: any, low: any, high: any): buffer
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

	function NanoFormat.relativeDifference(a: any, b: any): buffer
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
		a: any,
		b: any,
		relativeTolerance: any?,
		absoluteTolerance: any?
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

	function NanoFormat.factorial(value: any): buffer
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
			return true,negative,(expCode - NORMAL_EXP_BIAS) + log10(mantissa),	false
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

	function NanoFormat.sign(value: any): number
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

	function NanoFormat.neg(value: any): buffer
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

	function NanoFormat.abs(value: any): buffer
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

	function NanoFormat.reciprocal(value: any): buffer
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

	function NanoFormat.log10(value: any): buffer
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

	function NanoFormat.toNumber(value: any): number
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

	function NanoFormat.isNaN(value: any): boolean
		if typeof(value) == "number" then
			return value ~= value
		elseif typeof(value) == "buffer" then
			local raw = bufferReadBits(value, 0, 6)

			return band(raw, 63) == 63
				and bufferReadBits(value, 6, 2) >= SPECIAL_NAN
		end

		return mathSlowIsNaN(value)
	end

	function NanoFormat.isInfinite(value: any): boolean
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

	function NanoFormat.isFinite(value: any): boolean
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

	function NanoFormat.isZero(value: any): boolean
		if typeof(value) == "number" then
			return value == 0
		elseif typeof(value) == "buffer" then
			local raw = bufferReadBits(value, 0, 6)

			return band(raw, 1) == 0
				and bufferReadBits(value, 1, 7) == 0
		end

		return mathSlowIsZero(value)
	end

	function NanoFormat.isInteger(value: any): boolean
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

	function NanoFormat.isOdd(value: any): boolean
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

	function NanoFormat.isEven(value: any): boolean
		if not NanoFormat.isInteger(value) then
			return false
		end

		return not NanoFormat.isOdd(value)
	end

	function NanoFormat.pow10(value: any): buffer
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

	function NanoFormat.floor(value: any): buffer
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

	function NanoFormat.ceil(value: any): buffer
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
		baseCost: any,
		growth: any,
		owned: any,
		amount: any
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
		currency: any,
		baseCost: any,
		growth: any,
		owned: any?
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
		currency: any,
		baseCost: any,
		growth: any,
		owned: any?
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
		baseCost: any,
		growth: any,
		owned: any
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

	function NanoFormat.mathPerfInfo()
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

	function NanoFormat.compile(value: any): buffer
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
		operation: string,
		leftType: string,
		rightType: string
	)
		local operationMap = DIRECT_BINARY[operation]

		if operationMap == nil then
			return nil
		end

		local leftCode = TYPE_CODE[leftType] or leftType
		local rightCode = TYPE_CODE[rightType] or rightType

		return operationMap[leftCode .. rightCode]
	end

	function NanoFormat.bindRight(
		operation: string,
		constant: any,
		leftType: string?
	)
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

	function NanoFormat.add(a: any, b: any): buffer
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

	function NanoFormat.sub(a: any, b: any): buffer
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

	function NanoFormat.mul(a: any, b: any): buffer
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

	function NanoFormat.div(a: any, b: any): buffer
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

	function NanoFormat.compare(a: any, b: any): number
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

	function NanoFormat.pow(a: any, b: any): buffer
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

	function NanoFormat.eq(a: any, b: any): boolean
		return NanoFormat.compare(a, b) == 0
	end

	function NanoFormat.lt(a: any, b: any): boolean
		return NanoFormat.compare(a, b) < 0
	end

	function NanoFormat.lte(a: any, b: any): boolean
		return NanoFormat.compare(a, b) <= 0
	end

	function NanoFormat.gt(a: any, b: any): boolean
		return NanoFormat.compare(a, b) > 0
	end

	function NanoFormat.gte(a: any, b: any): boolean
		return NanoFormat.compare(a, b) >= 0
	end

	function NanoFormat.callPerfInfo()
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

	function NanoFormat.log1p(value: any): buffer
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

	function NanoFormat.inverseDiminishingReturns(value: any, scale: any): buffer
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

	function NanoFormat.logit(value: any): buffer
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

	function NanoFormat.powInt(base: any, exponent: any): buffer
		if not NanoFormat.isInteger(exponent) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.pow(base, exponent)
	end

	function NanoFormat.iteratedExp10(value: any, timesValue: any): buffer
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

	function NanoFormat.iteratedLog10(value: any, timesValue: any): buffer
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

	function NanoFormat.tetrate10(heightValue: any, payload: any?): buffer
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
		baseValue: any,
		heightValue: any,
		payload: any?
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
		baseValue: any,
		heightValue: any,
		payload: any?
	): buffer
		local height = mathV7FiniteScalar(heightValue)
		if height == nil or height < 0 or height ~= floor(height) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.tetrate(baseValue, height, payload)
	end

	function NanoFormat.tetrate10Integer(heightValue: any, payload: any?): buffer
		local height = mathV7FiniteScalar(heightValue)
		if height == nil or height < 0 or height ~= floor(height) then
			return makeSpecial(SPECIAL_NAN)
		end
		return NanoFormat.tetrate10(height, payload)
	end

	function NanoFormat.slog10(value: any): buffer
		if NanoFormat.isNaN(value) or NanoFormat.lt(value, 0) then
			return makeSpecial(SPECIAL_NAN)
		elseif NanoFormat.isZero(value) then
			return NanoFormat.fromNumber(-1)
		end
		return mathV7OldSlog10(value)
	end

	function NanoFormat.slog(value: any, baseValue: any?): buffer
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

	function NanoFormat.gammaSign(value: any): number
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

	function NanoFormat.logGamma(value: any): buffer
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

	function NanoFormat.gamma(value: any): buffer
		local sign = NanoFormat.gammaSign(value)
		if sign ~= sign or sign == 0 then
			return makeSpecial(SPECIAL_NAN)
		end

		local magnitude = NanoFormat.exp(NanoFormat.logGamma(value))
		return sign < 0 and NanoFormat.neg(magnitude) or magnitude
	end

	function NanoFormat.factorialReal(value: any): buffer
		return NanoFormat.gamma(NanoFormat.add(value, 1))
	end

	function NanoFormat.betaSign(a: any, b: any): number
		local sa = NanoFormat.gammaSign(a)
		local sb = NanoFormat.gammaSign(b)
		local sum = NanoFormat.add(a, b)
		local ss = NanoFormat.gammaSign(sum)
		if sa ~= sa or sb ~= sb or ss ~= ss or sa == 0 or sb == 0 or ss == 0 then
			return MATH_NAN
		end
		return sa * sb * ss
	end

	function NanoFormat.logBeta(a: any, b: any): buffer
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

	function NanoFormat.beta(a: any, b: any): buffer
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

NanoFormat.LBEncode = NanoFormat.lbencode
NanoFormat.LBDecode = NanoFormat.lbdecode
NanoFormat.LBEncodeV1 = NanoFormat.lbencodeV1
NanoFormat.LBDecodeV1 = NanoFormat.lbdecodeV1
NanoFormat.LBEncodeV2 = NanoFormat.lbencodeV2
NanoFormat.LBDecodeV2 = NanoFormat.lbdecodeV2
NanoFormat.LBCompare = NanoFormat.lbCompare
NanoFormat.LBRoundTripStable = NanoFormat.lbRoundTripStable

return NanoFormat
