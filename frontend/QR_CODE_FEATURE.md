# QR Code Feature Implementation

## Overview
Implementasi fitur QR Code untuk join room dan share room di aplikasi Skora. Fitur ini memungkinkan:
- **Scan QR Code** untuk join room sebagai peserta
- **Generate & Display QR Code** untuk setiap room yang unik
- **Copy Room Code** untuk share manual

## Features Implemented

### 1. QR Code Scanner (Dashboard)
**File**: `lib/features/room/presentation/screens/qr_scanner_screen.dart`

**Fitur**:
- Real-time QR code scanning menggunakan kamera device
- Custom overlay dengan frame scanning area
- Corner borders untuk visual guidance
- Flashlight toggle untuk kondisi cahaya rendah
- Auto-detect dan return room code
- Instructions panel di bottom

**Teknologi**:
- Package: `mobile_scanner: ^7.2.0`
- Custom painter untuk overlay effect
- Material design dengan dark theme

**Flow**:
1. User tap "Join Room" di Dashboard
2. Kamera terbuka dengan scanner overlay
3. Arahkan kamera ke QR code room
4. Auto-detect dan return ke dashboard
5. Join room dengan code yang di-scan

### 2. QR Code Generator (Exam Room)
**File**: `lib/features/room/presentation/screens/exam_room_screen.dart`

**Fitur**:
- Generate QR code unik untuk setiap room
- Format: `ROOM:{roomId}:{roomCode}`
- Display dalam popup dialog
- White background untuk optimal scanning
- Room info (name, code) di bawah QR
- Copy button untuk share code manual

**Teknologi**:
- Package: `qr_flutter: ^4.1.0`
- QR version: auto-detect optimal size
- Size: 250x250 pixels

**UI Components**:
- Blue "QR" button di room code section
- Popup dialog dengan:
  - QR code image (250x250)
  - Room code (large, blue, bold)
  - Room name
  - Instructions text
  - Copy button

### 3. Dashboard Integration
**File**: `lib/features/dashboard/dashboard_screen.dart`

**Updates**:
- Import QRScannerScreen
- `_scanQRCode()` method untuk navigate ke scanner
- `_joinRoomWithCode(String)` method untuk process scanned code
- "Join Room" card dengan QR scanner icon
- SnackBar feedback setelah scan

## Room Code Format

### Generation
```dart
String _generateRoomCode(String roomId) {
  final hash = roomId.hashCode.abs();
  final code = hash.toString().padLeft(6, '0').substring(0, 6);
  return '${code.substring(0, 3)}-${code.substring(3, 6)}';
}
```

**Format**: `XXX-XXX` (6 digits dengan separator)
**Example**: `123-456`

### QR Code Data
**Format**: `ROOM:{roomId}:{roomCode}`
**Example**: `ROOM:abc123:123-456`

**Parsing**:
```dart
final parts = scannedData.split(':');
if (parts.length == 3 && parts[0] == 'ROOM') {
  final roomId = parts[1];
  final roomCode = parts[2];
  // Join room logic
}
```

## Android Permissions

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

## Dependencies

**File**: `pubspec.yaml`

```yaml
dependencies:
  qr_flutter: ^4.1.0        # QR code generator
  mobile_scanner: ^7.2.0    # QR code scanner
```

## User Flow

### Join Room Flow (Participant)
```
Dashboard
  ↓ Tap "Join Room"
QR Scanner Screen
  ↓ Scan QR Code
  ↓ Auto-detect
Dashboard
  ↓ Show "Joining room: XXX-XXX"
  ↓ API Call (TODO)
Exam Room Screen (as participant)
```

### Share Room Flow (Host)
```
Exam Room Screen
  ↓ Tap "QR" button
QR Code Dialog
  ↓ Display QR + Code
  ↓ Participant scans OR
  ↓ Host taps "Copy"
Share code manually
```

## UI/UX Details

### QR Scanner Screen
- **Background**: Black (optimal for camera)
- **Overlay**: Semi-transparent black with transparent center
- **Frame**: Blue corner borders (30px length)
- **Scan Area**: 70% of screen width
- **Instructions**: Bottom panel with icon and text
- **Controls**: Close button (top-left), Flash toggle (top-right)

### QR Code Dialog
- **Background**: Dark theme (0xFF1E293B)
- **QR Container**: White background with padding
- **QR Size**: 250x250 pixels
- **Code Display**: Large (28px), blue, bold, letter-spacing: 4
- **Buttons**: Full-width blue button for copy

### Room Code Section (Exam Room)
- **Code Display**: 32px, blue, bold, letter-spacing: 4
- **QR Button**: Blue background, white text
- **Copy Button**: Gray background, white text
- **Layout**: Horizontal row with expanded code and buttons

## TODO: Backend Integration

### 1. Join Room API
```dart
Future<Either<Failure, RoomParticipantModel>> joinRoom(String roomCode) async {
  // POST /api/rooms/join
  // Body: { "room_code": "123-456" }
  // Response: RoomParticipantModel
}
```

### 2. Validate Room Code
```dart
Future<Either<Failure, RoomModel>> validateRoomCode(String roomCode) async {
  // GET /api/rooms/validate/{roomCode}
  // Response: RoomModel or 404
}
```

### 3. Get Room by Code
```dart
Future<Either<Failure, RoomModel>> getRoomByCode(String roomCode) async {
  // GET /api/rooms/code/{roomCode}
  // Response: RoomModel with full details
}
```

## Testing Checklist

### QR Scanner
- [ ] Camera permission request
- [ ] Camera opens successfully
- [ ] Overlay displays correctly
- [ ] QR code detection works
- [ ] Flash toggle works
- [ ] Close button works
- [ ] Auto-return after scan
- [ ] Error handling for no camera

### QR Generator
- [ ] QR code generates correctly
- [ ] Dialog opens/closes properly
- [ ] QR code is scannable
- [ ] Copy button works
- [ ] SnackBar shows feedback
- [ ] Room info displays correctly

### Integration
- [ ] Dashboard → Scanner navigation
- [ ] Scanner → Dashboard return with code
- [ ] Exam Room → QR Dialog
- [ ] Room code format consistent
- [ ] API integration (when ready)

## File Structure

```
lib/features/
├── dashboard/
│   └── dashboard_screen.dart          # Updated with scanner integration
├── room/
│   ├── data/models/
│   │   └── models.dart                # RoomModel, RoomParticipantModel
│   └── presentation/screens/
│       ├── qr_scanner_screen.dart     # NEW: QR Scanner
│       ├── exam_room_screen.dart      # Updated with QR generator
│       └── create_exam_room_screen.dart
```

## Design System

### Colors
- **Primary Blue**: `0xFF3B82F6`
- **Background Dark**: `0xFF0F172A`
- **Card Background**: `0xFF1E293B`
- **Border**: `0xFF334155`
- **Text Primary**: `Colors.white`
- **Text Secondary**: `0xFF94A3B8`
- **Text Tertiary**: `0xFF64748B`
- **Success**: `Colors.green`

### Typography
- **Room Code**: 32px, bold, letter-spacing: 4
- **QR Dialog Code**: 28px, bold, letter-spacing: 4
- **Title**: 20px, bold
- **Body**: 14px, regular
- **Caption**: 12px, regular

## Security Considerations

1. **QR Code Format**: Include room ID untuk validasi
2. **Code Expiration**: TODO - implement expiration time
3. **Permission Check**: Request camera permission before scanning
4. **Validation**: Validate room code format before API call
5. **Error Handling**: Handle invalid QR codes gracefully

## Performance

- **QR Generation**: Instant (client-side)
- **QR Scanning**: Real-time detection
- **Camera**: Auto-focus enabled
- **Memory**: Proper disposal of camera controller

## Accessibility

- **Instructions**: Clear text instructions for scanning
- **Visual Feedback**: Corner borders guide scanning area
- **Error Messages**: User-friendly error messages
- **Alternative**: Manual code entry option available

## Future Enhancements

1. **Manual Code Entry**: Dialog untuk input code manual
2. **Code Expiration**: Time-limited room codes
3. **Share Options**: Share QR via WhatsApp, Email, etc.
4. **History**: Recent scanned/joined rooms
5. **Offline Mode**: Cache room data for offline access
6. **Analytics**: Track scan success rate
