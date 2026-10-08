# NanoNum v2.4.10 — Bug-fix candidate

Base: the user's v2.4.9 Luau module (8,960 lines). This candidate preserves the standalone `ModuleScript`, v6 binary buffer format, and LB3 leaderboard encoding format. Existing function names are retained.

## Corrections

- **Scientific display precision:** Strings such as `2e1053`, `-2e1053`, and `2.5e1053` preserve their entered mantissa for *direct formatting* instead of reconstructing it from a rounded log10 coordinate. The weak-key sidecar does **not** make subsequent arithmetic, serialization, or reconstructed buffers exact; use `fromStringExact` for exact decimal calculations.
- **Packed-stream boundary validation:** `unpackMany(packed, count, totalBits)` now rejects a mismatched explicit `count` and `totalBits`. Without `totalBits`, prefix decoding retains its prior behavior, including skipping byte-padding checks.
- **Nonthrowing LB encoding:** `tryLBEncode` guards both coercion and encoding against malformed values.
- **Nonthrowing math:** `tryMath` returns `false, nil` on NaN results, matching the failure behavior of `tryCompile`. The ordinary operations themselves still return encoded NaN when appropriate.
- **Time and byte formatting:** Invalid nonfinite precision (and invalid nonfinite maxParts for `formatTime`) now produces `"NaN"` instead of constructing an invalid format specification.

## Test procedure

1. In Roblox Studio, place the source in a ModuleScript named `NanoNum_v2.4.10`.
2. Place `NanoNum_v2.4.10_RegressionTests.server.luau` in a sibling Script.
3. Run Studio and check the Output window. The script prints each `PASS` or `FAIL`, a final count, and throws when checks fail.
4. Before replacing production code, run existing save/load compatibility tests and compare a baseline performance benchmark with the new build.

**Validation status:** Static source checks were performed locally. Native Roblox Studio Luau execution and performance measurements were **not** available here; no runtime correctness or speedup claims are made.
