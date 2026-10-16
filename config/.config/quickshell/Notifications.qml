import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick

// Balões de notificação no canto superior direito, abaixo da barra.
PanelWindow {
    id: win

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + Theme.gap * 2
        right: Theme.gap
    }
    implicitWidth: 360
    implicitHeight: Math.max(1, column.implicitHeight)
    exclusiveZone: 0
    color: "transparent"
    visible: ShellState.popups.length > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-notifications"
    mask: Region { item: column }

    Column {
        id: column
        width: parent.width
        spacing: Theme.gap * 2

        Repeater {
            model: ShellState.popups

            Rectangle {
                id: card
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical

                width: column.width
                implicitHeight: content.implicitHeight + 24
                radius: Theme.radius
                color: Theme.bg
                border.width: 1
                border.color: critical ? Theme.red : Theme.border

                // entra deslizando da direita
                x: shown ? 0 : width + 20
                property bool shown: false
                Component.onCompleted: shown = true
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                Timer {
                    running: !card.critical && !area.containsMouse
                    interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                    onTriggered: { card.n.expire(); ShellState.dismiss(card.n); }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        // esquerdo: ação principal; direito/meio: fecha
                        const main = card.n.actions.find(a => a.identifier === "default");
                        if (mouse.button === Qt.LeftButton && main) main.invoke();
                        card.n.dismiss();
                        ShellState.dismiss(card.n);
                    }
                }

                Row {
                    id: content
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 12

                    Image {
                        width: 36
                        height: 36
                        visible: status === Image.Ready
                        source: card.n.image || (card.n.appIcon ? Quickshell.iconPath(card.n.appIcon, true) : "")
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: 72
                        sourceSize.height: 72
                    }

                    Column {
                        width: parent.width - 48
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 6
                            Text {
                                text: card.n.appName || "Notificação"
                                color: card.critical ? Theme.red : Theme.redSoft
                                font.family: Theme.font
                                font.pixelSize: 10
                            }
                        }
                        Text {
                            width: parent.width
                            text: card.n.summary
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: card.n.body
                            textFormat: Text.StyledText
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }

                        // Botões de ação do app
                        Row {
                            spacing: 6
                            visible: actions.count > 0
                            Repeater {
                                id: actions
                                model: card.n.actions.filter(a => a.identifier !== "default")
                                Rectangle {
                                    required property var modelData
                                    implicitWidth: label.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: 6
                                    color: Theme.surfaceHigh
                                    Text {
                                        id: label
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        color: Theme.text
                                        font.family: Theme.font
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { parent.modelData.invoke(); ShellState.dismiss(card.n); }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
