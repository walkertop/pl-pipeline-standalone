# PLAN: Codex CLI Demo

1. 将 fake Codex binary 放入 PATH。
2. 调用 `pl agent run --executor codex-cli --prompt-path prompts/implement.md`。
3. fake Codex 记录参数和 stdin prompt。
4. fake Codex 写出 `app/codex-result.txt`。
5. demo 校验产物和 trace。
