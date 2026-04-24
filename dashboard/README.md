# pl-pipeline Dashboard

零构建可视化面板，展示 change 状态 + 完整 trace 事件流。
**v1.3.2 起支持 live reload（SSE 推送）**。

> 👉 **面向最终用户的使用手册**：[`docs/dashboard-guide.md`](../docs/dashboard-guide.md)
> 本文偏**开发者视角**，讲实现细节与架构。

## 启动

```bash
# 在目标项目根目录
export PL_HOME=/path/to/pl-pipeline-standalone
export PATH="$PL_HOME/bin:$PATH"
pl dashboard --open

# 降级：关闭 live reload，使用纯静态托管（v1.3.0 行为）
pl dashboard --static-only
```

默认端口 8889，`--open` 自动打开浏览器。

## 视图

### 首页（index.html） — change 列表
展示项目里所有 change 的卡片总览：
- change_id + 当前 stage + gate badge
- 任务进度（done/total）
- 事件总数
- 最新更新相对时间
- 小尺寸 stage pipeline

**Live reload**：有新 change 出现、某 change 有新事件时，对应卡片自动 upsert，无需刷新。

### 详情页（change.html?id=xxx） — 单 change 时间轴
点击卡片进入：
- 4 个 info card：Stage / Gate / Tasks / Events
- 横向 stage pipeline（SPEC → PLAN → ... → ARCHIVE）
- Timeline 倒序事件列表
- 3 维过滤：artifact.* / business / gate+check
- 点任意事件行展开 payload

**Live reload**：新事件追加到文件后 1~2 秒内自动插入 Timeline 顶部（带 1.2s 闪烁高亮），同时 info card / stage pipeline 重算。

### Live 徽章（v1.3.2+）
顶部导航显示当前连接状态：
| 徽章 | 含义 |
|------|------|
| `● live` （绿色脉动） | SSE 连接中，事件实时推送 |
| `◐ connecting` （黄色脉动） | 正在连接 / 自动重连中 |
| `✕ reconnect` （红色） | 连接断开，指数退避重连 |
| `○ static` （灰色） | 服务端不支持 SSE，当前为静态模式 |

## 技术细节

### 数据来源
`_data.json` 由 `pl-dashboard.sh` 生成，指向每个 change 的 events.jsonl。
live-reload 模式下由 `scripts/_lib/dashboard-server.py` 直接映射 `/trace/*` 到宿主项目的 trace 目录；static-only 模式下通过 symlink 映射。

### Live reload 架构
- **服务端**：自写 `ThreadingHTTPServer`（仅用 Python stdlib）
  - `GET /_events/stream?change=<id>` — 订阅单 change jsonl tail（snapshot → append → reset / missing）
  - `GET /_events/index` — 订阅 trace 目录变化
  - `HEAD /_events/ping` — 前端能力探测
- **客户端**：`assets/live.js` 包装 `EventSource`，指数退避自动重连（1s → 15s）
- **降级**：探测失败时自动退回 v1.3.0 一次性静态加载

### 零构建
纯静态 HTML/CSS/JS（ES modules）。无 npm install，无 webpack，无框架。
**唯一运行时依赖：Python 3 stdlib。**

### 主题
默认暗色，点右上角 ☀/☾ 切换浅色。保存到 localStorage。

## 规划中

- v1.4：跨次统计视图（gate fail 率、rule 命中率）
- v1.5：因果图视图（artifact 反向追溯 agent + task）
- v1.6：接入 retro-miner 结果展示频繁模式 / 异常检测

## 目录结构

```
dashboard/
├── index.html              # list view (live-reload capable)
├── change.html             # timeline view (live-reload capable)
├── assets/
│   ├── styles.css          # 主题 + 组件样式 + live badge
│   ├── parser.js           # jsonl 解析 + 聚合
│   ├── live.js             # SSE 客户端 + 降级（v1.3.2+）
│   └── theme.js            # dark/light 切换
├── _data.json              # 运行时生成（gitignored）
└── trace/                  # softlink（运行时生成，static-only 模式必需）
```

