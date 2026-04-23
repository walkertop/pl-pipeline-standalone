---
id: build-verification
version: 1.0.0
scope: generic
category: verify
severity: error
description: 构建验证的通用协议 —— 何时构建、如何分级触发、失败处理。具体构建命令由 .pl-adapter.yaml 声明。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Build Verification · 构建验证协议

> **Rule-ID**: `BUILD-001`
> **适用范围**: 所有代码变更
> **优先级**: P0

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓，抽象具体构建命令到 adapter |

---

## 设计原则

构建验证的通用需求：
- 构建是质量的**最低门槛**，每个平台/栈都有自己的构建命令
- 不能每改一行就 build（浪费）也不能等到 commit 才 build（太晚）
- **变更感知触发**（change-aware build）是最佳平衡点
- 具体构建命令**不属于 pl-core**，由 `.pl-adapter.yaml` 声明

---

## 1. 构建命令来源

### Rule `BUILD-001-STD`: 每次代码变更后必须执行标准构建验证

构建命令从 `.pl-adapter.yaml` 的 `build_adapter` 节读取：

```yaml
# .pl-adapter.yaml 示例
build_adapter:
  install: "<栈级安装命令>"     # 如 npm install / pip install -r requirements.txt
  build:   "<栈级构建命令>"     # 如 npm run build / gradle build / cargo build
  test:    "<栈级测试命令>"
```

执行入口：
```bash
bash $PL_HOME/scripts/pl-runner.sh --check build
```

**绝不在 rule / core script 里硬编码**具体命令（如 `gradle xxx` / `npm xxx`）。

---

## 2. 执行时机（分级触发）

### Rule `BUILD-001-WHEN`: 构建验证有明确触发条件

**Rationale**: 过少验证会遗漏问题，过多会拖慢开发。按变更风险分级。

### 必须执行（P0）
- ✅ 每完成一个 task（`taskdag.md` 里的一个 task）后
- ✅ 代码变更影响多个模块时
- ✅ 集成新组件 / 新依赖后
- ✅ 提交代码前最终验证
- ✅ 修复编译错误后

### 建议执行（P1）
- 📋 新增 serialization / schema 定义后（若栈需要代码生成）
- 📋 修改架构层文件（Module 注册 / DI 配置 / 中间件）
- 📋 修改构建配置（gradle / package.json / Cargo.toml / ...）

**验收关联**: `ACC-001` P0 第 1、2 项。

---

## 3. 变更感知自动构建（Change-Aware Build）

### Rule `BUILD-001-AUTO`: Coding 过程中按变更规模启发式触发

**Rationale**: 不能等到 commit 才发现编译错误——越晚发现修复成本越高。
但也不能每改一行就 build。**基于变更规模的启发式触发**是最佳平衡点。

### 触发脚本

Agent / IDE 应周期性调用：
```bash
bash $PL_HOME/scripts/should-build.sh        # 退出码 0=需要, 1=不需要
bash $PL_HOME/scripts/should-build.sh --json # JSON 格式，供程序解析
```

（脚本若在独立仓尚未提供，由项目自行实现；通用阈值参考下表）

### 通用触发规则（满足任一即触发）

| # | 信号 | 推荐阈值 | Rationale |
|---|------|---------|-----------|
| 1 | 变更行数（新增+删除） | ≥ 100 行 | 大规模改动出错概率高 |
| 2 | 变更源文件数 | ≥ 5 个 | 跨文件修改易出链路问题 |
| 3 | 跨模块改动 | ≥ 2 个顶层目录 | 影响面大，需及时验证 |
| 4 | 核心架构文件改动 | 由 adapter 标注 | 架构层改动风险高 |
| 5 | 新建文件数 | ≥ 3 个 | 新文件涉及 import / 注册等易出错环节 |
| 6 | 时间兜底 | ≥ 30 分钟有未验证改动 | 避免长时间不验证 |

阈值可通过环境变量覆盖（`SHOULD_BUILD_LINES=80` 等）。

### Agent 检查点协议

Agent 在 coding 过程中，应在以下检查点调用：

```
Coding 检查点（建议时机）:
  ├─ CP1: 每完成一个独立功能单元
  ├─ CP2: 每完成一个 task（taskdag.md 中的一项）
  ├─ CP3: 切换到不同模块/页面开发前
  └─ CP4: 即将向用户汇报进度前
```

检查点处理流程：
```
1. 运行 should-build.sh --json
2. 若 shouldBuild=true:
   a. 运行 pl-runner.sh --check build
   b. 成功 → should-build.sh --mark → 继续
   c. 失败 → 立即修复 → 重新构建 → 标记
3. 若 shouldBuild=false:
   → 继续开发，无需中断
```

### 构建后标记

每次成功构建后**必须**标记，供时间兜底规则正确计算：
```bash
bash $PL_HOME/scripts/should-build.sh --mark
```

---

## 4. 失败处理流程

### Rule `BUILD-001-FAIL`: 构建失败必须记录并按流程修复

**Rationale**: 构建错误的解决经验是 **可复用资产**，记录下来可加速后续同类问题的解决。

```
构建失败
  ├─ 1. 记录错误信息到 docs/errors/ 目录（附上下文 + 修复方案）
  ├─ 2. 分析错误根因
  │   ├─ 编译错误 → 修复代码
  │   ├─ 依赖错误 → 检查 package manifest
  │   └─ 代码生成 / 注解处理器错误 → 检查相关 rule
  ├─ 3. 修复问题
  ├─ 4. 重新执行构建验证
  └─ 5. 确认通过后继续工作
  └─ 6. （可选）把该错误+修复写入 retro-miner 输入，供未来 pattern 挖掘
```

---

## 5. 构建环境约束（由 adapter 声明）

**本 rule 不钦定任何版本**。版本锁定由 `.pl-adapter.yaml` 或 `requires.tools` 节处理。

具体示例见栈级 adapter 的 `README.md`。

---

## 6. NO-list（本 Rule 不做的事）

- ❌ 不提供具体构建命令 → 由 `.pl-adapter.yaml` 的 `build_adapter` 声明
- ❌ 不提供语言/栈特定的错误速查 → 放 `adapters/adapter-<stack>/rules/build-errors.md`
- ❌ 不强制实现 `should-build.sh` → 项目自行实现或跳过（P1）
- ❌ 不替代 CI/CD → 本 rule 是 **本地开发期** 的纪律，CI 由 `.pl-adapter.yaml` 对应 pipeline 承担

---

## 7. 与其他 rule 的关系

| 关联 | 方向 | 说明 |
|------|------|------|
| `ACC-001` 验收标准 | 上游 | P0 项 1/2/3 依赖本 rule |
| `GIT-001` 提交规范 | 平级 | 提交前的最后一道构建验证 |
| 栈级 `build-errors.md` | 下游 | 具体错误速查 |
