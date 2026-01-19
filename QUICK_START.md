# KhmerScan - Quick Start Guide

## 🚀 Week 1 Complete! What's Working Now

### ✅ Implemented Features
1. **Modern Material 3 UI** with Khmer font support
2. **Home Screen** with category filtering and empty state
3. **Camera Screen** with document guide overlay
4. **Data Models** for documents and categories
5. **Theme System** with consistent styling

### 📱 Try It Out

```bash
# Make sure you're in the project directory
cd /Users/phirun/Projects_Personal/KhmerScan

# Run the app
flutter run
```

**What you'll see:**
- Beautiful home screen with "KhmerScan" title
- Category filter chips (Birth Certificate, National ID, Family Book, Marriage Certificate, Other)
- Empty state message in Khmer
- Floating action button "ស្កេនឯកសារ" (Scan Document)

**Click the FAB to:**
- Open the camera screen
- See the document guide overlay with corner markers
- Toggle flash with the top-right button
- Pick from gallery or capture a photo
- Currently returns to home screen (Week 2 will save the document)

---

## 🎨 Adding Lottie Animations (Optional for Now)

You can add Lottie animations later, but for now the app uses placeholder icons.

### Where to Get Animations
Visit [lottiefiles.com](https://lottiefiles.com) and download:

1. **Empty State**: Search "empty" → Download as JSON
   - Save to: `assets/animations/empty_documents.json`

2. **Scanning**: Search "scanning" → Download as JSON
   - Save to: `assets/animations/scanning.json`

3. **Camera Loading**: Search "camera loading" → Download as JSON
   - Save to: `assets/animations/camera_loading.json`

4. **Success**: Search "success checkmark" → Download as JSON
   - Save to: `assets/animations/success.json`

5. **Delete**: Search "delete trash" → Download as JSON
   - Save to: `assets/animations/delete.json`

After adding animations, the app will automatically use them instead of placeholders.

---

## 📝 Code Highlights

### Modern UI Components
- **SliverAppBar.large**: Expandable app bar that shrinks on scroll
- **FilterChip**: Category selection with animation
- **Shimmer Loading**: Skeleton loading states
- **FlutterAnimate**: Smooth fade and slide animations
- **Masonry Grid**: Pinterest-style document grid (Week 2)

### Khmer Language Support
All UI text uses Khmer script:
- "ស្កេនឯកសារ" (Scan Document)
- "គ្មានឯកសារ" (No Documents)
- "ទាំងអស់" (All)
- Category names in Khmer

### Camera Features
- Real-time camera preview
- Document alignment guide
- Flash toggle
- Gallery picker fallback
- Capture animation

---

## 🔍 Exploring the Code

### Key Files to Review

1. **`lib/main.dart`** - App entry point
   - Sets up Material 3 theme
   - Configures portrait orientation
   - Initializes home screen

2. **`lib/utils/theme.dart`** - Theme configuration
   - Material 3 with blue primary color
   - Khmer font via Google Fonts
   - Consistent styling

3. **`lib/models/document_category.dart`** - Document types
   - 5 categories with Khmer/English names
   - Icons and colors for each

4. **`lib/screens/home_screen.dart`** - Main screen
   - Category filtering
   - Document grid (ready for Week 2)
   - Empty state handling

5. **`lib/screens/camera_screen.dart`** - Camera interface
   - Custom overlay
   - Flash control
   - Capture animation

---

## 🧪 Testing Checklist

### Test These Features
- [ ] App launches without errors
- [ ] Home screen displays Khmer text correctly
- [ ] Category chips are clickable and animate
- [ ] FAB button animates on screen
- [ ] Camera screen opens when FAB is clicked
- [ ] Camera preview shows live feed
- [ ] Flash toggle works
- [ ] Document guide overlay is visible
- [ ] Capture button responds to tap
- [ ] Gallery picker can select images
- [ ] Back button returns to home screen

### Expected Behaviors
- ✅ Empty state always shows (no documents yet)
- ✅ Camera captures but doesn't save (Week 2 feature)
- ✅ Smooth animations throughout
- ✅ Responsive to different screen sizes

---

## 🐛 Common Issues & Solutions

### Issue: Camera Permission Denied
**Solution**: Add permissions to platform-specific files

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <!-- Rest of manifest -->
</manifest>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is needed to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select documents</string>
```

### Issue: Khmer Text Shows Boxes
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Camera Screen is Black
**Cause**: Camera initialization takes time

**Expected**: You'll see "ការចាប់ផ្តើមកាមេរ៉ា..." (Initializing camera) loading screen, then camera preview appears.

### Issue: Build Fails
**Solution**:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..  # iOS only
flutter run
```

---

## 📊 Project Stats

### Lines of Code (Week 1)
- Models: ~150 lines
- Screens: ~500 lines
- Utils: ~50 lines
- Total: ~700 lines of production code

### Dependencies Added
- **Core**: camera, path_provider, image_picker, sqflite, uuid, image
- **OCR**: google_mlkit_text_recognition
- **Export**: share_plus, pdf, printing
- **Monetization**: google_mobile_ads
- **UI**: flutter_staggered_grid_view, flutter_slidable, shimmer, flutter_animate, lottie
- **Utils**: provider, go_router, google_fonts

---

## 🎯 What's Next - Week 2

### Database & Storage
1. **DatabaseService** - SQLite for document metadata
2. **StorageService** - Image compression and file management
3. **DocumentCard** - Beautiful cards with swipe actions
4. **Full Flow** - Capture → Save → Display → Delete

### You'll Be Able To:
- ✨ Scan and save documents
- 📁 Organize by category
- 🖼️ View document thumbnails
- 🗑️ Swipe to delete
- 🔍 See document count per category

---

## 💡 Development Tips

### Hot Reload (r)
Press `r` in terminal while app is running to see changes instantly.

### Hot Restart (R)
Press `R` for full app restart (needed for state changes).

### Debug UI
- Red lines = Overflow issues
- Yellow lines = Rendering problems
- Use Flutter DevTools for performance analysis

### VS Code Extensions
- Flutter
- Dart
- Error Lens
- Material Icon Theme

---

## 🎨 Customization Ideas

### Change Primary Color
Edit `lib/utils/theme.dart`:
```dart
seedColor: const Color(0xFF4CAF50), // Green instead of blue
```

### Add More Categories
Edit `lib/models/document_category.dart`:
```dart
enum DocumentCategory {
  birthCertificate,
  nationalID,
  familyBook,
  marriageCertificate,
  other,
  passport,        // New!
  drivingLicense, // New!
}
```

### Adjust Layout
Edit grid columns in `lib/screens/home_screen.dart`:
```dart
crossAxisCount: 3, // Show 3 columns instead of 2
```

---

## 📚 Resources

### Flutter Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Material 3 Guide](https://m3.material.io/)
- [Camera Plugin](https://pub.dev/packages/camera)

### Khmer Development
- [Google Fonts - Noto Sans Khmer](https://fonts.google.com/noto/specimen/Noto+Sans+Khmer)
- [Khmer Unicode Guide](https://unicode.org/charts/PDF/U1780.pdf)

### Design Inspiration
- [Material Design](https://material.io/design)
- [Dribbble - Document Scanner](https://dribbble.com/search/document-scanner)

---

**Great job completing Week 1! 🎉**

The foundation is solid and ready for Week 2's database integration.
