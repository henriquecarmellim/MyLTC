//@ pragma UseQApplication
// Shell próprio do note — wallpaper + barra por monitor, OSD, notificações e quick actions.
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
}
