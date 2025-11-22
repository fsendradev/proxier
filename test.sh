#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Default log level
LOG_LEVEL=${1:-3}

echo "Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "Starting services with LOG_LEVEL=$LOG_LEVEL..."
LOG_LEVEL=$LOG_LEVEL docker-compose up -d --build

echo "Waiting for services to be ready..."
sleep 5

echo "Testing Proxy with Authentication..."
# Test with valid credentials
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -x http://testuser:secret@localhost:8080 https://www.google.com)

if [ "$RESPONSE" == "200" ]; then
    echo -e "${GREEN}SUCCESS: Proxy request with valid credentials worked! (Status: $RESPONSE)${NC}"
else
    echo -e "${RED}FAILURE: Proxy request failed. Status: $RESPONSE${NC}"
    docker-compose logs
    exit 1
fi

echo "Testing Proxy without Authentication (Should fail)..."
# Test without credentials
RESPONSE_NO_AUTH=$(curl -s -o /dev/null -w "%{http_code}" -x http://localhost:8080 https://www.google.com)

if [ "$RESPONSE_NO_AUTH" == "407" ]; then
    echo -e "${GREEN}SUCCESS: Proxy correctly required authentication. (Status: $RESPONSE_NO_AUTH)${NC}"
else
    echo -e "${RED}FAILURE: Proxy did not require authentication as expected. Status: $RESPONSE_NO_AUTH${NC}"
    exit 1
fi

echo "Testing SOCKS5 Proxy..."
# Test SOCKS5 with credentials
RESPONSE_SOCKS=$(curl -s -o /dev/null -w "%{http_code}" --socks5 user:password@localhost:8080 https://www.google.com)
# Note: curl might return 000 if socks fails, or the http code if it works.
# Wait, curl --socks5 uses the proxy to connect.
# If we use --socks5-hostname it does DNS on remote.
# Let's use --socks5-hostname user:password@localhost:8080

RESPONSE_SOCKS=$(curl -s -o /dev/null -w "%{http_code}" --socks5-basic --socks5-hostname testuser:secret@localhost:8080 https://www.google.com)

if [ "$RESPONSE_SOCKS" == "200" ]; then
    echo -e "${GREEN}SUCCESS: SOCKS5 request with valid credentials worked! (Status: $RESPONSE_SOCKS)${NC}"
else
    echo -e "${RED}FAILURE: SOCKS5 request failed. Status: $RESPONSE_SOCKS${NC}"
    exit 1
fi

echo -e "${GREEN}All tests passed!${NC}"
