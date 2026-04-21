# Changelog

本项目的所有显著变更都会记录在此。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### Added
- 项目初始化（Apache 2.0 License）
- 产品化 README.md（中文）
- MIGRATION_CHECKLIST.md：从宿主项目抽离 pl-pipeline 的完整蓝图
- docs/LAYER_ANALYSIS.md：Layer 2/3 抽象设计深度分析
- LICENSE / NOTICE / CODE_OF_CONDUCT / SECURITY / .gitignore / .editorconfig

### Planned for v0.1.0 (MVP)
- Layer 0 资产落盘（schemas + templates + config）
- 11 个 bash 脚本抽离并支持 `PL_HOME` 环境变量
- `bash scripts/pl-status.sh` 可对宿主项目的 `pl/changes/` 生效
- 最小端到端演示：在独立仓库内驱动一次 `SPEC → IMPLEMENT` 流程

### Planned for v0.2.0
- TypeScript CLI 重写（`packages/cli` + `packages/core`）
- `pl init --smart`：技术栈扫描 + Preset 推荐
- Build Adapter 协议（Gradle / npm / cargo / make / custom）
- IDE Adapter 首批：CodeBuddy / Cursor / Claude Code

### Planned for v1.0.0
- MCP Server 适配所有 MCP 兼容 IDE
- 文档站（pl-pipeline.dev）
- 首批官方 Preset（kotlin-kmm / web-react-nextjs / python-fastapi）
- 社区 Preset 目录（含 weex-to-kuikly 案例）

---

[Unreleased]: https://github.com/walkertop/pl-pipeline/compare/HEAD
