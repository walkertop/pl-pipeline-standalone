# demo-agent-crud-service

这个 demo 展示 `pl agent run` 的 hardening 路径：不传 `--repair-cmd`，而是由 `pl/config.yaml` 的 `agent.repair.strategy` 按失败类型选择修复脚本。

## Run

```bash
bash examples/demo-agent-crud-service/run-demo.sh
```

流程：

1. `write_bad_impl.sh` 写入一个不完整的用户 CRUD 实现。
2. gate D 运行 `python3 -m unittest discover -s tests` 并失败。
3. `pl agent run` 分类为 `test_failure`。
4. repair policy 选择 `./scripts/repair_test_failure.sh`。
5. repair 脚本读取 `PL_REPAIR_CONTEXT` / `PL_FAILURE_KIND`，写回完整实现。
6. gate D 再次通过。

核心验证产物：

- `pipeline-output/trace/crud-service-demo.events.jsonl`
- `pipeline-output/agent-runs/crud-service-demo/<run-id>/repair-context-attempt-0.md`
