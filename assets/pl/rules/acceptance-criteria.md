---
id: acceptance-criteria
version: 1.0.0
scope: generic
category: meta
severity: error
description: 需求交付的通用验收标准与质量门禁（P0/P1/P2 分级）。具体检查项由栈级 rule 提供，本 rule 定义框架。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Acceptance Criteria · 验收标准与质量门禁

> **Rule-ID**: `ACC-001`
> **适用范围**: 所有需求交付（含新增 / 修改 / 迁移）
> **优先级**: P0（本 rule 自身即 P0）

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓，抽象具体检查项 |

---

## 设计原则

> 验收标准的三个核心要求：
> 1. **可解释** —— 每条标准说明"为什么要查这个"
> 2. **可追踪** —— 每条标准关联到具体 Rule-ID，违反时可定位到规范
> 3. **可复用** —— 标准与业务无关，适用于所有需求交付

**分层设计**：本 rule 定义 **框架**（P0/P1/P2 分级 + 各阶段退出条件），
具体检查项由栈级 rule 填充（例：`adapter-kotlin/rules/kotlin-acceptance.md`）。

---

## 1. 代码质量门禁（三级分层）

### P0 —— 必须通过，阻塞交付

| # | 检查项（通用） | 关联规则 | 栈级具体化示例 |
|---|---|---|---|
| 1 | **编译 / 构建通过** | `BUILD-001` | Kotlin: `gradle build` / Node: `npm run build` / Python: `pytest --collect-only` |
| 2 | **构建产物可运行** | `BUILD-001` | 移动：APK/IPA 打包成功；Web：SSR bundle；Service：容器 up |
| 3 | **无 lint error** | 栈级 rule | Kotlin: detekt ↓0 error；JS: eslint ↓0 error；Py: ruff ↓0 error |
| 4 | **任务清单 100% 完成** | — | `pl/changes/<change-id>/taskdag.md` 所有任务状态 `done` |
| 5 | **无栈级禁止模式** | 栈级 rule | 语言特定：Kotlin `!!` / JS `any` / Py 裸 except 等 |

**Rationale**: P0 项是代码的"生存线"。编译不过无法运行，禁止模式是已知高风险实践。

### P1 —— 必须通过，不阻塞但需跟踪

| # | 检查项（通用） | 关联规则 |
|---|---|---|
| 6 | **架构合规** | 栈级 architecture rule（MVVM / layered / hex / clean...）|
| 7 | **类型安全** | 栈级 rule（严格 null 安全 / strict 类型 / ...）|
| 8 | **日志完整** | 栈级 logging rule（关键路径必有 info/error 日志）|
| 9 | **文档同步** | `GIT-001` / docs 目录更新 |
| 10 | **序列化合规**（如适用）| 栈级 serialization rule |

**Rationale**: P1 项是代码质量的"健康线"。不阻塞发布，但累积会降低可维护性。

### P2 —— 建议通过

| # | 检查项 | 关联 |
|---|---|---|
| 11 | **性能不劣化** | 首屏/响应时间 ≤ 基线 × 1.1 |
| 12 | **Code Review 通过** | 全部 rules |
| 13 | **迁移/变更文档更新** | `GIT-001` |

**Rationale**: P2 项是代码的"卓越线"。通过可显著提升用户体验和协作效率。

---

## 2. 迁移验收标准

### Rule `ACC-001-MIGRATE`: 迁移必须完成功能等价验证

**Rationale**: 迁移的核心承诺是"**功能不丢失**"。没有等价验证，任何遗漏都可能成为线上事故。

```
旧版功能清单 → 逐项对比 → 新版功能
```

| 验证维度 | 检查项 | 量化标准 | 方法 |
|---------|--------|---------|------|
| **UI 一致性** | 布局、颜色、字体与设计稿/旧版一致 | 关键截图差异率 ≤ 5% | 截图对比 |
| **交互完整性** | 点击、滑动、输入等交互正常 | 交互点覆盖率 = 100% | 手动 / 自动测试 |
| **数据正确性** | API 数据显示正确、计算无误 | 测试用例通过率 = 100% | 功能测试 |
| **边界处理** | 空数据、错误数据、网络异常 | 边界场景覆盖率 ≥ 90% | 异常测试 |
| **跨平台一致**（如适用）| Android 和 iOS 表现一致 | 双平台功能一致率 = 100% | 双平台测试 |

### 迁移完成标志

- [ ] change 已 archive（**可追踪**：关联 change-id）
- [ ] 构建验证通过（**关联**：`BUILD-001`）
- [ ] 功能对比测试通过（**关联**：上表验证维度）
- [ ] 文档更新完成（**关联**：`GIT-001`）
- [ ] Code Review 通过（**关联**：全部 Rules）

---

## 3. pl-pipeline 阶段门禁标准

### Rule `ACC-001-SPEC`: pl 每个阶段有明确的退出条件

**Rationale**: 阶段门禁确保工作 **不跳步、不遗漏**，每个阶段产出物可被下一阶段消费。

### SPEC 阶段（A0 退出条件）

- [ ] `spec.md` 含 Why / What / R1..Rn（带优先级）
- [ ] `deps.md`（若 legacy 迁移场景）依赖分析完成
- [ ] 不确定项登记到 Open Questions 章节
- [ ] 所有 BLOCKING 项已有结论 *或* 已生成 `confirmation-request.md`
- [ ] `.state.md` 标注 stage=SPEC、gate=A0、result=pass/soft_pass

### PLAN 阶段（B1 退出条件）

- [ ] `plan.md` 含架构决策 + 风险 + 里程碑
- [ ] `taskdag.md` 无环、每个 task 有依赖 / 完成标志
- [ ] `api.md`（若接口 ≥ 2）接口契约锁定
- [ ] `testmatrix.md` 覆盖所有 P0 功能

### IMPLEMENT 阶段（C 退出条件）

- [ ] `taskdag.md` 中所有 task 状态 = done
- [ ] 代码 P0 检查全部通过
- [ ] P1 通过 **或** 已建立跟踪 issue

### VERIFY / SMOKE 阶段（D / E 退出条件）

- [ ] 所有 check.run 事件 status=pass
- [ ] SMOKE probe 全过 **或** 显式 skip + 理由
- [ ] gate.eval 结果 = passed

### ARCHIVE 阶段（G 退出条件）

- [ ] 变更已合入主分支
- [ ] **资产沉淀检查**：新沉淀的 rules/skills 已入库（见内循环机制）
- [ ] `MIGRATION_LOG.md` / `CHANGELOG.md` 已更新（如适用）
- [ ] 本 change 的 `.state.md` 终态 = archived

---

## 4. 验收执行快速参考

```bash
# === P0 自动化检查（建议集成到 CI）===

# 1. 构建验证（栈级）
#    Kotlin: ./gradlew build
#    Node:   npm run build
#    Python: python -m build
# 具体命令由 .pl-adapter.yaml 声明，pl-runner.sh 统一执行

# 2. 禁止模式扫描（栈级）
#    由栈级 rule 通过 pl-rule-scan.sh 执行
pl rule-scan --severity error --fail-on-first

# === P1 人工检查 ===
# 3. 架构合规  → 栈级 architecture reviewer agent
# 4. 日志完整  → Code Review 时逐模块检查
# 5. 文档同步  → 检查 docs/ 和 MIGRATION_LOG.md
```

---

## 5. NO-list（本 Rule 不做的事）

- ❌ 不钦定具体语言/栈的禁止模式 → 放 `adapters/adapter-<stack>/rules/`
- ❌ 不提供具体的 lint 命令 → 由 adapter 的 `checks[]` 声明
- ❌ 不替代 code review → 人工 review 仍是 P1
- ❌ 不强制所有 P2 项 → 由项目自定义权衡
