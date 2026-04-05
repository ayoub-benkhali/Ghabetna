from fastapi import Request,HTTPException,status
from jose import JWTError, jwt
from app.config import settings

"""
Decodes JWT locally (no roundtrip to auth-service).
Checks permissions for protected routes.
Public routes bypass auth entirely.
"""

SELF_ROUTES={
    ("GET","/api/users/me"),
    ("PUT","/api/users/me"),
}

PUBLIC_ROUTES={
    ("POST","/api/auth/login"),
    ("POST", "/api/auth/refresh"),
    ("POST", "/api/auth/activate"),
    ("POST", "/api/auth/logout"),
}

#(METHOD, path_prefix)-> req perm
ROUTE_PERMISSIONS: dict[tuple[str, str], str] = {
    
    #Users
    ("GET",    "/api/users"):     "user:read",
    ("POST",   "/api/users"):     "user:create",
    ("PUT",    "/api/users/"):    "user:update",
    ("DELETE", "/api/users/"):    "user:delete",

    # Roles
    ("GET",    "/api/roles"):     "role:read",
    ("POST",   "/api/roles"):     "role:create",
    ("PUT",    "/api/roles/"):    "role:update",
    ("DELETE", "/api/roles/"):    "role:delete",

    # Forests
    ("GET",    "/api/forests"):   "forest:read",
    ("POST",   "/api/forests"):   "forest:create",
    ("PUT",    "/api/forests/"):  "forest:update",
    ("DELETE", "/api/forests/"):  "forest:delete",

    # Services
    ("GET",    "/api/services"):  "service:read",
    ("POST",   "/api/services"):  "service:create",
    ("PUT",    "/api/services/"): "service:update",
    ("DELETE", "/api/services/"): "service:delete",

    # Assignments - agents
    ("GET",    "/api/assignments"):              "assignment:read",
    ("GET",    "/api/assignments/users/"):       "assignment:read",
    ("POST",   "/api/assignments/users/"):       "assignment:create",
    ("DELETE", "/api/assignments/users/"):       "assignment:delete",
    ("GET",    "/api/assignments/parcelles/"):   "assignment:read",

    # Assignments — supervisors
    ("GET",    "/api/assignments/supervisors/"):      "assignment:read",
    ("POST",   "/api/assignments/supervisors/"):      "assignment:create",
    ("DELETE", "/api/assignments/supervisors/"):      "assignment:delete",
    ("GET",    "/api/assignments/forests/"):          "assignment:read",
}

PARCELLE_PERMISSIONS = {
    "GET":    "parcelle:read",
    "POST":   "parcelle:create",
    "PUT":    "parcelle:update",
    "DELETE": "parcelle:delete",
}

def _get_required_permission(method: str, path: str) -> str | None:

    # Self routes are authenticated but no specific permission required
    if (method,path) in SELF_ROUTES:
        return None

    # Check parcelles first — more specific, avoids collision with /api/forests prefix
    if "/parcelles" in path:
        return PARCELLE_PERMISSIONS.get(method)

    for (route_method, prefix), perm in ROUTE_PERMISSIONS.items():
        if method == route_method and path.startswith(prefix):
            return perm
    return None

async def verify_and_inject(request:Request)-> dict| None:
    """
    Returns decoded JWT payload for authenticated routes.
    Returns None for public routes.
    Raises HTTPException on auth/permission failure.
    """
    path=request.url.path
    method=request.method

    if (method,path) in PUBLIC_ROUTES:
        return None
    
    auth_header=request.headers.get("Authorization","")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Missing Token")
    
    token=auth_header.split(" ",1)[1]
    try:
        payload=jwt.decode(token,settings.JWT_SECRET,algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type")!="access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Invalid Token Type")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Invalid or Expired Token")
    
    required= _get_required_permission(method,path)
    if required and required not in payload.get("permissions",[]):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,detail=f"Permission '{required} Required"
        )
    
    return payload
