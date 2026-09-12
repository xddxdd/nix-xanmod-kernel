{
  callPackage,
  lib,
  fetchurl,
  ...
}:
let
  mkXanmodKernel = callPackage ./mkXanModKernel.nix { };

  linuxSources = lib.mapAttrs (_: v: {
    inherit (v) version;
    src = fetchurl {
      inherit (v) url hash;
    };
  }) (lib.importJSON ./version.json);
in
{
  # Stable Mainline kernel
  # The unsuffixed package uses generic x86_64-v1 for baseline compatibility
  linux-xanmod-main = mkXanmodKernel {
    pname = "linux-xanmod-main";
    inherit (linuxSources.linux-xanmod-main) version src;
  };
  linux-xanmod-main-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-main-x86_64-v2";
    inherit (linuxSources.linux-xanmod-main) version src;
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-main-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-main-x86_64-v3";
    inherit (linuxSources.linux-xanmod-main) version src;
    processorOpt = "x86_64-v3";
  };
  linux-xanmod-main-lto = mkXanmodKernel {
    pname = "linux-xanmod-main-lto";
    inherit (linuxSources.linux-xanmod-main) version src;
    lto = "thin";
  };
  linux-xanmod-main-lto-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-main-lto-x86_64-v2";
    inherit (linuxSources.linux-xanmod-main) version src;
    lto = "thin";
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-main-lto-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-main-lto-x86_64-v3";
    inherit (linuxSources.linux-xanmod-main) version src;
    lto = "thin";
    processorOpt = "x86_64-v3";
  };

  # Long Term Support kernel
  # The unsuffixed package uses generic x86_64-v1 for baseline compatibility
  linux-xanmod-lts = mkXanmodKernel {
    pname = "linux-xanmod-lts";
    inherit (linuxSources.linux-xanmod-lts) version src;
  };
  linux-xanmod-lts-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-lts-x86_64-v2";
    inherit (linuxSources.linux-xanmod-lts) version src;
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-lts-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-lts-x86_64-v3";
    inherit (linuxSources.linux-xanmod-lts) version src;
    processorOpt = "x86_64-v3";
  };
  linux-xanmod-lts-lto = mkXanmodKernel {
    pname = "linux-xanmod-lts-lto";
    inherit (linuxSources.linux-xanmod-lts) version src;
    lto = "thin";
  };
  linux-xanmod-lts-lto-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-lts-lto-x86_64-v2";
    inherit (linuxSources.linux-xanmod-lts) version src;
    lto = "thin";
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-lts-lto-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-lts-lto-x86_64-v3";
    inherit (linuxSources.linux-xanmod-lts) version src;
    lto = "thin";
    processorOpt = "x86_64-v3";
  };

  # Rolling Release kernel
  # The unsuffixed package uses generic x86_64-v1 for baseline compatibility
  linux-xanmod-edge = mkXanmodKernel {
    pname = "linux-xanmod-edge";
    inherit (linuxSources.linux-xanmod-edge) version src;
  };
  linux-xanmod-edge-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-edge-x86_64-v2";
    inherit (linuxSources.linux-xanmod-edge) version src;
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-edge-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-edge-x86_64-v3";
    inherit (linuxSources.linux-xanmod-edge) version src;
    processorOpt = "x86_64-v3";
  };
  linux-xanmod-edge-lto = mkXanmodKernel {
    pname = "linux-xanmod-edge-lto";
    inherit (linuxSources.linux-xanmod-edge) version src;
    lto = "thin";
  };
  linux-xanmod-edge-lto-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-edge-lto-x86_64-v2";
    inherit (linuxSources.linux-xanmod-edge) version src;
    lto = "thin";
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-edge-lto-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-edge-lto-x86_64-v3";
    inherit (linuxSources.linux-xanmod-edge) version src;
    lto = "thin";
    processorOpt = "x86_64-v3";
  };

  # Real-time kernel
  # The unsuffixed package uses generic x86_64-v1 for baseline compatibility
  linux-xanmod-rt = mkXanmodKernel {
    pname = "linux-xanmod-rt";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
  };
  linux-xanmod-rt-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-rt-x86_64-v2";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-rt-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-rt-x86_64-v3";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
    processorOpt = "x86_64-v3";
  };
  linux-xanmod-rt-lto = mkXanmodKernel {
    pname = "linux-xanmod-rt-lto";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
    lto = "thin";
  };
  linux-xanmod-rt-lto-x86_64-v2 = mkXanmodKernel {
    pname = "linux-xanmod-rt-lto-x86_64-v2";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
    lto = "thin";
    processorOpt = "x86_64-v2";
  };
  linux-xanmod-rt-lto-x86_64-v3 = mkXanmodKernel {
    pname = "linux-xanmod-rt-lto-x86_64-v3";
    inherit (linuxSources.linux-xanmod-rt) version src;
    rt = true;
    lto = "thin";
    processorOpt = "x86_64-v3";
  };
}