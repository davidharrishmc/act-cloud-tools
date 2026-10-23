#!/bin/bash
# Runs inside ubuntu:24.04. Builds the CI-pinned simulators into /out/act4-tools.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential git curl ca-certificates python3 python3-venv pkg-config \
  device-tree-compiler libboost-regex-dev libboost-system-dev libboost-program-options-dev \
  libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build xz-utils bzip2 flex bison
J=${J:-4}
P=/out/act4-tools; mkdir -p $P /build; cd /build
git clone -q https://github.com/riscv/riscv-isa-sim.git && cd riscv-isa-sim && git checkout -q 5a760667bf0d0ab893173b9eeff9c109c8d7dd9a
mkdir build && cd build && ../configure --prefix=$P/spike >/dev/null && make -j$J >/dev/null && make install >/dev/null; cd /build
git clone -q https://github.com/tenstorrent/whisper.git && cd whisper && git checkout -q 76f03922da799056b796dd3b39be27c88dc84dca
make -j$J >/dev/null && mkdir -p $P/whisper/bin && cp build-Linux/whisper $P/whisper/bin/; cd /build
curl -sL https://download.qemu.org/qemu-11.1.2.tar.xz | tar xJ && cd qemu-11.1.2
./configure --prefix=$P/qemu --target-list=riscv32-softmmu,riscv64-softmmu >/dev/null && make -j$J >/dev/null && make install >/dev/null
cat > $P/VERSIONS <<V
spike 5a760667bf0d0ab893173b9eeff9c109c8d7dd9a
whisper 76f03922da799056b796dd3b39be27c88dc84dca
qemu 11.1.2
built $(date -u +%F) in ubuntu:24.04
runtime apt: device-tree-compiler libboost-regex1.83.0 libboost-system1.83.0 libboost-program-options1.83.0 libglib2.0-0t64 libfdt1 libpixman-1-0 zlib1g
V
cd /out && tar czf act4-sims-ubuntu24.04-x86_64.tar.gz act4-tools && ls -la /out
