-- MyLTC — comportamento adaptativo do Hyprland.
-- (O resto da adaptação — bateria, tela cheia, luz noturna — fica no shell:
--  ~/.config/quickshell/Adaptive.qml.)

local scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"

-- Uma janela só na área (ou em tela cheia): sem espaços, bordas nem cantos,
-- para aproveitar a tela pequena do notebook.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name        = "myltc-sozinha",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})
hl.window_rule({
    name        = "myltc-tela-cheia",
    match       = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- Tampa: com monitor externo, fechar desliga só a tela do note (sem suspender);
-- abrir religa. Sem monitor externo quem decide é o systemd-logind (suspende).
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(scripts .. "lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(scripts .. "lid open"), { locked = true })
