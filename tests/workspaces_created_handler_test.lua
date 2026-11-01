-- workspaces_created_handler_test.lua — unit test for the scratchpad launch
-- path in config/hypr/workspaces.lua, without a compositor.
--
-- 0.57+ must use workspace.created + is_empty (on_created_empty is deprecated);
-- 0.56 must keep the old on_created_empty rule key.
--
-- Usage: lua5.5 tests/workspaces_created_handler_test.lua   (from the repo root)

local script = (arg and arg[0]) or "tests/workspaces_created_handler_test.lua"
local dir = script:match("^(.*)[/\\][^/\\]+$") or "."
local root = dir .. "/.."

package.path = root .. "/config/hypr/?.lua;" .. root .. "/config/hypr/?/init.lua;" .. package.path

local calls
local VERSION = "0.57.0"

local function fresh_hl()
    calls = { rules = {}, events = {}, exec = {} }
    hl = {
        version = function() return VERSION end,
        config = function() end,
        workspace_rule = function(t) calls.rules[#calls.rules + 1] = t end,
        on = function(event, fn) calls.events[event] = fn end,
        exec_cmd = function(cmd) calls.exec[#calls.exec + 1] = cmd end,
    }
end

local function load(version)
    VERSION = version
    fresh_hl()
    dofile(root .. "/config/hypr/workspaces.lua")
end

local function rule_for(name)
    for _, rule in ipairs(calls.rules) do
        if rule.workspace == "special:" .. name then return rule end
    end
    return nil
end

local function special_rule_count()
    local n = 0
    for _, rule in ipairs(calls.rules) do
        if tostring(rule.workspace):match("^special:") then n = n + 1 end
    end
    return n
end

local function executed(cmd)
    for _, v in ipairs(calls.exec) do
        if v == cmd then return true end
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

-- ── 0.57: event handler, no deprecated rule key ─────────────────────────────
load("0.57.0")
local handler = calls.events["workspace.created"]
check(type(handler) == "function", "0.57 registers workspace.created")
check(special_rule_count() == 3, "0.57 registers three scratchpad workspace rules")
check(rule_for("terminal") ~= nil and rule_for("files") ~= nil and rule_for("music") ~= nil,
      "0.57 keeps all three named rules")
check(rule_for("terminal").on_created_empty == nil and
      rule_for("files").on_created_empty == nil and
      rule_for("music").on_created_empty == nil,
      "0.57 does not set the deprecated on_created_empty key")

if handler then
    handler({ special = true, name = "special:files", is_empty = true })
    check(executed("nautilus"), "files scratchpad launches nautilus")
    calls.exec = {}
    handler({ special = true, name = "special:terminal", is_empty = true })
    check(executed("kitty --class scratchpad-terminal"), "terminal scratchpad launches kitty")
    calls.exec = {}
    handler({ special = true, name = "special:music", is_empty = true })
    check(executed("spotify"), "music scratchpad launches spotify")
    calls.exec = {}
    handler({ special = true, name = "files", is_empty = true })
    check(executed("nautilus"), "unprefixed special name still matches")
    calls.exec = {}
    handler({ special = true, name = "special:files", is_empty = false })
    check(#calls.exec == 0, "non-empty special workspace does not launch")
    handler({ special = false, name = "2", is_empty = true })
    check(#calls.exec == 0, "normal workspace does not launch")
end

-- ── 0.56: old rule key, no event handler ────────────────────────────────────
load("0.56.2")
check(calls.events["workspace.created"] == nil, "0.56 does not register workspace.created")
check(rule_for("terminal") ~= nil and rule_for("terminal").on_created_empty == "kitty --class scratchpad-terminal",
      "0.56 terminal rule keeps on_created_empty")
check(rule_for("files") ~= nil and rule_for("files").on_created_empty == "nautilus",
      "0.56 files rule keeps on_created_empty")
check(rule_for("music") ~= nil and rule_for("music").on_created_empty == "spotify",
      "0.56 music rule keeps on_created_empty")

if fail == 0 then
    print("WORKSPACES CREATED HANDLER: OK")
end
os.exit(fail)
