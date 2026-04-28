-- Script de création de la base de données plante_db
-- À exécuter en tant que root : mysql -u root -p < setup_db.sql

CREATE DATABASE IF NOT EXISTS plante_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'plante_user'@'localhost' IDENTIFIED BY 'plante2024!';
GRANT ALL PRIVILEGES ON plante_db.* TO 'plante_user'@'localhost';
FLUSH PRIVILEGES;
