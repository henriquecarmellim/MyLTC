import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Barra adaptativa: área vazia = ilhas soltas e afastadas das bordas;
// com janelas = compacta, encostada no topo.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    readonly property var workspace: Hyprland.focusedWorkspace
    readonly property bool busy: workspace !== null && workspace.toplevels.values.length > 0
    readonly property int inset: busy ? Theme.gap : Theme.gapIdle

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.gapIdle
    // Janelas sempre começam abaixo da barra compacta
    exclusiveZone: Theme.barHeight + Theme.gap
    color: "transparent"
    WlrLayershell.namespace: "shell-bar"

    // Só as ilhas recebem clique; o resto da faixa é transparente para as janelas
    mask: Region {
        Region { item: leftIsland }
        Region { item: centerIsland }
        Region { item: rightIsland }
    }

    Item {
        id: frame
        anchors.fill: parent
        property real inset: bar.inset
        Behavior on inset { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        // Esquerda: Arch (launcher) + mídia
        Island {
            id: leftIsland
            x: frame.inset
            y: frame.inset

            Label {
                text: "󰣇"
                color: Theme.red
                font.pixelSize: Theme.iconSize + 4
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["sh", "-c", "pkill fuzzel || fuzzel"])
                }
            }
            Media {}
        }

        // Centro: áreas de trabalho
        Island {
            id: centerIsland
            x: (frame.width - width) / 2
            y: frame.inset
            padding: 10
            Workspaces { monitorName: bar.modelData.name }
        }

        // Direita: status + relógio
        Island {
            id: rightIsland
            // clique no status (fora de volume/brilho) abre as quick actions
            TapHandler { onTapped: ShellState.panelOpen = !ShellState.panelOpen }
            x: frame.width - width - frame.inset
            y: frame.inset
            Status {}
            Clock {}
        }
    }
}
