# OneSignal 通知图标设置指南

## 问题
OneSignal 推送通知显示黄色小铃铛而不是应用 logo。

## 解决方案

### 1. 准备通知图标

#### Android 小图标要求：
- **颜色**：白色前景 + 透明背景（PNG 格式）
- **尺寸**：
  - `drawable-mdpi`: 24x24px
  - `drawable-hdpi`: 36x36px
  - `drawable-xhdpi`: 48x48px
  - `drawable-xxhdpi`: 72x72px
  - `drawable-xxxhdpi`: 96x96px

#### 在线工具生成图标：
- https://romannurik.github.io/AndroidAssetStudio/icons-notification.html
- 上传你的 logo，选择白色，下载所有尺寸

### 2. 添加图标到 Android 项目

将生成的图标文件放到对应文件夹：

```
android/app/src/main/res/
├── drawable-mdpi/
│   └── ic_stat_onesignal_default.png (24x24)
├── drawable-hdpi/
│   └── ic_stat_onesignal_default.png (36x36)
├── drawable-xhdpi/
│   └── ic_stat_onesignal_default.png (48x48)
├── drawable-xxhdpi/
│   └── ic_stat_onesignal_default.png (72x72)
└── drawable-xxxhdpi/
    └── ic_stat_onesignal_default.png (96x96)
```

**重要**：文件名必须是 `ic_stat_onesignal_default.png`

### 3. 配置 AndroidManifest.xml

打开 `android/app/src/main/AndroidManifest.xml`，在 `<application>` 标签内添加：

```xml
<application>
    <!-- 其他配置 -->
    
    <!-- OneSignal 通知图标配置 -->
    <meta-data
        android:name="com.onesignal.NotificationOpened.DEFAULT"
        android:value="DISABLE" />
    
    <!-- 小图标（状态栏） -->
    <meta-data
        android:name="com.onesignal.NotificationIcon"
        android:resource="@drawable/ic_stat_onesignal_default" />
    
    <!-- 大图标（通知展开时） - 可选 -->
    <meta-data
        android:name="com.onesignal.LargeIcon"
        android:resource="@mipmap/ic_launcher" />
    
    <!-- 通知强调色（Android 5.0+） -->
    <meta-data
        android:name="com.onesignal.NotificationAccentColor.DEFAULT"
        android:value="FF0000FF" /> <!-- 蓝色，改成你的品牌色 -->
</application>
```

### 4. 通过代码设置（可选）

在 Flutter 代码中也可以动态设置：

```dart
// lib/core/services/notification_service.dart

Future<void> initialize() async {
  if (_isInitialized) return;

  final appId = dotenv.env['ONESIGNAL_APP_ID'];
  if (appId == null || appId.isEmpty) {
    throw Exception('ONESIGNAL_APP_ID not found in .env');
  }

  OneSignal.initialize(appId);
  
  // 设置通知图标（Android）
  // 注意：这个方法在新版本可能已废弃，优先使用 AndroidManifest 配置
  
  OneSignal.Notifications.requestPermission(true);
  
  _isInitialized = true;
}
```

### 5. 通过 Edge Function 设置（推荐）

在发送通知时指定图标：

```typescript
// supabase/functions/send-notification/index.ts

const oneSignalPayload: any = {
  app_id: Deno.env.get('ONESIGNAL_APP_ID'),
  headings: { en: notification.title },
  contents: { en: notification.message },
  
  // Android 图标配置
  small_icon: 'ic_stat_onesignal_default', // 小图标
  large_icon: 'ic_launcher', // 大图标（可选）
  android_accent_color: 'FF0000FF', // 强调色
  
  // iOS 图标配置
  ios_badgeType: 'Increase',
  ios_badgeCount: 1,
  
  data: {
    notification_id: notificationId,
    type: notification.type,
    ...(notification.data || {}),
  },
};
```

### 6. 重新构建应用

```bash
# 清理构建缓存
flutter clean

# 重新构建
flutter build apk
# 或
flutter run
```

### 7. 测试

发送测试通知，检查是否显示正确的图标。

## 常见问题

### Q: 图标还是黄色铃铛？
A: 
1. 确认文件名是 `ic_stat_onesignal_default.png`
2. 确认图标是白色前景 + 透明背景
3. 重新构建应用（`flutter clean` + `flutter run`）
4. 卸载旧版本应用，重新安装

### Q: 图标显示为白色方块？
A: 图标背景不是透明的，重新生成图标

### Q: iOS 上如何设置？
A: iOS 使用应用图标作为通知图标，无需额外配置

### Q: 如何更改通知颜色？
A: 修改 `android:value="FF0000FF"` 中的颜色值（ARGB 格式）

## 推荐配置

```xml
<!-- 品牌色示例 -->
<!-- 蓝色 -->
<meta-data android:name="com.onesignal.NotificationAccentColor.DEFAULT" android:value="FF2196F3" />

<!-- 绿色 -->
<meta-data android:name="com.onesignal.NotificationAccentColor.DEFAULT" android:value="FF4CAF50" />

<!-- 红色 -->
<meta-data android:name="com.onesignal.NotificationAccentColor.DEFAULT" android:value="FFF44336" />

<!-- 紫色 -->
<meta-data android:name="com.onesignal.NotificationAccentColor.DEFAULT" android:value="FF9C27B0" />
```
