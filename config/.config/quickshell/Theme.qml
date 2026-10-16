pragma Singleton

import Quickshell
import QtQuick

// Paleta do latenci.in (frontend: --primary #ff2d39 sobre #0c0c0f)
Singleton {
    readonly property color red: "#ff2d39"
    readonly property color redLight: "#ff5b64"
    readonly property color redSoft: "#ff858c"
    readonly property color redDark: "#43141a"

    readonly property color bg: Qt.rgba(12 / 255, 12 / 255, 15 / 255, 0.78) // #0c0c0f
    readonly property color surface: "#141417"
    readonly property color surfaceHigh: "#202026"
    readonly property color border: "#2a2a30"

    readonly property color text: "#f4f4f5"
    readonly property color muted: "#a0a0aa"
    readonly property color subtle: "#5c5c66"

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int iconSize: 14

    readonly property int barHeight: 32
    readonly property int gap: 4
    readonly property int gapIdle: 16 // área vazia: ilhas soltas
    readonly property int radius: 10
}
