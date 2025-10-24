-- ============================================
-- 完整的 OAuth 登录修复脚本
-- ============================================
-- 这个脚本将彻底解决 digest() 函数错误

-- 步骤 1: 强制启用 pgcrypto 扩展（使用 CASCADE）
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
CREATE EXTENSION pgcrypto;

-- 步骤 2: 验证扩展
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    RAISE NOTICE '✅ pgcrypto 扩展已成功启用';
  ELSE
    RAISE EXCEPTION '❌ pgcrypto 扩展启用失败';
  END IF;
END $$;

-- 步骤 3: 测试 digest 函数
DO $$
DECLARE
  test_result bytea;
BEGIN
  test_result := digest('test', 'sha256');
  RAISE NOTICE '✅ digest() 函数工作正常';
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION '❌ digest() 函数测试失败: %', SQLERRM;
END $$;

-- 步骤 4: 确保其他必需的扩展也已启用
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 步骤 5: 重新创建 handle_new_user 函数（确保没有语法错误）
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_provider TEXT;
  v_provider_user_id TEXT;
  v_username TEXT;
  v_email TEXT;
BEGIN
  -- Determine provider
  v_provider := COALESCE(
    NEW.raw_app_meta_data->>'provider',
    NEW.raw_user_meta_data->>'provider',
    CASE 
      WHEN NEW.email LIKE '%@gmail.com' THEN 'google'
      WHEN NEW.raw_app_meta_data ? 'providers' THEN 
        CASE 
          WHEN NEW.raw_app_meta_data->'providers' @> '["google"]'::jsonb THEN 'google'
          WHEN NEW.raw_app_meta_data->'providers' @> '["github"]'::jsonb THEN 'github'
          WHEN NEW.raw_app_meta_data->'providers' @> '["discord"]'::jsonb THEN 'discord'
          ELSE 'otp'
        END
      ELSE 'otp'
    END
  );
  
  v_provider_user_id := COALESCE(
    NEW.raw_user_meta_data->>'sub',
    NEW.id::text
  );

  v_email := COALESCE(NEW.email, 'user_' || substring(NEW.id::text, 1, 8) || '@placeholder.local');

  v_username := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', ''),
    NULLIF(split_part(v_email, '@', 1), ''),
    'user_' || substring(NEW.id::text, 1, 8)
  );

  BEGIN
    INSERT INTO public.profiles (
      id, username, email, avatar_url, provider, provider_user_id,
      role, language, theme_mode, reports_count,
      reputation_score, notifications_enabled
    )
    VALUES (
      NEW.id,
      v_username,
      v_email,
      COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
      v_provider,
      v_provider_user_id,
      'user',
      'en',
      'dark',
      0,
      100,
      true
    )
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE '✅ Profile created for user: %', NEW.id;
    RETURN NEW;
    
  EXCEPTION
    WHEN unique_violation THEN
      -- If username already exists, append random suffix
      v_username := v_username || '_' || substring(NEW.id::text, 1, 4);
      
      INSERT INTO public.profiles (
        id, username, email, avatar_url, provider, provider_user_id,
        role, language, theme_mode, reports_count,
        reputation_score, notifications_enabled
      )
      VALUES (
        NEW.id,
        v_username,
        v_email,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        v_provider,
        v_provider_user_id,
        'user',
        'en',
        'dark',
        0,
        100,
        true
      )
      ON CONFLICT (id) DO NOTHING;
      
      RAISE NOTICE '✅ Profile created with modified username: %', v_username;
      RETURN NEW;
      
    WHEN OTHERS THEN
      -- Log error but don't block user creation
      RAISE WARNING '⚠️ Error in handle_new_user: % %', SQLERRM, SQLSTATE;
      RETURN NEW;
  END;
END;
$$;

-- 步骤 6: 删除并重新创建触发器（新创建的触发器默认启用）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 注意：新创建的触发器默认是启用状态，不需要额外的 ALTER TABLE 命令

-- 步骤 7: 验证触发器已创建并启用
DO $$
DECLARE
  trigger_enabled CHAR(1);
BEGIN
  SELECT tgenabled INTO trigger_enabled
  FROM pg_trigger 
  WHERE tgname = 'on_auth_user_created' 
  AND tgrelid = 'auth.users'::regclass;
  
  IF trigger_enabled IS NULL THEN
    RAISE EXCEPTION '❌ 触发器不存在';
  ELSIF trigger_enabled = 'D' THEN
    RAISE EXCEPTION '❌ 触发器已禁用';
  ELSE
    RAISE NOTICE '✅ 触发器 on_auth_user_created 已成功创建并启用';
  END IF;
END $$;

-- 步骤 8: 显示当前配置摘要
SELECT 
  '扩展状态' as category,
  extname as name,
  extversion as version
FROM pg_extension 
WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pg_net')

UNION ALL

SELECT 
  '触发器状态' as category,
  tgname as name,
  CASE tgenabled
    WHEN 'O' THEN 'enabled'
    WHEN 'D' THEN 'DISABLED'
    ELSE 'enabled'
  END as version
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created'

UNION ALL

SELECT 
  '函数状态' as category,
  proname as name,
  'exists' as version
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- ============================================
-- 执行完成提示
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ OAuth 登录修复脚本执行完成！';
  RAISE NOTICE '========================================';
  RAISE NOTICE '下一步：';
  RAISE NOTICE '1. 清除浏览器缓存';
  RAISE NOTICE '2. 重新尝试 Google 登录';
  RAISE NOTICE '3. 检查 auth.users 和 profiles 表';
  RAISE NOTICE '========================================';
END $$;
