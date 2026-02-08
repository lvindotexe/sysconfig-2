{ config, pkgs, lib, ... }:

let
  hasGhosttySupport = pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux;
in
{
  imports = [
    ./modules/shell/common.nix
    ./modules/shell/bash.nix
    ./modules/shell/zsh.nix
  ];

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
  # pre-existing dotfiles aside (e.g. ~/.bashrc -> ~/.bashrc.hm-bak).

  home.sessionVariables = {
    CLICOLOR = "1";
    LESS = "-FRX";
    PAGER = "less";
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  # Ensure Nix-provided tools win over macOS system binaries.
  # This also makes `vim` resolve to the Home Manager/Nix shim when enabled.
  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.opencode/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/code/mfe-dev/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/run/current-system/sw/bin"
  ];

  home.packages = with pkgs; [
    bat
    jq
    ripgrep
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
    gh

  ];


  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        viAlias = false;
        vimAlias = true;

        # Show absolute number on current line and relative numbers elsewhere.
        lineNumberMode = "relNumber";

        lsp = {
          enable = true;
        };

        # Enable language modules for the toolchains you have installed.
        languages = {
          go.enable = true;
          ts.enable = true;
        };
      };
    };
  };


  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/tmux/tmux.conf;
  };

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";

      core = {
        editor = "vim";
        excludesfile = "~/.gitignore_global";
      };

      color.ui = "auto";

      fetch.prune = true;
      pull.ff = "only";
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      rerere.enabled = true;
      merge.conflictstyle = "zdiff3";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

      help.autocorrect = "prompt";

    };
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

  programs.ghostty = lib.mkIf hasGhosttySupport (lib.mkMerge [
    {
      enable = true;
      settings = {
        theme = "Catppuccin Mocha";
      };
    }
    (lib.mkIf pkgs.stdenv.isDarwin {
      package = null;
      systemd.enable = false;
    })
  ]);

}
