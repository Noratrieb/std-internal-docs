#!/usr/bin/env bash

set -euxo pipefail

root=$(realpath "$PWD")

cp index.html "$root/www-root"

# use a higher depth because bootstrap might be broken with depth 1?
if [ ! -d 'rust' ]; then
    git clone --depth 50 https://github.com/rust-lang/rust.git
fi
cd rust

rm -f bootstrap.toml
./configure \
    --set llvm.download-ci-llvm=true \
    --set rust.llvm-tools=false \
    --set rust.llvm-bitcode-linker=false \
    --set build.warnings=false \
    --set build.optimized-compiler-builtins=false # necessary to make cross-doc work for all targets

targets=(
  x86_64-unknown-linux-gnu
  x86_64-pc-windows-msvc
  aarch64-apple-darwin
  wasm32-unknown-unknown
  # wasm32-wasip1
  aarch64-linux-android
  # aarch64-apple-ios
)

# bootstrap uses this var to perform CI detection :(
unset CI
unset GITHUB_ACTIONS

# sanity checks make no sense for doc
export BOOTSTRAP_SKIP_TARGET_SANITY=1

for target in "${targets[@]}"; do
    echo "Building $target"

    export RUSTDOCFLAGS="--document-private-items \
        --document-hidden-items \
        --html-before-content=$root/before.html \
        --extend-css=$root/style.css \
        --cap-lints=warn"

    ./x doc library --target "$target" --stage 1

    cp -rT "./build/$target/doc/" "$root/www-root/$target"
done
