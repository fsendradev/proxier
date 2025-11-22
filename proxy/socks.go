package proxy

import (
	"io"
	"log"
	"net"

	"github.com/armon/go-socks5"
	"proxyer/auth"
	"proxyer/pkg/logger"
)

type SocksServer struct {
	server *socks5.Server
	auth   *auth.Service
	logger *logger.Logger
}

// AuthAdapter adapts our auth.Service to socks5.CredentialStore
type AuthAdapter struct {
	auth   *auth.Service
	logger *logger.Logger
}

func (a *AuthAdapter) Valid(user, password string) bool {
	a.logger.Debug("[SOCKS5] Authenticating user: %s", user)
	valid := a.auth.ValidateUser(user, password)
	if valid {
		a.logger.Access("[SOCKS5] User %s authenticated", user)
	} else {
		a.logger.Debug("[SOCKS5] Auth failed for user %s", user)
	}
	return valid
}

func NewSocksServer(authService *auth.Service, logger *logger.Logger) (*SocksServer, error) {
	conf := &socks5.Config{
		Credentials: &AuthAdapter{auth: authService, logger: logger},
		Logger:      log.New(io.Discard, "", 0), // Disable internal logger, we handle it
	}

	server, err := socks5.New(conf)
	if err != nil {
		return nil, err
	}

	return &SocksServer{
		server: server,
		auth:   authService,
		logger: logger,
	}, nil
}

func (s *SocksServer) ServeConn(conn net.Conn) error {
	return s.server.ServeConn(conn)
}
