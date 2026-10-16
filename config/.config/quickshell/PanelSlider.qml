import QtQuick

// Slider do painel (volume/brilho). Mouse: clicar/arrastar/rolar. Teclado: ←/→.
Item {
    id: slider
    property string icon
    property int value: 0 // 0–100
    property bool focused: false
    property bool dimmed: false
    signal moved(int value)

    implicitHeight: 36

    function nudge(delta) { moved(Math.max(0, Math.min(100, value + delta))); }

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        text: slider.icon
        color: slider.dimmed ? Theme.subtle : Theme.text
        font.family: Theme.font
        font.pixelSize: 18
    }

    Rectangle {
        id: track
        anchors.left: iconText.right
        anchors.right: valueText.left
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: slider.focused ? 10 : 8
        radius: height / 2
        color: Theme.surfaceHigh
        border.width: slider.focused ? 1 : 0
        border.color: Theme.red

        Rectangle {
            width: Math.max(height, parent.width * slider.value / 100)
            height: parent.height
            radius: parent.radius
            color: slider.dimmed ? Theme.subtle : Theme.red
            Behavior on width { NumberAnimation { duration: 90 } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            function set(mx) { slider.moved(Math.round(Math.max(0, Math.min(1, (mx - 8) / track.width)) * 100)); }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => { if (pressed) set(mouse.x); }
            onWheel: wheel => slider.nudge(wheel.angleDelta.y > 0 ? 5 : -5)
        }
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: slider.value + "%"
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
}
