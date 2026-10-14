-- equisdots.lua — compositor-side plugin SDK (the `mod` table injected into a
-- plugin's hypr.lua). This is the Lua mirror of the shell-side `PluginHost`.
--
-- The Hyprland loader (config/hypr/plugins.lua) evaluates a plugin fragment as
--     local mod = ...
-- with a `mod` produced by M.make(). Keeping the SDK here (instead of inline in
-- plugins.lua) gives it the same lifecycle/versioning as the QML half.
--
-- API_VERSION must match the shell-side PluginHost.apiVersion surface; `compat`
-- gates on it (see equisdots/plugin-api).

local M = {}

M.API_VERSION = "1.0.0"

-- make(manifest, dir, report, hl) -> mod
--   manifest : the plugin.json table (needs .id)
--   dir      : the plugin's runtime folder (its plugin.json / scripts / hypr.lua)
--   report   : a { binds = {}, logs = {} } sink the loader serialises to the report
--   hl       : the Hyprland Lua API (allows tests to inject a stub)
function M.make(manifest, dir, report, hl)
    report = report or { binds = {}, logs = {} }
    local sdk = {
        id = manifest and manifest.id or "",
        dir = dir or "",
        api = M.API_VERSION,
    }

    function sdk.script(name)
        return (dir or "") .. "/scripts/" .. tostring(name)
    end

    function sdk.exec(cmd)
        return hl.dsp.exec_cmd(tostring(cmd))
    end

    -- hl.bind plus a recorded human label (feeds the keybind UI / report).
    function sdk.bind(key, dispatcher, opts)
        local clean, label
        if type(opts) == "table" then
            label = opts.label
            clean = {}
            for k, v in pairs(opts) do
                if k ~= "label" then clean[k] = v end
            end
            if next(clean) == nil then clean = nil end
        end
        if clean ~= nil then
            hl.bind(key, dispatcher, clean)
        else
            hl.bind(key, dispatcher)
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

return M
