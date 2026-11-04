#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
: "${GOROOT_BOOTSTRAP:?请指定官方 Go 1.27.3 的 GOROOT_BOOTSTRAP}"
export GOTOOLCHAIN=local
export GOMAXPROCS=${GOMAXPROCS:-4}
cd "$root/src"
CGO_ENABLED=0 ./make.bash
cd "$root"
./bin/go test cmd/internal/obj/... cmd/link/internal/... cmd/asm/internal/...
python3 - <<'PYMETA'
import json, pathlib, subprocess
p = pathlib.Path('misc/musl-toolchain/source.json')
m = json.loads(p.read_text())
m['sourceCommit'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
m['sourceDirty'] = bool(subprocess.check_output(['git', 'status', '--porcelain'], text=True).strip())
if m['sourceDirty']:
    raise SystemExit('禁止打包脏源码')
m['host'] = subprocess.check_output(['./bin/go', 'env', 'GOHOSTOS', 'GOHOSTARCH'], text=True).splitlines()
m['version'] = subprocess.check_output(['./bin/go', 'version'], text=True).strip()
pathlib.Path('toolchain-identity.json').write_text(json.dumps(m, indent=2) + '\n')
PYMETA
mkdir -p out
arch=$(./bin/go env GOHOSTARCH)
archive="go1.27.3-hexf00-musl.1.linux-${arch}.tar.gz"
# 保留编译标准库所需源码与许可证；排除 Git、中间 bootstrap、构建输出。
tar --exclude=./.git --exclude=./out --exclude=./pkg/bootstrap \
  --exclude=./pkg/obj --exclude=./.github -czf "out/$archive" --transform='s,^\.,go,' .
(cd out && sha256sum "$archive" > "$archive.sha256")
cp toolchain-identity.json out/
