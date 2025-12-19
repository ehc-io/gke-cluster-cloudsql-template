# =============================================================================
# GCP Projec Template - Artifact Registry
# =============================================================================

# -----------------------------------------------------------------------------
# Docker Repository
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.artifact_registry_name
  description   = "Docker container images repository"
  format        = var.artifact_registry_format
  project       = var.project_id

  labels = var.labels

  depends_on = [google_project_service.artifactregistry]
}

# -----------------------------------------------------------------------------
# IAM Bindings for Artifact Registry
# -----------------------------------------------------------------------------

# Allow GKE nodes to pull images from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "gke_nodes_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Allow Compute Engine service account to pull images (optional)
resource "google_artifact_registry_repository_iam_member" "compute_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.compute_engine.email}"
}
