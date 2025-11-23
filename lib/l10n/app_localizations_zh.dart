// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Pavra';

  @override
  String get appTitle => 'Pavra';

  @override
  String get common_ok => '确定';

  @override
  String get common_cancel => '取消';

  @override
  String get common_confirm => '确认';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_edit => '编辑';

  @override
  String get common_close => '关闭';

  @override
  String get common_loading => '加载中...';

  @override
  String get common_error => '错误';

  @override
  String get common_success => '成功';

  @override
  String get common_retry => '重试';

  @override
  String get common_back => '返回';

  @override
  String get common_next => '下一步';

  @override
  String get common_submit => '提交';

  @override
  String get auth_welcomeTitle => '欢迎使用 Pavra';

  @override
  String get auth_welcomeSubtitle => '报告和追踪您社区的基础设施问题';

  @override
  String get auth_emailLabel => '电子邮箱';

  @override
  String get auth_emailHint => '请输入您的邮箱';

  @override
  String get auth_sendOtp => '发送验证码';

  @override
  String get auth_otpTitle => '输入验证码';

  @override
  String get auth_otpSubtitle => '请输入发送到以下邮箱的6位验证码';

  @override
  String get auth_otpHint => '输入6位验证码';

  @override
  String get auth_verify => '验证';

  @override
  String get auth_resendCode => '重新发送';

  @override
  String get auth_invalidEmail => '请输入有效的邮箱地址';

  @override
  String get auth_invalidOtp => '请输入有效的6位验证码';

  @override
  String get auth_otpSent => '验证码发送成功';

  @override
  String get auth_otpFailed => '验证码发送失败';

  @override
  String get auth_verifyFailed => '验证失败';

  @override
  String get auth_signInWithGoogle => '使用 Google 登录';

  @override
  String get auth_signInWithGithub => '使用 Github 登录';

  @override
  String get auth_signInWithFacebook => '使用 Facebook 登录';

  @override
  String get auth_signInWithDiscord => '使用 Discord 登录';

  @override
  String get auth_orContinueWith => '或者使用以下方式继续';

  @override
  String get home_title => '主页';

  @override
  String get home_noUserLoggedIn => '没有用户登录';

  @override
  String get home_accountInfo => '账户信息';

  @override
  String get home_email => '邮箱';

  @override
  String get home_lastUpdated => '最后更新';

  @override
  String get home_appearance => '外观';

  @override
  String get home_themeMode => '主题模式';

  @override
  String get home_language => '语言';

  @override
  String get home_themeSystem => '跟随系统';

  @override
  String get home_themeLight => '浅色';

  @override
  String get home_themeDark => '深色';

  @override
  String get home_logout => '退出登录';

  @override
  String get home_confirmLogout => '确认退出';

  @override
  String get home_confirmLogoutMessage => '您确定要退出登录吗？';

  @override
  String get home_user => '用户';

  @override
  String get home_noEmail => '没有邮箱';

  @override
  String get home_userId => '用户ID';

  @override
  String get home_settings => '设置';

  @override
  String get camera_title => '摄像头检测';

  @override
  String get camera_startDetection => '开始检测';

  @override
  String get camera_stopDetection => '停止检测';

  @override
  String get camera_captureImage => '拍摄照片';

  @override
  String get camera_switchCamera => '切换摄像头';

  @override
  String get camera_detectionHistory => '检测历史';

  @override
  String get camera_detectionMetrics => '检测指标';

  @override
  String get camera_confidence => '置信度';

  @override
  String get camera_detecting => '检测中...';

  @override
  String get camera_noDetection => '暂无检测结果';

  @override
  String get camera_gpsStatus => 'GPS状态';

  @override
  String get camera_aiDetection => 'AI检测';

  @override
  String get camera_disabled => '已禁用';

  @override
  String get camera_active => '活跃';

  @override
  String get camera_inactive => '未激活';

  @override
  String get camera_initializingCamera => '正在初始化摄像头...';

  @override
  String get camera_aiDetectionActive => 'AI检测已激活';

  @override
  String get camera_detectionAnalytics => '检测分析';

  @override
  String get camera_noDataAvailable => '暂无检测数据';

  @override
  String get camera_detectionDistribution => '检测分布';

  @override
  String get camera_confidenceMetrics => '置信度指标';

  @override
  String get camera_recentActivity => '最近活动';

  @override
  String get camera_detected => '已检测';

  @override
  String get camera_recentDetections => '最近检测';

  @override
  String get camera_noDetectionsYet => '暂无检测';

  @override
  String get camera_startScanning => '开始扫描以检测道路问题';

  @override
  String get camera_flash => '闪光灯';

  @override
  String get camera_burstMode => '连拍模式';

  @override
  String get camera_gallery => '相册';

  @override
  String get camera_captured => '已拍摄';

  @override
  String get camera_errorPermissionDenied => '相机权限被拒绝';

  @override
  String get camera_errorCameraFailed => '相机初始化失败';

  @override
  String get camera_totalDetections => '总检测数';

  @override
  String get camera_potholes => '坑洞';

  @override
  String get camera_cracks => '裂缝';

  @override
  String get camera_obstacles => '障碍物';

  @override
  String get camera_average => '平均';

  @override
  String get camera_highest => '最高';

  @override
  String get camera_lowest => '最低';

  @override
  String get camera_justNow => '刚刚';

  @override
  String get camera_photoCaptured => '照片已成功拍摄';

  @override
  String get camera_imageProcessed => '图像已成功处理';

  @override
  String get camera_burstModeActivated => '连拍模式已激活';

  @override
  String get camera_burstModeDeactivated => '连拍模式已关闭';

  @override
  String get camera_detectionDetails => '检测详情';

  @override
  String get camera_type => '类型';

  @override
  String get camera_location => '位置';

  @override
  String get camera_time => '时间';

  @override
  String get camera_close => '关闭';

  @override
  String get camera_submitReport => '提交报告';

  @override
  String get camera_burstModeActive => '连拍模式已激活';

  @override
  String get camera_captureInstructions => '点击拍摄 • 长按启用连拍模式';

  @override
  String camera_burstModeInstructions(String burstMode) {
    return '$burstMode • 点击拍摄 • 长按退出';
  }

  @override
  String get camera_manualDetection => '手动AI检测';

  @override
  String get time_justNow => '刚刚';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String time_daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get map_title => '地图视图';

  @override
  String get map_searchHint => '搜索位置...';

  @override
  String get map_filterTitle => '筛选问题';

  @override
  String get map_nearbyIssues => '附近问题';

  @override
  String get map_issueDetails => '问题详情';

  @override
  String get map_reportedBy => '报告人';

  @override
  String get map_severity => '严重程度';

  @override
  String get map_status => '状态';

  @override
  String get map_distance => '距离';

  @override
  String get map_viewDetails => '查看详情';

  @override
  String get map_noIssuesFound => '附近没有发现问题';

  @override
  String get map_adjustLocation => '尝试调整您的位置或缩放级别';

  @override
  String get map_found => '个';

  @override
  String get map_suggestions => '建议';

  @override
  String get map_recentSearches => '最近搜索';

  @override
  String get map_issueTypes => '问题类型';

  @override
  String get map_severityLevels => '严重程度';

  @override
  String get map_clearAll => '清除全部';

  @override
  String get map_applyFilters => '应用筛选';

  @override
  String get map_description => '描述';

  @override
  String get map_directions => '导航';

  @override
  String get map_reportSimilar => '报告类似问题';

  @override
  String get map_reportIssuePrompt => '在此位置创建新的道路安全报告？';

  @override
  String get map_reported => '已报告';

  @override
  String get map_away => '外';

  @override
  String get map_reportIssue => '报告问题';

  @override
  String get map_locationServicesDisabled => '请在设备设置中启用位置服务';

  @override
  String get map_locationPermissionDenied => '位置权限已永久拒绝。请在应用设置中启用。';

  @override
  String get map_failedToLoadIssues => '加载附近问题失败';

  @override
  String map_showingIssuesWithin(String radius) {
    return '显示$radius英里内的问题';
  }

  @override
  String get map_refresh => '刷新';

  @override
  String get map_currentLocation => '当前位置';

  @override
  String get map_mapType => '地图类型';

  @override
  String get map_traffic => '交通';

  @override
  String get report_title => '报告问题';

  @override
  String get report_issueType => '问题类型';

  @override
  String get report_selectIssueType => '选择问题类型';

  @override
  String get report_pothole => '坑洞';

  @override
  String get report_crack => '裂缝';

  @override
  String get report_flooding => '积水';

  @override
  String get report_lighting => '照明';

  @override
  String get report_other => '其他';

  @override
  String get report_description => '描述';

  @override
  String get report_descriptionHint => '详细描述问题...';

  @override
  String get report_photos => '照片';

  @override
  String get report_addPhoto => '添加照片';

  @override
  String get report_location => '位置';

  @override
  String get report_useCurrentLocation => '使用当前位置';

  @override
  String get report_severityLevel => '严重程度';

  @override
  String get report_low => '低';

  @override
  String get report_medium => '中';

  @override
  String get report_high => '高';

  @override
  String get report_submitReport => '提交报告';

  @override
  String get report_submitting => '提交中...';

  @override
  String get report_success => '报告提交成功';

  @override
  String get report_failed => '报告提交失败';

  @override
  String get report_locationInfo => '位置信息';

  @override
  String get report_latitude => '纬度';

  @override
  String get report_longitude => '经度';

  @override
  String get report_saveDraft => '保存草稿';

  @override
  String get report_submittingReport => '正在提交报告...';

  @override
  String get report_selectIssueTypeWarning => '请至少选择一种问题类型以提交报告';

  @override
  String get report_uploadingReport => '正在上传报告...';

  @override
  String get report_syncingCloud => '正在与云服务器同步...';

  @override
  String get report_rateSeverity => '评估道路问题的严重程度';

  @override
  String get report_additionalPhotos => '附加照片';

  @override
  String get report_addPhotoHint => '添加问题的多个角度或特写镜头';

  @override
  String get report_photosLeft => '剩余';

  @override
  String get report_noAdditionalPhotos => '没有附加照片';

  @override
  String get report_tapToAddPhotos => '点击添加照片';

  @override
  String get report_locationDetails => '位置详情';

  @override
  String get report_address => '地址';

  @override
  String get report_gpsAccuracy => 'GPS精度';

  @override
  String get alerts_title => '安全警报';

  @override
  String get alerts_enableAlerts => '启用警报';

  @override
  String get alerts_alertRadius => '警报半径';

  @override
  String get alerts_routeMonitoring => '路线监控';

  @override
  String get alerts_noAlerts => '附近没有安全警报';

  @override
  String get alerts_viewOnMap => '在地图上查看';

  @override
  String get alerts_distance => '距离';

  @override
  String get alerts_activeAlerts => '活跃警报';

  @override
  String get alerts_settings => '设置';

  @override
  String get alerts_routes => '路线';

  @override
  String get alerts_alertTypes => '警报类型';

  @override
  String get alerts_roadDamage => '路面损坏';

  @override
  String get alerts_constructionZones => '施工区域';

  @override
  String get alerts_weatherHazards => '天气危险';

  @override
  String get alerts_trafficIncidents => '交通事故';

  @override
  String get alerts_locationSettings => '位置设置';

  @override
  String get alerts_coveragePreview => '覆盖范围预览';

  @override
  String get alerts_savedRoutes => '已保存的路线';

  @override
  String get alerts_addRoute => '添加路线';

  @override
  String get alerts_allClear => '一切正常！';

  @override
  String get alerts_noAlertsMessage => '您所在区域目前没有安全警报。如果附近报告任何道路危险，我们将立即通知您。';

  @override
  String get alerts_checkForUpdates => '检查更新';

  @override
  String get alerts_checking => '检查中...';

  @override
  String get alerts_updated => '安全警报已更新';

  @override
  String get alerts_acknowledged => '警报已标记为已确认';

  @override
  String get alerts_undo => '撤销';

  @override
  String get alerts_notificationSettings => '通知设置';

  @override
  String get alerts_soundAlerts => '声音警报';

  @override
  String get alerts_soundAlertsDesc => '为严重警报播放通知声音';

  @override
  String get alerts_vibration => '振动';

  @override
  String get alerts_vibrationDesc => '为高优先级警报振动设备';

  @override
  String get alerts_doNotDisturb => '勿扰模式';

  @override
  String get alerts_doNotDisturbDesc => '遵守系统勿扰设置';

  @override
  String get alerts_quietHours => '免打扰时段';

  @override
  String get alerts_quietHoursDesc => '在免打扰时段内仅显示严重安全警报';

  @override
  String get alerts_routeMonitoringInfo => '为您常用的路线启用监控，以接收有关路况、施工和事故的主动警报。';

  @override
  String get alerts_critical => '严重';

  @override
  String get report_reportSubmitted => '报告已提交';

  @override
  String get report_reportSubmittedMessage => '您的道路安全报告已成功提交给有关部门。';

  @override
  String get report_reportId => '报告ID';

  @override
  String get report_estimatedResponse => '预计响应时间：2-3个工作日';

  @override
  String get report_viewOnMap => '在地图上查看';

  @override
  String get report_done => '完成';

  @override
  String get report_unsavedChanges => '未保存的更改';

  @override
  String get report_unsavedChangesMessage => '您有未保存的更改。是否要在离开前保存草稿？';

  @override
  String get report_discard => '丢弃';

  @override
  String get report_photoUpdated => '照片更新成功';

  @override
  String get report_photoCaptureFailed => '拍摄照片失败';

  @override
  String get report_locationUpdated => '位置已更新';

  @override
  String get report_photoAdded => '照片添加成功';

  @override
  String get report_photoRemoved => '照片已移除';

  @override
  String get report_maxPhotos => '最多允许添加5张附加照片';

  @override
  String get report_photoAddFailed => '添加照片失败';

  @override
  String get report_draftSaved => '草稿保存成功';

  @override
  String get report_submitFailed => '提交报告失败。请重试。';

  @override
  String get report_obstacle => '障碍物';

  @override
  String get nav_camera => '相机';

  @override
  String get nav_map => '地图';

  @override
  String get nav_report => '报告';

  @override
  String get nav_alerts => '警报';

  @override
  String get nav_profile => '我的';

  @override
  String get language_english => 'English';

  @override
  String get language_chinese => '中文';

  @override
  String get settings_notifications => '通知';

  @override
  String get settings_pushNotifications => '推送通知';

  @override
  String get settings_pushNotificationsDesc => '启用推送通知';

  @override
  String get settings_alertTypes => '警报类型';

  @override
  String get settings_roadDamage => '路面损坏';

  @override
  String get settings_version => '版本';

  @override
  String get settings_developerMode => '开发者模式';

  @override
  String get settings_exitDeveloperMode => '退出开发者模式';

  @override
  String get settings_enterAccessCode => '输入访问代码';

  @override
  String get settings_accessCodeHint => '输入访问代码';

  @override
  String get settings_accessCodeIncorrect => '访问代码不正确';

  @override
  String get settings_developerModeEnabled => '开发者模式已启用';

  @override
  String get settings_developerModeDisabled => '开发者模式已禁用';

  @override
  String get settings_authorityWarning => '权限警告';

  @override
  String get settings_authorityWarningMessage =>
      '如果您切换到开发者模式，您只能切换回普通用户角色。您的权限身份将被永久删除。您确定要继续吗？';

  @override
  String get settings_requestAuthority => '申请成为权限用户';

  @override
  String get settings_requestAuthorityMessage => '您申请成为权限用户的请求已提交审核。';

  @override
  String get settings_requestAuthorityConfirm => '提交申请成为权限用户？此请求将由管理员审核。';

  @override
  String get settings_exitDeveloperModeMessage => '您确定要退出开发者模式吗？您将切换回普通用户角色。';

  @override
  String get settings_appInformation => '应用信息';

  @override
  String get profile_username => '用户名';

  @override
  String get profile_language => '语言';

  @override
  String get profile_role => '角色';

  @override
  String get profile_roleUser => '用户';

  @override
  String get profile_roleAuthority => '权限用户';

  @override
  String get profile_roleDeveloper => '开发者';

  @override
  String get profile_statistics => '统计';

  @override
  String get profile_totalReports => '总报告数';

  @override
  String get profile_reputation => '声誉';

  @override
  String get profile_statisticsAnalysis => '统计分析';

  @override
  String get profile_generateAnalysis => '生成分析';

  @override
  String get profile_generating => '生成中...';

  @override
  String get profile_analysisError => '生成分析失败，请重试。';

  @override
  String get profile_validReports => '有效报告';

  @override
  String get profile_insights => '洞察';

  @override
  String profile_insightReports(int count) {
    return '您已提交 $count 份有效报告以改善道路安全。';
  }

  @override
  String get profile_insightReputationHigh => '您的声誉分数非常出色！继续保持！';

  @override
  String get profile_insightReputationMedium => '您正在社区中建立良好的声誉。';

  @override
  String get profile_insightReputationLow => '提交更多报告以提高您的声誉分数。';

  @override
  String get profile_contributionExcellent => '您是道路安全的杰出贡献者！';

  @override
  String get profile_contributionGood => '您是社区的宝贵贡献者。';

  @override
  String get profile_contributionActive => '您是社区的活跃成员。';

  @override
  String get profile_contributionBeginner => '开始报告问题以为道路安全做出贡献。';

  @override
  String get profile_refreshAnalysis => '刷新分析';

  @override
  String get settings_roadDamageDesc => '坑洞、裂缝和路面问题';

  @override
  String get settings_constructionZones => '施工区域';

  @override
  String get settings_constructionZonesDesc => '道路施工和车道封闭';

  @override
  String get settings_weatherHazards => '天气危险';

  @override
  String get settings_weatherHazardsDesc => '大雾、结冰和天气状况';

  @override
  String get settings_trafficIncidents => '交通事故';

  @override
  String get settings_trafficIncidentsDesc => '事故和交通延误';

  @override
  String get settings_notificationBehavior => '通知行为';

  @override
  String get settings_sound => '声音';

  @override
  String get settings_soundDesc => '为通知播放声音';

  @override
  String get settings_vibration => '振动';

  @override
  String get settings_vibrationDesc => '为通知振动设备';

  @override
  String get alerts_miles => '英里';

  @override
  String get alerts_mile => '英里';

  @override
  String get alerts_routeMonitoringTitle => '路线监控';

  @override
  String get alerts_noSavedRoutes => '没有保存的路线。添加常用路线以监控警报。';

  @override
  String get severity_minor => '轻微';

  @override
  String get severity_low => '较低';

  @override
  String get severity_moderate => '中等';

  @override
  String get severity_high => '严重';

  @override
  String get severity_critical => '危急';

  @override
  String get severity_minorDesc => '轻微不便，无即时危险';

  @override
  String get severity_lowDesc => '轻微不适，影响最小';

  @override
  String get severity_moderateDesc => '明显问题，需要关注';

  @override
  String get severity_highDesc => '重大隐患，需要紧急修复';

  @override
  String get severity_criticalDesc => '极度危险，需要立即采取行动';

  @override
  String get report_descriptionPlaceholder => '描述道路状况、交通影响或其他相关细节...';

  @override
  String get report_optional => '可选';

  @override
  String get report_suggestions => '建议';

  @override
  String get report_analyzingImage => '正在用 AI 分析图片';

  @override
  String get report_analyzingImageMessage => '请稍候，我们正在分析图片...';

  @override
  String get report_draft => '草稿';

  @override
  String get report_uploadingPhoto => '正在上传照片...';

  @override
  String get notification_title => '通知';

  @override
  String get notification_markAllAsRead => '全部标记为已读';

  @override
  String get notification_deleteAll => '删除全部';

  @override
  String get notification_allMarkedAsRead => '所有通知已标记为已读';

  @override
  String get notification_allDeleted => '所有通知已删除';

  @override
  String get notification_errorLoading => '加载通知时出错';

  @override
  String get notification_empty => '暂无通知';

  @override
  String get notification_emptyMessage => '收到通知时会显示在这里';

  @override
  String get notification_delete => '删除通知';

  @override
  String get notification_deleteConfirm => '您确定要删除此通知吗？';

  @override
  String get notification_deleteAllTitle => '删除所有通知';

  @override
  String get notification_deleteAllConfirm => '您确定要删除所有通知吗？此操作无法撤销。';

  @override
  String get notification_deleted => '通知已删除';

  @override
  String get notification_typeSuccess => '成功';

  @override
  String get notification_typeWarning => '警告';

  @override
  String get notification_typeAlert => '提醒';

  @override
  String get notification_typeSystem => '系统';

  @override
  String get notification_typeUser => '用户';

  @override
  String get notification_typeReport => '报告';

  @override
  String get notification_typeLocation => '位置';

  @override
  String get notification_typeStatus => '状态';

  @override
  String get notification_typePromotion => '推广';

  @override
  String get notification_typeReminder => '提醒';

  @override
  String get notification_typeInfo => '信息';

  @override
  String get notification_create => '创建通知';

  @override
  String get notification_edit => '编辑通知';

  @override
  String get notification_titleLabel => '标题';

  @override
  String get notification_titleHint => '输入通知标题';

  @override
  String get notification_titleRequired => '标题为必填项';

  @override
  String get notification_titleTooLong => '标题过长（最多100个字符）';

  @override
  String get notification_messageLabel => '消息';

  @override
  String get notification_messageHint => '输入通知消息';

  @override
  String get notification_messageRequired => '消息为必填项';

  @override
  String get notification_messageTooLong => '消息过长（最多500个字符）';

  @override
  String get notification_typeLabel => '类型';

  @override
  String get notification_relatedActionLabel => '相关操作（可选）';

  @override
  String get notification_relatedActionHint => '例如：/reports/123';

  @override
  String get notification_preview => '预览';

  @override
  String get notification_update => '更新通知';

  @override
  String get notification_createSuccess => '通知创建成功';

  @override
  String get notification_createError => '创建通知失败';

  @override
  String get notification_updateSuccess => '通知更新成功';

  @override
  String get notification_updateError => '更新通知失败';

  @override
  String get notification_type_success => '成功';

  @override
  String get notification_type_warning => '警告';

  @override
  String get notification_type_alert => '警报';

  @override
  String get notification_type_system => '系统';

  @override
  String get notification_type_user => '用户';

  @override
  String get notification_type_report => '报告';

  @override
  String get notification_type_location_alert => '位置警报';

  @override
  String get notification_type_submission_status => '提交状态';

  @override
  String get notification_type_promotion => '推广';

  @override
  String get notification_type_reminder => '提醒';

  @override
  String get notification_type_info => '信息';

  @override
  String get report_newReport => '新建报告';

  @override
  String get report_myReports => '我的报告';

  @override
  String get report_allReports => '所有报告';

  @override
  String get report_noReports => '暂无报告';

  @override
  String get report_noReportsMessage => '您还没有提交任何报告';

  @override
  String get report_sortBy => '排序：';

  @override
  String get report_sortDate => '日期';

  @override
  String get report_sortSeverity => '严重程度';

  @override
  String get report_sortStatus => '状态';

  @override
  String get report_mine => '我的';

  @override
  String get report_statusReported => '已报告';

  @override
  String get report_statusInProgress => '处理中';

  @override
  String get report_statusResolved => '已解决';

  @override
  String get map_viewAlerts => '警报';

  @override
  String get profile_settings => '设置';

  @override
  String get report_openCamera => '打开相机检测';

  @override
  String get report_aiDetectionReady => 'AI检测已就绪，可扫描道路问题';

  @override
  String get report_quickReportTitle => '快速报告道路问题';

  @override
  String get report_selectMethodBelow => '选择下方方式开始报告';

  @override
  String get report_reportMethods => '报告方式';

  @override
  String get report_aiSmartDetection => 'AI 智能检测';

  @override
  String get report_useCameraAutoDetect => '使用相机自动识别道路问题';

  @override
  String get report_fillFormReport => '填写表单报告';

  @override
  String get report_selectFromGallery => '从相册选择';

  @override
  String get report_aiAnalyzePhoto => 'AI 分析照片';

  @override
  String get report_myContribution => '我的贡献';

  @override
  String get report_totalReports => '总报告';

  @override
  String get report_resolved => '已解决';

  @override
  String get report_reviewed => '已审核';

  @override
  String get report_inProgress => '处理中';

  @override
  String get report_recentReports => '最近报告';

  @override
  String get report_viewAll => '查看全部';

  @override
  String get report_filterMenuSubtitleHome => '快速报告道路问题';

  @override
  String get report_filterMenuSubtitleMy => '查看我提交的报告';

  @override
  String get report_filterMenuSubtitleAll => '浏览所有用户的报告';

  @override
  String get notification_filterAll => '全部';

  @override
  String get notification_filterUnread => '未读';

  @override
  String get notification_filterRead => '已读';

  @override
  String get notification_filterEmpty => '没有通知';

  @override
  String get notification_filterEmptyMessage => '没有符合所选过滤条件的通知';

  @override
  String get notification_clearFilter => '清除过滤';

  @override
  String get notification_selectFilter => '选择过滤条件';

  @override
  String get notification_filterActive => '个过滤条件';

  @override
  String get notification_filtersActive => '个过滤条件';

  @override
  String get notification_results => '条结果';

  @override
  String get notification_cannotDelete => '无法删除此通知';

  @override
  String get notification_deletePermissionDenied => '只有创建者可以在30天内删除通知';

  @override
  String get notification_expired => '已过期';

  @override
  String get notification_filter => '筛选';

  @override
  String get notification_toggleFilter => '切换筛选菜单';

  @override
  String get notification_filterSentByMe => '我发布的';

  @override
  String get notification_filterSentToMe => '发给我的';

  @override
  String get notification_filterAllUsers => '所有人的';

  @override
  String get notification_createdByMe => '我创建的';

  @override
  String get notification_statusDraft => '草稿';

  @override
  String get notification_statusScheduled => '已排程';

  @override
  String get notification_statusFailed => '发送失败';

  @override
  String get notification_statusSent => '已发送';

  @override
  String get issueTypes_title => '问题类型';

  @override
  String get issueTypes_manageTooltip => '管理问题类型';

  @override
  String get issueTypes_create => '创建问题类型';

  @override
  String get issueTypes_edit => '编辑问题类型';

  @override
  String get issueTypes_delete => '删除问题类型';

  @override
  String get issueTypes_name => '名称';

  @override
  String get issueTypes_description => '描述';

  @override
  String get issueTypes_nameRequired => '必填';

  @override
  String issueTypes_deleteConfirm(String name) {
    return '确定要删除 \"$name\" 吗？';
  }

  @override
  String get issueTypes_created => '问题类型已创建';

  @override
  String get issueTypes_updated => '问题类型已更新';

  @override
  String get issueTypes_deleted => '问题类型已删除';

  @override
  String get issueTypes_noTypes => '未找到问题类型';

  @override
  String get issueTypes_createPrompt => '点击 + 创建一个';

  @override
  String get issueTypes_errorPrefix => '错误：';

  @override
  String get report_enterLocation => '输入位置地址';

  @override
  String get report_untitled => '无标题报告';

  @override
  String get report_noLocation => '无位置';

  @override
  String get report_statusDraft => '草稿';

  @override
  String get report_statusSubmitted => '已提交';

  @override
  String get report_statusReviewed => '已审核';

  @override
  String get report_statusSpam => '垃圾信息';

  @override
  String get report_statusDiscarded => '已丢弃';

  @override
  String get report_critical => '严重';

  @override
  String get report_moderate => '中等';

  @override
  String get report_minor => '轻微';

  @override
  String get report_locationPermissionDeniedForever => '位置权限已永久拒绝。请在设置中启用。';

  @override
  String get report_locationError => '无法获取位置';

  @override
  String get report_manualAddressEntry => '手动输入地址';

  @override
  String get report_addressLine1 => '地址第一行';

  @override
  String get report_addressLine1Hint => '输入街道地址';

  @override
  String get report_addressLine2 => '地址第二行';

  @override
  String get report_addressLine2Hint => '公寓、单元等（可选）';

  @override
  String get report_city => '城市';

  @override
  String get report_cityHint => '输入城市';

  @override
  String get report_state => '州/省';

  @override
  String get report_stateHint => '输入州或省';

  @override
  String get report_postalCode => '邮政编码';

  @override
  String get report_postalCodeHint => '输入邮政编码';

  @override
  String get report_country => '国家';

  @override
  String get report_countryHint => '输入国家';

  @override
  String get report_useManualAddress => '手动输入地址';

  @override
  String get report_useGPS => '使用GPS定位';

  @override
  String get report_refreshLocation => '刷新位置';

  @override
  String get report_openSettings => '打开设置';

  @override
  String get report_manualReport => '手动报告';

  @override
  String get report_takePhoto => '拍照';

  @override
  String get report_chooseFromGallery => '从相册选择';

  @override
  String get report_locationNotSet => '未设置位置';

  @override
  String get report_accuracyExcellent => '优秀';

  @override
  String get report_accuracyGood => '良好';

  @override
  String get report_accuracyFair => '一般';

  @override
  String get report_accuracyPoor => '较差';

  @override
  String get report_locationPermissionDenied => '位置权限被拒绝';

  @override
  String get report_locationPermissionDeniedMessage => '请在设置中启用位置权限以使用GPS功能。';

  @override
  String get report_locationServiceDisabled => '位置服务已禁用';

  @override
  String get report_locationServiceDisabledMessage => '请启用位置服务以使用GPS功能。';

  @override
  String get report_gettingLocation => '正在获取位置...';

  @override
  String get report_editAddress => '编辑地址';

  @override
  String get report_enterAddress => '输入地址';

  @override
  String get report_searchingAddress => '正在搜索地址...';

  @override
  String get report_addressNotFound => '未找到地址';

  @override
  String get report_invalidAddress => '请输入有效的地址';

  @override
  String get report_addressSearchHint => '输入完整地址，我们将为您找到坐标';

  @override
  String get report_filterByStatus => '按状态筛选';

  @override
  String get report_reportsFound => '个报告';

  @override
  String get report_filter => '筛选';

  @override
  String get report_sort => '排序';

  @override
  String get report_reportDetails => '报告详情';

  @override
  String get report_mainPhoto => '主要照片';

  @override
  String get report_noIssueTypes => '未选择问题类型';

  @override
  String get report_coordinates => '坐标';

  @override
  String get report_severity => '严重程度';

  @override
  String get report_severityMinor => '轻微';

  @override
  String get report_severityLow => '低';

  @override
  String get report_severityModerate => '中等';

  @override
  String get report_severityHigh => '高';

  @override
  String get report_severityCritical => '严重';

  @override
  String get report_verify => '验证';

  @override
  String get report_verifyReport => '验证报告';

  @override
  String get report_verifyReportMessage => '您确定要验证此报告为合法吗？';

  @override
  String get report_verifySuccess => '报告验证成功';

  @override
  String get report_verifyFailed => '验证报告失败';

  @override
  String get report_markSpam => '标记为垃圾';

  @override
  String get report_markAsSpam => '标记为垃圾';

  @override
  String get report_markAsSpamMessage => '您确定要将此报告标记为垃圾吗？此操作无法撤消。';

  @override
  String get report_spamSuccess => '报告已标记为垃圾';

  @override
  String get report_spamFailed => '标记报告为垃圾失败';

  @override
  String get settings_requestAuthorityDialog => '申请权限角色';

  @override
  String get settings_requestAuthorityDesc => '填写以下表格以申请权限角色。标有 * 的字段为必填项。';

  @override
  String get settings_idNumber => '身份证号码';

  @override
  String get settings_idNumberHint => '输入您的身份证号码';

  @override
  String get settings_idNumberRequired => '身份证号码为必填项';

  @override
  String get settings_organization => '组织机构';

  @override
  String get settings_organizationHint => '输入您的组织机构名称';

  @override
  String get settings_organizationRequired => '组织机构为必填项';

  @override
  String get settings_location => '地区';

  @override
  String get settings_locationHint => '选择您的地区';

  @override
  String get settings_locationRequired => '地区为必填项';

  @override
  String get settings_referrerCode => '推荐码';

  @override
  String get settings_referrerCodeHint => '输入6位推荐码（可选）';

  @override
  String get settings_referrerCodeInvalid => '推荐码必须为6位数字';

  @override
  String get settings_remarks => '备注';

  @override
  String get settings_remarksHint => '附加信息（可选）';

  @override
  String get settings_requestSubmitted => '申请提交成功';

  @override
  String get settings_requestSubmittedDesc => '您的权限角色申请已提交审核。处理完成后将通知您。';

  @override
  String get settings_requestFailed => '提交申请失败';

  @override
  String get settings_hasPendingRequest => '您已有待处理的申请';

  @override
  String get location_johor => '柔佛';

  @override
  String get location_kedah => '吉打';

  @override
  String get location_kelantan => '吉兰丹';

  @override
  String get location_malacca => '马六甲';

  @override
  String get location_negeriSembilan => '森美兰';

  @override
  String get location_pahang => '彭亨';

  @override
  String get location_penang => '槟城';

  @override
  String get location_perak => '霹雳';

  @override
  String get location_perlis => '玻璃市';

  @override
  String get location_sabah => '沙巴';

  @override
  String get location_sarawak => '砂拉越';

  @override
  String get location_selangor => '雪兰莪';

  @override
  String get location_terengganu => '登嘉楼';

  @override
  String get location_kualaLumpur => '吉隆坡';

  @override
  String get location_labuan => '纳闽';

  @override
  String get location_putrajaya => '布城';

  @override
  String get settings_requestPending => '申请处理中';

  @override
  String get settings_statusPending => '申请审核中';

  @override
  String get settings_statusPendingDesc => '您的权限申请正在由管理员审核中';

  @override
  String get settings_statusApproved => '申请已批准';

  @override
  String get settings_statusApprovedDesc => '您的权限申请已获批准';

  @override
  String get settings_statusRejected => '申请被拒绝';

  @override
  String get settings_statusRejectedDesc => '您的权限申请未获批准。您可以提交新的申请';

  @override
  String get profile_viewProfile => '查看您的个人资料';

  @override
  String get requests_managementTitle => '申请管理';

  @override
  String get requests_managementSubtitle => '查看和管理权限申请';

  @override
  String get requests_tabAll => '全部';

  @override
  String get requests_tabPending => '待处理';

  @override
  String get requests_tabApproved => '已批准';

  @override
  String get requests_tabRejected => '已拒绝';

  @override
  String get requests_noRequests => '未找到申请';

  @override
  String get requests_userId => '用户ID';

  @override
  String get requests_detailTitle => '申请详情';

  @override
  String get requests_requestInfo => '申请信息';

  @override
  String get requests_userInfo => '用户信息';

  @override
  String get requests_reviewInfo => '审核信息';

  @override
  String get requests_createdAt => '创建时间';

  @override
  String get requests_reviewedBy => '审核人';

  @override
  String get requests_reviewedAt => '审核时间';

  @override
  String get requests_reviewComment => '审核意见';

  @override
  String get requests_reviewCommentHint => '给申请人的可选意见';

  @override
  String get requests_reviewAction => '审核操作';

  @override
  String get requests_approve => '批准';

  @override
  String get requests_reject => '拒绝';

  @override
  String get requests_confirmApprove => '确认批准';

  @override
  String get requests_confirmApproveMessage => '您确定要批准此权限申请吗？';

  @override
  String get requests_confirmReject => '确认拒绝';

  @override
  String get requests_confirmRejectMessage => '您确定要拒绝此权限申请吗？';

  @override
  String get requests_approveSuccess => '申请批准成功';

  @override
  String get requests_rejectSuccess => '申请拒绝成功';

  @override
  String get common_copied => '已复制到剪贴板';

  @override
  String get reputation_history => '信誉记录';

  @override
  String get reputation_noHistory => '暂无信誉记录';

  @override
  String get reputation_loadError => '加载信誉记录失败';

  @override
  String get reputation_uploadIssue => '提交报告';

  @override
  String get reputation_issueReviewed => '报告已验证';

  @override
  String get reputation_authorityRejected => '报告被拒绝';

  @override
  String get reputation_issueSpam => '报告被标记为垃圾';

  @override
  String get reputation_insufficientTitle => '信誉不足';

  @override
  String get reputation_insufficientMessage =>
      '您的信誉分数低于40分。您需要保持良好的信誉才能创建报告。请通过积极为社区做出贡献来提高您的信誉。';

  @override
  String get reputation_insufficientAuthorityMessage =>
      '您的信誉分数低于40分。您需要保持良好的信誉才能申请权限角色。请通过提交高质量的报告来提高您的信誉。';

  @override
  String get reputation_title => '信誉分数';

  @override
  String get reputation_currentScore => '当前分数';

  @override
  String get reputation_statusExcellent => '优秀';

  @override
  String get reputation_statusGood => '良好';

  @override
  String get reputation_statusLow => '较低';

  @override
  String get reputation_advice => '提示与建议';

  @override
  String get reputation_adviceExcellent => '做得很好！您的信誉非常优秀。继续提交高质量的报告以保持您的良好声誉。';

  @override
  String get reputation_adviceGood => '您做得不错！继续提交高质量的报告以提高您的信誉。';

  @override
  String get reputation_adviceLow => '您的信誉较低。专注于提交高质量的报告以提高您的声誉并恢复完全访问权限。';

  @override
  String get reputation_howToIncrease => '如何增加分数：';

  @override
  String get reputation_increaseUpload => '每提交一份报告 +1 分';

  @override
  String get reputation_increaseReviewed => '报告被权限用户验证 +5 分';

  @override
  String get reputation_howToDecrease => '什么会降低分数：';

  @override
  String get reputation_decreaseRejected => '报告被拒绝 -10 分';

  @override
  String get reputation_decreaseSpam => '报告被标记为垃圾 -15 分';

  @override
  String get reputation_recentActivity => '最近活动';

  @override
  String reputation_recentTrend(int change) {
    return '最近趋势：$change 分';
  }

  @override
  String get reputation_maxReached => '您已达到最高信誉！您的贡献仍会被记录和感谢。';

  @override
  String get reputation_actionUploadIssue => '提交报告';

  @override
  String get reputation_actionFirstReporter => '首位报告者';

  @override
  String get reputation_actionDuplicateReport => '重复报告';

  @override
  String get reputation_actionAbuseReport => '系统滥用';

  @override
  String get reputation_actionManualAdjustment => '手动调整';

  @override
  String get reputation_actionOthers => '其他操作';

  @override
  String get report_sortLatest => '最新';

  @override
  String get report_sortPriority => '优先级';

  @override
  String get report_sortLatestFirst => '最新优先';

  @override
  String get report_sortByPriority => '按优先级';

  @override
  String get report_filterDraft => '草稿';

  @override
  String get report_filterSubmitted => '已提交';

  @override
  String get report_search => '搜索';

  @override
  String get report_viewGrid => '网格视图';

  @override
  String get report_viewList => '列表视图';

  @override
  String get report_reachedEnd => '已到达底部';

  @override
  String get report_noMoreReports => '没有更多报告了';

  @override
  String get report_aiAnalysis => 'AI 分析结果';

  @override
  String get report_confidence => '置信水平';

  @override
  String get report_confidenceHigh => '高';

  @override
  String get report_confidenceMedium => '中';

  @override
  String get report_confidenceLow => '低';

  @override
  String get report_suggestedIssueTypes => '建议的问题类型';

  @override
  String get report_suggestedSeverity => '建议的严重程度';

  @override
  String get report_applySuggestions => '应用建议';

  @override
  String get report_noDescription => '无描述';

  @override
  String get report_reportSubmittedMessageNew => '您的道路安全报告已成功提交。感谢您为社区安全做出贡献！';

  @override
  String get iconPicker_title => '选择图标';

  @override
  String get iconPicker_searchHint => '搜索图标...';

  @override
  String get iconPicker_selectIcon => '选择图标';

  @override
  String get iconPicker_icon => '图标';

  @override
  String get report_searchReports => '搜索报告...';

  @override
  String get report_searchByTitleLocation => '按标题、位置或描述搜索';

  @override
  String get report_noResultsFound => '未找到结果';

  @override
  String get report_tryDifferentKeywords => '尝试不同的关键词';

  @override
  String get reportDetail_title => '报告详情';

  @override
  String get reportDetail_photos => '照片';

  @override
  String get reportDetail_noPhotos => '无可用照片';

  @override
  String get reportDetail_swipePhotos => '滑动查看更多照片';

  @override
  String reportDetail_loadingPhoto(int current, int total) {
    return '正在加载照片 $current/$total';
  }

  @override
  String get reportDetail_failedToLoad => '加载照片失败';

  @override
  String get reportDetail_noLocation => '无位置信息';

  @override
  String get reportDetail_coordinates => '坐标';

  @override
  String get reportDetail_noIssueTypes => '未选择问题类型';

  @override
  String get reportDetail_severity => '严重程度';

  @override
  String get reportDetail_severityMinor => '轻微问题 - 低优先级';

  @override
  String get reportDetail_severityLow => '低严重程度 - 可稍后处理';

  @override
  String get reportDetail_severityModerate => '中等严重程度 - 需要关注';

  @override
  String get reportDetail_severityHigh => '高严重程度 - 需要及时处理';

  @override
  String get reportDetail_severityCritical => '严重 - 需要立即处理';

  @override
  String get reportDetail_severityUnspecified => '未指定严重程度';

  @override
  String get reportDetail_noDescription => '未提供描述';

  @override
  String get reportDetail_communityVotes => '社区投票';

  @override
  String get reportDetail_verified => '已验证';

  @override
  String get reportDetail_spam => '垃圾信息';

  @override
  String get reportDetail_markSpam => '标记为垃圾';

  @override
  String get reportDetail_verify => '验证';

  @override
  String get reportDetail_reportVerified => '报告已验证';

  @override
  String get reportDetail_verificationRemoved => '已移除验证';

  @override
  String get reportDetail_markedAsSpam => '已标记为垃圾';

  @override
  String get reportDetail_spamVoteRemoved => '已移除垃圾投票';

  @override
  String reportDetail_failedToVote(String error) {
    return '投票失败：$error';
  }

  @override
  String get reportDetail_verifyReport => '验证报告';

  @override
  String get reportDetail_verifyReportConfirm =>
      '您确定要验证此报告为合法吗？这将把报告状态标记为\"已审核\"。';

  @override
  String get reportDetail_markAsSpam => '标记为垃圾';

  @override
  String get reportDetail_markAsSpamConfirm =>
      '您确定要将此报告标记为垃圾吗？这将把报告状态更改为\"垃圾\"。';

  @override
  String get reportDetail_reportVerifiedSuccess => '报告验证成功';

  @override
  String get reportDetail_reportMarkedSpam => '报告已标记为垃圾';

  @override
  String reportDetail_failedToVerify(String error) {
    return '验证报告失败：$error';
  }

  @override
  String reportDetail_failedToMarkSpam(String error) {
    return '标记为垃圾失败：$error';
  }

  @override
  String get reportDetail_verifyReportButton => '验证报告';

  @override
  String get reportDetail_markedAsSpamButton => '已标记为垃圾';

  @override
  String reportDetail_reportId(String id) {
    return '报告ID：$id';
  }

  @override
  String get common_untitled => '无标题';

  @override
  String get status_draft => '草稿';

  @override
  String get status_submitted => '已提交';

  @override
  String get status_reviewed => '已审核';

  @override
  String get status_spam => '垃圾信息';

  @override
  String get reportDetail_communityBelievesLegit => '社区认为这是合法的';

  @override
  String get reportDetail_communitySuspectsSpam => '社区怀疑这可能是垃圾信息';

  @override
  String get common_pleaseWait => '请稍候，正在处理...';

  @override
  String get savedRoute_title => '保存的路线';

  @override
  String get savedRoute_addRoute => '添加路线';

  @override
  String get savedRoute_editRoute => '编辑路线';

  @override
  String get savedRoute_routeName => '路线名称';

  @override
  String get savedRoute_routeNameHint => '例如：家到公司';

  @override
  String get savedRoute_from => '起点';

  @override
  String get savedRoute_to => '终点';

  @override
  String get savedRoute_selectLocation => '选择位置';

  @override
  String get savedRoute_useCurrentLocation => '使用当前位置';

  @override
  String get savedRoute_useSavedLocation => '使用保存的位置';

  @override
  String get savedRoute_monitoring => '监控中';

  @override
  String get savedRoute_monitoringDesc => '在此路线上时接收警报';

  @override
  String get savedRoute_distance => '距离';

  @override
  String get savedRoute_noRoutes => '没有保存的路线';

  @override
  String get savedRoute_noRoutesDesc => '创建路线以在常用路径上接收警报';

  @override
  String get savedRoute_deleteRoute => '删除路线';

  @override
  String get savedRoute_deleteConfirm => '您确定要删除此路线吗？';

  @override
  String get savedRoute_routeCreated => '路线创建成功';

  @override
  String get savedRoute_routeUpdated => '路线更新成功';

  @override
  String get savedRoute_routeDeleted => '路线已删除';

  @override
  String get savedRoute_monitoringEnabled => '已为此路线启用监控';

  @override
  String get savedRoute_monitoringDisabled => '已为此路线禁用监控';

  @override
  String get savedLocation_title => '保存的位置';

  @override
  String get savedLocation_addLocation => '添加位置';

  @override
  String get savedLocation_editLocation => '编辑位置';

  @override
  String get savedLocation_label => '标签';

  @override
  String get savedLocation_labelHint => '例如：家、公司、学校';

  @override
  String get savedLocation_locationName => '位置名称';

  @override
  String get savedLocation_locationNameHint => '输入位置名称';

  @override
  String get savedLocation_address => '地址';

  @override
  String get savedLocation_noLocations => '没有保存的位置';

  @override
  String get savedLocation_noLocationsDesc => '保存常去的地方以便快速访问';

  @override
  String get savedLocation_deleteLocation => '删除位置';

  @override
  String get savedLocation_deleteConfirm => '您确定要删除此位置吗？';

  @override
  String get savedLocation_locationSaved => '位置保存成功';

  @override
  String get savedLocation_locationDeleted => '位置已删除';

  @override
  String get savedLocation_home => '家';

  @override
  String get savedLocation_work => '公司';

  @override
  String get savedLocation_school => '学校';

  @override
  String get savedLocation_getDirections => '获取路线';

  @override
  String get common_nameRequired => '名称为必填项';

  @override
  String get common_locationRequired => '位置为必填项';

  @override
  String get savedLocation_searchLocation => '搜索位置';

  @override
  String get savedLocation_searchPlaceholder => '搜索地点...';

  @override
  String get savedLocation_fetchingAddress => '正在获取地址...';

  @override
  String get savedLocation_tapMapToSelect => '点击地图上的任意位置选择地点，或拖动标记进行调整';

  @override
  String get camera_autoDetectionEnabled => '自动检测已启用（每10秒）';

  @override
  String get camera_autoDetectionDisabled => '自动检测已禁用。使用拍摄按钮进行手动检测。';

  @override
  String get camera_analyzing => '分析中...（最多30秒）';

  @override
  String get camera_queuedDetections => '排队的检测';

  @override
  String get camera_retryQueue => '重试队列';

  @override
  String camera_queueProcessed(int count) {
    return '成功处理了 $count 个排队的检测';
  }

  @override
  String get camera_detectionTimeout => '检测时间过长。请重试。';

  @override
  String get camera_processingError => '处理图像时出错';

  @override
  String get camera_userNotAuthenticated => '用户未认证';

  @override
  String get camera_issueDetected => '检测到问题';

  @override
  String get camera_noIssueDetected => '未检测到问题';

  @override
  String get camera_viewHistory => '查看历史';

  @override
  String get camera_skippingAutoDetection => '跳过自动检测：上一次检测仍在处理中';

  @override
  String get report_editReport => '编辑报告';

  @override
  String get report_editTitle => '标题';

  @override
  String get report_editTitleHint => '输入报告标题';

  @override
  String get report_editTitleRequired => '标题为必填项';

  @override
  String get report_editDescriptionRequired => '描述为必填项';

  @override
  String get report_editAddressHint => '输入位置地址';

  @override
  String get report_editSeverity => '严重程度';

  @override
  String get report_editIssueTypes => '问题类型';

  @override
  String get report_editNoIssueTypes => '没有可用的问题类型';

  @override
  String get report_editSelectIssueType => '请至少选择一种问题类型';

  @override
  String get report_editSaveInfo => '更改将立即保存。您无法编辑位置坐标。';

  @override
  String get report_editUpdated => '报告更新成功';

  @override
  String report_editFailed(String error) {
    return '更新报告失败：$error';
  }

  @override
  String get report_actions => '报告操作';

  @override
  String get report_actionEdit => '编辑报告';

  @override
  String get report_actionEditDesc => '修改报告详情';

  @override
  String get report_actionShare => '分享报告';

  @override
  String get report_actionShareDesc => '通过消息应用分享';

  @override
  String get report_actionExportPDF => '导出为PDF';

  @override
  String get report_actionExportPDFDesc => '保存为PDF文档';

  @override
  String get report_actionDelete => '删除报告';

  @override
  String get report_actionDeleteDesc => '永久删除此报告';

  @override
  String get report_deleteConfirmTitle => '删除报告？';

  @override
  String get report_deleteConfirmMessage => '您确定要删除此报告吗？此操作无法撤销。';

  @override
  String get report_deleted => '报告删除成功';

  @override
  String report_deleteFailed(String error) {
    return '删除报告失败：$error';
  }

  @override
  String get report_generatingPDF => '正在生成PDF...';

  @override
  String get report_pdfExported => 'PDF导出成功';

  @override
  String report_pdfExportFailed(String error) {
    return '导出PDF失败：$error';
  }

  @override
  String report_shareFailed(String error) {
    return '分享报告失败：$error';
  }

  @override
  String get report_bulkOperations => '批量操作';

  @override
  String report_bulkSelected(int count) {
    return '已选择$count个报告';
  }

  @override
  String get report_bulkExportCSV => '导出为CSV';

  @override
  String get report_bulkExportCSVDesc => '导出所有选定的报告';

  @override
  String get report_bulkExportPDF => '导出为PDF';

  @override
  String get report_bulkExportPDFDesc => '为每个报告生成PDF';

  @override
  String get report_bulkDeleteAll => '全部删除';

  @override
  String get report_bulkDeleteAllDesc => '永久删除选定的报告';

  @override
  String get report_bulkProcessing => '处理中...';

  @override
  String report_bulkDeleteConfirmTitle(int count) {
    return '删除$count个报告？';
  }

  @override
  String get report_bulkDeleteConfirmMessage => '您确定要删除所有选定的报告吗？此操作无法撤销。';

  @override
  String get report_bulkCSVExported => 'CSV导出成功';

  @override
  String report_bulkCSVExportFailed(String error) {
    return '导出CSV失败：$error';
  }

  @override
  String report_bulkPDFsExported(int count) {
    return '$count个PDF导出成功';
  }

  @override
  String report_bulkPDFsExportFailed(String error) {
    return '导出PDF失败：$error';
  }

  @override
  String report_bulkDeleteSuccess(int success) {
    return '$success个报告删除成功';
  }

  @override
  String report_bulkDeletePartial(int success, int failed) {
    return '$success个已删除，$failed个失败';
  }

  @override
  String report_bulkDeleteFailed(String error) {
    return '删除报告失败：$error';
  }

  @override
  String get onboarding_getStarted => '开始使用';

  @override
  String get admin_title => '管理面板';

  @override
  String get admin_overview => '概览';

  @override
  String get admin_reports => '报告';

  @override
  String get admin_users => '用户';

  @override
  String get admin_totalReports => '总报告数';

  @override
  String get admin_totalUsers => '总用户数';

  @override
  String get admin_pendingReports => '待处理报告';

  @override
  String get admin_resolvedReports => '已解决报告';

  @override
  String get admin_approve => '批准';

  @override
  String get admin_reject => '拒绝';

  @override
  String get admin_resolve => '解决';

  @override
  String get admin_statusUpdated => '状态更新成功';

  @override
  String get admin_updateFailed => '更新状态失败';

  @override
  String get analytics_title => '分析仪表板';

  @override
  String get analytics_totalReports => '总报告数';

  @override
  String get analytics_resolved => '已解决';

  @override
  String get analytics_bySeverity => '按严重程度分类';

  @override
  String get analytics_byStatus => '按状态分类';

  @override
  String get analytics_byIssueType => '按问题类型分类';
}
