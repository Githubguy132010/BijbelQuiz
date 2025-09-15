from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class APIKey(Base):
    __tablename__ = "api_keys"
    id = Column(Integer, primary_key=True)
    user_email = Column(String, unique=True)
    api_key = Column(String, unique=True)
    active = Column(Boolean, default=True)
