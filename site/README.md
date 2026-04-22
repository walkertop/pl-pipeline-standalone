# pl-pipeline showcase site

面向对外宣讲的静态单页网站。零构建，纯 HTML + CSS + JS。

## 预览

```bash
# 方式一：直接 open（有些浏览器对 file:// 限制 localStorage，但功能都能看）
open site/index.html

# 方式二：起一个 local server（推荐）
cd site
python3 -m http.server 8888
# 然后浏览器打开 http://localhost:8888
```

## 部署到 GitHub Pages

推荐走 `/site` 子目录发布：

1. `Settings → Pages → Source: Deploy from a branch`
2. `Branch: main` 或 `site/showcase`，Folder: `/site`
3. GitHub 会给一个 `https://<user>.github.io/pl-pipeline-standalone/` 链接

或者纯静态托管（Vercel / Netlify / EdgeOne Pages）：
- 根目录留空即可，把 `site/` 当成发布目录

## 内容大纲

| 锚点 | 内容 |
|---|---|
| `#top` | Hero + 关键数字 |
| `#problem` | AI 编码三个痛点 |
| `#architecture` | 三层架构（piao / pl / adapter） |
| `#pipeline` | 6 阶段 × 7 门禁交互式 stepper + 真实 trace 示例 |
| `#contract` | 纸面契约 vs 可执行契约 对比 |
| `#flywheel` | retro v1→v2 自我演化飞轮 |
| `#start` | 30 秒上手 + 链接 |

## 文件

- `index.html` — 单页结构
- `styles.css` — 暗 / 亮双主题
- `app.js` — 主题切换 + stage stepper + nav highlight

## 二次修改

改 `app.js` 里的 `STAGE_DATA` 可以调整阶段详情；
改 `styles.css` 的 `[data-theme="dark"]` / `[data-theme="light"]` 块可调色板。

需要改文案的话，大多数都在 `index.html` 里直接改即可。
