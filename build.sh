#!/usr/bin/env bash

set -euxo pipefail

root=$(realpath "$PWD")

# use a higher depth because bootstrap might be broken with depth 1?
git clone --depth 50 https://github.com/rust-lang/rust.git
cd rust

./configure \
    --set llvm.download-ci-llvm=true \
    --set rust.download-rustc=true

targets=(x86_64-unknown-linux-gnu x86_64-pc-windows-msvc aarch64-apple-darwin)

# bootstrap uses this var to perform CI detection :(
unset CI

for target in "${targets[@]}"; do
    echo "Building $target"

    export RUSTDOCFLAGS="--document-private-items \
        --document-hidden-items \
        --html-before-content=$root/before.html \
        --extend-css=$root/style.css"

    ./x doc library --target "$target"

    mkdir "$root/www-root/$target"
    cp -r "./build/$target/doc" "$root/www-root/$target"
done
