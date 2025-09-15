from fastapi import APIRouter, HTTPException, Depends
from typing import List
import uuid
from datetime import datetime
from ..models.wallet import WalletCreate, WalletResponse, WalletBalance
from ..services.crypto_service import CryptoService

router = APIRouter()

# Mock database - In production, use PostgreSQL
mock_wallets = {}

@router.post("/create", response_model=WalletResponse)
async def create_wallet(wallet_data: WalletCreate):
    """Create a new quantum-resistant wallet"""
    try:
        # Generate unique wallet ID and address
        wallet_id = str(uuid.uuid4())
        address = CryptoService.generate_address(wallet_data.public_key)
        
        # Create wallet record
        wallet = {
            "id": wallet_id,
            "name": wallet_data.name,
            "address": address,
            "public_key": wallet_data.public_key,
            "kyber_public_key": wallet_data.kyber_public_key,
            "balance": 1000.0,  # Mock initial balance
            "created_at": datetime.now()
        }
        
        # Store in mock database
        mock_wallets[wallet_id] = wallet
        
        return WalletResponse(**wallet)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create wallet: {str(e)}")

@router.get("/{wallet_id}", response_model=WalletResponse)
async def get_wallet(wallet_id: str):
    """Get wallet information by ID"""
    if wallet_id not in mock_wallets:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    return WalletResponse(**mock_wallets[wallet_id])

@router.get("/{wallet_id}/balance", response_model=WalletBalance)
async def get_wallet_balance(wallet_id: str):
    """Get wallet balance"""
    if wallet_id not in mock_wallets:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    wallet = mock_wallets[wallet_id]
    return WalletBalance(
        balance=wallet["balance"],
        last_updated=datetime.now()
    )

@router.get("/address/{address}", response_model=WalletResponse)
async def get_wallet_by_address(address: str):
    """Get wallet information by address"""
    for wallet in mock_wallets.values():
        if wallet["address"] == address:
            return WalletResponse(**wallet)
    
    raise HTTPException(status_code=404, detail="Wallet not found")

@router.put("/{wallet_id}/balance")
async def update_wallet_balance(wallet_id: str, new_balance: float):
    """Update wallet balance (internal use)"""
    if wallet_id not in mock_wallets:
        raise HTTPException(status_code=404, detail="Wallet not found")
    
    mock_wallets[wallet_id]["balance"] = new_balance
    return {"message": "Balance updated successfully"}