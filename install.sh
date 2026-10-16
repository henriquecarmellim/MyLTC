#!/usr/bin/env bash
# MyLTC — instalador do rice (Arch Linux + Hyprland)
#   ./install.sh            instala pacotes + configs (faz backup do que já existe)
#   ./install.sh --no-deps  só copia as configs
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
backup="$HOME/.config/myltc-backup-$(date +%Y%m%d-%H%M%S)"

say() { printf '\033[38;2;255;45;57m==>\033[0m %s\n' "$*"; }

pacman_deps=(
    hyprland quickshell qt6-svg qt6-imageformats
    foot fuzzel hyprlock hypridle hyprsunset hyprpicker
    wl-clipboard cliphist grim slurp wf-recorder libnotify
    brightnessctl playerctl wireplumber btop cava cmatrix fastfetch imagemagick
    fish starship eza bat zoxide fzf
    adw-gtk-theme papirus-icon-theme adwaita-fonts adwaita-cursors ttf-jetbrains-mono-nerd
    plasma-integration breeze rofimoji dolphin
)
aur_deps=(pwvucontrol tty-clock)

if [[ "${1:-}" != "--no-deps" ]]; then
    say "Instalando pacotes do repositório oficial"
    sudo pacman -S --needed "${pacman_deps[@]}"
    if command -v yay >/dev/null; then
        say "Instalando pacotes do AUR (yay)"
        yay -S --needed "${aur_deps[@]}"
    else
        say "yay não encontrado: instale manualmente do AUR: ${aur_deps[*]}"
    fi
fi

say "Backup das configs atuais em $backup"
mkdir -p "$backup"
(cd "$repo/config" && find . -type f) | while read -r f; do
    if [[ -e "$HOME/$f" ]]; then
        mkdir -p "$backup/$(dirname "$f")"
        cp -a "$HOME/$f" "$backup/$f"
    fi
done

say "Copiando configs"
cp -a "$repo/config/." "$HOME/"
chmod +x "$HOME"/.config/hypr/scripts/* "$HOME"/.config/quickshell/scripts/*

say "Baixando wallpapers (créditos no README)"
mkdir -p "$HOME/Pictures/wallpapers"
curl -fsSL -o "$HOME/Pictures/wallpapers/japan-9mdyz8.png" https://w.wallhaven.cc/full/9m/wallhaven-9mdyz8.png || true
curl -fsSL -o "$HOME/Pictures/wallpapers/japan-r2z7lm.jpg" https://w.wallhaven.cc/full/r2/wallhaven-r2z7lm.jpg || true

say "Logo do fastfetch"
mkdir -p "$HOME/.config/fastfetch/logos"
cp -a "$repo/assets/Arch-fastfetch-red.png" "$HOME/.config/fastfetch/logos/"

say "Tema escuro (GTK) e cursor"
for kv in "gtk-theme 'adw-gtk3-dark'" "icon-theme 'Papirus-Dark'" "color-scheme 'prefer-dark'" \
    "cursor-theme 'Adwaita'" "cursor-size 24" "font-name 'Adwaita Sans 11'" \
    "monospace-font-name 'JetBrainsMono Nerd Font 11'" "accent-color 'red'"; do
    eval gsettings set org.gnome.desktop.interface "$kv" 2>/dev/null || true
done

say "Esquema de cores MyLTC para apps KDE/Qt (kdeglobals)"
{
    sed '/^\[General\]/,/^$/d' "$HOME/.local/share/color-schemes/MyLTC.colors"
    printf '\n[General]\nColorScheme=MyLTC\nTerminalApplication=foot\n\n[Icons]\nTheme=Papirus-Dark\n\n[KDE]\nwidgetStyle=Breeze\n'
} >"$HOME/.config/kdeglobals"

say "Notificações pelo shell MyLTC (desativa o dunst, se existir)"
systemctl --user mask dunst.service 2>/dev/null || true

read -rp "Instalar a regra do polkit para o botão de VPN (networkctl up/down wg0)? [s/N] " vpn
if [[ "$vpn" =~ ^[sS]$ ]]; then
    sed "s/@USER@/$USER/g" "$repo/system/50-vpn-casa.rules" | sudo tee /etc/polkit-1/rules.d/50-vpn-casa.rules >/dev/null
fi

say "Pronto! Saia e entre de novo no Hyprland (ou rode: hyprctl reload && qs -d)."
