-- init_db.sql
-- Schéma PostgreSQL pour l'application "plante"

-- Utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    mot_de_passe TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Plantes référencées
CREATE TABLE IF NOT EXISTS plants (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150),
    type VARCHAR(50), -- comestible, toxique, médicinale
    description TEXT
);

-- Scans réalisés par les utilisateurs
CREATE TABLE IF NOT EXISTS scans (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT,
    date_scan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    localisation VARCHAR(255)
);

-- Résultats d'analyse liés aux scans
CREATE TABLE IF NOT EXISTS analyses (
    id SERIAL PRIMARY KEY,
    scan_id INT REFERENCES scans(id) ON DELETE CASCADE,
    plante_id INT REFERENCES plants(id),
    sante VARCHAR(50),
    toxicite VARCHAR(50),
    usage_medicinal TEXT,
    impact_environnement TEXT
);

-- Historique de chat / assistant IA
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    message TEXT,
    reponse TEXT,
    date_message TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes utiles
CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_analyses_scan_id ON analyses(scan_id);

-- Exemple d'utilisation :
-- psql -U postgres -c "CREATE DATABASE plante_db;"
-- psql -U postgres -d plante_db -f db/init_db.sql
