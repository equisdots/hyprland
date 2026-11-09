-- monitor_layout_test.lua — unit tests for config/hypr/lib/monitor-layout.lua.
--
-- Run from the repo root: lua5.5 tests/monitor_layout_test.lua (tests/run.sh).
-- Uses plain Lua only: the library must stay free of hl.* / io so the parser
-- can be validated without a compositor.

local layout = dofile("config/hypr/lib/monitor-layout.lua")

local passed, failed = 0, 0
local function ok(cond, name)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write("FAIL: " .. name .. "\n")
    end
end

local function eq(a, b, name)
    ok(a == b, name .. " (got " .. tostring(a) .. ", want " .. tostring(b) .. ")")
end

-- ── mode_from_settings ────────────────────────────────────────────────────────
eq(layout.mode_from_settings(nil), "static", "missing settings -> static")
eq(layout.mode_from_settings("{}"), "static", "empty object -> static")
eq(layout.mode_from_settings('{"monitorsMode":"off"}'), "off", "off recognized")
eq(layout.mode_from_settings('{\n  "monitorsMode": "reconciler",\n  "x": 1\n}'), "reconciler",
   "pretty JSON + spaces recognized")
eq(layout.mode_from_settings('{"monitorsMode":"bogus"}'), "static", "invalid -> static")
eq(layout.mode_from_settings('{"other":"offscreen"}'), "static", "substring is not a mode")

-- ── parse_line: legacy 5-field format ─────────────────────────────────────────
local legacy = layout.parse_line("Chimei Innolux 0x150C|0|0|1|1920x1080@60")
ok(legacy ~= nil, "legacy line parses")
eq(legacy.desc, "Chimei Innolux 0x150C", "legacy desc")
eq(legacy.x, 0, "legacy x")
eq(legacy.y, 0, "legacy y")
eq(legacy.scale, 1, "legacy scale")
eq(legacy.mode, "1920x1080@60", "legacy mode")
eq(legacy.transform, 0, "legacy transform default")
eq(legacy.vrr, 0, "legacy vrr default")
eq(legacy.bitdepth, 8, "legacy bitdepth default")
eq(legacy.cm, nil, "legacy cm default")
eq(legacy.mirror, nil, "legacy mirror default")
eq(legacy.disabled, false, "legacy disabled default")

-- ── parse_line: extended fields ───────────────────────────────────────────────
local full = layout.parse_line("AU Optronics B156HAN15.H|-1920|1080|0.75|1920x1080@144.06Hz|3|2|10|srgb|Other Screen|0")
ok(full ~= nil, "extended line parses")
eq(full.desc, "AU Optronics B156HAN15.H", "extended desc")
eq(full.x, -1920, "negative x")
eq(full.y, 1080, "extended y")
eq(full.scale, 0.75, "fractional scale")
eq(full.transform, 3, "transform")
eq(full.vrr, 2, "vrr")
eq(full.bitdepth, 10, "bitdepth")
eq(full.cm, "srgb", "cm")
eq(full.mirror, "Other Screen", "mirror")

local disabled = layout.parse_line("Screen|0|0|1|1920x1080@60|0|0|8|auto||1")
ok(disabled ~= nil and disabled.disabled == true, "disabled=1 parsed")

-- ── parse_line: comments, blanks and unusable lines ───────────────────────────
eq(layout.parse_line(""), nil, "blank skipped")
eq(layout.parse_line("   "), nil, "spaces skipped")
eq(layout.parse_line("# desc|x|y"), nil, "comment skipped")
eq(layout.parse_line("only-a-desc"), nil, "missing columns skipped")
eq(layout.parse_line("Screen|x|0|1|mode"), nil, "bad x skipped")
eq(layout.parse_line("Screen|0|0|0|mode"), nil, "non-positive scale skipped")
eq(layout.parse_line("Screen|0|0|abc|mode"), nil, "non-numeric scale skipped")

local clamped = layout.parse_line("Screen|0|0|1|mode|99|9|7|")
eq(clamped.transform, 0, "out-of-range transform clamps")
eq(clamped.vrr, 0, "out-of-range vrr clamps")
eq(clamped.bitdepth, 8, "unknown bitdepth falls back to 8")

-- ── parse_display_config ──────────────────────────────────────────────────────
local rules = layout.parse_display_config([[
# Monitor layout: desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled
# comment
A|0|0|1|1920x1080@60
B|1920|0|1|1920x1080@60|0|0|8|srgb||0
bad-line
C|x|0|1|mode
]])
eq(#rules, 2, "only valid lines collected")
eq(rules[1].desc, "A", "first rule desc")
eq(rules[2].desc, "B", "second rule desc")

-- ── monitor_rule ──────────────────────────────────────────────────────────────
local rule = layout.monitor_rule(layout.parse_line("A|0|0|0.75|1920x1080@144.06Hz|0|0|8|srgb||0"))
eq(rule.output, "desc:A", "monitor_rule output")
eq(rule.mode, "1920x1080@144.06Hz", "monitor_rule mode")
eq(rule.position, "0x0", "monitor_rule position")
eq(rule.scale, 0.75, "monitor_rule scale")
eq(rule.transform, nil, "monitor_rule omits zero transform")
eq(rule.vrr, nil, "monitor_rule omits zero vrr")
eq(rule.bitdepth, nil, "monitor_rule omits 8-bit")
eq(rule.cm, "srgb", "monitor_rule cm")
eq(rule.mirror, nil, "monitor_rule omits empty mirror")

local high = layout.monitor_rule(layout.parse_line("B|1920|-1080|1|1920x1080@60|1|2|10|auto|A|0"))
eq(high.position, "1920x-1080", "monitor_rule negative position")
eq(high.transform, 1, "monitor_rule transform")
eq(high.vrr, 2, "monitor_rule vrr")
eq(high.bitdepth, 10, "monitor_rule bitdepth")
eq(high.cm, nil, "monitor_rule omits auto cm")
eq(high.mirror, "desc:A", "monitor_rule mirror desc")

local off = layout.monitor_rule(layout.parse_line("C|0|0|1|1920x1080@60|0|0|8|auto||1"))
eq(off.output, "desc:C", "disabled rule output")
eq(off.disabled, true, "disabled rule flag")
eq(off.mode, nil, "disabled rule omits mode")
eq(off.position, nil, "disabled rule omits position")
eq(off.scale, nil, "disabled rule omits scale")

local empty_mode = layout.monitor_rule(layout.parse_line("D|0|0|1||0|0|8|auto||0"))
eq(empty_mode.mode, "highrr", "empty mode falls back to highrr")

-- ── summary ───────────────────────────────────────────────────────────────────
if failed > 0 then
    io.stderr:write(string.format("%d passed, %d FAILED\n", passed, failed))
    os.exit(1)
end
io.write(string.format("monitor-layout: %d checks OK\n", passed))
