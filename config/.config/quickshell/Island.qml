import QtQuick

// "Ilha" da barra: fundo translúcido escuro com borda fina.
Rectangle {
    default property alias content: row.data
    property int padding: 12

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.bg
    border.color: Theme.border
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
