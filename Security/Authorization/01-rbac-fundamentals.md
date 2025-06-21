# RBAC Fundamentals

## Scenario Overview
- **Time Limit**: 35 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master Role-Based Access Control (RBAC) fundamentals by implementing secure access patterns for a monitoring application and junior administrator using both namespaced and cluster-wide permissions.

## Context
Your organization is deploying a monitoring application called **MetricsCollector** that needs to gather configuration data from secrets and expose metrics about cluster health. Additionally, you have a junior administrator who needs limited cluster access for monitoring purposes.

You must implement RBAC following the principle of least privilege:
1. **MetricsCollector application**: Runs in the `monitoring` namespace, needs to read secrets for database credentials and API keys, and must be able to list pods to generate metrics
2. **Junior administrator (junior-admin)**: Needs read-only access to view nodes and basic cluster information for monitoring dashboards
3. **Security requirement**: Demonstrate that permissions are properly scoped and isolated

## Prerequisites
- A running Kubernetes cluster (k3s is recommended)
- `kubectl` installed and configured with administrative access
- Basic understanding of Kubernetes resources (Deployments, Services, Secrets)

## Tasks

### Task 1: Create Initial Resources for MetricsCollector Application
*Suggested Time: 8 minutes*

Create the foundational resources for the MetricsCollector monitoring application.

1. **Create the `monitoring` namespace** where the application will run.

2. **Create a ServiceAccount** named `metrics-collector-sa` in the `monitoring` namespace for the application to use.

3. **Create sample secrets** that the application will need to access:
   - Secret named `db-credentials` containing a key `username` with value `metrics-user`
   - Secret named `api-keys` containing a key `prometheus-key` with value `secret-api-token-123`

**Hints:**
- Use imperative commands for faster creation
- Remember that secrets need to be in the same namespace as the application

### Task 2: Create and Deploy the MetricsCollector Application
*Suggested Time: 7 minutes*

Deploy a simple application that will use the ServiceAccount you created.

1. **Create a Deployment** named `metrics-collector` in the `monitoring` namespace with these specifications:
   - Use image `nginx:alpine` (simulating the metrics collector)
   - Set `spec.template.spec.serviceAccountName` to `metrics-collector-sa`
   - Add an environment variable `ROLE` with value `metrics-collector`
   - Use 1 replica

2. **Verify the pod is running** but note that it cannot yet access secrets (this will be fixed in the next task).

### Task 3: Configure Namespaced RBAC for MetricsCollector
*Suggested Time: 8 minutes*

Create appropriate RBAC permissions for the MetricsCollector to function properly.

1. **Create a Role** named `metrics-reader` in the `monitoring` namespace that allows:
   - Reading secrets (get, list verbs)
   - Listing pods (list verb only, for metrics generation)

2. **Create a RoleBinding** named `metrics-collector-binding` that binds the `metrics-reader` role to the `metrics-collector-sa` ServiceAccount.

**Production Pattern Note:** In production, you would typically create a ConfigMap hash annotation on the deployment to trigger rolling updates when secrets change.

### Task 4: Configure Cluster-Wide RBAC for Junior Administrator  
*Suggested Time: 6 minutes*

Set up limited cluster access for monitoring purposes.

1. **Create a ClusterRole** named `monitoring-reader` that allows:
   - Reading nodes (get, list, watch verbs)
   - Reading namespaces (get, list verbs)
   - Getting cluster-level metrics from the metrics API

2. **Create a ClusterRoleBinding** named `junior-admin-monitoring` that binds the `monitoring-reader` ClusterRole to the user `junior-admin`.

### Task 5: Test and Validate RBAC Implementation
*Suggested Time: 6 minutes*

Verify that permissions work as expected and are properly isolated.

1. **Test MetricsCollector ServiceAccount permissions** using `kubectl auth can-i`:
   - Should be able to list secrets in `monitoring` namespace
   - Should be able to list pods in `monitoring` namespace  
   - Should NOT be able to list secrets in `default` namespace
   - Should NOT be able to delete pods in any namespace

2. **Test junior-admin user permissions**:
   - Should be able to list nodes cluster-wide
   - Should be able to list namespaces
   - Should NOT be able to list pods in any namespace
   - Should NOT be able to delete or modify any resources

3. **Verify the MetricsCollector pod can access its secrets** by checking the pod's service account token and permissions.

## Verification Commands

### Task 1: Initial Resources
- **Verify namespace creation**:
  ```bash
  kubectl get namespace monitoring
  ```
  - **Expected Output**: Shows the `monitoring` namespace in `Active` status

- **Verify ServiceAccount creation**:
  ```bash
  kubectl get serviceaccount metrics-collector-sa -n monitoring -o yaml
  ```
  - **Expected Output**: Shows the ServiceAccount with `automountServiceAccountToken: true` and generated secrets

- **Verify secrets creation**:
  ```bash
  kubectl get secrets -n monitoring -o custom-columns=NAME:.metadata.name,TYPE:.type
  ```
  - **Expected Output**: Shows `db-credentials` and `api-keys` secrets with type `Opaque`

### Task 2: Application Deployment
- **Verify deployment is running**:
  ```bash
  kubectl get deployment metrics-collector -n monitoring -o wide
  ```
  - **Expected Output**: Shows 1/1 READY replicas using `nginx:alpine` image

- **Check pod is using correct ServiceAccount**:
  ```bash
  kubectl get pod -n monitoring -o jsonpath='{.items[0].spec.serviceAccountName}'
  ```
  - **Expected Output**: `metrics-collector-sa`

### Task 3: Namespaced RBAC
- **Verify Role creation**:
  ```bash
  kubectl describe role metrics-reader -n monitoring
  ```
  - **Expected Output**: Shows rules allowing `get,list` on `secrets` and `list` on `pods`

- **Verify RoleBinding**:
  ```bash
  kubectl describe rolebinding metrics-collector-binding -n monitoring
  ```
  - **Expected Output**: Shows `metrics-collector-sa` ServiceAccount bound to `metrics-reader` Role

### Task 4: Cluster-Wide RBAC
- **Verify ClusterRole creation**:
  ```bash
  kubectl describe clusterrole monitoring-reader
  ```
  - **Expected Output**: Shows rules allowing `get,list,watch` on `nodes` and `get,list` on `namespaces`

- **Verify ClusterRoleBinding**:
  ```bash
  kubectl describe clusterrolebinding junior-admin-monitoring
  ```
  - **Expected Output**: Shows user `junior-admin` bound to `monitoring-reader` ClusterRole

### Task 5: RBAC Permission Testing
- **MetricsCollector ServiceAccount - Allowed Actions**:
  ```bash
  kubectl auth can-i list secrets --as=system:serviceaccount:monitoring:metrics-collector-sa -n monitoring
  ```
  - **Expected Output**: `yes`

  ```bash
  kubectl auth can-i list pods --as=system:serviceaccount:monitoring:metrics-collector-sa -n monitoring
  ```
  - **Expected Output**: `yes`

- **MetricsCollector ServiceAccount - Denied Actions**:
  ```bash
  kubectl auth can-i list secrets --as=system:serviceaccount:monitoring:metrics-collector-sa -n default
  ```
  - **Expected Output**: `no`

  ```bash
  kubectl auth can-i delete pods --as=system:serviceaccount:monitoring:metrics-collector-sa -n monitoring
  ```
  - **Expected Output**: `no`

- **Junior Admin User - Allowed Actions**:
  ```bash
  kubectl auth can-i list nodes --as=junior-admin
  ```
  - **Expected Output**: `yes`

  ```bash
  kubectl auth can-i list namespaces --as=junior-admin
  ```
  - **Expected Output**: `yes`

- **Junior Admin User - Denied Actions**:
  ```bash
  kubectl auth can-i list pods --as=junior-admin -n monitoring
  ```
  - **Expected Output**: `no`

  ```bash
  kubectl auth can-i delete nodes --as=junior-admin
  ```
  - **Expected Output**: `no`

- **Verify Pod Can Access Secrets** (Advanced):
  ```bash
  kubectl exec -n monitoring deployment/metrics-collector -- ls /var/run/secrets/kubernetes.io/serviceaccount/
  ```
  - **Expected Output**: Shows `ca.crt`, `namespace`, and `token` files

## Expected Results
- **Monitoring namespace**: Contains a running MetricsCollector deployment with proper ServiceAccount configuration
- **Application secrets**: Two secrets (`db-credentials` and `api-keys`) accessible only to the MetricsCollector ServiceAccount
- **Namespaced RBAC**: Role `metrics-reader` and RoleBinding `metrics-collector-binding` providing limited access to secrets and pods within the monitoring namespace only
- **Cluster-wide RBAC**: ClusterRole `monitoring-reader` and ClusterRoleBinding `junior-admin-monitoring` providing read-only access to nodes and namespaces across the cluster
- **Permission isolation**: All `kubectl auth can-i` tests demonstrate proper permission boundaries with no privilege escalation
- **Functional application**: MetricsCollector pod successfully accesses its required secrets while being restricted from unauthorized resources

## Key Learning Points
- **Role vs. ClusterRole**: A `Role` is namespaced and grants permissions to resources within that specific namespace only. A `ClusterRole` is cluster-wide and can grant access to cluster-scoped resources (nodes, namespaces) or to namespaced resources across all namespaces
- **RoleBinding vs. ClusterRoleBinding**: A `RoleBinding` grants Role permissions within a namespace. A `ClusterRoleBinding` grants ClusterRole permissions cluster-wide. **Advanced pattern**: You can use a RoleBinding to bind a ClusterRole to limit its scope to one namespace
- **ServiceAccount Integration**: Applications should use ServiceAccounts with minimal required permissions. ServiceAccounts automatically get API server access tokens mounted at `/var/run/secrets/kubernetes.io/serviceaccount/`
- **Permission Verification**: `kubectl auth can-i` is essential for testing RBAC without creating actual kubeconfig files. It queries the API server's authorization layer directly
- **Principle of Least Privilege**: Grant only the minimum permissions required for functionality. Use specific verbs (get, list, watch) rather than wildcards (*) 
- **RBAC Subject Types**: Bindings can target ServiceAccounts (`system:serviceaccount:namespace:name`), Users (`username`), or Groups (`system:authenticated`, custom groups)
- **Production Patterns**: Real applications typically need ConfigMaps, Secrets, and resource discovery permissions. Always test with actual workloads rather than just theoretical permissions

## Exam & Troubleshooting Tips

### CKA Exam Strategies
- **Speed with Imperatives**: Use `kubectl create role/clusterrole/rolebinding/clusterrolebinding` commands rather than writing YAML. Example: `kubectl create role pod-reader --verb=get,list --resource=pods -n monitoring`
- **RBAC Questions Pattern**: Exam typically gives you a ServiceAccount name and asks you to create specific permissions. Always verify with `kubectl auth can-i` afterward
- **Common Exam Scenario**: "Create a ServiceAccount that can only read secrets in namespace X but not delete them" - focus on minimal verb sets

### Troubleshooting RBAC Issues
- **Permission Denied Errors**: 
  1. First, use `kubectl auth can-i <verb> <resource> --as=<subject> -n <namespace>` to confirm the issue
  2. Check if the binding exists: `kubectl get rolebinding,clusterrolebinding --all-namespaces | grep <subject-name>`
  3. Verify the role has correct rules: `kubectl describe role/clusterrole <role-name>`

- **ServiceAccount Authentication Issues**:
  - Check if ServiceAccount exists: `kubectl get sa <name> -n <namespace>`
  - Verify pod is using correct SA: `kubectl get pod <name> -o jsonpath='{.spec.serviceAccountName}'`
  - Check token mounting: `kubectl get pod <name> -o jsonpath='{.spec.automountServiceAccountToken}'`

### Common RBAC Mistakes & How to Avoid Them
- **Wrong Binding Type**: Cannot bind a Role with ClusterRoleBinding (only ClusterRole + ClusterRoleBinding or Role + RoleBinding)
- **Namespace Confusion**: Forgetting `-n namespace` creates resources in `default` namespace. Always double-check with `kubectl get role,rolebinding -A | grep <name>`
- **Subject Name Format**: ServiceAccounts must use full format `system:serviceaccount:namespace:name` in bindings
- **Overprivileged Permissions**: Using `*` wildcards or `create/delete` when only `get/list` needed. Always follow least privilege
- **Cross-Namespace Access**: Remember that RoleBindings grant access only within their namespace, even when binding ClusterRoles

### Production Security Considerations
- **ServiceAccount Token Security**: In production, consider using projected tokens with shorter lifespans and audience restrictions
- **RBAC Auditing**: Enable audit logging to track who accessed what resources: `--audit-log-path` and `--audit-policy-file`
- **Privilege Escalation Prevention**: Never grant `*` permissions on core resources like secrets, configmaps, or RBAC resources themselves
- **Regular RBAC Reviews**: Periodically audit permissions with `kubectl get clusterrolebinding -o yaml` and look for overly broad access
