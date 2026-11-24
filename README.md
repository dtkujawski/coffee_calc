# CoffeeCalc

A two-screen Android calculator for coffee. Swipe left and right to switch.

**Rest** (date screen): enter any of Roasted, Rested, Stored, Thawed and Frozen, and
the rest fill in. Entered values are solid orange, calculated ones are outlined and
italic. Total rest is days since roast minus days in the freezer. If the coffee
hasn't been thawed yet, Frozen counts up to today. Your last values are kept between
launches; Reset clears them.

**Ratio**: Dose (12–30 g) and brew ratio (1:13–1:18) sliders. Pours are running
scale totals: Bloom = 3× dose, 1st pour = 10× dose (adds 7×), 2nd pour = dose × ratio.

## Build and install

```sh
flutter test
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Or run `flutter run --release` with the phone plugged in. Each push also builds the
APK in GitHub Actions (download it from the run's Artifacts).

The release build is signed with the debug key, which is fine for sideloading.
