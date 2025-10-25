-- =====================================
-- 通知系统核心函数
-- =====================================
-- 包含通知系统的核心业务逻辑函数和触发器

-- =====================================
-- FUNCTION: set_updated_at
-- =====================================
-- 通用函数：自动更新记录的 updated_at 时间戳

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_updated_at IS '通用触发器函数：自动更新 updated_at 字段为当前时间';

-- =====================================
-- FUNCTION: create_user_notifications
-- =====================================
-- 根据通知的目标类型，自动为相应用户创建 user_notifications 记录
-- 
-- 支持的目标类型：
--   - single/custom: 使用 target_user_ids 数组
--   - role: 根据 target_roles 查询用户
--   - all: 所有注册用户

CREATE OR REPLACE FUNCTION public.create_user_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_user_id UUID;
  user_ids UUID[];
BEGIN
  -- 根据 target_type 确定目标用户列表
  CASE NEW.target_type
    WHEN 'single', 'custom' THEN
      -- 直接使用指定的用户 ID 列表
      user_ids := NEW.target_user_ids;
      
    WHEN 'role' THEN
      -- 查询指定角色的所有用户
      SELECT ARRAY_AGG(id) INTO user_ids
      FROM auth.users u
      JOIN public.profiles p ON u.id = p.id
      WHERE p.role = ANY(NEW.target_roles);
      
    WHEN 'all' THEN
      -- 获取所有用户
      SELECT ARRAY_AGG(id) INTO user_ids
      FROM auth.users;
      
    ELSE
      -- 未知类型，不创建记录
      user_ids := ARRAY[]::UUID[];
  END CASE;
  
  -- 批量创建 user_notifications 记录
  IF user_ids IS NOT NULL AND array_length(user_ids, 1) > 0 THEN
    FOREACH target_user_id IN ARRAY user_ids
    LOOP
      INSERT INTO public.user_notifications (notification_id, user_id)
      VALUES (NEW.id, target_user_id)
      ON CONFLICT (notification_id, user_id) DO NOTHING;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.create_user_notifications IS '根据通知目标类型自动创建 user_notifications 记录';

-- =====================================
-- TRIGGERS: updated_at 自动更新
-- =====================================

-- Trigger: profiles 表
DROP TRIGGER IF EXISTS trg_set_updated_at_profiles ON public.profiles;
CREATE TRIGGER trg_set_updated_at_profiles
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger: notifications 表
DROP TRIGGER IF EXISTS trg_set_updated_at_notifications ON public.notifications;
CREATE TRIGGER trg_set_updated_at_notifications
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger: user_notifications 表
DROP TRIGGER IF EXISTS trg_set_updated_at_user_notifications ON public.user_notifications;
CREATE TRIGGER trg_set_updated_at_user_notifications
  BEFORE UPDATE ON public.user_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =====================================
-- TRIGGER: 自动创建用户通知记录
-- =====================================
-- 当新通知插入且状态为 'sent' 时，自动为目标用户创建记录

DROP TRIGGER IF EXISTS trg_create_user_notifications ON public.notifications;
CREATE TRIGGER trg_create_user_notifications
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  WHEN (NEW.status = 'sent' AND NEW.is_deleted = FALSE)
  EXECUTE FUNCTION public.create_user_notifications();
