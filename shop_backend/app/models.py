from sqlalchemy import Column, Integer, String, Float, Boolean
from .database import Base

class Product(Base):
    __tablename__ = "products"   # The name of the table in the DB

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, index=True, nullable=False)
    description = Column(String)
    price = Column(Float, nullable=False)
    currency = Column(String, default="EUR")
    image_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
