from pydantic import BaseModel,EmailStr

class LoginRequest(BaseModel):
    email:EmailStr
    password:str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token:str
    token_type:str="bearer"

class RefreshRequest(BaseModel):
    refresh_token:str

class ActivativateAccountRequest(BaseModel):
    token:str
    password:str

    class Config:
        min_anystr_length=8

class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str="bearer"
