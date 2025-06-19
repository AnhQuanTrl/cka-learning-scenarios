# Variables for DigitalOcean Kubernetes cluster deployment
# Optimized for CKA Storage CSI learning scenario

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "cka-storage-test"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only alphanumeric characters and hyphens."
  }
}

variable "region" {
  description = "DigitalOcean region for the cluster"
  type        = string
  default     = "nyc1"

  validation {
    condition = contains([
      "nyc1", "nyc3", "ams2", "ams3", "blr1", "fra1",
      "lon1", "sgp1", "sfo2", "sfo3", "tor1", "syd1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region."
  }
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "storage-workers"
}

variable "node_size" {
  description = "Size of the worker nodes (cost-optimized for learning)"
  type        = string
  default     = "s-2vcpu-2gb"

  validation {
    condition = contains([
      "s-1vcpu-2gb", "s-2vcpu-2gb", "s-2vcpu-4gb", "s-4vcpu-8gb"
    ], var.node_size)
    error_message = "Node size must be a valid DigitalOcean droplet size."
  }
}

variable "node_count" {
  description = "Number of worker nodes (1 for cost optimization)"
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 5
    error_message = "Node count must be between 1 and 5 for cost-effective learning."
  }
}

variable "enable_auto_upgrade" {
  description = "Enable automatic Kubernetes version upgrades"
  type        = bool
  default     = false # Disabled for learning stability
}

variable "enable_surge_upgrade" {
  description = "Enable surge upgrades for zero-downtime updates"
  type        = bool
  default     = false # Disabled for cost optimization
}

variable "maintenance_policy" {
  description = "Maintenance policy for the cluster"
  type = object({
    start_time = string
    day        = string
  })
  default = {
    start_time = "02:00"
    day        = "sunday"
  }
}