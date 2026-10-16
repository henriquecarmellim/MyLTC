import Quickshell
import Quickshell.Wayland
import QtQuick

// Papel de parede desenhado pelo próprio shell (camada de fundo).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    // Troque aqui o arquivo (há outro em ~/Pictures/wallpapers)
    property string source: "file://" + Quickshell.env("HOME") + "/Pictures/wallpapers/japan-9mdyz8.png"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "shell-wallpaper"
    color: "#0c0c0f"

    Image {
        anchors.fill: parent
        source: win.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }
}
