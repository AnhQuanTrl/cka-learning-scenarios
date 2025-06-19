# Volume Binding Modes

## Scenario Overview
**Time Limit**: 20 minutes  
**Difficulty**: Intermediate  
**Environment**: k3s bare metal

## Objective
Understand the difference between `Immediate` and `WaitForFirstConsumer` volume binding modes by observing when PersistentVolume creation and binding occurs in each mode.

## Context
Your team needs to understand when volumes are created and bound in different scenarios. Some applications require immediate storage provisioning, while others benefit from topology-aware volume placement. You'll test both binding modes to understand their behavior and use cases.

## Prerequisites
- k3s cluster with multiple nodes (or single node for basic testing)
- kubectl access with admin privileges
- Clean environment (no existing PVs/PVCs)

## Tasks

### Task 1: Create StorageClass with Immediate binding (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `immediate-storage`
- **Provisioner**: `rancher.io/local-path`
- **Volume Binding Mode**: `Immediate`
- **Reclaim Policy**: `Delete`

### Task 2: Create StorageClass with WaitForFirstConsumer binding (3 minutes)
Create a StorageClass with these exact specifications:
- **Name**: `wait-storage`
- **Provisioner**: `rancher.io/local-path`
- **Volume Binding Mode**: `WaitForFirstConsumer`
- **Reclaim Policy**: `Delete`

### Task 3: Create PVC with Immediate binding and observe timing (4 minutes)
Create a PVC with these exact specifications:
- **Name**: `immediate-pvc`
- **StorageClass**: `immediate-storage`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `1Gi`

Observe when the PV is created (should be immediately after PVC creation).

### Task 4: Create PVC with WaitForFirstConsumer binding and observe timing (4 minutes)
Create a PVC with these exact specifications:
- **Name**: `wait-pvc`
- **StorageClass**: `wait-storage`
- **Access Mode**: `ReadWriteOnce`
- **Storage Request**: `1Gi`

Observe the PVC status (should remain Pending until a Pod consumes it).

### Task 5: Deploy application with node selector consuming Immediate storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `immediate-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `immediate-pvc`
- **Mount Path**: `/usr/share/nginx/html`
- **Node Selector**: `kubernetes.io/hostname=<specific-node-name>`

Note: Replace `<specific-node-name>` with an actual node name from your cluster.
Observe potential scheduling issues if storage isn't accessible from the selected node.

### Task 6: Deploy application with node selector consuming WaitForFirstConsumer storage (3 minutes)
Create a Deployment with these exact specifications:
- **Name**: `wait-app`
- **Image**: `nginx:1.20`
- **Replicas**: 1
- **PVC**: `wait-pvc`
- **Mount Path**: `/usr/share/nginx/html`
- **Node Selector**: `kubernetes.io/hostname=<specific-node-name>`

Note: Use the same node name as Task 5 for comparison.
Observe when the PV is created (should be after Pod creation and aligned with node placement).

## Verification Commands

### Check StorageClasses are created correctly:
```bash
# Should show both StorageClasses with different binding modes
kubectl get storageclass immediate-storage wait-storage
kubectl describe storageclass immediate-storage | grep -i binding
kubectl describe storageclass wait-storage | grep -i binding
```

### Observe Immediate binding behavior:
```bash
# Create PVC and immediately check PV creation
kubectl apply -f immediate-pvc.yaml
kubectl get pvc immediate-pvc
kubectl get pv

# PV should be created immediately
kubectl get pvc immediate-pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName
```

### Observe WaitForFirstConsumer binding behavior:
```bash
# Create PVC and check status - should be Pending
kubectl apply -f wait-pvc.yaml
kubectl get pvc wait-pvc
kubectl get pv

# PVC should be Pending, no PV created yet
kubectl describe pvc wait-pvc | grep -E "Status:|Events:"
```

### Verify binding occurs after Pod creation for WaitForFirstConsumer:
```bash
# Before deploying the Pod
kubectl get pvc wait-pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName

# Deploy the Pod that consumes wait-pvc
kubectl apply -f wait-app.yaml

# After Pod creation, check if PV is now created and bound
kubectl get pvc wait-pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName
kubectl get pv
```

### Check node placement and verify topology awareness:
```bash
# Get node names for node selector
kubectl get nodes -o custom-columns=NAME:.metadata.name

# Both applications should be running on the specified node
kubectl get deployment immediate-app wait-app
kubectl get pods -l app=immediate-app -o wide
kubectl get pods -l app=wait-app -o wide

# Check if pods are scheduled on the correct node
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# Verify storage is mounted correctly
kubectl describe pod -l app=immediate-app | grep -A3 -B3 "/usr/share/nginx/html"
kubectl describe pod -l app=wait-app | grep -A3 -B3 "/usr/share/nginx/html"
```

### Compare PV creation timing:
```bash
# Check when PVs were created (timestamps)
kubectl get pv -o custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp,CLAIM:.spec.claimRef.name

# Check PVC creation and binding events
kubectl describe pvc immediate-pvc | grep Events: -A10
kubectl describe pvc wait-pvc | grep Events: -A10
```

### Test with multiple PVCs to see pattern:
```bash
# Create additional PVCs to observe consistent behavior
kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: immediate-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: immediate-storage
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wait-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: wait-storage
EOF

# Check binding behavior
kubectl get pvc immediate-test-pvc wait-test-pvc
kubectl get pv
```

## Expected Results

### Immediate Binding Mode Results:
1. PVC `immediate-pvc` is created and immediately bound
2. PV is created as soon as PVC is created, without knowing Pod placement
3. PVC status changes to `Bound` immediately
4. Pod with node selector may face scheduling conflicts if storage isn't accessible from target node
5. Risk of storage/Pod location mismatch

### WaitForFirstConsumer Binding Mode Results:
1. PVC `wait-pvc` is created but remains in `Pending` status
2. No PV is created initially
3. PV is only created after Pod scheduling decision is made
4. PVC status changes to `Bound` only after Pod placement is determined
5. Storage provisioned with full knowledge of Pod's target node

### Key Timing and Topology Differences Observed:
- **Immediate**: PVC created → PV created immediately (no node knowledge) → Pod deployed
- **WaitForFirstConsumer**: PVC created (Pending) → Pod scheduled to node → PV created on correct node → PVC bound

### Storage Provisioning Timeline:
- **Immediate mode**: Storage ready before workload scheduling (potential topology mismatch)
- **WaitForFirstConsumer mode**: Storage provisioned after workload scheduling (topology-aware)

## Key Learning Points
- **Immediate Mode**: PV binding happens immediately when PVC is created, without Pod placement knowledge
- **WaitForFirstConsumer Mode**: PV binding is delayed until Pod scheduling, enabling topology-aware placement
- **Topology Awareness**: WaitForFirstConsumer considers node selectors, affinity, and scheduling constraints
- **Scheduling Risk**: Immediate mode may create storage in wrong location, causing Pod scheduling failures
- **Resource Efficiency**: WaitForFirstConsumer avoids creating inaccessible volumes
- **Node Selectors**: Both modes respect node selectors, but WaitForFirstConsumer aligns storage placement accordingly

## When to Use Each Mode
- **Immediate Mode**: Simple single-node environments, network-attached storage, legacy applications
- **WaitForFirstConsumer Mode**: Multi-node clusters, local storage, topology-sensitive applications, node-constrained workloads

## Multi-Node and Topology Considerations
In multi-node clusters, WaitForFirstConsumer ensures:
- Volumes are created on the same node/zone as the consuming Pod
- Prevents Pod scheduling failures due to storage/node location mismatches
- Supports topology-aware volume placement with node selectors and affinity rules
- Eliminates cross-node storage access issues for local storage
- Respects scheduling constraints (taints, tolerations, resource limits)

## Real Exam Tips
- Understand when PV creation occurs in each binding mode
- Practice identifying binding mode by observing PVC status behavior
- Know that WaitForFirstConsumer optimizes for topology awareness
- Remember: Immediate = instant binding, WaitForFirstConsumer = delayed until Pod creation
- Be able to troubleshoot Pending PVCs based on binding mode behavior