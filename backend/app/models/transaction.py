from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class TransactionType(str, Enum):
    SEND = "send"
    RECEIVE = "receive"

class TransactionStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"

class TransactionCreate(BaseModel):
    from_address: str
    to_address: str
    amount: float
    description: Optional[str] = ""
    signature: str

class TransactionResponse(BaseModel):
    id: str
    from_address: str
    to_address: str
    amount: float
    description: str
    type: TransactionType
    status: TransactionStatus
    signature: str
    tx_hash: Optional[str] = None
    timestamp: datetime
    
    class Config:
        from_attributes = True

class TransactionVerify(BaseModel):
    transaction_data: str
    signature: str
    public_key: str