# OpenClaw Vault Server - 架构设计

## 组件

1. **Vault API** (Go/Python)
   - REST API: /store, /read, /list, /audit
   - mTLS 客户端认证
   - 请求签名验证

2. **存储后端**
   - SQLite (单节点) / PostgreSQL (多节点)
   - 字段级 AES-256-GCM 加密
   - 密钥派生: Argon2id

3. **审计系统**
   - 只追加日志 (WAL)
   - 记录: who/when/what-action/key-name-hash
   - 不可篡改 (签名链)

4. **CLI 客户端**
   - 类似 `op` 的界面
   - 本地缓存（内存，不落地）
   - 短生命周期令牌

## 部署模式

```
┌─────────────┐     mTLS      ┌─────────────┐
│  OpenClaw   │ ◄───────────► │ Vault API   │
│  (Client)   │   短期令牌     │ (Docker)    │
└─────────────┘               └──────┬──────┘
                                     │
                              ┌──────▼──────┐
                              │  PostgreSQL │
                              │  (加密存储)  │
                              └─────────────┘
```

## 预估工作量

| 模块 | 人天 |
|------|------|
| API 开发 | 5-7天 |
| CLI 客户端 | 3-4天 |
| 审计系统 | 2-3天 |
| 测试/安全审计 | 3-5天 |
| **总计** | **13-19天** |

## 风险评估

⚠️ 自研密码学系统风险极高
- 建议用成熟库: HashiCorp Vault, Bitwarden SDK
- 或基于 age/mkcert 等经过审计的工具
