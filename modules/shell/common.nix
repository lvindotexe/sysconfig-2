{ ... }:

{
  home.shellAliases = import ./aliases.nix;

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    changeDirWidgetCommand = "fd --type d";
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
      format = "$username$hostname$directory$git_branch$git_status$nodejs$python$cmd_duration$status$character";

      username = {
        show_always = false;
        style_user = "bold mauve";
        style_root = "bold red";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = true;
        style = "bold mauve";
        format = "[@$hostname]($style) ";
      };

      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " ";
      };

      git_branch = {
        style = "bold green";
        format = "[$symbol$branch]($style) ";
        symbol = " ";
      };

      git_status = {
        style = "yellow";
        format = "[$all_status$ahead_behind]($style) ";
      };

      nodejs = {
        style = "green";
        format = "[ $version]($style) ";
      };

      python = {
        style = "yellow";
        format = "[ $version]($style) ";
      };

      cmd_duration = {
        min_time = 400;
        style = "peach";
        format = "[took $duration]($style) ";
      };

      status = {
        disabled = false;
        symbol = "✗";
        style = "red";
        format = "[$symbol $status]($style) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };
}
