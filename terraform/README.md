# Terraform Deployment for CKA Storage CSI Learning

This Terraform configuration deploys a cost-optimized DigitalOcean Kubernetes (DOKS) cluster specifically designed for the **Storage/StorageClass/06-digital-ocean-csi.md** learning scenario.

## 📋 Prerequisites

- [Terraform](https://terraform.io/downloads.html) >= 1.0
- [DigitalOcean CLI (doctl)](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- DigitalOcean account with API access
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for cluster management

## 💰 Cost Optimization

- **Control Plane**: FREE (DigitalOcean managed)
- **Worker Node**: $12/month = $0.0167/hour per `s-2vcpu-2gb` node
- **Learning Session**: 2 hours ≈ $0.33
- **Billing**: Per-second with 60-second minimum charge

## 🚀 Quick Start

### 1. Setup DigitalOcean Authentication

```bash
# Get your token from: https://cloud.digitalocean.com/account/api/tokens
export DIGITALOCEAN_TOKEN="your_digitalocean_token_here"

# Verify authentication
doctl account get
```

### 2. Configure Terraform Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit variables (optional - defaults are optimized for learning)
nano terraform.tfvars
```

### 3. Deploy the Cluster

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the cluster (takes 3-5 minutes)
terraform apply

# Save cluster outputs
terraform output -json > cluster-info.json
```

### 4. Configure kubectl

```bash
# Method 1: Using doctl (recommended)
doctl kubernetes cluster kubeconfig save cka-storage-test

# Method 2: Using Terraform output
terraform output -raw kubeconfig_raw > ~/.kube/config-cka-storage

# Verify cluster access
kubectl get nodes
kubectl get storageclass
```

### 5. Run the Learning Scenario

Follow the steps in `../Storage/StorageClass/06-digital-ocean-csi.md` starting from **Task 2**.

The cluster is pre-configured with:
- ✅ DigitalOcean CSI driver installed
- ✅ `do-block-storage` StorageClass available
- ✅ Volume expansion enabled
- ✅ Snapshot support ready

### 6. Clean Up (Important for Cost Control!)

```bash
# Delete all Kubernetes resources first
kubectl delete deployment --all
kubectl delete pvc --all
kubectl delete volumesnapshot --all

# Verify cleanup
kubectl get pvc,pv,volumesnapshot

# Destroy the cluster
terraform destroy

# Confirm in DigitalOcean console
doctl kubernetes cluster list
```

## 📊 Terraform Outputs

After deployment, useful information is available via outputs:

```bash
# Cluster information
terraform output cluster_name
terraform output cluster_endpoint
terraform output cluster_version

# Cost tracking
terraform output estimated_monthly_cost
terraform output estimated_hourly_cost

# Console URLs
terraform output digitalocean_console_urls

# Management commands
terraform output kubectl_config_command
terraform output cluster_delete_command
```

## 🛠 Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cluster_name` | `cka-storage-test` | Name of the Kubernetes cluster |
| `region` | `nyc1` | DigitalOcean region |
| `node_pool_name` | `storage-workers` | Name of the worker node pool |
| `node_size` | `s-2vcpu-2gb` | Size of worker nodes ($12/month) |
| `node_count` | `1` | Number of worker nodes |

### Available Regions

- `nyc1`, `nyc3` - New York
- `ams2`, `ams3` - Amsterdam  
- `fra1` - Frankfurt
- `lon1` - London
- `sgp1` - Singapore
- `sfo2`, `sfo3` - San Francisco
- `tor1` - Toronto
- `blr1` - Bangalore
- `syd1` - Sydney

## 🔧 Troubleshooting

### Authentication Issues

```bash
# Check token
echo $DIGITALOCEAN_TOKEN

# Test doctl access
doctl account get

# Verify API permissions
doctl kubernetes options versions
```

### Cluster Access Issues

```bash
# Reset kubeconfig
doctl kubernetes cluster kubeconfig save cka-storage-test --overwrite

# Check cluster status
doctl kubernetes cluster get cka-storage-test

# Verify nodes
kubectl get nodes -o wide
```

### Cost Monitoring

```bash
# Check current resources
doctl kubernetes cluster list
doctl compute volume list
doctl compute volume-snapshot list

# Monitor in DigitalOcean console
open "https://cloud.digitalocean.com/account/billing"
```

## 🎯 Integration with Learning Scenario

This Terraform configuration creates the exact cluster specifications required for the CSI learning scenario:

1. **Cluster Name**: `cka-storage-test` (matches scenario expectations)
2. **Node Configuration**: 1 x `s-2vcpu-2gb` worker node
3. **CSI Driver**: Pre-installed DigitalOcean CSI driver
4. **StorageClass**: `do-block-storage` ready for use
5. **Features**: Volume expansion and snapshots enabled

After deployment, jump directly to **Task 2** in the learning scenario, as **Task 1** (cluster creation) is handled by Terraform.

## 📝 Best Practices

- **Always run `terraform destroy`** after learning to stop billing
- **Monitor costs** in DigitalOcean console during learning
- **Use tags** for resource organization and cost tracking
- **Clean up Kubernetes resources** before destroying the cluster
- **Keep sessions short** (2-3 hours max) for cost efficiency

## 🔗 Related Resources

- [CKA Storage CSI Scenario](../Storage/StorageClass/06-digital-ocean-csi.md)
- [DigitalOcean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [DigitalOcean Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/)
- [Terraform Documentation](https://terraform.io/docs/)

## 📞 Support

For issues with:
- **Terraform configuration**: Check the troubleshooting section above
- **DigitalOcean services**: Contact [DigitalOcean Support](https://www.digitalocean.com/support/)
- **Learning scenario**: Refer to the scenario documentation and verification commands