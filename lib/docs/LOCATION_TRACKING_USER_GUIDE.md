# Location Tracking User Guide

## What is Location Tracking?

Location tracking is a feature that helps keep you safe on the road by automatically alerting you when you're near critical road hazards. When enabled, the app monitors your location in the background and sends you notifications when you approach severe road issues like:

- 🚧 Major construction zones
- 🕳️ Dangerous potholes or road damage
- ⚠️ Critical traffic incidents
- 🌧️ Severe weather hazards

## How It Works

When you enable location tracking, three things happen:

1. **GPS Monitoring**: The app continuously monitors your GPS location while you're on the move
2. **Smart Updates**: Your location is sent to our servers only when you've moved significantly (every 100 meters or 60 seconds)
3. **Proximity Alerts**: Every 2 minutes, the app checks if there are any critical road issues within 5 kilometers of your location and notifies you

### Visual Overview

```
You're driving → GPS tracks your location → Location updates to server
                                                    ↓
                                          Server checks for nearby issues
                                                    ↓
                                    Critical issue within 5km? → Notification sent!
```

## Privacy & Your Data

We take your privacy seriously:

### What We Track
- ✅ Your current GPS coordinates (latitude and longitude)
- ✅ When your location was last updated
- ✅ Whether you have location tracking enabled

### What We DON'T Track
- ❌ Your location history or movement patterns
- ❌ Where you've been in the past
- ❌ Your home or work addresses (unless you save them)
- ❌ Your location when tracking is disabled

### Your Control
- 🔒 Location tracking is **OFF by default** - you must explicitly enable it
- 🔒 You can disable location tracking at any time
- 🔒 When disabled, we immediately stop tracking and monitoring
- 🔒 Your location data is only visible to you and used for safety alerts
- 🔒 Stale location data (older than 30 minutes) is automatically excluded from proximity checks

## Battery Impact

We've designed location tracking to be battery-efficient:

### Battery-Saving Features

1. **Distance Filter**: GPS only updates when you've moved at least 50 meters
2. **Update Throttling**: Location is sent to the server only when you've moved 100+ meters AND 60+ seconds have passed
3. **Periodic Checks**: Proximity monitoring runs every 2 minutes, not continuously
4. **Smart Caching**: We remember which issues we've already notified you about to avoid duplicate checks

### Expected Battery Usage

- **Light usage** (short trips): Minimal impact, similar to using navigation apps briefly
- **Moderate usage** (daily commute): ~5-10% additional battery drain per day
- **Heavy usage** (long road trips): ~10-20% additional battery drain per day

### Tips to Minimize Battery Drain

- 💡 Disable location tracking when parked or not driving
- 💡 Keep your phone charged while on long trips
- 💡 Close other battery-intensive apps while driving
- 💡 Use battery saver mode if needed (location tracking will still work)

## How to Enable Location Tracking

### Step 1: Open Settings

1. Open the Pavra app
2. Tap the menu icon (☰) or navigate to **Settings**
3. Scroll to the **Location Tracking** section

### Step 2: Grant Permissions

When you first enable location tracking, you'll be asked to grant location permissions:

1. Tap **Enable Location Tracking**
2. When prompted, select **"Allow all the time"** or **"Allow while using the app"**
   - **Recommended**: "Allow all the time" for continuous protection
   - **Alternative**: "Allow while using the app" if you prefer more control

> **Note**: If you previously denied location permissions, you'll need to enable them in your device settings:
> - **iOS**: Settings → Pavra → Location → Always
> - **Android**: Settings → Apps → Pavra → Permissions → Location → Allow all the time

### Step 3: Confirm Activation

Once enabled, you'll see:
- ✅ **Status**: "Location tracking is active"
- 📍 **Last Update**: Timestamp of your last location update
- 🔔 **Monitoring**: "Checking for nearby issues every 2 minutes"

## How to Disable Location Tracking

Disabling location tracking is simple:

1. Open **Settings** in the Pavra app
2. Navigate to the **Location Tracking** section
3. Tap **Disable Location Tracking**
4. Confirm your choice

When disabled:
- GPS monitoring stops immediately
- No more location updates are sent to the server
- Proximity monitoring stops
- You won't receive proximity-based notifications

> **Note**: You can re-enable location tracking at any time by following the enable steps above.

## Understanding Proximity Notifications

### What Triggers a Notification?

You'll receive a notification when:
1. ✅ Location tracking is enabled
2. ✅ You're within 5 kilometers of a critical road issue
3. ✅ The issue has "high" or "critical" severity
4. ✅ You haven't been notified about this issue before (during this session)

### Notification Content

Each proximity notification includes:
- 📋 **Title**: Brief description of the issue
- 📍 **Location**: How far away the issue is
- ⚠️ **Severity**: High or Critical
- 🗺️ **Action**: Tap to view on map

### Managing Notifications

If you're receiving too many notifications:

1. **Adjust Alert Preferences**:
   - Go to Settings → Alert Preferences
   - Disable specific alert types (e.g., construction zones, weather hazards)
   - You'll still receive critical safety alerts

2. **Temporarily Disable**:
   - Disable location tracking when you're not driving
   - Re-enable when you need it

3. **System Notifications**:
   - You can also manage notifications in your device settings
   - **iOS**: Settings → Notifications → Pavra
   - **Android**: Settings → Apps → Pavra → Notifications

## Troubleshooting

### Location Tracking Won't Enable

**Problem**: Error message when trying to enable location tracking

**Solutions**:
1. **Check Location Permissions**:
   - Ensure you've granted location permissions to Pavra
   - Go to device settings and verify permissions

2. **Enable Location Services**:
   - Make sure location services are enabled on your device
   - **iOS**: Settings → Privacy → Location Services → ON
   - **Android**: Settings → Location → ON

3. **Restart the App**:
   - Close Pavra completely
   - Reopen and try enabling again

4. **Check Internet Connection**:
   - Location tracking requires an internet connection to update the server
   - Verify you have cellular data or Wi-Fi

### Not Receiving Proximity Notifications

**Problem**: Location tracking is enabled but no notifications appear

**Possible Causes**:
1. **No Critical Issues Nearby**:
   - You may not be near any high/critical severity issues
   - This is good news! It means the roads are safe

2. **Notifications Disabled**:
   - Check Settings → Notifications → Ensure notifications are enabled
   - Check device notification settings for Pavra

3. **Alert Preferences**:
   - Verify your alert preferences in Settings → Alert Preferences
   - Ensure at least one alert type is enabled

4. **Location Not Updating**:
   - Check the "Last Update" timestamp in Settings
   - If it's old, try disabling and re-enabling location tracking

### High Battery Drain

**Problem**: Location tracking is using too much battery

**Solutions**:
1. **Disable When Not Needed**:
   - Turn off location tracking when parked or not driving

2. **Check Other Apps**:
   - Other apps may be using GPS simultaneously
   - Close unnecessary location-based apps

3. **Update the App**:
   - Ensure you're using the latest version of Pavra
   - Updates often include battery optimizations

4. **Device Settings**:
   - Enable battery saver mode if needed
   - Location tracking will still work but may update less frequently

### Location Shows as "Stale" or "Inactive"

**Problem**: Status shows location hasn't updated recently

**Solutions**:
1. **Move Around**:
   - Location only updates when you move at least 50 meters
   - If you're stationary, the location won't update

2. **Check GPS Signal**:
   - Ensure you have a clear view of the sky
   - GPS works poorly indoors or in tunnels

3. **Restart Tracking**:
   - Disable and re-enable location tracking
   - This resets the GPS connection

## Frequently Asked Questions

### Q: Does location tracking work when the app is closed?

**A**: Yes! Location tracking works in the background even when the app is closed. However, you must grant "Allow all the time" location permissions for this to work.

### Q: Will I be notified about every road issue?

**A**: No, you'll only be notified about **high** and **critical** severity issues within 5 kilometers of your location. Minor issues won't trigger notifications.

### Q: Can other users see my location?

**A**: No, your location is private. Other users cannot see where you are. Your location is only used to determine if you should receive proximity alerts.

### Q: What happens if I lose internet connection?

**A**: Location tracking will continue to monitor your GPS position, but location updates won't be sent to the server until you regain internet connection. Proximity monitoring requires internet to check for nearby issues.

### Q: Does location tracking work in all countries?

**A**: Yes, location tracking works worldwide wherever GPS is available. However, road issue data may be limited in some regions depending on user reports.

### Q: How accurate is the location tracking?

**A**: Location accuracy depends on your device's GPS. Typically, accuracy is within 10-50 meters in open areas. Accuracy may be reduced in urban canyons, tunnels, or indoors.

### Q: Can I customize the 5km alert radius?

**A**: Currently, the 5km radius is fixed to balance timely alerts with notification frequency. Future updates may include customizable alert distances.

### Q: Will I be notified about the same issue multiple times?

**A**: No, the app remembers which issues it has already notified you about during your current session. You won't receive duplicate notifications for the same issue unless you restart the app or move significantly away and return.

### Q: What's the difference between "Allow while using" and "Allow all the time"?

**A**: 
- **"Allow while using"**: Location tracking only works when the app is open and in the foreground
- **"Allow all the time"**: Location tracking works continuously, even when the app is closed (recommended for best protection)

### Q: Does location tracking use cellular data?

**A**: Yes, but very little. Location updates are small data packets sent every 100 meters or 60 seconds. Expect ~1-5 MB of data usage per hour of driving.

## Best Practices

### For Daily Commuters

1. ✅ Enable location tracking before starting your commute
2. ✅ Keep the app running in the background
3. ✅ Disable tracking when you arrive at your destination
4. ✅ Charge your phone overnight to maintain battery

### For Road Trips

1. ✅ Enable location tracking at the start of your trip
2. ✅ Keep your phone charged (use car charger)
3. ✅ Keep the app updated for the latest road issue data
4. ✅ Report new issues you encounter to help other drivers

### For Urban Driving

1. ✅ Enable location tracking in high-traffic areas
2. ✅ Pay attention to construction zone alerts
3. ✅ Adjust alert preferences to reduce notification frequency if needed
4. ✅ Use navigation mode to see issues on the map

### For Privacy-Conscious Users

1. ✅ Use "Allow while using" permission if you prefer more control
2. ✅ Disable location tracking when not actively driving
3. ✅ Review your alert preferences to limit data collection
4. ✅ Remember: we don't store your location history

## Getting Help

If you're experiencing issues with location tracking:

1. **Check This Guide**: Review the troubleshooting section above
2. **Contact Support**: Tap Settings → Help & Support → Contact Us
3. **Report a Bug**: Settings → Help & Support → Report a Bug
4. **Community Forum**: Join our community to ask questions and share tips

## Privacy Policy & Terms

For more information about how we handle your location data:
- [Privacy Policy](privacy_policy_screen.dart)
- [Terms of Service](terms_of_service_screen.dart)

---

**Last Updated**: December 2024  
**Version**: 1.0

Stay safe on the road! 🚗💨
