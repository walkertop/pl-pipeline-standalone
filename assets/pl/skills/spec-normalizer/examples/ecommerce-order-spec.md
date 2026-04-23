# spec.md · ecommerce-order-detail

> **场景**：电商订单详情页（脱敏示例，用于 spec-normalizer skill 的输出演示）
> **change-id**: `feat-order-detail`
> **生成于**: 本示例用于 `spec-normalizer@1.0.0`

---

## 1. 基本信息

| 字段 | 值 |
|------|---|
| id | `order-detail` |
| 业务域 | 订单 / Order |
| 入口 | 个人中心 → 订单列表 → 订单卡片点击 |
| 复杂度 | 中（预估 8 个组件 / 3 个接口） |

## 2. 功能清单

| ID | 优先级 | 描述 | 验收标准 |
|----|--------|------|---------|
| R1 | P0 | 展示订单基本信息（订单号 / 下单时间 / 状态） | 所有字段非空，状态与后端返回一致 |
| R2 | P0 | 展示商品列表（图片 / 名称 / 数量 / 单价） | 滚动流畅，图片懒加载 |
| R3 | P0 | 展示金额明细（商品总价 / 运费 / 优惠 / 实付） | 金额计算和后端一致 |
| R4 | P1 | 按订单状态展示操作按钮（付款/取消/确认收货/售后）| 状态变化后按钮自动刷新 |
| R5 | P1 | 跳转物流详情（已发货状态显示） | 传递正确的物流单号 |
| R6 | P2 | 复制订单号到剪贴板 | 提示"已复制" |

## 3. UI 结构（Screen Map）

```
┌──────────────────────────────────────┐
│ [← NavBar: "订单详情"  复制按钮 ]    │ ← 复用: NavBar
├──────────────────────────────────────┤
│ 订单状态区（大字 + 描述）              │ ← 新建: OrderStatusBanner
│                                        │
├──────────────────────────────────────┤
│ 商品列表（R2）                         │ ← 复用: List
│  [图] 商品 A   x2   ¥99               │ ← 新建: OrderItemRow
│  [图] 商品 B   x1   ¥45               │
├──────────────────────────────────────┤
│ 金额明细（R3）                         │ ← 新建: PriceBreakdown
│ 商品总价:                   ¥144      │
│ 运费:                         ¥5      │
│ 优惠券:                     -¥10      │
│ ──────────────                         │
│ 实付:                        ¥139      │
├──────────────────────────────────────┤
│ 订单信息（订单号 / 时间 / 地址 / ...） │ ← 新建: OrderInfoSection
├──────────────────────────────────────┤
│ [底部操作按钮组] R4                    │ ← 新建: OrderActionBar
└──────────────────────────────────────┘
```

## 4. 数据依赖

| 接口 | 方法 | 路径 | 说明 | P0? |
|------|------|------|------|-----|
| 获取订单详情 | GET | `/api/orders/{id}` | 返回订单全量信息 | ✅ |
| 获取物流信息 | GET | `/api/logistics/{tracking_no}` | R5 需要 | |
| 取消订单 | POST | `/api/orders/{id}/cancel` | R4 中"取消"按钮 | |

## 5. 状态机

```
pending_payment ──> paid ──> shipped ──> delivered ──> completed
      │              │          │
      └── cancelled  └── refunding <── refund_requested
```

## 6. 跳转关系

| 入口 | 说明 |
|------|------|
| 订单列表 (OrderList) → OrderDetail(order_id) | 主入口 |
| 支付结果页 → OrderDetail | 支付成功后回跳 |

| 出口 | 说明 |
|------|------|
| OrderDetail → LogisticsDetail(tracking_no) | R5 触发 |
| OrderDetail → AfterSalesApply(order_id) | R4 中"售后" |

## 7. 埋点

- PV: `page_view_order_detail` (params: order_id, status)
- Click: `order_detail_action_click` (params: action_type)

## 8. Open Questions

| ID | 等级 | 描述 | 阻塞 |
|----|------|------|------|
| Q-001 | L3 | 订单状态为 `refunding` 时，操作按钮显示什么？当前方案：只显示"联系客服"；备选：同时显示"撤回申请" | NON_BLOCKING（按推荐推进） |
| Q-002 | L4 | "售后申请"的入口条件 —— 所有已付款订单都能申请？还是仅限 shipped 之后？ | **BLOCKING**（生成 confirmation-request） |

## 9. 验收基线

- [ ] 所有 P0 功能完成
- [ ] 状态流转的所有状态都有 UI 覆盖
- [ ] 首屏 < 1.5s（Lighthouse）
- [ ] 金额计算和 `GET /api/orders/{id}` 返回完全一致（0 偏差）
- [ ] 无图片时 `OrderItemRow` 有 placeholder
- [ ] 网络错误时展示 retry
- [ ] 若存在 legacy 版本：功能对比差异 ≤ 5%

---

**脱敏说明**：本示例模拟一个电商订单场景，不绑定任何具体项目。组件名如 `NavBar` / `List` 是通用语义名，真实项目请替换为项目组件库中的对应名称。
