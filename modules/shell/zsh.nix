{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.zsh-history-substring-search
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;

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

    initContent = ''
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

        eval "$(wt config shell init zsh)"
    '';
  };
}
