from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# 1) Where is our database? (SQLite file in the project folder)
DATABASE_URL = "sqlite:///./shop.db"

# 2) Create the engine (the "connection factory")
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},  # needed only for SQLite
)

# 3) SessionLocal = object that will give us DB sessions
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# 4) Base class for our ORM models (tables will inherit from this)
Base = declarative_base()


# 5) Dependency for FastAPI routes: gives a DB session and closes it after the request
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
