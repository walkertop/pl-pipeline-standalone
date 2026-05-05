# demo-agent-codex-cli

这个 demo 验证 `pl agent run --executor codex-cli` 的控制面集成。

它不依赖真实 Codex 登录态：`run-demo.sh` 会把 `scripts/fake-codex.sh` 放到临时 PATH 前面，用 fake binary 记录 `codex exec` 参数、读取 stdin prompt，并生成一个产物文件。

## Run

```bash
bash examples/demo-agent-codex-cli/run-demo.sh
```

验证点：

- `pl agent run` 自动构造 `codex exec --cd <project> --sandbox workspace-write --ask-for-approval never - < prompt`
- trace 中记录 `executor=codex-cli`
- trace 中默认记录 `provider=openai`
- trace 中记录 `tool_calls=["codex.exec"]`
- demo 产物 `app/codex-result.txt` 被 fake Codex 写出
