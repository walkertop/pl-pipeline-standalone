---
name: 📦 New Adapter Proposal
about: 为某技术栈提议新的 adapter
title: "[adapter] adapter-"
labels: ["adapter", "needs-triage"]
---

## 技术栈

- 语言 / 框架：<!-- 如 Rust + Axum + SQLx / Vue 3 + Nuxt / Swift + Vapor -->
- 最小版本：<!-- 如 Rust 1.70+ / Vue 3.4+ -->
- 目标项目形态：<!-- Web 后端 / 移动 / CLI / ... -->

## 为什么值得做成 adapter？

<!-- 社区有多少项目用这个栈？有哪些"它独特的坑 / 最佳实践"必须沉淀？ -->

## 资产清单（打算提供）

- [ ] `templates/spec.md` - 场景化字段（如：<!-- 特有字段 -->）
- [ ] `templates/plan.md` - 架构分层示例
- [ ] `templates/taskdag.md` - 典型任务模板
- [ ] agents（至少 1 个）：<!-- 如 ___-architect, ___-reviewer -->
- [ ] skills（至少 2 个）：<!-- 如 async patterns, ORM patterns -->
- [ ] rules（至少 1 个）：<!-- 如 coding standard, naming -->
- [ ] scripts/verify.sh（至少）
- [ ] build_adapter：`$PL_BUILD_CHECK_CMD = <...>`

## 检测规则

打算用什么方式让 `pl init --smart` 识别？

- [ ] `file_exists: <marker>`（如 `Cargo.toml`）
- [ ] `package_json_has: <key>`
- [ ] `pyproject_has: <key>`
- [ ] `cargo_has: <crate>`
- [ ] `go_mod_has: <module>`
- [ ] 其他：___

## 有 demo / case-study 计划吗？

- [ ] 是，会在 `examples/demo-<name>/` 提供可跑样例
- [ ] 否，先交 adapter 本身；demo 作为 follow-up issue

## 你是谁 / 贡献意向

<!-- 简介 + 是否愿意长期维护本 adapter -->
