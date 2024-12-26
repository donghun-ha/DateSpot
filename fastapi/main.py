"""
author: 
Description: 
Fixed: 
Usage: 
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import user as user
from pydantic import BaseModel
from user import router as user_router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 허용할 도메인 리스트
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class HealthCheckResponse(BaseModel):
    status: str
    message: str
    uptime: str

@app.get("/health", response_model=HealthCheckResponse)
async def health_check():
    """
    Health check endpoint
    """
    return {
        "status": "healthy",
        "message": "The server is running fine!",
        "uptime": "100%"  # Example additional info
    }

@app.get("/test", response_model=HealthCheckResponse)
async def health_check():
    """
    Health check endpoint
    """
    await user.get_redis_connection()
    user.connect()
    return {
        "status": "healthy",
        "message": "The server is running fine!",
        "uptime": "100%"  # Example additional info
    }

app.include_router(user_router, tags=["User Login"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host = "0.0.0.0", port = 6004)
    user.get_redis_connection()