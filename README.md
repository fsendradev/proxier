# Go Authenticated Proxy

A secure, high-performance web proxy written in Go, featuring support for both HTTP/HTTPS and SOCKS5 protocols on a single port. It includes built-in authentication via PostgreSQL and ad-blocking DNS integration.

## Features

- **Protocol Multiplexing**: Handles HTTP, HTTPS (CONNECT), and SOCKS5 traffic on the same port (default: 8080).
- **Authentication**: Secure user authentication backed by a PostgreSQL database.
- **Ad-Blocking**: Integrated AdGuard DNS (94.140.14.14) for privacy and ad-blocking.
- **Configurable Logging**: 4 levels of logging verbosity (Error, Info, Access, Debug).
- **Dockerized**: Ready for containerized deployment with a multi-stage Dockerfile.
- **Cloud Ready**: Terraform configurations included for AWS (App Runner) and GCP (Cloud Run).

## Quick Start

### Prerequisites

- Docker and Docker Compose installed.

### Local Development

1. **Start the services**:
   ```bash
   docker-compose up --build
   ```
   This will start the proxy server and a PostgreSQL database.

2. **Run Tests**:
   Use the included test script to verify functionality:
   ```bash
   ./test.sh
   ```
   You can specify the log level (1-4) as an argument:
   ```bash
   ./test.sh 4  # Run with Debug logging
   ```

### Default Credentials

The database is initialized with a default user:
- **Username**: `testuser`
- **Password**: `secret`

## Configuration

The application is configured via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Port to listen on | `8080` |
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `LOG_LEVEL` | Logging verbosity (1=Error, 2=Info, 3=Access, 4=Debug) | `3` |

## Deployment

Detailed deployment instructions and Terraform configurations are available in the [DEPLOY](DEPLOY/README.md) directory.

- **AWS**: Deploy to App Runner with RDS.
- **GCP**: Deploy to Cloud Run with Cloud SQL.

## Project Structure

- `auth/`: Authentication logic and database interaction.
- `pkg/logger/`: Custom logging package.
- `proxy/`: Core proxy server implementation (HTTP/SOCKS5).
- `DEPLOY/`: Terraform scripts and deployment guides.
- `Dockerfile`: Multi-stage build definition.
- `docker-compose.yml`: Local development environment.
