#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
export GOROOT="$root" PATH="$root/bin:$PATH" GOTOOLCHAIN=local
mkdir -p "$root/out/probe"
cd "$root/out/probe"
GO111MODULE=off CGO_ENABLED=1 CC=musl-gcc go build -buildmode=c-archive -o probe.a "$root/misc/musl-toolchain/probe.go"
musl-gcc -shared -fPIC -I/usr/include/node "$root/misc/musl-toolchain/probe.c" probe.a -lpthread -ldl -lm -o probe.node
readelf -d probe.node > elf.txt
if grep -q STATIC_TLS elf.txt; then
  echo '最终 .node 仍依赖静态 TLS' >&2
  exit 1
fi
# 固定 Node 20 / Alpine 3.20，测试用户无需启动选项即可加载。
case $(go env GOHOSTARCH) in
  amd64) image=node@sha256:6e0e1a13235997255e6f36fd3da4169d99b5e87c0de01dc08300359d23224c33 ;;
  arm64) image=node@sha256:32c5587d8f5b56bdfacbe832773059a2319aca74369bd61163e0c04726b1fd6d ;;
  *) exit 1 ;;
esac
docker run --rm -e MUSL_PROBE=expected -v "$PWD:/probe:ro" "$image" node -e '
const {Worker} = require("node:worker_threads");
const assert = require("node:assert/strict");
assert.equal(require("/probe/probe.node").result, 42);
Promise.all(Array.from({length:8}, () => new Promise((resolve,reject) => {
  const w = new Worker(`require("node:assert/strict").equal(require("/probe/probe.node").result,42)`, {eval:true});
  w.on("error", reject);
  w.on("exit", code => code === 0 ? resolve() : reject(new Error(`worker exit ${code}`)));
}))).then(() => console.log("PASS musl .node: Go calls, goroutines, GC, environment, 8 Node workers"));
'
