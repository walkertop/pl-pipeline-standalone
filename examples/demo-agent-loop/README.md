# demo-agent-loop

一个最小可验证 demo：展示 `pl agent run` 如何把错误代码尝试修复到 gate 通过。

## Run

```bash
bash examples/demo-agent-loop/run-demo.sh
```

脚本会执行：

1. `write_bad_impl.sh` 写入错误实现：`return a - b`。
2. `pl agent run` 调用 gate D，运行 `python3 -m unittest discover -s tests`。
3. gate 失败后生成 `PL_REPAIR_CONTEXT`。
4. `repair_impl.sh` 读取修复上下文并写回正确实现：`return a + b`。
5. gate D 再跑一次并通过。

可验证输出：

- `pipeline-output/trace/agent-loop-demo.events.jsonl`
- `pipeline-output/agent-runs/agent-loop-demo/<run-id>/repair-context-attempt-0.md`
- `python3 -m unittest discover -s tests`
