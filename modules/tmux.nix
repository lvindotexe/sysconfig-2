{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    mouse = true;
    escapeTime = 0;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];

    extraConfig = ''
      set -as terminal-features ",xterm-256color:RGB"

      # Status line at bottom
      set -g status-position bottom

      # Vim-like pane navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      # Reload config
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded"

      # Vim-like resizing (prefix + H/J/K/L)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Copy mode
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

      # Catppuccin Mocha status line
      set -g status on
      set -g status-interval 2
      set -g status-style "bg=#11111b,fg=#cdd6f4"
      set -g message-style "bg=#11111b,fg=#cdd6f4"
      set -g pane-border-style "fg=#45475a"
      set -g pane-active-border-style "fg=#a6e3a1"
      set -g window-status-separator "  "
      set -g window-status-style "bg=#11111b,fg=#bac2de"
      set -g window-status-current-style "bg=#11111b,fg=#cdd6f4,bold"
      set -g status-left-length 60
      set -g status-left "#[bg=#11111b,fg=#cdd6f4,bold]  #S  #[default]"
      set -g status-right-length 160
      set -g status-right "#[bg=#11111b,fg=#bac2de]  #{pane_current_path}  #[fg=#cdd6f4]%Y-%m-%d %H:%M #[fg=#bac2de]#H  #[default]"
      setw -g window-status-format "#I:#W"
      setw -g window-status-current-format "#I:#W"
    '';
  };
}
