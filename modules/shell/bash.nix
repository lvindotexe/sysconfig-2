{ ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = builtins.readFile ../../dotfiles/bashrc;
  };
}
