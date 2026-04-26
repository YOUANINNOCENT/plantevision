from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Iterator
import logging

from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    Float,
    String,
    Text,
    DateTime,
    Boolean,
    ForeignKey,
    func,
    inspect,
    text,
)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker, Session

# Configure database URL via environment variable.
# Fallback sur SQLite si DATABASE_URL n'est pas défini dans .env. Le .env
# contient normalement soit une URL MySQL, soit l'URL SQLite ci-dessous.
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///plante_dev.db')

# Options moteur adaptées à MySQL (ignorées si sqlite) :
# - pool_pre_ping : réouvre une connexion morte de manière transparente
# - pool_recycle : recycle les connexions avant le wait_timeout de MySQL (8h par défaut)
_engine_kwargs = {'echo': False, 'future': True}
if DATABASE_URL.startswith('mysql'):
    _engine_kwargs.update({'pool_pre_ping': True, 'pool_recycle': 3600})

# Create engine and session factory
engine = create_engine(DATABASE_URL, **_engine_kwargs)
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    future=True,
    # Empêche SQLAlchemy d'invalider les attributs des objets après commit.
    # Nécessaire parce que les helpers de db_service.py renvoient l'objet ORM
    # et la session est fermée juste après — sans ça, lire a.id à l'extérieur
    # déclenche DetachedInstanceError.
    expire_on_commit=False,
)
Base = declarative_base()


class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    # Code de réinitialisation (6 chiffres) + expiration. Effacés après usage.
    reset_token = Column(String(64), nullable=True)
    reset_token_expires = Column(DateTime(timezone=True), nullable=True)
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
    # plant_id : FK optionnelle vers plants.id (INT). Non utilisée tant qu'on n'a pas de table plants remplie.
    plant_id = Column(Integer, ForeignKey('plants.id', ondelete='SET NULL'), nullable=True)
    # plant_name : nom scientifique renvoyé par PlantNet (ex. "Lantana viburnoides").
    plant_name = Column(String(255), nullable=True)
    # category : comestible | medicinale | toxique | inconnu (déduit par Groq côté client)
    category = Column(String(32), nullable=True)
    image_path = Column(String(1024), nullable=True)
    result = Column(Text, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    location_label = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship('User', back_populates='analyses')
    plant = relationship('Plant', back_populates='analyses')


class Conversation(Base):
    __tablename__ = 'conversations'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=True)
    title = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship('User')
    messages = relationship('Message', back_populates='conversation', cascade='all, delete-orphan')


class Message(Base):
    __tablename__ = 'messages'
    id = Column(Integer, primary_key=True)
    conversation_id = Column(Integer, ForeignKey('conversations.id', ondelete='CASCADE'))
    role = Column(String(50), nullable=False)
    content = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    conversation = relationship('Conversation', back_populates='messages')


def init_db(drop_existing: bool = False) -> None:
    """Create all tables. Set drop_existing=True to drop tables first (dev only)."""
    if drop_existing:
        Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    # Migration légère : si des colonnes récentes manquent (base existante), les ajouter.
    try:
        insp = inspect(engine)
        if 'analyses' in insp.get_table_names():
            existing_cols = {c['name'] for c in insp.get_columns('analyses')}
            needed = {
                'latitude': 'FLOAT',
                'longitude': 'FLOAT',
                'location_label': 'VARCHAR(255)',
                'plant_name': 'VARCHAR(255)',
                'category': 'VARCHAR(32)',
            }
            with engine.begin() as conn:
                for col, sql_type in needed.items():
                    if col not in existing_cols:
                        conn.execute(text(f'ALTER TABLE analyses ADD COLUMN {col} {sql_type}'))

        # Colonnes reset_token sur la table users
        if 'users' in insp.get_table_names():
            existing_user_cols = {c['name'] for c in insp.get_columns('users')}
            user_needed = {
                'reset_token': 'VARCHAR(64)',
                'reset_token_expires': 'DATETIME',
            }
            with engine.begin() as conn:
                for col, sql_type in user_needed.items():
                    if col not in existing_user_cols:
                        conn.execute(text(f'ALTER TABLE users ADD COLUMN {col} {sql_type}'))
    except Exception as e:
        logging.getLogger(__name__).warning('Migration columns skipped: %s', e)


@contextmanager
def get_session() -> Iterator[Session]:
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
    logger = logging.getLogger(__name__)
    logger.info('Initializing database at %s', DATABASE_URL)
    init_db()
