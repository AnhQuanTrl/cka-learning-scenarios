# CSI Volume Cloning with PVC DataSource

## Scenario Overview
**Time Limit**: 20 minutes  
**Difficulty**: Advanced  
**Environment**: DigitalOcean Kubernetes (DOKS)
**Estimated Cost**: $0.33 for 2-hour learning session

## Objective
Master CSI volume cloning functionality using PVC dataSource to create direct volume-to-volume clones. Understand the differences between cloning and snapshot-based restoration, and learn when to use each approach for development, testing, and data management scenarios.

## Context
Your development team needs rapid provisioning of test environments with production-like data. CSI volume cloning allows direct PVC-to-PVC copying without creating intermediate snapshots. You'll explore clone performance characteristics, limitations, and practical use cases for efficient data management.

## Prerequisites
- Existing DOKS cluster (use `Storage/StorageClass/06-digital-ocean-csi.md` to create)
- CSI driver with volume cloning support
- kubectl access with admin privileges
- Understanding of PVC lifecycle and CSI concepts

## Tasks

### Part 1: Understanding Volume Cloning Capabilities

### Task 1: Verify CSI driver clone support (3 minutes)
- Check CSI driver capabilities for volume cloning
- Understand clone vs snapshot differences
- Verify StorageClass clone compatibility

### Task 2: Create source application with data (5 minutes)
Deploy a source application with these exact specifications:
- **Deployment Name**: `source-app`
- **Image**: `mysql:8.0`
- **PVC Name**: `source-data-pvc`
- **Storage**: `3Gi`
- **StorageClass**: `do-block-storage`
- **Database**: Create sample dataset

### Part 2: Direct Volume Cloning

### Task 3: Clone PVC within same StorageClass (4 minutes)
Create a cloned PVC with these specifications:
- **PVC Name**: `cloned-data-pvc`
- **Data Source**: `source-data-pvc` (PVC clone)
- **Size**: `3Gi` (same as source)
- **StorageClass**: `do-block-storage` (same as source)

### Task 4: Deploy application using cloned volume (4 minutes)
Create a new application using cloned data:
- **Deployment Name**: `cloned-app`
- **Image**: `mysql:8.0`
- **PVC**: `cloned-data-pvc`
- Verify data consistency and independence

### Part 3: Advanced Cloning Scenarios

### Task 5: Test clone independence and data isolation (4 minutes)
- Modify data in source application
- Verify cloned application data remains unchanged
- Test clone isolation and independence
- Compare clone vs snapshot behavior

## Verification Commands

### Check CSI driver cloning capabilities:
```bash
# Check CSI driver capabilities
kubectl describe csidriver dobs.csi.digitalocean.com

# Look for clone capabilities
kubectl get csidriver dobs.csi.digitalocean.com -o yaml | grep -A10 -B10 capabilities

# Check StorageClass for clone support
kubectl describe storageclass do-block-storage
```

### Deploy source MySQL application:
```bash
# Create source PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: source-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: do-block-storage
EOF

# Create MySQL deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: source-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: source-app
  template:
    metadata:
      labels:
        app: source-app
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass123
        - name: MYSQL_DATABASE
          value: sourcedb
        - name: MYSQL_USER
          value: appuser
        - name: MYSQL_PASSWORD
          value: apppass123
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: source-data-pvc
EOF

# Wait for MySQL to be ready
kubectl rollout status deployment/source-app
kubectl wait --for=condition=ready pod -l app=source-app --timeout=180s
```

### Create sample data in source:
```bash
# Create sample dataset
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, category, price, stock_quantity) VALUES
('Laptop Pro', 'Electronics', 1299.99, 50),
('Wireless Mouse', 'Electronics', 29.99, 200),
('Office Chair', 'Furniture', 249.99, 75),
('Smartphone', 'Electronics', 799.99, 120),
('Desk Lamp', 'Furniture', 59.99, 150),
('Tablet', 'Electronics', 399.99, 80),
('Keyboard', 'Electronics', 79.99, 180),
('Monitor', 'Electronics', 299.99, 60);
"

# Verify data creation
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "SELECT COUNT(*) as 'Total Products' FROM products;"
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "SELECT * FROM products LIMIT 5;"
```

### Create cloned PVC:
```bash
# Clone PVC using dataSource
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloned-data-pvc
spec:
  dataSource:
    name: source-data-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: do-block-storage
EOF

# Monitor clone creation
kubectl get pvc cloned-data-pvc -w

# Check clone status and details
kubectl describe pvc cloned-data-pvc
kubectl get pvc source-data-pvc cloned-data-pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,SIZE:.status.capacity.storage
```

### Deploy application with cloned volume:
```bash
# Create deployment using cloned PVC
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloned-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cloned-app
  template:
    metadata:
      labels:
        app: cloned-app
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass123
        - name: MYSQL_DATABASE
          value: sourcedb
        - name: MYSQL_USER
          value: appuser
        - name: MYSQL_PASSWORD
          value: apppass123
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: cloned-data-pvc
EOF

# Wait for cloned application to be ready
kubectl rollout status deployment/cloned-app
kubectl wait --for=condition=ready pod -l app=cloned-app --timeout=180s
```

### Verify data cloning and independence:
```bash
# Verify cloned data exists
kubectl exec -it deployment/cloned-app -- mysql -u root -prootpass123 sourcedb -e "SELECT COUNT(*) as 'Cloned Products' FROM products;"
kubectl exec -it deployment/cloned-app -- mysql -u root -prootpass123 sourcedb -e "SELECT * FROM products LIMIT 3;"

# Test data independence - modify source data
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "
INSERT INTO products (name, category, price, stock_quantity) VALUES
('New Product - Source Only', 'Test', 99.99, 10);
UPDATE products SET price = price * 1.1 WHERE category = 'Electronics';
"

# Verify source changes
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "SELECT COUNT(*) as 'Source Products' FROM products;"
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "SELECT * FROM products WHERE name LIKE '%Source Only%';"

# Verify clone remains unchanged
kubectl exec -it deployment/cloned-app -- mysql -u root -prootpass123 sourcedb -e "SELECT COUNT(*) as 'Cloned Products' FROM products;"
kubectl exec -it deployment/cloned-app -- mysql -u root -prootpass123 sourcedb -e "SELECT * FROM products WHERE name LIKE '%Source Only%';"

# Add data to clone to test independence
kubectl exec -it deployment/cloned-app -- mysql -u root -prootpass123 sourcedb -e "
INSERT INTO products (name, category, price, stock_quantity) VALUES
('Clone Only Product', 'Test', 49.99, 25);
"

# Verify clone-specific data doesn't appear in source
kubectl exec -it deployment/source-app -- mysql -u root -prootpass123 sourcedb -e "SELECT * FROM products WHERE name LIKE '%Clone Only%';"
```

### Compare clone vs source performance:
```bash
# Check volume details
kubectl get pv $(kubectl get pvc source-data-pvc -o jsonpath='{.spec.volumeName}') -o custom-columns=NAME:.metadata.name,SIZE:.spec.capacity.storage,STORAGECLASS:.spec.storageClassName,CREATED:.metadata.creationTimestamp

kubectl get pv $(kubectl get pvc cloned-data-pvc -o jsonpath='{.spec.volumeName}') -o custom-columns=NAME:.metadata.name,SIZE:.spec.capacity.storage,STORAGECLASS:.spec.storageClassName,CREATED:.metadata.creationTimestamp

# Check clone creation events
kubectl get events --field-selector involvedObject.name=cloned-data-pvc --sort-by='.firstTimestamp'

# Monitor both applications
kubectl get pods -l app=source-app,app=cloned-app -o wide
kubectl top pods -l app=source-app
kubectl top pods -l app=cloned-app
```

### Advanced cloning scenarios:
```bash
# Attempt cross-StorageClass clone (should fail or require special handling)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cross-class-clone-pvc
spec:
  dataSource:
    name: source-data-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: standard  # Different StorageClass
EOF

# Check if cross-class cloning is supported
kubectl describe pvc cross-class-clone-pvc | grep -A10 Events:

# Clean up failed clone attempt
kubectl delete pvc cross-class-clone-pvc --ignore-not-found=true
```

## Expected Results

### Clone Creation Results:
1. Cloned PVC `cloned-data-pvc` created successfully from source PVC
2. Clone process completed faster than snapshot+restore workflow
3. Cloned volume has identical data to source at clone time
4. Both source and clone applications run simultaneously

### Data Independence Results:
1. Changes to source data don't affect cloned data
2. Changes to cloned data don't affect source data
3. Both volumes operate independently after clone creation
4. Clone represents point-in-time copy of source volume

### Performance Characteristics:
1. Clone creation is typically faster than snapshot+restore
2. Clone requires same StorageClass as source (in most CSI drivers)
3. Clone size must be equal to or larger than source volume
4. Both volumes consume storage space independently

## Key Learning Points
- **Direct Cloning**: PVC-to-PVC cloning without intermediate snapshots
- **Point-in-Time Copy**: Clone captures source data at creation time
- **Data Independence**: Source and clone are completely independent after creation
- **StorageClass Requirement**: Clone typically requires same StorageClass as source
- **Performance Benefits**: Faster than snapshot+restore for immediate copies
- **CSI Driver Dependency**: Volume cloning requires CSI driver support

## Clone vs Snapshot Comparison

| Feature | Volume Clone | Volume Snapshot |
|---------|-------------|----------------|
| **Creation Speed** | Faster | Slower |
| **Storage Model** | Direct copy | Snapshot + restore |
| **Intermediate Object** | None | VolumeSnapshot |
| **Cross-StorageClass** | Limited | More flexible |
| **Use Case** | Quick copies | Backup/archive |
| **Resource Usage** | Immediate full copy | Incremental initially |

## Use Cases for Volume Cloning
- **Development Environments**: Quick test data provisioning
- **Blue-Green Deployments**: Parallel environment setup
- **Data Migration**: Moving data between applications
- **Performance Testing**: Isolated data copies for load testing
- **Troubleshooting**: Creating debug copies without affecting production

## Production Considerations
- **Storage Cost**: Clones consume full storage space immediately
- **Performance Impact**: Clone creation may affect source volume performance
- **Backup Strategy**: Clones are not backups (both copies in same location)
- **Lifecycle Management**: Plan clone cleanup and lifecycle policies
- **Security**: Ensure cloned data doesn't expose sensitive information

## Real Exam Tips
- Understand dataSource syntax for PVC cloning vs snapshot restoration
- Know that cloning is faster but less flexible than snapshots
- Practice identifying when to use cloning vs snapshots
- Remember that cloned PVCs typically require same StorageClass as source
- Be familiar with clone status checking and troubleshooting common issues
- Understand that clones create independent volumes, not linked copies