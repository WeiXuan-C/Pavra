-- ============================================
-- 使用 Supabase 管理员权限修复触发器
-- ============================================
-- 注意：这个脚本需要在 Supabase Dashboard 的 SQL Editor 中以管理员身份运行

-- 方法 1: 使用 supabase_admin 角色
DO $$
BEGIN
  -- 尝试启用触发器
  EXECUTE format('ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created');
  RAISE NOTICE '✅ 触发器已启用';
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE '⚠️ 权限不足，尝试使用管理员权限...';
    -- 如果失败，说明需要联系 Supabase 支持或使用其他方法
END $$;

-- 验证触发器状态
SELECT 
  tgname as trigger_name,
  tgenabled as enabled_code,
  CASE tgenabled
    WHEN 'O' THEN '✅ 已启用'
    WHEN 'D' THEN '❌ 已禁用'
    WHEN 'R' THEN '✅ 已启用（仅副本）'
    WHEN 'A' THEN '✅ 始终启用'
    ELSE '❓ 未知状态: ' || tgenabled
  END as status
FROM pg_trigger
WHERE tgname = 'on_auth_user_created'
  AND tgrelid = 'auth.users'::regclass;
