#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nix
import functools
import json
import re
import subprocess
import urllib.request
from pathlib import Path

PACKAGES_URL = "http://deb.xanmod.org/dists/sid/main/binary-amd64/Packages"
ARCHIVE_URL = "https://gitlab.com/xanmod/linux/-/archive/{tag}.tar.bz2"

VARIANTS = {
    "main": "linux-xanmod",
    "lts": "linux-xanmod-lts",
    "edge": "linux-xanmod-edge",
    "rt": "linux-xanmod-rt",
}


def fetch_packages():
    request = urllib.request.Request(
        PACKAGES_URL,
        headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        text = response.read().decode()
    packages = {}
    for block in text.split("\n\n"):
        fields = {}
        for line in block.splitlines():
            key, _, value = line.partition(": ")
            fields[key] = value
        if "Package" in fields:
            packages[fields["Package"]] = fields
    return packages


def variant_version(packages, prefix):
    for name in packages:
        if re.fullmatch(rf"{prefix}-x64v\d+", name):
            match = re.search(r"linux-image-(.+?)-x64v\d+-(xanmod\d+)", packages[name]["Depends"])
            if match:
                return f"{match[1]}-{match[2]}"
    raise RuntimeError(f"No meta package found for {prefix} in this suite")


@functools.lru_cache(None)
def nix_prefetch_hash(url):
    result = subprocess.run(
        ["nix", "store", "prefetch-file", "--json", url],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)["hash"]


if __name__ == "__main__":
    packages = fetch_packages()
    versions = {}
    for variant, prefix in VARIANTS.items():
        version = variant_version(packages, prefix)
        url = ARCHIVE_URL.format(tag=version)
        print(f"{variant}: {version}")
        versions[f"linux-xanmod-{variant}"] = {
            "version": version,
            "url": url,
            "hash": nix_prefetch_hash(url),
        }

    output_file = Path(__file__).resolve().parent / "version.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(versions, f, indent=2, sort_keys=True)