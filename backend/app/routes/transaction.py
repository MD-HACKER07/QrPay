from fastapi import APIRouter, HTTPException
from typing import List
import uuid
from datetime import datetime
from ..models.transaction import (
    TransactionCreate, 
    TransactionResponse, 
    TransactionVerify,
    TransactionType,
    TransactionStatus
)
from ..services.crypto_service import CryptoService

router = APIRouter()

# Mock database - In production, use PostgreSQL
mock_transactions = {}

@router.post("/send", response_model=TransactionResponse)
async def send_transaction(transaction_data: TransactionCreate):
    """Process a send transaction with quantum-resistant signature"""
    try:
        # Verify signature (mock implementation)
        # In production, this would verify Dilithium signature
        if not transaction_data.signature.startswith("qrpay_sig_"):
            raise HTTPException(status_code=400, detail="Invalid signature format")
        
        # Generate transaction ID and hash
        tx_id = str(uuid.uuid4())
        tx_hash = f"qrpay_tx_{tx_id[:16]}"
        
        # Create transaction record
        transaction = {
            "id": tx_id,
            "from_address": transaction_data.from_address,
            "to_address": transaction_data.to_address,
            "amount": transaction_data.amount,
            "description": transaction_data.description,
            "type": TransactionType.SEND,
            "status": TransactionStatus.COMPLETED,  # Mock completion
            "signature": transaction_data.signature,
            "tx_hash": tx_hash,
            "timestamp": datetime.now()
        }
        
        # Store in mock database
        mock_transactions[tx_id] = transaction
        
        return TransactionResponse(**transaction)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process transaction: {str(e)}")

@router.post("/verify", response_model=dict)
async def verify_transaction(verify_data: TransactionVerify):
    """Verify a transaction signature using post-quantum cryptography"""
    try:
        # Mock verification - In production, use actual Dilithium verification
        is_valid = CryptoService.verify_signature(
            verify_data.public_key,
            verify_data.transaction_data,
            verify_data.signature
        )
        
        return {
            "valid": is_valid,
            "algorithm": "Dilithium",
            "verified_at": datetime.now()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to verify signature: {str(e)}")

@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(transaction_id: str):
    """Get transaction details by ID"""
    if transaction_id not in mock_transactions:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    return TransactionResponse(**mock_transactions[transaction_id])

@router.get("/wallet/{wallet_address}", response_model=List[TransactionResponse])
async def get_wallet_transactions(wallet_address: str, limit: int = 50):
    """Get transaction history for a wallet address"""
    transactions = []
    
    for tx in mock_transactions.values():
        if tx["from_address"] == wallet_address or tx["to_address"] == wallet_address:
            # Determine transaction type from perspective of this wallet
            if tx["from_address"] == wallet_address:
                tx["type"] = TransactionType.SEND
            else:
                tx["type"] = TransactionType.RECEIVE
            
            transactions.append(TransactionResponse(**tx))
    
    # Sort by timestamp (newest first) and limit results
    transactions.sort(key=lambda x: x.timestamp, reverse=True)
    return transactions[:limit]

@router.get("/", response_model=List[TransactionResponse])
async def get_all_transactions(limit: int = 100):
    """Get all transactions (admin endpoint)"""
    transactions = [TransactionResponse(**tx) for tx in mock_transactions.values()]
    transactions.sort(key=lambda x: x.timestamp, reverse=True)
    return transactions[:limit]