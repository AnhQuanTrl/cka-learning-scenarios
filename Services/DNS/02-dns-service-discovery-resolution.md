# DNS Service Discovery and Resolution

## Scenario Overview
- **Time Limit**: 35 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master Kubernetes DNS service discovery patterns, naming conventions, and resolution mechanisms for effective cross-namespace and cross-cluster communication.

## Context
As a DevOps engineer at CloudScale Solutions, you're implementing a comprehensive microservices architecture spanning multiple namespaces. The development team needs clear guidelines on service discovery patterns, and the platform team requires robust DNS configuration for cross-namespace communication, headless services, and custom DNS policies. Your task is to demonstrate all DNS resolution patterns and establish best practices for the organization.

## Prerequisites
- Running k3s cluster with CoreDNS
- kubectl access with cluster-admin privileges
- Basic understanding of Kubernetes services and networking
- Familiarity with DNS concepts and nslookup/dig commands

## Tasks

### Task 1: Namespace and Service Infrastructure Setup
**Time**: 8 minutes

Create a multi-namespace environment with various service types to demonstrate DNS resolution patterns.

**Step 1a**: Create multiple namespaces for different environments:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
  labels:
    tier: web
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend
  labels:
    tier: api
---
apiVersion: v1
kind: Namespace
metadata:
  name: database
  labels:
    tier: data
```

**Step 1b**: Deploy a web application in the frontend namespace with both ClusterIP and headless services:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: frontend
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: web-headless
  namespace: frontend
spec:
  clusterIP: None
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

**Step 1c**: Deploy an API service in the backend namespace:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: httpd
        image: httpd:2.4
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"  
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: backend
spec:
  selector:
    app: api-server
  ports:
  - port: 8080
    targetPort: 80
  type: ClusterIP
```

**Step 1d**: Deploy a database service in the database namespace with both regular and headless services:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-db
  namespace: database
spec:
  serviceName: postgres-headless
  replicas: 2
  selector:
    matchLabels:
      app: postgres-db
  template:
    metadata:
      labels:
        app: postgres-db
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          value: "password123"
        - name: POSTGRES_DB
          value: "appdb"
        ports:
        - containerPort: 5432
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: database
spec:
  selector:
    app: postgres-db
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  namespace: database
spec:
  clusterIP: None
  selector:
    app: postgres-db
  ports:
  - port: 5432
    targetPort: 5432
```

### Task 2: DNS Naming Convention Analysis
**Time**: 8 minutes

Test and document the complete DNS naming conventions used in Kubernetes.

**Step 2a**: Create a debug pod with network tools in the default namespace:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-debug
  namespace: default
spec:
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 2b**: Test service resolution within the same namespace by creating a test pod in the frontend namespace:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-debug
  namespace: frontend
spec:
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 2c**: From the frontend-debug pod, test different DNS resolution patterns:
- Short name resolution: `web-service`
- Full service FQDN: `web-service.frontend.svc.cluster.local`
- Cross-namespace resolution: `api-service.backend.svc.cluster.local`
- Headless service resolution: `web-headless.frontend.svc.cluster.local`

Document the IP addresses returned by each resolution method.

**Step 2d**: From the default namespace dns-debug pod, test cross-namespace service discovery and document which naming patterns work and which fail.

### Task 3: Headless Services and Pod DNS Records
**Time**: 7 minutes

Explore how headless services create individual pod DNS records and their use cases.

**Step 3a**: From the dns-debug pod, resolve the headless services and compare with regular ClusterIP services:
- Query `web-headless.frontend.svc.cluster.local`
- Query `postgres-headless.database.svc.cluster.local`
- Compare with `web-service.frontend.svc.cluster.local`
- Compare with `postgres-service.database.svc.cluster.local`

**Step 3b**: Analyze individual pod DNS records for StatefulSet pods:
- Query `postgres-db-0.postgres-headless.database.svc.cluster.local`
- Query `postgres-db-1.postgres-headless.database.svc.cluster.local`
- Document the stable network identity provided by StatefulSet pod DNS records

**Step 3c**: Create a debug pod in the database namespace to test local resolution:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: database-debug
  namespace: database
spec:
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 3d**: From the database-debug pod, demonstrate direct pod communication using StatefulSet pod DNS names.

### Task 4: DNS Policies and Custom Configuration
**Time**: 7 minutes

Implement and test different DNS policies and custom DNS configurations.

**Step 4a**: Create a pod with **ClusterFirst** DNS policy (default behavior):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-clusterfirst
  namespace: default
spec:
  dnsPolicy: ClusterFirst
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 4b**: Create a pod with **Default** DNS policy (uses node's DNS configuration):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-default
  namespace: default
spec:
  dnsPolicy: Default
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 4c**: Create a pod with **None** DNS policy and custom DNS configuration:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-custom
  namespace: default
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers:
    - 10.43.0.10
    - 8.8.8.8
    searches:
    - default.svc.cluster.local
    - svc.cluster.local
    - cluster.local
    options:
    - name: ndots
      value: "2"
    - name: edns0
  containers:
  - name: debug
    image: busybox:1.35
    command: ['sleep', '3600']
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 4d**: Compare `/etc/resolv.conf` contents across all three DNS policy pods and document the differences.

### Task 5: Cross-Namespace Service Communication
**Time**: 5 minutes

Implement practical cross-namespace service communication patterns.

**Step 5a**: Create a multi-tier application configuration that demonstrates proper cross-namespace DNS usage:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: frontend
data:
  backend-url: "http://api-service.backend.svc.cluster.local:8080"
  database-url: "postgres://postgres-service.database.svc.cluster.local:5432/appdb"
  cache-endpoints: "redis-0.redis-headless.cache.svc.cluster.local:6379,redis-1.redis-headless.cache.svc.cluster.local:6379"
```

**Step 5b**: Deploy an application pod that uses the cross-namespace configuration:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-tier-app
  namespace: frontend
spec:
  containers:
  - name: app
    image: busybox:1.35
    command: ['sleep', '3600']
    env:
    - name: BACKEND_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: backend-url
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database-url
    resources:
      requests:
        memory: "32Mi"
        cpu: "25m"
      limits:
        memory: "64Mi"
        cpu: "50m"
```

**Step 5c**: From the multi-tier-app pod, test connectivity to services in other namespaces using the configured URLs.

## Verification Commands

### Task 1 Verification
```bash
# Verify all namespaces are created
kubectl get namespaces | grep -E "(frontend|backend|database)"

# Verify all deployments are running
kubectl get deployments -A | grep -E "(web-app|api-server|postgres-db)"

# Verify all services are created with correct types
kubectl get services -A -o wide | grep -E "(web-service|web-headless|api-service|postgres-service|postgres-headless)"

# Check pod readiness across all namespaces
kubectl get pods -A | grep -E "(web-app|api-server|postgres-db)"
```

**Expected Output**: All namespaces should exist, deployments should show READY status, services should have appropriate cluster IPs (or None for headless), and all pods should be Running.

### Task 2 Verification
```bash
# Test DNS resolution from frontend-debug pod
kubectl exec -n frontend frontend-debug -- nslookup web-service
kubectl exec -n frontend frontend-debug -- nslookup web-service.frontend.svc.cluster.local
kubectl exec -n frontend frontend-debug -- nslookup api-service.backend.svc.cluster.local

# Test DNS resolution from default namespace
kubectl exec dns-debug -- nslookup web-service.frontend.svc.cluster.local
kubectl exec dns-debug -- nslookup api-service.backend.svc.cluster.local

# Verify DNS search domains
kubectl exec -n frontend frontend-debug -- cat /etc/resolv.conf
```

**Expected Output**: Short names should resolve within the same namespace, FQDNs should resolve from any namespace, and /etc/resolv.conf should show appropriate search domains (namespace.svc.cluster.local, svc.cluster.local, cluster.local).

### Task 3 Verification
```bash
# Compare headless vs regular service resolution
kubectl exec dns-debug -- nslookup web-headless.frontend.svc.cluster.local
kubectl exec dns-debug -- nslookup web-service.frontend.svc.cluster.local

# Test StatefulSet pod DNS records
kubectl exec dns-debug -- nslookup postgres-db-0.postgres-headless.database.svc.cluster.local
kubectl exec dns-debug -- nslookup postgres-db-1.postgres-headless.database.svc.cluster.local

# Verify pod endpoints for headless services
kubectl get endpoints -n frontend web-headless -o yaml
kubectl get endpoints -n database postgres-headless -o yaml
```

**Expected Output**: Headless services should return multiple A records (one per pod), regular services should return single cluster IP, StatefulSet pods should have stable DNS names, and endpoints should show individual pod IPs.

### Task 4 Verification
```bash
# Compare resolv.conf across different DNS policies
kubectl exec dns-clusterfirst -- cat /etc/resolv.conf
kubectl exec dns-default -- cat /etc/resolv.conf  
kubectl exec dns-custom -- cat /etc/resolv.conf

# Test service resolution with different DNS policies
kubectl exec dns-clusterfirst -- nslookup web-service.frontend.svc.cluster.local
kubectl exec dns-default -- nslookup web-service.frontend.svc.cluster.local
kubectl exec dns-custom -- nslookup web-service.frontend.svc.cluster.local

# Verify custom DNS configuration is applied
kubectl describe pod dns-custom | grep -A 10 "DNS Config"
```

**Expected Output**: ClusterFirst should show Kubernetes DNS server, Default should show node DNS, None should show custom configuration, and service resolution should work appropriately based on policy.

### Task 5 Verification
```bash
# Verify ConfigMap cross-namespace URLs
kubectl get configmap -n frontend app-config -o yaml

# Test cross-namespace connectivity from multi-tier app
kubectl exec -n frontend multi-tier-app -- nslookup api-service.backend.svc.cluster.local
kubectl exec -n frontend multi-tier-app -- nslookup postgres-service.database.svc.cluster.local

# Verify environment variables are set correctly
kubectl exec -n frontend multi-tier-app -- env | grep -E "(BACKEND_URL|DATABASE_URL)"

# Test actual HTTP connectivity (if services are responding)
kubectl exec -n frontend multi-tier-app -- wget -qO- --timeout=5 api-service.backend.svc.cluster.local:8080 || echo "Service not responding (expected for demo)"
```

**Expected Output**: ConfigMap should contain proper FQDNs, DNS resolution should work for all cross-namespace services, environment variables should be populated correctly, and connectivity tests should demonstrate network reachability.

## Expected Results

After completing this scenario, you should have:

1. **Comprehensive DNS Infrastructure**: Multi-namespace environment with various service types demonstrating all DNS patterns
2. **DNS Naming Mastery**: Complete understanding of Kubernetes DNS naming conventions and FQDN construction
3. **Headless Service Expertise**: Knowledge of pod DNS records, StatefulSet DNS patterns, and direct pod communication
4. **DNS Policy Configuration**: Experience with different DNS policies and custom DNS configuration
5. **Cross-Namespace Communication**: Practical patterns for inter-service communication across namespace boundaries
6. **Service Discovery Best Practices**: Documentation and examples for organizational DNS standards

## Key Learning Points

- **DNS Naming Conventions**: Understanding the hierarchy: `<service>.<namespace>.svc.cluster.local`
- **Service Types and DNS**: How ClusterIP and headless services differ in DNS resolution behavior
- **Search Domain Behavior**: How Kubernetes configures DNS search domains for namespace-aware resolution
- **StatefulSet DNS Patterns**: Stable network identities for stateful applications using pod DNS records
- **DNS Policy Options**: When to use ClusterFirst, Default, ClusterFirstWithHostNet, and None policies
- **Cross-Namespace Communication**: Best practices for service discovery across namespace boundaries
- **Headless Services Use Cases**: When and why to use headless services for direct pod communication

## Exam & Troubleshooting Tips

**Real Exam Tips**:
- Know the complete DNS naming pattern: `<service>.<namespace>.svc.cluster.local`
- Understand that short names only resolve within the same namespace
- Remember that headless services (clusterIP: None) return pod IPs instead of service IPs
- Be familiar with common DNS policies: ClusterFirst (default), Default, None
- Know how to create and use custom DNS configurations with dnsConfig
- Understand StatefulSet pod DNS naming: `<pod-name>.<headless-service>.<namespace>.svc.cluster.local`

**Troubleshooting Tips**:
- **Service Not Resolving**: Check if using correct FQDN for cross-namespace resolution
- **DNS Resolution Fails**: Verify CoreDNS pods are running in kube-system namespace
- **Intermittent Resolution**: Check DNS policy and ensure appropriate search domains in /etc/resolv.conf
- **StatefulSet Pod Access**: Ensure using headless service name in StatefulSet pod DNS records
- **Custom DNS Issues**: Validate dnsConfig syntax and ensure nameservers are reachable
- **Cross-Namespace Communication**: Verify NetworkPolicy isn't blocking traffic between namespaces
- **DNS Cache Issues**: Some applications cache DNS, may need pod restart after DNS changes