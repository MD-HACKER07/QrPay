# QrPay: Quantum-Resistant UPI Wallet

A revolutionary payment system that integrates post-quantum cryptography into the UPI ecosystem to ensure digital transactions remain secure in the post-quantum era.

## 🚀 Features

- **Quantum-Safe Security**: Uses Dilithium signatures and Kyber key exchange
- **Cross-Platform Mobile App**: Built with Flutter for Android and iOS
- **Secure Key Storage**: Hardware-backed keystore integration
- **UPI Integration**: Compatible with existing UPI infrastructure
- **Mock Payments**: Phase 1 implementation with mock transactions

## 🏗️ Architecture

### Frontend (Mobile)
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Provider** - State management
- **GoRouter** - Navigation
- **Flutter Secure Storage** - Secure key storage

### Backend (API)
- **Python FastAPI** - High-performance web framework
- **PostgreSQL** - Database (planned)
- **Rust modules** - Post-quantum cryptography operations

### Cryptography
- **Dilithium** - Post-quantum digital signatures
- **Kyber** - Post-quantum key exchange
- **Rust** - Core cryptographic implementations

## 📂 Project Structure

```
qrpay/
├── mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── screens/       # UI screens
│   │   ├── widgets/       # Reusable components
│   │   ├── services/      # Business logic
│   │   ├── models/        # Data models
│   │   └── providers/     # State management
│   └── pubspec.yaml
├── backend/               # Python FastAPI backend
│   ├── app/
│   │   ├── routes/        # API endpoints
│   │   ├── models/        # Pydantic models
│   │   └── services/      # Business services
│   └── requirements.txt
├── docs/                  # Documentation
└── tests/                 # Test files
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.35.3+
- Python 3.8+
- Dart 3.9.2+

### Mobile App Setup

1. Navigate to mobile directory:
   ```bash
   cd mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Create virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the server:
   ```bash
   cd app
   python main.py
   ```

The API will be available at `http://localhost:8000`

## 🔐 Security Features

### Post-Quantum Cryptography
- **Dilithium**: NIST-standardized post-quantum digital signature scheme
- **Kyber**: NIST-standardized post-quantum key encapsulation mechanism
- **Hardware Security**: Integration with device secure enclaves

### Key Management
- Private keys stored in hardware-backed keystore
- Secure key generation using quantum-safe algorithms
- Regular key rotation capabilities

## 📱 Mobile App Features

### Wallet Management
- Create quantum-resistant wallets
- Secure key storage
- Balance tracking
- Transaction history

### Payments
- Send payments with QR codes
- Receive payments
- Transaction verification
- Real-time balance updates

### Security
- Biometric authentication (planned)
- Hardware-backed key storage
- Quantum-resistant signatures

## 🌐 API Endpoints

### Wallet Management
- `POST /api/wallet/create` - Create new wallet
- `GET /api/wallet/{wallet_id}` - Get wallet info
- `GET /api/wallet/{wallet_id}/balance` - Get balance

### Transactions
- `POST /api/transaction/send` - Send payment
- `POST /api/transaction/verify` - Verify signature
- `GET /api/transaction/wallet/{address}` - Get transaction history

### Authentication
- `POST /api/auth/validate-address` - Validate address format
- `POST /api/auth/generate-challenge` - Generate auth challenge

## 🛣️ Roadmap

### Phase 1 - Prototype (Current)
- ✅ Basic Flutter UI
- ✅ Mock cryptographic operations
- ✅ Local storage
- ✅ Python FastAPI backend
- ✅ Mock transaction processing

### Phase 2 - Integration (Q2 2025)
- 🔄 Rust cryptographic modules
- 🔄 Real Dilithium/Kyber implementation
- 🔄 UPI sandbox integration
- 🔄 PostgreSQL database

### Phase 3 - Production (Q3-Q4 2025)
- 🔄 Hardware acceleration
- 🔄 Performance optimization
- 🔄 Security audits
- 🔄 Production deployment

## 🧪 Testing

### Mobile Tests
```bash
cd mobile
flutter test
```

### Backend Tests
```bash
cd backend
pytest
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For support and questions, please open an issue in the GitHub repository.

---

**Note**: This is a Phase 1 prototype implementation. The cryptographic operations are currently mocked for development purposes. Production implementation will use actual post-quantum cryptographic libraries.