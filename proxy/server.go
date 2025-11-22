package proxy

import (
	"context"
	"encoding/base64"
	"io"
	"net"
	"net/http"
	"strings"
	"time"

	"proxyer/auth"
	"proxyer/pkg/logger"
)

type Server struct {
	auth      *auth.Service
	dialer    *net.Dialer
	transport *http.Transport
	logger    *logger.Logger
}

func NewServer(auth *auth.Service, logger *logger.Logger) *Server {
	// AdGuard DNS
	dnsServer := "94.140.14.14:53"

	resolver := &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{
				Timeout: time.Millisecond * time.Duration(10000),
			}
			return d.DialContext(ctx, "udp", dnsServer)
		},
	}

	dialer := &net.Dialer{
		Timeout:  30 * time.Second,
		KeepAlive: 30 * time.Second,
		Resolver: resolver,
	}

	transport := &http.Transport{
		DialContext:           dialer.DialContext,
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	return &Server{
		auth:      auth,
		dialer:    dialer,
		transport: transport,
		logger:    logger,
	}
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 1. Authenticate
	user, ok := s.checkAuth(r)
	if !ok {
		s.logger.Debug("Auth failed from %s", r.RemoteAddr)
		w.Header().Set("Proxy-Authenticate", "Basic realm=\"Proxy\"")
		http.Error(w, "Proxy Authentication Required", http.StatusProxyAuthRequired)
		return
	}

	// 2. Handle HTTPS (CONNECT)
	if r.Method == http.MethodConnect {
		s.handleTunneling(w, r, user)
	} else {
		// 3. Handle HTTP
		s.handleHTTP(w, r, user)
	}
}

func (s *Server) checkAuth(r *http.Request) (string, bool) {
	authHeader := r.Header.Get("Proxy-Authorization")
	if authHeader == "" {
		return "", false
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || parts[0] != "Basic" {
		return "", false
	}

	payload, err := base64.StdEncoding.DecodeString(parts[1])
	if err != nil {
		return "", false
	}

	pair := strings.SplitN(string(payload), ":", 2)
	if len(pair) != 2 {
		return "", false
	}

	return pair[0], s.auth.ValidateUser(pair[0], pair[1])
}

func (s *Server) handleTunneling(w http.ResponseWriter, r *http.Request, user string) {
	destConn, err := s.dialer.Dial("tcp", r.Host)
	if err != nil {
		s.logger.Debug("Failed to dial %s: %v", r.Host, err)
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	
	// Log successful access
	s.logger.Access("CONNECT %s from %s (User: %s)", r.Host, r.RemoteAddr, user)

	w.WriteHeader(http.StatusOK)
	hijacker, ok := w.(http.Hijacker)
	if !ok {
		s.logger.Error("Hijacking not supported")
		http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
		destConn.Close()
		return
	}
	clientConn, _, err := hijacker.Hijack()
	if err != nil {
		s.logger.Error("Hijack error: %v", err)
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		destConn.Close()
		return
	}
	go transfer(destConn, clientConn)
	go transfer(clientConn, destConn)
}

func (s *Server) handleHTTP(w http.ResponseWriter, r *http.Request, user string) {
	resp, err := s.transport.RoundTrip(r)
	if err != nil {
		s.logger.Debug("Failed to roundtrip %s: %v", r.Host, err)
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	
	// Log successful access
	s.logger.Access("%s %s from %s (User: %s)", r.Method, r.Host, r.RemoteAddr, user)

	defer resp.Body.Close()
	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func transfer(destination io.WriteCloser, source io.ReadCloser) {
	defer destination.Close()
	defer source.Close()
	io.Copy(destination, source)
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}
