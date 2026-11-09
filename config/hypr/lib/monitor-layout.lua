-- monitor-layout.lua — pure parser for ~/.config/hypr/display-config and the
-- `monitorsMode` setting.
--
-- No hl.* and no io: the config side (monitors.lua) does the file reading and
-- the tests can run this module standalone with plain Lua.
--
-- Format written by scripts/persist-display-config.sh:
--   desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled
-- Fields 6-11 are optional: older 5-field files keep working with the defaults
-- (0, 0, 8, auto, "", 0). Blank lines and '#' comments are ignored.

local M = {}

M.DEFAULT_MODE = "static"

local VALID_MODES = {
    static = true,     -- rules applied by monitors.lua at config load
    reconciler = true, -- rules + the legacy restore-monitors.sh poller
    off = true,        -- wildcard/auto layout only
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function number(s)
    return tonumber(trim(s))
end

local function integer(s)
    local n = tonumber(trim(s))
    if not n or n ~= math.floor(n) then return nil end
    return math.floor(n)
end

local function boolean(s)
    s = trim(s):lower()
    return s == "1" or s == "true" or s == "yes" or s == "on"
end

-- "static" (default) | "reconciler" | "off"
function M.mode_from_settings(text)
    if type(text) ~= "string" then return M.DEFAULT_MODE end
    local mode = text:match('"monitorsMode"%s*:%s*"([%w_%-]+)"')
    if mode and VALID_MODES[mode] then return mode end
    return M.DEFAULT_MODE
end

-- Parse one non-comment line. Returns nil when the line is unusable (a
-- partially written or hand-edited file must never produce bad rules).
function M.parse_line(line)
    line = trim(line)
    if line == "" or line:sub(1, 1) == "#" then return nil end

    local fields = {}
    for field in (line .. "|"):gmatch("([^|]*)|") do
        fields[#fields + 1] = field
    end

    local desc = trim(fields[1])
    local x = integer(fields[2])
    local y = integer(fields[3])
    local scale = number(fields[4])
    if desc == "" or x == nil or y == nil or scale == nil or scale <= 0 then return nil end

    local mode = trim(fields[5])
    local transform = integer(fields[6]) or 0
    local vrr = integer(fields[7]) or 0
    local bitdepth = integer(fields[8]) or 8
    local cm = trim(fields[9])
    local mirror = trim(fields[10])
    local disabled = boolean(fields[11])

    if transform < 0 or transform > 7 then transform = 0 end
    if vrr < -1 or vrr > 3 then vrr = 0 end
    if bitdepth ~= 10 then bitdepth = 8 end

    return {
        desc = desc,
        x = x,
        y = y,
        scale = scale,
        mode = mode ~= "" and mode or nil,
        transform = transform,
        vrr = vrr,
        bitdepth = bitdepth,
        cm = cm ~= "" and cm or nil,
        mirror = mirror ~= "" and mirror or nil,
        disabled = disabled,
    }
end

function M.parse_display_config(text)
    local rules = {}
    if type(text) ~= "string" then return rules end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local rule = M.parse_line(line)
        if rule then rules[#rules + 1] = rule end
    end
    return rules
end

-- Table for hl.monitor(). A disabled screen only carries `disabled`: applying
-- mode/position/scale to it is meaningless and can fight the compositor.
function M.monitor_rule(rule)
    local out = { output = "desc:" .. rule.desc }
    if rule.disabled then
        out.disabled = true
        return out
    end
    out.mode = rule.mode or "highrr"
    out.position = tostring(rule.x) .. "x" .. tostring(rule.y)
    out.scale = rule.scale
    if rule.transform ~= 0 then out.transform = rule.transform end
    if rule.vrr ~= 0 then out.vrr = rule.vrr end
    if rule.bitdepth ~= 8 then out.bitdepth = rule.bitdepth end
    if rule.cm and rule.cm ~= "auto" then out.cm = rule.cm end
    if rule.mirror then out.mirror = "desc:" .. rule.mirror end
    return out
end

return M
