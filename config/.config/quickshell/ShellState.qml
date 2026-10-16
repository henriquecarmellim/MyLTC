pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Estado compartilhado do shell: painel de quick actions, toggles e notificações.
Singleton {
    id: root

    property bool panelOpen: false
    property bool dnd: false       // não perturbe: notificações não aparecem na tela
    property bool keepAwake: false // "não desligar": bloqueia suspensão/tampa/ociosidade
    property bool nightLight: false

    // Notificações que estão aparecendo na tela agora
    property var popups: []

    function dismiss(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
        popups = [];
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups].slice(0, 5);
            n.closed.connect(() => root.dismiss(n));
        }
    }
    readonly property var history: server.trackedNotifications

    // "Não desligar": segura suspensão, fechamento da tampa e ociosidade
    Process {
        running: root.keepAwake
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=Shell",
            "--why=Não desligar (quick actions)", "--mode=block", "sleep", "infinity"]
    }

    // Luz noturna (hyprsunset)
    Process {
        running: root.nightLight
        command: ["hyprsunset", "--temperature", "4500"]
    }

    // Atalhos globais (chamados pelo Hyprland: hl.dsp.global("shell:..."))
    GlobalShortcut {
        appid: "shell"
        name: "sidebar"
        description: "Abre/fecha as quick actions"
        onPressed: root.panelOpen = !root.panelOpen
    }
    GlobalShortcut {
        appid: "shell"
        name: "clearNotifs"
        description: "Limpa as notificações"
        onPressed: root.clearAll()
    }
    IpcHandler {
        target: "panel"
        function toggle(): void { root.panelOpen = !root.panelOpen; }
    }
}
