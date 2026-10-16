//@ pragma UseQApplication
// Shell próprio do note — wallpaper + barra por monitor, OSD, notificações, quick actions e motor adaptativo.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Wallpaper {}
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {}
        }
    }

    Osd {}
    Notifications {}
    QuickPanel {}
    Adaptive {}
}
