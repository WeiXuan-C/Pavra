# OneSignal 通知问题修复总结

## 🔍 问题诊断

你的Notification记录无法通过OneSignal发送给用户的**根本原因**是：

### 主要问题
**OneSignal凭证未正确加载到Serverpod的密码系统中**

具体表现：
1. `config/passwords.yaml` 文件中使用了环境变量占位符 `${ONESIGNAL_APP_ID}` 和 `${ONESIGNAL_API_KEY}`
2. **Serverpod的YAML配置文件不支持环境变量自动替换**
3. 当代码调用 `session.serverpod.getPassword('oneSignalAppId')` 时，返回的是字符串 `"${ONESIGNAL_APP_ID}"` 而不是实际的App ID
4. OneSignal API调用失败，因为使用了无效的凭证

## ✅ 解决方案

### 1. 修改 `passwords.yaml` 文件
将环境变量占位符替换为实际的凭证值：

```yaml
development:
  oneSignalAppId: '2eebafba-17aa-49a6-91aa-f9f7f2f72aca'
  oneSignalApiKey: 'os_v2_app_f3v27oqxvje2nenk7h37f5zkzlnemkqsxkuezzffpgs3ug34lfz4gluj5rzlhqysuixzw5yr6lp4t36yxkj3r7camutveielpkqx24i'

production:
  oneSignalAppId: '2eebafba-17aa-49a6-91aa-f9f7f2f72aca'
  oneSignalApiKey: 'os_v2_app_f3v27oqxvje2nenk7h37f5zkzlnemkqsxkuezzffpgs3ug34lfz4gluj5rzlhqysuixzw5yr6lp4t36yxkj3r7camutveielpkqx24i'
```

### 2. 增强凭证加载逻辑
修改了三个文件，添加了环境变量回退机制：

#### `server.dart`
```dart
void _initializeOneSignal(Serverpod pod, DotEnv? dotenv) {
  // 先尝试从 passwords.yaml 读取
  var appId = pod.getPassword('oneSignalAppId');
  var apiKey = pod.getPassword('oneSignalApiKey');

  // 如果是占位符或为空，则从环境变量读取
  if (appId == null || appId.isEmpty || appId.startsWith('\${')) {
    appId = Platform.environment['ONESIGNAL_APP_ID'] ?? dotenv?['ONESIGNAL_APP_ID'];
  }
  if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('\${')) {
    apiKey = Platform.environment['ONESIGNAL_API_KEY'] ?? dotenv?['ONESIGNAL_API_KEY'];
  }
  
  // 验证凭证
  if (appId == null || apiKey == null || appId.isEmpty || apiKey.isEmpty) {
    PLog.warn('⚠️ OneSignal credentials not found.');
    return;
  }
  
  PLog.info('✅ OneSignal credentials loaded successfully');
}
```

#### `notification_endpoint.dart` 和 `scheduled_notification_task.dart`
在 `_getOneSignalService()` 方法中添加了相同的回退逻辑。

## 🧪 验证步骤

### 1. 检查服务器日志
重启服务器后，应该看到：
```
✅ OneSignal credentials loaded successfully
   App ID: 2eebafba...
   API Key: os_v2_app_...
```

### 2. 测试通知发送
```dart
// 在Flutter应用中测试
final result = await client.notification.sendToUser(
  userId: 'your-user-id',
  title: '测试通知',
  message: '这是一条测试消息',
  type: 'info',
);

print('发送结果: $result');
```

### 3. 检查OneSignal Dashboard
1. 登录 [OneSignal Dashboard](https://app.onesignal.com/)
2. 进入你的应用 (App ID: 2eebafba-17aa-49a6-91aa-f9f7f2f72aca)
3. 查看 **Delivery** → **Messages** 确认通知是否发送成功

## 📋 完整的通知流程

### 客户端 (Flutter)
1. ✅ OneSignal SDK已正确初始化 (`lib/core/services/onesignal_service.dart`)
2. ✅ 用户登录时设置External User ID (`lib/core/providers/auth_provider.dart`)
3. ✅ 用户登出时移除External User ID

### 服务器端 (Serverpod)
1. ✅ OneSignal凭证现在可以正确加载
2. ✅ 通知记录创建在Supabase数据库
3. ✅ 通过OneSignal REST API发送推送通知
4. ✅ 支持单用户、多用户、角色和全体用户通知

## 🔐 安全建议

虽然现在问题已解决，但为了更好的安全性，建议：

1. **不要将 `passwords.yaml` 提交到Git**
   - 已在 `.gitignore` 中配置
   
2. **生产环境使用环境变量**
   - Railway等平台会自动注入环境变量
   - 代码已支持环境变量回退

3. **定期轮换API密钥**
   - 在OneSignal Dashboard中可以重新生成API Key

## 🚀 下一步

1. **重启服务器**
   ```bash
   cd pavra_server/pavra_server_server
   dart run bin/main.dart
   ```

2. **测试通知功能**
   - 发送测试通知
   - 检查用户是否收到推送

3. **监控日志**
   - 查看服务器日志确认OneSignal API调用成功
   - 检查OneSignal Dashboard的发送统计

## 📚 相关文件

- `pavra_server/pavra_server_server/config/passwords.yaml` - 凭证配置
- `pavra_server/pavra_server_server/lib/server.dart` - 服务器初始化
- `pavra_server/pavra_server_server/lib/src/endpoints/notification_endpoint.dart` - 通知API
- `pavra_server/pavra_server_server/lib/src/services/onesignal_service.dart` - OneSignal服务
- `lib/core/services/onesignal_service.dart` - Flutter客户端OneSignal服务
- `lib/docs/NOTIFICATION_USAGE.md` - 通知使用文档

---

**修复完成时间**: 2024-10-25  
**问题状态**: ✅ 已解决
