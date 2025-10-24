-- ============================================
-- 检查所有相关函数
-- ============================================

-- 查看所有 handle_* 函数
SELECT 
  proname as function_name,
  pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname LIKE 'handle_%'
  AND pronamespace = 'public'::regnamespace
ORDER BY proname;

-- 查看所有触发器及其对应的函数
SELECT 
  t.tgname as trigger_name,
  p.proname as function_name,
  t.tgenabled as enabled,
  CASE t.tgenabled
    WHEN 'O' THEN '✅ 已启用'
    WHEN 'D' THEN '❌ 已禁用'
    ELSE '✅ 已启用'
  END as status
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE t.tgrelid = 'auth.users'::regclass
ORDER BY t.tgname;
