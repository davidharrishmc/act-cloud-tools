#!/bin/bash
# Runs inside ubuntu:24.04. Builds the CI-pinned simulators into /out/act4-tools.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential git curl ca-certificates python3 python3-venv pkg-config \
  device-tree-compiler libboost-regex-dev libboost-system-dev libboost-program-options-dev \
  libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build xz-utils bzip2 flex bison
J=${J:-4}
P=/out/act4-tools; mkdir -p $P /build; cd /build; rm -rf $P/spike
git clone -q --recurse-submodules https://github.com/riscv/riscv-isa-sim.git && cd riscv-isa-sim && git checkout -q 2c300cd90eb74bb79f3fcdd58596a6f8d842d01c && git submodule update -q --init
mkdir build && cd build && ../configure --prefix=$P/spike >/dev/null && make -j$J >/dev/null && make install >/dev/null; test -x $P/spike/bin/spike; cd /build
[ -x $P/whisper/bin/whisper ] || { git clone -q https://github.com/tenstorrent/whisper.git && cd whisper && git checkout -q 1d60e5ceb4b61ded0d0f695e922783661b9c0a75
make -j$J >/dev/null && mkdir -p $P/whisper/bin && cp build-Linux/whisper $P/whisper/bin/; cd /build; }
if [ ! -x $P/qemu/bin/qemu-system-riscv64 ]; then
  curl -sL https://download.qemu.org/qemu-11.1.2.tar.xz | tar xJ && cd qemu-11.1.2
  ./configure --prefix=$P/qemu --target-list=riscv32-softmmu,riscv64-softmmu >/dev/null && make -j$J >/dev/null && make install >/dev/null
fi
cat > $P/VERSIONS <<V
spike 2c300cd90eb74bb79f3fcdd58596a6f8d842d01c
whisper 1d60e5ceb4b61ded0d0f695e922783661b9c0a75
qemu 11.1.2
built $(date -u +%F) in ubuntu:24.04
runtime apt: device-tree-compiler libboost-regex1.83.0 libboost-system1.83.0 libboost-program-options1.83.0 libglib2.0-0t64 libfdt1 libpixman-1-0 zlib1g
V
cd /out && tar czf act4-sims-ubuntu24.04-x86_64.tar.gz act4-tools && ls -la /out
