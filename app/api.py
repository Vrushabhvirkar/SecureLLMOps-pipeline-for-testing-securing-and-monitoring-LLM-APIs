from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from auth import verify_api_key, verify_jwt, create_jwt
import os
from dotenv import load_dotenv
import sys
sys.path.append("../scanner")

from scanner_runner import run_security_scan


load_dotenv("../.env")

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

class LoginRequest(BaseModel):
    username: str
    password: str

class ChatRequest(BaseModel):
    prompt: str

@app.post("/login")
def login(data: LoginRequest):
    if data.username == "admin" and data.password == "pass123":
        token = create_jwt(data.username)
        return {"access_token": token}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/chat")
def chat(
    data: ChatRequest,
    api_key: str = Depends(verify_api_key),
    user: str = Depends(verify_jwt)
):
    # Local LLM backend
    fake_response = f"[LOCAL LLM] Response to: {data.prompt}"

    # Run custom vulnerability scanner
    scan_result = run_security_scan(data.prompt, fake_response)

    return {
        "user": user,
        "prompt": data.prompt,
        "response": fake_response,
        "security_scan": scan_result,
        "backend": "local-fallback"
    }

