# AWS Deployment Guide

This proxy is containerized and ready for deployment on AWS. To deploy in different countries (regions), you can replicate the deployment in each desired AWS Region (e.g., `us-east-1`, `eu-central-1`, `ap-northeast-1`).

## Prerequisites
- AWS CLI installed and configured.
- Docker installed.

## Option 1: AWS App Runner (Easiest)
App Runner handles the container and load balancing automatically.

1.  **Push Image to ECR**:
    ```bash
    # Create repo
    aws ecr create-repository --repository-name proxyer
    
    # Login
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
    
    # Build & Push
    docker build -t proxyer .
    docker tag proxyer:latest <account-id>.dkr.ecr.<region>.amazonaws.com/proxyer:latest
    docker push <account-id>.dkr.ecr.<region>.amazonaws.com/proxyer:latest
    ```

2.  **Create App Runner Service**:
    - Go to AWS Console > App Runner.
    - Create Service > Source: Container Registry.
    - Select the image you pushed.
    - **Configuration**:
        - Port: `8080`
        - Environment Variables:
            - `DATABASE_URL`: Connection string to your PostgreSQL (RDS or Aurora).
            - `PORT`: `8080`

## Option 2: EC2 with Docker Compose (Cheapest/Manual)
Good for specific IP requirements in different regions.

1.  **Launch EC2 Instance** in the desired region (e.g., `us-east-1`).
2.  **Install Docker & Docker Compose** on the instance.
3.  **Copy Files**: `docker-compose.yml`, `Dockerfile`, `init.sql`, and source code (or just pull the image from ECR).
4.  **Run**:
    ```bash
    docker-compose up -d
    ```
    *Note: For production, use a managed RDS database instead of the local postgres container in docker-compose, and update `DATABASE_URL` accordingly.*

## Database (PostgreSQL)
For a multi-region setup, you have two main options:
1.  **Centralized DB**: One RDS instance in a main region. All proxies connect to it. (Higher latency for auth checks from far regions).
2.  **Replicated DB**: Read replicas in each region or Amazon Aurora Global Database for low-latency reads in every region.

## Testing
Once deployed, configure your browser or client to use the proxy IP/DNS and port 8080.
**Auth**: `testuser` / `secret` (or whatever you configured in DB).
