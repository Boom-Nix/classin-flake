Classin for NixOS Flakes  
For installing:  
Added this flake in your flake.nix inputs:  
  
inputs = {  
    ...other inputs such as nixpkgs...  
    classin = {  
      url = "github:Boom-Nix/classin-flake";  
      inputs.nixpkgs.follows = "nixpkgs";  
    };  
    .......  
  };  


And add these codes in your system config in case you are cjk:  
fonts = {  
    fonts = with pkgs; [  
      noto-fonts  
      noto-fonts-cjk-sans  
      noto-fonts-emoji  
      source-code-pro  
      source-han-mono  
      source-han-sans  
      source-han-serif  
    ];  
    fontDir.enable = true;  
    fontconfig.enable = true;  
    enableDefaultFonts = true;  
    fontconfig.defaultFonts = {  
      emoji = [ "Noto Color Emoji" ];  
      monospace = [ "Source Han Mono" ];  
      sansSerif = [ "Noto Sans CJK SC" ];  
      serif = [ "Source Han Serif" ];  
  };  
 };  
