# NFS CSI Driver vs Subdir Provisioner Comparison

## Scenario Overview
**Time Limit**: 25 minutes  
**Difficulty**: Advanced  
**Environment**: k3s bare metal with homelab NFS server

## Objective
Compare two different approaches to NFS storage in Kubernetes: the modern NFS CSI Driver and the legacy NFS Subdir External Provisioner. Understand their differences in volume isolation, security, features, and implementation patterns.

## Context
Your team needs to choose between two NFS storage solutions for production workloads. The legacy NFS Subdir External Provisioner has been reliable but lacks modern CSI features. The newer NFS CSI Driver offers better integration and advanced features. You'll deploy both systems to compare their capabilities.

## Prerequisites
- k3s cluster running
- NFS server accessible from the cluster (IP: `<NFS_SERVER_IP>`, export: `/var/nfs`)
- kubectl access with admin privileges
- No existing NFS provisioners installed

## Tasks

### Part 1: NFS Subdir External Provisioner Setup

### Task 1: Deploy NFS Subdir External Provisioner (4 minutes)
Deploy the legacy NFS provisioner with these exact specifications:
- **Namespace**: `nfs-subdir-system`
- **Image**: `registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2`
- **Provisioner Name**: `k8s-sigs.io/nfs-subdir-external-provisioner`
- **NFS Server**: `<NFS_SERVER_IP>`
- **NFS Path**: `/var/nfs`

### Task 2: Create StorageClass for Subdir Provisioner (2 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `nfs-subdir`
- **Provisioner**: `k8s-sigs.io/nfs-subdir-external-provisioner`
- **Parameters**: 
  - `onDelete`: `delete`
  - `pathPattern`: `${.PVC.namespace}-${.PVC.name}-${.PVC.annotations.volume.beta.kubernetes.io/storage-provisioner}`
- **Reclaim Policy**: `Delete`

### Part 2: NFS CSI Driver Setup

### Task 3: Deploy NFS CSI Driver (4 minutes)
Deploy the modern CSI driver with these exact specifications:
- **Namespace**: `nfs-csi-system`
- **CSI Plugin Name**: `nfs.csi.k8s.io`
- **Version**: `v4.11.0` (latest stable)
- Use Helm installation method

### Task 4: Create StorageClass for CSI Driver (2 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `nfs-csi`
- **Provisioner**: `nfs.csi.k8s.io`
- **Parameters**:
  - `server`: `<NFS_SERVER_IP>`
  - `share`: `/var/nfs`
  - `subDir`: `csi-volumes`
- **Volume Binding Mode**: `Immediate`
- **Reclaim Policy**: `Delete`

### Part 3: Application Deployment and Comparison

### Task 5: Deploy application using Subdir Provisioner (3 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `subdir-app-pvc`
- **StorageClass**: `nfs-subdir`
- **Storage Request**: `1Gi`
- **Deployment Name**: `subdir-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **Mount Path**: `/usr/share/nginx/html`

### Task 6: Deploy application using CSI Driver (3 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `csi-app-pvc`
- **StorageClass**: `nfs-csi`
- **Storage Request**: `1Gi`
- **Deployment Name**: `csi-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **Mount Path**: `/usr/share/nginx/html`

### Task 7: Create test data and compare volume isolation (4 minutes)
- Write different test files to each storage type
- Examine NFS server directory structure
- Compare volume isolation approaches
- Test data persistence and access patterns

### Task 8: Compare advanced features (3 minutes)
- Test volume expansion capabilities
- Check snapshot support (CSI only)
- Compare monitoring and observability
- Evaluate security features

## Verification Commands

### Check both provisioners are deployed:
```bash
# NFS Subdir External Provisioner
kubectl get deployment -n nfs-subdir-system
kubectl get pods -n nfs-subdir-system -l app=nfs-client-provisioner

# NFS CSI Driver
kubectl get daemonset -n nfs-csi-system
kubectl get deployment -n nfs-csi-system
kubectl get pods -n nfs-csi-system
```

### Verify StorageClasses:
```bash
# Should show both StorageClasses with different provisioners
kubectl get storageclass nfs-subdir nfs-csi
kubectl describe storageclass nfs-subdir | grep -E "Provisioner:|Parameters:"
kubectl describe storageclass nfs-csi | grep -E "Provisioner:|Parameters:"
```

### Check applications and storage:
```bash
# Both applications should be running
kubectl get deployment subdir-app csi-app
kubectl get pods -l app=subdir-app
kubectl get pods -l app=csi-app

# Check PVCs and PVs
kubectl get pvc subdir-app-pvc csi-app-pvc
kubectl get pv
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,CAPACITY:.spec.capacity.storage,ACCESS:.spec.accessModes
```

### Create test data and examine volume structure:
```bash
# Create test data in subdir storage
kubectl exec -it deployment/subdir-app -- sh -c "echo 'Subdir Provisioner Data - $(date)' > /usr/share/nginx/html/subdir-test.txt"
kubectl exec -it deployment/subdir-app -- sh -c "echo 'namespace: default, pvc: subdir-app-pvc' > /usr/share/nginx/html/info.txt"

# Create test data in CSI storage
kubectl exec -it deployment/csi-app -- sh -c "echo 'CSI Driver Data - $(date)' > /usr/share/nginx/html/csi-test.txt"
kubectl exec -it deployment/csi-app -- sh -c "echo 'namespace: default, pvc: csi-app-pvc' > /usr/share/nginx/html/info.txt"

# Verify data exists
kubectl exec -it deployment/subdir-app -- cat /usr/share/nginx/html/subdir-test.txt
kubectl exec -it deployment/csi-app -- cat /usr/share/nginx/html/csi-test.txt
```

### Compare volume isolation on NFS server:
```bash
# Check NFS server directory structure (run on NFS server or with NFS client)
# Subdir volumes appear as: default-subdir-app-pvc-<random-suffix>
# CSI volumes appear as: csi-volumes/<pv-name>

# List directory structure
ls -la /var/nfs/
ls -la /var/nfs/csi-volumes/ 2>/dev/null || echo "CSI volumes directory structure"
```

### Test volume expansion (CSI Driver only):
```bash
# Check if StorageClass supports expansion
kubectl describe storageclass nfs-csi | grep -i expansion

# Try to expand CSI PVC (should work)
kubectl patch pvc csi-app-pvc -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
kubectl get pvc csi-app-pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,REQUESTED:.spec.resources.requests.storage

# Try to expand Subdir PVC (should fail)
kubectl patch pvc subdir-app-pvc -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
kubectl describe pvc subdir-app-pvc | grep -i events
```

### Check CSI-specific features:
```bash
# Check CSI driver capabilities
kubectl get csidriver
kubectl describe csidriver nfs.csi.k8s.io

# Check if volume snapshots are supported
kubectl get volumesnapshotclass 2>/dev/null || echo "No VolumeSnapshotClass available"
kubectl api-resources | grep snapshot
```

### Monitor and observe differences:
```bash
# Check resource usage
kubectl top pods -n nfs-subdir-system
kubectl top pods -n nfs-csi-system

# Compare pod logs
kubectl logs -n nfs-subdir-system -l app=nfs-client-provisioner --tail=20
kubectl logs -n nfs-csi-system -l app=csi-nfs-controller --tail=20

# Check storage metrics
kubectl describe pv | grep -E "Name:|StorageClass:|Source:|Node Affinity:"
```

## Expected Results

### NFS Subdir External Provisioner Results:
1. Creates subdirectories with pattern: `default-subdir-app-pvc-<random-suffix>`
2. Direct NFS mount with simple directory-based isolation
3. No CSI features (snapshots, cloning, expansion)
4. Lightweight deployment (single pod)
5. Legacy approach with proven stability
6. Limited metadata and monitoring capabilities

### NFS CSI Driver Results:
1. Creates structured directory: `csi-volumes/<pv-name>/`
2. CSI-compliant volume management
3. Supports volume expansion, snapshots, and cloning
4. Full CSI controller and node components
5. Modern architecture with better integration
6. Rich metadata and observability features

### Key Differences Observed:

#### Volume Isolation:
- **Subdir**: Simple directory naming, shared NFS export
- **CSI**: Structured hierarchy, better isolation boundaries

#### Feature Support:
- **Subdir**: Basic provisioning only
- **CSI**: Full CSI feature set (expansion, snapshots, cloning)

#### Architecture:
- **Subdir**: Single provisioner pod
- **CSI**: Controller + DaemonSet architecture

#### Monitoring:
- **Subdir**: Limited observability
- **CSI**: Rich metrics and events

## Key Learning Points
- **Legacy vs Modern**: Subdir is stable but limited, CSI is feature-rich and standards-compliant
- **Volume Isolation**: CSI provides better structure and isolation than simple subdirectories
- **Feature Set**: CSI supports advanced features like expansion, snapshots, and cloning
- **Architecture**: CSI uses standard controller/node pattern for better scalability
- **Migration Path**: Teams should plan migration from Subdir to CSI for long-term benefits

## When to Use Each Approach
- **NFS Subdir Provisioner**: Legacy environments, simple requirements, proven stability needs
- **NFS CSI Driver**: New deployments, advanced features needed, standards compliance, future-proofing

## Real Exam Tips
- Understand both legacy and modern NFS provisioning approaches
- Know the differences between directory-based and CSI-based volume management
- Practice identifying provisioner types by their naming patterns and capabilities
- Be familiar with CSI driver architecture and capabilities
- Remember: Subdir = simple directories, CSI = structured volumes with advanced features