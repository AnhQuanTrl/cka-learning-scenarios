# API Server Storage and Encryption Issues

## Scenario Overview
- **Time Limit**: 55 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda kubeadm cluster

## Objective
Master API server storage, encryption, and admission controller troubleshooting by systematically breaking and recovering from configuration issues that affect data security, audit compliance, and resource creation workflows.

## Context
You're the lead security engineer responding to an urgent security compliance audit finding. The team attempted to implement encryption at rest and enhanced audit logging to meet new regulatory requirements, but the changes have caused widespread cluster functionality issues. Secrets and ConfigMaps aren't being encrypted properly, audit logs are missing critical security events, and certain admission controllers are blocking legitimate resource creation. The compliance deadline is approaching, and you must quickly resolve these storage and encryption issues while maintaining data integrity.

## Prerequisites
- Running Killercoda kubeadm cluster with etcd access
- Understanding of Kubernetes encryption at rest concepts
- Familiarity with etcdctl commands and etcd data inspection
- Knowledge of admission controllers and audit logging
- SSH access to control plane node

## Tasks

### Task 1: Baseline Setup and Encryption Validation (10 minutes)
Establish encryption at rest and create comprehensive baseline validation.

1a. Verify current cluster health and encryption status:
```bash
kubectl get nodes
kubectl get pods -A | grep -E "(api|etcd)"
```

1b. Check if encryption is currently configured:
```bash
sudo grep -i "encryption" /etc/kubernetes/manifests/kube-apiserver.yaml
ls -la /etc/kubernetes/pki/encryption* 2>/dev/null || echo "No encryption configuration found"
```

1c. Create initial encryption configuration:
```bash
# Generate encryption key
head -c 32 /dev/urandom | base64 > /tmp/encryption-key

# Create EncryptionConfiguration
cat <<EOF | sudo tee /etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(cat /tmp/encryption-key)
  - identity: {}
EOF
```

1d. Configure API server with encryption:
```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/apiserver-backup.yaml

# Add encryption configuration to API server
sudo sed -i '/- kube-apiserver/a\    - --encryption-provider-config=/etc/kubernetes/pki/encryption-config.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml

# Add volume mount for encryption config
sudo sed -i '/volumeMounts:/a\    - mountPath: /etc/kubernetes/pki/encryption-config.yaml\n      name: encryption-config\n      readOnly: true' /etc/kubernetes/manifests/kube-apiserver.yaml

# Add volume for encryption config
sudo sed -i '/volumes:/a\  - hostPath:\n      path: /etc/kubernetes/pki/encryption-config.yaml\n      type: File\n    name: encryption-config' /etc/kubernetes/manifests/kube-apiserver.yaml
```

1e. Wait for API server restart and create test resources:
```bash
# Wait for API server to restart
sleep 60
kubectl get nodes

# Create test secret and configmap for encryption validation
kubectl create secret generic encryption-test --from-literal=key1=secret-value
kubectl create configmap encryption-test --from-literal=config-key=config-value
```

1f. Validate encryption using etcdctl:
```bash
# Check if data is encrypted in etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/encryption-test | strings | grep -E "(secret-value|k8s:enc:aescbc)"
```

### Task 2: Break 1 - Invalid Encryption Provider Configuration (12 minutes)
Introduce errors in the EncryptionConfiguration to break data encryption.

2a. Corrupt the encryption configuration with invalid provider:
```bash
cat <<EOF | sudo tee /etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - invalidprovider:
      keys:
      - name: key1
        secret: $(cat /tmp/encryption-key)
  - identity: {}
EOF
```

2b. Monitor API server failure after restart:
```bash
kubectl get nodes
kubectl create secret generic test-broken --from-literal=test=value
```

2c. Analyze encryption provider errors in API server logs:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -i "encryption\|provider\|invalid"
```

2d. Check kubelet logs for API server restart issues:
```bash
sudo journalctl -u kubelet --since "2 minutes ago" | grep -E "encryption|provider|apiserver"
```

2e. Validate the encryption configuration syntax:
```bash
# Check YAML syntax
sudo python3 -c "import yaml; yaml.safe_load(open('/etc/kubernetes/pki/encryption-config.yaml'))" 2>&1 || echo "YAML syntax error"

# Verify against Kubernetes schema
kubectl explain --api-version=apiserver.config.k8s.io/v1 EncryptionConfiguration
```

2f. Fix the encryption provider configuration:
```bash
cat <<EOF | sudo tee /etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(cat /tmp/encryption-key)
  - identity: {}
EOF

# Verify recovery
kubectl get nodes
kubectl create secret generic recovery-test --from-literal=test=recovered
```

### Task 3: Break 2 - Non-existent Encryption Key File (10 minutes)
Break encryption by pointing to a missing encryption key file.

3a. Modify encryption configuration to reference non-existent key file:
```bash
cat <<EOF | sudo tee /etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: missing-key-content
  - identity: {}
EOF
```

3b. Observe API server startup failure:
```bash
kubectl get componentstatuses
kubectl create configmap test-missing-key --from-literal=test=value
```

3c. Analyze encryption key validation errors:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | tail -20 | grep -E "encryption|key|base64|invalid"
```

3d. Test encryption key validation manually:
```bash
# Try to decode the invalid key
echo "missing-key-content" | base64 -d 2>&1 || echo "Invalid base64 encoding"

# Compare with valid key format
echo "Valid key length: $(cat /tmp/encryption-key | base64 -d | wc -c) bytes"
echo "Required for AES: 32 bytes"
```

3e. Check API server static pod status:
```bash
# Monitor pod restarts
sudo crictl ps -a | grep kube-apiserver | head -3

# Check kubelet attempts to restart
sudo journalctl -u kubelet --since "2 minutes ago" | grep -c "apiserver"
```

3f. Restore valid encryption key:
```bash
cat <<EOF | sudo tee /etc/kubernetes/pki/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(cat /tmp/encryption-key)
  - identity: {}
EOF

# Verify encryption works
kubectl create secret generic key-recovery-test --from-literal=recovered=true
```

### Task 4: Break 3 - Read-only Audit Log Path (12 minutes)
Configure audit logging with inaccessible log directory.

4a. Create audit policy and configure API server with read-only log path:
```bash
# Create audit policy
cat <<EOF | sudo tee /etc/kubernetes/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Metadata
  omitStages:
  - RequestReceived
EOF

# Create read-only directory for audit logs
sudo mkdir -p /var/log/audit-readonly
sudo chmod 444 /var/log/audit-readonly
```

4b. Add audit configuration to API server manifest:
```bash
sudo sed -i '/- kube-apiserver/a\    - --audit-log-path=/var/log/audit-readonly/audit.log\n    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml\n    - --audit-log-maxage=30\n    - --audit-log-maxbackup=3\n    - --audit-log-maxsize=100' /etc/kubernetes/manifests/kube-apiserver.yaml

# Add volume mounts for audit
sudo sed -i '/mountPath: \/etc\/kubernetes\/pki\/encryption-config.yaml/a\    - mountPath: /etc/kubernetes/audit-policy.yaml\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/audit-readonly\n      name: audit-log-dir' /etc/kubernetes/manifests/kube-apiserver.yaml

# Add volumes for audit
sudo sed -i '/name: encryption-config/a\  - hostPath:\n      path: /etc/kubernetes/audit-policy.yaml\n      type: File\n    name: audit-policy\n  - hostPath:\n      path: /var/log/audit-readonly\n      type: Directory\n    name: audit-log-dir' /etc/kubernetes/manifests/kube-apiserver.yaml
```

4c. Monitor API server failure due to audit log write permissions:
```bash
kubectl get nodes
sudo crictl ps | grep kube-apiserver
```

4d. Analyze audit log permission errors:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -E "audit|log|permission|denied|readonly"
```

4e. Check filesystem permissions and write access:
```bash
# Verify directory permissions
ls -ld /var/log/audit-readonly
sudo -u kube-apiserver touch /var/log/audit-readonly/test.log 2>&1 || echo "Write permission denied"

# Check if API server can write to alternate location
ls -ld /var/log/
```

4f. Fix audit log permissions and verify recovery:
```bash
# Fix directory permissions
sudo chmod 755 /var/log/audit-readonly

# Verify API server recovery
kubectl get componentstatuses

# Test audit logging
kubectl create secret generic audit-test --from-literal=audit=enabled
sleep 5
sudo ls -la /var/log/audit-readonly/
sudo grep "audit-test" /var/log/audit-readonly/audit.log
```

### Task 5: Break 4 - Invalid Admission Controllers (11 minutes)
Configure non-existent or misconfigured admission controllers.

5a. Add invalid admission controllers to API server configuration:
```bash
sudo sed -i '/- kube-apiserver/a\    - --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,PersistentVolumeClaimResize,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,RuntimeClass,ResourceQuota,InvalidAdmissionController,NonExistentController' /etc/kubernetes/manifests/kube-apiserver.yaml
```

5b. Monitor API server startup failure:
```bash
kubectl get nodes
kubectl create deployment admission-test --image=nginx:1.20
```

5c. Analyze admission controller errors:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -E "admission|controller|plugin|invalid|unknown"
```

5d. List available admission controllers:
```bash
# Check what admission controllers are available
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -A 20 -B 5 "admission.*plugin"
```

5e. Test admission controller functionality with valid configuration:
```bash
# Remove invalid admission controllers
sudo sed -i '/--enable-admission-plugins.*InvalidAdmissionController/c\    - --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,PersistentVolumeClaimResize,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,RuntimeClass,ResourceQuota' /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify recovery
kubectl get nodes
kubectl create deployment admission-fixed --image=nginx:1.20 --replicas=2
```

5f. Validate admission controller enforcement:
```bash
# Test ResourceQuota admission controller
kubectl create namespace quota-test
kubectl create quota test-quota --hard=pods=1 -n quota-test
kubectl create deployment quota-test --image=nginx:1.20 --replicas=3 -n quota-test

# Check quota enforcement
kubectl get pods -n quota-test
kubectl describe quota test-quota -n quota-test
```

### Task 6: Comprehensive Recovery and Validation (10 minutes)
Perform complete system validation and clean up test resources.

6a. Validate all encryption, audit, and admission functionality:
```bash
# Test encryption end-to-end
kubectl create secret generic final-encryption-test --from-literal=key=final-value
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/final-encryption-test | grep -E "k8s:enc:aescbc"
```

6b. Verify audit logging captures security events:
```bash
# Create events that should be audited
kubectl create secret generic audit-validation --from-literal=audit=working
kubectl delete secret audit-validation

# Check audit log entries
sudo grep "audit-validation" /var/log/audit-readonly/audit.log | tail -3
sudo grep -c "secrets" /var/log/audit-readonly/audit.log
```

6c. Test admission controller policy enforcement:
```bash
# Create deployment that should be allowed
kubectl create deployment controller-test --image=nginx:1.20

# Verify ResourceQuota enforcement still works
kubectl get deployment controller-test
kubectl describe quota test-quota -n quota-test
```

6d. Validate complete API server functionality:
```bash
# Test all major API operations
kubectl get all -A --chunk-size=100 | head -10
kubectl auth can-i create secrets
kubectl version --short
```

6e. Performance and stability validation:
```bash
# Check API server performance
time kubectl get pods -A > /dev/null
kubectl get events --sort-by=.metadata.creationTimestamp | tail -5

# Verify no ongoing restarts
sudo crictl ps | grep kube-apiserver
kubectl get pods -n kube-system | grep apiserver
```

6f. Clean up test resources:
```bash
# Remove test resources
kubectl delete secret encryption-test recovery-test key-recovery-test final-encryption-test 2>/dev/null
kubectl delete configmap encryption-test test-missing-key 2>/dev/null
kubectl delete deployment admission-test admission-fixed controller-test 2>/dev/null
kubectl delete namespace quota-test
```

## Verification Commands

### Task 1 Verification
```bash
# Verify encryption configuration
sudo test -f /etc/kubernetes/pki/encryption-config.yaml && echo "Encryption config exists"
sudo grep -q "encryption-provider-config" /etc/kubernetes/manifests/kube-apiserver.yaml && echo "API server configured for encryption"

# Verify encrypted data in etcd
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/encryption-test | grep -q "k8s:enc:aescbc"  # Should show encrypted data
```

### Task 2 Verification
```bash
# Verify break symptoms
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -c "invalidprovider\|unknown.*provider"  # Should show > 0 during break

# Verify recovery
kubectl get nodes | grep Ready  # Should show ready nodes after fix
kubectl create secret generic verify-recovery --from-literal=test=working  # Should succeed after fix
```

### Task 3 Verification
```bash
# Verify key validation errors
echo "missing-key-content" | base64 -d 2>&1 | grep -c "invalid\|illegal"  # Should show error during break

# Verify recovery
kubectl create configmap verify-key-fix --from-literal=test=fixed  # Should succeed after fix
kubectl get secret key-recovery-test -o jsonpath='{.data.recovered}'  # Should show base64 encoded 'true'
```

### Task 4 Verification
```bash
# Verify permission issues
ls -ld /var/log/audit-readonly | grep "r--r--r--"  # Should show read-only permissions during break
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -c "permission.*denied\|readonly"  # Should show > 0 during break

# Verify audit logging works
sudo test -f /var/log/audit-readonly/audit.log && echo "Audit log exists"
sudo grep -c "secrets" /var/log/audit-readonly/audit.log  # Should show > 0 after fix
```

### Task 5 Verification
```bash
# Verify admission controller errors
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -c "InvalidAdmissionController\|NonExistentController"  # Should show > 0 during break

# Verify quota enforcement
kubectl describe quota test-quota -n quota-test | grep "Used.*pods.*1"  # Should show quota enforcement working
kubectl get deployment admission-fixed -o jsonpath='{.status.readyReplicas}'  # Should equal 2 after fix
```

### Task 6 Verification
```bash
# Comprehensive validation
sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/final-encryption-test | grep -q "k8s:enc:aescbc"  # Should show encryption working
sudo grep -q "audit-validation" /var/log/audit-readonly/audit.log  # Should show audit logging working
kubectl auth can-i create secrets | grep "yes"  # Should show admission controllers allowing valid operations
```

## Expected Results
- **Initial Setup**: Working encryption at rest with secrets/configmaps encrypted in etcd
- **Break 1**: API server fails due to invalid encryption provider configuration
- **Break 2**: Startup failure due to invalid encryption key format
- **Break 3**: API server cannot start due to read-only audit log directory
- **Break 4**: Startup failure due to non-existent admission controllers
- **Recovery**: All storage, encryption, and admission control functionality restored
- **Final State**: Fully functional cluster with secure encrypted storage and comprehensive audit logging

## Key Learning Points
- **Encryption at Rest Management**: Master EncryptionConfiguration syntax, key management, and etcdctl validation commands
- **Storage and Audit Troubleshooting**: Understand file system permissions, log path configuration, and audit policy validation
- **Admission Controller Debugging**: Learn to identify invalid controllers, understand the admission chain, and troubleshoot policy enforcement
- **etcd Data Inspection**: Develop skills for validating encrypted data storage and troubleshooting encryption failures
- **Security Compliance**: Understand the relationship between encryption, auditing, and admission control for regulatory compliance

## Exam & Troubleshooting Tips
- **CKA Exam Strategy**: Encryption and admission controller questions are frequent; practice etcdctl commands and configuration validation
- **Common Error Patterns**: Memorize encryption provider names (aescbc, aesgcm, identity) and admission controller syntax for quick fixes
- **Troubleshooting Workflow**: Always check API server logs first for encryption/admission errors; these issues prevent startup entirely
- **Key Management**: Practice encryption key generation and base64 encoding/decoding for quick key troubleshooting
- **Audit Debugging**: Remember that audit logging failures often involve file permissions; check directory access before complex troubleshooting
- **Production Considerations**: Understand encryption key rotation, audit log retention policies, and admission controller security implications