# =============================================================================
# GCP Foundation Template - Cloud SQL Database
# =============================================================================

# -----------------------------------------------------------------------------
# Cloud SQL PostgreSQL Instance
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "postgres" {
  name                = var.cloudsql_instance_name
  database_version    = var.cloudsql_database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = true

  settings {
    tier              = var.cloudsql_tier
    availability_type = var.cloudsql_availability_type
    disk_size         = var.cloudsql_disk_size
    disk_type         = var.cloudsql_disk_type
    disk_autoresize   = true

    # IP configuration - Private IP only
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id
      enable_private_path_for_google_cloud_services = true
    }

    # Backup configuration
    backup_configuration {
      enabled                        = var.cloudsql_backup_enabled
      start_time                     = var.cloudsql_backup_start_time
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3  # 3 AM UTC
      update_track = "stable"
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # Database flags (optional - uncomment as needed)
    # database_flags {
    #   name  = "log_checkpoints"
    #   value = "on"
    # }
    # database_flags {
    #   name  = "log_connections"
    #   value = "on"
    # }
    # database_flags {
    #   name  = "log_disconnections"
    #   value = "on"
    # }

    # User labels
    user_labels = var.labels
  }

  depends_on = [
    google_project_service.sqladmin,
    google_service_networking_connection.private_vpc_connection
  ]
}

# -----------------------------------------------------------------------------
# Default Database
# -----------------------------------------------------------------------------

resource "google_sql_database" "default" {
  name     = "default"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# -----------------------------------------------------------------------------
# Database User (application user)
# -----------------------------------------------------------------------------
# Note: For production, use Secret Manager to store passwords
# or use Cloud SQL IAM authentication

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
  project  = var.project_id

  # Deletion policy
  deletion_policy = "ABANDON"
}

# -----------------------------------------------------------------------------
# Store Database Password in Secret Manager (optional but recommended)
# -----------------------------------------------------------------------------

resource "google_project_service" "secretmanager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.cloudsql_instance_name}-app-user-password"
  project   = var.project_id

  labels = var.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Allow GKE nodes to access the secret
resource "google_secret_manager_secret_iam_member" "gke_nodes_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_nodes.email}"
}
