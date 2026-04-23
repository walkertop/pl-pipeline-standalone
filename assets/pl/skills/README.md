# pl-pipeline Core Skills

本目录存放 pl-pipeline **核心通用 skill**，所有 pl-pipeline 用户都可以直接复用，不绑定任何技术栈或业务。

## 分层

```
assets/pl/skills/    ← 通用（pl 本体能力）      ← 本目录
adapters/adapter-*/skills/   ← 栈级（next.js / fastapi / kotlin 等）
<user-project>/.codebuddy/skills/   ← 项目级（项目专属扩展）
```

加载优先级：**项目级 > 栈级 > 通用**（后者被前者覆盖）。
具体机制见 [`docs/guides/asset-layering.md`](../../../docs/guides/asset-layering.md)（v1.5 完成后生成）。

## 命名与元数据约定

每个 skill 是一个子目录，必含 `SKILL.md`，顶部 YAML frontmatter：

```yaml
---
id: <kebab-case-id>
version: 1.0.0
scope: generic               # generic | stack-specific | project-specific
category: spec | finalization | planning | archive | ...
requires: [<other-skill-id@ver>]  # 可选
---
```

## 清单（v1.5 计划）

| Skill | 来源 | 状态 |
|-------|------|------|
| `spec-normalizer/` | 从 KuiklyPolyCity 脱敏迁入 | ✅ D2（v1.5.0-alpha）|
| `finalization-template/` | 从 KuiklyPolyCity 脱敏迁入 | ✅ D3 |

> **栈级 skill（Kotlin 相关）** 已迁移至 `adapters/adapter-kotlin/skills/`：
> - `kotlin-code-review/`（Kotlin 代码审查，需叠加 adapter-kotlin）

## 脱敏硬规则

所有从项目迁入的 skill 必须通过脱敏检查：**不能出现特定项目路径、业务词、钦定技术栈**。
详见 [`docs/guides/asset-sanitization-guide.md`](../../../docs/guides/asset-sanitization-guide.md)。
