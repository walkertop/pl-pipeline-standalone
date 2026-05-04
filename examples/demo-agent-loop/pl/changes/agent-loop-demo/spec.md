# SPEC: Agent Loop Demo

实现一个 `add(a, b)` 函数，并通过 Python `unittest`。

这个 demo 的真实目标不是计算器本身，而是证明：

- agent/executor 可以先产出错误实现；
- gate 能捕获失败；
- PL-Pipeline 能生成 repair context；
- repair 命令能消费上下文并修正代码；
- 最终 gate 通过，trace 留痕。
