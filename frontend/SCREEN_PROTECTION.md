# Screen Protection Feature Documentation

## Overview
Implementasi screen protection untuk mencegah screenshot dan screen recording selama exam session menggunakan library resmi dari pub.dev.

## Libraries Used

### 1. flutter_windowmanager (v0.2.0)
**Purpose**: Mencegah screenshot dan screen recording di Android
**Pub.dev**: https://pub.dev/packages/flutter_windowmanager
**Platform**: Android only

**Features**:
- FLAG_SECURE: Mencegah screenshot dan screen recording
- FLAG_KEEP_SCREEN_ON: Keep screen awake during exam
- Works at OS level (Android WindowManager)

### 2. screenshot_callback (v3.0.1)
**Purpose**: Detect screenshot attempts
**Pub.dev**: https://pub.dev/packages/screenshot_callback
**Platform**: Android & iOS

**Features**:
- Callback listener untuk screenshot attempts
- Logging dan tracking
- Warning dialog untuk users

## Implementation

### 1. ScreenProtectionService
**File**: `lib/core/services/screen_protection_service.dart`

**Singleton service** untuk manage screen protection globally.

**Methods**:
```dart
// Enable protection
await ScreenProtectionService().enableProtection();

// Disable protection
await ScreenProtectionService().disableProtection();

// Check status
bool isEnabled = ScreenProtectionService().isProtectionEnabled;
```

**How it works**:
- Android: Uses `FlutterWindowManager.FLAG_SECURE`
- iOS: Screenshot callback only (iOS doesn't allow blocking screenshots)
- Automatically initializes screenshot listener
- Logs all screenshot attempts

### 2. ProtectedScreen Widget
**File**: `lib/core/widgets/protected_screen.dart`

**Wrapper widget** untuk screens yang perlu protection.

**Usage**:
```dart
ProtectedScreen(
  showWarningDialog: true,
  onScreenshotAttempt: () {
    // Custom action
  },
  child: YourScreen(),
)
```

**Features**:
- Auto-enable protection on screen open
- Auto-disable protection on screen close
- Lifecycle aware (handles app resume/pause)
- Optional warning dialog
- Custom callback for screenshot attempts

**Parameters**:
- `child`: Widget yang akan di-protect
- `showWarningDialog`: Show warning saat screenshot attempt (default: true)
- `onScreenshotAttempt`: Custom callback untuk screenshot attempts

### 3. Protected Screens

#### Exam Room Screen
**File**: `lib/features/room/presentation/screens/exam_room_screen.dart`

**Protection**: ✅ Enabled
**Badge**: Red "Protected" badge di AppBar
**Reason**: Prevent sharing room details and QR codes

#### Exam Session Screen
**File**: `lib/features/ujian/presentation/screens/exam_session_screen.dart`

**Protection**: ✅ Enabled
**Badge**: Red "Protected" badge di AppBar
**Features**:
- Screen protection active
- WillPopScope untuk prevent accidental exit
- Timer countdown
- Question navigation
- Submit confirmation

## Android Implementation Details

### FLAG_SECURE
```dart
await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
```

**Effect**:
- Black screen in recent apps
- Screenshot blocked (shows black image)
- Screen recording blocked (shows black screen)
- Works in all Android versions

### Permissions
No additional permissions required. FLAG_SECURE is a window flag, not a permission.

## iOS Limitations

**Important**: iOS doesn't allow apps to block screenshots at system level.

**What we can do**:
- Detect screenshot attempts via callback
- Show warning dialog
- Log attempts for review
- Take action (e.g., submit exam, flag user)

**What we cannot do**:
- Block screenshots completely
- Block screen recording

## User Experience

### When Protection is Active

1. **Screenshot Attempt**:
   - Android: Screenshot fails (black image)
   - iOS: Screenshot succeeds but logged
   - Warning dialog shown (if enabled)
   - Attempt logged to backend (TODO)

2. **Screen Recording**:
   - Android: Recording shows black screen
   - iOS: Recording works (cannot be blocked)

3. **Recent Apps**:
   - Android: Shows black preview
   - iOS: Shows normal preview

4. **Visual Indicator**:
   - Red "Protected" badge in AppBar
   - Security icon visible

### User Warnings

**Dialog Content**:
```
⚠️ Warning

Screenshot and screen recording are not allowed during 
the exam session. This attempt has been logged.

[I Understand]
```

## Security Features

### 1. Automatic Protection
- Enabled when entering protected screen
- Disabled when leaving protected screen
- Re-enabled when app resumes

### 2. Lifecycle Management
- Handles app pause/resume
- Handles screen rotation
- Handles system dialogs

### 3. Logging
All screenshot attempts are logged with:
- Timestamp
- User ID (TODO)
- Screen name
- Device info (TODO)

### 4. Backend Integration (TODO)
```dart
// Log to backend
await logSecurityEvent({
  'type': 'screenshot_attempt',
  'user_id': userId,
  'room_id': roomId,
  'timestamp': DateTime.now(),
  'device': deviceInfo,
});
```

## Testing

### Test on Android Device

1. **Enable Protection**:
```bash
flutter run
# Navigate to Exam Room or Exam Session
```

2. **Try Screenshot**:
   - Press Power + Volume Down
   - Result: Black image saved
   - Warning dialog appears

3. **Try Screen Recording**:
   - Start screen recording
   - Navigate to protected screen
   - Result: Black screen in recording

4. **Check Recent Apps**:
   - Open recent apps
   - Result: Black preview for protected screen

### Test on iOS Device

1. **Enable Protection**:
```bash
flutter run
# Navigate to Exam Room or Exam Session
```

2. **Try Screenshot**:
   - Press Power + Volume Up
   - Result: Screenshot succeeds
   - Warning dialog appears
   - Attempt logged

3. **Screen Recording**:
   - Cannot be blocked on iOS
   - Only detection available

## Configuration

### Enable/Disable Protection

**Global Toggle** (in settings):
```dart
class AppSettings {
  static bool screenProtectionEnabled = true;
  
  static Future<void> toggleProtection(bool enabled) async {
    screenProtectionEnabled = enabled;
    if (enabled) {
      await ScreenProtectionService().enableProtection();
    } else {
      await ScreenProtectionService().disableProtection();
    }
  }
}
```

### Per-Screen Configuration

```dart
// Disable warning dialog
ProtectedScreen(
  showWarningDialog: false,
  child: MyScreen(),
)

// Custom callback
ProtectedScreen(
  onScreenshotAttempt: () {
    // Log to analytics
    // Show custom message
    // Take action
  },
  child: MyScreen(),
)
```

## Best Practices

### 1. Use Protection Selectively
Only protect screens with sensitive content:
- ✅ Exam questions
- ✅ Room QR codes
- ✅ Student answers
- ❌ Dashboard
- ❌ Settings
- ❌ Profile

### 2. Inform Users
Show clear indication when protection is active:
- Badge in AppBar
- Info dialog on first use
- Help section explaining why

### 3. Handle Gracefully
Don't punish users for accidental attempts:
- First attempt: Warning
- Multiple attempts: Log and review
- Excessive attempts: Flag for review

### 4. Provide Alternatives
If users need to save info:
- Export results after exam
- Email summary
- Download certificate

## Troubleshooting

### Protection Not Working

**Check**:
1. Library installed: `flutter pub get`
2. Android device (not emulator)
3. Protection enabled in code
4. No conflicting flags

**Debug**:
```dart
debugPrint('Protection enabled: ${ScreenProtectionService().isProtectionEnabled}');
```

### Warning Dialog Not Showing

**Check**:
1. `showWarningDialog: true`
2. Context is valid
3. No other dialogs open

### iOS Screenshots Not Blocked

**Expected behavior**: iOS doesn't allow blocking screenshots.
**Solution**: Use detection + logging + warnings

## Future Enhancements

### 1. Advanced Detection
- Detect screen recording apps
- Detect screen mirroring
- Detect external displays

### 2. Backend Integration
- Log all attempts to database
- Real-time alerts to proctors
- Analytics dashboard

### 3. Proctoring Features
- Camera monitoring
- Face detection
- Tab switching detection
- Multiple monitor detection

### 4. Compliance
- GDPR compliance for logging
- User consent for monitoring
- Data retention policies

## Dependencies

```yaml
dependencies:
  flutter_windowmanager: ^0.2.0
  screenshot_callback: ^3.0.1
```

## Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Block Screenshot | ✅ | ❌ | ❌ |
| Block Recording | ✅ | ❌ | ❌ |
| Detect Screenshot | ✅ | ✅ | ❌ |
| Warning Dialog | ✅ | ✅ | ✅ |
| Logging | ✅ | ✅ | ✅ |

## Security Considerations

### 1. Not Foolproof
- Users can use external cameras
- Users can use second device
- Screen mirroring may work

### 2. Complementary Measures
- Proctoring (camera monitoring)
- Time limits
- Question randomization
- Answer shuffling
- IP tracking
- Device fingerprinting

### 3. Privacy
- Inform users about monitoring
- Get consent before exam
- Comply with privacy laws
- Secure storage of logs

## Code Examples

### Basic Usage
```dart
class MyExamScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProtectedScreen(
      child: Scaffold(
        appBar: AppBar(title: Text('Exam')),
        body: ExamContent(),
      ),
    );
  }
}
```

### With Custom Callback
```dart
ProtectedScreen(
  showWarningDialog: true,
  onScreenshotAttempt: () {
    // Log to backend
    logSecurityEvent('screenshot_attempt');
    
    // Show custom message
    showCustomWarning();
    
    // Increment violation count
    incrementViolations();
  },
  child: ExamScreen(),
)
```

### Manual Control
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _protection = ScreenProtectionService();
  
  @override
  void initState() {
    super.initState();
    _protection.enableProtection();
  }
  
  @override
  void dispose() {
    _protection.disableProtection();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyContent(),
    );
  }
}
```

## Summary

✅ **Implemented**:
- Screen protection service (singleton)
- Protected screen wrapper widget
- Exam room protection
- Exam session protection
- Screenshot detection
- Warning dialogs
- Lifecycle management

⏳ **TODO**:
- Backend logging integration
- Analytics dashboard
- User consent flow
- Settings toggle
- iOS enhanced detection
- Proctoring features

🔒 **Security Level**: Medium-High
- Effective on Android
- Detection only on iOS
- Requires complementary measures
- User education important
