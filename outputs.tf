# =============================================================================
# GCP Foundation Template - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Project Information
# -----------------------------------------------------------------------------

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.main.name
}

output "vpc_self_link" {
  description = "The self link of the VPC"
  value       = google_compute_network.main.self_link
}

output "gke_subnet_id" {
  description = "The ID of the GKE subnet"
  value       = google_compute_subnetwork.gke.id
}

output "gke_subnet_name" {
  description = "The name of the GKE subnet"
  value       = google_compute_subnetwork.gke.name
}

output "database_subnet_id" {
  description = "The ID of the database subnet"
  value       = google_compute_subnetwork.database.id
}

output "database_subnet_name" {
  description = "The name of the database subnet"
  value       = google_compute_subnetwork.database.name
}

output "dmz_subnet_id" {
  description = "The ID of the DMZ subnet"
  value       = google_compute_subnetwork.dmz.id
}

output "workload_subnet_ids" {
  description = "Map of workload subnet IDs"
  value       = { for k, v in google_compute_subnetwork.workload : k => v.id }
}

output "nat_ip" {
  description = "The NAT IP address for outbound internet access"
  value       = google_compute_router_nat.main.nat_ips
}

# -----------------------------------------------------------------------------
# GKE Outputs
# -----------------------------------------------------------------------------

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster (private)"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "gke_node_pool_name" {
  description = "The name of the GKE node pool"
  value       = google_container_node_pool.main.name
}

output "gke_get_credentials_command" {
  description = "Command to get GKE credentials (run from jump host)"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.region} --project ${var.project_id} --internal-ip"
}

# -----------------------------------------------------------------------------
# Virtual Machines Outputs
# -----------------------------------------------------------------------------

output "jumphost_name" {
  description = "The name of the jump host VM"
  value       = google_compute_instance.jumphost.name
}

output "jumphost_internal_ip" {
  description = "The internal IP of the jump host VM"
  value       = google_compute_instance.jumphost.network_interface[0].network_ip
}

output "jumphost_zone" {
  description = "The zone of the jump host VM"
  value       = google_compute_instance.jumphost.zone
}

output "jumphost_ssh_command" {
  description = "Command to SSH into the jump host via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.jumphost.name} --zone=${google_compute_instance.jumphost.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "firewall_vm_name" {
  description = "The name of the firewall VM"
  value       = google_compute_instance.firewall.name
}

output "firewall_vm_internal_ip" {
  description = "The internal IP of the firewall VM"
  value       = google_compute_instance.firewall.network_interface[0].network_ip
}

# External IP disabled due to org policy constraints
# output "firewall_vm_external_ip" {
#   description = "The external IP of the firewall VM"
#   value       = google_compute_instance.firewall.network_interface[0].access_config[0].nat_ip
# }

# -----------------------------------------------------------------------------
# Cloud SQL Outputs
# -----------------------------------------------------------------------------

output "cloudsql_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "cloudsql_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "cloudsql_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "cloudsql_database_name" {
  description = "The name of the default database"
  value       = google_sql_database.default.name
}

output "cloudsql_app_user" {
  description = "The application database user"
  value       = google_sql_user.app_user.name
}

output "cloudsql_password_secret_name" {
  description = "The name of the Secret Manager secret containing the database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_name" {
  description = "The name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.docker.name
}

output "artifact_registry_location" {
  description = "The location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.docker.location
}

output "artifact_registry_url" {
  description = "The URL of the Artifact Registry repository"
  value       = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.name}"
}

output "artifact_registry_docker_config_command" {
  description = "Command to configure Docker to authenticate with Artifact Registry"
  value       = "gcloud auth configure-docker ${google_artifact_registry_repository.docker.location}-docker.pkg.dev"
}

# -----------------------------------------------------------------------------
# Service Accounts Outputs
# -----------------------------------------------------------------------------

output "gke_nodes_service_account" {
  description = "The email of the GKE nodes service account"
  value       = google_service_account.gke_nodes.email
}

output "compute_engine_service_account" {
  description = "The email of the Compute Engine service account"
  value       = google_service_account.compute_engine.email
}
