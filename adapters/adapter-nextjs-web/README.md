# adapter-nextjs-web

> pl-pipeline 的 Next.js Web 项目适配器。把"Next.js 最佳实践"注入为 pl-core
> 可直接消费的模板 / agents / skills / rules / scripts，让你在新 Next.js 项目
> 里一条命令就能接入 `/pl:proposal → /pl:plan → /pl:implement → /pl:verify →
> /pl:archive` 的完整研发流水线。

## 适用场景

- Next.js **13.4+ App Router**（RSC + Server Actions）
- TypeScript 项目（要求 `strict: true`）
- 前端 Web 应用（SSG / SSR / ISR 均可）

## 一键安装

```bash
# 到你的 Next.js 项目根目录
cd /path/to/my-next-app

# 初始化 pl（若还没做过）
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml
mkdir -p .codebuddy/{agents,skills,rules} scripts pl/changes

# 安装本 adapter（需先 export PATH="$PL_HOME/bin:$PATH" 启用 pl CLI）
pl adapter install \
  $PL_HOME/adapters/adapter-nextjs-web \
  .

# 导出 adapter 注入的构建命令（或从 .pl-adapter.yaml 读）
export PL_BUILD_CHECK_CMD="npx tsc --noEmit"
```

完成后会得到：

```
.pl-adapter.yaml                          ← 记录注入元数据
pl/templates/{spec,plan,taskdag}.md       ← 场景化模板
.codebuddy/agents/nextjs-{architect,reviewer}.md
.codebuddy/skills/{react-server-components,nextjs-app-router,
                   nextjs-data-fetching,nextjs-performance}.md
.codebuddy/rules/{typescript-strict,nextjs-conventions,react-hooks}.md
scripts/adapter-nextjs-web-{build,verify,lint}.sh
```

## 提供什么

| 资产类 | 数量 | 亮点 |
|---|---|---|
| Templates | 3 | spec/plan/taskdag 适配前端页面分解口径 |
| Agents | 2 | 架构师（决策 RSC vs Client）+ 审查员（Web Vitals 视角） |
| Skills | 4 | RSC / App Router / Data Fetching / Performance |
| Rules | 3 | TS 严格模式 / Next.js 约定 / React Hooks |
| Scripts | 3 | build / verify / lint 三件套 |
| BuildAdapter | 1 | `$PL_BUILD_CHECK_CMD = npx tsc --noEmit` |

## 校验

```bash
pl adapter validate $PL_HOME/adapters/adapter-nextjs-web
```

## 案例

见 `docs/case-study.md`（完整 change 从 proposal → archive 的示范）。

## 版本

| 版本 | 日期 | 变化 |
|---|---|---|
| 0.1.0 | 2026-04-21 | 首版 |
