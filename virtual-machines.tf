# =============================================================================
# GCP Foundation Template - Virtual Machines
# =============================================================================

# -----------------------------------------------------------------------------
# Jump Host VM (for database and GKE control plane access)
# -----------------------------------------------------------------------------

resource "google_compute_instance" "jumphost" {
  name         = var.jumphost_vm_name
  machine_type = var.jumphost_machine_type
  zone         = var.jumphost_zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.database.id
    # No external IP - access via IAP
  }

  # Service account
  service_account {
    email  = google_service_account.compute_engine.email
    scopes = ["cloud-platform"]
  }

  # Metadata for OS Login
  metadata = {
    enable-oslogin = "TRUE"
  }

  # Tags for firewall rules
  tags = ["iap-ssh", "jumphost"]

  # Labels
  labels = merge(var.labels, {
    purpose = "jumphost"
  })

  # Allow stopping for update
  allow_stopping_for_update = true

  # Shielded VM configuration
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  depends_on = [
    google_project_service.compute,
    google_service_account.compute_engine,
    google_compute_subnetwork.database
  ]
}

# -----------------------------------------------------------------------------
# Firewall Appliance VM (Placeholder - replace with pfSense if needed)
# -----------------------------------------------------------------------------

resource "google_compute_instance" "firewall" {
  name         = var.firewall_vm_name
  machine_type = var.firewall_machine_type
  zone         = var.firewall_zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.dmz.id
    # No external IP - org policy restricts external IPs
    # Access via IAP tunnel instead
  }

  # Service account
  service_account {
    email  = google_service_account.compute_engine.email
    scopes = ["cloud-platform"]
  }

  # Metadata for OS Login
  metadata = {
    enable-oslogin = "TRUE"
  }

  # Tags for firewall rules
  tags = ["firewall-appliance", "http-server", "https-server", "iap-ssh"]

  # Labels
  labels = merge(var.labels, {
    purpose = "firewall"
  })

  # IP forwarding disabled - org policy restricts this
  # Enable if org policy allows: can_ip_forward = true

  # Allow stopping for update
  allow_stopping_for_update = true

  # Shielded VM configuration
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  depends_on = [
    google_project_service.compute,
    google_service_account.compute_engine,
    google_compute_subnetwork.dmz
  ]
}