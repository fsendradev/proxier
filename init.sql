CREATE TABLE IF NOT EXISTS users (
    username TEXT PRIMARY KEY,
    password TEXT NOT NULL
);

-- Insert a default user 'testuser' with password 'secret'
INSERT INTO users (username, password) VALUES ('testuser', 'secret') ON CONFLICT DO NOTHING;
