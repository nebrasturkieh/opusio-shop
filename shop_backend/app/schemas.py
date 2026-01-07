from typing import Optional
from pydantic import BaseModel


# Shared fields between different product schemas
class ProductBase(BaseModel):
    name: str
    slug: str
    description: Optional[str] = None
    price: float
    currency: str = "EUR"
    image_url: Optional[str] = None
    is_active: bool = True


# Schema used when creating a product (client -> API)
class ProductCreate(ProductBase):
    pass


# Schema used when sending a product back to the client (API -> client)
class Product(ProductBase):
    id: int  # DB-generated ID

    class Config:
        orm_mode = True
