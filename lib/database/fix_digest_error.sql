-- ============================================
-- 修复 digest() 函数错误
-- ============================================
-- 这个错误通常发生在 OAuth 登录时
-- Supabase 需要 pgcrypto 扩展来处理密码哈希

-- 1. 启用 pgcrypto 扩展
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. 验证扩展已启用
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';

-- 3. 测试 digest 函数
SELECT digest('test', 'sha256');

-- ============================================
-- 说明
-- ============================================
-- 如果上面的命令成功执行，digest() 函数应该可以正常工作了
-- 这将修复 OAuth 登录时的 "function digest(text, unknown) does not exist" 错误
--
-- 在 Supabase Dashboard 中执行：
-- 1. 进入 SQL Editor
-- 2. 运行这个脚本
-- 3. 重新测试 OAuth 登录
