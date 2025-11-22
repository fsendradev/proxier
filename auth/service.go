package auth

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

type Service struct {
	db *sql.DB
}

func NewService(dbURL string) (*Service, error) {
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		return nil, fmt.Errorf("error opening database: %w", err)
	}

	// Retry connection logic
	for i := 0; i < 10; i++ {
		err = db.Ping()
		if err == nil {
			break
		}
		fmt.Printf("Waiting for database... (%d/10)\n", i+1)
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		return nil, fmt.Errorf("error connecting to database after retries: %w", err)
	}

	// Ensure table exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			username TEXT PRIMARY KEY,
			password TEXT NOT NULL
		);
	`)
	if err != nil {
		return nil, fmt.Errorf("error creating table: %w", err)
	}

	return &Service{db: db}, nil
}

func (s *Service) Close() error {
	return s.db.Close()
}

func (s *Service) ValidateUser(username, password string) bool {
	var storedPassword string
	err := s.db.QueryRow("SELECT password FROM users WHERE username = $1", username).Scan(&storedPassword)
	if err != nil {
		if err != sql.ErrNoRows {
			fmt.Printf("Database error: %v\n", err)
		}
		return false
	}
	
	// In a real app, use bcrypt. For this example, we'll do simple comparison as requested/implied simplicity.
	// If you want bcrypt, we can add it.
	return storedPassword == password
}
