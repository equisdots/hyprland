-- settings_version_gate_test.lua — unit test for the Hyprland 0.57 gates in
-- config/hypr/settings.lua, without a compositor.
--
-- It stubs `hl` (version/config/gesture) and `colors`, loads settings.lua twice
-- and asserts the branch chosen for 0.56 vs 0.57:
--   · 0.57+: layers.layers_hog_keyboard_focus, no misc key, no special_scale_factor.
--   · 0.56 : misc.layers_hog_keyboard_focus and both special_scale_factor keys.
--
-- Usage: lua5.5 tests/settings_version_gate_test.lua   (from the repo root)

local script = (arg and arg[0]) or "tests/settings_version_gate_test.lua"
local dir = script:match("^(.*)[/\\][^/\\]+$") or "."
local root = dir .. "/.."

package.path = root .. "/config/hypr/?.lua;" .. root .. "/config/hypr/?/init.lua;" .. package.path
package.loaded["colors"] = {
    active_border   = "rgba(ffffffff)",
    inactive_border = "rgba(888888ff)",
}

local calls = {}
local VERSION = "0.57.0"

hl = {
    version = function() return VERSION end,
    config  = function(t) calls[#calls + 1] = t end,
    gesture = function(t) calls[#calls + 1] = { gesture = t } end,
}

local function load_settings(version)
    VERSION = version
    calls = {}
    dofile(root .. "/config/hypr/settings.lua")
end

local function find(path, expected)
    for _, call in ipairs(calls) do
        local cur = call
        for part in path:gmatch("[^.]+") do
            if type(cur) ~= "table" then cur = nil; break end
            cur = cur[part]
        end
        if cur ~= nil and (expected == nil or cur == expected) then
            return true
        end
    end
    return false
end

local fail = 0
local function check(ok, label)
    if ok then
        print(" ok   " .. label)
    else
        print(" FAIL " .. label)
        fail = 1
    end
end

load_settings("0.57.0")
check(find("layers.layers_hog_keyboard_focus", true), "0.57 uses layers.layers_hog_keyboard_focus")
check(not find("misc.layers_hog_keyboard_focus"), "0.57 does not set the deprecated misc key")
check(not find("dwindle.special_scale_factor"), "0.57 does not set dwindle.special_scale_factor")
check(not find("master.special_scale_factor"), "0.57 does not set master.special_scale_factor")

load_settings("0.56.2")
check(find("misc.layers_hog_keyboard_focus", true), "0.56 keeps misc.layers_hog_keyboard_focus")
check(not find("layers.layers_hog_keyboard_focus"), "0.56 does not use the 0.57 layers key")
check(find("dwindle.special_scale_factor", 0.85), "0.56 keeps dwindle.special_scale_factor")
check(find("master.special_scale_factor", 0.85), "0.56 keeps master.special_scale_factor")

if fail == 0 then
    print("SETTINGS VERSION GATE: OK")
end
os.exit(fail)
