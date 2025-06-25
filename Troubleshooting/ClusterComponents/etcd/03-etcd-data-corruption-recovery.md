# etcd Data Corruption and Recovery

## Scenario Overview
- **Time Limit**: 50 minutes
- **Difficulty**: Expert
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master critical etcd data corruption recovery techniques including backup restoration, cluster rebuild procedures, and disaster recovery workflows essential for production cluster survival.

## Context
It's Friday evening and disaster strikes: your primary production Kubernetes cluster has lost all etcd data due to a catastrophic storage failure. The SAN array suffered a complete meltdown, corrupting the etcd data directory across all control plane nodes. All cluster state is lost - deployments, services, secrets, everything. Your team has 50 minutes before the Monday morning release window, and you need to restore the cluster from backups while preserving as much application state as possible. The business is depending on you to execute a flawless disaster recovery.

## Prerequisites
- Access to Killercoda Ubuntu Playground with a running kubeadm cluster
- Root access to control plane nodes with etcd data directory access
- Understanding of etcd cluster architecture and data consistency
- Familiarity with etcdctl backup and restore commands

## Tasks

### Task 1: Create Production Environment and Initial Backup (8 minutes)
Set up a realistic production environment with critical data and create baseline backups before simulating corruption.

Create **critical production workloads** with important state:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: DB_CONNECTION
          value: "postgresql://payments-db:5432/payments"
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: production
spec:
  selector:
    app: payment-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create **critical configuration data**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: payment-secrets
  namespace: production
type: Opaque
data:
  api-key: cGF5bWVudC1hcGkta2V5LXNlY3JldA== # payment-api-key-secret
  db-password: c3VwZXItc2VjdXJlLXBhc3N3b3Jk # super-secure-password
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: payment-config
  namespace: production
data:
  config.properties: |
    environment=production
    payment.processor.url=https://api.payments.company.com
    payment.timeout=30000
    payment.retry.count=3
    logging.level=INFO
```

Create **RBAC and ServiceAccounts**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service-account
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: payment-service-role
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payment-service-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: payment-service-account
  namespace: production
roleRef:
  kind: Role
  name: payment-service-role
  apiGroup: rbac.authorization.k8s.io
```

**Create baseline etcd backup**:
```bash
# Create backup directory
sudo mkdir -p /var/backups/etcd

# Create etcd snapshot
sudo ETCDCTL_API=3 etcdctl snapshot save /var/backups/etcd/backup-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup integrity
sudo ETCDCTL_API=3 etcdctl snapshot status /var/backups/etcd/backup-*.db --write-out=table
```

### Task 2: Simulate Catastrophic Data Corruption (10 minutes)
Create realistic data corruption scenarios that require full disaster recovery procedures.

**Method 1: Simulate disk full scenario causing data corruption**:
```bash
# Fill etcd data directory to simulate disk full
sudo dd if=/dev/zero of=/var/lib/etcd/disk-full-file bs=1M count=100

# Stop etcd to prevent further corruption
sudo systemctl stop etcd

# Corrupt etcd database files
sudo truncate -s 0 /var/lib/etcd/member/wal/0000000000000000-0000000000000000.wal
```

**Method 2: Manually corrupt etcd database files**:
```bash
# Stop etcd service
sudo systemctl stop etcd

# Corrupt the etcd database
sudo dd if=/dev/urandom of=/var/lib/etcd/member/snap/db bs=1M count=1 conv=notrunc

# Corrupt WAL files
sudo rm -f /var/lib/etcd/member/wal/*
```

**Method 3: Delete etcd member configuration (simulating cluster split)**:
```bash
# Stop etcd
sudo systemctl stop etcd

# Remove member directory completely
sudo rm -rf /var/lib/etcd/member

# Modify cluster configuration to simulate member mismatch
sudo mkdir -p /var/lib/etcd/member
echo "corrupted-cluster-id" | sudo tee /var/lib/etcd/member/cluster_id
```

**Method 4: Simulate complete data directory loss**:
```bash
# Stop etcd
sudo systemctl stop etcd

# Backup the data directory (to simulate external backup)
sudo mv /var/lib/etcd /var/lib/etcd-corrupted-$(date +%Y%m%d-%H%M%S)

# Create empty directory simulating complete data loss
sudo mkdir -p /var/lib/etcd
sudo chown -R etcd:etcd /var/lib/etcd
```

### Task 3: Assess Data Loss and Corruption Impact (8 minutes)
Document the extent of data corruption and cluster state loss.

**Attempt cluster recovery**:
- Try to start etcd and assess failure modes
- Examine etcd logs for corruption error messages
- Test if any data can be recovered from corrupted files

**Validate cluster state loss**:
- Verify API server cannot connect to etcd
- Confirm all kubectl commands fail
- Document that all cluster state is effectively lost

**Assess backup integrity**:
- Verify backup files exist and are not corrupted
- Check backup file sizes and timestamps
- Test backup file integrity using etcdctl

**Plan recovery strategy**:
- Determine if corruption is recoverable without backup restoration
- Identify which applications will need to be redeployed
- Document the scope of data loss requiring restoration

### Task 4: etcd Cluster Rebuild and Data Restoration (15 minutes)
Execute complete etcd cluster rebuild using backup restoration procedures.

**Prepare for restoration**:
```bash
# Stop all cluster components
sudo systemctl stop kubelet
sudo systemctl stop etcd

# Ensure clean etcd data directory
sudo rm -rf /var/lib/etcd/*
sudo mkdir -p /var/lib/etcd
```

**Restore etcd from backup**:
```bash
# Restore etcd cluster from snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/backup-*.db \
  --name etcd-$(hostname) \
  --initial-cluster etcd-$(hostname)=https://127.0.0.1:2380 \
  --initial-cluster-token etcd-cluster-restored \
  --initial-advertise-peer-urls https://127.0.0.1:2380 \
  --data-dir /var/lib/etcd

# Fix ownership
sudo chown -R etcd:etcd /var/lib/etcd
```

**Update etcd configuration for restored cluster**:
```bash
# Update etcd manifest if needed for new cluster token
sudo sed -i 's/--initial-cluster-token=.*/--initial-cluster-token=etcd-cluster-restored/' \
  /etc/kubernetes/manifests/etcd.yaml

# Ensure proper data directory
sudo sed -i 's|hostPath: {path: /var/lib/etcd.*}|hostPath: {path: /var/lib/etcd, type: DirectoryOrCreate}|' \
  /etc/kubernetes/manifests/etcd.yaml
```

**Restart cluster components**:
```bash
# Start etcd
sudo systemctl start etcd

# Wait for etcd to be ready
sleep 10

# Start kubelet
sudo systemctl start kubelet

# Monitor cluster component startup
sudo systemctl status etcd kubelet
```

### Task 5: Cluster State Validation and Application Recovery (7 minutes)
Verify complete cluster restoration and validate all critical application state.

**Validate etcd cluster health**:
```bash
# Check etcd health
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify cluster member status
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**Verify API server connectivity**:
```bash
# Test basic cluster functionality
kubectl get nodes
kubectl get namespaces
kubectl cluster-info
```

**Validate restored application state**:
```bash
# Check if production namespace and resources are restored
kubectl get all -n production
kubectl get secrets -n production
kubectl get configmaps -n production
kubectl get serviceaccounts -n production

# Verify RBAC is intact
kubectl auth can-i get secrets --as=system:serviceaccount:production:payment-service-account -n production
```

**Test application functionality**:
```bash
# Verify payment service is functional
kubectl get deployment payment-service -n production -o wide
kubectl get pods -n production -l app=payment-service

# Test service connectivity
kubectl exec -n production deployment/payment-service -- curl -s payment-service:80
```

### Task 6: Post-Recovery Monitoring and Backup Strategy (2 minutes)
Implement monitoring and establish improved backup procedures to prevent future data loss.

**Monitor cluster stability post-recovery**:
```bash
# Check for any abnormal behavior
kubectl get events --sort-by='.lastTimestamp' | tail -20
kubectl get pods --all-namespaces | grep -v Running

# Verify resource integrity
kubectl get all --all-namespaces --no-headers | wc -l
```

**Establish improved backup procedures**:
```bash
# Create automated backup script
cat > /usr/local/bin/etcd-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/etcd"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup-$DATE.db"

sudo ETCDCTL_API=3 etcdctl snapshot save $BACKUP_FILE \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Keep only last 7 days of backups
find $BACKUP_DIR -name "backup-*.db" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/etcd-backup.sh

# Test backup script
/usr/local/bin/etcd-backup.sh
```

## Verification Commands

### Task 1 Verification
```bash
# Verify production workloads are created
kubectl get all -n production
kubectl get secrets,configmaps -n production
kubectl get serviceaccounts,roles,rolebindings -n production

# Verify backup was created
ls -la /var/backups/etcd/
sudo ETCDCTL_API=3 etcdctl snapshot status /var/backups/etcd/backup-*.db --write-out=table
```
**Expected Output**: All production resources should exist, backup file should be present with valid status showing hash, revision, and total keys.

### Task 2 Verification
```bash
# Verify etcd corruption (choose based on method used)
sudo systemctl status etcd
sudo journalctl -u etcd --no-pager -l

# Check data directory corruption
sudo ls -la /var/lib/etcd/
sudo ls -la /var/lib/etcd/member/

# Test cluster inaccessibility
kubectl get nodes --request-timeout=5s
```
**Expected Output**: etcd service should be failed/stopped, data directory should be corrupted/missing, kubectl commands should fail with connection errors.

### Task 3 Verification
```bash
# Assess restoration options
sudo ETCDCTL_API=3 etcdctl snapshot status /var/backups/etcd/backup-*.db --write-out=table

# Check cluster accessibility
kubectl cluster-info --request-timeout=5s

# Verify corruption extent
sudo ls -la /var/lib/etcd/member/snap/ 2>/dev/null || echo "Snap directory missing"
sudo ls -la /var/lib/etcd/member/wal/ 2>/dev/null || echo "WAL directory missing"
```
**Expected Output**: Backup should show valid status, cluster should be inaccessible, corruption should be confirmed in etcd data structures.

### Task 4 Verification
```bash
# Verify restoration completed
sudo ls -la /var/lib/etcd/member/
sudo systemctl status etcd

# Check etcd health after restoration
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Test API server reconnection
kubectl get componentstatuses
kubectl get nodes
```
**Expected Output**: etcd data directory should be restored, etcd service should be healthy, API server should be accessible, nodes should show Ready status.

### Task 5 Verification
```bash
# Verify complete cluster functionality
kubectl get all --all-namespaces
kubectl get namespaces

# Check production workload restoration
kubectl get deployment payment-service -n production
kubectl describe deployment payment-service -n production

# Verify secrets and configmaps are restored
kubectl get secret payment-secrets -n production -o yaml
kubectl get configmap payment-config -n production -o yaml

# Test RBAC restoration
kubectl auth can-i get configmaps --as=system:serviceaccount:production:payment-service-account -n production
```
**Expected Output**: All namespaces and resources should be present, production deployment should show 3/3 ready replicas, secrets should contain original data, RBAC should work correctly.

### Task 6 Verification
```bash
# Check cluster stability
kubectl get events --sort-by='.lastTimestamp' | head -10
kubectl get pods --all-namespaces | grep -v Running

# Verify backup automation
ls -la /usr/local/bin/etcd-backup.sh
/usr/local/bin/etcd-backup.sh
ls -la /var/backups/etcd/

# Test backup integrity
sudo ETCDCTL_API=3 etcdctl snapshot status /var/backups/etcd/backup-*.db --write-out=table | tail -1
```
**Expected Output**: No critical events or failing pods, backup script should be executable, new backup should be created successfully with valid status.

## Expected Results
- Complete etcd cluster restoration from backup with all data intact
- All production workloads (payment-service deployment) restored and functional
- Critical configuration data (secrets, configmaps) fully recovered
- RBAC and ServiceAccount configurations restored and working
- Cluster operating normally with all components healthy
- Automated backup procedures established for future protection
- Full disaster recovery capability demonstrated and validated

## Key Learning Points
- **Backup criticality**: etcd backups are the only way to recover from complete data corruption - they are literally cluster survival insurance
- **Disaster recovery procedures**: Complete cluster rebuild requires stopping all components and restoring etcd state first
- **etcdctl restore process**: Understanding snapshot restore with proper cluster tokens and member configuration
- **Data corruption types**: Different corruption scenarios (disk full, file corruption, member loss) require different recovery approaches
- **Recovery validation**: Systematic verification that all cluster state and application data is properly restored
- **Backup automation**: Regular automated backups are essential for production cluster survival
- **Business continuity**: Understanding the impact of cluster data loss on business operations and recovery time objectives

## Exam & Troubleshooting Tips
- **CKA Exam Focus**: Backup and restore is a critical exam topic - know `etcdctl snapshot save` and `etcdctl snapshot restore` commands
- **Critical Commands**: 
  - `etcdctl snapshot save backup.db` for creating backups
  - `etcdctl snapshot restore backup.db --data-dir /new/path` for restoring
  - `etcdctl snapshot status backup.db` for verifying backup integrity
- **Production Best Practices**:
  - Schedule automated daily etcd backups
  - Store backups on separate storage systems (not same disk as etcd)
  - Test backup restoration procedures regularly
  - Monitor etcd disk space to prevent corruption
  - Implement cluster-level backups for multi-master setups
- **Recovery Strategy**:
  - Always try least destructive recovery first (restart services)
  - Check if corruption is localized before full restoration
  - Document recovery procedures and practice them
  - Have backup retention policies (keep multiple backup generations)
- **Common Mistakes**:
  - Not setting proper ownership after restoration (`chown -R etcd:etcd /var/lib/etcd`)
  - Forgetting to update cluster tokens in manifests
  - Not validating backup integrity before disaster strikes
  - Assuming backups work without testing restoration
- **Emergency Procedures**: In real disasters, speed matters - have documented runbooks and practice restoration under pressure
- **Multi-Master Considerations**: For production clusters with multiple control plane nodes, understand distributed backup and restore procedures