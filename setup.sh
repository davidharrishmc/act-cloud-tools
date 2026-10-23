#!/bin/bash
# Claude Code cloud environment setup script for riscv-arch-test (ACT4) regressions.
# Installs the CI-pinned Sail, GCC, Spike, Whisper and QEMU into /opt/act4-tools, links them into
# /usr/local/bin, and installs mise with the repo's tool versions.  Paste into the environment's
# "Setup script" field.  Runs as root on Ubuntu 24.04; must finish in ~5 min to be cached.
set -euo pipefail
TAG=${ACT_TOOLS_TAG:-v2026-10-23b}
SIMS=${ACT_TOOLS_TARBALL:-https://github.com/davidharrishmc/act-cloud-tools/releases/download/$TAG/act4-sims-ubuntu24.04-x86_64.tar.gz}
SAIL=0.16
GCC=2026.08.27
T=/opt/act4-tools
export DEBIAN_FRONTEND=noninteractive
dl() { case "$1" in http*) curl -fsSL --retry 5 --retry-all-errors "$1" ;; *) cat "$1" ;; esac; }

apt-get update -qq
apt-get install -y -qq --no-install-recommends curl ca-certificates git make xz-utils file build-essential libyaml-dev libffi-dev \
  device-tree-compiler libboost-regex1.83.0 libboost-system1.83.0 libboost-program-options1.83.0 \
  libglib2.0-0t64 libfdt1 libpixman-1-0 zlib1g python3 python3-venv >/dev/null

mkdir -p $T/sail $T/gcc
dl "$SIMS" | tar xz -C /opt &
dl "https://github.com/riscv/sail-riscv/releases/download/$SAIL/sail-riscv-Linux-x86_64.tar.gz" | tar xz -C $T/sail --strip-components=1 &
dl "https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/$GCC/riscv64-elf-ubuntu-24.04-gcc.tar.xz" | tar xJ -C $T/gcc --strip-components=1 &
wait

for d in spike/bin whisper/bin qemu/bin sail/bin gcc/bin; do ln -sf $T/$d/* /usr/local/bin/; done

# mise and the tool versions in riscv-arch-test's .mise.toml, shared by every user
export MISE_DATA_DIR=/opt/mise MISE_CACHE_DIR=/opt/mise/cache MISE_INSTALL_PATH=/usr/local/bin/mise
curl -fsSL https://mise.run | sh >/dev/null
cat > /etc/profile.d/act4-tools.sh <<P
export MISE_DATA_DIR=/opt/mise MISE_CACHE_DIR=/opt/mise/cache UV_CACHE_DIR=/opt/uv-cache
P
mise settings set ruby.compile false >/dev/null 2>&1 || true
mise use -g uv@0.13.0 ruby@3.4.11 prek@0.5.5 shellcheck@0.11.0 "gem:bundler@4.0.22" >/dev/null
chmod -R a+rwX /opt/mise
mkdir -p /opt/uv-cache && chmod a+rwX /opt/uv-cache

# Warm the Ruby gem and Python package caches from riscv-arch-test, so sessions do not rebuild them
ACT_REPO=${ACT_REPO:-https://github.com/riscv/riscv-arch-test.git}
ACT_BRANCH=${ACT_BRANCH:-act4}
export UV_CACHE_DIR=/opt/uv-cache
rm -rf /tmp/act-warm && git clone -q --depth 1 -b "$ACT_BRANCH" "$ACT_REPO" /tmp/act-warm
(cd /tmp/act-warm && mise trust -q && mise install -q && mise exec -- uv sync -q && \
  cd framework/src/act/data && mise exec -- bundle install --quiet)
rm -rf /tmp/act-warm
chmod -R a+rwX /opt/mise /opt/uv-cache

cat > $T/VERSIONS.setup <<V
sail $SAIL, gcc $GCC, sims $(head -3 $T/VERSIONS | tr '\n' ' '), set up $(date -u +%FT%TZ)
V
spike --help 2>&1 | head -1; whisper --version 2>&1 | head -1; qemu-system-riscv64 --version | head -1
sail_riscv_sim --version; riscv64-unknown-elf-gcc --version | head -1
