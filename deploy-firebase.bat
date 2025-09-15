@echo off
echo ========================================
echo    QrPay Firebase Deployment Script
echo ========================================
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI is not installed or not in PATH
    echo Please install Firebase CLI first: npm install -g firebase-tools
    pause
    exit /b 1
)

echo Firebase CLI found. Proceeding with deployment...
echo.

REM Navigate to project root
cd /d "%~dp0"

REM Check if user is logged in
echo Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to login to Firebase first.
    echo Opening Firebase login...
    firebase login
    if %errorlevel% neq 0 (
        echo Login failed. Please try again.
        pause
        exit /b 1
    )
)

echo Authentication successful!
echo.

REM Set the Firebase project
echo Setting Firebase project to qrpay001...
firebase use qrpay001
if %errorlevel% neq 0 (
    echo Failed to set project. Make sure qrpay001 exists in your Firebase console.
    pause
    exit /b 1
)

echo Project set successfully!
echo.

REM Deploy Firestore rules
echo Deploying Firestore security rules...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo Failed to deploy Firestore rules.
    pause
    exit /b 1
)

echo Firestore rules deployed successfully!
echo.

REM Deploy Storage rules
echo Deploying Storage security rules...
firebase deploy --only storage
if %errorlevel% neq 0 (
    echo Failed to deploy Storage rules.
    pause
    exit /b 1
)

echo Storage rules deployed successfully!
echo.

REM Deploy Firestore indexes
echo Deploying Firestore indexes...
firebase deploy --only firestore:indexes
if %errorlevel% neq 0 (
    echo Failed to deploy Firestore indexes.
    pause
    exit /b 1
)

echo Firestore indexes deployed successfully!
echo.

echo ========================================
echo    Deployment completed successfully!
echo ========================================
echo.
echo Your Firebase project is now configured with:
echo - Firestore security rules
echo - Storage security rules  
echo - Firestore performance indexes
echo.
echo You can now test your QrPay application.
echo.
pause
