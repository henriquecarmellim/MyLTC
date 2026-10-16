#!/bin/sh
# Uma linha JSON a cada 3s para a barra: Wi-Fi, VPN, bateria e brilho.
while :; do
    ssid=$(iwctl station wlan0 show 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
        awk -F'  +' '/Connected network/ {print $3; exit}')
    # /proc/net/wireless: qualidade do link 0–70
    quality=$(awk '/wlan0/ {gsub(/\./, "", $3); print int($3 * 100 / 70)}' /proc/net/wireless)
    [ "$(cat /sys/class/net/wg0/operstate 2>/dev/null || echo down)" != down ] && vpn=true || vpn=false

    bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
    capacity=$(cat "$bat/capacity" 2>/dev/null || echo -1)
    state=$(cat "$bat/status" 2>/dev/null || echo Unknown)

    bl=$(ls -d /sys/class/backlight/* 2>/dev/null | head -1)
    bright=$(( $(cat "$bl/brightness" 2>/dev/null || echo 0) * 100 / $(cat "$bl/max_brightness" 2>/dev/null || echo 1) ))

    printf '{"ssid":"%s","signal":%d,"vpn":%s,"battery":%d,"batteryState":"%s","brightness":%d}\n' \
        "$(printf '%s' "$ssid" | sed 's/["\\]/\\&/g')" "${quality:-0}" "$vpn" "$capacity" "$state" "$bright"
    sleep 3
done
