import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Quick actions: escondido, desliza da direita. Super+N ou clique no status da barra.
// Teclado: setas/hjkl navegam, Enter/Espaço ativa, ←/→ ajustam sliders, Esc fecha.
PanelWindow {
    id: panel

    readonly property bool open: ShellState.panelOpen

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + Theme.gap * 2
        right: Theme.gap
    }
    implicitWidth: 360
    implicitHeight: box.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    visible: open || box.x < implicitWidth
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Clicar fora fecha
    HyprlandFocusGrab {
        windows: [panel]
        active: panel.open
        onCleared: ShellState.panelOpen = false
    }

    // ---- Estado ----
    property bool wifi: true
    property bool vpn: true
    property int brightness: 0
    property string confirming: "" // reiniciar/desligar pedem 2 toques

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool volMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    readonly property string scripts: Quickshell.shellDir + "/scripts/"

    Process {
        id: readToggles
        command: ["sh", panel.scripts + "toggles.sh"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    panel.wifi = s.wifi;
                    panel.vpn = s.vpn;
                } catch (e) {}
            }
        }
    }
    Process {
        id: readBrightness
        command: ["sh", "-c", "b=$(ls -d /sys/class/backlight/* | head -1); echo $(( $(cat $b/brightness) * 100 / $(cat $b/max_brightness) ))"]
        stdout: SplitParser { onRead: line => panel.brightness = parseInt(line) }
    }
    function refresh() {
        readToggles.running = true;
        readBrightness.running = true;
    }
    onOpenChanged: if (open) { refresh(); cursor = Qt.point(0, 0); confirming = ""; }
    Timer { interval: 1500; repeat: true; running: panel.open; onTriggered: readToggles.running = true }
    Timer { id: confirmReset; interval: 3000; onTriggered: panel.confirming = "" }

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }

    function activate(id) {
        switch (id) {
        case "awake": ShellState.keepAwake = !ShellState.keepAwake; break;
        case "vpn": run(`sh ${scripts}toggles.sh vpn ${vpn ? "down" : "up"}`); vpn = !vpn; break;
        case "wifi": run(`sh ${scripts}toggles.sh wifi ${wifi ? "off" : "on"}`); wifi = !wifi; break;
        case "dnd": ShellState.dnd = !ShellState.dnd; break;
        case "night": ShellState.nightLight = !ShellState.nightLight; break;
        case "mic": if (source) source.audio.muted = !source.audio.muted; break;
        case "volume": if (sink) sink.audio.muted = !sink.audio.muted; break;
        case "lock": ShellState.panelOpen = false; run("pidof hyprlock || hyprlock"); break;
        case "suspend": ShellState.panelOpen = false; run("systemctl suspend"); break;
        case "logout": run("hyprctl dispatch 'hl.dsp.exit()'"); break;
        case "reboot":
        case "poweroff":
            if (confirming === id) run(`systemctl ${id}`);
            else { confirming = id; confirmReset.restart(); }
            break;
        case "clear": ShellState.clearAll(); break;
        }
    }

    function adjust(id, delta) {
        if (id === "volume" && sink) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta / 100));
        } else if (id === "brightness") {
            setBrightness(brightness + delta);
        }
    }
    function setBrightness(v) {
        brightness = Math.max(1, Math.min(100, v));
        run(`brightnessctl -q set ${brightness}%`);
    }
    function setVolume(v) {
        if (!sink) return;
        sink.audio.muted = false;
        sink.audio.volume = v / 100;
    }

    // ---- Navegação por teclado: linhas de itens focáveis ----
    readonly property var rows: [
        ["awake", "vpn"],
        ["wifi", "dnd"],
        ["night", "mic"],
        ["volume"],
        ["brightness"],
        ["lock", "suspend", "logout", "reboot", "poweroff"],
        ["clear"]
    ]
    property point cursor: Qt.point(0, 0) // x = coluna, y = linha
    readonly property string current: rows[cursor.y][Math.min(cursor.x, rows[cursor.y].length - 1)]
    function isFocused(id) { return open && current === id; }

    function move(dx, dy) {
        let y = Math.max(0, Math.min(rows.length - 1, cursor.y + dy));
        let x = dy !== 0 ? Math.min(cursor.x, rows[y].length - 1) : cursor.x + dx;
        if (dx !== 0 && (x < 0 || x >= rows[y].length)) {
            // fim da linha: passa para a próxima/anterior
            y = Math.max(0, Math.min(rows.length - 1, y + dx));
            x = dx > 0 ? 0 : rows[y].length - 1;
        }
        cursor = Qt.point(x, y);
    }

    // ---- Conteúdo ----
    Rectangle {
        id: box
        width: panel.implicitWidth
        implicitHeight: layout.implicitHeight + 28
        radius: Theme.radius + 4
        color: Qt.rgba(12 / 255, 12 / 255, 15 / 255, 0.92)
        border.color: Theme.border
        border.width: 1

        x: panel.open ? 0 : panel.implicitWidth + 20
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        focus: panel.open
        Keys.onPressed: event => {
            const k = event.key;
            const slider = panel.current === "volume" || panel.current === "brightness";
            if (k === Qt.Key_Escape) ShellState.panelOpen = false;
            else if (k === Qt.Key_Up || k === Qt.Key_K) panel.move(0, -1);
            else if (k === Qt.Key_Down || k === Qt.Key_J) panel.move(0, 1);
            else if ((k === Qt.Key_Left || k === Qt.Key_H) && slider) panel.adjust(panel.current, -5);
            else if ((k === Qt.Key_Right || k === Qt.Key_L) && slider) panel.adjust(panel.current, 5);
            else if (k === Qt.Key_Left || k === Qt.Key_H) panel.move(-1, 0);
            else if (k === Qt.Key_Right || k === Qt.Key_L) panel.move(1, 0);
            else if (k === Qt.Key_Tab) panel.move(1, 0);
            else if (k === Qt.Key_Backtab) panel.move(-1, 0);
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) panel.activate(panel.current);
            else return;
            event.accepted = true;
        }

        ColumnLayout {
            id: layout
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 12

            // Cabeçalho
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Quick actions"
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "↑↓←→ · Enter · Esc"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Tile {
                    Layout.fillWidth: true
                    icon: "󰅶"; label: "Não desligar"
                    detail: ShellState.keepAwake ? "Sem suspender nem tampa" : "Desligado"
                    on: ShellState.keepAwake; focused: panel.isFocused("awake")
                    onActivated: panel.activate("awake")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "󰦝"; label: "VPN de casa"
                    detail: panel.vpn ? "Conectada · wg0" : "Desligada"
                    on: panel.vpn; focused: panel.isFocused("vpn")
                    onActivated: panel.activate("vpn")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: panel.wifi ? "󰤨" : "󰤮"; label: "Wi-Fi"
                    on: panel.wifi; focused: panel.isFocused("wifi")
                    onActivated: panel.activate("wifi")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: ShellState.dnd ? "󰂛" : "󰂚"; label: "Não perturbe"
                    on: ShellState.dnd; focused: panel.isFocused("dnd")
                    onActivated: panel.activate("dnd")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: "󰖔"; label: "Luz noturna"
                    detail: ShellState.nightLight ? "4500 K" : "Desligada"
                    on: ShellState.nightLight; focused: panel.isFocused("night")
                    onActivated: panel.activate("night")
                }
                Tile {
                    Layout.fillWidth: true
                    icon: panel.micMuted ? "󰍭" : "󰍬"; label: "Microfone"
                    detail: panel.micMuted ? "Mudo" : "Ativo"
                    on: !panel.micMuted; focused: panel.isFocused("mic")
                    onActivated: panel.activate("mic")
                }
            }

            PanelSlider {
                Layout.fillWidth: true
                icon: panel.volMuted ? "󰝟" : "󰕾"
                value: panel.volume
                dimmed: panel.volMuted
                focused: panel.isFocused("volume")
                onMoved: v => panel.setVolume(v)
            }
            PanelSlider {
                Layout.fillWidth: true
                icon: "󰃠"
                value: panel.brightness
                focused: panel.isFocused("brightness")
                onMoved: v => panel.setBrightness(v)
            }

            // Energia
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "lock", icon: "󰌾", label: "Bloquear" },
                        { id: "suspend", icon: "󰒲", label: "Suspender" },
                        { id: "logout", icon: "󰍃", label: "Sair" },
                        { id: "reboot", icon: "󰜉", label: "Reiniciar" },
                        { id: "poweroff", icon: "󰐥", label: "Desligar" }
                    ]

                    Rectangle {
                        required property var modelData
                        readonly property bool focused: panel.isFocused(modelData.id)
                        readonly property bool armed: panel.confirming === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 52
                        radius: Theme.radius
                        color: armed ? Theme.red : Theme.surface
                        border.width: focused ? 2 : 1
                        border.color: focused ? Theme.red : Theme.border

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.parent.modelData.icon
                                color: parent.parent.armed ? Theme.text : Theme.red
                                font.family: Theme.font
                                font.pixelSize: 18
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.parent.armed ? "Confirma?" : parent.parent.modelData.label
                                color: parent.parent.armed ? Theme.text : Theme.muted
                                font.family: Theme.font
                                font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.activate(parent.modelData.id)
                        }
                    }
                }
            }

            // Notificações
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radius
                color: Theme.surface
                border.width: panel.isFocused("clear") ? 2 : 1
                border.color: panel.isFocused("clear") ? Theme.red : Theme.border

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: `󰂚  ${ShellState.history.values.length} notificaç${ShellState.history.values.length === 1 ? "ão" : "ões"}`
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Limpar"
                    color: Theme.red
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.activate("clear")
                }
            }
        }
    }
}
