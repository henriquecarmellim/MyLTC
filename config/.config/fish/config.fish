# MyLTC — fish
if status is-interactive
    set -g fish_greeting # sem mensagem de boas-vindas

    # Cores da linha de comando (paleta latenci.in)
    set -g fish_color_command ff5b64
    set -g fish_color_param f4f4f5
    set -g fish_color_quote ff858c
    set -g fish_color_error ff2d39 --bold
    set -g fish_color_autosuggestion 5c5c66
    set -g fish_color_comment 5c5c66
    set -g fish_color_operator a0a0aa
    set -g fish_color_redirection a0a0aa
    set -g fish_color_valid_path --underline
    set -g fish_pager_color_prefix ff2d39 --bold
    set -g fish_pager_color_progress a0a0aa

    # Atalhos de comando
    alias ls 'eza --icons --group-directories-first'
    alias ll 'eza -l --icons --group-directories-first --git'
    alias la 'eza -la --icons --group-directories-first --git'
    alias tree 'eza --tree --icons'
    alias cat 'bat --paging=never'
    alias relogio 'tty-clock -c -s -B -C 1'
    alias visualizador 'cava'
    alias matrix 'cmatrix -b -u 3 -C red'

    starship init fish | source
    zoxide init fish --cmd cd | source
    fzf --fish | source

    # fastfetch ao abrir um terminal novo
    fastfetch
end
