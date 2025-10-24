# OAuth 登录错误修复指南

## 问题描述
新用户使用第三方登录（Google/GitHub/Discord）时出现错误：
```
ERROR: function digest(text, unknown) does not exist (SQLSTATE 42883)
```

## 原因
Supabase 的内部认证系统需要 `pgcrypto` 扩展来处理密码哈希，但该扩展可能未启用。

## 解决方案

### ⭐ 推荐方法: 使用完整修复脚本

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目
3. 进入 **SQL Editor**
4. 复制并运行 `lib/database/complete_oauth_fix.sql` 文件的全部内容
5. 查看执行结果，确保所有步骤都显示 ✅
6. 运行 `lib/database/verify_oauth_setup.sql` 验证配置
7. 清除浏览器缓存，重新测试 Google 登录

**为什么这个方法更好？**
- 强制重新安装 pgcrypto 扩展（使用 CASCADE）
- 重新创建触发器和函数
- 自动验证所有配置
- 提供详细的执行反馈

### 方法 2: 快速修复（如果推荐方法不起作用）

在 SQL Editor 中运行：

```sql
-- 强制重新安装 pgcrypto
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
CREATE EXTENSION pgcrypto;

-- 验证
SELECT digest('test', 'sha256');
```

### 方法 3: 完整诊断

如果方法 1 和 2 都不起作用，运行 `lib/database/diagnose_and_fix.sql` 进行完整诊断。

## 验证修复

1. 清除浏览器缓存和 cookies
2. 尝试使用 Google/GitHub/Discord 登录
3. 检查是否能成功登录并创建 profile

## 如果问题仍然存在

### 检查 1: 确认触发器正常工作
```sql
-- 查看 handle_new_user 函数
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- 查看触发器
SELECT * FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
```

### 检查 2: 手动测试 profile 创建
```sql
-- 查看最近的认证用户
SELECT id, email, created_at, raw_user_meta_data
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 查看对应的 profiles
SELECT p.id, p.username, p.email, p.role, p.created_at
FROM public.profiles p
JOIN auth.users u ON p.id = u.id
ORDER BY p.created_at DESC
LIMIT 5;
```

### 检查 3: 查看错误日志
在 Supabase Dashboard > Logs > Postgres Logs 中查看详细错误信息。

## 预防措施

在 `lib/database/schema.sql` 开头添加：
```sql
-- 确保必需的扩展已启用
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_net;
```

## 联系支持

如果以上方法都无法解决问题：
1. 导出完整的错误日志
2. 检查 Supabase 项目的 PostgreSQL 版本
3. 联系 Supabase 支持团队

## 相关文件
- `lib/database/fix_digest_error.sql` - 快速修复脚本
- `lib/database/diagnose_and_fix.sql` - 完整诊断脚本
- `lib/database/function.sql` - 用户创建触发器
- `lib/database/schema.sql` - 数据库架构
