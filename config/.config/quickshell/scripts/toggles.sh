#!/bin/sh
# Estado/controle dos toggles do painel.
#   toggles.sh            -> {"wifi":true,"vpn":true}
#   toggles.sh wifi on|off
#   toggles.sh vpn up|down   (precisa da regra do polkit em /etc/polkit-1/rules.d)
case "$1" in
    wifi) iwctl device wlan0 set-property Powered "$2" ;;
    vpn)  networkctl "$2" wg0 ;;
    *)
        powered=$(iwctl device wlan0 show 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
            awk '{for (i = 1; i < NF; i++) if ($i == "Powered") {print $(i + 1); exit}}')
        [ "$powered" = "on" ] && wifi=true || wifi=false
        state=$(cat /sys/class/net/wg0/operstate 2>/dev/null || echo down)
        [ "$state" = "down" ] && vpn=false || vpn=true
        printf '{"wifi":%s,"vpn":%s}\n' "$wifi" "$vpn"
        ;;
esac
