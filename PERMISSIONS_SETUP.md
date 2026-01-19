# Camera & Storage Permissions Setup

## 📱 Android Permissions

### 1. Edit AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Add these permissions before the `<application>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera Permission -->
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- Storage Permissions (for Android 12 and below) -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <!-- Camera Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>

    <application
        ...>
        <!-- Your app configuration -->
    </application>
</manifest>
```

### 2. Update Minimum SDK Version

File: `android/app/build.gradle`

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Make sure this is at least 21
        targetSdkVersion 34
    }
}
```

---

## 🍎 iOS Permissions

### Edit Info.plist

File: `ios/Runner/Info.plist`

Add these entries inside the `<dict>` tag:

```xml
<dict>
    <!-- Existing keys... -->

    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>KhmerScan needs camera access to scan documents. Your documents are stored locally and never uploaded.</string>

    <!-- Photo Library Permission -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>KhmerScan needs photo library access to import documents from your gallery.</string>

    <!-- Photo Library Add Permission (iOS 11+) -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>KhmerScan needs permission to save scanned documents to your photo library.</string>

</dict>
```

### Update Minimum iOS Version

File: `ios/Podfile`

```ruby
platform :ios, '12.0'  # Make sure this is at least 12.0
```

---

## ✅ Verification Steps

### Test on Android
```bash
# Run on Android device
flutter run -d <android-device-id>

# When you tap the scan button:
# 1. Permission dialog should appear
# 2. Grant camera permission
# 3. Camera preview should show
```

### Test on iOS
```bash
# Run on iOS device/simulator
flutter run -d <ios-device-id>

# When you tap the scan button:
# 1. Permission dialog should appear with your custom message
# 2. Grant camera permission
# 3. Camera preview should show
```

---

## 🐛 Troubleshooting

### Android: Permission Denied Even After Granting
**Solution**: Uninstall and reinstall the app
```bash
flutter clean
flutter run
```

### iOS: Camera Shows Black Screen
**Possible causes**:
1. Permission not granted
2. Simulator doesn't have camera (test on real device)
3. Info.plist not updated correctly

**Solution**:
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

### Permission Dialog Doesn't Show
**Check**:
1. Permissions are in the correct files
2. Files are saved
3. App is completely closed and reopened
4. Try uninstalling and reinstalling

---

## 📝 Permission Best Practices

### When to Request Permissions
- ✅ Request when user taps "Scan Document" button (context is clear)
- ❌ Don't request on app launch (confusing for users)

### Permission Messages
Good examples:
- "Camera is needed to scan your documents"
- "Access your photos to import existing documents"

Bad examples:
- "We need camera" (not specific)
- "Required for app to work" (vague)

### Handling Permission Denial
If user denies permission:
1. Show a helpful message
2. Explain why permission is needed
3. Provide button to open Settings
4. Don't repeatedly ask

---

## 🔒 Privacy Notes

### Data Storage
- Documents are stored **locally** on device
- No cloud upload (respects user privacy)
- User has full control to delete

### What We Store
- ✅ Document images (locally)
- ✅ OCR extracted text (locally)
- ✅ Document metadata (locally)
- ❌ No server uploads
- ❌ No analytics tracking
- ❌ No user personal data collection

---

## 📱 Platform-Specific Notes

### Android 13+ (API 33+)
- Separate permissions for images/videos
- Granular media access
- No WRITE_EXTERNAL_STORAGE needed

### Android 11-12 (API 30-32)
- Scoped storage
- Need WRITE_EXTERNAL_STORAGE

### Android 10 and below (API 29-)
- Traditional storage permissions
- WRITE_EXTERNAL_STORAGE required

### iOS 14+
- Privacy improvements
- More detailed permission dialogs
- "Limited Photos" option

---

## 🧪 Testing Checklist

- [ ] Android: Camera permission dialog shows
- [ ] Android: Permission persists after app restart
- [ ] Android: Gallery picker works
- [ ] iOS: Camera permission dialog shows with custom message
- [ ] iOS: Permission persists after app restart
- [ ] iOS: Gallery picker works
- [ ] Both: Denying permission shows appropriate error
- [ ] Both: Camera preview displays correctly
- [ ] Both: Flash toggle works

---

## 🚀 Ready to Test!

After setting up permissions:

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run on device**:
   ```bash
   flutter run
   ```

3. **Test flow**:
   - Tap "ស្កេនឯកសារ" button
   - Grant camera permission
   - See camera preview
   - Capture a photo
   - Return to home screen

If everything works, you're ready for Week 2! 🎉
