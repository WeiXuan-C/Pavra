-- ============================================
-- 通知系统数据库触发器和定时任务
-- ============================================

-- 1. 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================
-- 2. 创建触发器函数：自动发送通知
-- ============================================

CREATE OR REPLACE FUNCTION trigger_send_notification()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
BEGIN
  -- 只有当状态为 'sent' 时才触发
  IF NEW.status = 'sent' THEN
    -- 获取 Edge Function URL
    edge_function_url := 'https://jgmbdrbcvhtmpfzqggzh.supabase.co/functions/v1/send-notification';
    service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbWJkcmJjdmh0bXBmenFnZ3poIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk4MzQ3NiwiZXhwIjoyMDc1NTU5NDc2fQ.7GD-zE8HgsSgY1GJEUJfFm1URRqS6PmyQxpqITwPs-s';
    
    -- 如果没有配置，使用默认值
    IF edge_function_url IS NULL OR edge_function_url = '' THEN
      edge_function_url := 'https://jgmbdrbcvhtmpfzqggzh.supabase.co/functions/v1/send-notification';
    END IF;
    
    IF service_role_key IS NULL OR service_role_key = '' THEN
      service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbWJkcmJjdmh0bXBmenFnZ3poIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk4MzQ3NiwiZXhwIjoyMDc1NTU5NDc2fQ.7GD-zE8HgsSgY1GJEUJfFm1URRqS6PmyQxpqITwPs-s';
    END IF;
    
    -- 使用 pg_net 异步调用 Edge Function（推荐方式）
    BEGIN
      -- 使用 net.http_post 进行异步调用
      PERFORM net.http_post(
        url := edge_function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_role_key
        ),
        body := jsonb_build_object('notificationId', NEW.id)
      );
      
      RAISE NOTICE 'Notification queued for sending: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
      -- 记录错误但不阻止事务
      RAISE WARNING 'Error calling Edge Function: %', SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. 创建触发器：在通知插入时触发
-- ============================================

DROP TRIGGER IF EXISTS on_notification_created ON notifications;

CREATE TRIGGER on_notification_created
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_send_notification();

-- ============================================
-- 4. 创建触发器：在通知更新时触发
-- ============================================

CREATE OR REPLACE FUNCTION trigger_send_notification_on_update()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
BEGIN
  -- 只有当状态从非 'sent' 变为 'sent' 时才触发
  IF OLD.status != 'sent' AND NEW.status = 'sent' THEN
    edge_function_url := 'https://jgmbdrbcvhtmpfzqggzh.supabase.co/functions/v1/send-notification';
    service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbWJkcmJjdmh0bXBmenFnZ3poIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk4MzQ3NiwiZXhwIjoyMDc1NTU5NDc2fQ.7GD-zE8HgsSgY1GJEUJfFm1URRqS6PmyQxpqITwPs-s';
    
    IF edge_function_url IS NULL OR edge_function_url = '' THEN
      edge_function_url := 'https://jgmbdrbcvhtmpfzqggzh.supabase.co/functions/v1/send-notification';
    END IF;
    
    IF service_role_key IS NULL OR service_role_key = '' THEN
      service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbWJkcmJjdmh0bXBmenFnZ3poIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk4MzQ3NiwiZXhwIjoyMDc1NTU5NDc2fQ.7GD-zE8HgsSgY1GJEUJfFm1URRqS6PmyQxpqITwPs-s';
    END IF;
    
    BEGIN
      -- 使用 net.http_post 进行异步调用
      PERFORM net.http_post(
        url := edge_function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_role_key
        ),
        body := jsonb_build_object('notificationId', NEW.id)
      );
      
      RAISE NOTICE 'Notification queued for sending: %', NEW.id;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error calling Edge Function: %', SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_notification_updated ON notifications;

CREATE TRIGGER on_notification_updated
  AFTER UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_send_notification_on_update();

-- ============================================
-- 5. 创建定时任务：处理调度通知
-- ============================================

SELECT cron.schedule(
  'process-scheduled-notifications',
  '* * * * *',
  $$
  UPDATE notifications
  SET 
    status = 'sent',
    sent_at = NOW(),
    updated_at = NOW()
  WHERE 
    status = 'scheduled'
    AND scheduled_at <= NOW()
    AND is_deleted = FALSE;
  $$
);
