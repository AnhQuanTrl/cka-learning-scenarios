# Volume Snapshots and VolumeSnapshotClasses

## Scenario Overview
**Time Limit**: 25 minutes  
**Difficulty**: Advanced  
**Environment**: DigitalOcean Kubernetes (DOKS)
**Estimated Cost**: $0.33 for 2-hour learning session

## Objective
Master Kubernetes volume snapshot functionality including VolumeSnapshot, VolumeSnapshotClass, and VolumeSnapshotContent objects. Learn to create point-in-time snapshots and restore them to new volumes for backup and disaster recovery scenarios.

## Context
Your team needs to implement backup and disaster recovery strategies for stateful applications. Kubernetes volume snapshots provide a standardized way to create point-in-time copies of persistent volumes. You'll explore the complete snapshot ecosystem and learn to manage snapshot lifecycles effectively.

## Prerequisites
- Existing DOKS cluster (use `Storage/StorageClass/06-digital-ocean-csi.md` to create)
- CSI driver with snapshot support
- kubectl access with admin privileges
- Understanding of PVC and PV concepts

## Tasks

### Part 1: Understanding VolumeSnapshotClass

### Task 1: Examine default VolumeSnapshotClass (3 minutes)
- Check if default VolumeSnapshotClass exists
- Understand VolumeSnapshotClass parameters
- Create custom VolumeSnapshotClass if needed

### Task 2: Create custom VolumeSnapshotClass (4 minutes)
Create a VolumeSnapshotClass with these exact specifications:
- **Name**: `fast-snapshots`
- **Driver**: `dobs.csi.digitalocean.com`
- **Deletion Policy**: `Delete`
- **Parameters**: Custom retention settings

### Part 2: Creating and Managing Volume Snapshots

### Task 3: Deploy application with persistent data (4 minutes)
Create a stateful application with these specifications:
- **Deployment Name**: `database-app`
- **Image**: `postgres:13`
- **PVC Name**: `database-pvc`
- **Storage**: `5Gi`
- **StorageClass**: `do-block-storage`
- **Mount Path**: `/var/lib/postgresql/data`

### Task 4: Create meaningful test data (3 minutes)
- Initialize PostgreSQL database
- Create tables and insert test data
- Verify data persistence and integrity

### Task 5: Create VolumeSnapshot (4 minutes)
Create a VolumeSnapshot with these exact specifications:
- **Name**: `database-backup-snapshot`
- **Source PVC**: `database-pvc`
- **VolumeSnapshotClass**: `fast-snapshots`

### Part 3: Snapshot Restoration and Management

### Task 6: Restore snapshot to new PVC (4 minutes)
Create a new PVC from snapshot with these specifications:
- **PVC Name**: `restored-database-pvc`
- **Data Source**: `database-backup-snapshot`
- **Size**: `5Gi`
- **StorageClass**: `do-block-storage`

### Task 7: Verify data restoration (3 minutes)
Deploy a new application using restored PVC:
- **Deployment Name**: `restored-database-app`
- **Image**: `postgres:13`
- **PVC**: `restored-database-pvc`
- Verify original data is present and intact

## Verification Commands

### Check VolumeSnapshotClass support:
```bash
# Check if snapshot CRDs are installed
kubectl get crd | grep snapshot

# List available VolumeSnapshotClasses
kubectl get volumesnapshotclass

# Check default VolumeSnapshotClass
kubectl get volumesnapshotclass -o yaml

# Check CSI driver snapshot support
kubectl describe csidriver dobs.csi.digitalocean.com | grep -i snapshot
```

### Create custom VolumeSnapshotClass:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: fast-snapshots
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "false"
driver: dobs.csi.digitalocean.com
deletionPolicy: Delete
parameters:
  # DigitalOcean specific parameters (if any)
  description: "Fast snapshot class for CKA learning"
EOF

# Verify creation
kubectl get volumesnapshotclass fast-snapshots
kubectl describe volumesnapshotclass fast-snapshots
```

### Deploy PostgreSQL application:
```bash
# Create PVC for database
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: do-block-storage
EOF

# Create PostgreSQL deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database-app
  template:
    metadata:
      labels:
        app: database-app
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: testdb
        - name: POSTGRES_USER
          value: testuser
        - name: POSTGRES_PASSWORD
          value: testpass
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: database-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: database-storage
        persistentVolumeClaim:
          claimName: database-pvc
EOF

# Wait for deployment to be ready
kubectl rollout status deployment/database-app
kubectl get pods -l app=database-app
```

### Create test data:
```bash
# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=database-app --timeout=120s

# Create test data
kubectl exec -it deployment/database-app -- psql -U testuser -d testdb -c "
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employees (name, department) VALUES 
('Alice Johnson', 'Engineering'),
('Bob Smith', 'Marketing'),
('Carol Davis', 'Engineering'),
('David Wilson', 'Sales'),
('Eva Brown', 'Engineering');
"

# Verify data
kubectl exec -it deployment/database-app -- psql -U testuser -d testdb -c "SELECT COUNT(*) FROM employees;"
kubectl exec -it deployment/database-app -- psql -U testuser -d testdb -c "SELECT * FROM employees;"
```

### Create VolumeSnapshot:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: database-backup-snapshot
spec:
  volumeSnapshotClassName: fast-snapshots
  source:
    persistentVolumeClaimName: database-pvc
EOF

# Monitor snapshot creation
kubectl get volumesnapshot database-backup-snapshot -w

# Check snapshot status
kubectl describe volumesnapshot database-backup-snapshot
kubectl get volumesnapshot database-backup-snapshot -o jsonpath='{.status.readyToUse}'

# Check VolumeSnapshotContent
kubectl get volumesnapshotcontent
kubectl describe volumesnapshotcontent $(kubectl get volumesnapshot database-backup-snapshot -o jsonpath='{.status.boundVolumeSnapshotContentName}')
```

### Restore from snapshot:
```bash
# Create PVC from snapshot
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-database-pvc
spec:
  dataSource:
    name: database-backup-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: do-block-storage
EOF

# Deploy restored application
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restored-database-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: restored-database-app
  template:
    metadata:
      labels:
        app: restored-database-app
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: testdb
        - name: POSTGRES_USER
          value: testuser
        - name: POSTGRES_PASSWORD
          value: testpass
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: database-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: database-storage
        persistentVolumeClaim:
          claimName: restored-database-pvc
EOF

# Wait for restoration deployment
kubectl rollout status deployment/restored-database-app
kubectl get pods -l app=restored-database-app
```

### Verify data restoration:
```bash
# Wait for restored PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=restored-database-app --timeout=120s

# Verify restored data
kubectl exec -it deployment/restored-database-app -- psql -U testuser -d testdb -c "SELECT COUNT(*) FROM employees;"
kubectl exec -it deployment/restored-database-app -- psql -U testuser -d testdb -c "SELECT * FROM employees ORDER BY id;"

# Compare with original data
echo "=== Original Database ==="
kubectl exec -it deployment/database-app -- psql -U testuser -d testdb -c "SELECT * FROM employees ORDER BY id;"

echo "=== Restored Database ==="
kubectl exec -it deployment/restored-database-app -- psql -U testuser -d testdb -c "SELECT * FROM employees ORDER BY id;"
```

### Advanced snapshot management:
```bash
# List all snapshots
kubectl get volumesnapshot

# Check snapshot sizes and creation times
kubectl get volumesnapshot -o custom-columns=NAME:.metadata.name,READY:.status.readyToUse,SIZE:.status.restoreSize,CREATED:.metadata.creationTimestamp

# Monitor snapshot events
kubectl get events --field-selector involvedObject.kind=VolumeSnapshot

# Check snapshot content details
kubectl get volumesnapshotcontent -o custom-columns=NAME:.metadata.name,SNAPSHOT:.spec.volumeSnapshotRef.name,SIZE:.status.restoreSize,HANDLE:.status.snapshotHandle
```

## Expected Results

### VolumeSnapshotClass Results:
1. Custom VolumeSnapshotClass `fast-snapshots` created successfully
2. VolumeSnapshotClass configured with DigitalOcean CSI driver
3. Deletion policy set to automatically clean up snapshots

### Snapshot Creation Results:
1. VolumeSnapshot `database-backup-snapshot` created from active PVC
2. VolumeSnapshotContent automatically created by CSI driver
3. Snapshot shows `readyToUse: true` status
4. Snapshot visible in DigitalOcean Control Panel

### Restoration Results:
1. New PVC `restored-database-pvc` created from snapshot
2. Restored application successfully accesses snapshot data
3. All original data intact and queryable
4. Both original and restored applications run simultaneously

## Key Learning Points
- **VolumeSnapshotClass**: Defines how snapshots are created and managed
- **VolumeSnapshot**: User request for a snapshot of a specific PVC
- **VolumeSnapshotContent**: Actual snapshot resource created by CSI driver
- **Point-in-Time Consistency**: Snapshots capture exact state at creation time
- **CSI Driver Integration**: Snapshot functionality requires CSI driver support
- **Restoration Process**: Snapshots can be restored to new PVCs for recovery

## Volume Snapshot Lifecycle
1. **Create VolumeSnapshotClass** - Define snapshot behavior and parameters
2. **Request VolumeSnapshot** - Create snapshot from existing PVC
3. **CSI Driver Processing** - Driver creates actual snapshot and VolumeSnapshotContent
4. **Snapshot Ready** - Status shows readyToUse: true
5. **Restoration** - Create new PVC using snapshot as dataSource
6. **Cleanup** - Delete snapshots based on deletion policy

## Production Considerations
- **Backup Strategy**: Regular automated snapshots for disaster recovery
- **Retention Policies**: Configure appropriate snapshot retention periods
- **Cost Management**: Monitor snapshot storage costs and cleanup old snapshots
- **Testing**: Regularly test snapshot restoration procedures
- **Security**: Ensure snapshots don't contain sensitive data in metadata

## Real Exam Tips
- Understand the three-object model: VolumeSnapshotClass, VolumeSnapshot, VolumeSnapshotContent
- Practice creating snapshots from running applications
- Know how to restore snapshots to new PVCs with correct dataSource syntax
- Remember that snapshots require CSI driver support (not available with all provisioners)
- Be familiar with snapshot status fields and troubleshooting common issues