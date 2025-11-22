package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"

	"proxyer/auth"
	"proxyer/pkg/logger"
	"proxyer/proxy"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize Logger
	logLevelStr := os.Getenv("LOG_LEVEL")
	logLevel := 3 // Default to Access level
	if logLevelStr != "" {
		fmt.Sscanf(logLevelStr, "%d", &logLevel)
	}
	appLogger := logger.New(logLevel)

	// Initialize Auth Service
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		appLogger.Error("DATABASE_URL environment variable is required")
		os.Exit(1)
	}

	authService, err := auth.NewService(dbURL)
	if err != nil {
		appLogger.Error("Failed to initialize auth service: %v", err)
		os.Exit(1)
	}
	defer authService.Close()

	// Initialize HTTP Proxy Server
	httpProxy := proxy.NewServer(authService, appLogger)

	// Initialize SOCKS5 Proxy Server
	socksProxy, err := proxy.NewSocksServer(authService, appLogger)
	if err != nil {
		appLogger.Error("Failed to initialize SOCKS5 server: %v", err)
		os.Exit(1)
	}

	// Start Listener
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		appLogger.Error("Failed to listen on :%s: %v", port, err)
		os.Exit(1)
	}
	appLogger.Info("Starting multi-protocol proxy on :%s (Log Level: %d)", port, logLevel)

	for {
		conn, err := listener.Accept()
		if err != nil {
			appLogger.Debug("Accept error: %v", err)
			continue
		}

		go handleConnection(conn, httpProxy, socksProxy, appLogger)
	}
}

func handleConnection(conn net.Conn, httpProxy *proxy.Server, socksProxy *proxy.SocksServer, logger *logger.Logger) {
	// Use a buffered reader to peek at the first byte
	reader := bufio.NewReader(conn)
	
	// Peek 4 bytes to see methods
	peekCount := 4
	header, err := reader.Peek(peekCount)
	if err != nil {
		// If less than 4 bytes, it might still be valid if it's a short packet, but let's just handle what we have
		if err != io.EOF && len(header) == 0 {
			conn.Close()
			return
		}
	}

	// Create a wrapper connection that includes the buffered data
	bufferedConn := &BufferedConn{
		Conn:   conn,
		Reader: reader,
	}

	if len(header) > 0 && header[0] == 0x05 {
		// SOCKS5
		logger.Debug("Handling SOCKS5 connection from %s. Header: %x", conn.RemoteAddr(), header)
		if err := socksProxy.ServeConn(bufferedConn); err != nil {
			logger.Debug("SOCKS5 error: %v", err)
		}
	} else {
		// Assume HTTP/HTTPS
		server := &http.Server{
			Handler: httpProxy,
			ErrorLog: log.New(io.Discard, "", 0), // Suppress default http server logs, we handle them
		}
		server.Serve(&SingleConnListener{conn: bufferedConn})
	}
}

// BufferedConn wraps a net.Conn and a bufio.Reader to allow reading buffered data
type BufferedConn struct {
	net.Conn
	Reader *bufio.Reader
}

func (b *BufferedConn) Read(p []byte) (int, error) {
	return b.Reader.Read(p)
}

// SingleConnListener is a listener that returns a single connection and then closes
type SingleConnListener struct {
	conn net.Conn
	done bool
}

func (l *SingleConnListener) Accept() (net.Conn, error) {
	if l.done {
		return nil, net.ErrClosed
	}
	l.done = true
	return l.conn, nil
}

func (l *SingleConnListener) Close() error {
	return nil
}

func (l *SingleConnListener) Addr() net.Addr {
	return l.conn.LocalAddr()
}
