# Static vs Dynamic Provisioning with StorageClasses

## Scenario Overview
**Time Limit**: 20 minutes  
**Difficulty**: Intermediate  
**Environment**: k3s bare metal

## Objective
Understand the difference between static provisioning (using `kubernetes.io/no-provisioner` StorageClass with manually created PVs) and dynamic provisioning (StorageClass automatically creates PVs). Compare both approaches using StorageClasses.

## Context
Your team needs to understand the two provisioning models within the StorageClass framework. Static provisioning uses `no-provisioner` StorageClasses where PVs are manually created but still associated with a StorageClass. Dynamic provisioning uses provisioner plugins that automatically create PVs when PVCs are created.

## Prerequisites
- k3s cluster running
- kubectl access with admin privileges
- Clean environment (no existing PVs/PVCs to avoid confusion)

## Tasks

## Part 1: Static Provisioning (No-Provisioner StorageClass)

### Task 1: Create StorageClass for static provisioning (2 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `static-storage`
- **Provisioner**: `kubernetes.io/no-provisioner`
- **Volume Binding Mode**: `WaitForFirstConsumer`
- **Reclaim Policy**: `Retain`

### Task 2: Manually create PersistentVolume for static provisioning (4 minutes)
Create a PV with these exact specifications:
- **Name**: `static-pv`
- **Capacity**: `2Gi`
- **Access Mode**: `ReadWriteOnce`
- **Reclaim Policy**: `Retain`
- **StorageClass**: `static-storage`
- **Host Path**: `/tmp/static-storage` (use local storage for k3s)

### Task 3: Create PVC for static provisioning (2 minutes)
Create a PVC that binds to the manually created PV:
- **Name**: `static-app-pvc`
- **StorageClass**: `static-storage`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `2Gi`

### Task 4: Deploy application using static storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `static-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `static-app-pvc`
- **Mount Path**: `/usr/share/nginx/html`

## Part 2: Dynamic Provisioning (Automatic PV Creation)

### Task 5: Create StorageClass for dynamic provisioning (2 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `dynamic-storage`
- **Provisioner**: `rancher.io/local-path`
- **Reclaim Policy**: `Delete`
- **Volume Binding Mode**: `Immediate`

### Task 6: Create PVC for dynamic provisioning (3 minutes)
Create a PVC that triggers automatic PV creation:
- **Name**: `dynamic-app-pvc`
- **StorageClass**: `dynamic-storage`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `2Gi`

### Task 7: Deploy application using dynamic storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `dynamic-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `dynamic-app-pvc`
- **Mount Path**: `/usr/share/nginx/html`

### Task 8: Compare the two approaches (2 minutes)
- Observe the differences in PV creation workflow
- Check PV naming patterns and properties
- Verify both applications are running successfully

## Verification Commands

### Compare Static vs Dynamic StorageClass Provisioning:
```bash
# Check both StorageClasses - should show no-provisioner vs rancher.io/local-path
kubectl get storageclass static-storage dynamic-storage
kubectl describe storageclass static-storage | grep -E "Provisioner:|VolumeBindingMode:"
kubectl describe storageclass dynamic-storage | grep -E "Provisioner:|VolumeBindingMode:"

# Check PVs - should show manually created 'static-pv' and automatically created PV
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,CAPACITY:.spec.capacity.storage,CLAIM:.spec.claimRef.name
```

### Verify Static Provisioning Setup:
```bash
# Should show manually created PV with custom name and static-storage StorageClass
kubectl get pv static-pv
kubectl describe pv static-pv | grep -E "StorageClass:|Source:"

# Should show PVC bound to static PV via static-storage StorageClass
kubectl get pvc static-app-pvc
kubectl describe pvc static-app-pvc | grep -E "Volume:|StorageClass:|Capacity:"

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

### Compare PV Creation Methods:
```bash
# Static PV: Custom name 'static-pv' with no-provisioner StorageClass
# Dynamic PV: Generated name 'pvc-<uuid>' with rancher.io/local-path provisioner
kubectl get pv -o custom-columns=NAME:.metadata.name,STORAGECLASS:.spec.storageClassName,PROVISIONER:.metadata.annotations.pv\\.kubernetes\\.io/provisioned-by,CLAIM:.spec.claimRef.name
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
1. StorageClass `static-storage` exists with `kubernetes.io/no-provisioner`
2. PV `static-pv` exists with custom name, `/tmp/static-storage` path, and `static-storage` StorageClass
3. PVC `static-app-pvc` is bound to `static-pv` through StorageClass matching
4. Deployment `static-app` is running with static storage mounted
5. Manual workflow: StorageClass → Manual PV creation → PVC binds to existing PV

### Dynamic Provisioning Results:
1. StorageClass `dynamic-storage` exists with `rancher.io/local-path` provisioner
2. PVC `dynamic-app-pvc` triggers automatic PV creation through StorageClass
3. PV has generated name like `pvc-<uuid>` and references `dynamic-storage` StorageClass
4. Deployment `dynamic-app` is running with dynamic storage mounted
5. Automatic workflow: StorageClass → PVC creation → Automatic PV creation

### Key Differences Observed:
- **Provisioner**: Static uses `no-provisioner`, Dynamic uses `rancher.io/local-path`
- **PV Creation**: Static requires manual PV creation, Dynamic creates PV automatically
- **StorageClass Role**: Static StorageClass only for matching, Dynamic StorageClass drives provisioning
- **Management**: Static requires pre-planning PVs, Dynamic scales on-demand

## Key Learning Points
- **Static Provisioning**: Uses `kubernetes.io/no-provisioner` StorageClass with manually created PVs
- **Dynamic Provisioning**: Uses provisioner plugins in StorageClass to automatically create PVs
- **StorageClass Role**: Static uses StorageClass for matching only, Dynamic uses StorageClass for provisioning
- **Workflow**: Static = no-provisioner StorageClass → Manual PV → PVC binding, Dynamic = provisioner StorageClass → PVC → Auto-PV creation
- **Volume Control**: Static gives precise control over PV creation and placement, Dynamic provides automation and scalability

## When to Use Each Approach
- **Static Provisioning**: Local storage, pre-existing volumes, precise control requirements, specific topology needs
- **Dynamic Provisioning**: Cloud environments, automated scaling, development/testing, general-purpose storage

## Real Exam Tips
- Understand the difference between `kubernetes.io/no-provisioner` and provisioner plugins
- Know that static provisioning still uses StorageClasses (with no-provisioner)
- Practice creating both no-provisioner and dynamic StorageClasses
- Recognize that static PVs must match StorageClass specifications exactly
- Remember: Static = no-provisioner StorageClass + manual PVs, Dynamic = provisioner StorageClass + automatic PVs