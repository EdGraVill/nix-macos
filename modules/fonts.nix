{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    cascadia-code
    inter
    open-sans
  ];
}
