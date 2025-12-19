# =============================================================================
# GCP Foundation Template - Networking
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.compute]
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

# GKE Subnet (with secondary range for pods)
resource "google_compute_subnetwork" "gke" {
  name                     = var.gke_subnet_name
  ip_cidr_range            = var.gke_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
  project                  = var.project_id

  secondary_ip_range {
    range_name    = var.gke_pods_range_name
    ip_cidr_range = var.gke_pods_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Database Subnet
resource "google_compute_subnetwork" "database" {
  name                     = var.database_subnet_name
  ip_cidr_range            = var.database_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true
  project                  = var.project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE Private Endpoint Subnet
resource "google_compute_subnetwork" "gke_pe" {
  name                     = var.gke_pe_subnet_name
  ip_cidr_range            = var.gke_pe_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = false
  project                  = var.project_id
}

# DMZ Subnet (for firewall appliance)
resource "google_compute_subnetwork" "dmz" {
  name                     = var.dmz_subnet_name
  ip_cidr_range            = var.dmz_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = false
  project                  = var.project_id
}

# Additional Workload Subnets
resource "google_compute_subnetwork" "workload" {
  for_each = var.workload_subnets

  name                     = each.key
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = each.value.private_google_access
  project                  = var.project_id
  description              = each.value.description

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# -----------------------------------------------------------------------------
# Cloud Router and NAT (for private GKE nodes internet access)
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.main.id
  project = var.project_id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Private Service Connection (for Cloud SQL)
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "private_service_range" {
  name          = "private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  address       = split("/", var.private_service_cidr)[0]
  network       = google_compute_network.main.id
  project       = var.project_id

  depends_on = [google_project_service.servicenetworking]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  depends_on = [google_project_service.servicenetworking]
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.vpc_name}-allow-internal"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allows all internal TCP, UDP, and ICMP traffic between VPC subnets for inter-service communication"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.database_subnet_cidr,
    var.dmz_subnet_cidr,
    "10.8.1.0/24",
    "10.8.2.0/24",
    "10.8.3.0/24",
    "10.8.4.0/24"
  ]

  priority = 1000
}

# Allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name        = "${var.vpc_name}-allow-http"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allows HTTP traffic (port 80) from internet to VMs tagged with http-server"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  priority      = 1000
}

# Allow HTTPS traffic
resource "google_compute_firewall" "allow_https" {
  name        = "${var.vpc_name}-allow-https"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allows HTTPS traffic (port 443) from internet to VMs tagged with https-server"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
  priority      = 1000
}

# Allow PostgreSQL access from VPC
resource "google_compute_firewall" "allow_postgres" {
  name        = "allow-postgres"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow PostgreSQL connections within VPC"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.database_subnet_cidr
  ]

  target_tags = ["postgres"]
  priority    = 1000
}

# Allow IAP SSH access (for OS Login)
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "${var.vpc_name}-allow-iap-ssh"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow SSH access via Identity-Aware Proxy"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
  priority      = 1000
}

# Firewall appliance access (VPN protocols)
resource "google_compute_firewall" "firewall_access" {
  name        = "firewall-appliance-access"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow access to firewall appliance (HTTP, HTTPS, VPN protocols)"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  allow {
    protocol = "udp"
    ports    = ["500", "1194", "4500"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["firewall-appliance"]
  priority      = 1000
}

# GKE Master to Node communication (required for private clusters)
resource "google_compute_firewall" "gke_master_to_nodes" {
  name        = "${var.gke_cluster_name}-master-to-nodes"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow GKE master to communicate with nodes"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  # GKE control plane CIDR
  source_ranges = [var.gke_master_cidr]
  target_tags   = ["gke-${var.gke_cluster_name}"]
  priority      = 1000
}

# Allow health check probes
resource "google_compute_firewall" "allow_health_checks" {
  name        = "${var.vpc_name}-allow-health-checks"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow GCP health check probes"

  allow {
    protocol = "tcp"
  }

  # Google Cloud health check IP ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["allow-health-check"]
  priority    = 1000
}

# Deny kubelet external access (security best practice)
resource "google_compute_firewall" "deny_kubelet_external" {
  name        = "${var.gke_cluster_name}-deny-kubelet-external"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Deny external access to kubelet"

  deny {
    protocol = "tcp"
    ports    = ["10255"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-${var.gke_cluster_name}"]
  priority      = 900
}

# Allow kubelet internal access
resource "google_compute_firewall" "allow_kubelet_internal" {
  name        = "${var.gke_cluster_name}-allow-kubelet-internal"
  network     = google_compute_network.main.id
  project     = var.project_id
  description = "Allow internal kubelet access"

  allow {
    protocol = "tcp"
    ports    = ["10255"]
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_master_cidr
  ]

  target_tags = ["gke-${var.gke_cluster_name}"]
  priority    = 999
}
