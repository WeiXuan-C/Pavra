core/
    放项目的核心逻辑和基础服务，通常包括：
    api/
        api_client.dart
        user_api.dart
    middleware/
        auth_middleware.dart
    constants/（常量、枚举等）
    utils/（工具类、格式化函数）
        helper.dart
        action_logger.dart
    services/（API 调用、数据库访问）
        onesignal_service.dart
    supabase/
        supabase_client.dart
        auth_service.dart
        database_service.dart
        storage_service.dart
        realtime_service.dart
    models/（数据模型、实体类）
        user_model.dart //被 data / presentation 引用, 可复用、通用性强
    localization/
        app_localizations.dart
        app_localizations_en.arb
        app_localizations_zh.arb //application resource bundle
        locale_provider.dart

data/
    providers/ 管全局逻辑，如用户、主题、设置, App 级（长生命周期）
        user_provider.dart
        settings_provider.dart
        theme_provider.dart
    models/ 依赖 core（不能反向引用）, 业务特化，方便操作数据库/API
    repositories/
    sources/

presentation/
    放所有**界面（UI 层）**相关的内容：
    各个页面（screens / views）
    页面内部的 state management（例如 Provider、Bloc、Riverpod 等）
    局部组件（如果跟特定页面强绑定）
    providers/ 控制页面交互状态，如加载、按钮、摄像头开关, 局部（短生命周期）

routes/
    这里通常放路由定义与导航逻辑，例如：
    app_routes.dart（定义路由常量）
    app_router.dart（使用 GoRouter 或 AutoRoute 等配置导航）

theme/
    放主题样式相关内容：
    app_theme.dart（定义颜色、字体、暗/亮模式）
    color_schemes.dart
    text_styles.dart

widgets/
    放可复用的小组件（UI 片段）：
    比如自定义按钮、输入框、卡片、加载动画等；
    与具体页面无关，可在不同页面重用。

main.dart
    项目入口文件，通常包含：
    runApp(MyApp())
    初始化依赖（如 Firebase、DI、路由等）
    主题和导航的顶层配置