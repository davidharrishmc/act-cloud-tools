#!/bin/bash
# Smoke test after setup.sh: build one small H suite and run it on Sail, Spike, Whisper and QEMU (rv64).
set -uo pipefail
. /etc/profile.d/act4-tools.sh
REPO=${1:-https://github.com/davidharrishmc/riscv-arch-test.git}; BR=${2:-hypervisor}
cd /tmp && rm -rf act && git clone -q --depth 1 -b "$BR" "$REPO" act && cd act && mise trust -q
E=Shgatpa,Shvsatpa
mise exec -- env EXCLUDE_EXTENSIONS='' EXTENSIONS=$E make tests --jobs 4 >/tmp/tests.log 2>&1 || { tail -30 /tmp/tests.log; exit 1; }
for c in sail/sail-rv64-max spike/spike-rv64-max whisper/whisper-rv64-max qemu/qemu-rv64-max; do
  n=$(basename $c)
  mise exec -- env FAST=True EXTENSIONS=$E EXCLUDE_EXTENSIONS='' CONFIG_FILES=config/$c/test_config.yaml make elfs --jobs 4 >/tmp/$n.log 2>&1 || { tail -20 /tmp/$n.log; }
  mise exec -- ./run_tests.py -j 4 "$(cat config/$c/run_cmd.txt)" work/$n/elfs 2>&1 | tail -1
done
