import Quickshell.Services.Mpris
import QtQuick

// Música atual: clique = play/pause, rolar = próxima/anterior.
Item {
    id: root
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }
    visible: player !== null

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Label {
            text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
            color: Theme.red
            font.pixelSize: Theme.iconSize
        }
        Label {
            text: {
                if (!root.player) return "";
                const artist = root.player.trackArtist;
                const title = root.player.trackTitle || root.player.identity;
                return artist ? `${artist} — ${title}` : title;
            }
            color: Theme.muted
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 280)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
        onWheel: wheel => {
            if (!root.player) return;
            if (wheel.angleDelta.y < 0 && root.player.canGoNext) root.player.next();
            else if (wheel.angleDelta.y > 0 && root.player.canGoPrevious) root.player.previous();
        }
    }
}
