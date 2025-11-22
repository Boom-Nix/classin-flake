# flake.nix

{
  description = "ClassIn application package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      # 1. 解构出 lib
      lib = nixpkgs.lib;
    in
    {
      # 导出 NixOS 模块 (如果您想用 Flake 管理整个系统)
      nixosModules.classin = { config, pkgs, ... }: {
        environment.systemPackages = [ config.packages.classin ];
      };

      # 2. 导出 packages
      packages = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          # 🌟 关键修改：导入配置了 allowUnfree = true 的 pkgs 集合
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true; # 允许非自由包
            };
          };
        in
        {
          # 实例化并导出 classin 包 (使用配置过的 pkgs)
          classin = pkgs.callPackage ./package.nix {};
          
          # 方便用户安装的 defaultPackage
          defaultPackage = self.packages.${system}.classin;
        }
      );
      
      # 3. 确保 'nix develop' 可用 (同样使用允许 unfree 的 pkgs)
      devShells = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        let
          # 🌟 关键修改：导入配置了 allowUnfree = true 的 pkgs 集合
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true; # 允许非自由包
            };
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixpkgs-fmt # 格式化工具
            ];
          };
        }
      );
    };
}