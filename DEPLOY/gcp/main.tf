terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable necessary APIs
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  name             = "${var.app_name}-db-instance"
  region           = var.region
  database_version = "POSTGRES_14"
  deletion_protection = false # For demo purposes

  settings {
    tier = "db-f1-micro"
  }
  depends_on = [google_project_service.sqladmin_api]
}

resource "google_sql_database" "database" {
  name     = "proxydb"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "proxyuser"
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}

# Cloud Run Service
resource "google_cloud_run_service" "default" {
  name     = "${var.app_name}-service"
  location = var.region

  template {
    spec {
      containers {
        image = var.image_uri
        env {
          name  = "DATABASE_URL"
          value = "postgres://proxyuser:${var.db_password}@/${google_sql_database.database.name}?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
        env {
          name  = "LOG_LEVEL"
          value = "3"
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  
  depends_on = [google_project_service.run_api]
}

# Allow unauthenticated invocations (Public Proxy)
resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
