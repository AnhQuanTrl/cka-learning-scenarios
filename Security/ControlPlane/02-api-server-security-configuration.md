# API Server Security Configuration

## Scenario Overview
- **Time Limit**: 50 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Configure comprehensive API server security settings including authentication, authorization, admission controllers, and audit logging to meet enterprise security requirements.

## Context
SecureOps Corporation is preparing for a comprehensive security audit of their Kubernetes infrastructure. The security team has identified several API server hardening requirements: multi-layered authentication, comprehensive audit logging for compliance, restrictive admission controllers, and enhanced TLS security. As the platform security engineer, you need to implement these security configurations while maintaining cluster functionality and performance.

## Prerequisites
- Killercoda Ubuntu Playground environment
- Understanding of Kubernetes API server architecture
- Familiarity with kubeadm, kubectl, and systemctl commands
- Knowledge of TLS, authentication, and authorization concepts

## Tasks

### Task 1: Cluster Initialization and Security Baseline Assessment
**Time: 8 minutes**

Initialize a kubeadm cluster and assess the current API server security configuration.

1. **Initialize kubeadm cluster**:
   - Install Docker, kubeadm, kubelet, and kubectl
   - Initialize cluster with kubeadm using secure pod network CIDR
   - Configure kubectl access and install CNI plugin

2. **Examine current API server configuration**:
   - Inspect `/etc/kubernetes/manifests/kube-apiserver.yaml`
   - Document current authentication and authorization methods
   - Check enabled admission controllers and security parameters

3. **Create baseline test resources**:
   - Create namespace **security-test** for testing configurations
   - Create ServiceAccount **test-sa** in the security-test namespace
   - Create a simple pod **baseline-pod** to test initial access patterns

**Hint**: Use `kubeadm init --pod-network-cidr=10.244.0.0/16` and save all current configuration for comparison.

### Task 2: Enhanced Authentication Configuration
**Time: 10 minutes**

Configure multiple authentication methods and secure authentication parameters.

1. **Configure authentication methods**:
   - Ensure certificate-based authentication is properly configured
   - Configure service account token authentication with secure parameters
   - Add authentication webhook configuration preparation (simulate OIDC setup)

2. **Secure authentication parameters**:
   - Set **--service-account-signing-key-file** and **--service-account-issuer**
   - Configure **--service-account-extend-token-expiration=false**
   - Set **--service-account-max-token-expiration=1h**

3. **Disable insecure authentication**:
   - Ensure **--insecure-port=0** (disabled insecure port)
   - Verify **--anonymous-auth=false** for anonymous access restriction
   - Configure **--basic-auth-file** is not present (disabled basic auth)

4. **Test authentication methods**:
   - Create a certificate-based user **secure-user**
   - Generate certificate signing request and approve it
   - Configure kubeconfig for the new user and test access

**Hint**: Use `kubeadm alpha certs certificate-key` to understand certificate management.

### Task 3: Authorization Hardening with RBAC
**Time: 8 minutes**

Configure and verify comprehensive RBAC authorization with minimal privilege principles.

1. **Verify and configure authorization modes**:
   - Ensure **--authorization-mode=Node,RBAC** is configured
   - Remove any **AlwaysAllow** modes if present
   - Configure **--authorization-webhook-config-file** preparation

2. **Implement restrictive RBAC policies**:
   - Create ClusterRole **security-auditor** with read-only access to security-related resources
   - Create ClusterRole **namespace-admin** with full access only to specific namespaces
   - Create Role **pod-manager** in security-test namespace with pod management permissions

3. **Test authorization policies**:
   - Bind **secure-user** to **security-auditor** ClusterRole
   - Test access permissions with `kubectl auth can-i` commands
   - Verify least-privilege access patterns are working

4. **Configure system account restrictions**:
   - Review system:masters group memberships
   - Ensure proper RBAC for system components
   - Validate default service account has minimal permissions

**Hint**: Use `kubectl auth can-i --list --as=secure-user` to test user permissions comprehensively.

### Task 4: Admission Controller Security Configuration
**Time: 10 minutes**

Configure security-focused admission controllers for policy enforcement.

1. **Enable core security admission controllers**:
   - Configure **--enable-admission-plugins** to include:
     - **NodeRestriction** (restrict kubelet permissions)
     - **PodSecurity** (Pod Security Standards enforcement)
     - **ServiceAccount** (automatic service account injection)
     - **ResourceQuota** (resource limit enforcement)

2. **Configure Pod Security Standards admission**:
   - Set default pod security policies for different namespace patterns
   - Configure **--admission-control-config-file** with Pod Security configuration
   - Create pod security configuration file with baseline and restricted profiles

3. **Test admission controller enforcement**:
   - Attempt to create privileged pods (should be restricted)
   - Test resource quota enforcement with over-limit resources
   - Verify service account token auto-mounting behavior

4. **Configure additional security controllers**:
   - Enable **LimitRanger** for default resource limits
   - Configure **NetworkPolicy** admission if network policies are required
   - Set up **ValidatingAdmissionWebhook** preparation for custom policies

**Hint**: Create `/etc/kubernetes/admission-config.yaml` for admission controller configuration.

### Task 5: Comprehensive Audit Logging Configuration
**Time: 8 minutes**

Implement comprehensive audit logging for security monitoring and compliance.

1. **Create audit policy file**:
   - Create `/etc/kubernetes/audit-policy.yaml` with comprehensive logging rules
   - Configure different audit levels: **None**, **Metadata**, **Request**, **RequestResponse**
   - Include rules for secrets, configmaps, RBAC resources, and authentication events

2. **Configure audit logging parameters**:
   - Set **--audit-log-path=/var/log/audit.log**
   - Configure **--audit-log-maxage=30**, **--audit-log-maxbackup=10**, **--audit-log-maxsize=100**
   - Enable **--audit-policy-file=/etc/kubernetes/audit-policy.yaml**

3. **Configure audit webhook** (simulate external logging):
   - Prepare audit webhook configuration file
   - Set **--audit-webhook-config-file** parameter
   - Configure audit webhook batch settings for performance

4. **Test and verify audit logging**:
   - Perform various operations (create pods, secrets, RBAC changes)
   - Examine audit log entries for completeness
   - Verify sensitive data is properly redacted in logs

**Hint**: Use `jq` to parse and analyze JSON audit log entries effectively.

### Task 6: TLS and Network Security Hardening
**Time: 6 minutes**

Configure advanced TLS settings and network security parameters.

1. **Configure TLS security**:
   - Set **--tls-min-version=VersionTLS12** for minimum TLS version
   - Configure **--tls-cipher-suites** with secure cipher suites only
   - Verify certificate-related parameters are properly configured

2. **Configure API server network security**:
   - Set **--request-timeout=60s** for request timeout limits
   - Configure **--max-requests-inflight=400** and **--max-mutating-requests-inflight=200**
   - Set **--profiling=false** to disable profiling endpoints

3. **Configure etcd security settings**:
   - Verify **--etcd-cafile**, **--etcd-certfile**, **--etcd-keyfile** are properly configured
   - Ensure **--etcd-servers** uses HTTPS endpoints only
   - Configure **--encryption-provider-config** reference (from previous scenario)

4. **Test security configuration**:
   - Verify API server starts successfully with all security parameters
   - Test TLS connection security using openssl s_client
   - Validate request rate limiting and timeout behavior

**Hint**: Use `openssl s_client -connect localhost:6443 -showcerts` to verify TLS configuration.

## Verification Commands

### Task 1 Verification:
```bash
# Verify cluster initialization
kubectl get nodes

# Check current API server configuration
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -E "(authentication|authorization|admission)"

# Verify baseline resources
kubectl get namespace security-test
kubectl get serviceaccount test-sa -n security-test
```

### Task 2 Verification:
```bash
# Check authentication configuration
grep -E "(service-account|anonymous|insecure)" /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify certificate-based user creation
kubectl get csr

# Test authentication
kubectl auth can-i get pods --as=secure-user
```

**Expected Output**: Authentication parameters should show secure configurations, CSR should be approved, and user should have appropriate access.

### Task 3 Verification:
```bash
# Verify authorization mode
grep "authorization-mode" /etc/kubernetes/manifests/kube-apiserver.yaml

# Test user permissions
kubectl auth can-i --list --as=secure-user

# Check RBAC configurations
kubectl get clusterroles security-auditor namespace-admin
kubectl get role pod-manager -n security-test
```

**Expected Output**: Authorization mode should be `Node,RBAC`, user should have limited permissions matching the security-auditor role.

### Task 4 Verification:
```bash
# Check enabled admission plugins
grep "enable-admission-plugins" /etc/kubernetes/manifests/kube-apiserver.yaml

# Test admission controller enforcement
kubectl create namespace test-privileged
kubectl label namespace test-privileged pod-security.kubernetes.io/enforce=restricted

# Attempt privileged pod creation (should fail)
kubectl run privileged-test --image=nginx --privileged=true -n test-privileged
```

**Expected Output**: Admission plugins should include security controllers, privileged pod creation should be blocked.

### Task 5 Verification:
```bash
# Verify audit configuration
grep -E "(audit-log|audit-policy)" /etc/kubernetes/manifests/kube-apiserver.yaml

# Check audit log exists and has entries
ls -la /var/log/audit.log
tail -5 /var/log/audit.log | jq .

# Test audit logging by creating a secret
kubectl create secret generic test-secret --from-literal=key=value -n security-test
grep "test-secret" /var/log/audit.log
```

**Expected Output**: Audit parameters should be configured, log file should exist and contain JSON entries for operations.

### Task 6 Verification:
```bash
# Check TLS and security parameters
grep -E "(tls-min-version|tls-cipher-suites|request-timeout|profiling)" /etc/kubernetes/manifests/kube-apiserver.yaml

# Test TLS connection
echo | openssl s_client -connect localhost:6443 2>&1 | grep -E "(Protocol|Cipher)"

# Verify API server is running with new configuration
kubectl get pods -n kube-system | grep kube-apiserver
```

**Expected Output**: TLS version should be 1.2+, secure ciphers should be used, API server pod should be running.

## Expected Results

After completing all tasks, you should have:

1. **Hardened kubeadm cluster** with comprehensive API server security configuration
2. **Multi-layered authentication** with certificate-based and service account authentication
3. **Restrictive RBAC authorization** with least-privilege access patterns
4. **Security-focused admission controllers** enforcing pod security and resource policies
5. **Comprehensive audit logging** capturing security-relevant events for compliance
6. **TLS and network security hardening** with secure protocols and rate limiting

## Key Learning Points

- **API server security** requires multi-layered approach covering authentication, authorization, and admission control
- **Authentication hardening** involves disabling insecure methods and configuring secure token parameters
- **RBAC authorization** provides fine-grained access control with least-privilege principles
- **Admission controllers** enforce security policies at resource creation time
- **Audit logging** is essential for security monitoring and compliance requirements
- **TLS configuration** and network security prevent protocol-level attacks and abuse

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **Practice API server configuration** modification and restart procedures
- **Memorize key security parameters** for authentication, authorization, and admission control
- **Know audit policy syntax** and common logging requirements for compliance
- **Understand admission controller order** and interaction between different controllers
- **Be familiar with troubleshooting** API server startup failures due to security misconfigurations

### Troubleshooting Tips:
- **API server won't start**: Check configuration file syntax and certificate paths
- **Authentication failures**: Verify certificate validity and authentication method configuration
- **Authorization denials**: Review RBAC policies and use `kubectl auth can-i` for testing
- **Admission controller issues**: Check controller configuration and policy files
- **Audit logging problems**: Verify file permissions and disk space for audit logs
- **Performance degradation**: Review rate limiting settings and audit policy complexity
- **Certificate errors**: Validate certificate expiration and CA chain configuration