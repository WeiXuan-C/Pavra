# Database Migrations

This directory contains database migration scripts for the Pavra application.

## Migration Files

### 20251125000001_add_onesignal_columns.sql
Adds OneSignal integration columns to the notifications table:
- `onesignal_notification_id` - OneSignal notification ID for tracking
- `sound` - Custom notification sound file name
- `category` - Android notification channel/category
- `priority` - Notification priority (1-10)
- `error_message` - Error details if send fails
- `recipients_count` - Total intended recipients
- `successful_deliveries` - Successful delivery count
- `failed_deliveries` - Failed delivery count

**Requirements:** 2.1, 10.1, 10.5

### 20251125000001_add_onesignal_columns_rollback.sql
Rollback script to remove OneSignal columns if needed.

### 20251125000002_add_system_notification_triggers.sql
Adds automatic notification triggers for system events:
- Report creation notifications for nearby users
- Report verification notifications for report creators
- Reputation change notifications for affected users
- Authority request decision notifications for requesters

**Requirements:** 11.1, 11.2, 11.3, 11.4

### 20251125000002_add_system_notification_triggers_rollback.sql
Rollback script to remove system notification triggers and functions.

## Running Migrations

### Using Supabase CLI

If you have Supabase CLI installed and configured:

```bash
# Apply migration
supabase db push

# Or apply specific migration
supabase migration up
```

### Manual Application

Connect to your Supabase database and run:

```bash
psql -h <your-db-host> -U postgres -d postgres -f supabase/migrations/20251125000001_add_onesignal_columns.sql
```

### Testing on Development Database

1. **Backup your database first:**
   ```sql
   -- Create a backup of the notifications table
   CREATE TABLE notifications_backup AS SELECT * FROM public.notifications;
   ```

2. **Apply the migration:**
   ```bash
   psql -h <dev-db-host> -U postgres -d postgres -f supabase/migrations/20251125000001_add_onesignal_columns.sql
   ```

3. **Verify the changes:**
   ```sql
   -- Check that new columns exist
   SELECT column_name, data_type, column_default
   FROM information_schema.columns
   WHERE table_name = 'notifications'
   AND column_name IN (
     'onesignal_notification_id',
     'sound',
     'category',
     'priority',
     'error_message',
     'recipients_count',
     'successful_deliveries',
     'failed_deliveries'
   );
   
   -- Verify indexes were created
   SELECT indexname, indexdef
   FROM pg_indexes
   WHERE tablename = 'notifications'
   AND indexname IN ('idx_notifications_onesignal_id', 'idx_notifications_status_created');
   ```

4. **Test with sample data:**
   ```sql
   -- Insert a test notification with OneSignal fields
   INSERT INTO public.notifications (
     title,
     message,
     type,
     status,
     onesignal_notification_id,
     sound,
     category,
     priority,
     recipients_count
   ) VALUES (
     'Test Notification',
     'Testing OneSignal integration',
     'info',
     'sent',
     'test-onesignal-id-123',
     'alert.wav',
     'alert',
     8,
     5
   );
   
   -- Verify the data was inserted correctly
   SELECT * FROM public.notifications WHERE onesignal_notification_id = 'test-onesignal-id-123';
   
   -- Clean up test data
   DELETE FROM public.notifications WHERE onesignal_notification_id = 'test-onesignal-id-123';
   ```

### Rollback

If you need to rollback the migration:

```bash
psql -h <your-db-host> -U postgres -d postgres -f supabase/migrations/20251125000001_add_onesignal_columns_rollback.sql
```

## Migration Naming Convention

Migrations follow the pattern: `YYYYMMDDHHMMSS_description.sql`

- Timestamp ensures chronological ordering
- Description should be concise and descriptive
- Rollback scripts use the same timestamp with `_rollback` suffix
