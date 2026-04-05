from pydantic import BaseModel

class AssignRequest(BaseModel):
    parcelle_id:int

class SupervisorAssignRequest(BaseModel):
    forest_id:int

class AssignmentResponse(BaseModel):
    user_id:int
    parcelle_id:int|None

    class Config:
        from_attributes=True

class SupervisorAssignmentResponse(BaseModel):
    user_id:int
    forest_id:int|None

    class Config:
        from_attributes=True