@echo off
echo 🎯 QrPay Flutter Frontend
echo ==============================

REM Add Flutter to PATH
set PATH=%PATH%;D:\flutter_windows_3.35.3-stable\flutter\bin

echo 📱 Starting QrPay Flutter App...
echo 🌐 App will open in Chrome browser
echo 🔄 Hot reload enabled for development
echo ------------------------------

cd mobile

echo 📦 Getting dependencies...
flutter pub get

echo 🚀 Starting Flutter app...
flutter run -d chrome --web-port 3000

pause