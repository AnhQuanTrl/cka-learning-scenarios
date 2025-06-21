# RBAC Advanced Patterns

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Implement production-grade RBAC patterns using aggregated ClusterRoles and demonstrate real-world permission validation through actual workload deployment and management.

## Context
Your organization is scaling its Kubernetes operations and needs a robust, maintainable RBAC system. The security team has mandated a tiered permission structure that can evolve without constant manual updates. You need to implement:

1. **`ops-lead`**: Senior operators who need comprehensive read-only access across all namespaces, including sensitive resources like secrets for troubleshooting production issues.
2. **`app-developer`**: Application developers who need to deploy and manage their applications but should be restricted from accessing infrastructure resources or secrets.

You'll use aggregated ClusterRoles to create a modular, scalable permission system that demonstrates production patterns including namespace isolation, workload-based validation, and automated role composition.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with administrative access.

## Tasks

### Task 1: Create Test Environment and Base Resources
*Suggested Time: 8 minutes*

Create the testing environment and understand the foundation for aggregated ClusterRoles by examining Kubernetes' built-in roles.

1. **Create test namespaces** for validating permissions:
   ```bash
   kubectl create namespace development
   kubectl create namespace staging
   kubectl create namespace production
   ```

2. **Examine the built-in `view` ClusterRole** to understand what permissions it provides:
   ```bash
   kubectl describe clusterrole view
   ```
   **Expected Output**: You should see extensive read-only permissions for most Kubernetes resources, but notably **no** access to secrets.

3. **Create a focused ClusterRole** for secret access that will be aggregated later. Create a file named `secret-viewer-clusterrole.yaml`:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: secret-viewer
     labels:
       rbac.example.com/aggregate-to-ops-lead: "true"
   rules:
   - apiGroups: [""]
     resources: ["secrets"]
     verbs: ["get", "list", "watch"]
   ```

4. **Apply the secret-viewer ClusterRole**:
   ```bash
   kubectl apply -f secret-viewer-clusterrole.yaml
   ```

5. **Verify the ClusterRole was created with correct labels**:
   ```bash
   kubectl get clusterrole secret-viewer --show-labels
   ```
   **Expected Output**: Should show `rbac.example.com/aggregate-to-ops-lead=true` in the LABELS column.

### Task 2: Implement Aggregated ClusterRole Pattern
*Suggested Time: 12 minutes*

Create an aggregated ClusterRole that automatically composes permissions from multiple smaller roles. This demonstrates a production pattern for building complex, maintainable RBAC structures.

1. **Understand aggregation**: Aggregated ClusterRoles use label selectors to automatically include rules from other ClusterRoles. When you label a ClusterRole to match the selector, Kubernetes automatically adds its rules to the aggregated role.

2. **Label the built-in `view` ClusterRole** to be included in our aggregation:
   ```bash
   kubectl label clusterrole view rbac.example.com/aggregate-to-ops-lead=true
   ```

3. **Verify the label was applied**:
   ```bash
   kubectl get clusterrole view --show-labels
   ```
   **Expected Output**: Should show `rbac.example.com/aggregate-to-ops-lead=true` in the labels.

4. **Create the aggregated ClusterRole**. Create a file named `ops-lead-aggregated-clusterrole.yaml`:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: ops-lead-role
   aggregationRule:
     clusterRoleSelectors:
     - matchLabels:
         rbac.example.com/aggregate-to-ops-lead: "true"
   rules: []
   ```
   Note the empty `rules: []` - this will be automatically populated by the aggregation controller.

5. **Apply the aggregated ClusterRole**:
   ```bash
   kubectl apply -f ops-lead-aggregated-clusterrole.yaml
   ```

6. **Wait for aggregation and verify the combined permissions**:
   ```bash
   kubectl describe clusterrole ops-lead-role
   ```
   **Expected Output**: Should show rules from both `view` and `secret-viewer` ClusterRoles automatically combined.

7. **Create a ClusterRoleBinding** for testing:
   ```bash
   kubectl create clusterrolebinding ops-user-binding --clusterrole=ops-lead-role --user=ops-user
   ```

### Task 3: Create Production-Grade Developer Role
*Suggested Time: 10 minutes*

Create a focused ClusterRole for developers that follows the principle of least privilege while enabling them to deploy and manage applications effectively.

1. **Create the app-developer ClusterRole**. Create a file named `app-developer-clusterrole.yaml`:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: app-developer-role
   rules:
   # Core application resources
   - apiGroups: ["apps"]
     resources: ["deployments", "replicasets"]
     verbs: ["*"]
   - apiGroups: [""]
     resources: ["services", "endpoints"]
     verbs: ["*"]
   - apiGroups: ["networking.k8s.io"]
     resources: ["ingresses"]
     verbs: ["*"]
   # Read-only access to pods for debugging
   - apiGroups: [""]
     resources: ["pods", "pods/log", "pods/status"]
     verbs: ["get", "list", "watch"]
   # ConfigMaps for application configuration (but not secrets)
   - apiGroups: [""]
     resources: ["configmaps"]
     verbs: ["*"]
   ```

2. **Apply the ClusterRole**:
   ```bash
   kubectl apply -f app-developer-clusterrole.yaml
   ```

3. **Create a ClusterRoleBinding** for testing:
   ```bash
   kubectl create clusterrolebinding dev-user-binding --clusterrole=app-developer-role --user=dev-user
   ```

4. **Verify the ClusterRole permissions**:
   ```bash
   kubectl describe clusterrole app-developer-role
   ```
   **Expected Output**: Should show specific rules for deployments, services, ingresses, pods (read-only), and configmaps, but no access to secrets or cluster-level resources.

### Task 4: Validate Permissions with Real Workloads
*Suggested Time: 15 minutes*

Test the RBAC implementation by actually deploying and managing applications, demonstrating how these roles work in practice.

1. **Create test secrets in each namespace** for ops validation:
   ```bash
   kubectl create secret generic app-config --from-literal=database-url=postgresql://localhost:5432/app -n development
   kubectl create secret generic app-config --from-literal=database-url=postgresql://localhost:5432/app -n staging
   ```

2. **Test ops-user permissions** (should have broad read access):
   ```bash
   kubectl auth can-i list pods --as=ops-user --all-namespaces
   ```
   **Expected Output**: `yes`
   
   ```bash
   kubectl auth can-i list secrets --as=ops-user --all-namespaces
   ```
   **Expected Output**: `yes`
   
   ```bash
   kubectl auth can-i create deployments --as=ops-user -n development
   ```
   **Expected Output**: `no`

3. **Test dev-user deployment capabilities** by creating a real application:
   ```bash
   kubectl auth can-i create deployments --as=dev-user -n development
   ```
   **Expected Output**: `yes`

4. **Create a test deployment as dev-user**. Create a file named `test-app-deployment.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: test-app
     namespace: development
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: test-app
     template:
       metadata:
         labels:
           app: test-app
       spec:
         containers:
         - name: nginx
           image: nginx:1.20
           ports:
           - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: test-app-service
     namespace: development
   spec:
     selector:
       app: test-app
     ports:
     - port: 80
       targetPort: 80
   ```

5. **Apply the deployment using impersonation**:
   ```bash
   kubectl apply -f test-app-deployment.yaml --as=dev-user
   ```
   **Expected Output**: Both deployment and service should be created successfully.

6. **Test dev-user restrictions**:
   ```bash
   kubectl auth can-i list secrets --as=dev-user -n development
   ```
   **Expected Output**: `no`
   
   ```bash
   kubectl auth can-i list nodes --as=dev-user
   ```
   **Expected Output**: `no`

7. **Demonstrate ops-user can troubleshoot the deployment**:
   ```bash
   kubectl get pods -n development --as=ops-user
   kubectl get secrets -n development --as=ops-user
   ```
   **Expected Output**: Both commands should succeed, showing ops-user can see workloads and secrets for troubleshooting.

### Task 5: Demonstrate Dynamic Role Composition
*Suggested Time: 5 minutes*

Show how aggregated roles automatically update when new component roles are added, demonstrating the scalability benefit of this pattern.

1. **Create an additional component role** for log access. Create a file named `log-viewer-clusterrole.yaml`:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: log-viewer
     labels:
       rbac.example.com/aggregate-to-ops-lead: "true"
   rules:
   - apiGroups: [""]
     resources: ["pods/log"]
     verbs: ["get", "list"]
   ```

2. **Apply the new role**:
   ```bash
   kubectl apply -f log-viewer-clusterrole.yaml
   ```

3. **Verify automatic aggregation** - the ops-lead-role should now include log viewing permissions:
   ```bash
   kubectl describe clusterrole ops-lead-role | grep -A 10 -B 5 "pods/log"
   ```
   **Expected Output**: Should show the new `pods/log` permission automatically added to the aggregated role.

4. **Test the new permission**:
   ```bash
   kubectl auth can-i get pods/log --as=ops-user -n development
   ```
   **Expected Output**: `yes` - demonstrating the role automatically gained the new capability.

## Expected Results
- **Three test namespaces** (`development`, `staging`, `production`) for realistic permission testing
- **Aggregated ClusterRole** (`ops-lead-role`) that automatically composes permissions from labeled component roles
- **Modular permission structure** with separate roles for secrets, logs, and base viewing permissions
- **Production-grade developer role** (`app-developer-role`) with precise application management permissions
- **Real workload deployment** demonstrating actual permission usage beyond theoretical testing
- **Dynamic role composition** showing how aggregated roles automatically update when new components are added
- **Comprehensive validation** through both `kubectl auth can-i` and actual resource operations

## Key Learning Points
- **Aggregated ClusterRoles**: Enable modular, maintainable RBAC by automatically composing permissions from multiple smaller roles using label selectors
- **Label-based Role Composition**: The `aggregationRule` uses label selectors to dynamically include permissions from other ClusterRoles, with automatic synchronization by the controller manager
- **Built-in Role Leverage**: Production RBAC strategies should build upon Kubernetes' built-in roles (`view`, `edit`, `admin`) rather than recreating their functionality
- **Principle of Least Privilege**: Each role should grant only the minimum permissions necessary for its function, as demonstrated by the focused `app-developer-role`
- **Real-world Validation**: RBAC testing should include actual workload deployment and management, not just theoretical permission checking
- **Dynamic Role Evolution**: Aggregated roles automatically gain new capabilities when component roles are added, enabling scalable permission management
- **Namespace-scoped Testing**: Production RBAC validation requires testing across multiple namespaces to ensure proper isolation and access patterns

## Exam & Troubleshooting Tips

### CKA Exam Strategies
- **Understanding Aggregation**: Be able to explain how aggregated ClusterRoles work and identify them by the presence of `aggregationRule` and empty `rules: []`
- **Label Debugging**: Use `kubectl get clusterrole <name> --show-labels` to verify label selectors match between aggregated roles and their components
- **Permission Verification**: Always test RBAC with `kubectl auth can-i` before assuming permissions work correctly
- **Built-in Role Knowledge**: Memorize the capabilities of built-in roles (`view`, `edit`, `admin`, `cluster-admin`) to leverage them effectively

### Common Troubleshooting Scenarios
- **Missing Permissions in Aggregated Role**: Check if component roles have the correct labels matching the `clusterRoleSelectors`
- **Controller Synchronization Lag**: Aggregation updates can take 5-10 seconds; use `kubectl describe clusterrole <name>` to verify current effective permissions
- **Impersonation Testing**: Always test with `--as=username` to validate permissions from the user's perspective
- **Namespace vs Cluster Scope**: Remember that ClusterRoles grant cluster-wide permissions; use RoleBindings to restrict to specific namespaces

### Production Troubleshooting
- **Permission Denied Errors**: Use `kubectl auth can-i <verb> <resource> --as=<user> -n <namespace>` to diagnose access issues
- **Role Binding Confusion**: Check both ClusterRoleBindings and RoleBindings when troubleshooting user permissions
- **Service Account Issues**: Remember that pods use service account tokens; test permissions with `--as=system:serviceaccount:<namespace>:<sa-name>`

### Cleanup Commands
```bash
# Remove custom labels from built-in roles
kubectl label clusterrole view rbac.example.com/aggregate-to-ops-lead-

# Delete test resources
kubectl delete namespace development staging production
kubectl delete clusterrole secret-viewer log-viewer ops-lead-role app-developer-role
kubectl delete clusterrolebinding ops-user-binding dev-user-binding
```
