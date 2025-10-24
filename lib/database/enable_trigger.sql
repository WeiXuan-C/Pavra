-- ============================================
-- 启用 on_auth_user_created 触发器
-- ============================================

-- 启用触发器
ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created;

-- 验证触发器已启用
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  CASE tgenabled
    WHEN 'O' THEN '✅ 已启用'
    WHEN 'D' THEN '❌ 已禁用'
    WHEN 'R' THEN '✅ 已启用（仅副本）'
    WHEN 'A' THEN '✅ 始终启用'
    ELSE '❓ 未知状态'
  END as status
FROM pg_trigger
WHERE tgname = 'on_auth_user_created'
  AND tgrelid = 'auth.users'::regclass;

-- 显示成功消息
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ 触发器已启用！';
  RAISE NOTICE '========================================';
  RAISE NOTICE '现在可以测试 Google 登录了';
  RAISE NOTICE '新用户将自动创建 profile';
  RAISE NOTICE '========================================';
END $$;
