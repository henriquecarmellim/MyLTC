import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Row {
    id: root
    spacing: 12
    anchors.verticalCenter: parent.verticalCenter

    property var info: ({ ssid: "", signal: 0, vpn: false, battery: -1, batteryState: "Unknown", brightness: 0 })

    Process {
        running: true
        command: ["sh", Quickshell.shellDir + "/scripts/status.sh"]
        stdout: SplitParser {
            onRead: line => {
                try { root.info = JSON.parse(line); } catch (e) {}
            }
        }
    }

    function pick(icons, percent) {
        const i = Math.floor(Math.max(0, percent) / (100 / icons.length));
        return icons[Math.min(icons.length - 1, i)];
    }

    // Wi-Fi
    Label {
        text: root.info.ssid ? root.pick(["󰤟", "󰤢", "󰤥", "󰤨"], root.info.signal) : "󰤮"
        color: root.info.ssid ? Theme.text : Theme.subtle
        font.pixelSize: Theme.iconSize
    }

    // VPN de casa (wg0)
    Label {
        visible: root.info.vpn
        text: "󰦝"
        color: Theme.red
        font.pixelSize: Theme.iconSize
    }

    // Volume: rolar ajusta, clique silencia
    Item {
        id: vol
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: volRow.implicitWidth
        implicitHeight: Theme.barHeight

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : true
        readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

        Row {
            id: volRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: vol.muted ? "󰝟" : root.pick(["󰕿", "󰖀", "󰕾"], vol.volume)
                color: vol.muted ? Theme.subtle : Theme.text
                font.pixelSize: Theme.iconSize
            }
            Label { text: vol.volume + "%"; color: Theme.muted }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: if (vol.sink) vol.sink.audio.muted = !vol.sink.audio.muted
            onWheel: wheel => {
                if (!vol.sink) return;
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                vol.sink.audio.volume = Math.max(0, Math.min(1, vol.sink.audio.volume + step));
            }
        }
    }

    // Brilho: rolar ajusta
    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: brRow.implicitWidth
        implicitHeight: Theme.barHeight

        Row {
            id: brRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Label { text: root.pick(["󰃞", "󰃟", "󰃠"], root.info.brightness); font.pixelSize: Theme.iconSize }
            Label { text: root.info.brightness + "%"; color: Theme.muted }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => Quickshell.execDetached(["sh", "-c", `brightnessctl set ${wheel.angleDelta.y > 0 ? "5%+" : "5%-"} && qs ipc call osd brightness`])
        }
    }

    // Bateria
    Row {
        visible: root.info.battery >= 0
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        readonly property bool charging: root.info.batteryState === "Charging" || root.info.batteryState === "Full"
        readonly property bool low: root.info.battery <= 20 && !charging

        Label {
            text: parent.charging ? "󰂄" : root.pick(["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"], root.info.battery)
            color: parent.low ? Theme.red : Theme.text
            font.pixelSize: Theme.iconSize
        }
        Label { text: root.info.battery + "%"; color: parent.low ? Theme.red : Theme.muted }
        // modo economia (fora da tomada) — ver Adaptive.qml
        Label {
            visible: ShellState.powerSave
            text: "󰌪"
            color: "#7ec699"
            font.pixelSize: Theme.iconSize
        }
    }
}
