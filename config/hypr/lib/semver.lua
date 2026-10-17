-- semver.lua — minimal semver-range evaluator, mirror of scripts/plugins_compat.sh.
--
-- Kept in lockstep with the bash evaluator (see fixtures/compat-vectors.json
-- and scripts/test.sh, which run BOTH against the same vectors). Used by the
-- Hyprland-side plugin loader (config/hypr/plugins.lua) to enforce `compat`.
--
-- Supported range syntax (space/comma = AND):
--   >=1.0  >1.0  <=2.0  <2.0  =1.2.3  1.2.3   ^1.2.0   ~1.2.0
-- `^` = same major and >= v.  `~` = same major.minor and >= v.

local M = {}

local function parse(v)
    local out = {}
    for n in tostring(v):gmatch("%d+") do out[#out + 1] = tonumber(n) end
    return out
end

-- -1, 0, 1
local function cmp(a, b)
    local pa, pb = parse(a), parse(b)
    local n = math.max(#pa, #pb)
    for i = 1, n do
        local x, y = pa[i] or 0, pb[i] or 0
        if x < y then return -1 end
        if x > y then return 1 end
    end
    return 0
end

local function valid_version(v)
    v = tostring(v)
    if v == "" then return false end
    for seg in (v .. "."):gmatch("([^.]*)%.") do
        if seg == "" or not seg:match("^%d+$") then return false end
    end
    return true
end

-- @return 0 satisfied, 1 violated, 2 unparsable
function M.satisfies(ver, range)
    if not range or range == "" then return 0 end
    range = range:gsub(",", " ")
    for part in range:gmatch("%S+") do
        local op = part:match("^(>=)")
            or part:match("^(<=)")
            or part:match("^(>)")
            or part:match("^(<)")
            or part:match("^(=)")
            or part:match("^(%^)")
            or part:match("^(~)")
            or "="
        local v = part:sub(#op + 1)
        if v == "" then return 2 end
        if not valid_version(v) then return 2 end
        local c = cmp(ver, v)
        if op == ">=" then
            if c < 0 then return 1 end
        elseif op == "<=" then
            if c > 0 then return 1 end
        elseif op == ">" then
            if c <= 0 then return 1 end
        elseif op == "<" then
            if c >= 0 then return 1 end
        elseif op == "=" then
            if c ~= 0 then return 1 end
        elseif op == "~" then
            if ver:match("^(%d+%.%d+)") ~= v:match("^(%d+%.%d+)") then return 1 end
            if c < 0 then return 1 end
        elseif op == "^" then
            if ver:match("^(%d+)") ~= v:match("^(%d+)") then return 1 end
            if c < 0 then return 1 end
        end
    end
    return 0
end

return M
