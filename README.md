# Nix packages for XanMod Kernel

This repo contains Linux kernels with XanMod patches and tunings from the official [XanMod GitLab repository](https://gitlab.com/xanmod/linux).

## Which kernel versions are provided?

This repo provides the following kernel variants, consistent with the [upstream definitions](https://xanmod.org):

```bash
└───packages
    └───x86_64-linux
        # Main branch kernel, provides all LTO/CPU arch variants
        ├───linux-xanmod-main
        ├───linux-xanmod-main-x86_64-v2 (no binary cache)
        ├───linux-xanmod-main-x86_64-v3
        ├───linux-xanmod-main-lto
        ├───linux-xanmod-main-lto-x86_64-v2 (no binary cache)
        ├───linux-xanmod-main-lto-x86_64-v3
        # LTS kernel, provides all LTO/CPU arch variants (no binary cache)
        ├───linux-xanmod-lts
        ├───linux-xanmod-lts-x86_64-v2
        ├───linux-xanmod-lts-x86_64-v3
        ├───linux-xanmod-lts-lto
        ├───linux-xanmod-lts-lto-x86_64-v2
        ├───linux-xanmod-lts-lto-x86_64-v3
        # Edge branch kernel, provides all LTO/CPU arch variants (no binary cache)
        ├───linux-xanmod-edge
        ├───linux-xanmod-edge-x86_64-v2
        ├───linux-xanmod-edge-x86_64-v3
        ├───linux-xanmod-edge-lto
        ├───linux-xanmod-edge-lto-x86_64-v2
        ├───linux-xanmod-edge-lto-x86_64-v3
        # Real-time kernel, provides all LTO/CPU arch variants (no binary cache)
        ├───linux-xanmod-rt
        ├───linux-xanmod-rt-x86_64-v2
        ├───linux-xanmod-rt-x86_64-v3
        ├───linux-xanmod-rt-lto
        ├───linux-xanmod-rt-lto-x86_64-v2
        └───linux-xanmod-rt-lto-x86_64-v3
```

`x86_64-v4` and `zen4` variants are not provided as packages: according to the
[psABI level reference table](https://xanmod.org/) on XanMod's website, `x86-64-v4`
(AVX-512) brings no kernel benefit. You can still enable them via the `processorOpt`
argument when overriding the kernel.

The kernel versions are automatically kept in sync with upstream XanMod releases via a daily GitHub Action (see [kernel-xanmod/update.py](kernel-xanmod/update.py)), so once XanMod updates their kernels, this repo will automatically catch up. The script reads kernel versions from the meta packages in the [XanMod APT repository](http://deb.xanmod.org), prefetches the corresponding source tarballs from GitLab into [kernel-xanmod/version.json](kernel-xanmod/version.json), and is also exposed as the `update-xanmod` flake app.

Use `nix flake show github:xddxdd/nix-xanmod-kernel/release` to see the current effective versions.

The kernels ending in `-lto` have Clang+ThinLTO enabled.

Kernel releases follow upstream naming, e.g. `7.2.4-x64v3-xanmod1` for the x86_64-v3 variant and `6.18.49-rt-x64v2-xanmod1` for the real-time variant, matching the kernels distributed in the XanMod APT repository.

For each linux kernel entry under `packages`, we have a corresponding `linuxPackages` entry under `legacyPackages` for easier use in your NixOS configuration, e.g.:

- `linux-xanmod-main` -> `inputs.nix-xanmod-kernel.legacyPackages.x86_64-linux.linuxPackages-xanmod-main`
- `linux-xanmod-lts-lto` -> `inputs.nix-xanmod-kernel.legacyPackages.x86_64-linux.linuxPackages-xanmod-lts-lto`

## How to use kernels

#### Flakes

Add the `release` branch of this repo to the inputs section of your `flake.nix`:

```nix
{
  inputs = {
    nix-xanmod-kernel.url = "github:xddxdd/nix-xanmod-kernel/release";
    # Do not override its nixpkgs input, otherwise brand new kernels may fail
    # to build with older nixpkgs kernel build machinery, or miss the binary cache
  }
}
```

The `release` branch contains the latest kernel that has been built by my [Hydra CI](https://hydra.lantian.pub/jobset/lantian/nix-xanmod-kernel) and is present in binary cache.

> If you want the absolute latest version with or without binary cache, use the `master` branch (default branch) instead:
>
> ```nix
> {
>   inputs = {
>         nix-xanmod-kernel.url = "github:xddxdd/nix-xanmod-kernel";
>   }
> }
> ```

Add the repo's overlay in your NixOS configuration, this will expose the packages in this flake as `pkgs.xanmodKernels.*`.

```nix
{
  outputs = { nix-xanmod-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [
              # Use the exact nixpkgs revision as defined in this repo to ensure binary cache hits.
              nix-xanmod-kernel.overlays.pinned

              # Alternatively, use nixpkgs from your environment, nixpkgs.config will apply.
              # Note: may not hit binary cache; kernel will need to be built locally.
              # nix-xanmod-kernel.overlays.default

              # Only use one of the two overlays!
            ];

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

Then specify `pkgs.xanmodKernels.linuxPackages-xanmod-main` (or other variants you'd like) in your `boot.kernelPackages` option.

> **`pinned` overlay is recommended** to ensure binary cache hits. The `pinned` overlay uses the exact nixpkgs revision defined in this flake, matching what was used to build the cached kernels. With the `default` overlay, a different nixpkgs revision may cause cache misses and trigger local kernel compilation even if a cached kernel is available.
>
> Use `pinned` if:
>
> - You want to ensure that you can fetch kernel from binary cache.
> - You want to make sure that the kernel can be built successfully.
>
> Use `default` if:
>
> - You want to avoid initializing multiple instances of nixpkgs.
> - You want to use latest kernel modules that are just merged/updated within nixpkgs.
> - You want to customize `nixpkgs.config` options.

#### Non-Flakes

This flake is usable in non-flakes nix configuration using npins and the following snippet:

Npins commands:

```bash
npins init
npins add github xddxdd nix-xanmod-kernel
```

```nix
let
  sources = import ./npins/default.nix;
  xanmod-source = import sources.nix-xanmod-kernel;
  xanmod-kernel =
    xanmod-source.outputs.legacyPackages.x86_64-linux.linuxPackages-xanmod-main-lto-x86_64-v3;
in
{
  boot.kernelPackages = xanmod-kernel;
}
```

You may also fetch the flakes directly using fetchFromGitHub,
but note that you will have to manually update the revision and hash to update your kernel, which is tedious.

### Binary cache

The binary cache is automatically configured via [`nixConfig`](flake.nix:12-19) in this flake, so Nix will prompt you to accept it when you first use this repo.

I'm running a Hydra CI to build the kernels and push them to my Attic binary cache. You can see the build status here: <https://hydra.lantian.pub/jobset/lantian/nix-xanmod-kernel>

Due to build capacity limitations, kernels of the `lts`, `edge` and `rt` branches, as well as `x86_64-v2` variants, are not built.

If you prefer to manually configure the binary cache (or are not using flakes), add the following config:

```nix
{
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
}
```

**Important:** As with all binary caches, after adding binary cache to your NixOS configuration, please apply your settings once before enabling XanMod kernel, so that the binary cache settings can take effect.

### Example configuration

```nix
{
  outputs = { nix-xanmod-kernel, ... }: {
    nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          { pkgs, ... }: {
            nixpkgs.overlays = [ nix-xanmod-kernel.overlays.pinned ];
            boot.kernelPackages = pkgs.xanmodKernels.linuxPackages-xanmod-main;

            # Binary cache is auto-configured via nixConfig in flake.nix,
            # no additional binary cache config is needed.

            # ... your other configs
          }
        )
      ];
    };
  };
}
```

### Help! My kernel is failing to build!

In most cases, failing to build a kernel is caused by incompatibilities between the nixpkgs kernel build machinery and a brand new kernel version, which will be fixed in a future nixpkgs revision.

## How to customize XanMod kernel

The kernels provided in this flake can be overridden to use your own kernel source. This is helpful if you want to use a kernel version not available in Nixpkgs, or customize XanMod optimization settings in [kernel-xanmod/mkXanModKernel.nix](kernel-xanmod/mkXanModKernel.nix).

### Available Arguments

The following arguments can be passed to `mkXanModKernel`:

#### Required Arguments

- **`pname`**: Package name for the kernel
- **`version`**: Kernel version string, e.g. `7.2.4-xanmod1` (real-time kernels are suffixed with `-rt`, e.g. `6.18.49-rt-xanmod1`)
- **`src`**: Kernel source derivation, must be a XanMod GitLab tarball containing the base config under `CONFIGS/x86_64/config` (or `config-rt` for real-time kernels)

#### Optional Arguments

**Compiler & Optimization:**

- **`lto`**: Link-Time Optimization setting. Options: `"none"` (default), `"thin"`, or `"full"`. Non-`"none"` values use Clang.
- **`processorOpt`**: Processor optimization level. Options: `"x86_64-v1"` (default), `"x86_64-v2"`, `"x86_64-v3"`, `"x86_64-v4"`, `"zen4"`, or `"native"` (requires impure environment). Note that `x86_64-v4` and `zen4` are
  not used by any prebuilt package, see the psABI note above.
- **`autofdo`**: AutoFDO (Automatic Feedback-Directed Optimization) settings. Options:
  - `false` (default): Disable AutoFDO
  - `true`: Enable AutoFDO for profiling performance patterns only
  - `./path/to/autofdo/profile`: Enable AutoFDO with specified profile (requires `lto != "none"`)

> AutoFDO hasn't been fully tested. Please report issue if you encounter any.

**XanMod Kernel Settings:**

- **`rt`**: Build real-time kernel. Selects `CONFIGS/x86_64/config-rt` as the base config and prefixes the kernel localversion with `-rt`. Default: `false`.

**XanMod Fine Tuning Settings:**

All tuning defaults follow the upstream config files (`CONFIGS/x86_64/config`, `config-rt`) shipped inside the source tarball.

- **`hzTicks`**: Timer frequency. Options: `"250"` (default), `"100"`, `"300"`, `"500"`, `"1000"`, or `null` to disable.
- **`tickrate`**: Tick rate. Options: `"idle"` (default), `"periodic"`, `"full"`, or `null` to disable.
- **`preemptType`**: Preemption type. Options: `"lazy"` (default), `"full"` (default for real-time kernels, since `PREEMPT_RT` requires `PREEMPT=y`), `"voluntary"`, `"none"`, or `null` to disable.
- **`hugepage`**: Huge page settings. Options: `"always"` (default), `"madvise"`, or `null` to disable.

**Patch Control:**

- **`prePatch`**: Shell commands to run before applying patches. Default: `""`.
- **`patches`**: List of additional patches to apply. Default: `[ ]`.
- **`postPatch`**: Shell commands to run after applying patches. Default: `""`.

**Module Settings:**

- **`autoModules`**: Build as many components as possible as kernel modules, including disabled ones. Default: `true`.

**Other Options:**

Additional arguments are passed through to `buildLinux` from nixpkgs. See [nixpkgs/pkgs/os-specific/linux/kernel/generic.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/generic.nix) for available options.

### Example Usage

```nix
{
  kernel = pkgs.xanmodKernels.linux-xanmod-main.override {
    pname = "linux-xanmod-with-custom-source";
    version = "7.2.4-xanmod1";
    src = pkgs.fetchurl {
      # ...
    };

    # Customize XanMod settings
    lto = "thin";
    processorOpt = "x86_64-v3";
    hzTicks = "1000";

    # Additional args are available. See kernel-xanmod/mkXanModKernel.nix
  };

  # For non-LTO kernels
  kernelPackages = pkgs.linuxKernel.packagesFor kernel;


  # For LTO kernels, helpers.kernelModuleLLVMOverride fixes compilation for some
  # out-of-tree modules in nixpkgs.
  kernelPackagesWithLTOFix = let
    # helpers.nix provides a few utilities for building kernel with LTO.
    # I haven't figured out a clean way to expose it in flakes.
    helpers = pkgs.callPackage "${inputs.nix-xanmod-kernel.outPath}/helpers.nix" {};
  in helpers.kernelModuleLLVMOverride (pkgs.linuxKernel.packagesFor kernel);
}
```
