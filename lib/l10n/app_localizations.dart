import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Pavra'**
  String get appName;

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Pavra'**
  String get appTitle;

  /// Common button text for OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// Common button text for Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Common button text for Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// Common button text for Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// Common button text for Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// Common button text for Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// Common button text for Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// Loading status message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// Common error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// Common success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// Common button text for Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// Common button text for Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// Common button text for Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// Common button text for Submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get common_submit;

  /// Welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pavra'**
  String get auth_welcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Report and track infrastructure issues in your community'**
  String get auth_welcomeSubtitle;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_emailLabel;

  /// Email input field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get auth_emailHint;

  /// Button to send OTP verification code
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get auth_sendOtp;

  /// OTP entry screen title
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get auth_otpTitle;

  /// OTP entry screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code sent to'**
  String get auth_otpSubtitle;

  /// OTP input field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get auth_otpHint;

  /// Button to verify OTP code
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get auth_verify;

  /// Button to resend verification code
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get auth_resendCode;

  /// Error message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get auth_invalidEmail;

  /// Error message for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get auth_invalidOtp;

  /// Success message when OTP is sent
  ///
  /// In en, this message translates to:
  /// **'Verification code sent successfully'**
  String get auth_otpSent;

  /// Error message when OTP sending fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code'**
  String get auth_otpFailed;

  /// Error message when verification fails
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get auth_verifyFailed;

  /// Button to sign in with Google
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get auth_signInWithGoogle;

  /// Button to sign in with Github
  ///
  /// In en, this message translates to:
  /// **'Sign in with Github'**
  String get auth_signInWithGithub;

  /// Button to sign in with Facebook
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get auth_signInWithFacebook;

  /// Button to sign in with Discord
  ///
  /// In en, this message translates to:
  /// **'Sign in with Discord'**
  String get auth_signInWithDiscord;

  /// Text separator for alternative sign in methods
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get auth_orContinueWith;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// Message when no user is logged in
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get home_noUserLoggedIn;

  /// Account information section title
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get home_accountInfo;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get home_email;

  /// Last updated timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get home_lastUpdated;

  /// Appearance settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get home_appearance;

  /// Theme mode setting label
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get home_themeMode;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get home_language;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get home_themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get home_themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get home_themeDark;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get home_logout;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get home_confirmLogout;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get home_confirmLogoutMessage;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get home_user;

  /// Message when user has no email
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get home_noEmail;

  /// User ID label
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get home_userId;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get home_settings;

  /// Camera detection screen title
  ///
  /// In en, this message translates to:
  /// **'Camera Detection'**
  String get camera_title;

  /// Button to start detection
  ///
  /// In en, this message translates to:
  /// **'Start Detection'**
  String get camera_startDetection;

  /// Button to stop detection
  ///
  /// In en, this message translates to:
  /// **'Stop Detection'**
  String get camera_stopDetection;

  /// Button to capture image
  ///
  /// In en, this message translates to:
  /// **'Capture Image'**
  String get camera_captureImage;

  /// Button to switch between cameras
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get camera_switchCamera;

  /// Detection history section title
  ///
  /// In en, this message translates to:
  /// **'Detection History'**
  String get camera_detectionHistory;

  /// Detection metrics section title
  ///
  /// In en, this message translates to:
  /// **'Detection Metrics'**
  String get camera_detectionMetrics;

  /// Detection confidence label
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get camera_confidence;

  /// Status message during detection
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get camera_detecting;

  /// Message when no detections are available
  ///
  /// In en, this message translates to:
  /// **'No detections yet'**
  String get camera_noDetection;

  /// GPS status label
  ///
  /// In en, this message translates to:
  /// **'GPS Status'**
  String get camera_gpsStatus;

  /// AI detection feature label
  ///
  /// In en, this message translates to:
  /// **'AI Detection'**
  String get camera_aiDetection;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get camera_disabled;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get camera_active;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get camera_inactive;

  /// Camera initialization status message
  ///
  /// In en, this message translates to:
  /// **'Initializing Camera...'**
  String get camera_initializingCamera;

  /// Message when AI detection is active
  ///
  /// In en, this message translates to:
  /// **'AI Detection Active'**
  String get camera_aiDetectionActive;

  /// Detection analytics section title
  ///
  /// In en, this message translates to:
  /// **'Detection Analytics'**
  String get camera_detectionAnalytics;

  /// Message when no detection data is available
  ///
  /// In en, this message translates to:
  /// **'No detection data available'**
  String get camera_noDataAvailable;

  /// Detection distribution chart label
  ///
  /// In en, this message translates to:
  /// **'Detection Distribution'**
  String get camera_detectionDistribution;

  /// Confidence metrics section label
  ///
  /// In en, this message translates to:
  /// **'Confidence Metrics'**
  String get camera_confidenceMetrics;

  /// Recent activity section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get camera_recentActivity;

  /// Word 'detected' used in detection messages
  ///
  /// In en, this message translates to:
  /// **'detected'**
  String get camera_detected;

  /// Recent detections section title
  ///
  /// In en, this message translates to:
  /// **'Recent Detections'**
  String get camera_recentDetections;

  /// Message when no detections have been made
  ///
  /// In en, this message translates to:
  /// **'No Detections Yet'**
  String get camera_noDetectionsYet;

  /// Prompt to start scanning for road issues
  ///
  /// In en, this message translates to:
  /// **'Start scanning to detect road issues'**
  String get camera_startScanning;

  /// Camera flash control label
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get camera_flash;

  /// Burst mode camera feature label
  ///
  /// In en, this message translates to:
  /// **'Burst Mode'**
  String get camera_burstMode;

  /// Gallery button label
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get camera_gallery;

  /// Word 'captured' used in capture messages
  ///
  /// In en, this message translates to:
  /// **'captured'**
  String get camera_captured;

  /// Error message when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get camera_errorPermissionDenied;

  /// Error message when camera initialization fails
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize camera'**
  String get camera_errorCameraFailed;

  /// Total detections count label
  ///
  /// In en, this message translates to:
  /// **'Total Detections'**
  String get camera_totalDetections;

  /// Potholes detection type label
  ///
  /// In en, this message translates to:
  /// **'Potholes'**
  String get camera_potholes;

  /// Cracks detection type label
  ///
  /// In en, this message translates to:
  /// **'Cracks'**
  String get camera_cracks;

  /// Label for obstacles detected by the camera
  ///
  /// In en, this message translates to:
  /// **'Obstacles'**
  String get camera_obstacles;

  /// Average confidence metric label
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get camera_average;

  /// Highest confidence metric label
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get camera_highest;

  /// Lowest confidence metric label
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get camera_lowest;

  /// Timestamp for very recent detections
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get camera_justNow;

  /// Success message when photo is captured
  ///
  /// In en, this message translates to:
  /// **'Photo captured successfully'**
  String get camera_photoCaptured;

  /// Success message when image is processed
  ///
  /// In en, this message translates to:
  /// **'Image processed successfully'**
  String get camera_imageProcessed;

  /// Message when burst mode is activated
  ///
  /// In en, this message translates to:
  /// **'Burst mode activated'**
  String get camera_burstModeActivated;

  /// Message when burst mode is deactivated
  ///
  /// In en, this message translates to:
  /// **'Burst mode deactivated'**
  String get camera_burstModeDeactivated;

  /// Detection details dialog title
  ///
  /// In en, this message translates to:
  /// **'Detection Details'**
  String get camera_detectionDetails;

  /// Detection type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get camera_type;

  /// Detection location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get camera_location;

  /// Detection time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get camera_time;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get camera_close;

  /// Submit report button text
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get camera_submitReport;

  /// Burst mode active indicator
  ///
  /// In en, this message translates to:
  /// **'Burst Mode Active'**
  String get camera_burstModeActive;

  /// Instructions for normal capture mode
  ///
  /// In en, this message translates to:
  /// **'Tap to capture • Long press for burst mode'**
  String get camera_captureInstructions;

  /// Instructions for burst mode
  ///
  /// In en, this message translates to:
  /// **'{burstMode} • Tap to capture • Long press to exit'**
  String camera_burstModeInstructions(String burstMode);

  /// Timestamp for very recent activity
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get time_justNow;

  /// Timestamp for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String time_minutesAgo(int minutes);

  /// Timestamp for hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String time_hoursAgo(int hours);

  /// Timestamp for days ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String time_daysAgo(int days);

  /// Map view screen title
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get map_title;

  /// Search input hint text
  ///
  /// In en, this message translates to:
  /// **'Search location...'**
  String get map_searchHint;

  /// Filter dialog title
  ///
  /// In en, this message translates to:
  /// **'Filter Issues'**
  String get map_filterTitle;

  /// Nearby issues section title
  ///
  /// In en, this message translates to:
  /// **'Nearby Issues'**
  String get map_nearbyIssues;

  /// Issue details dialog title
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get map_issueDetails;

  /// Reporter label
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get map_reportedBy;

  /// Severity level label
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get map_severity;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get map_status;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get map_distance;

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get map_viewDetails;

  /// Message when no issues are found
  ///
  /// In en, this message translates to:
  /// **'No issues found nearby'**
  String get map_noIssuesFound;

  /// Hint to adjust location
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your location or zoom level'**
  String get map_adjustLocation;

  /// Word 'found' in count messages
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get map_found;

  /// Search suggestions section title
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get map_suggestions;

  /// Recent searches section title
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get map_recentSearches;

  /// Issue types filter section
  ///
  /// In en, this message translates to:
  /// **'Issue Types'**
  String get map_issueTypes;

  /// Severity levels filter section
  ///
  /// In en, this message translates to:
  /// **'Severity Levels'**
  String get map_severityLevels;

  /// Clear all filters button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get map_clearAll;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get map_applyFilters;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get map_description;

  /// Directions button text
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get map_directions;

  /// Report similar issue button
  ///
  /// In en, this message translates to:
  /// **'Report Similar'**
  String get map_reportSimilar;

  /// Prompt to create report
  ///
  /// In en, this message translates to:
  /// **'Create a new road safety report at this location?'**
  String get map_reportIssuePrompt;

  /// Reported status
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get map_reported;

  /// Distance away suffix
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get map_away;

  /// Report issue screen title
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get report_title;

  /// Issue type field label
  ///
  /// In en, this message translates to:
  /// **'Issue Type'**
  String get report_issueType;

  /// Issue type selection prompt
  ///
  /// In en, this message translates to:
  /// **'Select Issue Type'**
  String get report_selectIssueType;

  /// Pothole issue type option
  ///
  /// In en, this message translates to:
  /// **'Pothole'**
  String get report_pothole;

  /// Crack issue type option
  ///
  /// In en, this message translates to:
  /// **'Crack'**
  String get report_crack;

  /// Flooding issue type option
  ///
  /// In en, this message translates to:
  /// **'Flooding'**
  String get report_flooding;

  /// Lighting issue type option
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get report_lighting;

  /// Other issue type option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get report_other;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get report_description;

  /// Description field hint text
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail...'**
  String get report_descriptionHint;

  /// Photos section label
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get report_photos;

  /// Add photo button text
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get report_addPhoto;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get report_location;

  /// Button to use current location
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get report_useCurrentLocation;

  /// Severity level field label
  ///
  /// In en, this message translates to:
  /// **'Severity Level'**
  String get report_severityLevel;

  /// Low severity option
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get report_low;

  /// Medium severity option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get report_medium;

  /// High severity option
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get report_high;

  /// Submit report button text
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get report_submitReport;

  /// Submitting status message
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get report_submitting;

  /// Success message after report submission
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get report_success;

  /// Error message when report submission fails
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get report_failed;

  /// Location information section title
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get report_locationInfo;

  /// Latitude label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get report_latitude;

  /// Longitude label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get report_longitude;

  /// Save as draft button
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get report_saveDraft;

  /// Submitting report status
  ///
  /// In en, this message translates to:
  /// **'Submitting Report...'**
  String get report_submittingReport;

  /// Warning to select issue type
  ///
  /// In en, this message translates to:
  /// **'Please select at least one issue type to submit the report'**
  String get report_selectIssueTypeWarning;

  /// Uploading report status
  ///
  /// In en, this message translates to:
  /// **'Uploading report...'**
  String get report_uploadingReport;

  /// Syncing with cloud message
  ///
  /// In en, this message translates to:
  /// **'Syncing with cloud servers...'**
  String get report_syncingCloud;

  /// Severity rating instruction
  ///
  /// In en, this message translates to:
  /// **'Rate the severity of the road issue'**
  String get report_rateSeverity;

  /// Additional photos section title
  ///
  /// In en, this message translates to:
  /// **'Additional Photos'**
  String get report_additionalPhotos;

  /// Hint for adding photos
  ///
  /// In en, this message translates to:
  /// **'Add multiple angles or close-up shots of the issue'**
  String get report_addPhotoHint;

  /// Photos left suffix
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get report_photosLeft;

  /// No photos message
  ///
  /// In en, this message translates to:
  /// **'No additional photos'**
  String get report_noAdditionalPhotos;

  /// Tap to add photos prompt
  ///
  /// In en, this message translates to:
  /// **'Tap to add photos'**
  String get report_tapToAddPhotos;

  /// Location details section title
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get report_locationDetails;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get report_address;

  /// GPS accuracy label
  ///
  /// In en, this message translates to:
  /// **'GPS Accuracy'**
  String get report_gpsAccuracy;

  /// Safety alerts screen title
  ///
  /// In en, this message translates to:
  /// **'Safety Alerts'**
  String get alerts_title;

  /// Enable alerts toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Alerts'**
  String get alerts_enableAlerts;

  /// Alert radius setting label
  ///
  /// In en, this message translates to:
  /// **'Alert Radius'**
  String get alerts_alertRadius;

  /// Route monitoring feature label
  ///
  /// In en, this message translates to:
  /// **'Route Monitoring'**
  String get alerts_routeMonitoring;

  /// Message when no alerts are nearby
  ///
  /// In en, this message translates to:
  /// **'No safety alerts nearby'**
  String get alerts_noAlerts;

  /// View on map button text
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get alerts_viewOnMap;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get alerts_distance;

  /// Active alerts tab label
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get alerts_activeAlerts;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get alerts_settings;

  /// Routes tab label
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get alerts_routes;

  /// Alert types section title
  ///
  /// In en, this message translates to:
  /// **'Alert Types'**
  String get alerts_alertTypes;

  /// Road damage alert type
  ///
  /// In en, this message translates to:
  /// **'Road Damage'**
  String get alerts_roadDamage;

  /// Construction zones alert type
  ///
  /// In en, this message translates to:
  /// **'Construction Zones'**
  String get alerts_constructionZones;

  /// Weather hazards alert type
  ///
  /// In en, this message translates to:
  /// **'Weather Hazards'**
  String get alerts_weatherHazards;

  /// Traffic incidents alert type
  ///
  /// In en, this message translates to:
  /// **'Traffic Incidents'**
  String get alerts_trafficIncidents;

  /// Location settings section title
  ///
  /// In en, this message translates to:
  /// **'Location Settings'**
  String get alerts_locationSettings;

  /// Coverage preview section title
  ///
  /// In en, this message translates to:
  /// **'Coverage Preview'**
  String get alerts_coveragePreview;

  /// Saved routes section title
  ///
  /// In en, this message translates to:
  /// **'Saved Routes'**
  String get alerts_savedRoutes;

  /// Add route button text
  ///
  /// In en, this message translates to:
  /// **'Add Route'**
  String get alerts_addRoute;

  /// All clear message
  ///
  /// In en, this message translates to:
  /// **'All Clear!'**
  String get alerts_allClear;

  /// No alerts detailed message
  ///
  /// In en, this message translates to:
  /// **'No safety alerts in your area right now. We\'ll notify you immediately if any road hazards are reported nearby.'**
  String get alerts_noAlertsMessage;

  /// Check for updates button
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get alerts_checkForUpdates;

  /// Checking status
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get alerts_checking;

  /// Alerts updated message
  ///
  /// In en, this message translates to:
  /// **'Safety alerts updated'**
  String get alerts_updated;

  /// Alert acknowledged message
  ///
  /// In en, this message translates to:
  /// **'Alert marked as acknowledged'**
  String get alerts_acknowledged;

  /// Undo action text
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get alerts_undo;

  /// Notification settings title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get alerts_notificationSettings;

  /// Sound alerts setting
  ///
  /// In en, this message translates to:
  /// **'Sound Alerts'**
  String get alerts_soundAlerts;

  /// Sound alerts description
  ///
  /// In en, this message translates to:
  /// **'Play notification sounds for critical alerts'**
  String get alerts_soundAlertsDesc;

  /// Vibration setting
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get alerts_vibration;

  /// Vibration description
  ///
  /// In en, this message translates to:
  /// **'Vibrate device for high priority alerts'**
  String get alerts_vibrationDesc;

  /// Do not disturb setting
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get alerts_doNotDisturb;

  /// Do not disturb description
  ///
  /// In en, this message translates to:
  /// **'Respect system do not disturb settings'**
  String get alerts_doNotDisturbDesc;

  /// Quiet hours setting
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get alerts_quietHours;

  /// Quiet hours description
  ///
  /// In en, this message translates to:
  /// **'Only critical safety alerts will be shown during quiet hours'**
  String get alerts_quietHoursDesc;

  /// Route monitoring information
  ///
  /// In en, this message translates to:
  /// **'Enable monitoring for your frequent routes to receive proactive alerts about road conditions, construction, and incidents along your path.'**
  String get alerts_routeMonitoringInfo;

  /// Critical severity level
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get alerts_critical;

  /// Report submitted dialog title
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get report_reportSubmitted;

  /// Report submitted success message
  ///
  /// In en, this message translates to:
  /// **'Your road safety report has been successfully submitted to the authorities.'**
  String get report_reportSubmittedMessage;

  /// Report ID label
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get report_reportId;

  /// Estimated response time
  ///
  /// In en, this message translates to:
  /// **'Estimated Response: 2-3 business days'**
  String get report_estimatedResponse;

  /// View on map button
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get report_viewOnMap;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get report_done;

  /// Unsaved changes dialog title
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get report_unsavedChanges;

  /// Unsaved changes message
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save as draft before leaving?'**
  String get report_unsavedChangesMessage;

  /// Discard button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get report_discard;

  /// Photo updated message
  ///
  /// In en, this message translates to:
  /// **'Photo updated successfully'**
  String get report_photoUpdated;

  /// Photo capture failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo'**
  String get report_photoCaptureFailed;

  /// Location updated message
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get report_locationUpdated;

  /// Photo added message
  ///
  /// In en, this message translates to:
  /// **'Photo added successfully'**
  String get report_photoAdded;

  /// Photo removed message
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get report_photoRemoved;

  /// Maximum photos warning
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 additional photos allowed'**
  String get report_maxPhotos;

  /// Photo add failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to add photo'**
  String get report_photoAddFailed;

  /// Draft saved message
  ///
  /// In en, this message translates to:
  /// **'Draft saved successfully'**
  String get report_draftSaved;

  /// Submit failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report. Please try again.'**
  String get report_submitFailed;

  /// Obstacle issue type
  ///
  /// In en, this message translates to:
  /// **'Obstacle'**
  String get report_obstacle;

  /// Navigation bar label for camera screen
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get nav_camera;

  /// Navigation bar label for map screen
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get nav_map;

  /// Navigation bar label for report screen
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get nav_report;

  /// Navigation bar label for alerts screen
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get nav_alerts;

  /// Navigation bar label for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get language_chinese;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// Push notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settings_pushNotifications;

  /// Push notifications description
  ///
  /// In en, this message translates to:
  /// **'Enable push notifications'**
  String get settings_pushNotificationsDesc;

  /// Alert types section title
  ///
  /// In en, this message translates to:
  /// **'Alert Types'**
  String get settings_alertTypes;

  /// Road damage notification type
  ///
  /// In en, this message translates to:
  /// **'Road Damage'**
  String get settings_roadDamage;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// Developer mode label
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get settings_developerMode;

  /// Exit developer mode button
  ///
  /// In en, this message translates to:
  /// **'Exit Developer Mode'**
  String get settings_exitDeveloperMode;

  /// Enter access code dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Access Code'**
  String get settings_enterAccessCode;

  /// Access code input hint
  ///
  /// In en, this message translates to:
  /// **'Enter access code'**
  String get settings_accessCodeHint;

  /// Incorrect access code error message
  ///
  /// In en, this message translates to:
  /// **'Incorrect access code'**
  String get settings_accessCodeIncorrect;

  /// Developer mode enabled success message
  ///
  /// In en, this message translates to:
  /// **'Developer mode enabled'**
  String get settings_developerModeEnabled;

  /// Developer mode disabled success message
  ///
  /// In en, this message translates to:
  /// **'Developer mode disabled'**
  String get settings_developerModeDisabled;

  /// Authority warning dialog title
  ///
  /// In en, this message translates to:
  /// **'Authority Warning'**
  String get settings_authorityWarning;

  /// Authority warning message
  ///
  /// In en, this message translates to:
  /// **'If you switch to developer mode, you can only switch back to regular user role. Your authority status will be permanently removed. Are you sure you want to continue?'**
  String get settings_authorityWarningMessage;

  /// Request authority role button
  ///
  /// In en, this message translates to:
  /// **'Request Authority Role'**
  String get settings_requestAuthority;

  /// Request authority success message
  ///
  /// In en, this message translates to:
  /// **'Your request to become an authority has been submitted for review.'**
  String get settings_requestAuthorityMessage;

  /// Request authority confirmation message
  ///
  /// In en, this message translates to:
  /// **'Submit a request to become an authority user? This request will be reviewed by administrators.'**
  String get settings_requestAuthorityConfirm;

  /// Exit developer mode confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit developer mode? You will be switched back to regular user role.'**
  String get settings_exitDeveloperModeMessage;

  /// App information section title
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get settings_appInformation;

  /// Username label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profile_username;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// Role label
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profile_role;

  /// User role label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profile_roleUser;

  /// Authority role label
  ///
  /// In en, this message translates to:
  /// **'Authority'**
  String get profile_roleAuthority;

  /// Developer role label
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get profile_roleDeveloper;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profile_statistics;

  /// Total reports label
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get profile_totalReports;

  /// Reputation label
  ///
  /// In en, this message translates to:
  /// **'Reputation'**
  String get profile_reputation;

  /// Road damage description
  ///
  /// In en, this message translates to:
  /// **'Potholes, cracks, and road surface issues'**
  String get settings_roadDamageDesc;

  /// Construction zones notification type
  ///
  /// In en, this message translates to:
  /// **'Construction Zones'**
  String get settings_constructionZones;

  /// Construction zones description
  ///
  /// In en, this message translates to:
  /// **'Road work and lane closures'**
  String get settings_constructionZonesDesc;

  /// Weather hazards notification type
  ///
  /// In en, this message translates to:
  /// **'Weather Hazards'**
  String get settings_weatherHazards;

  /// Weather hazards description
  ///
  /// In en, this message translates to:
  /// **'Fog, ice, and weather conditions'**
  String get settings_weatherHazardsDesc;

  /// Traffic incidents notification type
  ///
  /// In en, this message translates to:
  /// **'Traffic Incidents'**
  String get settings_trafficIncidents;

  /// Traffic incidents description
  ///
  /// In en, this message translates to:
  /// **'Accidents and traffic delays'**
  String get settings_trafficIncidentsDesc;

  /// Notification behavior section title
  ///
  /// In en, this message translates to:
  /// **'Notification Behavior'**
  String get settings_notificationBehavior;

  /// Sound setting label
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settings_sound;

  /// Sound setting description
  ///
  /// In en, this message translates to:
  /// **'Play sound for notifications'**
  String get settings_soundDesc;

  /// Vibration setting label
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settings_vibration;

  /// Vibration setting description
  ///
  /// In en, this message translates to:
  /// **'Vibrate for notifications'**
  String get settings_vibrationDesc;

  /// Miles unit (plural)
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get alerts_miles;

  /// Mile unit (singular)
  ///
  /// In en, this message translates to:
  /// **'mile'**
  String get alerts_mile;

  /// Route monitoring section title
  ///
  /// In en, this message translates to:
  /// **'Route Monitoring'**
  String get alerts_routeMonitoringTitle;

  /// Message when no routes are saved
  ///
  /// In en, this message translates to:
  /// **'No saved routes. Add frequent routes to monitor for alerts.'**
  String get alerts_noSavedRoutes;

  /// Minor severity level
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severity_minor;

  /// Low severity level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severity_low;

  /// Moderate severity level
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severity_moderate;

  /// High severity level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severity_high;

  /// Critical severity level
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severity_critical;

  /// Minor severity description
  ///
  /// In en, this message translates to:
  /// **'Minor inconvenience, no immediate danger'**
  String get severity_minorDesc;

  /// Low severity description
  ///
  /// In en, this message translates to:
  /// **'Slight discomfort, minimal impact'**
  String get severity_lowDesc;

  /// Moderate severity description
  ///
  /// In en, this message translates to:
  /// **'Noticeable issue, requires attention'**
  String get severity_moderateDesc;

  /// High severity description
  ///
  /// In en, this message translates to:
  /// **'Significant hazard, needs urgent repair'**
  String get severity_highDesc;

  /// Critical severity description
  ///
  /// In en, this message translates to:
  /// **'Extreme danger, immediate action required'**
  String get severity_criticalDesc;

  /// Description input placeholder text
  ///
  /// In en, this message translates to:
  /// **'Describe the road condition, traffic impact, or any other relevant details...'**
  String get report_descriptionPlaceholder;

  /// Optional field indicator
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get report_optional;

  /// Suggestions section title
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get report_suggestions;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification_title;

  /// Mark all notifications as read button
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notification_markAllAsRead;

  /// Delete all notifications button
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get notification_deleteAll;

  /// Success message when all notifications are marked as read
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notification_allMarkedAsRead;

  /// Success message when all notifications are deleted
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get notification_allDeleted;

  /// Error message when loading notifications fails
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get notification_errorLoading;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notification_empty;

  /// Empty state message
  ///
  /// In en, this message translates to:
  /// **'You\'ll see notifications here when you receive them'**
  String get notification_emptyMessage;

  /// Delete notification dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notification_delete;

  /// Delete notification confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get notification_deleteConfirm;

  /// Delete all notifications dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications'**
  String get notification_deleteAllTitle;

  /// Delete all notifications confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This action cannot be undone.'**
  String get notification_deleteAllConfirm;

  /// Success message when notification is deleted
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notification_deleted;

  /// Success notification type label
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get notification_typeSuccess;

  /// Warning notification type label
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get notification_typeWarning;

  /// Alert notification type label
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get notification_typeAlert;

  /// System notification type label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notification_typeSystem;

  /// User notification type label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get notification_typeUser;

  /// Report notification type label
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get notification_typeReport;

  /// Location notification type label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get notification_typeLocation;

  /// Status notification type label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get notification_typeStatus;

  /// Promotion notification type label
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get notification_typePromotion;

  /// Reminder notification type label
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notification_typeReminder;

  /// Info notification type label
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get notification_typeInfo;

  /// Create notification button and screen title
  ///
  /// In en, this message translates to:
  /// **'Create Notification'**
  String get notification_create;

  /// Edit notification screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Notification'**
  String get notification_edit;

  /// Notification title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notification_titleLabel;

  /// Notification title field hint
  ///
  /// In en, this message translates to:
  /// **'Enter notification title'**
  String get notification_titleHint;

  /// Title required validation message
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get notification_titleRequired;

  /// Title too long validation message
  ///
  /// In en, this message translates to:
  /// **'Title is too long (max 100 characters)'**
  String get notification_titleTooLong;

  /// Notification message field label
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notification_messageLabel;

  /// Notification message field hint
  ///
  /// In en, this message translates to:
  /// **'Enter notification message'**
  String get notification_messageHint;

  /// Message required validation message
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get notification_messageRequired;

  /// Message too long validation message
  ///
  /// In en, this message translates to:
  /// **'Message is too long (max 500 characters)'**
  String get notification_messageTooLong;

  /// Notification type field label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notification_typeLabel;

  /// Related action field label
  ///
  /// In en, this message translates to:
  /// **'Related Action (Optional)'**
  String get notification_relatedActionLabel;

  /// Related action field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., /reports/123'**
  String get notification_relatedActionHint;

  /// Preview section title
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get notification_preview;

  /// Update notification button text
  ///
  /// In en, this message translates to:
  /// **'Update Notification'**
  String get notification_update;

  /// Success message when notification is created
  ///
  /// In en, this message translates to:
  /// **'Notification created successfully'**
  String get notification_createSuccess;

  /// Error message when notification creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create notification'**
  String get notification_createError;

  /// Success message when notification is updated
  ///
  /// In en, this message translates to:
  /// **'Notification updated successfully'**
  String get notification_updateSuccess;

  /// Error message when notification update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update notification'**
  String get notification_updateError;

  /// Success type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get notification_type_success;

  /// Warning type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get notification_type_warning;

  /// Alert type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get notification_type_alert;

  /// System type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notification_type_system;

  /// User type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get notification_type_user;

  /// Report type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get notification_type_report;

  /// Location alert type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Location Alert'**
  String get notification_type_location_alert;

  /// Submission status type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Submission Status'**
  String get notification_type_submission_status;

  /// Promotion type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get notification_type_promotion;

  /// Reminder type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notification_type_reminder;

  /// Info type label in dropdown
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get notification_type_info;

  /// New report tab label
  ///
  /// In en, this message translates to:
  /// **'New Report'**
  String get report_newReport;

  /// My reports tab label
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get report_myReports;

  /// All reports tab label
  ///
  /// In en, this message translates to:
  /// **'All Reports'**
  String get report_allReports;

  /// No reports empty state title
  ///
  /// In en, this message translates to:
  /// **'No Reports'**
  String get report_noReports;

  /// No reports empty state message
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted any reports yet'**
  String get report_noReportsMessage;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get report_sortBy;

  /// Sort by date option
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get report_sortDate;

  /// Sort by severity option
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get report_sortSeverity;

  /// Sort by status option
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get report_sortStatus;

  /// My report badge
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get report_mine;

  /// Reported status label
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get report_statusReported;

  /// In progress status label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get report_statusInProgress;

  /// Resolved status label
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get report_statusResolved;

  /// View alerts button on map
  ///
  /// In en, this message translates to:
  /// **'View Alerts'**
  String get map_viewAlerts;

  /// Settings button on profile
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile_settings;

  /// Button to open camera detection screen
  ///
  /// In en, this message translates to:
  /// **'Open Camera Detection'**
  String get report_openCamera;

  /// Description for camera detection feature
  ///
  /// In en, this message translates to:
  /// **'AI detection ready to scan road issues'**
  String get report_aiDetectionReady;

  /// Quick report section title
  ///
  /// In en, this message translates to:
  /// **'Quick Report Road Issues'**
  String get report_quickReportTitle;

  /// Instruction text for report methods
  ///
  /// In en, this message translates to:
  /// **'Select a method below to start reporting'**
  String get report_selectMethodBelow;

  /// Report methods section title
  ///
  /// In en, this message translates to:
  /// **'Report Methods'**
  String get report_reportMethods;

  /// AI detection card title
  ///
  /// In en, this message translates to:
  /// **'AI Smart Detection'**
  String get report_aiSmartDetection;

  /// AI detection card subtitle
  ///
  /// In en, this message translates to:
  /// **'Use camera to automatically detect road issues'**
  String get report_useCameraAutoDetect;

  /// Manual report card title
  ///
  /// In en, this message translates to:
  /// **'Manual Report'**
  String get report_manualReport;

  /// Manual report card subtitle
  ///
  /// In en, this message translates to:
  /// **'Fill form to report'**
  String get report_fillFormReport;

  /// Gallery selection card title
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get report_selectFromGallery;

  /// Gallery selection card subtitle
  ///
  /// In en, this message translates to:
  /// **'AI analyze photo'**
  String get report_aiAnalyzePhoto;

  /// Stats section title
  ///
  /// In en, this message translates to:
  /// **'My Contribution'**
  String get report_myContribution;

  /// Total reports stat label
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get report_totalReports;

  /// Resolved reports stat label
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get report_resolved;

  /// In progress reports stat label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get report_inProgress;

  /// Recent reports section title
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get report_recentReports;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get report_viewAll;

  /// Filter menu subtitle for home
  ///
  /// In en, this message translates to:
  /// **'Quick report road issues'**
  String get report_filterMenuSubtitleHome;

  /// Filter menu subtitle for my reports
  ///
  /// In en, this message translates to:
  /// **'View my submitted reports'**
  String get report_filterMenuSubtitleMy;

  /// Filter menu subtitle for all reports
  ///
  /// In en, this message translates to:
  /// **'Browse all user reports'**
  String get report_filterMenuSubtitleAll;

  /// Filter tab label for all notifications
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notification_filterAll;

  /// Filter tab label for unread notifications
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notification_filterUnread;

  /// Filter tab label for read notifications
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notification_filterRead;

  /// Empty state title for filtered view
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notification_filterEmpty;

  /// Empty state message for filtered view
  ///
  /// In en, this message translates to:
  /// **'No notifications match the selected filter'**
  String get notification_filterEmptyMessage;

  /// Button to clear current filter
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get notification_clearFilter;

  /// Title for filter selection menu
  ///
  /// In en, this message translates to:
  /// **'Select Filter'**
  String get notification_selectFilter;

  /// Singular form for active filter count
  ///
  /// In en, this message translates to:
  /// **'filter active'**
  String get notification_filterActive;

  /// Plural form for active filters count
  ///
  /// In en, this message translates to:
  /// **'filters active'**
  String get notification_filtersActive;

  /// Label for results count
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get notification_results;

  /// Error message when user cannot delete notification
  ///
  /// In en, this message translates to:
  /// **'Cannot delete this notification'**
  String get notification_cannotDelete;

  /// Permission denied message for delete
  ///
  /// In en, this message translates to:
  /// **'Only the creator can delete notifications within 30 days'**
  String get notification_deletePermissionDenied;

  /// Label for expired notifications
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get notification_expired;

  /// Filter label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get notification_filter;

  /// Toggle filter menu tooltip
  ///
  /// In en, this message translates to:
  /// **'Toggle filter menu'**
  String get notification_toggleFilter;

  /// Filter for notifications sent by current user
  ///
  /// In en, this message translates to:
  /// **'Sent by Me'**
  String get notification_filterSentByMe;

  /// Filter for notifications sent to current user
  ///
  /// In en, this message translates to:
  /// **'Sent to Me'**
  String get notification_filterSentToMe;

  /// Filter for all users' notifications (developer only)
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get notification_filterAllUsers;

  /// Notifications that you personally created.
  ///
  /// In en, this message translates to:
  /// **'Created by Me'**
  String get notification_createdByMe;

  /// Notification is still being prepared and not yet sent.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get notification_statusDraft;

  /// Notification has been scheduled for future delivery.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get notification_statusScheduled;

  /// Notification failed to send due to an error.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get notification_statusFailed;

  /// Notification has been successfully sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get notification_statusSent;

  /// Issue types management screen title
  ///
  /// In en, this message translates to:
  /// **'Issue Types'**
  String get issueTypes_title;

  /// Tooltip for manage issue types button
  ///
  /// In en, this message translates to:
  /// **'Manage Issue Types'**
  String get issueTypes_manageTooltip;

  /// Create issue type dialog title
  ///
  /// In en, this message translates to:
  /// **'Create Issue Type'**
  String get issueTypes_create;

  /// Edit issue type dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Issue Type'**
  String get issueTypes_edit;

  /// Delete issue type dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Issue Type'**
  String get issueTypes_delete;

  /// Issue type name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get issueTypes_name;

  /// Issue type description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueTypes_description;

  /// Name required validation message
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get issueTypes_nameRequired;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String issueTypes_deleteConfirm(String name);

  /// Issue type created success message
  ///
  /// In en, this message translates to:
  /// **'Issue type created'**
  String get issueTypes_created;

  /// Issue type updated success message
  ///
  /// In en, this message translates to:
  /// **'Issue type updated'**
  String get issueTypes_updated;

  /// Issue type deleted success message
  ///
  /// In en, this message translates to:
  /// **'Issue type deleted'**
  String get issueTypes_deleted;

  /// No issue types message
  ///
  /// In en, this message translates to:
  /// **'No issue types found'**
  String get issueTypes_noTypes;

  /// Prompt to create issue type
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one'**
  String get issueTypes_createPrompt;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get issueTypes_errorPrefix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
