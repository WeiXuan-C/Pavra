-- ============================================
-- 验证 OAuth 设置脚本
-- ============================================
-- 运行此脚本来验证所有配置是否正确

-- 1. 检查 pgcrypto 扩展
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto')
    THEN '✅ pgcrypto 扩展已启用'
    ELSE '❌ pgcrypto 扩展未启用'
  END as pgcrypto_status;

-- 2. 测试 digest 函数
SELECT 
  CASE 
    WHEN digest('test', 'sha256') IS NOT NULL
    THEN '✅ digest() 函数工作正常'
    ELSE '❌ digest() 函数不可用'
  END as digest_status;

-- 3. 检查 profiles 表是否存在
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'profiles'
    )
    THEN '✅ profiles 表存在'
    ELSE '❌ profiles 表不存在'
  END as profiles_table_status;

-- 4. 检查 handle_new_user 函数
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc 
      WHERE proname = 'handle_new_user'
    )
    THEN '✅ handle_new_user 函数存在'
    ELSE '❌ handle_new_user 函数不存在'
  END as function_status;

-- 5. 检查触发器是否存在并启用
SELECT 
  CASE 
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'on_auth_user_created'
      AND tgrelid = 'auth.users'::regclass
    )
    THEN '❌ on_auth_user_created 触发器不存在'
    WHEN EXISTS (
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'on_auth_user_created'
      AND tgrelid = 'auth.users'::regclass
      AND tgenabled = 'D'
    )
    THEN '⚠️ on_auth_user_created 触发器已禁用'
    ELSE '✅ on_auth_user_created 触发器已启用'
  END as trigger_status;

-- 6. 显示最近的认证用户（最多5个）
SELECT 
  '最近的认证用户' as info,
  id,
  email,
  created_at,
  raw_app_meta_data->>'provider' as provider
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 7. 显示最近的 profiles（最多5个，通过 auth.users 的 created_at 排序）
SELECT 
  '最近的 profiles' as info,
  p.id,
  p.username,
  p.email,
  p.provider,
  p.role,
  u.created_at
FROM public.profiles p
JOIN auth.users u ON p.id = u.id
ORDER BY u.created_at DESC
LIMIT 5;

-- 8. 检查是否有用户没有对应的 profile
SELECT 
  '没有 profile 的用户' as warning,
  u.id,
  u.email,
  u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC
LIMIT 5;

-- 9. 显示触发器详细信息
SELECT 
  '触发器详细信息' as info,
  t.tgname as trigger_name,
  t.tgenabled as enabled,
  p.proname as function_name,
  pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'auth.users'::regclass
  AND t.tgname = 'on_auth_user_created';
