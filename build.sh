#!/usr/bin/env bash

set -euxo pipefail

root=$(realpath "$PWD")

cp index.html "$root/www-root"

# use a higher depth because bootstrap might be broken with depth 1?
if [ ! -d 'rust' ]; then
    git clone --depth 50 https://github.com/rust-lang/rust.git
    pushd rust
    git ls-files -z -- ':(glob)library/**/*.rs' \
    | xargs -0 sed -i'' -E 's@^ *#!?\[doc\(cfg.*$@// & // commented out for std.noratrieb.dev@'
    git ls-files -z -- ':(glob)src/librustdoc/**/*.rs' \
    | xargs -0 sed -i'' -E 's@^ *cfgs\.push\("doc".*$@// & // commented out for std.noratrieb.dev@'
    git --no-pager diff # show diff for easier debugging in case of deploy failures
    popd
fi
cd rust

rm -f bootstrap.toml
configure_args=(
    --set llvm.download-ci-llvm=true
    --set rust.llvm-tools=false
    --set rust.llvm-bitcode-linker=false
    --set build.optimized-compiler-builtins=false # necessary to make cross-doc work for all targets
    --set change-id=ignore
    --set rust.deny-warnings=false
)
./configure "${configure_args[@]}"

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
        --generate-link-to-definition \
        --generate-macro-expansion"

    ./x doc library --target "$target" --stage 1

    cp -rT "./build/$target/doc/" "$root/www-root/$target"
done
