# Static vs Dynamic Provisioning

## Scenario Overview
**Time Limit**: 20 minutes  
**Difficulty**: Intermediate  
**Environment**: k3s bare metal

## Objective
Understand the fundamental difference between static provisioning (manually creating PVs) and dynamic provisioning (StorageClass automatically creates PVs). Compare both approaches by deploying similar applications using each method.

## Context
Your team needs to understand when to use static vs dynamic provisioning. You'll set up both approaches side-by-side to see the workflow differences, benefits, and trade-offs of each provisioning method.

## Prerequisites
- k3s cluster running
- kubectl access with admin privileges
- Clean environment (no existing PVs/PVCs to avoid confusion)

## Tasks

## Part 1: Static Provisioning (Manual PV Creation)

### Task 1: Manually create PersistentVolume for static provisioning (4 minutes)
Create a PV with these exact specifications:
- **Name**: `static-pv`
- **Capacity**: `2Gi`
- **Access Mode**: `ReadWriteOnce`
- **Reclaim Policy**: `Retain`
- **Host Path**: `/tmp/static-storage` (use local storage for k3s)

### Task 2: Create PVC for static provisioning (3 minutes)
Create a PVC that binds to the manually created PV:
- **Name**: `static-app-pvc`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `2Gi`
- **Do NOT specify StorageClass** (to bind to static PV)

### Task 3: Deploy application using static storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `static-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `static-app-pvc`
- **Mount Path**: `/usr/share/nginx/html`

## Part 2: Dynamic Provisioning (StorageClass Creates PVs)

### Task 4: Create StorageClass for dynamic provisioning (2 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `dynamic-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Delete`
- **Volume Binding Mode**: `Immediate`

### Task 5: Create PVC for dynamic provisioning (3 minutes)
Create a PVC that triggers automatic PV creation:
- **Name**: `dynamic-app-pvc`
- **StorageClass**: `dynamic-storage`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `2Gi`

### Task 6: Deploy application using dynamic storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `dynamic-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `dynamic-app-pvc`
- **Mount Path**: `/usr/share/nginx/html`

### Task 7: Compare the two approaches (2 minutes)
- Observe the differences in PV creation workflow
- Check PV naming patterns and properties
- Verify both applications are running successfully

## Verification Commands

### Compare Static vs Dynamic PV Creation Workflow:
```bash
# Check all PVs - should show manually created 'static-pv' and automatically created PV
kubectl get pv
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,SOURCE:.spec.hostPath.path,CLAIM:.spec.claimRef.name
```

### Verify Static Provisioning Setup:
```bash
# Should show manually created PV with custom name
kubectl get pv static-pv
kubectl describe pv static-pv

# Should show PVC bound to static PV
kubectl get pvc static-app-pvc
kubectl describe pvc static-app-pvc | grep -E "Volume:|Capacity:"

# Should show application running with static storage
kubectl get deployment static-app
kubectl get pods -l app=static-app
```

### Verify Dynamic Provisioning Setup:
```bash
# Should show StorageClass
kubectl get storageclass dynamic-storage

# Should show PVC bound to automatically created PV
kubectl get pvc dynamic-app-pvc
kubectl describe pvc dynamic-app-pvc | grep -E "Volume:|Capacity:"

# Should show application running with dynamic storage
kubectl get deployment dynamic-app
kubectl get pods -l app=dynamic-app
```

### Compare PV Naming Patterns:
```bash
# Static PV: Custom name 'static-pv'
# Dynamic PV: Generated name 'pvc-<uuid>'
kubectl get pv -o custom-columns=NAME:.metadata.name,TYPE:.metadata.labels,CLAIM:.spec.claimRef.name
```

### Check Both Applications Are Working:
```bash
# Both pods should be running
kubectl get pods -l app=static-app
kubectl get pods -l app=dynamic-app

# Check volume mounts
kubectl describe pod -l app=static-app | grep -A5 -B5 "/usr/share/nginx/html"
kubectl describe pod -l app=dynamic-app | grep -A5 -B5 "/usr/share/nginx/html"
```

### Test Storage Functionality:
```bash
# Write test files to both storage types
kubectl exec -it deployment/static-app -- sh -c "echo 'Static Storage Test' > /usr/share/nginx/html/static.txt"
kubectl exec -it deployment/dynamic-app -- sh -c "echo 'Dynamic Storage Test' > /usr/share/nginx/html/dynamic.txt"

# Verify files exist
kubectl exec -it deployment/static-app -- cat /usr/share/nginx/html/static.txt
kubectl exec -it deployment/dynamic-app -- cat /usr/share/nginx/html/dynamic.txt
```

## Expected Results

### Static Provisioning Results:
1. PV `static-pv` exists with custom name and `/tmp/static-storage` path
2. PVC `static-app-pvc` is bound to `static-pv`
3. Deployment `static-app` is running with static storage mounted
4. Manual workflow: PV created first, then PVC binds to existing PV

### Dynamic Provisioning Results:
1. StorageClass `dynamic-storage` exists with rancher.io/local-path provisioner
2. PVC `dynamic-app-pvc` is bound to automatically created PV
3. PV has generated name like `pvc-<uuid>` (not custom name)
4. Deployment `dynamic-app` is running with dynamic storage mounted
5. Automatic workflow: PVC created first, then PV created automatically

### Key Differences Observed:
- **PV Names**: Static uses custom names, Dynamic uses generated names
- **Creation Order**: Static requires PV first, Dynamic creates PV after PVC
- **Management**: Static requires manual PV management, Dynamic is automated
- **Flexibility**: Dynamic can create many PVs easily, Static requires individual PV creation

## Key Learning Points
- **Static Provisioning**: Admin creates PVs manually, PVCs bind to existing PVs
- **Dynamic Provisioning**: StorageClass provisioner creates PVs automatically when PVCs are created
- **Naming Patterns**: Static PVs have custom names, Dynamic PVs have generated pvc-<uuid> names
- **Workflow**: Static = PV → PVC → Pod, Dynamic = StorageClass → PVC → Auto-PV → Pod
- **Use Cases**: Static for specific storage requirements, Dynamic for general automated provisioning

## When to Use Each Approach
- **Static Provisioning**: Pre-existing storage systems, specific performance requirements, legacy environments
- **Dynamic Provisioning**: Cloud environments, automated workflows, development/testing, modern applications

## Real Exam Tips
- Understand both workflows and when each is appropriate
- Practice identifying static vs dynamic PVs by their naming patterns
- Know that most modern Kubernetes environments prefer dynamic provisioning
- Be able to troubleshoot both provisioning methods
- Remember: Static = manual PV creation, Dynamic = StorageClass automation