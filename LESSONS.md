# LESSONS.md

## Lesson Format
- 现象：
- 根因：
- 修复：
- 防复发：

## 2026-03-08 事件-001：浏览器操作长时间卡住
- 现象：出现 27 分钟延迟响应
- 根因：浏览器操作未设置超时保护
- 修复：所有浏览器操作强制设置 timeoutMs / timeout
- 防复发：浏览器与网络相关操作默认加超时，不允许裸调用

## 2026-03-09 事件-002：Cron 投递失败
- 现象：daily / end-of-day cron 报错，无法发送 Telegram
- 根因：delivery 使用 channel=last，但 isolated 模式下缺失 chatId
- 修复：显式设置 Telegram channel 与 chatId
- 防复发：所有 cron 投递配置显式指定目标，不依赖 last

## 2026-03-09 事件-003：GLM 套餐未生效
- 现象：OpenClaw 调用 GLM 时未消耗 GLM Coding Plan 套餐额度
- 根因：使用了普通 zai API provider，而非 Coding Plan 专用接入方式
- 修复：新增 glm-coding provider，使用 `https://open.bigmodel.cn/api/coding/paas/v4`
- 防复发：订阅类模型必须验证实际额度消耗，不以“已配置成功”作为最终判定
