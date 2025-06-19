# Basic StorageClass Creation

## Scenario Overview
**Time Limit**: 15 minutes  
**Difficulty**: Beginner  
**Environment**: k3s bare metal

## Objective
Create and configure different types of StorageClasses and deploy applications that consume them to understand their practical usage.

## Context
Your k3s cluster needs multiple storage options for different application requirements. You need to create StorageClasses with different configurations and deploy applications that use them to verify they work correctly.

## Prerequisites
- k3s cluster running
- kubectl access with admin privileges

## Tasks

### Task 1: Create StorageClass named `fast-storage` (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `fast-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Retain`

### Task 2: Create StorageClass named `slow-storage` (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `slow-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Delete`
- **Volume Binding Mode**: `WaitForFirstConsumer`

### Task 3: Set Default StorageClass (2 minutes)
- Make `fast-storage` the default StorageClass
- Ensure no other StorageClass is marked as default

### Task 4: Create StatefulSet using specific StorageClass (4 minutes)
Create a StatefulSet with these exact specifications:
- **Name**: `database`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **StorageClass**: `slow-storage` (explicitly specified)
- **Storage Request**: `1Gi`
- **Mount Path**: `/var/lib/data`

### Task 5: Create Deployment using default StorageClass (3 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `webapp-storage`
- **Deployment Name**: `webapp`
- **Image**: `nginx:1.20`
- **Replicas**: 2
- **StorageClass**: Use default (do not specify storageClassName in PVC)
- **Storage Request**: `500Mi`
- **Mount Path**: `/usr/share/nginx/html`

## Verification Commands

### Check StorageClasses are created correctly:
```bash
# Should show both fast-storage and slow-storage
kubectl get storageclass

# fast-storage should be marked as (default)
kubectl get storageclass fast-storage
kubectl get storageclass slow-storage
```

### Verify Default StorageClass:
```bash
# Should show fast-storage with (default) annotation
kubectl get storageclass -o wide

# Should return "true"
kubectl get storageclass fast-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}'
```

### Check Applications and Storage:
```bash
# Should show database StatefulSet and webapp Deployment
kubectl get statefulset database
kubectl get deployment webapp

# Should show all pods running
kubectl get pods -l app=database
kubectl get pods -l app=webapp

# Should show PVCs and their StorageClasses
kubectl get pvc
kubectl get pvc -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,STATUS:.status.phase
```

### Verify Volume Mounts:
```bash
# Check database pod volume mount
kubectl describe pod database-0 | grep -A5 -B5 "/var/lib/data"

# Check webapp pod volume mounts
kubectl get pods -l app=webapp -o name | head -1 | xargs kubectl describe | grep -A5 -B5 "/usr/share/nginx/html"
```

### Verify PersistentVolumes:
```bash
# Should show PVs created by both StorageClasses
kubectl get pv
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,STATUS:.status.phase
```

## Expected Results
1. `kubectl get storageclass` shows both `fast-storage (default)` and `slow-storage`
2. `kubectl get pvc` shows `data-database-0` using `slow-storage` and `webapp-storage` using `fast-storage`
3. All pods are in `Running` state
4. PVs are automatically created and `Bound`
5. Volume mounts are correctly configured in pod descriptions

## Real Exam Tips
- Always specify exact names and values as required
- Test StorageClasses with actual workloads, not just creation
- Use verification commands to confirm configuration
- Practice both explicit and default StorageClass scenarios