-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║ layers.lua — backdrop blur for the Quickshell layer surfaces (glass).      ║
-- ║                                                                           ║
-- ║ Hyprland does not decorate layer surfaces; a layer rule with blur = true  ║
-- ║ enables the same backdrop blur the compositor applies to windows. The     ║
-- ║ shell controls how much shows through with settings.json "glass" (the     ║
-- ║ background alpha); blur strength comes from decoration:blur (Blur Size /  ║
-- ║ Passes in the Hyprland tab).                                              ║
-- ║                                                                           ║
-- ║ ignore_alpha keeps fully transparent regions (host padding, shadow mar-   ║
-- ║ gins, full-screen overlays) from producing blurred rectangles.            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

local namespaces = {
    "^qs-master$",              -- popups, menus, bar editor (ui/Main.qml)
    "^quickshell$",             -- the bar (PanelWindow default namespace)
    "^qs-floating-overlay$",    -- floating sidebar
    "^qs-popups$",              -- notifications
    "^qs-widget-",              -- desktop widgets
}

for _, ns in ipairs(namespaces) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.15 })
end
