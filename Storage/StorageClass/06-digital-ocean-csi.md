# DigitalOcean CSI Storage Features

## Scenario Overview
**Time Limit**: 20 minutes  
**Difficulty**: Intermediate  
**Environment**: DigitalOcean Kubernetes (DOKS)
**Estimated Cost**: $0.33 for 2-hour learning session

## Objective
Explore cloud-specific CSI storage features using DigitalOcean's managed Kubernetes service, focusing on dynamic volume expansion capabilities that are not available in on-premises environments.

## Context
Your team needs to evaluate cloud-native storage features for production workloads. DigitalOcean's CSI driver provides dynamic volume expansion capabilities that aren't available with local storage provisioners. You'll deploy applications and test volume expansion to understand its practical benefits and limitations.

## Prerequisites
- DigitalOcean account with API access
- `doctl` CLI installed and configured
- `kubectl` installed locally
- Basic understanding of cloud costs and billing

> **Note**: For advanced CSI features like volume snapshots and cloning, see the `Storage/VolumeSnapshots/` scenarios that build on this cluster setup.

## Cost Optimization Strategy
- **Minimum cluster**: 1 node ($10/month = $0.33/day = $0.014/hour)
- **Per-second billing**: 60-second minimum charge
- **Learning session**: Complete scenario in 2 hours ≈ $0.33
- **Immediate teardown**: Delete cluster after completion

## Tasks

### Part 1: Cost-Effective Cluster Setup

### Task 1: Create minimal DOKS cluster for learning (4 minutes)
Create a cluster with these exact specifications:
- **Name**: `cka-storage-test`
- **Region**: `nyc1` (or closest to you)
- **Node Pool**: 
  - **Count**: 1 node
  - **Size**: `s-2vcpu-2gb` ($12/month node)
  - **Name**: `storage-workers`
- **Kubernetes Version**: Latest stable

### Task 2: Configure kubectl and verify CSI driver (2 minutes)
- Download kubeconfig and configure kubectl
- Verify pre-installed DigitalOcean CSI driver
- Check default `do-block-storage` StorageClass

### Part 2: Volume Expansion Testing

### Task 3: Deploy application with initial storage (3 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `expandable-pvc`
- **StorageClass**: `do-block-storage`
- **Initial Size**: `5Gi`
- **Access Mode**: `ReadWriteOnce`
- **Deployment Name**: `storage-app`
- **Image**: `nginx:1.20`
- **Mount Path**: `/usr/share/nginx/html`

### Task 4: Create initial data and expand volume (4 minutes)
- Write test data to the initial 5Gi volume
- Expand PVC to `10Gi` dynamically
- Verify application can access expanded storage
- Confirm no downtime during expansion

### Part 3: CSI Monitoring and Observability

### Task 5: Test CSI monitoring and observability (4 minutes)
- Check volume statistics and metrics
- Monitor CSI driver logs and events
- Verify DigitalOcean Control Panel integration
- Monitor volume expansion events

### Task 6: Clean up and cluster teardown (3 minutes)
- Delete applications and volumes
- Verify no orphaned resources
- Delete DOKS cluster to stop billing
- Confirm cluster deletion in DO console

## Verification Commands

### Check cluster creation and CSI driver:
```bash
# Create cluster (replace with your preferences)
doctl kubernetes cluster create cka-storage-test \
  --region nyc1 \
  --node-pool "name=storage-workers;size=s-2vcpu-2gb;count=1" \
  --wait

# Get kubeconfig
doctl kubernetes cluster kubeconfig save cka-storage-test

# Verify CSI driver is installed
kubectl get pods -n kube-system | grep csi
kubectl get storageclass
kubectl describe storageclass do-block-storage
```

### Deploy application with initial storage:
```bash
# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: expandable-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: do-block-storage
EOF

# Create deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-app
  template:
    metadata:
      labels:
        app: storage-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        volumeMounts:
        - name: storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: expandable-pvc
EOF

# Verify deployment
kubectl get pvc expandable-pvc
kubectl get deployment storage-app
kubectl get pods -l app=storage-app
```

### Create initial data and test expansion:
```bash
# Create initial data
kubectl exec -it deployment/storage-app -- sh -c "echo 'Initial data before expansion - $(date)' > /usr/share/nginx/html/before-expansion.txt"
kubectl exec -it deployment/storage-app -- sh -c "dd if=/dev/zero of=/usr/share/nginx/html/large-file-5gb.bin bs=1M count=1024"
kubectl exec -it deployment/storage-app -- df -h /usr/share/nginx/html

# Expand volume to 10Gi
kubectl patch pvc expandable-pvc -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Wait for expansion and verify
kubectl get pvc expandable-pvc -w
kubectl exec -it deployment/storage-app -- df -h /usr/share/nginx/html

# Create data in expanded space
kubectl exec -it deployment/storage-app -- sh -c "echo 'Data after expansion - $(date)' > /usr/share/nginx/html/after-expansion.txt"
kubectl exec -it deployment/storage-app -- sh -c "dd if=/dev/zero of=/usr/share/nginx/html/large-file-10gb.bin bs=1M count=2048"
```


### Monitor CSI features and check DigitalOcean integration:
```bash
# Check CSI driver logs
kubectl logs -n kube-system -l app=csi-do-controller --tail=20
kubectl logs -n kube-system -l app=csi-do-node --tail=20

# Check volume expansion events
kubectl describe pvc expandable-pvc | grep Events: -A10
kubectl get events --field-selector reason=VolumeExpansion

# View volume metrics and resource usage
kubectl top nodes
kubectl describe node | grep -A10 -B5 "Allocated resources"

# Check DigitalOcean Control Panel
echo "Visit https://cloud.digitalocean.com/kubernetes/clusters to see cluster"
echo "Visit https://cloud.digitalocean.com/volumes to see block storage volumes"
echo "Check volume resize history in DigitalOcean console"
```

### Clean up and teardown:
```bash
# Delete applications and storage
kubectl delete deployment storage-app
kubectl delete pvc expandable-pvc

# Verify all resources are cleaned up
kubectl get pvc,pv
kubectl get pods

# Delete cluster to stop billing
doctl kubernetes cluster delete cka-storage-test --force

# Verify cluster deletion
doctl kubernetes cluster list
```

## Expected Results

### Cluster Setup Results:
1. DOKS cluster created with 1 worker node
2. CSI driver pre-installed and functional
3. `do-block-storage` StorageClass available and configured
4. Cluster accessible via kubectl

### Volume Expansion Results:
1. PVC successfully expanded from 5Gi to 10Gi without downtime
2. Application continues running during expansion
3. Additional storage space immediately available
4. Data created before expansion preserved

### CSI Features Observed:
- **Dynamic Expansion**: Volume size increased without pod restart
- **Live Expansion**: File system automatically expanded during application runtime
- **Cloud Integration**: Volume resize visible in DigitalOcean console
- **Event Monitoring**: CSI expansion events tracked in Kubernetes
- **Zero Downtime**: Volume expansion completed without service interruption

## Key Learning Points
- **Cloud CSI Advantages**: Volume expansion unavailable with local storage provisioners
- **Cost Efficiency**: Per-second billing allows affordable learning experiments
- **Production Ready**: DigitalOcean CSI driver supports enterprise storage requirements
- **Operational Simplicity**: No manual CSI driver installation or configuration needed
- **Live Expansion**: Applications can scale storage dynamically without downtime
- **Seamless Scaling**: Storage grows transparently with application needs

## Cost Management for Learning
- **Minimal Setup**: $10/month = $0.33/day for learning
- **Per-Second Billing**: Only pay for actual usage time
- **Quick Teardown**: Delete cluster immediately after completion
- **Resource Monitoring**: Track costs in DigitalOcean Control Panel
- **Budget Alerts**: Set up billing alerts for learning projects

## Production Considerations
- **High Availability**: Use multiple nodes in production
- **Capacity Planning**: Monitor volume usage and plan expansion proactively
- **Performance Impact**: Test expansion impact on application performance
- **Cost Optimization**: Right-size initial volumes to minimize expansion needs
- **Security**: Configure appropriate access controls and network policies

## Real Exam Tips
- Understand cloud-specific CSI features vs on-premises limitations
- Practice volume expansion scenarios and troubleshooting
- Know which StorageClasses support volume expansion (allowVolumeExpansion: true)
- Be familiar with CSI driver architecture and monitoring
- Remember: Cloud CSI = advanced features, On-premises = basic provisioning
- Practice identifying when volume expansion is required vs creating new volumes