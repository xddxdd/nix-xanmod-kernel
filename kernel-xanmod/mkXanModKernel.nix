{
  lib,
  callPackage,
  buildLinux,
  stdenv,
  kernelPatches,
  applyPatches,
  impureUseNativeOptimizations,
  ...
}:
lib.makeOverridable (
  {
    pname,
    version,
    src,

    # Real-time kernel, uses upstream CONFIGS/x86_64/config-rt as base
    # configuration and prefixes localversion with "-rt"
    rt ? false,

    # Set to one of "none", "thin" or "full", anything other than "none" uses Clang
    # to build the kernel with the selected LTO option
    lto ? "none",

    # Patches to be applied in patchedSrc phase. This is different from buildLinux's kernelPatches.
    prePatch ? "",
    patches ? [ ],
    postPatch ? "",

    # XanMod fine tuning settings, see ./xanmodSettings.nix for corresponding options
    # Tuning defaults follow the upstream config files (CONFIGS/x86_64/config and
    # config-rt) shipped inside the source tarball. Set to null or false to disable.
    hzTicks ? "250",
    tickrate ? "idle",
    # Real-time kernels use PREEMPT=y like upstream config-rt
    preemptType ? (if rt then "full" else "lazy"),
    hugepage ? "always",
    # Generic baseline so unsuffixed kernels run on any x86_64 machine
    processorOpt ? "x86_64-v1",

    # AutoFDO settings
    # AutoFDO hasn't been fully tested. Please report issue if you encounter any.
    #
    # false - Disable AutoFDO
    # true - Enable AutoFDO for profiling performance patterns only
    # ./path/to/autofdo/profile: Enable AutoFDO with specified profile
    autofdo ? false,

    # Build as much components as possible as kernel modules, including disabled ones.
    # This can enable unexpected modules, such as nova_core.
    # https://github.com/xddxdd/nix-cachyos-kernel/issues/13
    #
    # Disabling this causes boot issues for me. Reenabling.
    autoModules ? true,

    # See nixpkgs/pkgs/os-specific/linux/kernel/generic.nix for additional options.
    # Additional args are passed to buildLinux.
    ...
  }@args:

  # AutoFDO requires Clang compiler
  assert autofdo != false -> lto != "none";

  let
    helpers = callPackage ../helpers.nix { };
    inherit (helpers) stdenvLLVM ltoMakeflags;

    # Upstream version, e.g. "7.2.4-xanmod1" or "6.18.49-rt-xanmod1" for
    # real-time kernels, where the "xanmod" part matches the localversion
    # file in the source tree and can be "xanmod2" etc. on new releases
    versionMatch = builtins.match "(.*)-(xanmod[0-9]*)" version;
    versionBase = if versionMatch == null then version else lib.elemAt versionMatch 0;
    xanmodLocalversion = if versionMatch == null then "" else "-${lib.elemAt versionMatch 1}";

    # Upstream versions of real-time kernels are suffixed with "-rt",
    # which is carried inside CONFIG_LOCALVERSION instead of the version
    baseVersion = lib.removeSuffix "-rt" versionBase;

    # For use in moddirversion
    fullVersion = lib.versions.pad 3 baseVersion;

    # Follow upstream localversion scheme:
    #
    # - the "localversion" file in the source tree contains "-xanmod1"
    # - CONFIG_LOCALVERSION carries the psABI suffix, e.g. "-x64v2",
    #   or "-rt-x64v2" for real-time kernels
    #
    # resulting in a kernel release like "7.2.4-x64v2-xanmod1"
    processorLocalversion = {
      x86_64-v1 = "-x64v1";
      x86_64-v2 = "-x64v2";
      x86_64-v3 = "-x64v3";
      x86_64-v4 = "-x64v4";
      zen4 = "-zen4";
      native = "-native";
    }.${processorOpt};
    localversion = (lib.optionalString rt "-rt") + processorLocalversion;

    # buildLinux doesn't accept postPatch, so adding config file early here
    patchedSrc = applyPatches {
      name = "linux-src-patched";
      inherit src;
      patches = [
        kernelPatches.bridge_stp_helper.patch
        kernelPatches.request_key_helper.patch
      ] ++ patches;

      inherit prePatch;
      postPatch = ''
        install -Dm644 ${if rt then "CONFIGS/x86_64/config-rt" else "CONFIGS/x86_64/config"} arch/x86/configs/xanmod_defconfig
      '' + postPatch;
    };

    xanmodSettings = callPackage ./xanmodSettings.nix { };
    structuredExtraConfig =
      # Apply basic kernel options
      (with lib.kernel; {
        NR_CPUS = lib.mkForce (option (freeform "8192"));

        # Follow NixOS default config to not break etc overlay
        OVERLAY_FS = module;
        OVERLAY_FS_REDIRECT_DIR = no;
        OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW = yes;
        OVERLAY_FS_INDEX = no;
        OVERLAY_FS_XINO_AUTO = no;
        OVERLAY_FS_METACOPY = no;
        OVERLAY_FS_DEBUG = no;

        # Fix HID_HAPTIC linking error
        HID = yes;
      })

      # Apply XanMod specific settings
      // (lib.mapAttrs (_: lib.mkForce) (
        (with lib.kernel; {
          LOCALVERSION = freeform localversion;
        })
        // xanmodSettings.lto."${lto}"
        // (lib.optionalAttrs (hzTicks != null) xanmodSettings.hzTicks."${hzTicks}")
        // (lib.optionalAttrs (tickrate != null) xanmodSettings.tickrate."${tickrate}")
        // (lib.optionalAttrs (preemptType != null) xanmodSettings.preemptType."${preemptType}")
        // (lib.optionalAttrs (hugepage != null) xanmodSettings.hugepage."${hugepage}")
        // (lib.optionalAttrs (processorOpt != null) xanmodSettings.processorOpt.${processorOpt})
        // (lib.optionalAttrs (autofdo != false) {
          AUTOFDO_CLANG = lib.kernel.yes;
        })
      ))

      # Apply user custom settings
      // (args.structuredExtraConfig or { });
  in
  buildLinux (
    (lib.removeAttrs args [
      "pname"
      "version"
      "src"
      "rt"
      "lto"
      "prePatch"
      "patches"
      "postPatch"
    ])
    // {
      inherit pname version;
      src = patchedSrc;

      stdenv =
        # Apply native optimization on top of stdenv if requested
        (if processorOpt == "native" then impureUseNativeOptimizations else lib.id)
          # Select stdenv/stdenvLLVM based on requested compiler
          (args.stdenv or (if lto == "none" then stdenv else stdenvLLVM));

      extraMakeFlags =
        (lib.optionals (lto != "none") ltoMakeflags)
        ++ lib.optionals (builtins.isPath autofdo) [
          "CLANG_AUTOFDO_PROFILE=${autofdo}"
        ]
        ++ (args.extraMakeFlags or [ ]);

      defconfig = args.defconfig or "xanmod_defconfig";

      modDirVersion = args.modDirVersion or "${fullVersion}${localversion}${xanmodLocalversion}";

      # XanMod's config has some unused options for older kernel versions
      ignoreConfigErrors = args.ignoreConfigErrors or true;

      inherit structuredExtraConfig autoModules;

      extraMeta = {
        description =
          "Linux XanMod Kernel"
          + lib.optionalString rt " (real-time)"
          + lib.optionalString (lto == "thin") " with Clang+ThinLTO"
          + lib.optionalString (lto == "full") " with Clang+FullLTO";
        broken = !stdenv.hostPlatform.isx86_64;
      }
      // (args.extraMeta or { });
    }
  )
)
