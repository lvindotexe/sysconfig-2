{ ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      eval "$(wt config shell init bash)"
    '';
  };
}
