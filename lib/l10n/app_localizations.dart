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
