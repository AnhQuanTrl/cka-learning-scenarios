# DigitalOcean CSI Storage Features

## Scenario Overview
**Time Limit**: 30 minutes  
**Difficulty**: Advanced  
**Environment**: DigitalOcean Kubernetes (DOKS)
**Estimated Cost**: $0.33 for 2-hour learning session

## Objective
Explore cloud-specific CSI storage features using DigitalOcean's managed Kubernetes service, including volume expansion, snapshots, and cloning capabilities that are not available in on-premises environments.

## Context
Your team needs to evaluate cloud-native storage features for production workloads. DigitalOcean's CSI driver provides advanced capabilities like dynamic volume expansion, point-in-time snapshots, and volume cloning. You'll deploy applications and test these features to understand their practical benefits and limitations.

## Prerequisites
- DigitalOcean account with API access
- `doctl` CLI installed and configured
- `kubectl` installed locally
- Basic understanding of cloud costs and billing

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

### Part 3: Volume Snapshots and Cloning

### Task 5: Create volume snapshot (3 minutes)
Create a VolumeSnapshot with these exact specifications:
- **Name**: `storage-app-snapshot`
- **Source PVC**: `expandable-pvc`
- **Snapshot Class**: Use default (auto-detected)

### Task 6: Restore from snapshot to new volume (4 minutes)
Create a new PVC from snapshot with these specifications:
- **PVC Name**: `restored-pvc`
- **Data Source**: `storage-app-snapshot`
- **Size**: `10Gi` (same as expanded volume)
- **StorageClass**: `do-block-storage`

### Task 7: Deploy second application using restored volume (3 minutes)
Create a second Deployment with these specifications:
- **Name**: `restored-app`
- **Image**: `nginx:1.20`
- **PVC**: `restored-pvc`
- **Mount Path**: `/usr/share/nginx/html`
- Verify data from original application is present

### Part 4: Advanced CSI Features and Monitoring

### Task 8: Test CSI monitoring and observability (4 minutes)
- Check volume statistics and metrics
- Monitor CSI driver logs and events
- Verify DigitalOcean Control Panel integration
- Test snapshot management in DO console

### Task 9: Clean up and cluster teardown (3 minutes)
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

### Create and verify volume snapshot:
```bash
# Create snapshot
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: storage-app-snapshot
spec:
  source:
    persistentVolumeClaimName: expandable-pvc
EOF

# Check snapshot status
kubectl get volumesnapshot
kubectl describe volumesnapshot storage-app-snapshot
kubectl get volumesnapshot storage-app-snapshot -o jsonpath='{.status.readyToUse}'
```

### Restore from snapshot:
```bash
# Create PVC from snapshot
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
spec:
  dataSource:
    name: storage-app-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: do-block-storage
EOF

# Deploy second application
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restored-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: restored-app
  template:
    metadata:
      labels:
        app: restored-app
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
          claimName: restored-pvc
EOF

# Verify data restoration
kubectl get pods -l app=restored-app
kubectl exec -it deployment/restored-app -- ls -la /usr/share/nginx/html/
kubectl exec -it deployment/restored-app -- cat /usr/share/nginx/html/before-expansion.txt
kubectl exec -it deployment/restored-app -- cat /usr/share/nginx/html/after-expansion.txt
```

### Monitor CSI features and check DigitalOcean integration:
```bash
# Check CSI driver logs
kubectl logs -n kube-system -l app=csi-do-controller --tail=20
kubectl logs -n kube-system -l app=csi-do-node --tail=20

# Check volume and snapshot events
kubectl describe pvc expandable-pvc | grep Events: -A10
kubectl describe volumesnapshot storage-app-snapshot | grep Events: -A10

# View volume metrics (if available)
kubectl top nodes
kubectl describe node | grep -A10 -B5 "Allocated resources"

# Check DigitalOcean Control Panel
echo "Visit https://cloud.digitalocean.com/kubernetes/clusters to see cluster"
echo "Visit https://cloud.digitalocean.com/volumes to see block storage volumes"
echo "Visit https://cloud.digitalocean.com/images/snapshots to see volume snapshots"
```

### Clean up and teardown:
```bash
# Delete applications and storage
kubectl delete deployment storage-app restored-app
kubectl delete pvc expandable-pvc restored-pvc
kubectl delete volumesnapshot storage-app-snapshot

# Verify all resources are cleaned up
kubectl get pvc,pv,volumesnapshot
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

### Snapshot and Cloning Results:
1. Volume snapshot created successfully from active PVC
2. Snapshot appears in DigitalOcean Control Panel
3. New PVC restored from snapshot with all data intact
4. Second application accesses restored data immediately
5. Both applications run simultaneously with independent storage

### CSI Features Observed:
- **Dynamic Expansion**: Volume size increased without pod restart
- **Snapshot Consistency**: Point-in-time copy preserves all data
- **Cloud Integration**: Resources visible in DO console
- **Monitoring**: CSI metrics and events available
- **Zero Downtime**: Operations complete without service interruption

## Key Learning Points
- **Cloud CSI Advantages**: Features like expansion and snapshots unavailable in local storage
- **Cost Efficiency**: Per-second billing allows affordable learning experiments
- **Production Ready**: DigitalOcean CSI driver supports enterprise storage requirements
- **Operational Simplicity**: No manual CSI driver installation or configuration needed
- **Disaster Recovery**: Snapshots enable point-in-time recovery and environment cloning
- **Seamless Scaling**: Applications can grow storage without infrastructure changes

## Cost Management for Learning
- **Minimal Setup**: $10/month = $0.33/day for learning
- **Per-Second Billing**: Only pay for actual usage time
- **Quick Teardown**: Delete cluster immediately after completion
- **Resource Monitoring**: Track costs in DigitalOcean Control Panel
- **Budget Alerts**: Set up billing alerts for learning projects

## Production Considerations
- **High Availability**: Use multiple nodes in production
- **Backup Strategy**: Regular snapshots for disaster recovery
- **Monitoring**: Implement volume usage and performance monitoring
- **Cost Optimization**: Right-size volumes and clean up unused snapshots
- **Security**: Configure appropriate access controls and network policies

## Real Exam Tips
- Understand cloud-specific CSI features vs on-premises limitations
- Practice volume expansion scenarios and troubleshooting
- Know how to create and restore from volume snapshots
- Be familiar with CSI driver architecture and monitoring
- Remember: Cloud CSI = advanced features, On-premises = basic provisioning
- Practice identifying when cloud CSI features are required vs sufficient