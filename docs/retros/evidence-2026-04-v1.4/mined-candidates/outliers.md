# Pattern 4 · 异常点

- events scanned: **192**

## 4.1 check.run duration 异常（z-score ≥ 3）

_(no duration outliers detected)_

## 4.2 check.run 失败 burst（同 trace 同 checker 失败 ≥ 3 次）

| trace_id | checker | fail / total |
|---|---|---|
| `demo-run-06_20260422_125839` | `lint` | 3 / 3 |

**提示**：duration 异常常指向 CI/网络/资源问题；fail burst 常指向 retry-heavy 的 check（改完代码直接跑没过就再跑）。