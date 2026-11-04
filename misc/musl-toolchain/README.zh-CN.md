# musl 专用 Go 工具链

本分支维护 Go 1.27.3 的定制候选工具链，只供 Linux x64、ARM64 的 Go PDF `c-archive` → Node `.node` 构建使用。PDF 仍使用现有 Go 实现，应用仍安装原有 Node loader 和单个 `.node`，不增加辅助进程，也不要求修改 Node 启动参数。GNU、macOS、Windows 线路继续使用官方 Go。

## 来源与适配

权威来源见 `source.json`。基础为官方 `go1.27.3`；引入 Jay Gowdy 的 [Go CL 696635 patchset 4](https://go-review.googlesource.com/c/go/+/696635/4)，保留原作者代码及测试。该补丁尚未进入官方 Go，因此此编译器不能当作官方支持承诺。

补丁为 archive/shared 构建生成动态 TLS 访问，允许 musl 在 Node 运行后加载含 Go runtime 的共享库；同时处理非 glibc 的 ELF 初始化函数不提供 argc/argv 的情况。适配 1.27.3 时，glibc 检测符号单独放入 `callbacks_linux.go`，避免给其他平台引入 Linux 符号；`gcc_unix.c` 保留官方的新初始化入口。

行为差异：该工具链构建的 Go library/archive 中 `os.Args` 为空；musl 下环境变量和辅助向量从 `/proc/self` 读取，受容器 `/proc` 权限约束。上游候选的环境读取还有 8 KiB 限制。现有消费者不能依赖进程参数；这些差异与 TLS 修复都需要在真实 PDF 消费者中验证。只验证 Linux amd64、arm64；不承诺其他架构、Go plugin、race、所有 cgo 或任意宿主程序兼容。

## 构建、保存与使用

仅在工具链源码变化时构建；不要求每次业务包发布重编 Go。专用 workflow 为两种架构各构建一次，执行相关 assembler/linker 单元测试及 Alpine Node 加载检查，再上传压缩包、SHA-256、精确源码身份。工作流不加入业务 PR 的平台矩阵。

本机构建：指定官方 Go 1.27.3 的 `GOROOT_BOOTSTRAP`，执行 `misc/musl-toolchain/build.sh`。产物的宿主是 Linux GNU；在 GNU 构建容器里配合现有 Zig/musl C/C++ 工具链编译目标 `.node`，无需把 Go 编译器安装到终端用户的 Alpine 系统。

消费者必须固定完整源码提交、压缩包 SHA-256，并验证 `toolchain-identity.json`；解压后设置 `GOROOT`、`PATH`、`GOTOOLCHAIN=local`，确认 `go version` 包含 `hexf00-musl.1`。必须移除 archive 脚本中强制 `GOTOOLCHAIN=go1.24.3` 的设置，否则会静默切回官方工具链。不要通过未固定的分支名、latest、仅版本字符串或缓存命中判断身份。

GitHub Actions artifact 会到期，不能作为永久发行仓库；保存经验证的压缩包及校验值后再接入长期存储。缓存只加速，不作为唯一来源。Go 安全更新或升级时需适配补丁、重编工具链，重跑两种架构的真实 PDF `.node` 消费者验证。构建通过只证明工具链生成成功，不能代表 PDF 已验收。
