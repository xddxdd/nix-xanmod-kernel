{ lib, ... }:
with lib.kernel;
{
  hzTicks = {
    "250" = {
      HZ_250 = yes;
      HZ = freeform "250";
    };
  }
  // lib.genAttrs [ "100" "300" "500" "1000" ] (hz: {
    HZ_300 = no;
    "HZ_${hz}" = yes;
    HZ = freeform hz;
  });

  lto = {
    none = {
      LTO_NONE = yes;
      LTO_CLANG_THIN = no;
      LTO_CLANG_FULL = no;
    };
    thin = {
      LTO_NONE = no;
      LTO_CLANG_THIN = yes;
      LTO_CLANG_FULL = no;
    };
    full = {
      LTO_NONE = no;
      LTO_CLANG_THIN = no;
      LTO_CLANG_FULL = yes;
    };
  };

  processorOpt = {
    x86_64-v1 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "1";
    };
    x86_64-v2 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "2";
    };
    x86_64-v3 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "3";
    };
    x86_64-v4 = {
      GENERIC_CPU = yes;
      MZEN4 = no;
      X86_NATIVE_CPU = no;
      X86_64_VERSION = freeform "4";
    };
    zen4 = {
      GENERIC_CPU = no;
      MZEN4 = yes;
      X86_NATIVE_CPU = no;
    };
    native = {
      GENERIC_CPU = no;
      X86_NATIVE_CPU = yes;
    };
  };

  tickrate = {
    periodic = {
      NO_HZ_IDLE = no;
      NO_HZ_FULL = no;
      NO_HZ = no;
      NO_HZ_COMMON = no;
      HZ_PERIODIC = yes;
    };
    idle = {
      HZ_PERIODIC = no;
      NO_HZ_FULL = no;
      NO_HZ_IDLE = yes;
      NO_HZ = yes;
      NO_HZ_COMMON = yes;
    };
    full = {
      HZ_PERIODIC = no;
      NO_HZ_IDLE = no;
      CONTEXT_TRACKING_FORCE = no;
      NO_HZ_FULL_NODEF = yes;
      NO_HZ_FULL = yes;
      NO_HZ = yes;
      NO_HZ_COMMON = yes;
      CONTEXT_TRACKING = yes;
    };
  };

  preemptType = {
    full = {
      PREEMPT_DYNAMIC = yes;
      PREEMPT = yes;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = no;
    };
    lazy = {
      PREEMPT_DYNAMIC = yes;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = yes;
      PREEMPT_NONE = no;
    };
    voluntary = {
      PREEMPT_DYNAMIC = no;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = yes;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = no;
    };
    none = {
      PREEMPT_DYNAMIC = no;
      PREEMPT = no;
      PREEMPT_VOLUNTARY = no;
      PREEMPT_LAZY = no;
      PREEMPT_NONE = yes;
    };
  };

  hugepage = {
    always = {
      TRANSPARENT_HUGEPAGE_MADVISE = no;
      TRANSPARENT_HUGEPAGE_ALWAYS = yes;
    };
    madvise = {
      TRANSPARENT_HUGEPAGE_ALWAYS = no;
      TRANSPARENT_HUGEPAGE_MADVISE = yes;
    };
  };
}
