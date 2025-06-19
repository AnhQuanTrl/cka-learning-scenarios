# StorageClass Reclaim Policies

## Scenario Overview
**Time Limit**: 18 minutes  
**Difficulty**: Intermediate  
**Environment**: k3s bare metal

## Objective
Understand and demonstrate the behavior of different reclaim policies (`Retain` vs `Delete`) by observing what happens to PersistentVolumes when PersistentVolumeClaims are deleted.

## Context
Your team needs to understand data retention policies for different storage requirements. Production data needs to be retained even when applications are removed, while development data can be automatically cleaned up. You'll test both approaches to understand their implications.

## Prerequisites
- k3s cluster running
- kubectl access with admin privileges
- Clean environment (no existing PVs/PVCs)

## Tasks

### Task 1: Create StorageClass with Retain policy (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `retain-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Retain`
- **Volume Binding Mode**: `Immediate`

### Task 2: Create StorageClass with Delete policy (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `delete-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Delete`
- **Volume Binding Mode**: `Immediate`

### Task 3: Deploy application using Retain storage (4 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `retain-app-pvc`
- **StorageClass**: `retain-storage`
- **Storage Request**: `1Gi`
- **Access Mode**: `ReadWriteOnce`
- **Deployment Name**: `retain-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **Mount Path**: `/usr/share/nginx/html`

### Task 4: Deploy application using Delete storage (4 minutes)
Create a Deployment and PVC with these exact specifications:
- **PVC Name**: `delete-app-pvc`
- **StorageClass**: `delete-storage`
- **Storage Request**: `1Gi`
- **Access Mode**: `ReadWriteOnce`
- **Deployment Name**: `delete-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **Mount Path**: `/usr/share/nginx/html`

### Task 5: Create test data in both storage volumes (2 minutes)
- Write a test file named `important-data.txt` to the retain storage
- Write a test file named `temp-data.txt` to the delete storage
- Content should identify which storage type it came from

### Task 6: Delete PVCs and observe reclaim behavior (2 minutes)
- Delete both PVCs: `retain-app-pvc` and `delete-app-pvc`
- Observe the different behavior of the underlying PVs
- Note the PV status changes

## Verification Commands

### Check StorageClasses are created correctly:
```bash
# Should show both StorageClasses with different reclaim policies
kubectl get storageclass retain-storage delete-storage
kubectl describe storageclass retain-storage | grep -i reclaim
kubectl describe storageclass delete-storage | grep -i reclaim
```

### Verify initial setup:
```bash
# Should show both applications running
kubectl get deployment retain-app delete-app
kubectl get pods -l app=retain-app
kubectl get pods -l app=delete-app

# Should show both PVCs bound
kubectl get pvc retain-app-pvc delete-app-pvc
kubectl get pv
```

### Create and verify test data:
```bash
# Create test data in retain storage
kubectl exec -it deployment/retain-app -- sh -c "echo 'Critical production data - DO NOT DELETE' > /usr/share/nginx/html/important-data.txt"

# Create test data in delete storage  
kubectl exec -it deployment/delete-app -- sh -c "echo 'Temporary development data - can be deleted' > /usr/share/nginx/html/temp-data.txt"

# Verify data exists
kubectl exec -it deployment/retain-app -- cat /usr/share/nginx/html/important-data.txt
kubectl exec -it deployment/delete-app -- cat /usr/share/nginx/html/temp-data.txt
```

### Record PV names before deletion:
```bash
# Note the PV names for tracking after PVC deletion
kubectl get pvc -o custom-columns=PVC:.metadata.name,PV:.spec.volumeName,STORAGECLASS:.spec.storageClassName
```

### Delete PVCs and observe reclaim behavior:
```bash
# Delete both PVCs
kubectl delete pvc retain-app-pvc delete-app-pvc

# Immediately check PV status
kubectl get pv

# Check PV status details
kubectl get pv -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RECLAIM:.spec.persistentVolumeReclaimPolicy,CLAIM:.spec.claimRef.name
```

### Verify reclaim policy behavior:
```bash
# Delete policy PV should be gone or terminating
# Retain policy PV should be in Released status
kubectl get pv

# Check if any PVs remain
kubectl describe pv | grep -E "Name:|Status:|Claim:"
```

### Demonstrate manual PV cleanup for retained volumes:
```bash
# Find the retained PV (if any remain)
kubectl get pv -o wide

# For retained PVs, you can either:
# Option 1: Delete manually
kubectl delete pv <retained-pv-name>

# Option 2: Clear claim reference to make it Available again
kubectl patch pv <retained-pv-name> --type json -p '[{"op": "remove", "path": "/spec/claimRef"}]'
```

## Expected Results

### Before PVC Deletion:
1. Both StorageClasses exist with different reclaim policies
2. Both applications running with mounted storage
3. Both PVCs bound to their respective PVs
4. Test data files exist in both storage volumes

### After PVC Deletion:
1. **Delete Policy PV**: Automatically deleted (PV disappears)
2. **Retain Policy PV**: Remains but status changes to `Released`
3. Data in retain storage preserved but inaccessible until manual intervention
4. Data in delete storage completely removed

### Key Observations:
- `Delete` policy: PV lifecycle tied to PVC lifecycle
- `Retain` policy: PV survives PVC deletion but requires manual cleanup
- Released PVs cannot be automatically rebound to new PVCs

## Key Learning Points
- **Retain Policy**: Preserves data after PVC deletion, requires manual PV management
- **Delete Policy**: Automatically cleans up storage when PVC is deleted
- **Released Status**: Retained PVs are unavailable until manually cleaned or reclaimed
- **Data Safety**: Retain protects against accidental data loss but requires operational overhead
- **Storage Lifecycle**: Understanding when storage persists vs gets cleaned up

## When to Use Each Policy
- **Retain Policy**: Production data, databases, compliance requirements, data recovery scenarios
- **Delete Policy**: Development environments, temporary storage, automated cleanup needs

## Real Exam Tips
- Practice identifying PV status changes after PVC deletion
- Understand manual cleanup procedures for retained PVs
- Know that Released PVs cannot automatically bind to new PVCs
- Remember: Retain = manual cleanup required, Delete = automatic cleanup
- Be able to troubleshoot why a PV cannot be reused (likely needs claim reference removal)
