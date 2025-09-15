# Firebase Authentication Configuration

## Authentication Providers Setup

### 1. Google Sign-In
```
Provider: Google
Status: Enabled
Web Client ID: Your web client ID from Google Cloud Console
Android Client ID: Your Android client ID from Google Cloud Console
iOS Client ID: Your iOS client ID from Google Cloud Console
```

### 2. Apple Sign-In
```
Provider: Apple
Status: Enabled
Service ID: Your Apple Service ID
Team ID: Your Apple Developer Team ID
Key ID: Your Apple Key ID
Private Key: Upload your Apple private key file
```

### 3. Email/Password
```
Provider: Email/Password
Status: Enabled
Email Enumeration Protection: Enabled
```

## Authentication Settings

### Password Policy
```
Minimum Length: 6 characters
Require Uppercase: No
Require Lowercase: No
Require Numbers: No
Require Special Characters: No
```

### User Management
```
Allow Users to Delete Account: Yes
Allow Account Linking: Yes
Email Verification: Optional (recommended: Required)
Password Reset: Enabled
```

### Security Rules
```
Multi-factor Authentication: Optional
Account Takeover Protection: Enabled
Suspicious Activity Detection: Enabled
```

## Domain Configuration

### Authorized Domains
Add these domains to your Firebase Authentication settings:
```
localhost
127.0.0.1
your-domain.com
your-app-name.web.app
your-app-name.firebaseapp.com
```

### Redirect URLs (for OAuth)
```
http://localhost:3002/__/auth/handler
https://your-domain.com/__/auth/handler
https://your-app-name.web.app/__/auth/handler
```

## Mobile App Configuration

### Android
```
Package Name: com.example.qrpay (or your actual package name)
SHA-1 Certificate Fingerprint: Your debug/release SHA-1 fingerprints
```

### iOS
```
Bundle ID: com.example.qrpay (or your actual bundle ID)
App Store ID: Your App Store ID (if published)
Team ID: Your Apple Developer Team ID
```

## Additional Security Settings

### Session Management
```
Session Cookie Duration: 14 days
Require Recent Login for Sensitive Operations: Yes
Sign-out All Devices on Password Change: Yes
```

### Rate Limiting
```
Sign-in Attempts: 5 per hour per IP
Password Reset Attempts: 5 per hour per email
Account Creation: 10 per hour per IP
```
