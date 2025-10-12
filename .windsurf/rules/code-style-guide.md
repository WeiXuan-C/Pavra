---
trigger: always_on
---

# Pavra Project Development Rules

本文档详细说明 Pavra 项目的开发规范、最佳实践和功能要求。所有团队成员必须遵循这些规则，以确保应用的一致性、可用性和可维护性。

---

## 📱 1. ASO Optimization (应用商店优化)

### 基本要求

- 实施 **完整且标准的 App Store Optimization (ASO)** 策略
- 确保 **应用名称、简短描述、详细描述** 包含相关的高价值关键词
- 使用 **高质量的应用图标、截图和预览视频** 提高视觉吸引力和转化率
- 在商店列表和应用内视觉中保持 **清晰一致的品牌标识**
- 鼓励 **用户积极评价和定期更新** 以提升商店排名
- 优化 **应用类别和标签** 以触达正确的目标受众
- 为每种支持的语言 **本地化商店列表文本和图片**

---

## 🎨 2. Theme Support (主题支持)

### 要求

- Pavra 必须支持 **Light Mode（亮色模式）** 和 **Dark Mode（暗色模式）**
- 用户可以轻松切换主题模式
- 所有 UI 组件必须正确适配两种主题
- 主题切换应该是平滑的，无闪烁

### 颜色使用规范

- ✅ 使用 `Theme.of(context).colorScheme.primary`
- ✅ 使用 `Theme.of(context).textTheme.bodyLarge`
- ❌ 不要硬编码颜色值（如 `Color(0xFF000000)`）
- ❌ 不要使用固定的黑白颜色

---

## 🎯 3. UI/UX Standards (界面标准)

### 设计原则

- 遵循 **Material Design 3** 或 **Cupertino Design** 规范
- 确保 **一致的间距、字体大小、颜色和按钮样式**
- 所有交互元素必须有 **清晰的视觉反馈**（hover、点击、聚焦）
- 保持 **响应式设计**，适配手机、平板和桌面屏幕

### 间距规范

```dart
// 使用统一的间距常量
const double paddingSmall = 8.0;
const double paddingMedium = 16.0;
const double paddingLarge = 24.0;
const double paddingXLarge = 32.0;
```

### 按钮规范

- **主要操作**: 使用 `ElevatedButton`（如"提交"、"保存"）
- **次要操作**: 使用 `OutlinedButton`（如"取消"）
- **文本操作**: 使用 `TextButton`（如"跳过"、"稍后"）
- **危险操作**: 使用红色主题（如"删除"、"退出登录"）

### 加载状态

- 使用 **骨架屏（Skeleton）** 代替简单的加载圈
- 长时间操作显示进度指示器
- 提供友好的错误提示信息

### 无障碍支持

- 所有图片必须有 `semanticLabel`
- 按钮必须有合适的触摸区域（最小 48x48 dp）
- 确保颜色对比度符合 WCAG 标准

---

## 💻 4. Code Quality (代码质量)

### 注释规范

所有函数、方法和类必须有 **英文注释** 说明其用途。

```dart
/// Get user profile from database
/// 
/// Returns [UserProfile] if found, null otherwise.
/// Throws [Exception] if database operation fails.
Future<UserProfile?> getUserProfile(String userId) async {
  // Implementation...
}
```

### 注释要求

- 使用 `///` 进行文档注释（可生成文档）
- 使用 `//` 进行行内注释
- 说明函数的 **作用、参数、返回值、异常**
- 复杂逻辑必须有注释说明

### 避免的注释

```dart
❌ int age = 25; // age variable
❌ // 这是一个函数（不要用中文注释代码）
✅ // Calculate user's age based on birth date
```

---

## 🌍 5. Multi-Language Support (多语言支持)

### 要求

- Pavra 必须支持 **English（英语）** 和 **中文（简体中文）** 翻译
- 所有文本内容、标签和消息必须可翻译
- 确保切换语言不会破坏布局或 UI

### ARB 文件格式

```json
{
  "appTitle": "Pavra",
  "@appTitle": {
    "description": "The application title"
  },
  "login": "Login",
  "welcome": "Welcome, {name}!",
  "@welcome": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}

---

## 🏗️ 6. Architecture Rules (架构规范)

### 三层架构

遵循项目的三层架构设计（详见 `ARCHITECTURE.md`）：

```
Presentation Layer (presentation/)
    ↓
Repository Layer (data/repositories/)
    ↓
API Layer (core/api/)
    ↓
Service Layer (core/supabase/)
```

### 依赖规则

- ✅ `presentation/` 可以依赖 `data/` 和 `core/`
- ✅ `data/` 可以依赖 `core/`
- ❌ `core/` 不应依赖 `data/` 或 `presentation/`
- ❌ `data/` 不应依赖 `presentation/`

### 数据流规则

```dart
// ✅ 正确的数据流
UI (Screen) → Repository → API → DatabaseService

// ❌ 错误的数据流
UI (Screen) → DatabaseService (跳过 Repository 和 API)
```

### Provider 使用规范

#### 全局 Provider (data/providers/)

```dart
// 长生命周期，App 级别
class UserProvider extends ChangeNotifier {
  final _userRepository = UserRepository();
  UserProfile? _currentUser;
  
  // 管理全局用户状态
}
```

#### 局部 Provider (presentation/*/providers/)

```dart
// 短生命周期，页面级别
class CameraDetectionProvider extends ChangeNotifier {
  bool _isDetecting = false;
  
  // 管理页面交互状态
}
```

---

## 📝 7. Naming Conventions (命名规范)

### 文件命名

- **Screen**: `xxx_screen.dart` (如 `home_screen.dart`)
- **Provider**: `xxx_provider.dart` (如 `user_provider.dart`)
- **Model**: `xxx_model.dart` (如 `user_model.dart`)
- **Repository**: `xxx_repository.dart` (如 `user_repository.dart`)
- **API**: `xxx_api.dart` (如 `user_api.dart`)
- **Service**: `xxx_service.dart` (如 `auth_service.dart`)
- **Widget**: `xxx_widget.dart` (如 `custom_button_widget.dart`)

### 变量命名

```dart
// ✅ 使用小驼峰命名（camelCase）
String userName;
int userAge;
bool isLoggedIn;

// ❌ 不要使用
String user_name;  // 下划线
String UserName;   // 大驼峰
```

### 类命名

```dart
// ✅ 使用大驼峰命名（PascalCase）
class UserProfile { }
class AuthService { }

// ❌ 不要使用
class userProfile { }
class auth_service { }
```

### 常量命名

```dart
// ✅ 使用小驼峰或全大写
const String apiBaseUrl = 'https://api.example.com';
const int MAX_RETRY_COUNT = 3;

// ❌ 不要混合使用
const String API_BASE_URL = 'https://api.example.com';  // 不一致
```

### 私有变量

```dart
// ✅ 使用下划线前缀
class MyClass {
  String _privateVariable;
  final _repository = UserRepository();
}
```

---

## 🔒 8. Security & Privacy (安全与隐私)

### API Key 管理

```dart
// ❌ 不要硬编码 API Key
const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

// ✅ 使用常量文件和环境变量
// core/constants/supabase_constants.dart
class SupabaseConstants {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');
}
```

### 敏感数据处理

- 不要在日志中输出敏感信息（密码、token）
- 使用安全存储（如 `flutter_secure_storage`）存储敏感数据
- 所有网络请求使用 HTTPS

### Row Level Security (RLS)

- 所有 Supabase 表必须启用 RLS
- 定义清晰的 RLS 策略（详见 `database/policy.sql`）
- 测试 RLS 策略确保用户只能访问自己的数据

---

## 🧪 9. Testing (测试规范)

### 测试类型

- **Unit Tests**: 测试单个函数、方法
- **Widget Tests**: 测试 UI 组件
- **Integration Tests**: 测试完整功能流程

### 测试覆盖率

- 目标：至少 70% 的代码覆盖率
- 关键业务逻辑必须 100% 覆盖

### 测试文件位置

```
test/
├── unit/
│   ├── repositories/
│   └── services/
├── widget/
│   └── screens/
└── integration/
```

### 测试命名

```dart
// ✅ 使用描述性名称
test('getUserProfile returns null when user not found', () {
  // Test implementation
});

// ❌ 不要使用
test('test1', () { });
```

---

## 🎬 10. Skeleton Loading (骨架屏)

### 要求

- 所有数据加载页面必须使用 **骨架屏** 代替简单的加载圈
- 骨架屏应该模仿实际内容的布局
- 使用 `shimmer` 效果增加视觉吸引力

### 实现方式

```dart
// 使用 shimmer package
import 'package:shimmer/shimmer.dart';

Widget buildSkeleton() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      children: [
        Container(height: 20, color: Colors.white),
        SizedBox(height: 8),
        Container(height: 100, color: Colors.white),
      ],
    ),
  );
}
```

### 何时使用

- ✅ 首次加载数据
- ✅ 刷新数据
- ✅ 分页加载
- ❌ 不要在按钮点击等短暂操作中使用

---

## 🔍 11. SEO (未来计划)

### Web 平台 SEO

当应用支持 Web 平台时，需要考虑：

- **Meta Tags**: 设置 title、description、keywords
- **Open Graph**: 社交媒体分享优化
- **Sitemap**: 生成网站地图
- **Robots.txt**: 配置搜索引擎爬虫规则
- **Structured Data**: 使用 Schema.org 标记

### Flutter Web SEO 实现

```html
<!-- web/index.html -->
<head>
  <title>Pavra - Road Safety Reporting App</title>
  <meta name="description" content="Report road hazards and stay safe">
  <meta property="og:title" content="Pavra">
  <meta property="og:description" content="Road Safety Reporting">
</head>
```

---

## 📦 12. Error Handling (错误处理)

### 统一错误处理

```dart
try {
  final result = await repository.getData();
  return result;
} on NetworkException catch (e) {
  // 网络错误
  showErrorDialog('Network error: ${e.message}');
} on AuthException catch (e) {
  // 认证错误
  navigateToLogin();
} catch (e) {
  // 其他错误
  logger.error('Unexpected error: $e');
  showErrorDialog('Something went wrong');
}
```

### 错误提示规范

- **用户友好**: 使用简单明了的语言
- **可操作**: 提供解决方案（如"重试"、"返回"）
- **不要暴露技术细节**: 用户不需要看到堆栈跟踪

### 日志记录

```dart
// 使用 logger package
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');  // 开发时使用
logger.i('Info message');   // 一般信息
logger.w('Warning message'); // 警告
logger.e('Error message');  // 错误
```

---

## 🚀 13. Performance (性能优化)

### 图片优化

- 使用合适的图片格式（WebP 优先）
- 压缩图片，减小文件大小
- 使用 `CachedNetworkImage` 缓存网络图片
- 懒加载图片

### 列表优化

```dart
// ✅ 使用 ListView.builder（懒加载）
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ 不要一次性构建所有 Widget
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

### 状态管理优化

- 只在需要时调用 `notifyListeners()`
- 使用 `Selector` 避免不必要的重建
- 避免在 `build` 方法中进行复杂计算

### 数据库查询优化

- 使用索引加速查询
- 只查询需要的字段（不要 `SELECT *`）
- 使用分页加载大量数据

---

## 📚 14. Documentation (文档规范)

### 必需文档

- [x] **ARCHITECTURE.md**: 架构设计说明
- [x] **DIRECTORY.md**: 目录结构说明
- [x] **RULES.md**: 开发规范（本文档）
- [ ] **REMINDER.md**: 开发注意事项
- [ ] **README.md**: 项目介绍和快速开始

### 代码文档

- 所有公共 API 必须有文档注释
- 复杂算法必须有解释说明
- 使用 `dartdoc` 生成 API 文档

### 更新文档

- 架构变更时更新 ARCHITECTURE.md
- 添加新目录时更新 DIRECTORY.md
- 新规则时更新 RULES.md

---

## ✅ 15. Code Review Checklist (代码审查清单)

提交代码前，确保：

- [ ] 代码遵循命名规范
- [ ] 所有函数有注释说明
- [ ] 遵循三层架构设计
- [ ] 没有硬编码的值
- [ ] 错误处理完善
- [ ] 在亮色和暗色模式下都测试过
- [ ] 所有文本都使用国际化
- [ ] 没有提交敏感信息（API Key、密码）
- [ ] 代码格式化（运行 `dart format .`）
- [ ] 没有 lint 警告（运行 `dart analyze`）

---

## 🔄 文档版本

- **Version**: 2.0
- **Last Updated**: 2025-10-11
- **Maintainer**: Pavra Team

---

遵循这些规则将帮助我们构建高质量、易维护、用户友好的应用！🚀