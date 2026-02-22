# CropIntel - Quick Setup Script for Android USB Debugging
# Run this script to set up and run the app on your phone

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CropIntel - Android USB Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Flutter installation
Write-Host "[1/5] Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Flutter is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ Flutter not found in PATH" -ForegroundColor Red
        Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Flutter not found" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Run Flutter Doctor
Write-Host "[2/5] Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

# Step 3: Check for connected devices
Write-Host "[3/5] Checking for connected Android devices..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
Write-Host $devices
Write-Host ""

if ($devices -match "No devices detected") {
    Write-Host "⚠ No devices found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. USB Debugging is enabled on your phone" -ForegroundColor Yellow
    Write-Host "  2. Phone is connected via USB cable" -ForegroundColor Yellow
    Write-Host "  3. You've allowed USB debugging on your phone" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "See ANDROID_USB_SETUP.md for detailed instructions" -ForegroundColor Cyan
    
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

Write-Host ""

# Step 4: Generate Android platform files
Write-Host "[4/5] Generating Android platform files..." -ForegroundColor Yellow
if (-Not (Test-Path "android")) {
    Write-Host "Creating Android folder..." -ForegroundColor Cyan
    flutter create .
    Write-Host "✓ Android platform files created" -ForegroundColor Green
} else {
    Write-Host "✓ Android folder already exists" -ForegroundColor Green
}

Write-Host ""

# Step 5: Install dependencies
Write-Host "[5/5] Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencies installed" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to run the app
Write-Host "Ready to run the app on your phone!" -ForegroundColor Cyan
$run = Read-Host "Do you want to run the app now? (y/n)"

if ($run -eq "y") {
    Write-Host ""
    Write-Host "Starting app on connected device..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes on first run..." -ForegroundColor Yellow
    Write-Host ""
    flutter run
} else {
    Write-Host ""
    Write-Host "To run the app later, use:" -ForegroundColor Cyan
    Write-Host "  flutter run" -ForegroundColor White
    Write-Host ""
    Write-Host "To build APK, use:" -ForegroundColor Cyan
    Write-Host "  flutter build apk --release" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
Write-Host "For detailed instructions, see ANDROID_USB_SETUP.md" -ForegroundColor Cyan
Write-Host ""
