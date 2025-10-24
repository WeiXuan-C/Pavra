-- 列出所有 public schema 中的函数
SELECT 
  proname as function_name,
  CASE 
    WHEN proname = 'handle_new_oauth_user' THEN '🔵 OAuth 登录处理'
    WHEN proname = 'handle_new_user' THEN '🔵 通用用户创建'
    WHEN proname = 'handle_confirmed_user' THEN '🔵 邮箱确认处理'
    ELSE ''
  END as description
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname LIKE 'handle_%'
ORDER BY proname;
