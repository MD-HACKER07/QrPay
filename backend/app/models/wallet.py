from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class WalletCreate(BaseModel):
    name: str
    public_key: str
    kyber_public_key: str

class WalletResponse(BaseModel):
    id: str
    name: str
    address: str
    public_key: str
    balance: float
    created_at: datetime
    
    class Config:
        from_attributes = True

class WalletBalance(BaseModel):
    balance: float
    last_updated: datetime