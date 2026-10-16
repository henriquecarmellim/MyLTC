import Quickshell
import Quickshell.Hyprland
import QtQuick

// Áreas de trabalho numeradas (para usar com Super+N):
// ativa = pílula vermelha, com janelas = número claro + tracinho, vazia = apagada.
// Sempre mostra 1–5; as de cima entram deslizando para o lado quando aparecem
// e saem animadas quando ficam vazias.
// Clique vai para a área; rolar o mouse troca para a próxima/anterior.
Item {
    id: root
    property string monitorName
    readonly property int shown: 5

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: list.contentWidth
    implicitHeight: Theme.barHeight

    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var occupied: {
        const ids = {};
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > 0 && ws.toplevels.values.length > 0) ids[ws.id] = true;
        return ids;
    }
    // Áreas que devem aparecer, em ordem
    readonly property var wanted: {
        const ids = new Set();
        for (let i = 1; i <= shown; i++) ids.add(i);
        for (const id in occupied) ids.add(Number(id));
        if (activeId > 0) ids.add(activeId);
        return [...ids].sort((a, b) => a - b);
    }

    // Mantém o modelo em sincronia inserindo/removendo só o que mudou,
    // para as animações de entrada/saída rodarem só nas áreas afetadas.
    ListModel { id: model }
    function sync() {
        for (let i = model.count - 1; i >= 0; i--)
            if (!wanted.includes(model.get(i).wsId)) model.remove(i);
        wanted.forEach((id, i) => {
            if (i >= model.count || model.get(i).wsId !== id) model.insert(i, { wsId: id });
        });
    }
    onWantedChanged: sync()
    Component.onCompleted: sync()

    function go(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => root.go(Math.max(1, root.activeId + (wheel.angleDelta.y < 0 ? 1 : -1)))
    }

    ListView {
        id: list
        anchors.verticalCenter: parent.verticalCenter
        width: contentWidth
        height: 20
        orientation: ListView.Horizontal
        spacing: 4
        interactive: false
        model: model

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                NumberAnimation { property: "scale"; from: 0.3; to: 1; duration: 320; easing.type: Easing.OutBack }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 160 }
                NumberAnimation { property: "scale"; to: 0.3; duration: 180; easing.type: Easing.InCubic }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: chip
            required property int wsId
            readonly property bool active: wsId === root.activeId
            readonly property bool used: root.occupied[wsId] === true

            implicitWidth: active ? 28 : 20
            implicitHeight: 20
            radius: height / 2
            color: active ? Theme.red : "transparent"

            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: chip.wsId === 10 ? "0" : chip.wsId // tecla 0 = área 10
                color: chip.active || chip.used ? Theme.text : Theme.subtle
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
