import os
from contextlib import contextmanager
from typing import Iterator

from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Text,
    DateTime,
    Boolean,
    ForeignKey,
    func,
)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker

# Configure database URL via environment variable, fallback to sqlite file for dev
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///plante_dev.db')

# Create engine and session factory
engine = create_engine(DATABASE_URL, echo=False, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
Base = declarative_base()


class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    analyses = relationship('Analysis', back_populates='user', cascade='all, delete-orphan')


class Plant(Base):
    __tablename__ = 'plants'
    id = Column(Integer, primary_key=True)
    scientific_name = Column(String(255), index=True, nullable=True)
    common_name = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)

    analyses = relationship('Analysis', back_populates='plant')


class Analysis(Base):
    __tablename__ = 'analyses'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    plant_id = Column(Integer, ForeignKey('plants.id', ondelete='SET NULL'), nullable=True)
    image_path = Column(String(1024), nullable=True)
    result = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship('User', back_populates='analyses')
    plant = relationship('Plant', back_populates='analyses')


def init_db(drop_existing: bool = False) -> None:
    """Create all tables. Set drop_existing=True to drop tables first (dev only)."""
    if drop_existing:
        Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


@contextmanager
def get_session() -> Iterator[SessionLocal]:
    """Provide a transactional scope around a series of operations."""
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


if __name__ == '__main__':
    # Quick helper to initialize DB when running this file directly
    print('Initializing database at', DATABASE_URL)
    init_db()
