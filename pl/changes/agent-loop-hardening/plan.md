# PLAN: Agent Loop Hardening

## PL Pipeline Mapping

| Stage | Output |
|---|---|
| SPEC | 明确 hardening 边界：repair policy + failure classification + CRUD demo |
| PLAN | 以 TDD 增量推进 policy 与 demo |
| IMPLEMENT | 更新 `pl-agent-run.sh`，新增 demo 和文档 |
| VERIFY | agent CLI 测试、demo 自测、shell 语法检查、核心回归 |
| OBSERVE | trace 中出现 `failure_kind` / `repair_source` |
| ARCHIVE | 下一步进入外部 executor adapter 和 agent trace model |

## Design

`pl/config.yaml` 新增可选配置：

```yaml
agent:
  repair:
    max_retries: 1
    strategy:
      test_failure: "./scripts/repair_test_failure.sh"
      default: "./scripts/repair_default.sh"
```

优先级：

1. CLI `--repair-cmd` 显式指定时优先。
2. 否则读取 `strategy.<failure_kind>`。
3. 否则读取 `strategy.default`。
4. 都没有则停止并返回 blocked。

## Failure Classification

先用保守文本分类：

- 语法/解析错误 -> `syntax_error`
- import/file 缺失 -> `missing_file`
- unittest/pytest/assertion 失败 -> `test_failure`
- timeout 关键词 -> `timeout`
- contract/schema/pact 关键词 -> `contract_violation`
- 其他 -> `unknown`

分类结果写入：

- `agent.gate.result`
- `agent.repair.context`
- repair context Markdown
- `agent.run.complete`
