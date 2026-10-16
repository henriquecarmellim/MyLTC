import Quickshell
import QtQuick

Row {
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Label {
        text: Qt.locale("pt_BR").toString(clock.date, "ddd dd/MM").replace(".", "")
        color: Theme.muted
    }
    Label {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.red
        font.bold: true
    }
}
