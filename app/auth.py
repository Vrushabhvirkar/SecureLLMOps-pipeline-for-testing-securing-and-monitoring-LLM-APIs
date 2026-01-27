from fastapi import Header, HTTPException, Depends
from jose import jwt
from datetime import datetime, timedelta
import os  # ✅ NEW

# ✅ REPLACE config import with env-backed config
JWT_SECRET = os.getenv("JWT_SECRET")
APP_API_KEY = os.getenv("APP_API_KEY")
JWT_ALGO = os.getenv("JWT_ALGO", "HS256")
JWT_EXP_MINUTES = int(os.getenv("JWT_EXP_MINUTES", "60"))

if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET is missing")

if not APP_API_KEY:
    raise RuntimeError("APP_API_KEY is missing")


def verify_api_key(x_api_key: str = Header(None)):
    if x_api_key != APP_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")


def create_jwt(username: str):
    payload = {
        "sub": username,
        "exp": datetime.utcnow() + timedelta(minutes=JWT_EXP_MINUTES)
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGO)
    return token


# ✅ Full JWT validation
def verify_jwt(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid or Expired Token")

    token = authorization.replace("Bearer ", "")

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
        return payload["sub"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or Expired Token")

