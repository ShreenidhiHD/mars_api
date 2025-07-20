from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, List
from datetime import datetime
import uuid
from enum import Enum

class MessageDirection(str, Enum):
    INCOMING = "incoming"
    OUTGOING = "outgoing"

class User(SQLModel, table=True):
    __tablename__ = "users"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    session_id: str = Field(unique=True, index=True, default_factory=lambda: str(uuid.uuid4()))
    email: Optional[str] = Field(default=None, index=True)
    phone_number: Optional[str] = Field(default=None, index=True)
    ip_address: str = Field(index=True)
    user_agent: Optional[str] = None
    device_fingerprint: Optional[str] = Field(default=None, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_active: datetime = Field(default_factory=datetime.utcnow)
    chats: List["Chat"] = Relationship(back_populates="user")

class Chat(SQLModel, table=True):
    __tablename__ = "chats"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    session_id: str = Field(foreign_key="users.session_id", index=True)
    direction: MessageDirection = Field(index=True)
    text: str
    metadata: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow, index=True)
    
    user: Optional[User] = Relationship(back_populates="chats")
