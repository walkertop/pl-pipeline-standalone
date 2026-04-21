# Pull Request

## 类型

- [ ] `feat`：新功能
- [ ] `fix`：bug 修复
- [ ] `docs`：文档
- [ ] `refactor`：重构
- [ ] `test`：测试
- [ ] `chore`：构建 / 杂项
- [ ] `perf`：性能
- [ ] `ci`：CI / 工作流

## Scope（11 选 1）

- [ ] `piao-kernel`
- [ ] `pl-core`
- [ ] `adapter-sdk`
- [ ] `adapters`（具体：___）
- [ ] `scripts`
- [ ] `ide-integrations`
- [ ] `examples`
- [ ] `docs`
- [ ] `assets`
- [ ] `tooling`
- [ ] `repo`（根级文件）

## 变更摘要

<!-- 一段话讲清这个 PR 做了什么 -->

## 关联

- Closes # / Related # / Part of #

---

## 自检清单

### 通用

- [ ] commit message 遵循 [CONTRIBUTING.md](../CONTRIBUTING.md) 的 Conventional Commits
- [ ] 变更的文件数 / 行数合理（大 PR 请拆）
- [ ] 无个人绝对路径（`/Users/xxx/...`）
- [ ] 无临时调试代码 / commented-out blocks

### 涉及脚本

- [ ] `bash -n scripts/<script>.sh` 通过
- [ ] 兼容 bash 3.2（macOS 默认）
- [ ] 关键路径手工跑过一次

### 涉及 adapter

- [ ] `bash scripts/adapter-validate.sh adapters/<adapter-dir>` 通过
- [ ] `bash scripts/adapter-install.sh --dry-run ...` 输出预期
- [ ] `adapter.yaml` 字段与 `adapter-manifest.schema.json` 对齐

### 涉及 pl-core 模板 / schema

- [ ] 所有现有 demo 的 `.state.md` 仍能被 `pl-status.sh` 识别
- [ ] 如果破坏性：CHANGELOG 有迁移说明

### 涉及 examples

- [ ] `pl-status.sh` 对新 demo 识别正常
- [ ] `.pl-adapter.yaml` 里 `installed_from` 用 `$PL_HOME` 占位而非绝对路径

---

## 附加说明

<!-- review 视角 / trade-off / 后续计划 -->
