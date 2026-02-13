{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "alvin";
        email = "lvindotexe@github.com";
      };
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

}
