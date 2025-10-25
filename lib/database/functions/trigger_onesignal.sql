-- =====================================
-- ONESIGNAL 推送通知集成
-- =====================================
-- 当 notifications 表插入新记录时，通过后端 API 发送 OneSignal 推送
-- 
-- 依赖：
--   - pg_net 扩展 (CREATE EXTENSION IF NOT EXISTS pg_net)
--   - 后端服务必须运行并可访问
--   - SERVICE_SECRET 必须与后端配置匹配

-- =====================================
-- FUNCTION: notify_via_backend
-- =====================================
-- 异步调用后端 API 发送 OneSignal 推送通知

CREATE OR REPLACE FUNCTION public.notify_via_backend()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  backend_url TEXT := 'https://pavra-production.up.railway.app/notificationEndpoint/handleNotificationCreated';
  service_secret TEXT := 'x6J4HmEUvObeJUxgvgr5Tmhp6JkP3voc';
BEGIN
  -- 只处理 status = 'sent' 且未删除的通知
  IF NEW.status = 'sent' AND NEW.is_deleted = FALSE THEN
    -- 异步调用后端 API (不阻塞数据库操作)
    PERFORM net.http_post(
      url := backend_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Service-Secret', service_secret
      ),
      body := jsonb_build_object(
        'notificationId', NEW.id::TEXT
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_via_backend IS '异步调用后端 API 发送 OneSignal 推送通知';

-- =====================================
-- TRIGGER: trigger_send_push_notification
-- =====================================
-- 在 notifications 插入后触发推送

DROP TRIGGER IF EXISTS trigger_send_push_notification ON public.notifications;
CREATE TRIGGER trigger_send_push_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  WHEN (NEW.status = 'sent' AND NEW.is_deleted = FALSE)
  EXECUTE FUNCTION public.notify_via_backend();

-- =====================================
-- 配置说明
-- =====================================
-- 1. 后端 URL: 修改 backend_url 变量指向正确的服务地址
-- 2. Service Secret: 确保 service_secret 与后端环境变量 SERVICE_SECRET 一致
-- 3. 异步执行: 使用 pg_net 扩展，不会阻塞数据库插入操作
-- 4. 错误处理: 推送失败不影响通知记录的创建
