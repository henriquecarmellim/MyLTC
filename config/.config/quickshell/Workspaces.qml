import Quickshell
import Quickshell.Hyprland
import QtQuick

// Áreas de trabalho numeradas (para usar com Super+N):
// ativa = pílula vermelha, com janelas = número claro, vazia = número apagado.
// Sempre mostra 1–5; acima disso só as que têm janelas ou a ativa.
// Clique vai para a área; rolar o mouse troca para a próxima/anterior.
Item {
    id: root
    property string monitorName
    readonly property int shown: 5

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var occupied: {
        const ids = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0 && ws.toplevels.values.length > 0) ids[ws.id] = true;
        return ids;
    }
    readonly property int last: {
        let max = shown;
        for (const id in occupied) max = Math.max(max, Number(id));
        return Math.max(max, activeId);
    }

    function go(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => root.go(Math.max(1, root.activeId + (wheel.angleDelta.y < 0 ? 1 : -1)))
    }

    Row {
        id: row
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.last

            Rectangle {
                id: chip
                required property int index
                readonly property int wsId: index + 1
                readonly property bool active: wsId === root.activeId
                readonly property bool used: root.occupied[wsId] === true
                visible: wsId <= root.shown || used || active

                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: active ? 28 : 20
                implicitHeight: 20
                radius: height / 2
                color: active ? Theme.red : "transparent"

                Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 160 } }

                Text {
                    anchors.centerIn: parent
                    text: chip.wsId % 10 === 0 ? "0" : chip.wsId // tecla 0 = área 10
                    color: chip.active ? Theme.text : chip.used ? Theme.text : Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.bold: chip.active || chip.used
                }

                // Marca de "tem janelas" embaixo do número
                Rectangle {
                    visible: chip.used && !chip.active
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 4
                    height: 2
                    radius: 1
                    color: Theme.red
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(chip.wsId)
                }
            }
        }
    }
}
