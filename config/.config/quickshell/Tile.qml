import QtQuick

// Botão de toggle do painel. `focused` = selecionado pelo teclado.
Rectangle {
    id: tile
    property string icon
    property string label
    property string detail
    property bool on: false
    property bool focused: false
    signal activated

    implicitHeight: 58
    radius: Theme.radius
    color: on ? Theme.redDark : Theme.surface
    border.width: focused ? 2 : 1
    border.color: focused ? Theme.red : on ? Qt.rgba(1, 0.18, 0.22, 0.45) : Theme.border
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.icon
            color: tile.on ? Theme.red : Theme.muted
            font.family: Theme.font
            font.pixelSize: 20
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                text: tile.label
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
            Text {
                text: tile.detail !== "" ? tile.detail : tile.on ? "Ligado" : "Desligado"
                color: tile.on ? Theme.redSoft : Theme.subtle
                font.family: Theme.font
                font.pixelSize: 10
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.activated()
    }
}
