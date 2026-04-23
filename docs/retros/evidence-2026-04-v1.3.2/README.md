# v1.3.2-alpha — Dashboard Live Reload

**Tag**: `pl-v1.3.2-alpha`
**Branch**: `feat/v1.3.2-live-reload` → merged to `main`
**Date**: 2026-04-23

## 目标

v1.3.0-alpha dashboard 是静态快照，每次需刷新才能看到新事件。
本里程碑让观察层"真正可观"：事件写入 jsonl 后 1~2 秒内自动推送到所有打开的 dashboard。

## 变更清单

### 后端（新增）
- `scripts/_lib/dashboard-server.py` — 自写 SSE server（Python stdlib 零依赖）
  - `/_events/stream?change=<id>` — 单 change tail
  - `/_events/index` — 目录变化
  - `HEAD /_events/ping` — 能力探测

### 前端（新增）
- `dashboard/assets/live.js` — SSE 客户端 + 自动重连 + 状态徽章

### 前端（改造）
- `dashboard/change.html` — 增量 append + 全量 refreshHeader；降级兼容
- `dashboard/index.html` — 卡片 upsert / remove；降级兼容

### 脚本（改造）
- `scripts/pl-dashboard.sh` — 新增 `--static-only`，默认启动 SSE server

### 文档
- `dashboard/README.md` 补 live reload 章节 + 徽章说明
- `CHANGELOG.md` 补 v1.3.0-alpha 和 v1.3.2-alpha 两节
- `ROADMAP.md` 当前版本更新

## 设计决策

| 选择 | 否决项 | 理由 |
|------|--------|------|
| SSE | WebSocket | 单向推送已够用，`EventSource` 原生自动重连 |
| 自写 HTTP server | `python3 -m http.server` | stdlib 不支持长连接端点 |
| 轮询 tail | fs-event lib | 与 `observe-fs.py` 同策略（不装 fswatch / inotifywait） |
| 内容寻址 dedup key | 时间戳 dedup | 继承 v1.3.0 规则引擎选择，防大修改被聚合成一条 |

## E2E 证据

### 端点层（curl）
```
event: hello   → 订阅成功
event: snapshot → 2 历史 events 下发
[用户追加一条]
event: append  → 新 event 1~2s 内推送
[再追加]
event: append  → 再推送
```

### 浏览器层（Playwright）
- 打开 index.html：卡片"demo" 显示 `◇ 0/0 ● 2`
- 追加 `plan.task.added` → 卡片自动更新为 `◇ 0/1 ● 3`
- 新建 demo2 trace → 第二张卡片自动出现
- 打开 change.html?id=demo：timeline 4 events，追加后 5 events，新行带 1.2s 闪烁高亮

截图：[change-live.png](./change-live.png)

### 降级路径（curl）
- `pl-dashboard.sh --static-only`：`HEAD /_events/ping` 返回 404
- 前端 probe 返回 false → Live 徽章 `○ static` → 退回 v1.3.0 一次性加载

## 后续方向

- v1.4 Dashboard 接入：cross-change 统计视图（gate fail 率、rule 命中率）
- v1.5 Dashboard 接入：因果图视图（artifact 反向追溯 agent + task）
- v1.6 Dashboard 接入：展示 retro-miner 挖掘出的 frequent / anti-patterns
