# =============================================================================
# GCP Projec Template - GKE Cluster
# =============================================================================

# -----------------------------------------------------------------------------
# GKE Cluster (Private)
# -----------------------------------------------------------------------------

resource "google_container_cluster" "main" {
  name     = var.gke_cluster_name
  location = var.region
  project  = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke.id

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name = var.gke_pods_range_name
    # Services range will be auto-allocated
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  # Master authorized networks - Only allow access from Jump Host
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${google_compute_instance.jumphost.network_interface[0].network_ip}/32"
      display_name = "Jump Host"
    }
  }

  # Release channel
  release_channel {
    channel = var.gke_release_channel
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Resource labels
  resource_labels = var.labels

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Binary authorization (optional - can be enabled for production)
  # binary_authorization {
  #   evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  # }

  depends_on = [
    google_project_service.container,
    google_compute_subnetwork.gke,
    google_compute_instance.jumphost
  ]

  # Ignore changes to node pool as we manage it separately
  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count
    ]
  }
}

# -----------------------------------------------------------------------------
# GKE Node Pool
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "main" {
  name       = var.gke_node_pool_name
  location   = var.region
  cluster    = google_container_cluster.main.name
  project    = var.project_id

  # Node count per zone (will be multiplied by number of zones)
  node_count = var.gke_nodes_per_zone

  # Node locations (zones)
  node_locations = var.zones

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.gke_min_nodes_per_zone
    max_node_count = var.gke_max_nodes_per_zone
  }

  # Management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    machine_type = var.gke_node_machine_type
    disk_size_gb = var.gke_node_disk_size_gb
    disk_type    = var.gke_node_disk_type

    # Service account
    service_account = google_service_account.gke_nodes.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels
    labels = merge(var.labels, {
      node_pool = var.gke_node_pool_name
    })

    # Tags for firewall rules
    tags = [
      "gke-${var.gke_cluster_name}",
      "allow-health-check"
    ]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Shielded instance configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload metadata configuration
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [
    google_service_account.gke_nodes,
    google_project_iam_member.gke_nodes_log_writer,
    google_project_iam_member.gke_nodes_metric_writer,
    google_project_iam_member.gke_nodes_artifact_registry_reader
  ]
}
