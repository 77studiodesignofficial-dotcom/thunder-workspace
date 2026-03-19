# KIMI_WEBSEARCH_401_RUNBOOK.md

## 适用场景
当 OpenClaw 的 `web_search` 配置为 `provider = "kimi"` 时，调用返回：

- `Kimi API error (401): Invalid Authentication`

## 先验结论（2026-03-19 已验证）
这个报错**不一定是 key 本身失效**。
在本环境里，最终根因是：

- `web_search(kimi)` 默认请求 `https://api.moonshot.ai/v1`
- 当前使用的 Moonshot/Kimi key 实际只对 `https://api.moonshot.cn/v1` 有效
- 结果是：**key 被正确读取，但请求打到了错误 endpoint**，从而报 401

## 标准排查顺序

### 1. 确认当前 provider
检查：
- `tools.web.search.provider`

期望：
- 值为 `"kimi"`

### 2. 确认当前 search 子配置
检查：
- `tools.web.search.kimi.apiKey`
- `tools.web.search.kimi.baseUrl`
- `tools.web.search.kimi.model`

### 3. 不要先入为主地判断为“key 失效”
先区分三类问题：

1. **没读到 key**
2. **读到了 key，但 endpoint 错了**
3. **key 本身无效 / 权限不支持**

### 4. 验证 endpoint 口径
重点比较：
- `https://api.moonshot.ai/v1`
- `https://api.moonshot.cn/v1`

如果出现：
- `.cn = 200`
- `.ai = 401`

则应优先判断为：
- **endpoint 口径不匹配**
- 而不是直接更换 key

### 5. 修复方式
在确认 `.cn` 可用时，设置：

- `tools.web.search.kimi.baseUrl = "https://api.moonshot.cn/v1"`
- `tools.web.search.kimi.model = "moonshot-v1-128k"`

必要时显式设置：
- `tools.web.search.kimi.apiKey = <working moonshot key>`

## 本环境最终生效配置
```json
{
  "tools": {
    "web": {
      "search": {
        "provider": "kimi",
        "kimi": {
          "apiKey": "<redacted>",
          "baseUrl": "https://api.moonshot.cn/v1",
          "model": "moonshot-v1-128k"
        }
      }
    }
  }
}
```

## 自动化守护
已存在自动同步脚本：
- `/Users/titen/.openclaw/workspace/kimi-websearch-endpoint-sync.sh`

已存在 cron：
```cron
*/30 * * * * /Users/titen/.openclaw/workspace/kimi-websearch-endpoint-sync.sh >> /Users/titen/.openclaw/logs/kimi-websearch-sync.log 2>&1
```

### 守护逻辑
- 同时探测 `.cn` 与 `.ai`
- 自动选取可用 endpoint
- 仅在 endpoint 变化时回写配置并重启 Gateway

## 验收标准
满足以下 3 项才算修复完成：

1. `openclaw.json` 中 `tools.web.search.kimi.baseUrl` 与当前可用 endpoint 一致
2. `kimi-websearch-sync.log` 显示当前 endpoint 检查正常
3. `web_search` 实测成功返回，不再出现 `401 Invalid Authentication`

## 经验规则
当 `web_search(kimi)` 报 401 时，**优先查 endpoint 口径，再查 key**。
不要默认把 401 直接归因为 API key 失效。
