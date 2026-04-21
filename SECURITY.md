# 安全策略

## 支持的版本

pl-pipeline 目前处于 `v0.x` 早期阶段，**仅最新 minor 版本**会收到安全更新。

| 版本 | 是否支持 |
|------|---------|
| 0.x (latest) | ✅ |
| 更旧版本 | ❌ |

## 报告漏洞

如果你发现 pl-pipeline 中的安全漏洞，**请不要通过公开的 GitHub Issue 披露**。

### 首选：GitHub Security Advisories

1. 访问 https://github.com/walkertop/pl-pipeline/security/advisories/new
2. 填写报告细节

### 备选：私下联系

如果无法通过上述方式提交，请：

1. 在 GitHub 上提一个**低敏感度**的 Issue（例如 "Security: request private disclosure channel"）
2. 在 Issue 中 @walkertop 请求私聊渠道
3. 维护者会回复建立私聊

## 报告内容应包含

- 漏洞类型（代码注入 / 路径遍历 / 命令注入 / 权限绕过 / 其它）
- 受影响版本或 commit SHA
- 复现步骤（最小化示例）
- 潜在影响（执行任意命令 / 读取任意文件 / 拒绝服务 / 其它）
- 你建议的修复方案（可选）

## 响应时间

- **初步确认**：3 个工作日内
- **影响评估**：7 个工作日内
- **修复发布**：视严重程度 7-30 天

## 已知的安全考量

pl-pipeline 的设计默认执行来自项目内的脚本（`.codebuddy/hooks/*.sh` 等），因此：

- **不要**在 pl-pipeline 管理的项目里引入不可信的 hook 脚本
- **不要**使用 `pl` 执行来自不可信来源的 preset（社区 preset 目前仅为规划，未开放）
- CI 环境运行 `pl` 时建议使用只读 token

## 致谢

欢迎安全研究者贡献。经确认的有效漏洞报告会在 Release Notes 和 `SECURITY.md` 中致谢（除非报告者要求匿名）。
