-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ WORKSPACE RULES & SCRATCHPADS                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ MULTI-MONITOR: UNIFIED DESKTOPS & BOOT DEFAULTS                          │
-- │                                                                           │
-- │ The author's rig is 4 physical screens (laptop + 3 Xiaomi). The rules    │
-- │ below are only the BOOT DEFAULTS of "desktop 1": each monitor starts on  │
-- │ its own pinned workspace (laptop = 1, then leftwards 2, 3, 4).           │
-- │                                                                           │
-- │ Optional UNIFIED DESKTOPS mode (scripts/ws-desktops-lib.sh is the engine)│
-- │ turns SUPER + 1..9 into full-desktop jumps: with >= 2 roster screens     │
-- │ connected, EVERY screen switches at once (workspace = (d-1)*4 + rank).   │
-- │ With fewer screens — or on other people's hardware (different EDIDs) —   │
-- │ the classic per-monitor behavior is kept untouched. Disable the mode     │
-- │ explicitly with "unifiedDesktops": false in settings.json.               │
-- │                                                                           │
-- │ KEEP THE MON_* DESCRIPTIONS IN SYNC with ROSTER_DESCS in                 │
-- │ scripts/ws-desktops-lib.sh (same rank order!).                           │
-- │                                                                           │
-- │ Identify your own monitors with: hyprctl monitors all                    │
-- │ (the "description" field is the key, e.g. "Xiaomi ... 5275600003570").   │
-- └───────────────────────────────────────────────────────────────────────────┘

local semver = require("lib.semver")

-- Hyprland 0.57 removed special_scale_factor (its scaling code is gone).
-- Approximate the old 0.85 scratchpad inset with workspace gaps on 0.57+.
local IS_057 = semver.satisfies(hl.version(), ">=0.57.0") == 0
local SPECIAL_GAPS = IS_057 and 48 or nil

-- --- LAPTOP (rightmost) + externals leftwards ---
-- NOTE: same order/descriptions as ROSTER_DESCS in scripts/ws-desktops-lib.sh
local MON_LAPTOP = "desc:AU Optronics B156HAN15.H"
local MON_LEFT2  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003084"  -- DP-6
local MON_LEFT3  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600003570"  -- HDMI-A-3
local MON_LEFT4  = "desc:Xiaomi Corporation P27FBB-RGGL 5275600072695"  -- DP-5

-- Desktop-1 boot defaults: each monitor shows its own pinned workspace on login.
hl.workspace_rule({ workspace = "1", monitor = MON_LAPTOP, default = true })
hl.workspace_rule({ workspace = "2", monitor = MON_LEFT2, default = true })
hl.workspace_rule({ workspace = "3", monitor = MON_LEFT3, default = true })
hl.workspace_rule({ workspace = "4", monitor = MON_LEFT4, default = true })

-- --- ALTERNATIVE: pin your own screens here (examples) ---
-- hl.workspace_rule({ workspace = "1", monitor = "desc:YOUR_PRIMARY_DESCRIPTION", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "desc:YOUR_SECONDARY_DESCRIPTION" })
-- hl.workspace_rule({ workspace = "3", monitor = "desc:YOUR_THIRD_DESCRIPTION" })

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ BOOT FALLBACK (hardware not in the roster)                               │
-- │                                                                           │
-- │ Hyprland's default-workspace picker skips every workspace bound to a     │
-- │ monitor that is not connected (state/workspace/LifecyclePolicy), so a    │
-- │ panel whose EDID is not listed above makes the session boot on the first  │
-- │ free id (5 with this 4-screen roster). Force desktop 1 on the focused     │
-- │ monitor in that case; roster monitors keep their pinned slots untouched.  │
-- └───────────────────────────────────────────────────────────────────────────┘

local ROSTER = { MON_LAPTOP, MON_LEFT2, MON_LEFT3, MON_LEFT4 }

local function in_roster(description)
    for _, selector in ipairs(ROSTER) do
        -- Same rule as CMonitor::matchesStaticSelector: desc: is a prefix match.
        local needle = selector:sub(6)
        if (description or ""):sub(1, #needle) == needle then return true end
    end
    return false
end

hl.on("hyprland.start", function()
    local focused = hl.get_active_monitor()
    if focused and not in_roster(focused.description) then
        hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    end
end)

-- ┌───────────────────────────────────────────────────────────────────────────┐
-- │ SPECIAL WORKSPACES (Scratchpads)                                         │
-- │                                                                           │
-- │ Named scratchpads toggled with keybinds. They launch their app           │
-- │ automatically the first time they are opened. 0.57 deprecates the        │
-- │ on_created_empty rule key, so use workspace.created + is_empty there.    │
-- └───────────────────────────────────────────────────────────────────────────┘

local SCRATCHPADS = {
    terminal = "kitty --class scratchpad-terminal",
    files    = "nautilus",
    music    = "spotify",
}

local function scratchpad_name(ws)
    if not ws or not ws.special then return nil end
    return (ws.name or ""):match("^special:(.+)$") or ws.name
end

if IS_057 then
    hl.on("workspace.created", function(ws)
        if not ws or not ws.is_empty then return end
        local cmd = SCRATCHPADS[scratchpad_name(ws)]
        if cmd then hl.exec_cmd(cmd) end
    end)
end

for name, cmd in pairs(SCRATCHPADS) do
    local rule = { workspace = "special:" .. name, gaps_out = SPECIAL_GAPS }
    if not IS_057 then rule.on_created_empty = cmd end
    hl.workspace_rule(rule)
end
