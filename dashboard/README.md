# pl-pipeline Dashboard

零构建可视化面板，展示 change 状态 + 完整 trace 事件流。

## 启动

```bash
# 在目标项目根目录
export PL_HOME=/path/to/pl-pipeline-standalone
bash $PL_HOME/scripts/pl-dashboard.sh --open
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

### 详情页（change.html?id=xxx） — 单 change 时间轴
点击卡片进入：
- 4 个 info card：Stage / Gate / Tasks / Events
- 横向 stage pipeline（SPEC → PLAN → ... → ARCHIVE）
- Timeline 倒序事件列表
- 3 维过滤：artifact.* / business / gate+check
- 点任意事件行展开 payload

## 技术细节

### 数据来源
`_data.json` 由 `pl-dashboard.sh` 生成，指向每个 change 的 events.jsonl。
`trace/` 是软链到 `$PL_PROJECT/pipeline-output/trace/`（让浏览器能 fetch）。

### 零构建
纯静态 HTML/CSS/JS（ES modules）。无 npm install，无 webpack，无框架。

### 主题
默认暗色，点右上角 ☀/☾ 切换浅色。保存到 localStorage。

## 规划中

- v1.4：Live reload（tail events.jsonl，实时追事件）
- v1.5：跨次统计视图（gate fail 率、rule 命中率）
- v1.6：因果图视图（artifact 反向追溯 agent + task）

## 目录结构

```
dashboard/
├── index.html              # list view
├── change.html             # timeline view
├── assets/
│   ├── styles.css          # 主题 + 组件样式
│   ├── parser.js           # jsonl 解析 + 聚合
│   └── theme.js            # dark/light 切换
├── _data.json              # 运行时生成（gitignored）
└── trace/                  # softlink（运行时生成）
```
