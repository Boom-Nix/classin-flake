# package.nix
# 运行方式: nix-build package.nix

{ pkgs ? import <nixpkgs> {} }:

let
  # 2. 从 pkgs 中解构出所有需要的组件 (包含所有已识别的依赖 e2fsprogs, xorg 集合)
  inherit (pkgs) stdenv fetchurl writeShellScript writeText electron steam lib xz e2fsprogs xorg; 

  pname = "classin";
  version = "6.0.4.3227";

  # --- 1. ClassIn 资源包 ---
  resource = stdenv.mkDerivation {
    name = "${pname}-resource-${version}";

    src = fetchurl {
      url = "https://www.eeo.cn/download/client/${pname}_${version}_amd64.deb";
      sha256 = "sha256-a3zip/Jn3zjaLgqybI6ZdzNM9dsrhVO3wuvwyV7xGoI=";
    };

    nativeBuildInputs = [ stdenv.cc.bintools pkgs.xz ];
    dontFixup = true;

    unpackPhase = ''
      echo "1. 提取 .deb 归档..."
      ar x $src
    '';

    installPhase = ''
      echo "2. 将文件复制到 $out 路径..."
      mkdir -p $out
      tar xf data.tar.xz -C $out
    '';
  };

  # --- 2. Steam-Run 虚拟环境 (包含所有已知的运行时依赖) ---
  steam-run = (steam.override {
    extraPkgs = p: [ 
      resource
      # 解决 libcom_err.so.2
      e2fsprogs 
      # 解决 libICE.so.6, libSM.so.6, 并添加其他常见的 X11 依赖
      xorg.libICE 
      xorg.libSM 
      xorg.libX11
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libXcursor
      xorg.libxcb
    ]; 
  }).run;

  # --- 3. 启动脚本 (使用 FHS 路径 /opt) ---
  # FHS 环境中 ClassIn AppRun 期望的路径
  FHS_CLASSIN_BIN="/opt/apps/classin/AppRun";

  startScript = writeShellScript "classin" ''
    echo "尝试在 FHS 环境的 ${FHS_CLASSIN_BIN} 路径启动 ClassIn ${version}..."
    
    # 直接在 steam-run 隔离环境中执行 FHS 路径 /opt/apps/classin/AppRun
    ${steam-run}/bin/steam-run sh -c "exec ${FHS_CLASSIN_BIN} \$@"
  '';

  # --- 4. 桌面文件 ---
  desktopFile = writeText "classin.desktop" ''
    [Desktop Entry]
    Name=ClassIn
    Comment=ClassIn Online Classroom
    Exec=${startScript}
    Terminal=false
    Type=Application
    Icon=${resource}/usr/share/icons/hicolor/scalable/apps/classin.svg
    Categories=Education;
  '';

in
# --- 5. 主包定义 ---
stdenv.mkDerivation {
  inherit pname version;

  phases = [ "installPhase" ];

  installPhase = ''
    echo "安装启动脚本和桌面文件到 $out..."
    mkdir -p $out/bin $out/share/applications $out/share/icons

    ln -s ${startScript} $out/bin/${pname}
    ln -s ${desktopFile} $out/share/applications/${pname}.desktop
    mkdir -p $out/share/icons/hicolor
    ln -s ${resource}/usr/share/icons/hicolor $out/share/icons/hicolor
  '';
}