# Outputs for DigitalOcean Kubernetes cluster
# Essential information for connecting to the cluster and running CKA scenarios

output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.name
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.endpoint
  sensitive   = true
}

output "cluster_region" {
  description = "Region where the cluster is deployed"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.region
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.version
}

output "cluster_status" {
  description = "Status of the cluster"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.status
}

output "node_pool_id" {
  description = "ID of the node pool"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.node_pool[0].id
}

output "node_pool_nodes" {
  description = "Information about nodes in the pool"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.node_pool[0].nodes
}

# Kubeconfig for kubectl access
output "kubeconfig_raw" {
  description = "Raw kubeconfig for kubectl access"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.kube_config[0].raw_config
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes cluster host"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.kube_config[0].host
  sensitive   = true
}

output "kubeconfig_token" {
  description = "Kubernetes cluster token"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.kube_config[0].token
  sensitive   = true
}

output "kubeconfig_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.cka_storage_test.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

# Project information
output "project_id" {
  description = "ID of the DigitalOcean project"
  value       = digitalocean_project.cka_learning.id
}

# Cost optimization information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for the cluster (USD)"
  value       = "$12.00 (1 x s-2vcpu-2gb node) + $0 (free control plane)"
}

output "estimated_hourly_cost" {
  description = "Estimated hourly cost for learning sessions (USD)"
  value       = "$0.0167 per hour (2-hour session ≈ $0.33)"
}

# Commands for easy cluster access
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.cka_storage_test.name}"
}

output "cluster_delete_command" {
  description = "Command to delete cluster and stop billing"
  value       = "doctl kubernetes cluster delete ${digitalocean_kubernetes_cluster.cka_storage_test.name} --force"
}

# DigitalOcean Console URLs
output "digitalocean_console_urls" {
  description = "Useful DigitalOcean console URLs for monitoring"
  value = {
    cluster   = "https://cloud.digitalocean.com/kubernetes/clusters/${digitalocean_kubernetes_cluster.cka_storage_test.id}"
    volumes   = "https://cloud.digitalocean.com/volumes"
    snapshots = "https://cloud.digitalocean.com/images/snapshots"
    billing   = "https://cloud.digitalocean.com/account/billing"
  }
}