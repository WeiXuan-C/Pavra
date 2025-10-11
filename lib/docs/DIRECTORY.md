# 项目目录结构说明

本文档详细说明了 Pavra 项目的目录结构和文件组织方式。

---

##  lib/ 根目录结构

lib/
    core/              # 核心逻辑和基础服务（业务无关）
    data/              # 数据层（Provider、Repository、Data Source）
    database/          # 数据库脚本（SQL）
    docs/              # 项目文档
    presentation/      # UI 层（所有界面和页面）
    routes/            # 路由定义和导航逻辑
    theme/             # 主题样式配置
    widgets/           # 可复用的通用组件
    main.dart          # 应用入口

---

## 🔧 core/ - 核心逻辑层

**定位**: 放项目的核心逻辑、基础服务、工具类等，**与具体业务无关**，可复用性强。

```
core/
├── api/                    # API 层（业务逻辑）
│   └── user/
│       └── user_api.dart   # Users/Profiles 表的业务逻辑
│                           # 使用 DatabaseService 进行 CRUD
│                           # 返回 Map<String, dynamic>
│
├── constants/              # 常量、枚举、配置
│   └── supabase_constants.dart  # Supabase URL、API Key 等配置
│
├── localization/           # 国际化/多语言支持
│   ├── app_localizations.dart      # 本地化主类
│   ├── app_localizations_en.arb    # 英文资源文件 (ARB格式)
│   ├── app_localizations_zh.arb    # 中文资源文件
│   └── locale_provider.dart        # 语言切换 Provider
│
├── middleware/             # 中间件（如认证拦截器）
│   └── auth_middleware.dart        # 路由认证中间件
│
├── models/                 # 通用数据模型
│   └── user_model.dart     # User/UserProfile Model
│                           # 被 data/ 和 presentation/ 引用
│                           # 通用性强，可复用
│
├── providers/              # 核心 Provider（如果需要）
│   └── [core-level providers]
│
├── services/               # 第三方服务集成
│   └── onesignal_service.dart      # OneSignal 推送通知服务
│
├── supabase/               # Supabase 服务封装
│   ├── supabase_client.dart        # Supabase 客户端初始化
│   ├── auth_service.dart           # 认证服务（登录、注册、OAuth）
│   ├── database_service.dart       # 通用 CRUD 层（表无关）
│   ├── storage_service.dart        # 文件存储服务
│   └── realtime_service.dart       # 实时订阅服务
│
├── utils/                  # 工具类和辅助函数
│   ├── helper.dart         # 通用辅助函数
│   └── action_logger.dart  # 日志记录工具
│
└── app_export.dart         # 统一导出文件（便于引用）
```

### 核心层职责

- **api/**: 针对特定数据库表的业务逻辑，使用 `DatabaseService`
- **supabase/**: Supabase 相关的所有服务（Auth、Database、Storage、Realtime）
- **models/**: 通用的数据模型，可被整个项目引用
- **constants/**: 全局常量和配置
- **utils/**: 工具函数，与业务无关

---

## 📊 data/ - 数据层

**定位**: 数据仓库层，负责数据的获取、转换和状态管理。

```
data/
├── models/                 # 业务特定的数据模型
│   └── report_model.dart   # 报告模型（依赖 core/models/）
│                           # 业务特化，方便操作数据库/API
│
├── providers/              # 全局数据状态管理
│   ├── user_provider.dart      # 用户状态管理（App 级）
│   ├── settings_provider.dart  # 设置状态管理
│   └── theme_provider.dart     # 主题状态管理
│                               # 长生命周期，贯穿整个应用
│
├── repositories/           # 数据仓库层
│   ├── user_repository.dart    # 用户数据仓库
│   │                           # 调用 UserApi
│   │                           # 将 Map<String, dynamic> 转换为 Model
│   │                           # 提供类型安全的接口
│   └── [other_repository.dart]
│
└── sources/                # 数据源（本地/远程）
    ├── local/              # 本地数据源（SharedPreferences、Hive 等）
    └── remote/             # 远程数据源（API 调用封装）
```

### 数据层职责

- **providers/**: App 级别的全局状态管理，生命周期长
- **repositories/**: 数据访问的统一接口，负责数据转换（JSON → Model）
- **models/**: 业务特定的模型，可以依赖 `core/models/`
- **sources/**: 原始数据源的封装（本地存储、远程 API）

---

## 🗄️ database/ - 数据库脚本

**定位**: 存放 Supabase 数据库的 SQL 脚本。

```
database/
├── schema.sql      # 数据库表结构定义
├── function.sql    # 数据库函数（Stored Procedures）
└── policy.sql      # Row Level Security 策略
```

### 数据库层职责

- 定义数据库表结构
- 定义数据库函数和触发器
- 配置安全策略（RLS）

---

## 📄 docs/ - 项目文档

**定位**: 项目相关的文档和说明。

```
docs/
├── ARCHITECTURE.md     # 架构设计文档（三层架构说明）
├── DIRECTORY.md        # 目录结构说明（本文档）
├── RULES.md            # 开发规范和最佳实践
└── REMINDER.md         # 开发注意事项和提醒
```

---

## 🎨 presentation/ - UI 层

**定位**: 所有界面相关的内容，包括页面、Widget、局部状态管理。

```
presentation/
├── authentication_screen/      # 认证页面（登录/注册）
│   ├── authentication_screen.dart      # 页面主文件
│   ├── authentication_provider.dart    # 页面状态管理
│   └── widgets/                        # 页面内部组件
│
├── camera_detection_screen/    # 摄像头检测页面
│   ├── camera_detection_screen.dart
│   ├── camera_detection_provider.dart  # 摄像头状态管理
│   └── widgets/
│
├── home_screen/                # 首页
│   └── home_screen.dart
│
├── map_view_screen/            # 地图视图页面
│   ├── map_view_screen.dart
│   ├── map_view_provider.dart
│   └── widgets/
│
├── report_submission_screen/   # 报告提交页面
│   ├── report_submission_screen.dart
│   ├── report_submission_provider.dart
│   └── widgets/
│
└── safety_alerts_screen/       # 安全警报页面
    ├── safety_alerts_screen.dart
    ├── safety_alerts_provider.dart
    └── widgets/
```

### UI 层职责

- **screens/**: 各个页面的主文件
- **providers/**: 页面级别的状态管理（局部、短生命周期）
  - 控制页面交互状态（加载、按钮、输入框等）
  - 与特定页面强绑定
- **widgets/**: 页面内部的组件（不可复用，与页面逻辑耦合）

### Provider 分层

- **data/providers/**: 全局 Provider（如 `user_provider.dart`）
  - App 级别，长生命周期
  - 管理用户、主题、设置等全局状态
  
- **presentation/*/providers/**: 局部 Provider（如 `camera_detection_provider.dart`）
  - 页面级别，短生命周期
  - 控制页面交互状态（加载、按钮、摄像头开关等）

---

## 🧭 routes/ - 路由层

**定位**: 路由定义和导航逻辑。

```
routes/
└── app_routes.dart     # 路由配置
                        # 定义路由常量
                        # 配置 GoRouter 或其他路由框架
```

### 路由层职责

- 定义所有路由路径常量
- 配置路由跳转逻辑
- 设置路由守卫（如认证检查）

---

## 🎨 theme/ - 主题层

**定位**: 应用的主题样式配置。

```
theme/
├── app_theme.dart          # 主题配置主文件
│                           # 定义 ThemeData
│                           # 暗/亮模式配置
├── color_schemes.dart      # 颜色方案定义
└── text_styles.dart        # 文字样式定义
```

### 主题层职责

- 定义应用的颜色方案
- 配置文字样式
- 支持暗/亮模式切换

---

## 🧩 widgets/ - 通用组件层

**定位**: 可复用的通用 Widget，与具体页面无关。

```
widgets/
├── custom_error_widget.dart    # 自定义错误组件
├── custom_icon_widget.dart     # 自定义图标组件
└── custom_image_widget.dart    # 自定义图片组件
```

### 组件层职责

- 提供可复用的通用组件
- 与具体业务逻辑解耦
- 可在多个页面中使用

### widgets/ vs presentation/*/widgets/

- **lib/widgets/**: 通用组件，可在任何页面使用
- **lib/presentation/*/widgets/**: 页面专用组件，与页面逻辑强绑定

---

## 📱 main.dart - 应用入口

**定位**: 应用的启动入口。

```dart
main.dart
├── void main() async
├── Supabase 初始化
├── OneSignal 初始化
├── MultiProvider 配置
└── runApp(MyApp())
```

### 入口文件职责

- 初始化第三方服务（Supabase、OneSignal 等）
- 配置全局 Provider
- 设置路由和主题
- 启动应用

---

## 📐 架构设计原则

### 1. 分层架构

```
UI Layer (presentation/)
    ↓ 调用
Data Layer (data/repositories/)
    ↓ 调用
API Layer (core/api/)
    ↓ 调用
Service Layer (core/supabase/database_service.dart)
```

### 2. 依赖规则

- ✅ **presentation/** 可以依赖 **data/** 和 **core/**
- ✅ **data/** 可以依赖 **core/**
- ❌ **core/** 不应该依赖 **data/** 或 **presentation/**
- ❌ **data/** 不应该依赖 **presentation/**

### 3. 文件命名规范

- **Screen**: `xxx_screen.dart`
- **Provider**: `xxx_provider.dart`
- **Model**: `xxx_model.dart`
- **Repository**: `xxx_repository.dart`
- **API**: `xxx_api.dart`
- **Service**: `xxx_service.dart`
- **Widget**: `custom_xxx_widget.dart` 或 `xxx_widget.dart`

### 4. 目录组织原则

- **按功能分组**: 每个 screen 有自己的文件夹
- **相关文件放在一起**: Provider、Widget 和 Screen 放在同一目录
- **通用内容上提**: 可复用的内容放在更高层级（如 `widgets/`、`core/`）

---

## 🔍 文件查找指南

### 我要找...

- **认证逻辑**: `core/supabase/auth_service.dart`
- **数据库操作**: `core/supabase/database_service.dart`
- **用户相关 API**: `core/api/user/user_api.dart`
- **用户数据仓库**: `data/repositories/user_repository.dart`
- **用户全局状态**: `data/providers/user_provider.dart`
- **用户模型**: `core/models/user_model.dart`
- **登录页面**: `presentation/authentication_screen/`
- **路由配置**: `routes/app_routes.dart`
- **主题配置**: `theme/app_theme.dart`
- **通用组件**: `widgets/`
- **数据库表结构**: `database/schema.sql`

---

## 📚 相关文档

- **架构设计**: 详见 `ARCHITECTURE.md`
- **开发规范**: 详见 `RULES.md`
- **注意事项**: 详见 `REMINDER.md`