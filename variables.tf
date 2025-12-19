# =============================================================================
# GCP Foundation Template - Variable Declarations
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The default GCP region for resources"
  type        = string
  default     = "southamerica-east1"
}

variable "zones" {
  description = "List of zones for multi-zone deployments"
  type        = list(string)
  default     = ["southamerica-east1-a", "southamerica-east1-b"]
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "main-vpc"
}

variable "gke_subnet_name" {
  description = "Name of the subnet for GKE nodes"
  type        = string
  default     = "gke-subnet"
}

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE nodes subnet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_pods_cidr" {
  description = "Secondary CIDR range for GKE pods"
  type        = string
  default     = "10.220.0.0/14"
}

variable "gke_pods_range_name" {
  description = "Name of the secondary range for GKE pods"
  type        = string
  default     = "gke-pods"
}

variable "database_subnet_name" {
  description = "Name of the subnet for database access"
  type        = string
  default     = "database-subnet"
}

variable "database_subnet_cidr" {
  description = "CIDR range for database subnet"
  type        = string
  default     = "10.2.0.0/16"
}

variable "gke_pe_subnet_name" {
  description = "Name of the subnet for GKE Private Endpoint"
  type        = string
  default     = "gke-pe-subnet"
}

variable "gke_pe_subnet_cidr" {
  description = "CIDR range for GKE Private Endpoint subnet"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE control plane (must be /28, cannot overlap with any subnet)"
  type        = string
  default     = "172.16.1.0/28"
}

variable "dmz_subnet_name" {
  description = "Name of the DMZ subnet (for firewall appliance)"
  type        = string
  default     = "dmz-subnet"
}

variable "dmz_subnet_cidr" {
  description = "CIDR range for DMZ subnet"
  type        = string
  default     = "10.8.0.0/24"
}

variable "workload_subnets" {
  description = "Map of additional workload subnets"
  type = map(object({
    cidr                     = string
    private_google_access    = bool
    description              = string
  }))
  default = {
    "workload-subnet-1" = {
      cidr                  = "10.8.1.0/24"
      private_google_access = true
      description           = "General workload subnet 1"
    }
    "workload-subnet-2" = {
      cidr                  = "10.8.2.0/24"
      private_google_access = true
      description           = "General workload subnet 2"
    }
    "workload-subnet-3" = {
      cidr                  = "10.8.3.0/24"
      private_google_access = true
      description           = "General workload subnet 3"
    }
    "workload-subnet-4" = {
      cidr                  = "10.8.4.0/24"
      private_google_access = true
      description           = "General workload subnet 4"
    }
  }
}

# -----------------------------------------------------------------------------
# Cloud SQL Private Service Connection
# -----------------------------------------------------------------------------

variable "private_service_cidr" {
  description = "CIDR range for Cloud SQL private service connection"
  type        = string
  default     = "10.100.0.0/16"
}

# -----------------------------------------------------------------------------
# GKE Configuration
# -----------------------------------------------------------------------------

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "main-cluster"
}

variable "gke_node_pool_name" {
  description = "Name of the GKE node pool"
  type        = string
  default     = "main-node-pool"
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-custom-8-16384"
}

variable "gke_node_disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 100
}

variable "gke_node_disk_type" {
  description = "Disk type for GKE nodes"
  type        = string
  default     = "pd-standard"
}

variable "gke_nodes_per_zone" {
  description = "Number of nodes per zone in the node pool"
  type        = number
  default     = 2
}

variable "gke_min_nodes_per_zone" {
  description = "Minimum number of nodes per zone for autoscaling"
  type        = number
  default     = 1
}

variable "gke_max_nodes_per_zone" {
  description = "Maximum number of nodes per zone for autoscaling"
  type        = number
  default     = 5
}

variable "gke_release_channel" {
  description = "GKE release channel (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

# -----------------------------------------------------------------------------
# Virtual Machines Configuration
# -----------------------------------------------------------------------------

variable "jumphost_vm_name" {
  description = "Name of the jump host VM"
  type        = string
  default     = "jump-database"
}

variable "jumphost_machine_type" {
  description = "Machine type for the jump host VM"
  type        = string
  default     = "e2-small"
}

variable "jumphost_zone" {
  description = "Zone for the jump host VM"
  type        = string
  default     = "southamerica-east1-b"
}

variable "firewall_vm_name" {
  description = "Name of the firewall appliance VM (placeholder)"
  type        = string
  default     = "firewall-appliance"
}

variable "firewall_machine_type" {
  description = "Machine type for the firewall VM"
  type        = string
  default     = "e2-small"
}

variable "firewall_zone" {
  description = "Zone for the firewall VM"
  type        = string
  default     = "southamerica-east1-a"
}

# -----------------------------------------------------------------------------
# Cloud SQL Configuration
# -----------------------------------------------------------------------------

variable "cloudsql_instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "main-postgres"
}

variable "cloudsql_database_version" {
  description = "PostgreSQL version for Cloud SQL"
  type        = string
  default     = "POSTGRES_15"
}

variable "cloudsql_tier" {
  description = "Machine tier for Cloud SQL instance (e.g., db-custom-2-7680 for 2 vCPU/7.5GB)"
  type        = string
  default     = "db-custom-2-7680"
}

variable "cloudsql_disk_size" {
  description = "Disk size in GB for Cloud SQL instance"
  type        = number
  default     = 10
}

variable "cloudsql_disk_type" {
  description = "Disk type for Cloud SQL instance"
  type        = string
  default     = "PD_SSD"
}

variable "cloudsql_availability_type" {
  description = "Availability type for Cloud SQL (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "cloudsql_backup_enabled" {
  description = "Enable automated backups for Cloud SQL"
  type        = bool
  default     = true
}

variable "cloudsql_backup_start_time" {
  description = "Start time for Cloud SQL backups (HH:MM format, UTC)"
  type        = string
  default     = "03:00"
}

# -----------------------------------------------------------------------------
# Artifact Registry Configuration
# -----------------------------------------------------------------------------

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "docker-repo"
}

variable "artifact_registry_format" {
  description = "Format of the Artifact Registry repository"
  type        = string
  default     = "DOCKER"
}

# -----------------------------------------------------------------------------
# Labels/Tags
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    environment = "production"
  }
}
