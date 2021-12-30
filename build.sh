#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# This scripts checkout seL4 and wasmedge, and create an seL4 example app for running WebAssembly in seL4.
# If you see error like "undefined reference `__getauxval`", your aarch64-linux-gcc's version is 10 or greater.
# You can add this line to `projects/musllibc/src/misc/getauxval.c`
# ```
# weak_alias(getauxval, __getauxval);
# ```

set -xuo pipefail
# Install dependency
# See https://docs.sel4.systems/projects/buildsystem/host-dependencies.html
sudo apt update && apt install \
 cmake ccache ninja-build cmake-curses-gui \
 python3-dev python3-pip \
 libxml2-utils ncurses-dev \
 curl git doxygen device-tree-compiler \
 u-boot-tools \
 protobuf-compiler python-protobuf \
 gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
 qemu-system-aarch64 libc6-dev-arm64-cross \
 haskell-stack bc cpio

pip3 install --user setuptools sel4-deps camkes-deps

# Create root directory
mkdir -pv sel4_wasmedge
cd sel4_wasmedge

# Setup project files
git clone https://gerrit.googlesource.com/git-repo .repo/repo
.repo/repo/repo init -u https://github.com/second-state/wasmedge-seL4.git

# Update and checkout files
.repo/repo/repo sync

# Apply patches

patch -p1 -d projects/camkes-tool < .repo/manifests/patches/01-camkes-tool.patch
patch -p1 -d projects/llvm < .repo/manifests/patches/02-llvm.patch
patch -p1 -d projects/seL4_libs < .repo/manifests/patches/03-seL4_libs.patch
patch -p1 -d projects/seL4_projects_libs < .repo/manifests/patches/04-seL4_projects_libs.patch
patch -p1 -d projects/vm-examples < .repo/manifests/patches/05-vm-examples.patch
patch -p1 -d projects/vm-linux < .repo/manifests/patches/06-vm-linux.patch
patch -p1 -d projects/wasmedge < .repo/manifests/patches/07-wasmedge.patch

# Copy wasm examples
cp .repo/manifests/wasm-examples/*.wasm projects/vm-examples/apps/Arm/wasmedge/overlay_files/

# Configure seL4
mkdir -p build
cd build
../init-build.sh -DCAMKES_VM_APP=wasmedge -DPLATFORM=qemu-arm-virt

# Build image
ninja
ninja
