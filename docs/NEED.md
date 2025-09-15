# NEED.md  

## 🚀 Project Name  
**QrPay: Quantum-Resistant UPI Wallet**  

---

## 📌 Vision  
The future of payments must survive **quantum attacks**. QrPay integrates **post-quantum cryptography (PQC)** into the UPI ecosystem to ensure digital transactions remain secure in the post-quantum era.  

We will build **from scratch**:  
- A **mobile wallet app** (Flutter).  
- A **cryptographic core** (Rust → compiled into Flutter plugin).  
- A **backend server** (Python + Rust) to integrate with **UPI sandbox**.  

---

## 🎯 Goals  
1. Implement **Dilithium (signatures)** and **Kyber (key exchange)** for quantum-safe transactions.  
2. Build a **cross-platform wallet app** (Android + iOS).  
3. Secure **key storage** with device hardware keystore.  
4. Support **mock payments first**, then integrate with **UPI sandbox API**.  
5. Ensure compliance with **RBI & NIST PQC standards**.  

---

## 🏗️ Tech Stack  
### Core Cryptography  
- **Rust** → PQC implementation (Dilithium + Kyber).  
- Compile to **FFI** or native plugins for Flutter.  

### Mobile App  
- **Flutter (Dart)** → Wallet UI + transaction flow.  
- Libraries:  
  - `flutter_secure_storage` → secure key storage.  
  - `go_router` → wallet navigation.  

### Backend  
- **Python (FastAPI)** → REST APIs for UPI integration.  
- **Rust modules** → heavy PQC ops if needed on server.  
- Database: **PostgreSQL** (store transactions, user mapping).  

---

## 🔑 Features (Phase-wise)  

### Phase 1 – Prototype  
- Generate **Dilithium + Kyber key pairs** in Rust.  
- Store private keys securely.  
- Sign and verify **mock transactions**.  
- Basic Flutter UI (wallet create, send, receive).  

### Phase 2 – Integration  
- Connect Flutter app to **backend API**.  
- Implement **key exchange with Kyber**.  
- Encrypt/decrypt transaction payloads.  
- UPI sandbox integration.  

### Phase 3 – Optimization  
- Batch signing for speed.  
- GPU/Hardware acceleration (if possible).  
- Compression (zlib) for large keys/signatures.  

---

## 📂 Project Structure  
```
qrpay/
│── mobile/              # Flutter wallet
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   ├── android/
│   ├── ios/
│   └── pqcrypto/        # Rust plugin for PQC
│── backend/             # Python + Rust APIs
│   ├── app/
│   ├── routes/
│   └── requirements.txt
│── docs/                # Documentation
│   ├── NEED.md
│   ├── ARCHITECTURE.md
│── tests/               # Unit + Integration tests
```

---

## 🛡️ Security Considerations  
- Use **hardware-backed keystore** (Android Keystore / iOS Secure Enclave).  
- Follow **constant-time implementations** (prevent side-channel attacks).  
- Ensure **compliance** with RBI & GDPR.  
- Regular **key rotation**.  

---

## 📅 Roadmap  
- **Q1 2025** → Prototype wallet with mock payments.  
- **Q2 2025** → Integrate PQC + UPI sandbox.  
- **Q3 2025** → Beta release with real PQC-protected transactions.  
- **Q4 2025** → Full rollout + optimization.  
