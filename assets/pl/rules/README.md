# pl-pipeline Core Rules

本目录存放 pl-pipeline **核心通用规则**，用于 AI 在各阶段自我约束，或用于 `pl-rule-scan.sh` 扫描。

## 分层

```
assets/pl/rules/         ← 通用（pl 本体纪律）       ← 本目录
adapters/adapter-*/rules/  ← 栈级（编码规范、测试规范）
<user-project>/.codebuddy/rules/  ← 项目级
```

## 规则格式

Rule 是 Markdown 文件，顶部 YAML frontmatter 可声明检测字段，供 `pl-rule-scan.sh` 执行：

```yaml
---
id: piao-pipeline-discipline
version: 1.0.0
severity: warning           # error | warning | info
scope: generic
applies_to:
  glob: ["pl/changes/**/*.md"]
detect:
  - kind: file_not_contains
    pattern: "^## .state"
    message: ".state.md 必需 stage/gate 字段"
message: "..."
fix_hint: "..."
---
```

没声明 detect 字段的 rule 仍可被 AI 读作约束（纯文档模式）。

## 清单（v1.5 计划）

| Rule | 来源 | 状态 |
|------|------|------|
| `piao-pipeline-discipline.md` | 从 KuiklyPolyCity 脱敏迁入 | ✅ D3 |
| `acceptance-criteria.md` | 同上 | ✅ D3 |
| `build-verification.md` | 同上（gradle 命令抽象化完成）| ✅ D3 |
| `git-commit.md` | 同上（Scope 表通用化，path 改 `pl/changes`）| ✅ Tier 1 |

> **栈级 rule（Kotlin 相关）** 已迁移至 `adapters/adapter-kotlin/rules/`：
> - `kotlin-coding-standards.md`（Kotlin 通用编码规范）
> - `kotlinx-serialization.md`（kotlinx.serialization 使用规范）
