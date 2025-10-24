-- ============================================
-- 诊断和修复 OAuth 登录问题
-- ============================================

-- 步骤 1: 检查当前安装的扩展
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pg_net');

-- 步骤 2: 启用必需的扩展
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 步骤 3: 验证 digest 函数
DO $$
BEGIN
  -- 测试 digest 函数
  PERFORM digest('test', 'sha256');
  RAISE NOTICE 'digest() 函数工作正常';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '错误: %', SQLERRM;
END;
$$;

-- 步骤 4: 检查 auth.users 表的触发器
SELECT 
  tgname AS trigger_name,
  tgtype,
  proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'auth.users'::regclass;

-- 步骤 5: 检查 profiles 表是否存在且结构正确
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 步骤 6: 测试创建一个测试用户 profile
-- 注意：这只是测试，不会实际创建用户
DO $$
DECLARE
  test_id UUID := gen_random_uuid();
BEGIN
  -- 尝试插入测试数据
  INSERT INTO public.profiles (
    id, username, email, role, language, theme_mode
  ) VALUES (
    test_id,
    'test_user_' || substring(test_id::text, 1, 8),
    'test@example.com',
    'user',
    'en',
    'system'
  );
  
  RAISE NOTICE '测试插入成功';
  
  -- 清理测试数据
  DELETE FROM public.profiles WHERE id = test_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '测试插入失败: %', SQLERRM;
END;
$$;

-- ============================================
-- 执行说明
-- ============================================
-- 1. 在 Supabase Dashboard > SQL Editor 中运行此脚本
-- 2. 查看输出结果
-- 3. 如果看到任何错误，记录下来
-- 4. 重新测试 OAuth 登录
--
-- 常见问题：
-- - 如果 pgcrypto 扩展无法启用，可能需要联系 Supabase 支持
-- - 如果 profiles 表不存在，需要先运行 schema.sql
-- - 如果触发器有问题，可能需要重新创建 handle_new_user 函数
