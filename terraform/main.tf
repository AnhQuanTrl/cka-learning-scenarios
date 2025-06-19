terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  # token is read from DIGITALOCEAN_TOKEN environment variable
}

# Get available Kubernetes versions
data "digitalocean_kubernetes_versions" "main" {}

# Create the DOKS cluster for CKA Storage learning
resource "digitalocean_kubernetes_cluster" "cka_storage_test" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.main.latest_version

  # Cost-optimized node pool for learning
  node_pool {
    name       = var.node_pool_name
    size       = var.node_size
    node_count = var.node_count

    # Add labels for identification and cost tracking
    labels = {
      environment = "learning"
      scenario    = "cka-storage-csi"
      purpose     = "cost-optimized"
    }
  }

  # Add tags for cost tracking and organization
  tags = [
    "cka-learning",
    "storage-scenario",
    "cost-optimized",
    "auto-delete"
  ]

  # Lifecycle management - prevent accidental destruction during learning
  lifecycle {
    prevent_destroy = false # Set to true if you want extra protection
  }
}

# Create a project for better organization (optional)
resource "digitalocean_project" "cka_learning" {
  name        = "CKA Learning Scenarios"
  description = "Project for CKA exam preparation scenarios"
  purpose     = "Educational or personal use"
  environment = "Development"

  resources = [
    digitalocean_kubernetes_cluster.cka_storage_test.urn
  ]
}