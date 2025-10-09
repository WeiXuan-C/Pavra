CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp AS
$$
DECLARE
  v_provider TEXT;
  v_provider_user_id TEXT;
  v_username TEXT;
  v_email TEXT;
  v_recovery_code TEXT;
  v_device_token TEXT;
BEGIN
  -- Provider
  v_provider := COALESCE(NEW.raw_user_meta_data->>'provider', 'email');
  v_provider_user_id := NEW.raw_user_meta_data->>'provider_user_id';

  -- Email fallback
  v_email := COALESCE(
    NULLIF(NEW.email, ''),
    CASE 
      WHEN v_provider_user_id IS NOT NULL THEN v_provider_user_id || '@' || v_provider || '.local'
      ELSE 'unknown_' || substring(NEW.id::text, 1, 8) || '@placeholder.local'
    END
  );

  -- Username fallback
  v_username := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'username', ''),
    NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', ''),
    NULLIF(split_part(v_email, '@', 1), ''),
    CASE 
      WHEN v_provider_user_id IS NOT NULL THEN v_provider || '_' || substring(v_provider_user_id, 1, 6)
      ELSE 'user_' || substring(NEW.id::text, 1, 8)
    END
  );

  -- Recovery code
  v_recovery_code := encode(
    digest(EXTRACT(EPOCH FROM NOW())::text || NEW.id::text, 'sha256'),
    'hex'
  );

  -- Device token
  v_device_token := NEW.raw_user_meta_data->>'device_token';

  -- Insert into profile
  INSERT INTO public.profiles (
    id, username, email, avatar_url, provider, provider_user_id,
    recovery_code, role, language, theme_mode, reports_count,
    reputation_score, notifications_enabled, device_token
  )
  VALUES (
    NEW.id,
    v_username,
    v_email,
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    v_provider,
    v_provider_user_id,
    v_recovery_code,
    'user',
    'en',
    'dark',
    0,
    100,
    true,
    v_device_token
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- =====================================================
-- ATTACH TRIGGER TO auth.users
-- =====================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
