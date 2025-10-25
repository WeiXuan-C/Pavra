-- =====================================
-- FUNCTION: handle_new_user
-- =====================================
-- 自动为新用户创建 profile 记录
-- 触发器：当 auth.users 插入新记录时自动执行

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
      
      RETURN NEW;
      
    WHEN OTHERS THEN
      -- Log error but don't block user creation
      RAISE NOTICE 'Error in handle_new_user: % %', SQLERRM, SQLSTATE;
      RETURN NEW;
  END;
END;
$$;

-- 绑定触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON FUNCTION public.handle_new_user IS '自动为新用户创建 profile 记录';
