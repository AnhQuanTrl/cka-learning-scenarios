# Advanced Network Isolation

## Scenario Overview
- **Time Limit**: 60 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal with Calico CNI

## Objective
Implement advanced NetworkPolicy patterns for multi-environment isolation, complex service-to-service communication control, and production-grade network security troubleshooting.

## Context
Your company operates a microservices-based e-commerce platform across development, staging, and production environments. The security team has mandated strict network isolation requirements: environments must be completely isolated from each other, only specific services can communicate externally, and all network access must follow the principle of least privilege. You need to implement sophisticated NetworkPolicies that handle complex scenarios while maintaining operational visibility for troubleshooting.

## Prerequisites
- Running k3s cluster with Calico CNI installed
- kubectl access with cluster-admin privileges
- Completion of Network Policy Fundamentals scenario
- Basic understanding of microservices architecture

## Tasks

### Task 1: Deploy Multi-Environment Microservices Infrastructure
**Time**: 15 minutes

Create a realistic microservices architecture deployed across three environments with identical service topologies.

1a. Create environment namespaces with appropriate labels:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: dev
    tier: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    tier: pre-production
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: prod
    tier: production
```

1b. Deploy the API Gateway service in each environment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: dev
  labels:
    app: api-gateway
    service: gateway
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
        service: gateway
        environment: dev
    spec:
      containers:
      - name: gateway
        image: nginx:1.25
        ports:
        - containerPort: 80
        env:
        - name: AUTH_SERVICE_URL
          value: "auth-service.dev.svc.cluster.local:8080"
        - name: PAYMENT_SERVICE_URL
          value: "payment-service.dev.svc.cluster.local:8081"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: dev
  labels:
    app: api-gateway
    service: gateway
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: api-gateway
  type: ClusterIP
```

1c. Deploy the Authentication service in each environment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: dev
  labels:
    app: auth-service
    service: auth
    environment: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        service: auth
        environment: dev
    spec:
      containers:
      - name: auth
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "auth-db.dev.svc.cluster.local"
        - name: EXTERNAL_AUTH_URL
          value: "https://auth0.com/api/v2"
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: dev
  labels:
    app: auth-service
    service: auth
spec:
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: auth-service
  type: ClusterIP
```

1d. Deploy the Payment service and Database in each environment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: dev
  labels:
    app: payment-service
    service: payment
    environment: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
        service: payment
        environment: dev
    spec:
      containers:
      - name: payment
        image: httpd:2.4
        ports:
        - containerPort: 80
        env:
        - name: STRIPE_API_URL
          value: "https://api.stripe.com/v1"
        - name: DB_HOST
          value: "payment-db.dev.svc.cluster.local"
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: dev
  labels:
    app: payment-service
    service: payment
spec:
  ports:
  - port: 8081
    targetPort: 80
  selector:
    app: payment-service
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-db
  namespace: dev
  labels:
    app: auth-db
    service: database
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth-db
  template:
    metadata:
      labels:
        app: auth-db
        service: database
        environment: dev
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "authdb"
        - name: POSTGRES_USER
          value: "authuser"
        - name: POSTGRES_PASSWORD
          value: "authpass123"
---
apiVersion: v1
kind: Service
metadata:
  name: auth-db
  namespace: dev
  labels:
    app: auth-db
    service: database
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: auth-db
  type: ClusterIP
```

1e. Replicate the same deployments and services in staging and prod namespaces, changing the namespace field and environment labels accordingly.

### Task 2: Implement Environment Isolation Policies
**Time**: 12 minutes

Create comprehensive NetworkPolicies that completely isolate environments from each other while maintaining necessary internal communication.

2a. Create a default deny-all policy for each environment that blocks both ingress and egress traffic to establish a secure baseline.

**Hint**: Apply the policy to all pods in each namespace using `podSelector: {}` with both `Ingress` and `Egress` policy types.

2b. Create environment-specific ingress policies that only allow communication from pods within the same environment.

**Hint**: Use `namespaceSelector` to match the environment label, allowing intra-environment communication while blocking cross-environment access.

2c. Create DNS egress policies for each environment to allow name resolution within the cluster.

**Hint**: Allow egress to any destination on ports 53 (UDP and TCP) for DNS lookups.

### Task 3: Configure Service-to-Service Communication Rules
**Time**: 15 minutes

Implement fine-grained NetworkPolicies that control communication between specific microservices based on business logic requirements.

3a. Create policies allowing the API Gateway to communicate with Auth and Payment services on their specific ports within the same environment.

**Hint**: Use `podSelector` with `matchLabels` to target specific services and specify exact ports in the egress rules.

3b. Create policies allowing Auth and Payment services to communicate with their respective databases on port 5432 within the same environment.

**Hint**: Target services by their `service` label and allow communication to pods with `service: database` label.

3c. Create policies that allow the API Gateway to receive traffic from external sources (simulating load balancer traffic).

**Hint**: Create an ingress policy for the API Gateway that allows traffic from any source on port 80.

### Task 4: Control External Service Access
**Time**: 10 minutes

Implement egress policies that allow specific services to access external APIs while blocking unauthorized external communication.

4a. Create an egress policy allowing the Auth service to access external authentication providers on HTTPS port 443.

**Hint**: Allow egress to any external destination (`to: []`) but restrict to specific ports for external API access.

4b. Create an egress policy allowing the Payment service to access external payment processors on HTTPS port 443.

**Hint**: Similar to auth policy, but applied to payment service pods only.

4c. Verify that other services (like databases) cannot access external services by attempting outbound connections.

**Hint**: Test from database pods to confirm external access is blocked due to the default deny-all policy.

### Task 5: Implement Network Policy Troubleshooting and Monitoring
**Time**: 8 minutes

Create policies and test scenarios that demonstrate NetworkPolicy debugging techniques and conflict resolution.

5a. Create a deliberately conflicting NetworkPolicy that causes connectivity issues between services.

**Hint**: Create a policy that contradicts existing rules, such as denying traffic that other policies should allow.

5b. Use kubectl commands and pod-based network testing to identify and resolve the policy conflicts.

**Hint**: Use `kubectl describe networkpolicy`, `kubectl exec` with `curl` and `nc` commands, and policy inspection to debug issues.

5c. Create a monitoring policy that allows a dedicated network monitoring tool to access metrics from all services.

**Hint**: Create a policy that allows pods with a specific label (like `role: monitoring`) to access other services on metrics ports.

## Verification Commands

### Task 1 Verification
```bash
# Verify all namespaces and environments
kubectl get namespaces -l tier

# Verify all deployments across environments
kubectl get deployments -A -l service
kubectl get pods -A -l service

# Verify services are created in each environment
kubectl get services -A
```
**Expected Output**: Three namespaces (dev, staging, prod) with tier labels, all deployments showing READY status, and services available in each environment.

### Task 2 Verification
```bash
# Verify NetworkPolicies are created
kubectl get networkpolicies -A

# Test cross-environment isolation (should fail)
kubectl exec -n dev deployment/api-gateway -- curl -s --connect-timeout 5 api-gateway.staging.svc.cluster.local
kubectl exec -n staging deployment/auth-service -- curl -s --connect-timeout 5 auth-service.prod.svc.cluster.local:8080

# Test intra-environment communication (should work)
kubectl exec -n dev deployment/api-gateway -- curl -s --connect-timeout 5 auth-service.dev.svc.cluster.local:8080
```
**Expected Output**: NetworkPolicies exist in all namespaces, cross-environment connections timeout or fail, intra-environment connections succeed.

### Task 3 Verification
```bash
# Test API Gateway to services communication within environment
kubectl exec -n dev deployment/api-gateway -- curl -s --connect-timeout 5 auth-service.dev.svc.cluster.local:8080
kubectl exec -n dev deployment/api-gateway -- curl -s --connect-timeout 5 payment-service.dev.svc.cluster.local:8081

# Test service to database communication
kubectl exec -n dev deployment/auth-service -- nc -zv auth-db.dev.svc.cluster.local 5432

# Test unauthorized service-to-service communication (should fail)
kubectl exec -n dev deployment/auth-service -- curl -s --connect-timeout 5 payment-service.dev.svc.cluster.local:8081
```
**Expected Output**: API Gateway successfully connects to both services, services connect to their databases, unauthorized service-to-service communication fails.

### Task 4 Verification
```bash
# Test external API access from Auth service (should work)
kubectl exec -n dev deployment/auth-service -- curl -s --connect-timeout 5 -I https://httpbin.org/status/200

# Test external API access from Payment service (should work)
kubectl exec -n dev deployment/payment-service -- curl -s --connect-timeout 5 -I https://api.github.com

# Test blocked external access from database (should fail)
kubectl exec -n dev deployment/auth-db -- curl -s --connect-timeout 5 -I https://google.com

# Test DNS resolution works from all services
kubectl exec -n dev deployment/auth-service -- nslookup auth-db.dev.svc.cluster.local
```
**Expected Output**: Auth and Payment services can access external HTTPS services, database cannot access external services, DNS resolution works for all services.

### Task 5 Verification
```bash
# Inspect NetworkPolicy details for troubleshooting
kubectl describe networkpolicy -n dev

# Test connectivity after resolving conflicts
kubectl exec -n dev deployment/api-gateway -- curl -s --connect-timeout 5 auth-service.dev.svc.cluster.local:8080

# Verify monitoring access (if implemented)
kubectl run monitoring-pod --image=curlimages/curl --labels="role=monitoring" --rm -it -- curl -s api-gateway.dev.svc.cluster.local/metrics
```
**Expected Output**: NetworkPolicy descriptions show rule details, connectivity works after conflict resolution, monitoring pod can access metrics endpoints.

## Expected Results

- **Three isolated environments** (dev, staging, prod) with complete network separation
- **Twelve deployments** running across environments: 4 services × 3 environments each
- **Comprehensive NetworkPolicies** implementing:
  - Default deny-all policies for each environment
  - Environment isolation rules
  - Service-to-service communication controls
  - External access policies for specific services
  - DNS resolution policies
- **Verified network flows** showing allowed intra-environment communication and blocked cross-environment access
- **Working external API access** from Auth and Payment services only
- **Demonstrated troubleshooting techniques** for NetworkPolicy debugging

## Key Learning Points

- **Environment Isolation**: Complete network separation between development environments using namespace-based policies
- **Complex Selector Logic**: Combining `namespaceSelector`, `podSelector`, and port specifications for precise traffic control
- **Service Communication Patterns**: Implementing microservices communication rules that reflect real-world business logic
- **External Access Control**: Selective external API access while maintaining security boundaries
- **Policy Composition**: Managing multiple NetworkPolicies that work together without conflicts
- **Troubleshooting Techniques**: Using kubectl commands and network testing tools to debug policy issues
- **Production Patterns**: Real-world NetworkPolicy patterns for multi-environment deployments

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Label Strategy**: Use consistent labeling across environments and services for easier policy management
- **Policy Testing**: Always test policies incrementally, verifying each rule works before adding complexity
- **Documentation**: Keep track of policy purposes and dependencies for easier troubleshooting
- **Namespace Scope**: Remember that NetworkPolicies are namespace-scoped; cross-namespace rules require careful selector design

### Troubleshooting Tips
- **Policy Conflicts**: Use `kubectl describe networkpolicy` to identify overlapping or conflicting rules
- **Selector Debugging**: Verify pod labels match policy selectors using `kubectl get pods --show-labels`
- **Network Testing**: Use `curl`, `nc` (netcat), and `nslookup` from within pods to test connectivity
- **Policy Priority**: NetworkPolicies are additive; multiple policies affecting the same pod combine their rules
- **CNI Limitations**: Ensure your CNI plugin supports all NetworkPolicy features you're using
- **Log Analysis**: Check CNI and kube-proxy logs for NetworkPolicy enforcement errors
- **External Access**: Remember that egress policies with `to: []` allow access to any external destination on specified ports