# PLAN: Agent Trace Model

## PL Pipeline Mapping

| Stage | Output |
|---|---|
| SPEC | 明确 agent trace metadata 字段 |
| PLAN | 先 CLI 参数，后 trace 写入，最后文档 |
| IMPLEMENT | 更新 `pl-agent-run.sh` 和测试 |
| VERIFY | agent tests + demos + CLI regression |
| OBSERVE | 新 trace 字段出现在 JSONL |
| ARCHIVE | 下一阶段接外部 executor adapter |

## Design

新增的字段统一构造成 `AGENT_TRACE_META`，再合并到 agent 相关事件里：

```json
{
  "provider": "openai",
  "model": "codex-local-test",
  "prompt_path": "prompts/implement.md",
  "input_artifacts": ["specs/spec.md"],
  "output_artifacts": ["app/result.txt"],
  "tool_calls": ["shell"],
  "tokens": {
    "input": 123,
    "output": 45,
    "total": 168
  }
}
```

字段为空时不写入，保持现有 trace 简洁。

## Compatibility

- 不改变现有参数语义。
- 不要求 provider/model 必填。
- 不要求 token 采集真实准确，允许 executor adapter 后续填充。
- 旧 `pl agent run --repair-cmd ...` 和 `agent.repair.strategy` 继续可用。
