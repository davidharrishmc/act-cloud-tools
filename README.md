# act-cloud-tools

Prebuilt simulators and a setup script for running [riscv-arch-test](https://github.com/riscv/riscv-arch-test)
(ACT4) regressions in Claude Code cloud environments (Ubuntu 24.04, x86_64).

| Tool | Version | Source |
|---|---|---|
| Sail RISC-V | 0.16 | sail-riscv release, downloaded by `setup.sh` |
| RISC-V GCC | 2026.08.27 | riscv-gnu-toolchain release, downloaded by `setup.sh` |
| Spike | 2c300cd90eb7 | built by `build-in-container.sh` (release tarball) |
| Whisper | 1d60e5ceb4b6 | built by `build-in-container.sh` (release tarball) |
| QEMU | 11.1.2 (riscv32/64-softmmu) | built by `build-in-container.sh` (release tarball) |

The versions are the ones ACT's CI pins (`.github/scripts/install-*.sh`, `.github/actions/setup-tools`).

## Cloud environment

Paste `setup.sh` into the environment's **Setup script** field (claude.ai/code, environment settings). It
installs everything under `/opt/act4-tools`, links the binaries into `/usr/local/bin`, installs mise with
ACT's tool versions, and warms the Ruby gem and Python package caches. It finishes in well under the ~5
minutes needed for the environment snapshot to be cached. Optional variables: `ACT_TOOLS_TAG`,
`ACT_REPO`, `ACT_BRANCH`.

Sessions should `source /etc/profile.d/act4-tools.sh` (or set `MISE_DATA_DIR=/opt/mise
UV_CACHE_DIR=/opt/uv-cache` in the environment's variables) so mise and uv find the cached installs.

`smoke.sh [repo] [branch]` builds two small suites and runs them on Sail, Spike, Whisper and QEMU.

## Rebuilding the simulator tarball

```
podman run --rm -e J=8 -v $PWD/out:/out -v $PWD/build-in-container.sh:/build.sh:ro ubuntu:24.04 bash /build.sh
./slim.sh out/act4-tools act4-sims-ubuntu24.04-x86_64.tar.gz
```

Licensed tools (Imperas, Questa) are not included.
