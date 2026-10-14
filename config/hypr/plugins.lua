-- ═══════════════════════════════════════════════════════════════════════════
-- plugins.lua — equisdots plugin loader (Hyprland side).
--
-- Discovers installed plugins (standard: equisdots/plugins docs/plugins.md)
-- and evaluates the enabled ones' hypr.lua fragments with an injected SDK.
--
-- Registry folders:
--   ~/.config/hypr/plugins/<id>/       managed by dots (rsync)
--   ~/.config/hypr/plugins-user/<id>/  user-owned; wins on id collisions
--
-- Enablement: settings.json — the manifest's "toggle" path when present, or
-- plugins.<id>.enabled by default; a missing key falls back to the manifest's
-- "defaultEnabled" (default false).
--
-- A failing plugin never aborts the config: every fragment runs under pcall
-- and the outcome is written to ~/.cache/equisdots/plugins-report.json for
-- the shell/CLI to surface.
--
-- Test overrides: EQUISDOTS_PLUGINS_DIR, EQUISDOTS_PLUGINS_USER,
-- EQUISDOTS_SETTINGS, EQUISDOTS_PLUGINS_REPORT.
-- ═══════════════════════════════════════════════════════════════════════════

local json = require("lib.json")

local M = {}

local function env(name, fallback)
    local v = os.getenv(name)
    if v == nil or v == "" then
        return fallback
    end
    return v
end

local home = env("HOME", "/")
local config_dir = env("XDG_CONFIG_HOME", home .. "/.config")
local cache_dir = env("XDG_CACHE_HOME", home .. "/.cache")

local MANAGED_DIR = env("EQUISDOTS_PLUGINS_DIR", config_dir .. "/hypr/plugins")
local USER_DIR = env("EQUISDOTS_PLUGINS_USER", config_dir .. "/hypr/plugins-user")
local SETTINGS_PATH = env("EQUISDOTS_SETTINGS", config_dir .. "/hypr/settings.json")
local REPORT_PATH = env("EQUISDOTS_PLUGINS_REPORT", cache_dir .. "/equisdots/plugins-report.json")

local function list_dirs(base)
    local dirs = {}
    if not base or base == "" then
        return dirs
    end
    local p = io.popen("find '" .. base .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null")
    if not p then
        return dirs
    end
    local out = p:read("*a") or ""
    p:close()
    for line in out:gmatch("[^\n]+") do
        dirs[#dirs + 1] = line
    end
    return dirs
end

local function read_manifest(dir)
    local data, err = json.decode_file(dir .. "/plugin.json")
    if type(data) ~= "table" or type(data.id) ~= "string" or data.id == "" then
        return nil, err or "manifest has no id"
    end
    return data
end

local function resolve_enabled(manifest, settings)
    local toggle = manifest.toggle
    if type(toggle) ~= "string" or toggle == "" then
        toggle = "plugins." .. manifest.id .. ".enabled"
    end
    local cur = settings
    for part in toggle:gmatch("[^.]+") do
        if type(cur) ~= "table" or cur[part] == nil then
            return manifest.defaultEnabled == true, toggle
        end
        cur = cur[part]
    end
    if type(cur) == "boolean" then
        return cur, toggle
    end
    return manifest.defaultEnabled == true, toggle
end

-- ── SDK (injected into each fragment as `...`) ───────────────────────────
local function make_sdk(manifest, dir, report)
    local hl_ = hl
    local sdk = {
        id = manifest.id,
        dir = dir,
    }

    function sdk.script(name)
        return dir .. "/scripts/" .. tostring(name)
    end

    function sdk.exec(cmd)
        return hl_.dsp.exec_cmd(tostring(cmd))
    end

    function sdk.bind(key, dispatcher, opts)
        local clean
        local label
        if type(opts) == "table" then
            label = opts.label
            clean = {}
            for k, v in pairs(opts) do
                if k ~= "label" then
                    clean[k] = v
                end
            end
            if next(clean) == nil then
                clean = nil
            end
        end
        if clean ~= nil then
            hl_.bind(key, dispatcher, clean)
        else
            hl_.bind(key, dispatcher)
        end
        report.binds[#report.binds + 1] = {
            key = tostring(key),
            label = tostring(label or key),
        }
    end

    function sdk.log(msg)
        report.logs[#report.logs + 1] = tostring(msg)
    end

    return sdk
end

-- ── report (~/.cache/equisdots/plugins-report.json) ─────────────────────
local function esc(s)
    s = tostring(s or "")
    s = s:gsub("[\\\"]", "\\%0")
    s = s:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return s
end

local function report_json(results)
    local out = {}
    for _, r in ipairs(results) do
        local fields = {
            '"id":"' .. esc(r.id) .. '"',
            '"status":"' .. esc(r.status) .. '"',
            '"dir":"' .. esc(r.dir) .. '"',
            '"toggle":"' .. esc(r.toggle) .. '"',
            '"enabled":' .. tostring(r.enabled == true),
        }
        if r.error then
            fields[#fields + 1] = '"error":"' .. esc(r.error) .. '"'
        end
        if r.binds and #r.binds > 0 then
            local bs = {}
            for _, b in ipairs(r.binds) do
                bs[#bs + 1] = '{"key":"' .. esc(b.key) .. '","label":"' .. esc(b.label) .. '"}'
            end
            fields[#fields + 1] = '"binds":[' .. table.concat(bs, ",") .. ']'
        end
        if r.logs and #r.logs > 0 then
            local ls = {}
            for _, l in ipairs(r.logs) do
                ls[#ls + 1] = '"' .. esc(l) .. '"'
            end
            fields[#fields + 1] = '"logs":[' .. table.concat(ls, ",") .. ']'
        end
        out[#out + 1] = "    {" .. table.concat(fields, ",") .. "}"
    end
    return "[\n" .. table.concat(out, ",\n") .. (out[1] and "\n" or "") .. "]\n"
end

local function write_report(results)
    local dir = REPORT_PATH:match("^(.*)/[^/]+$")
    if dir then
        os.execute("mkdir -p '" .. dir .. "' 2>/dev/null")
    end
    local f = io.open(REPORT_PATH, "w")
    if not f then
        return
    end
    f:write(report_json(results))
    f:close()
end

-- ── load ──────────────────────────────────────────────────────────────────
function M.load()
    local settings = json.decode_file(SETTINGS_PATH) or {}
    local results = {}
    local seen = {}

    local dirs = {}
    for _, d in ipairs(list_dirs(USER_DIR)) do
        dirs[#dirs + 1] = d
    end
    for _, d in ipairs(list_dirs(MANAGED_DIR)) do
        dirs[#dirs + 1] = d
    end

    for _, dir in ipairs(dirs) do
        local manifest = read_manifest(dir)
        if manifest and not seen[manifest.id] then
            seen[manifest.id] = true
            local enabled, toggle = resolve_enabled(manifest, settings)
            local entry = {
                id = manifest.id,
                dir = dir,
                toggle = toggle,
                enabled = enabled,
                binds = {},
                logs = {},
            }
            if not enabled then
                entry.status = "disabled"
            else
                local frag = io.open(dir .. "/hypr.lua", "r")
                if not frag then
                    entry.status = "ok" -- no hypr fragment: nothing to run
                else
                    frag:close()
                    local chunk, cerr = loadfile(dir .. "/hypr.lua")
                    if not chunk then
                        entry.status = "error"
                        entry.error = tostring(cerr)
                    else
                        local sdk = make_sdk(manifest, dir, entry)
                        local ok, err = pcall(chunk, sdk)
                        if ok then
                            entry.status = "ok"
                        else
                            entry.status = "error"
                            entry.error = tostring(err)
                        end
                    end
                end
            end
            results[#results + 1] = entry
        end
    end

    M.results = results
    write_report(results)
    return results
end

return M
