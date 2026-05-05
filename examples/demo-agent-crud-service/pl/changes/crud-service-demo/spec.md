# SPEC: CRUD Service Demo

实现一个内存版用户 CRUD 服务，满足：

- 创建用户时自动分配递增 id。
- 可以读取、更新、删除用户。
- `get_user` / `list_users` 返回副本，避免外部突变内部状态。
- 删除不存在的用户返回 `False`。

这个 demo 用于验证 `pl agent run` 的 repair policy：

- 初始实现故意不完整。
- gate D 由单测捕获失败。
- agent loop 分类为 `test_failure`。
- policy 自动选择 `repair_test_failure.sh`。
