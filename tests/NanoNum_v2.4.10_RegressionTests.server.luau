--!strict
-- NanoNum v2.4.11 regression suite. Run as a Script in Roblox Studio.
-- Place NanoNum_v2.4.11 (ModuleScript) beside this Script.
local N = require(script.Parent:WaitForChild("NanoNum_v2.4.11"))
local passed = 0
local failed = 0

local function check(name: string, condition: boolean)
    if condition then passed += 1; print("PASS", name)
    else failed += 1; warn("FAIL", name) end
end

local function near(actual: number, expected: number, tolerance: number): boolean
    return actual == actual and math.abs(actual - expected) <= tolerance * math.max(1, math.abs(expected))
end

check("version", string.find(N.VERSION, "2.4.11", 1, true) ~= nil)
check("binary format compatible", N.BINARY_FORMAT_VERSION == 6)
check("leaderboard version", N.LB_VERSION == 3)

-- Buffer and ordinary arithmetic
for _, x in {-100, -2.25, -1, 0, 0.5, 1, 127, 128, 123456.625} do
    local b = N.fromNumber(x)
    check("finite buffer " .. tostring(x), N.isValid(b) and near(N.toNumber(b), x, 1e-13))
end
check("add", near(N.toNumber(N.add(1.2, 3.4)), 4.6, 1e-13))
check("sub", near(N.toNumber(N.sub(9.5, 2.5)), 7, 1e-13))
check("mul", near(N.toNumber(N.mul(2.5, 4)), 10, 1e-13))
check("div", near(N.toNumber(N.div(7, 2)), 3.5, 1e-13))
check("negative pow integer", near(N.toNumber(N.pow(-2, 3)), -8, 1e-13))
check("negative pow fractional is NaN", N.isNaN(N.pow(-2, 0.5)))
check("sqrt", near(N.toNumber(N.sqrt(81)), 9, 1e-13))
check("cbrt negative", near(N.toNumber(N.cbrt(-27)), -3, 1e-10))
check("fractional part signed", near(N.toNumber(N.frac(-2.25)), -0.25, 1e-13))
check("mod Euclidean", near(N.toNumber(N.mod(-7, 3)), 2, 1e-13))
check("fmod sign", near(N.toNumber(N.fmod(-7, 3)), -1, 1e-13))
check("floor negative", near(N.toNumber(N.floor(-0.125)), -1, 1e-13))
check("ceil negative", near(N.toNumber(N.ceil(-0.125)), 0, 1e-13))
check("trunc negative", near(N.toNumber(N.trunc(-0.125)), 0, 1e-13))
check("huge scientific buffer", N.isValid(N.fromString("2e1053")))
check("preserved scientific coefficient", N.format(N.fromString("2e1053"), 2, "scientific") == "2e1053")
check("preserved negative coefficient", N.format(N.fromString("-2e1053"), 2, "scientific") == "-2e1053")
check("preserved scientific fractional", N.format(N.fromString("2.5e1053"), 2, "scientific") == "2.5e1053")
check("scientific number compares", N.gt(N.fromString("2e1053"), N.fromString("1e1053")))
check("invalid buffer rejected", not N.isValid(buffer.create(0)))

-- Guarded APIs should return false without throwing on erroneous inputs.
local ok, good, b = pcall(N.tryMath, "add", 2, 3)
check("tryMath success", ok and good == true and near(N.toNumber(b), 5, 1e-13))
local okBad, goodBad = pcall(N.tryMath, "pow", -2, 0.5)
check("tryMath NaN fails safely", okBad and goodBad == false)
local okInvalid, goodInvalid = pcall(N.tryLBEncode, "not-a-number")
check("tryLBEncode invalid string fails safely", okInvalid and goodInvalid == false)
local okEmpty, goodEmpty = pcall(N.tryLBEncode, buffer.create(0))
check("tryLBEncode empty buffer fails safely", okEmpty and goodEmpty == false)

-- Packing: the explicitly provided bit count must be consumed exactly.
local values = {N.fromNumber(1), N.fromNumber(-2), N.fromString("2e1053")}
local packed, bits = N.packMany(values)
local unpacked = N.unpackMany(packed, 3, bits)
check("packed count", #unpacked == 3)
check("packed value 1", N.eq(unpacked[1], values[1]))
check("packed value 2", N.eq(unpacked[2], values[2]))
check("packed value 3", N.eq(unpacked[3], values[3]))
local okShort = pcall(N.unpackMany, packed, 2, bits)
check("truncated count rejected", not okShort)
local guardedOk, guardedResult = N.tryUnpackMany(packed, 2, bits)
check("guarded truncated count rejected", not guardedOk and guardedResult == nil)

-- The OrderedDataStore codec is quantized: check idempotence, not exact equality.
for _, value in {0, 0.5, 1, 2, 100, -0.25, -100, 1e20} do
    local code = N.lbencode(value)
    local restored = N.lbdecode(code)
    check("LB valid " .. tostring(value), N.isLBCode(code))
    check("LB stable " .. tostring(value), N.lbencode(restored) == code)
end

-- Exact decimal arithmetic is separate from the approximate binary buffer.
local a = N.fromStringExact("0.1")
local c = N.fromStringExact("0.2")
check("exact addition", N.formatExact(N.addExact(a, c), 3) == "3.000e-1")
local zero = N.fromStringExact("0")
local exactInput = N.fromStringExact("1.25")
local combinedLeft = N.addExact(zero, exactInput)
local combinedRight = N.addExact(exactInput, zero)
check("exact add zero maintains value", N.compareExact(combinedLeft, exactInput) == 0 and N.compareExact(combinedRight, exactInput) == 0)
check("exact add zero does not mutate input flags", zero.Approximate ~= true and exactInput.Approximate ~= true)
combinedLeft.Approximate = true
check("exact add does not alias operand", exactInput.Approximate ~= true)

check("exact multiplication", N.formatExact(N.mulExact(N.fromStringExact("12.5"), N.fromStringExact("8")), 2) == "1.00e2")
local quotient = N.divExact(N.fromStringExact("1"), N.fromStringExact("8"), 20)
check("exact terminating division", N.formatExact(quotient, 3) == "1.250e-1" and not quotient.Approximate)
check("repeating division marked approximate", N.divExact(N.fromStringExact("1"), N.fromStringExact("3"), 10).Approximate == true)

-- Formatter regressions
check("clock over one day", N.formatClock(2354235, 2) == "27d 05:57:15.00")
check("invalid time precision", N.formatTime(1, "clock", math.huge) == "NaN")
check("invalid byte precision", N.formatBytes(1024, math.huge, true) == "NaN")

print(string.format("NanoNum v2.4.11 regression suite: %d passed, %d failed", passed, failed))
if failed > 0 then error(string.format("NanoNum v2.4.11: %d regression tests failed", failed)) end
