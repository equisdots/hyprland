-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ MONITORS                                                                   ║
-- ║                                                                           ║
-- ║ The saved layout (~/.config/hypr/display-config) is read while the config ║
-- ║ loads and registered as hl.monitor() rules. Hyprland stores those rules   ║
-- ║ and applies them when each output connects (boot, hotplug/re-dock) and    ║
-- ║ when the config is reloaded — no mid-session file reads and no "apply     ║
-- ║ after N seconds" race.                                                    ║
-- ║                                                                           ║
-- ║ settings.json → monitorsMode:                                             ║
-- ║   "static"      saved rules only (default)                                ║
-- ║   "reconciler"  saved rules + scripts/restore-monitors.sh poller          ║
-- ║   "off"         wildcard/auto only (display-config is ignored)            ║
-- ║                                                                           ║
-- ║ The mode is also available in Settings → Monitors → Saved layout.         ║
-- ║ Layout lines are keyed by the monitor DESCRIPTION (EDID model + serial,   ║
-- ║ e.g. "Xiaomi Corporation P27FBB-RGGL 5275600003570"), which identifies a  ║
-- ║ physical screen no matter which connector it lands on.                    ║
-- ║ Identify your monitors with: hyprctl monitors all                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local layout = require("lib.monitor-layout")

local function read_file(path)
    if type(io) ~= "table" or type(io.open) ~= "function" then return nil end
    local ok, file = pcall(io.open, path, "r")
    if not ok or not file then return nil end
    local text = file:read("*a")
    file:close()
    return text
end

local home = os.getenv("HOME") or ""
local settings = read_file(home .. "/.config/hypr/settings.json") or ""
local mode = layout.mode_from_settings(settings)
local saved = {}

if mode ~= "off" then
    saved = layout.parse_display_config(read_file(home .. "/.config/hypr/display-config") or "")
end

-- Wildcard fallback first: monitors without a saved rule are auto-placed at
-- their highest refresh rate. Specific desc: rules below win for their screen.
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })

for _, rule in ipairs(saved) do
    hl.monitor(layout.monitor_rule(rule))
end

-- ────────────────────────────────────────────────────────────────────────────
-- Manual override (optional): rules declared here merge with the saved ones.
--
-- hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1920x0", scale = 1 })
-- ────────────────────────────────────────────────────────────────────────────
