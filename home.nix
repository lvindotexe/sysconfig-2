{ config, pkgs, lib, ... }:

let
  secretsFile = ./secrets.yaml;
  hasSecrets = builtins.pathExists secretsFile;
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "alvinv";
  home.homeDirectory = "/Users/alvinv";

  # Prefer XDG locations like ~/.config/...
  xdg.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # First activation can require `--backup-file-extension hm-bak` to move any
  # pre-existing dotfiles aside (e.g. ~/.zshrc -> ~/.zshrc.hm-bak).

  home.sessionVariables = {
    CLICOLOR = "1";
    LESS = "-FRX";
    PAGER = "less";
  };

  home.shellAliases = {
    cat = "bat";
    grep = "rg";
    ls = "eza -lah --group-directories-first --git";
  };

  home.packages = with pkgs; [
    age
    bat
    eza
    fd
    jq
    ripgrep
    sops
    yt-dlp
    vim

    deno
    nodejs_25
    go
    bun

    docker
    ffmpeg
    htop
    tree
    moreutils
    tmux

    # history substring search widget for zsh
    zsh-history-substring-search
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    changeDirWidgetCommand = "fd --type d";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./dotfiles/starship/starship.toml);
  };

  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/tmux/tmux.conf;
  };

  programs.gh = {
    # Whether to enable the GitHub CLI (gh).
    enable = true;

    # Written to `$XDG_CONFIG_HOME/gh/config.yml`.
    settings = {
      # What protocol to use when performing git operations. Supported values: ssh, https
      git_protocol = "ssh";
      # What editor gh should run when creating issues, pull requests, etc. If blank, will refer to environment.
      editor = "";
      # When to interactively prompt. This is a global config that cannot be overridden by hostname. Supported values: enabled, disabled
      prompt = "enabled";
      # Preference for editor-based interactive prompting. This is a global config that cannot be overridden by hostname. Supported values: enabled, disabled
      prefer_editor_prompt = "disabled";
      # A pager program to send command output to, e.g. "less". If blank, will refer to environment. Set the value to "cat" to disable the pager.
      pager = "";

      # Aliases allow you to create nicknames for gh commands
      aliases = {
        # `gh co` -> `gh pr checkout`
        co = "pr checkout";
      };

      # The path to a unix socket through which to send HTTP connections. If blank, HTTP traffic will be handled by net/http.DefaultTransport.
      http_unix_socket = "";
      # What web browser gh should use when opening URLs. If blank, will refer to environment.
      browser = "";
      # Whether to display labels using their RGB hex color codes in terminals that support truecolor. Supported values: enabled, disabled
      color_labels = "disabled";
      # Whether customizable, 4-bit accessible colors should be used. Supported values: enabled, disabled
      accessible_colors = "disabled";
      # Whether an accessible prompter should be used. Supported values: enabled, disabled
      accessible_prompter = "disabled";
      # Whether to use a animated spinner as a progress indicator. If disabled, a textual progress indicator is used instead. Supported values: enabled, disabled
      spinner = "enabled";
    };

    # Written to `$XDG_CONFIG_HOME/gh/hosts.yml`.
    hosts = {
      # Per-host gh settings for github.com.
      "github.com" = {
        # What protocol to use when performing git operations. Supported values: ssh, https
        git_protocol = "ssh";
        # The default GitHub username for this host.
        user = "lvindotexe";
      };
    };
  };

  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "catppuccin-mocha";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Silence upcoming default change warnings.
    dotDir = config.home.homeDirectory;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    # "Fancy" split: keep the large/complex stuff in a normal file, but still
    # let Home Manager generate/manage ~/.zshrc.
    initContent = lib.mkMerge [
      (lib.mkBefore (builtins.readFile ./dotfiles/zshrc))
      ''
        # history substring search plugin
        if [[ -f ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
          source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        fi

        setopt AUTO_CD
        setopt INTERACTIVE_COMMENTS
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_REDUCE_BLANKS

        bindkey -e
        bindkey "^[[A" history-substring-search-up
        bindkey "^[[B" history-substring-search-down
      ''
    ];
  };

  # Optional secrets support via sops-nix.
  # This is a no-op unless ./secrets.yaml exists.
  # sops = lib.mkIf hasSecrets {
  #   defaultSopsFile = secretsFile;
  #   age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  # };
}
