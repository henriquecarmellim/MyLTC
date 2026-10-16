import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Motor adaptativo do MyLTC: o rice reage sozinho ao contexto do notebook.
//  - Fora da tomada: modo economia (sem desfoque e sem sombras); na tomada volta tudo.
//  - Bateria 20% / 10% / 5% descarregando: avisos (5% é crítico).
//  - Janela em tela cheia: notificações não aparecem (só as críticas).
//  - 19h–6h30: luz noturna liga sozinha; mexer no botão vale até o próximo horário.
Scope {
    id: root

    // ---- Energia ----
    property bool onAc: true
    property int battery: 100
    property bool ready: false
    property var warned: ({}) // limiares já avisados nesta descarga

    Process {
        id: power
        command: ["sh", "-c",
            "ac=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1); " +
            "b=$(ls -d /sys/class/power_supply/BAT* | head -1); " +
            "echo \"${ac:-1} $(cat $b/capacity 2>/dev/null || echo 100)\""]
        stdout: SplitParser {
            onRead: line => {
                const [ac, cap] = line.trim().split(" ").map(Number);
                root.battery = cap;
                if (root.onAc !== (ac === 1) || !root.ready) {
                    root.onAc = ac === 1;
                    root.applyPowerMode(!root.ready);
                }
                root.ready = true;
                root.checkBattery();
            }
        }
    }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: power.running = true }

    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }
    function notify(title, body, urgency) {
        Quickshell.execDetached(["notify-send", "-a", "MyLTC", "-u", urgency || "normal", "-i", "battery", title, body]);
    }

    function applyPowerMode(silent) {
        ShellState.powerSave = !onAc;
        const on = onAc ? "true" : "false";
        hypr(`hl.config({ decoration = { blur = { enabled = ${on} }, shadow = { enabled = ${on} } } })`);
        if (!silent)
            notify(onAc ? "Na tomada" : "Modo economia",
                onAc ? "Desfoque e sombras de volta." : "Sem desfoque e sem sombras para poupar bateria.");
    }

    function checkBattery() {
        if (onAc) { warned = ({}); return; }
        for (const level of [5, 10, 20]) {
            if (battery <= level && !warned[level]) {
                const w = warned; w[level] = true; warned = w;
                notify(`Bateria em ${battery}%`,
                    level === 5 ? "Ligue na tomada agora — o note vai desligar." : "Hora de procurar uma tomada.",
                    level === 5 ? "critical" : "normal");
                break;
            }
        }
    }

    // ---- Tela cheia => não perturbe automático ----
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "fullscreen") ShellState.autoDnd = event.data === "1";
            else if (event.name === "workspace" || event.name === "activewindowv2") root.refreshFullscreen();
        }
    }
    Process {
        id: fullscreenCheck
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { ShellState.autoDnd = (JSON.parse(text).fullscreen || 0) > 0; }
                catch (e) { ShellState.autoDnd = false; }
            }
        }
    }
    function refreshFullscreen() { fullscreenCheck.running = true; }

    // ---- Luz noturna automática ----
    property var lastNight: undefined
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            const minutes = now.getHours() * 60 + now.getMinutes();
            const night = minutes >= 19 * 60 || minutes < 6 * 60 + 30;
            // só age quando cruza o horário: o toggle manual vale até lá
            if (night !== root.lastNight) {
                root.lastNight = night;
                ShellState.nightLight = night;
            }
        }
    }
}
