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

-- Slug for a default bind id: lowercase, non-alphanumerics collapse to "-".
local function slug(s)
    s = tostring(s or ""):lower()
    s = s:gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
    return s
end

-- make(manifest, dir, report, hl, overrides) -> mod
--   manifest  : the plugin.json table (needs .id)
--   dir       : the plugin's runtime folder (its plugin.json / scripts / hypr.lua)
--   report    : a { binds = {}, logs = {} } sink the loader serialises to the report
--   hl        : the Hyprland Lua API (allows tests to inject a stub)
--   overrides : user bind overrides, resolved by the loader from the plugin's
--               own settings file (`<scope>.binds`): bind id -> "NEW KEY" to
--               rebind, or false to disable that single bind. The plugin owns
--               the action; the user owns the key (keybinds editor plugin).
function M.make(manifest, dir, report, hl, overrides)
    report = report or { binds = {}, logs = {} }
    overrides = overrides or {}
    local used_ids = {}
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

    -- hl.bind plus a recorded human label + stable bind id. opts:
    --   label : human name — feeds the report / keybinds editor and is
    --           forwarded to hyprctl as the bind description
    --   id    : stable bind id for user overrides (default: slug of label)
    -- Every other key (locked, repeating, ...) is passed through untouched.
    -- Overrides (see M.make): "NEW KEY" rebinds, false disables this single
    -- bind while the plugin itself stays enabled.
    function sdk.bind(key, dispatcher, opts)
        local label, id, clean, had_label
        if type(opts) == "table" then
            label = opts.label
            id = opts.id
            had_label = opts.label ~= nil
            clean = {}
            for k, v in pairs(opts) do
                if k ~= "label" and k ~= "id" then clean[k] = v end
            end
            if next(clean) == nil then clean = nil end
        end
        label = tostring(label or key)
        id = tostring(id or slug(label))
        if id == "" then id = slug(key) end
        if used_ids[id] then
            report.logs[#report.logs + 1] =
                "bind id '" .. id .. "' declared twice (set explicit opts.id per bind)"
        end
        used_ids[id] = true

        local rec = {
            id = id,
            key = tostring(key),
            defaultKey = tostring(key),
            label = label,
        }
        local ov = overrides[id]
        if ov == false then
            rec.key = ""
            rec.disabled = true
            report.binds[#report.binds + 1] = rec
            return
        end
        if type(ov) == "string" and ov ~= "" then
            key = ov
            rec.key = ov
            rec.overridden = true
        end
        -- Surface an explicit label to hyprctl too (bind description), unless
        -- the plugin already set one; label/id never leak into hl.bind flags.
        if had_label then
            clean = clean or {}
            if clean.description == nil then clean.description = label end
        end
        if clean ~= nil then
            hl.bind(key, dispatcher, clean)
        else
            hl.bind(key, dispatcher)
        end
        report.binds[#report.binds + 1] = rec
    end

    function sdk.log(msg)
        report.logs[#report.logs + 1] = tostring(msg)
    end

    return sdk
end

return M
