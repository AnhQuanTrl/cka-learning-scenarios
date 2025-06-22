# Network Policy Fundamentals

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal with Calico CNI

## Objective
Master the creation and implementation of Kubernetes Network Policies to control ingress and egress traffic between pods and external services.

## Context
Your development team is migrating from a monolithic application to microservices architecture. The security team requires network-level isolation between different application tiers (frontend, backend, database) while maintaining necessary communication paths. You need to implement Network Policies that follow the principle of least privilege, starting with a default-deny posture and explicitly allowing only required traffic flows.

## Prerequisites
- Running k3s cluster with Calico CNI installed
- kubectl access with cluster-admin privileges
- Basic understanding of pod networking and service discovery

## Tasks

### Task 1: Deploy Multi-Tier Application Infrastructure
**Time**: 8 minutes

Create the foundational application infrastructure with three distinct tiers that will be secured with Network Policies.

1a. Create three namespaces for application tiers:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
  labels:
    tier: frontend
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend
  labels:
    tier: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: database
  labels:
    tier: database
```

1b. Deploy the frontend web application:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: frontend
  labels:
    app: web-app
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        tier: frontend
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "api-service.backend.svc.cluster.local:8080"
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: frontend
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: web-app
  type: ClusterIP
```

1c. Deploy the backend API service:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: backend
  labels:
    app: api-server
    tier: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
        tier: backend
    spec:
      containers:
      - name: api
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "db-service.database.svc.cluster.local"
        - name: DB_PORT
          value: "5432"
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: backend
spec:
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: api-server
  type: ClusterIP
```

1d. Deploy the database service:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
  namespace: database
  labels:
    app: postgres-db
    tier: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-db
  template:
    metadata:
      labels:
        app: postgres-db
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "appdb"
        - name: POSTGRES_USER
          value: "dbuser"
        - name: POSTGRES_PASSWORD
          value: "dbpass123"
---
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: database
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres-db
  type: ClusterIP
```

### Task 2: Test Initial Network Connectivity
**Time**: 5 minutes

Verify that all pods can communicate with each other before implementing Network Policies, establishing a baseline for comparison.

2a. Test frontend to backend connectivity by executing a command in a frontend pod to reach the backend service.

2b. Test backend to database connectivity by executing a command in a backend pod to reach the database service.

2c. Test external internet connectivity from each tier by executing curl commands to reach external services like `google.com`.

### Task 3: Implement Default Deny Network Policies
**Time**: 10 minutes

Create restrictive Network Policies that deny all traffic by default, following security best practices.

3a. Create a default deny ingress policy for the frontend namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

3b. Create a default deny all traffic policy for the backend namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

3c. Create a default deny ingress policy for the database namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### Task 4: Configure Selective Ingress Traffic Rules
**Time**: 12 minutes

Implement targeted ingress policies that allow specific traffic flows required for application functionality.

4a. Create a policy allowing frontend pods to receive HTTP traffic from any source:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-ingress
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: web-app
  policyTypes:
  - Ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
```

4b. Create a policy allowing backend pods to receive traffic only from frontend namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-from-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
```

4c. Create a policy allowing database pods to receive traffic only from backend pods using both namespace and pod selectors:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-from-backend
  namespace: database
spec:
  podSelector:
    matchLabels:
      app: postgres-db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
      podSelector:
        matchLabels:
          app: api-server
    ports:
    - protocol: TCP
      port: 5432
```

### Task 5: Configure Egress Traffic Rules
**Time**: 10 minutes

Implement egress policies for the backend namespace to control outbound traffic while allowing necessary external connectivity.

5a. Create an egress policy allowing backend pods to communicate with the database:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

5b. Create an egress policy allowing backend pods to perform DNS lookups:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-dns
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

5c. Create an egress policy allowing backend pods to access external services on specific ports:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-external
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

## Verification Commands

### Task 1 Verification
```bash
# Verify namespace creation
kubectl get namespaces -l tier

# Verify all deployments are running
kubectl get deployments -A -l tier
kubectl get pods -A -l tier

# Verify services are created
kubectl get services -A
```
**Expected Output**: All namespaces show `tier` labels, all deployments show `READY 2/2` (or `1/1` for database), all pods show `Running` status, and services are accessible.

### Task 2 Verification
```bash
# Test frontend to backend connectivity
kubectl exec -n frontend deployment/web-app -- curl -s --connect-timeout 5 api-service.backend.svc.cluster.local:8080

# Test backend to database connectivity
kubectl exec -n backend deployment/api-server -- nc -zv db-service.database.svc.cluster.local 5432

# Test external connectivity from backend
kubectl exec -n backend deployment/api-server -- curl -s --connect-timeout 5 -I google.com
```
**Expected Output**: Frontend receives HTTP response from backend, backend successfully connects to database port 5432, and external curl returns HTTP headers from google.com.

### Task 3 Verification
```bash
# Verify Network Policies are created
kubectl get networkpolicies -A

# Test that connectivity is now blocked
kubectl exec -n frontend deployment/web-app -- curl -s --connect-timeout 5 api-service.backend.svc.cluster.local:8080
kubectl exec -n backend deployment/api-server -- nc -zv db-service.database.svc.cluster.local 5432
```
**Expected Output**: Network Policies exist in each namespace. Connectivity tests should timeout or fail, demonstrating that default deny policies are enforcing traffic restrictions.

### Task 4 Verification
```bash
# Test frontend ingress (should work from any pod)
kubectl run test-pod --image=curlimages/curl --rm -it -- curl -s web-service.frontend.svc.cluster.local

# Test backend ingress from frontend (should work)
kubectl exec -n frontend deployment/web-app -- curl -s --connect-timeout 5 api-service.backend.svc.cluster.local:8080

# Test backend ingress from database (should fail)
kubectl exec -n database deployment/postgres-db -- nc -zv api-service.backend.svc.cluster.local 8080

# Test database ingress from backend (should work)
kubectl exec -n backend deployment/api-server -- nc -zv db-service.database.svc.cluster.local 5432
```
**Expected Output**: Frontend accessible from test pod, backend accessible from frontend, backend NOT accessible from database, database accessible from backend.

### Task 5 Verification
```bash
# Test backend to database connectivity (should work)
kubectl exec -n backend deployment/api-server -- nc -zv db-service.database.svc.cluster.local 5432

# Test DNS resolution from backend (should work)
kubectl exec -n backend deployment/api-server -- nslookup db-service.database.svc.cluster.local

# Test external HTTP/HTTPS access from backend (should work)
kubectl exec -n backend deployment/api-server -- curl -s --connect-timeout 5 -I httpbin.org/status/200

# Test blocked external ports from backend (should fail)
kubectl exec -n backend deployment/api-server -- nc -zv httpbin.org 22
```
**Expected Output**: Database connection succeeds, DNS resolution returns IP address, HTTP/HTTPS requests to external services succeed, SSH connection to external service fails.

## Expected Results

- **Three namespaces** (`frontend`, `backend`, `database`) with appropriate tier labels
- **Six deployments** running: web-app (2 replicas), api-server (2 replicas), postgres-db (1 replica)
- **Three services** providing internal cluster access to each application tier
- **Seven Network Policies** implementing defense-in-depth security:
  - 3 default deny policies (1 per namespace)
  - 3 selective ingress policies (frontend access, backend from frontend, database from backend)
  - 3 egress policies (backend to database, DNS access, external HTTP/HTTPS)
- **Verified traffic flows** showing allowed communication paths work and denied paths are blocked

## Key Learning Points

- **Network Policy Scope**: Policies are namespace-scoped and use label selectors to target specific pods
- **Traffic Direction Control**: Separate `Ingress` and `Egress` policy types control inbound and outbound traffic independently
- **Selector Logic**: `podSelector`, `namespaceSelector`, and combined selectors provide flexible targeting options
- **Default Deny Principle**: Empty `podSelector: {}` applies policies to all pods, creating secure defaults
- **Port Specification**: Network policies can control traffic at the protocol and port level for fine-grained access control
- **Policy Composition**: Multiple policies with different selectors can be combined to create complex traffic rules
- **DNS Considerations**: DNS lookup traffic (port 53 UDP/TCP) must be explicitly allowed in egress policies

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Start with Default Deny**: Always implement default deny policies first, then add specific allow rules
- **Label Strategy**: Use consistent labeling strategies across namespaces and pods for easier policy management
- **Test Incrementally**: Apply policies one at a time and test connectivity to identify which policy blocks desired traffic
- **Remember DNS**: Most egress policies need DNS access; include port 53 UDP/TCP rules

### Troubleshooting Tips
- **Policy Not Working**: Check that pods have labels matching the `podSelector` in the policy
- **Intermittent Connectivity**: Verify all pod replicas have consistent labels and that services have correct selectors
- **DNS Failures**: Ensure egress policies include DNS ports (53 UDP/TCP) for name resolution
- **External Access Issues**: Check that egress policies allow required external ports (80, 443, etc.)
- **Policy Conflicts**: Use `kubectl describe networkpolicy` to check policy details and rule precedence
- **CNI Compatibility**: Verify your CNI plugin (Calico, Cilium, etc.) supports Network Policy enforcement