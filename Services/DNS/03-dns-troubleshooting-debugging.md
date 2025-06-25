# DNS Troubleshooting and Debugging

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal cluster with intentionally broken DNS configurations

## Objective
Master systematic DNS troubleshooting techniques to diagnose and resolve common DNS resolution failures in Kubernetes clusters.

## Context
As a Kubernetes administrator, you've received reports that applications are experiencing intermittent DNS resolution failures. Services can't resolve each other, external domains are unreachable, and pod startup is failing due to DNS issues. You need to systematically diagnose and repair the DNS infrastructure to restore normal cluster operations.

## Prerequisites
- Running k3s cluster with kubectl access
- Basic understanding of Kubernetes DNS concepts
- Familiarity with network troubleshooting tools (nslookup, dig)

## Tasks

### Task 1: Create Broken DNS Environment (10 minutes)
Create a multi-tier application environment with intentionally broken DNS configurations to practice troubleshooting.

Create the **frontend** deployment that depends on DNS resolution:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_SERVICE
          value: "backend.default.svc.cluster.local"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: default
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create the **backend** deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: httpd:2.4
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: default
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create a **DNS test pod** with networking tools:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-test-pod
  namespace: default
spec:
  containers:
  - name: dns-tools
    image: busybox:1.35
    command: ['sleep', '3600']
  restartPolicy: Always
```

Now **break the DNS configuration** by modifying the CoreDNS ConfigMap:
```bash
# Save the original CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# Create a broken CoreDNS configuration
kubectl patch configmap coredns -n kube-system --patch='
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . 8.8.8.999 1.1.1.999
        cache 30
        loop
        reload
        loadbalance
    }
'
```

### Task 2: DNS Resolution Testing and Initial Diagnosis (8 minutes)
Perform initial DNS resolution tests to identify the scope of DNS issues.

Test **internal service DNS resolution** from the DNS test pod:
- Query the backend service using its short name
- Query the backend service using its fully qualified domain name (FQDN)
- Query the frontend service from the backend namespace

Test **external DNS resolution** from the DNS test pod:
- Query external domains like **google.com** and **kubernetes.io**
- Test with different DNS record types (A, AAAA, MX)

Document which DNS queries are failing and which are succeeding to establish a pattern.

### Task 3: CoreDNS Pod Status and Health Analysis (8 minutes)
Examine CoreDNS pod health and identify infrastructure-level DNS issues.

Analyze **CoreDNS pod status**:
- Check if CoreDNS pods are running and ready
- Examine pod resource usage (CPU, memory)
- Review pod restart count and recent restart reasons

Inspect **CoreDNS service configuration**:
- Verify the kube-dns service exists and has proper endpoints
- Check that the service IP matches the cluster DNS configuration
- Validate that the service ports are correctly configured

Examine **CoreDNS logs** for error patterns:
- Look for upstream DNS server connection failures
- Identify configuration parsing errors
- Find DNS query timeout and retry patterns

### Task 4: DNS Configuration Validation (8 minutes)
Validate DNS configuration at both the cluster and pod levels.

Examine **cluster DNS settings**:
- Check kubelet configuration for cluster DNS IP and domain
- Verify that the cluster DNS IP is reachable from worker nodes
- Validate DNS search domain configuration

Inspect **pod DNS configuration**:
- Examine `/etc/resolv.conf` inside the DNS test pod
- Check DNS policy settings on pods
- Verify nameserver IP addresses and search domains

Review **CoreDNS ConfigMap** (Corefile):
- Validate Corefile syntax and plugin configuration
- Check upstream DNS server addresses for reachability
- Verify kubernetes plugin configuration for cluster domain

### Task 5: DNS Resolution Repair and Validation (8 minutes)
Repair the identified DNS issues and validate that resolution is working correctly.

**Restore functional CoreDNS configuration**:
- Fix the upstream DNS server addresses in the Corefile
- Restart CoreDNS pods to apply the configuration changes
- Monitor CoreDNS pod logs during startup for configuration errors

**Validate DNS resolution after repair**:
- Test internal service resolution using short names and FQDNs
- Verify external domain resolution is working
- Confirm that new pods receive correct DNS configuration

**Test application connectivity**:
- Verify that the frontend can resolve the backend service
- Test cross-namespace service resolution
- Validate that DNS caching is working correctly

### Task 6: Advanced DNS Troubleshooting Scenarios (3 minutes)
Address advanced DNS issues including loops and performance problems.

**DNS loop detection and resolution**:
- Identify if DNS loops are present in the configuration
- Use CoreDNS logs to detect loop conditions
- Configure loop detection and prevention mechanisms

**Search domain limit issues**:
- Test DNS resolution with long service names that exceed search domain limits
- Validate behavior when search domain count exceeds system limits
- Configure appropriate search domain strategies

## Verification Commands

### Task 1 Verification
```bash
# Verify deployments are created and running
kubectl get deployments frontend backend
kubectl get services frontend backend

# Verify DNS test pod is running
kubectl get pod dns-test-pod

# Verify CoreDNS configuration is modified
kubectl get configmap coredns -n kube-system -o yaml | grep "8.8.8.999"

# Check that DNS resolution is broken
kubectl exec dns-test-pod -- nslookup backend
```
**Expected Output**: Deployments should show READY status, services should exist, DNS test pod should be Running, and nslookup should fail or timeout.

### Task 2 Verification
```bash
# Test internal DNS resolution
kubectl exec dns-test-pod -- nslookup backend
kubectl exec dns-test-pod -- nslookup backend.default.svc.cluster.local
kubectl exec dns-test-pod -- nslookup frontend

# Test external DNS resolution
kubectl exec dns-test-pod -- nslookup google.com
kubectl exec dns-test-pod -- nslookup kubernetes.io
```
**Expected Output**: Internal DNS queries should fail with "server can't find" errors, external DNS queries should timeout or fail due to invalid upstream servers.

### Task 3 Verification
```bash
# Check CoreDNS pod status
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl describe pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS service
kubectl get service kube-dns -n kube-system
kubectl get endpoints kube-dns -n kube-system

# Examine CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
```
**Expected Output**: CoreDNS pods should be Running, service should have valid endpoints, logs should show DNS forwarding errors and "no servers succeed" messages.

### Task 4 Verification
```bash
# Check pod DNS configuration
kubectl exec dns-test-pod -- cat /etc/resolv.conf

# Check cluster DNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Verify kubelet DNS settings (on node)
sudo cat /var/lib/rancher/k3s/agent/etc/containerd/config.toml | grep dns
```
**Expected Output**: resolv.conf should show cluster DNS IP (typically 10.43.0.10), nameservers should match cluster DNS service IP, CoreDNS config should show invalid upstream servers.

### Task 5 Verification
```bash
# Restore CoreDNS configuration
kubectl apply -f coredns-backup.yaml

# Restart CoreDNS pods
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system

# Test DNS resolution after repair
kubectl exec dns-test-pod -- nslookup backend
kubectl exec dns-test-pod -- nslookup google.com

# Verify CoreDNS logs show successful resolution
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=20
```
**Expected Output**: DNS queries should succeed with proper IP addresses returned, CoreDNS logs should show successful upstream queries without errors.

### Task 6 Verification
```bash
# Check for DNS loops in CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns | grep -i loop

# Test search domain behavior
kubectl exec dns-test-pod -- nslookup backend.default.svc.cluster.local.extra.long.domain

# Verify DNS cache is working
kubectl exec dns-test-pod -- time nslookup google.com
kubectl exec dns-test-pod -- time nslookup google.com
```
**Expected Output**: No loop messages in logs, search domain queries handle gracefully, repeated DNS queries should show faster response times due to caching.

## Expected Results
- CoreDNS pods running and healthy with functional configuration
- Internal service DNS resolution working for both short names and FQDNs
- External domain DNS resolution functional with valid upstream servers
- Pod DNS configuration properly inherited from cluster settings
- DNS caching and performance optimized
- All application pods able to resolve service dependencies

## Key Learning Points
- **Systematic DNS troubleshooting methodology**: Start with pod connectivity, then service resolution, then external queries
- **CoreDNS configuration management**: Understanding Corefile syntax and plugin interactions
- **DNS resolution hierarchy**: Pod DNS policy → kubelet DNS settings → CoreDNS configuration → upstream servers
- **Common DNS failure patterns**: Invalid upstream servers, configuration syntax errors, resource constraints
- **DNS testing tools**: nslookup, dig, and kubectl networking commands for diagnosis
- **DNS performance optimization**: Caching configuration, upstream server selection, and loop prevention

## Exam & Troubleshooting Tips
- **CKA Exam Approach**: DNS troubleshooting typically appears as "services can't reach each other" - always check DNS first
- **Efficient Diagnosis**: Use `kubectl exec pod -- nslookup service` as the fastest DNS test method
- **CoreDNS Logs**: Most DNS issues show clear error messages in CoreDNS pod logs - check these first
- **Configuration Backup**: Always backup working configurations before making changes (`kubectl get cm coredns -n kube-system -o yaml > backup.yaml`)
- **Common Issues**: 
  - Invalid upstream DNS servers (check internet connectivity)
  - Incorrect cluster domain in kubelet config
  - CoreDNS ConfigMap syntax errors
  - DNS policy conflicts in pod specifications
  - systemd-resolved conflicts on Ubuntu nodes (disable with `systemctl disable systemd-resolved`)
- **Performance Issues**: Check CoreDNS resource limits, increase cache TTL, and optimize upstream server selection
- **Emergency Recovery**: Keep a known-good CoreDNS configuration for quick restoration during outages