from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from routes import wallet, transaction, auth

# Create FastAPI app
app = FastAPI(
    title="QrPay Backend API",
    description="Quantum-Resistant UPI Wallet Backend",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(wallet.router, prefix="/api/wallet", tags=["Wallet"])
app.include_router(transaction.router, prefix="/api/transaction", tags=["Transaction"])

@app.get("/")
async def root():
    return {
        "message": "QrPay Backend API",
        "version": "1.0.0",
        "status": "running",
        "features": [
            "Quantum-resistant cryptography",
            "UPI integration",
            "Secure wallet management"
        ]
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": "2025-09-12T16:02:00Z"}

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal server error: {str(exc)}"}
    )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )