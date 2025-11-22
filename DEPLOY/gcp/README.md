# GCP Deployment

This directory contains Terraform configuration to deploy the Proxyer to Google Cloud Platform using Cloud Run and Cloud SQL.

## Prerequisites

- Terraform installed
- Google Cloud SDK (`gcloud`) installed and authenticated
- Docker image pushed to Google Container Registry (GCR) or Artifact Registry

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan -var="project_id=YOUR_PROJECT_ID" -var="db_password=YOUR_SECURE_PASSWORD" -var="image_uri=gcr.io/YOUR_PROJECT/IMAGE"
   ```

3. Apply the deployment:
   ```bash
   terraform apply -var="project_id=YOUR_PROJECT_ID" -var="db_password=YOUR_SECURE_PASSWORD" -var="image_uri=gcr.io/YOUR_PROJECT/IMAGE"
   ```
