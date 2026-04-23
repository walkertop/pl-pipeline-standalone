---
id: git-commit
version: 1.0.0
scope: generic
category: meta
severity: warning
description: Git 提交规范（Conventional Commits）与分支命名约定。通用于所有 pl-pipeline 项目，与具体技术栈无关。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Git Commit · 提交规范与分支约定

> **Rule-ID**: `GIT-001`
> **适用范围**: 所有代码提交
> **优先级**: P1

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓，去除栈名硬编码，Scope 通用化 |

---

## 设计原则

- **结构化信息是自动化的前提**：只有 commit message 结构化，Changelog / 语义版本 / CI 触发才能自动化
- **通用性优先**：不绑定具体项目或技术栈，各项目可在 `<user-project>/.codebuddy/rules/` 中扩展 scope 枚举
- **可追溯**：commit 与变更提案（pl/changes/）建立双向链接

---

## 1. 分支策略

### Rule `GIT-001-BRANCH`: 分支命名必须标识变更类型

**Rationale**: 规范的分支命名使团队成员一眼识别分支用途；CI/CD 可据此触发不同流水线（feature → PR 检查，fix → 快速通道等）。

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `main` 或 `master` | `main` |
| 功能分支 | `feature/<name>` | `feature/user-profile` |
| 修复分支 | `fix/<name>` | `fix/login-timeout` |
| 重构分支 | `refactor/<name>` | `refactor/api-layer` |
| 文档分支 | `docs/<name>` | `docs/readme-update` |

### 分支工作流

```
main ← feature/xxx ← 日常开发
                    ↑
                    PR 审核后合入
```

---

## 2. Commit Message 格式

### Rule `GIT-001-MSG`: Commit Message 必须遵循 Conventional Commits

**Rationale**: 结构化的提交信息支持 **自动生成 Changelog**、**语义化版本**、**快速定位变更意图**，同时为 AI 辅助工具（如 pl-pipeline 自身的归档阶段）提供可解析的输入。

### 标准格式

```
<type>(<scope>): <subject>

[body]

[footer]
```

### Type 类型（固定枚举）

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(auth): add OAuth2 support` |
| `fix` | Bug 修复 | `fix(payment): correct discount rounding` |
| `refactor` | 重构（不改行为） | `refactor(api): extract response helper` |
| `docs` | 文档 | `docs(readme): add deployment guide` |
| `test` | 测试 | `test(user): add unit tests for profile` |
| `chore` | 构建/工具链 | `chore(deps): bump framework to v2.3` |
| `style` | 代码格式 | `style: fix indentation` |
| `perf` | 性能优化 | `perf(list): use virtualization for long lists` |
| `ci` | CI 配置 | `ci(gha): add nightly build` |
| `build` | 构建配置 | `build(bundler): switch to esbuild` |

### Scope 范围（动态扩展）

Scope 应对应当前变更所属的**模块/功能域**。pl-pipeline 不强制枚举，项目可在自己的 `.codebuddy/rules/` 中细化：

| 模式 | 说明 | 示例 |
|------|------|------|
| 业务域 | 业务模块变更 | `auth`、`payment`、`order` |
| 技术层 | 基础设施变更 | `api`、`db`、`cache`、`adapter` |
| 工程化 | 构建/迁移变更 | `build`、`ci`、`migration` |
| 页面/视图 | UI 级变更 | `profile`、`dashboard`、`settings` |

> **原则**: Scope 不是固定枚举，随项目迭代自然产生。**语义清晰 > 名称统一**。

### 完整示例

```
feat(auth): add OAuth2 Google login

- Implement OAuth2 client with state/PKCE verification
- Add callback route handler for token exchange
- Update user model to store provider-specific IDs

Closes: pl/changes/add-oauth2-login
Refs: #1234
```

---

## 3. 变更记录关联

### Rule `GIT-001-LINK`: 变更提案相关的 commit 必须关联 pl/changes

**Rationale**: pl-pipeline 的可追溯性依赖 commit 与 change 的双向链接。归档阶段（ARCHIVE）会扫描 commit 历史反查变更完整性。

### 关联格式

在 footer 中使用以下任意一种：

```
Closes: pl/changes/<change-id>      # 收尾提交（最后一个）
Refs: pl/changes/<change-id>         # 中间提交（过程中）
Part-of: pl/changes/<change-id>      # 多 commit 组合完成一个 change
```

### 示例

```
feat(payment): add refund flow (2/3)

Implement refund state machine with idempotency guarantee.

Part-of: pl/changes/add-refund-flow
```

**验收关联**: Archive 阶段（`ACC-001` Archive 门禁）检查：
- 所有完成的 change 必须至少有一个 `Closes` 提交
- change 目录下 taskdag.md 的所有 T## 任务都应该有对应 commit

---

## 4. 违规检测速查

| Rule-ID | 违规类型 | 检测方法 |
|---------|---------|---------|
| `GIT-001-MSG` | commit 不符合 Conventional Commits | `commit-msg` hook 用正则 `^(feat|fix|refactor|docs|test|chore|style|perf|ci|build)(\(.+\))?: .+` 校验 |
| `GIT-001-BRANCH` | 分支命名不符合前缀 | `pre-push` hook 校验分支名 |
| `GIT-001-LINK` | change 归档时无 Closes 提交 | `/pl:archive` 扫描 git log |

---

## 5. 与其他 rule 的关系

- 本 rule 关注 **提交的形式**（message / 分支）
- 具体提交粒度、代码审查要求由 `acceptance-criteria.md` 定义
- 栈级 commit 惯例（例如前端的 conventional-changelog preset）可在 `adapters/adapter-<stack>/rules/` 中补充

---

## Footnote · 脱敏说明

本 rule 从源项目迁入时的变化：
- 去除具体技术栈名称（原文示例包含特定框架名）
- Type 枚举扩充（增加 `ci` / `build`，与 Angular Conventional Commits 对齐）
- 变更记录关联从 `openspec/changes/*` 改为 `pl/changes/*`（pl-pipeline 原生路径）
- Scope 表改为"模式 + 示例"，去除项目专属枚举
