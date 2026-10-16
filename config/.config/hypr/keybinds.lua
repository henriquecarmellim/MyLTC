-- Atalhos do note — portados do PC (Caelestia), só os essenciais e úteis.
-- Sem área de trabalho especial. Ações que dependem da barra usam
-- hl.dsp.global("shell:...") para o shell próprio registrar depois.

local home = os.getenv("HOME")
local scripts = home .. "/.config/hypr/scripts/"

-- Programas
local terminal      = "foot"
local browser       = "firefox"
local editor        = "code"
local fileExplorer  = "dolphin"
local audioSettings = "pwvucontrol"

-- Volume (igual ao PC: passo de 10%, máximo 100%)
local volumeStep = 10
local volumeMax  = 100

-- Flags
local locked           = { locked = true }
local mouse            = { mouse = true }
local release          = { release = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }

local function bind(keys, action, flags)
    if type(keys) == "string" then keys = { keys } end
    for _, key in ipairs(keys) do
        hl.bind(key, action, flags)
    end
end

-- Áreas de trabalho em blocos de 10 (mesma lógica do PC)
local function wsaction(action, i)
    return function()
        local ws = hl.get_active_workspace()
        if not ws then return end
        local target = math.floor((ws.id - 1) / 10) * 10 + i
        if action == "move" then
            hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = target }))
        end
    end
end

local function resize_active_window(x, y)
    return function()
        local win = hl.get_active_window()
        if win and win.size then
            hl.dispatch(hl.dsp.window.resize({ x = win.size.x * x / 100, y = win.size.y * y / 100, relative = true }))
        end
    end
end

-- Janela flutuante pequena no canto inferior direito, fixada (picture-in-picture)
local function pip()
    local win = hl.get_active_window()
    local screen = hl.get_active_monitor()
    if not (win and win.size and screen) then return end

    local mw, mh = screen.width / screen.scale, screen.height / screen.scale
    local factor = (mh / 4) / win.size.y
    local w = math.floor(math.max(200, win.size.x * factor))
    local h = math.floor(math.max(150, win.size.y * factor))
    local offset = math.min(mw, mh) * 0.03

    if not win.floating then hl.dispatch(hl.dsp.window.float()) end
    hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = win }))
    hl.dispatch(hl.dsp.window.move({
        x = math.floor(screen.x + mw - w - offset),
        y = math.floor(screen.y + mh - h - offset),
        relative = false, window = win,
    }))
    hl.dispatch(hl.dsp.window.pin({ action = "on", window = "address:" .. win.address }))
end

-- Vai para a janela do app; se não estiver aberto, abre (no lugar das áreas especiais)
local function focus_or_launch(class, command)
    return function()
        for _, w in ipairs(hl.get_windows() or {}) do
            if w.class and w.class:lower() == class:lower() then
                return hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
            end
        end
        hl.dispatch(hl.dsp.exec_cmd(command))
    end
end

---- Shell / sessão ----
bind("SUPER + SUPER_L", hl.dsp.exec_cmd("pkill fuzzel || fuzzel"), release) -- launcher
bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(scripts .. "session"))
bind("SUPER + N", hl.dsp.global("shell:sidebar"))
bind("SUPER + K", hl.dsp.global("shell:showall"))
bind("CTRL + ALT + C", hl.dsp.global("shell:clearNotifs"), locked)
bind("SUPER + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend"), locked)
-- Reinicia o shell próprio (Quickshell em ~/.config/quickshell)
bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("qs kill; sleep .1; qs -d"), release)

---- Áreas de trabalho ----
for i = 1, 10 do
    local key = i % 10 -- 10 = tecla 0
    bind("SUPER + " .. key, wsaction("focus", i))
    bind("SUPER + ALT + " .. key, wsaction("move", i))
end

---- Janelas ----
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
    bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Área anterior/próxima pelo teclado (igual ao PC)
bind("CTRL + SUPER + Left", hl.dsp.focus({ workspace = "r-1" }), repeating)
bind("CTRL + SUPER + Right", hl.dsp.focus({ workspace = "r+1" }), repeating)

bind("ALT + TAB", hl.dsp.window.cycle_next(), repeating)
bind("SHIFT + ALT + TAB", hl.dsp.window.cycle_next({ next = false }), repeating)

bind({ "SUPER + Minus", "SUPER + ALT + Left" }, resize_active_window(-10, 0), repeating)
bind({ "SUPER + Equal", "SUPER + ALT + Right" }, resize_active_window(10, 0), repeating)
bind({ "SUPER + SHIFT + Minus", "SUPER + ALT + Up" }, resize_active_window(0, -10), repeating)
bind({ "SUPER + SHIFT + Equal", "SUPER + ALT + Down" }, resize_active_window(0, 10), repeating)

bind("SUPER + mouse:272", hl.dsp.window.drag(), mouse)
bind("SUPER + mouse:273", hl.dsp.window.resize(), mouse)
bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
bind("SUPER + ALT + Backslash", pip)
bind("SUPER + P", hl.dsp.window.pin())
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + ALT + Space", hl.dsp.window.float())
bind("SUPER + Q", hl.dsp.window.close())

---- Apps ----
bind("SUPER + T", hl.dsp.exec_cmd(terminal))
bind("SUPER + W", hl.dsp.exec_cmd(browser))
bind("SUPER + C", hl.dsp.exec_cmd(editor))
bind("SUPER + E", hl.dsp.exec_cmd(fileExplorer))
bind("CTRL + ALT + V", hl.dsp.exec_cmd(audioSettings))
bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(terminal .. " -a btop -T btop btop"))
bind("SUPER + M", focus_or_launch("spotify", "spotify"))
bind("SUPER + D", focus_or_launch("discord", "discord"))
bind("SUPER + R", focus_or_launch("todoist", "todoist"))

---- Utilitários ----
bind("Print", hl.dsp.exec_cmd(scripts .. "screenshot full"), locked)
bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(scripts .. "screenshot region"))
bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd(scripts .. "screenshot region"))
bind("CTRL + ALT + R", hl.dsp.exec_cmd(scripts .. "record"))
bind("SUPER + ALT + R", hl.dsp.exec_cmd(scripts .. "record sound"))
bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(scripts .. "record region"))
bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
bind("SUPER + V", hl.dsp.exec_cmd("pkill fuzzel || cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))
bind("SUPER + ALT + V", hl.dsp.exec_cmd("pkill fuzzel || cliphist list | fuzzel --dmenu | cliphist delete"))
bind("SUPER + Period", hl.dsp.exec_cmd("pkill fuzzel || rofimoji --selector fuzzel --action copy"))

---- Brilho ----
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+ && qs ipc call osd brightness"), locked_repeating)
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%- && qs ipc call osd brightness"), locked_repeating)

---- Mídia ----
bind({ "CTRL + SUPER + Space", "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.exec_cmd("playerctl play-pause"), locked)
bind({ "CTRL + SUPER + Equal", "XF86AudioNext" }, hl.dsp.exec_cmd("playerctl next"), locked)
bind({ "CTRL + SUPER + Minus", "XF86AudioPrev" }, hl.dsp.exec_cmd("playerctl previous"), locked)
bind({ "CTRL + SUPER + Backspace", "XF86AudioStop" }, hl.dsp.exec_cmd("playerctl stop"), locked)

---- Volume ----
bind({ "SUPER + SHIFT + M", "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
    "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " .. (volumeMax / 100) ..
    " @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%+"), locked_repeating)
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(
    "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. volumeStep .. "%-"), locked_repeating)
