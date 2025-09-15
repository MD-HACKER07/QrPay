# QrPay Testing Guide

## 🚀 How to Run the Complete Application

### Prerequisites
- **Flutter SDK** installed and configured
- **Python 3.8+** installed
- **Chrome browser** for web testing

### Option 1: Quick Start (Recommended)

#### Start Backend Server
```bash
python start_backend.py
```
This will:
- Check if all Python dependencies are installed
- Start the FastAPI server on http://localhost:8000
- Enable auto-reload for development
- Show API documentation at http://localhost:8000/docs

#### Start Frontend App
```bash
# On Windows
start_frontend.bat

# On Mac/Linux
cd mobile
flutter pub get
flutter run -d chrome --web-port 3000
```

### Option 2: Manual Setup

#### Backend Setup
```bash
cd backend
pip install -r requirements.txt
cd app
python main.py
```

#### Frontend Setup
```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port 3000
```

## 🧪 Testing the Application

### 1. Authentication Flow (Now with Real Firebase!)
1. **Open the app** - Should show splash screen with QrPay logo
2. **Login screen** - Modern UI with OAuth buttons and email form
3. **Test OAuth** - Click "Continue with Google" (real Firebase Auth!)
4. **Test Email Login** - Create real account or use existing Firebase user
5. **Sign Up** - Creates real user in Firebase Auth + Firestore
6. **Forgot Password** - Sends real password reset email via Firebase

### 🔥 **Firebase Console Verification**
- Visit: https://console.firebase.google.com/project/qrpay001
- Check **Authentication** tab for new user accounts
- Check **Firestore Database** for user and wallet data
- Monitor real-time updates as you use the app

### 2. Wallet Features
1. **Wallet Setup** - Create quantum-resistant wallet
2. **Home Screen** - PayZapp-style interface with:
   - Promotional banner with cashback offer
   - Add bill card
   - Quick action grid (Scan QR, Pay Anyone, etc.)
   - Service grid with badges
   - Balance section
3. **Send Payment** - Test payment sending with validation
4. **Receive Payment** - Generate QR codes for receiving
5. **Transaction History** - View detailed transaction records

### 3. UI Components Testing
1. **Navigation** - Test all screen transitions
2. **Bottom Navigation** - Test all 5 tabs
3. **Animations** - Check smooth transitions and loading states
4. **Responsive Design** - Resize browser window
5. **Error Handling** - Test with invalid inputs

### 4. Backend API Testing
Visit http://localhost:8000/docs to test:
1. **Wallet APIs** - Create wallet, get balance
2. **Transaction APIs** - Send payments, verify signatures
3. **Auth APIs** - Validate addresses, generate challenges

## 🎯 Key Features to Test

### PayZapp-Style UI
- ✅ Orange promotional banner with light bulb
- ✅ Blue quick action grid with 4 buttons
- ✅ Service grid with "EARN ₹241" badge
- ✅ Custom bottom navigation with center QR button
- ✅ Professional color scheme and typography

### Authentication System
- ✅ Modern login with OAuth buttons
- ✅ Email/password authentication
- ✅ Sign up with validation
- ✅ Forgot password flow
- ✅ Secure token storage

### Wallet Functionality
- ✅ Quantum-resistant wallet creation
- ✅ Balance display and management
- ✅ Send/receive payments
- ✅ QR code generation
- ✅ Transaction history
- ✅ Mock cryptographic operations

## 🐛 Known Issues & Limitations

### Current Limitations
1. **Mock Implementation** - Cryptography is simulated for demo
2. **No Real UPI** - Uses mock payment processing
3. **Web Only** - Optimized for Chrome browser testing
4. **Mock OAuth** - Social login is simulated

### Expected Behavior
1. **Fast Loading** - App should load quickly
2. **Smooth Navigation** - No lag between screens
3. **Proper Validation** - Forms should validate inputs
4. **Error Messages** - Clear feedback for invalid actions
5. **Responsive UI** - Works on different screen sizes

## 📊 Testing Checklist

### ✅ Authentication
- [ ] Splash screen loads with animation
- [ ] Login screen shows OAuth buttons
- [ ] Email login works with validation
- [ ] Sign up flow completes successfully
- [ ] Forgot password sends confirmation

### ✅ Home Screen (PayZapp Style)
- [ ] Promotional banner displays correctly
- [ ] Quick action grid has 4 buttons
- [ ] Service grid shows badges
- [ ] Bottom navigation works
- [ ] All colors match PayZapp theme

### ✅ Wallet Features
- [ ] Wallet creation completes
- [ ] Balance displays correctly
- [ ] Send payment form validates
- [ ] QR code generates for receive
- [ ] Transaction history shows records

### ✅ Technical
- [ ] No console errors
- [ ] API calls work (check Network tab)
- [ ] Navigation is smooth
- [ ] Loading states show properly
- [ ] Error handling works

## 🎉 Success Criteria

The app is working correctly if:
1. **UI matches PayZapp** design from the screenshot
2. **Authentication flow** completes without errors
3. **Wallet operations** work smoothly
4. **Navigation** is intuitive and fast
5. **No critical errors** in browser console

## 🔧 Troubleshooting

### Common Issues
1. **Flutter not found** - Check PATH configuration
2. **Dependencies missing** - Run `flutter pub get`
3. **Port conflicts** - Change ports in startup scripts
4. **CORS errors** - Backend CORS is configured for all origins

### Getting Help
1. Check browser console for errors
2. Check terminal output for Flutter/Python errors
3. Verify all dependencies are installed
4. Ensure ports 3000 and 8000 are available

## 📈 Next Steps After Testing

1. **Feedback Collection** - Note any UI/UX improvements
2. **Performance Testing** - Check loading times
3. **Security Review** - Validate authentication flows
4. **Production Planning** - Prepare for real crypto integration
5. **User Testing** - Get feedback from potential users

The QrPay application is now ready for comprehensive testing and demonstration!