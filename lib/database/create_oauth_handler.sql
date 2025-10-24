-- ============================================
-- 创建 OAuth 用户处理函数
-- ============================================
-- 这个函数专门处理 OAuth 登录（Google, GitHub, Discord）

CREATE OR REPLACE FUNCTION public.handle_new_oauth_user()
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
  -- 只处理 OAuth 提供商
  v_provider := COALESCE(
    NEW.raw_app_meta_data->>'provider',
    NEW.raw_user_meta_data->>'provider'
  );
  
  -- 如果不是 OAuth 登录，跳过
  IF v_provider NOT IN ('google', 'github', 'discord', 'facebook') THEN
    RETURN NEW;
  END IF;
  
  v_provider_user_id := COALESCE(
    NEW.raw_user_meta_data->>'sub',
    NEW.id::text
  );

  v_email := COALESCE(
    NEW.email, 
    'user_' || substring(NEW.id::text, 1, 8) || '@placeholder.local'
  );

  v_username := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', ''),
    NULLIF(NEW.raw_user_meta_data->>'user_name', ''),
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

    RAISE LOG 'OAuth profile created for user: % (provider: %)', NEW.id, v_provider;
    RETURN NEW;
    
  EXCEPTION
    WHEN unique_violation THEN
      -- 如果用户名冲突，添加后缀
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
      
      RAISE LOG 'OAuth profile created with modified username: %', v_username;
      RETURN NEW;
      
    WHEN OTHERS THEN
      RAISE WARNING 'Error in handle_new_oauth_user: % %', SQLERRM, SQLSTATE;
      RETURN NEW;
  END;
END;
$$;

-- 验证函数已创建
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_oauth_user')
    THEN '✅ handle_new_oauth_user 函数已创建'
    ELSE '❌ 函数创建失败'
  END as status;

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ OAuth 处理函数已创建！';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Supabase 会自动调用这个函数';
  RAISE NOTICE '当用户通过 Google/GitHub/Discord 登录时';
  RAISE NOTICE '========================================';
END $$;
