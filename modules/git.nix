{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
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
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases.co = "pr checkout";
    };
    hosts."github.com" = {
      git_protocol = "ssh";
      user = "lvindotexe";
    };
  };
}
