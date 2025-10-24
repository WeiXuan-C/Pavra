-- ============================================
-- OneSignal 推送通知触发器
-- ============================================
-- 当 notifications 表插入新记录时，自动调用后端发送推送

CREATE OR REPLACE FUNCTION notify_via_backend()
RETURNS TRIGGER AS $$
DECLARE
  -- 生产环境 URL (Railway)
  backend_url TEXT := 'https://pavra-production.up.railway.app/notificationEndpoint/handleNotificationCreated';
  
  -- Service Secret - 必须与后端配置匹配
  -- 生产环境使用环境变量 SERVICE_SECRET
  service_secret TEXT := 'x6J4HmEUvObeJUxgvgr5Tmhp6JkP3voc';
BEGIN
  -- 只处理 status = 'sent' 的通知
  IF NEW.status = 'sent' THEN
    -- 异步调用后端 API
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
$$ LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_send_push_notification ON public.notifications;
CREATE TRIGGER trigger_send_push_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION notify_via_backend();

-- ============================================
-- 注意事项
-- ============================================
-- 1. 需要启用 Supabase pg_net 扩展：
--    CREATE EXTENSION IF NOT EXISTS pg_net;
--
-- 2. 确保后端 URL 正确
-- 3. 确保 SERVICE_SECRET 匹配
-- 4. 触发器是异步的，不会阻塞插入操作
