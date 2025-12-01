// Supabase Edge Function: send-notification
// 用于发送 OneSignal 推送通知

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { notificationId } = await req.json();

    if (!notificationId) {
      throw new Error('notificationId is required');
    }

    // 初始化 Supabase 客户端
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // 1. 从数据库获取通知详情
    console.log('Fetching notification:', notificationId);
    
    const { data: notification, error: fetchError } = await supabaseClient
      .from('notifications')
      .select('*')
      .eq('id', notificationId)
      .single();

    if (fetchError) {
      console.error('Database error:', fetchError);
      throw new Error(`Database error: ${fetchError.message} (${fetchError.code})`);
    }

    if (!notification) {
      console.error('Notification not found:', notificationId);
      throw new Error(`Notification not found: ${notificationId}`);
    }

    console.log('Notification found:', notification.title, 'status:', notification.status);

    // 只处理 status='sent' 的通知
    if (notification.status !== 'sent') {
      return new Response(
        JSON.stringify({
          success: true,
          message: `Notification status is ${notification.status}, skipping send`,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. 根据 target_type 解析目标用户
    let targetUserIds: string[] = [];
    let useSegments = false;

    switch (notification.target_type) {
      case 'single':
      case 'custom':
        targetUserIds = notification.target_user_ids || [];
        break;

      case 'role':
        // 查询特定角色的用户
        const { data: users, error: usersError } = await supabaseClient
          .from('profiles')
          .select('id')
          .in('role', notification.target_roles || []);

        if (usersError) {
          throw new Error(`Failed to fetch users by role: ${usersError.message}`);
        }

        targetUserIds = users?.map((u: any) => u.id) || [];
        break;

      case 'all':
        // 广播到所有用户
        useSegments = true;
        break;

      default:
        throw new Error(`Unknown target_type: ${notification.target_type}`);
    }

    // 3. 构建 OneSignal 请求体
    const oneSignalPayload: any = {
      app_id: Deno.env.get('ONESIGNAL_APP_ID'),
      headings: { en: notification.title },
      contents: { en: notification.message },
      
      // Android 图标配置
      small_icon: 'ic_stat_onesignal_default',
      large_icon: 'ic_launcher',
      android_accent_color: 'FF2196F3', // 蓝色，可以改成你的品牌色
      
      // iOS 配置
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      
      data: {
        notification_id: notificationId,
        type: notification.type,
        ...(notification.data || {}),
      },
    };

    // 设置目标用户
    if (useSegments) {
      oneSignalPayload.included_segments = ['All'];
    } else {
      if (targetUserIds.length === 0) {
        throw new Error('No target users found');
      }
      oneSignalPayload.include_aliases = {
        external_id: targetUserIds,
      };
      oneSignalPayload.target_channel = 'push';
    }

    // 添加可选字段
    if (notification.sound) {
      oneSignalPayload.android_sound = notification.sound;
      oneSignalPayload.ios_sound = `${notification.sound}.wav`;
    }

    if (notification.category) {
      oneSignalPayload.android_channel_id = notification.category;
    }

    if (notification.priority) {
      oneSignalPayload.priority = notification.priority;
    }

    // 4. 调用 OneSignal API
    // 根据 OneSignal 文档，Create Notification API 使用 REST API Key
    // 认证方式: Authorization: Basic <REST_API_KEY>
    const restApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');
    
    if (!restApiKey) {
      throw new Error('ONESIGNAL_REST_API_KEY not configured');
    }
    
    console.log('Calling OneSignal API for notification:', notification.title);
    console.log('Using REST API Key:', restApiKey.substring(0, 15) + '...');
    console.log('Payload:', JSON.stringify(oneSignalPayload, null, 2));
    
    const oneSignalResponse = await fetch('https://api.onesignal.com/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${restApiKey}`,
      },
      body: JSON.stringify(oneSignalPayload),
    });

    if (!oneSignalResponse.ok) {
      const errorText = await oneSignalResponse.text();
      throw new Error(`OneSignal API error: ${oneSignalResponse.status} - ${errorText}`);
    }

    const oneSignalResult = await oneSignalResponse.json();

    // 5. 更新通知状态
    const { error: updateError } = await supabaseClient
      .from('notifications')
      .update({
        onesignal_notification_id: oneSignalResult.id,
        recipients_count: oneSignalResult.recipients || 0,
        successful_deliveries: oneSignalResult.recipients || 0,
        sent_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', notificationId);

    if (updateError) {
      console.error('Failed to update notification:', updateError);
      // 不抛出错误，因为通知已经发送成功
    }

    return new Response(
      JSON.stringify({
        success: true,
        notification_id: notificationId,
        onesignal_id: oneSignalResult.id,
        recipients: oneSignalResult.recipients,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in send-notification:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
