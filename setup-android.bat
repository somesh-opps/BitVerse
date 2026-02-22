@echo off
echo ========================================
echo   CropIntel - Android USB Setup
echo ========================================
echo.

echo [1/5] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo X Flutter not found!
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo √ Flutter is installed
echo.

echo [2/5] Running Flutter Doctor...
flutter doctor
echo.

echo [3/5] Checking for connected devices...
flutter devices
echo.

echo [4/5] Generating Android platform files...
if not exist "android" (
    echo Creating Android folder...
    flutter create .
    echo √ Android platform files created
) else (
    echo √ Android folder already exists
)
echo.

echo [5/5] Installing dependencies...
flutter pub get
echo √ Dependencies installed
echo.

echo ========================================
echo   Setup Complete!
echo ========================================
echo.

echo Ready to run the app on your phone!
set /p run="Do you want to run the app now? (y/n): "

if /i "%run%"=="y" (
    echo.
    echo Starting app on connected device...
    echo This may take a few minutes on first run...
    echo.
    flutter run
) else (
    echo.
    echo To run the app later, use: flutter run
    echo To build APK, use: flutter build apk --release
    echo.
)

echo.
echo For detailed instructions, see ANDROID_USB_SETUP.md
pause
