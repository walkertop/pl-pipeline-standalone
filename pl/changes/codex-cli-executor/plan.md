# PLAN: Codex CLI Executor

## PL Pipeline Mapping

| Stage | Output |
|---|---|
| SPEC | 明确 Codex CLI executor 的命令协议 |
| PLAN | 先 fake Codex 测试，再实现 executor，再补 demo |
| IMPLEMENT | 更新 `pl-agent-run.sh` 和 demo |
| VERIFY | agent tests + fake demo + existing regressions |
| OBSERVE | trace 中出现 `codex-cli` / `codex.exec` |
| ARCHIVE | 下一步可接真实 Codex smoke 或 Claude executor |

## Design

`codex-cli` 是 executor adapter，不是内置 agent：

```text
PL prompt/artifacts -> pl agent run -> codex exec -> repo patch/output -> gate -> trace
```

当前实现使用 prompt 文件作为 stdin：

```bash
codex exec \
  --cd "$PL_PROJECT" \
  --sandbox workspace-write \
  --ask-for-approval never \
  -m "$MODEL" \
  - < "$PL_PROJECT/$PROMPT_PATH"
```

`--cmd` 仍可覆盖，用于调试或自定义 Codex 命令。

## Verification Strategy

不在测试中调用真实 Codex CLI，而是：

- 在临时 PATH 中放 fake `codex`。
- fake binary 记录 argv 和 stdin。
- fake binary 写出一个产物文件。
- 测试检查 argv / stdin / output artifact / trace。

这样 CI 不需要 Codex 登录态，也不需要网络。
