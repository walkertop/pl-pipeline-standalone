# pl-pipeline Core Agents

本目录存放 pl-pipeline **核心通用 agent**（pl 本体流程编排类，不绑定业务）。

## 分层

```
assets/pl/agents/        ← 通用（pl 编排 / 归档）      ← 本目录
adapters/adapter-*/agents/  ← 栈级（nextjs-architect 等）
<user-project>/.codebuddy/agents/  ← 项目级
```

## Agent 格式

Agent 是一个 Markdown 文件，顶部 YAML frontmatter：

```yaml
---
id: pipeline-master
version: 1.0.0
scope: generic
description: "驱动 SPEC→PLAN→IMPLEMENT→VERIFY→SMOKE→OBSERVE→ARCHIVE 六阶段"
tools: [...]                # 可选：允许使用的工具白名单
---
```

主体是 Markdown prompt，描述 agent 的职责、工作流程、交接协议。

## 清单（v1.5 计划）

| Agent | 来源 | 状态 |
|-------|------|------|
| `pipeline-master.md` | 从 KuiklyPolyCity 脱敏迁入 | 🟡 D3 |
| `knowledge-archiver.md` | 同上 | 🟡 D3 |
