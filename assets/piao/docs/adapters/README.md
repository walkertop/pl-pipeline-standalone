# piao-pipeline · Adapters

> 本目录存放 **piao-pipeline 的业务场景适配层**（adapter）。每个子目录是一个独立 adapter，把 kernel 的通用契约翻译成具体业务工作流。

---

## 目录结构

```
adapters/
├── README.md                         ← 本文件（总览 + 新增 adapter 指南）
└── <adapter_name>/                   ← 每个 adapter 一个目录
    ├── README.md                     ← adapter 入口，回答"这个 adapter 在做什么"
    ├── task-types.md                 ← 本 adapter 注册的 task 类型（扩展点 A）
    ├── acceptance-criteria.md        ← 本 adapter 的验收脚本清单（扩展点 B）
    ├── trace-impl.md                 ← 本 adapter 的 trace 实现（扩展点 C）
    └── evolution-sources.md          ← 本 adapter 的演化源清单（扩展点 D）
```

四个扩展点的规范定义见 `kernel/07-extensibility.md §2`。

---

## 已有 adapter 清单

| adapter 目录 | status | 用途 | 上游 kernel rev |
|------------|--------|------|----------------|
| `frontend-migration/` | charter published · task-types published | 把 legacy source framework 的 UI 业务单元迁移到 host language + declarative UI DSL | `m1_final_decisions@v1` + kernel 三文档 @v1.1 |

> **2026-04-18 阶段 2 路径 A 完结**：`frontend-migration` 阶段 2 产出 2 份 adapter 文档（charter + task-types）+ 2 份配对 review，累计压测出 7 条 kernel 缺口；经 `urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` 合并处理 R1-R7，kernel 三文档完成小升：
> - `01-identity-model@v1.1`（§3.4 adapter 资产 scope 约定 + §4.4 命名风格）
> - `02-artifact-model@v1.1`（§2.1.1 `artifact.*` 派生示范 + §2.1.2 命名风格 + §2.2 派生类型注册方式）
> - `07-extensibility@v1.1`（§2.5 扩展点占位声明建议格式 + §2.6 扩展点合规性自验证 checklist v0.1）
>
> §1.2 共 7 条 kernel 缺口中 6 条 consumed（Q1/Q2/Q3/Q5/Q6/Q7），Q4 延期至阶段 3 与 §1.1 合并清理（wordcheck v0.1 尚不支持行内豁免）。
>
> **下一步**：进入**分支 2b** —— 启动工作流 A（M4 Snapshot Model 起稿）。

> **2026-04-18 分支 2b 启动 · M4 Snapshot Model 首版 draft 落地**：
> - `urn:piao:spec:architecture:version_snapshot@v1 (draft)` 已发布，回答 `post_m1_kickoff@v1 §4` 锁定的四个必答问题（何时打 · 装什么 · 怎么寻址 · 与 drift 的接口）
> - 配对 review `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1` 已发布，判定 draft 成色**充分**，但压测出 7 条新 kernel 缺口（Q8–Q14）：
>   - **路径 A 4 条**（Q10/Q11/Q13/Q14）：04 内部原地消化，不升 rev
>   - **路径 B 3 条** + 联动 2 条（Q8→R12 / Q9→R13 / Q12→R14 + R15/R16）：建议打包为 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` 合并处理
> - 04 draft 未发明新术语 / 新事件类型 / 新 kind，完全引用 kernel 三件套 + v1.1 小升（`01 §3.4` / `01 §4.4` 被直接消费，验证路径 A 决策有效）
>
> **下一步**：按 review §4.3 推荐"先 A 后 B"——04 内部消化 R8–R11 → 启动 m4_snapshot_kernel_alignment proposal → 04 draft → published → M5 Drift 起稿

---

## 新增 adapter 的最小 Checklist

在本目录下新建 `<your_adapter>/` 之前，确认：

- [ ] 该业务场景**不能**用 kernel 现有通用契约表达（否则属于 kernel 应补齐的能力，不是新 adapter）
- [ ] adapter 名只使用**描述性通用词**（如 `frontend-migration` / `backend-api-spec`），避免具体工具名
- [ ] 新 adapter 必须完整实现 `kernel/07-extensibility.md §2` 的四个扩展点（至少占位声明）
- [ ] 新 adapter 的第一次 `artifact.produced` 事件必须指向 kernel 某个 `published` 状态的 rev 作为 `upstream`
- [ ] 若新 adapter 引入了**新的禁用词豁免需求**（如"本 adapter 范围内允许用 `compose`"），通过 `scenario-wordlist.md` 的白名单 patch 提案登记，而非私自偏移

---

## 与 kernel 的关系约束

> 这一段是**双向契约**。违反任一条都会打破 kernel 的通用性承诺。

### Kernel 对 adapter 的承诺
1. Kernel 文档不出现**任何** adapter 名字（除 `_review/` 历史追述段）
2. Kernel 契约变更（任何 `rev` 升级）必须提前 1 个 milestone 通知 adapter 维护者
3. Kernel 的 event schema 变更走 `01-identity-model.md §10.1` published/draft 两态

### Adapter 对 kernel 的承诺
1. Adapter 的 artifact 必须使用 kernel 已注册的 kind（扩展新 kind 需先提 `kernel/01 §2` 的 proposal）
2. Adapter 产出的 L2 事件必须挂到某条 L1 事件下（见 `kernel/03 §2`）
3. Adapter 不得在其文档里修改 kernel 的通用规范定义——只能**引用**与**扩展**

---

## 导航

- kernel 契约索引：`docs/piao-pipeline/00-overview.md §1`
- 扩展点规范：`docs/piao-pipeline/kernel/07-extensibility.md §2`
- 场景词白名单：`docs/piao-pipeline/kernel/scenario-wordlist.md`
- M1 review 产物：`docs/piao-pipeline/kernel/_review/`（3 份收尾文档 + 本目录的落地 proposal）
