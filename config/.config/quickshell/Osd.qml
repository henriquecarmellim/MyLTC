import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick

// Indicador de volume/brilho que aparece ao usar as teclas.
// Volume: automático (qualquer mudança no PipeWire).
// Brilho: `qs ipc call osd brightness` (chamado pelos atalhos).
PanelWindow {
    id: osd

    property string kind: "volume"
    property int value: 0
    property bool muted: false
    property bool shown: false
    property bool ready: false // não mostra nada ao iniciar o shell

    anchors.bottom: true
    margins.bottom: 72
    implicitWidth: 280
    implicitHeight: 52
    exclusiveZone: 0
    color: "transparent"
    visible: shown || box.opacity > 0
    mask: Region {} // não intercepta cliques
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-osd"

    function show(newKind, newValue, newMuted) {
        if (!ready) return;
        kind = newKind;
        value = Math.max(0, Math.min(100, newValue));
        muted = newMuted;
        shown = true;
        hide.restart();
    }

    Timer { interval: 1500; running: true; onTriggered: osd.ready = true }
    Timer { id: hide; interval: 1300; onTriggered: osd.shown = false }

    // Volume
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: osd.sink ? osd.sink.audio : null
        function onVolumeChanged() { osd.show("volume", Math.round(osd.sink.audio.volume * 100), osd.sink.audio.muted); }
        function onMutedChanged() { osd.show("volume", Math.round(osd.sink.audio.volume * 100), osd.sink.audio.muted); }
    }

    // Brilho
    Process {
        id: readBrightness
        command: ["sh", "-c", "b=$(ls -d /sys/class/backlight/* | head -1); echo $(( $(cat $b/brightness) * 100 / $(cat $b/max_brightness) ))"]
        stdout: SplitParser { onRead: line => osd.show("brightness", parseInt(line), false) }
    }
    IpcHandler {
        target: "osd"
        function brightness(): void { readBrightness.running = true; }
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radius + 4
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Row {
            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: osd.kind === "brightness" ? "󰃠" : osd.muted ? "󰝟" : osd.value > 50 ? "󰕾" : osd.value > 0 ? "󰖀" : "󰕿"
                color: osd.muted ? Theme.subtle : Theme.red
                font.family: Theme.font
                font.pixelSize: 20
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 160
                height: 6
                radius: 3
                color: Theme.surfaceHigh

                Rectangle {
                    width: parent.width * osd.value / 100
                    height: parent.height
                    radius: parent.radius
                    color: osd.muted ? Theme.subtle : Theme.red
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                text: osd.value + "%"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
