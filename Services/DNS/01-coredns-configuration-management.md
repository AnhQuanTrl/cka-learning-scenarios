# CoreDNS Configuration and Management

## Scenario Overview
- **Time Limit**: 50 minutes
- **Difficulty**: Intermediate to Advanced
- **Environment**: k3s bare metal

## Objective
Master CoreDNS deployment architecture, ConfigMap customization, and upstream DNS forwarding to manage cluster DNS services effectively for enterprise-grade Kubernetes environments.

## Context
Your company is migrating from a traditional DNS infrastructure to Kubernetes-native DNS services. The network team requires custom DNS forwarding rules, performance optimization, and integration with existing corporate DNS servers. You need to configure CoreDNS to handle both internal cluster DNS and external domain resolution while maintaining high availability and performance.

## Prerequisites
- Running k3s cluster with admin access
- `kubectl` configured and working
- Understanding of DNS concepts and Kubernetes services
- Access to examine CoreDNS deployment and configuration

## Tasks

### Task 1: Examine CoreDNS Architecture and Deployment
**Time**: 8 minutes

Analyze the existing CoreDNS deployment to understand its architecture:
1. Examine the **CoreDNS deployment** in the **kube-system** namespace
2. Identify the **number of replicas**, **resource requests/limits**, and **deployment strategy**
3. Examine the **CoreDNS service** and its **endpoints**
4. Check the **CoreDNS ConfigMap** structure and current **Corefile** configuration
5. Verify which **DNS service name** is used for backward compatibility

Document the current CoreDNS configuration including plugin order and settings.

### Task 2: Configure Custom Upstream DNS Forwarding
**Time**: 15 minutes

Configure CoreDNS to use custom upstream DNS servers for external domain resolution:
1. **Backup** the existing CoreDNS ConfigMap to a file named **coredns-backup.yaml**
2. Modify the CoreDNS ConfigMap to forward all external DNS queries to **8.8.8.8** and **8.8.4.4**
3. Configure **specific domain forwarding**: forward **company.local** domain queries to **192.168.1.10**
4. Add **conditional forwarding**: forward **dev.local** domain to **10.0.0.5** and **prod.local** domain to **10.0.0.6**
5. **Restart** CoreDNS pods to apply the configuration changes

The Corefile should maintain existing Kubernetes service discovery while adding custom forwarding rules.

### Task 3: Implement CoreDNS Plugin Configuration
**Time**: 12 minutes

Enhance CoreDNS with additional plugins for better observability and performance:
1. Add **logging plugin** to log all DNS queries with timestamps
2. Configure **metrics plugin** on port **9153** for Prometheus monitoring
3. Add **ready plugin** with custom endpoint **/ready** for health checks
4. Configure **cache plugin** with **TTL of 60 seconds** for better performance
5. Add **reload plugin** for automatic configuration reloading
6. **Configure multiple cluster domains**: Update kubernetes plugin to serve both **cluster.local** and **cka.local** domains

Test each plugin configuration and verify functionality through appropriate endpoints. Verify that services resolve under both domain suffixes.

### Task 4: Create Custom DNS Records with Hosts Plugin
**Time**: 10 minutes

Configure custom DNS records for internal services using the hosts plugin:
1. Add **hosts plugin** configuration to the Corefile
2. Create custom DNS entries for:
   - **api.internal** pointing to **10.0.1.100**
   - **db.internal** pointing to **10.0.1.200** 
   - **cache.internal** pointing to **10.0.1.150**
3. Configure **wildcard entries** for **\*.dev.internal** pointing to **10.0.2.0/24** range
4. Set appropriate **TTL values** for custom records
5. **Reload** CoreDNS configuration and test custom DNS resolution

### Task 5: Scale and Optimize CoreDNS Performance
**Time**: 5 minutes

Optimize CoreDNS for production workloads:
1. **Scale** CoreDNS deployment to **3 replicas** for high availability
2. Configure **resource requests**: CPU **100m**, Memory **128Mi**
3. Configure **resource limits**: CPU **200m**, Memory **256Mi**
4. Add **pod anti-affinity** to distribute CoreDNS pods across different nodes
5. Configure **priorityClassName** for CoreDNS pods to ensure scheduling priority

Verify that all CoreDNS replicas are running and distributed properly across nodes.

## Verification Commands

### Task 1 Verification
```bash
# Examine CoreDNS deployment
kubectl get deployment coredns -n kube-system -o yaml
kubectl describe deployment coredns -n kube-system

# Check CoreDNS service and endpoints
kubectl get svc kube-dns -n kube-system -o yaml
kubectl get endpoints kube-dns -n kube-system

# Examine current ConfigMap
kubectl get configmap coredns -n kube-system -o yaml
kubectl describe configmap coredns -n kube-system

# Check DNS service name
kubectl get svc -n kube-system | grep dns
```
**Expected Output**: Deployment should show CoreDNS with default configuration. Service should be named **kube-dns** for compatibility. ConfigMap should contain the default Corefile with standard plugins.

### Task 2 Verification
```bash
# Verify backup was created
ls -la coredns-backup.yaml
cat coredns-backup.yaml

# Check updated ConfigMap
kubectl get configmap coredns -n kube-system -o yaml | grep -A 20 "forward"

# Test external DNS resolution
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup google.com
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup company.local
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup dev.local

# Verify CoreDNS pods restarted
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=20
```
**Expected Output**: External queries should resolve through 8.8.8.8/8.8.4.4. Custom domains should forward to specified servers. CoreDNS logs should show configuration reload.

### Task 3 Verification
```bash
# Check plugin configuration
kubectl get configmap coredns -n kube-system -o yaml | grep -E "(log|metrics|ready|cache|reload)"

# Test metrics endpoint
kubectl port-forward -n kube-system svc/kube-dns 9153:9153 &
curl http://localhost:9153/metrics | grep coredns
pkill kubectl

# Test ready endpoint
kubectl exec -n kube-system deployment/coredns -- wget -qO- http://localhost:8080/ready

# Verify cache is working
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- time nslookup kubernetes.default
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- time nslookup kubernetes.default

# Check logs for query logging
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=10 | grep -i "query"

# Test multiple cluster domain support
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup kubernetes.default.svc.cluster.local
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup kubernetes.default.svc.cka.local
```
**Expected Output**: Metrics should be accessible on port 9153. Ready endpoint should return success. Cached queries should be faster on second attempt. Logs should show DNS queries. Both cluster.local and cka.local domains should resolve to the same Kubernetes service.

### Task 4 Verification
```bash
# Check hosts plugin configuration
kubectl get configmap coredns -n kube-system -o yaml | grep -A 10 "hosts"

# Test custom DNS records
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup api.internal
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup db.internal
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup cache.internal

# Test wildcard entries
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup test.dev.internal
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- nslookup app.dev.internal

# Verify TTL settings
kubectl run dns-test --image=busybox:latest --restart=Never --rm -it -- dig api.internal
```
**Expected Output**: Custom records should resolve to specified IP addresses. Wildcard entries should resolve appropriately. TTL values should match configuration.

### Task 5 Verification
```bash
# Check scaled deployment
kubectl get deployment coredns -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

# Verify resource configuration
kubectl describe deployment coredns -n kube-system | grep -A 10 -B 5 "Limits\|Requests"

# Check anti-affinity configuration
kubectl get deployment coredns -n kube-system -o yaml | grep -A 10 affinity

# Verify priority class
kubectl describe pods -n kube-system -l k8s-app=kube-dns | grep -i priority

# Test DNS resolution from multiple pods
for i in {1..5}; do kubectl run dns-test-$i --image=busybox:latest --restart=Never --rm -it -- nslookup kubernetes.default; done
```
**Expected Output**: 3 CoreDNS replicas should be running on different nodes. Resource requests/limits should match configuration. Anti-affinity should distribute pods across nodes.

## Expected Results
- CoreDNS deployment analyzed and documented with current architecture
- Custom upstream DNS forwarding configured (8.8.8.8, 8.8.4.4, company.local → 192.168.1.10)
- Enhanced plugin configuration with logging, metrics, ready, cache, and reload plugins
- Custom DNS records created using hosts plugin (api.internal, db.internal, cache.internal)
- CoreDNS scaled to 3 replicas with optimized resource allocation and anti-affinity

## Task Solutions

### Task 1 Solution: Examine CoreDNS Architecture
```bash
# Step 1: Examine CoreDNS deployment
kubectl get deployment coredns -n kube-system -o yaml > coredns-deployment-analysis.yaml
kubectl describe deployment coredns -n kube-system

# Step 2: Check service and endpoints
kubectl get svc kube-dns -n kube-system -o yaml
kubectl get endpoints kube-dns -n kube-system

# Step 3: Examine ConfigMap
kubectl get configmap coredns -n kube-system -o yaml
```

### Task 2 Solution: Configure Custom Upstream DNS Forwarding
```bash
# Step 1: Backup existing ConfigMap
kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml

# Step 2: Create updated Corefile
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
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
        forward company.local 192.168.1.10
        forward dev.local 10.0.0.5
        forward prod.local 10.0.0.6
        forward . 8.8.8.8 8.8.4.4
        cache 30
        loop
        reload
        loadbalance
    }
EOF

# Step 3: Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system
```

### Task 3 Solution: Implement CoreDNS Plugin Configuration
```bash
# Update ConfigMap with enhanced plugins and multiple cluster domains
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        log
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local cka.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward company.local 192.168.1.10
        forward dev.local 10.0.0.5
        forward prod.local 10.0.0.6
        forward . 8.8.8.8 8.8.4.4
        cache 60
        loop
        reload
        loadbalance
    }
EOF

# Restart to apply changes
kubectl rollout restart deployment/coredns -n kube-system
```

### Task 4 Solution: Create Custom DNS Records with Hosts Plugin
```bash
# Add hosts plugin to Corefile
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        log
        errors
        health {
            lameduck 5s
        }
        ready
        hosts {
            10.0.1.100 api.internal
            10.0.1.200 db.internal
            10.0.1.150 cache.internal
            10.0.2.1 *.dev.internal
            ttl 300
            reload 10s
            fallthrough
        }
        kubernetes cluster.local cka.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward company.local 192.168.1.10
        forward dev.local 10.0.0.5
        forward prod.local 10.0.0.6
        forward . 8.8.8.8 8.8.4.4
        cache 60
        loop
        reload
        loadbalance
    }
EOF

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

### Task 5 Solution: Scale and Optimize CoreDNS Performance
```bash
# Step 1: Scale to 3 replicas
kubectl scale deployment coredns --replicas=3 -n kube-system

# Step 2: Patch deployment with resources and anti-affinity
kubectl patch deployment coredns -n kube-system --type merge -p='
{
  "spec": {
    "template": {
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "preferredDuringSchedulingIgnoredDuringExecution": [
              {
                "weight": 100,
                "podAffinityTerm": {
                  "labelSelector": {
                    "matchLabels": {
                      "k8s-app": "kube-dns"
                    }
                  },
                  "topologyKey": "kubernetes.io/hostname"
                }
              }
            ]
          }
        },
        "containers": [
          {
            "name": "coredns",
            "resources": {
              "requests": {
                "cpu": "100m",
                "memory": "128Mi"
              },
              "limits": {
                "cpu": "200m",
                "memory": "256Mi"
              }
            }
          }
        ]
      }
    }
  }
}'

# Step 3: Verify scaling and optimization
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
kubectl describe deployment coredns -n kube-system
```

## Key Learning Points
- CoreDNS is deployed as a standard Kubernetes Deployment in kube-system namespace
- Service remains named "kube-dns" for backward compatibility with existing clusters
- Corefile configuration follows plugin chain architecture with order significance
- Forward plugin enables integration with existing corporate DNS infrastructure
- Hosts plugin provides static DNS records without external DNS providers
- Cache plugin significantly improves DNS resolution performance
- Metrics and logging plugins essential for production observability
- Resource management and scaling critical for high-availability DNS services
- Kubernetes plugin supports multiple cluster domains (e.g., cluster.local and cka.local) for enhanced compatibility

## Exam & Troubleshooting Tips
- **CKA Exam**: Know how to modify CoreDNS ConfigMap and restart pods safely
- **Plugin Order**: Plugins execute in the order they appear in Corefile - order matters
- **Backup Strategy**: Always backup ConfigMap before making changes: `kubectl get cm coredns -n kube-system -o yaml > backup.yaml`
- **Safe Restart**: Use rolling restart: `kubectl rollout restart deployment/coredns -n kube-system`
- **Testing**: Use temporary pods for DNS testing: `kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup <domain>`
- **Common Error**: Forgetting to restart CoreDNS pods after ConfigMap changes
- **Troubleshooting**: Check CoreDNS logs: `kubectl logs -n kube-system -l k8s-app=kube-dns`
- **Performance**: Monitor DNS query metrics and cache hit rates for optimization
- **Debugging**: Use `dig` command for detailed DNS query analysis with TTL and response codes