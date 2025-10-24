# 🚨 快速修复：OAuth 登录错误

## 问题
新用户第三方登录时出现：`function digest(text, unknown) does not exist`

## 立即修复（2 分钟）

### 步骤 1: 打开 Supabase SQL Editor
1. 访问 https://supabase.com/dashboard
2. 选择你的项目
3. 点击左侧菜单 **SQL Editor**

### 步骤 2: 运行这个命令
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

### 步骤 3: 验证
```sql
SELECT digest('test', 'sha256');
```

如果返回结果（一串十六进制），说明修复成功！

### 步骤 4: 测试登录
清除浏览器缓存，重新尝试 OAuth 登录。

---

## 为什么会出现这个问题？

Supabase 的认证系统需要 `pgcrypto` 扩展来处理密码哈希。新项目可能没有自动启用这个扩展。

## 预防未来问题

在部署新的 Supabase 项目时，始终先运行：
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_net;
```

这些扩展已经添加到 `lib/database/schema.sql` 文件的开头。

## 仍然有问题？

查看 `OAUTH_LOGIN_FIX.md` 获取详细的故障排除指南。
