# AWS Deployment

This directory contains Terraform configuration to deploy the Proxyer to AWS using App Runner and RDS.

## Prerequisites

- Terraform installed
- AWS CLI configured
- Docker image pushed to ECR (Private or Public)

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan -var="db_password=YOUR_SECURE_PASSWORD" -var="image_identifier=YOUR_ECR_IMAGE_URI"
   ```

3. Apply the deployment:
   ```bash
   terraform apply -var="db_password=YOUR_SECURE_PASSWORD" -var="image_identifier=YOUR_ECR_IMAGE_URI"
   ```
