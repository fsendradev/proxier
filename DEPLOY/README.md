# Deployment Guide

This repository contains deployment configurations for AWS and GCP using Terraform.

## Directory Structure

- `aws/`: Terraform configuration for AWS (App Runner + RDS).
- `gcp/`: Terraform configuration for GCP (Cloud Run + Cloud SQL).
- `install_tools.sh`: Script to install Terraform, AWS CLI, and Google Cloud SDK.

## Prerequisites

Before starting, ensure you have the necessary tools installed. You can run the helper script:

```bash
./install_tools.sh
```

Then configure your credentials:
- AWS: `aws configure`
- GCP: `gcloud init`

## General Steps

1. **Build and Push Docker Image**:
   Before deploying, you need to build the Docker image and push it to a container registry (ECR for AWS, GCR/Artifact Registry for GCP).

   ```bash
   # Example for AWS ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   docker build -t proxyer .
   docker tag proxyer:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/proxyer:latest
   docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/proxyer:latest
   ```

2. **Choose your Cloud Provider**:
   Navigate to the corresponding directory (`DEPLOY/aws` or `DEPLOY/gcp`) and follow the `README.md` inside.

## Database Initialization

The Terraform scripts create the database instance but might not initialize the schema (`init.sql`). You may need to connect to the database manually or use a migration tool to run the `init.sql` script after deployment.

For **AWS App Runner**, you can temporarily allow public access to RDS or use a bastion host to run the SQL script.
For **GCP Cloud Run**, you can use the Cloud SQL Proxy to connect locally and run the script.
