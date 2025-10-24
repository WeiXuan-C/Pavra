-- ============================================
-- 替代方案：重新创建触发器（这会自动启用）
-- ============================================

-- 步骤 1: 完全删除旧触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 步骤 2: 重新创建触发器（新创建的触发器默认是启用的）
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 步骤 3: 验证触发器状态
SELECT 
  tgname as trigger_name,
  tgenabled as enabled_code,
  CASE tgenabled
    WHEN 'O' THEN '✅ 已启用'
    WHEN 'D' THEN '❌ 已禁用'
    ELSE '✅ 已启用'
  END as status,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgname = 'on_auth_user_created'
  AND tgrelid = 'auth.users'::regclass;

-- 步骤 4: 显示成功消息
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ 触发器已重新创建！';
  RAISE NOTICE '新创建的触发器默认是启用状态';
  RAISE NOTICE '========================================';
  RAISE NOTICE '现在可以测试 Google 登录了';
  RAISE NOTICE '========================================';
END $$;
