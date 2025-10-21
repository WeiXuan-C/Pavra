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
}
