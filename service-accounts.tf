# =============================================================================
# GCP Project Template - Service Accounts
# =============================================================================

# -----------------------------------------------------------------------------
# GKE Node Pool Service Account
# -----------------------------------------------------------------------------

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.gke_cluster_name}-nodes-sa"
  display_name = "GKE Node Pool Service Account"
  description  = "Service account for GKE cluster nodes"
  project      = var.project_id

  depends_on = [google_project_service.iam]
}

# GKE Node Pool Service Account IAM Bindings
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_resource_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# -----------------------------------------------------------------------------
# Compute Engine Service Account (for standalone VMs)
# -----------------------------------------------------------------------------

resource "google_service_account" "compute_engine" {
  account_id   = "compute-engine-sa"
  display_name = "Compute Engine Service Account"
  description  = "Service account for standalone Compute Engine VMs"
  project      = var.project_id

  depends_on = [google_project_service.iam]
}

# Compute Engine Service Account IAM Bindings
resource "google_project_iam_member" "compute_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compute_engine.email}"
}

resource "google_project_iam_member" "compute_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.compute_engine.email}"
}

# OS Login role for SSH access via IAM
resource "google_project_iam_member" "compute_os_login" {
  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.compute_engine.email}"
}
