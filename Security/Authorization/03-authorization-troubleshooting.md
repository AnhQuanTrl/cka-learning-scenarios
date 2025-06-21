# Authorization Troubleshooting

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Learn to systematically troubleshoot RBAC authorization issues using kubectl debugging tools and audit logs to identify and resolve common permission problems.

## Context
Your development team is reporting access issues after recent RBAC changes. As the platform engineer, you need to troubleshoot why users can't access resources they should be able to use. The team has reported these specific problems:

1. **Sarah (developer)** can't create deployments in the `dev` namespace despite having a "developer" role
2. **Mike (ops-viewer)** can't list pods across all namespaces even though he should have read-only access
3. **The deployment-manager ServiceAccount** used by CI/CD pipeline is failing to update deployments

You'll use kubectl's authorization testing tools and audit logs to diagnose and fix these permission issues.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended)
- `kubectl` installed and configured with administrative access
- Basic understanding of RBAC concepts (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)

## Tasks

### Task 1: Set Up the Problematic RBAC Configuration
*Suggested Time: 8 minutes*

Create the initial resources that contain the authorization problems you'll need to troubleshoot.

1. **Create the `dev` namespace**:
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: dev
   ```

2. **Create user certificate for Sarah** (simulate user authentication):
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: sarah-certs
     namespace: dev
   type: Opaque
   data:
     # This simulates having user certificates - in real scenarios these would be actual cert files
     client-cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t
     client-key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t
   ```

3. **Create a Role for developers** (with intentional issues):
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     namespace: dev
     name: developer
   rules:
   - apiGroups: ["apps"]
     resources: ["deployment"]  # Missing 's' - should be "deployments"
     verbs: ["get", "list", "create", "update", "patch", "delete"]
   - apiGroups: [""]
     resources: ["pods", "services"]
     verbs: ["get", "list"]
   ```

4. **Create RoleBinding for Sarah**:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: sarah-developer
     namespace: dev
   subjects:
   - kind: User
     name: sarah
     apiGroup: rbac.authorization.k8s.io
   roleRef:
     kind: Role
     name: developer
     apiGroup: rbac.authorization.k8s.io
   ```

5. **Create ClusterRole for ops-viewer** (with scope issues):
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: ops-viewer
   rules:
   - apiGroups: [""]
     resources: ["pods", "services", "nodes"]
     verbs: ["get", "list", "watch"]
   ```

6. **Create incorrect binding for Mike** (using RoleBinding instead of ClusterRoleBinding):
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding  # Should be ClusterRoleBinding for cluster-wide access
   metadata:
     name: mike-ops-viewer
     namespace: default
   subjects:
   - kind: User
     name: mike
     apiGroup: rbac.authorization.k8s.io
   roleRef:
     kind: ClusterRole
     name: ops-viewer
     apiGroup: rbac.authorization.k8s.io
   ```

7. **Create ServiceAccount for CI/CD**:
   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: deployment-manager
     namespace: dev
   ```

8. **Create Role for deployment management** (missing key verbs):
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     namespace: dev
     name: deployment-manager
   rules:
   - apiGroups: ["apps"]
     resources: ["deployments"]
     verbs: ["get", "list"]  # Missing "update", "patch" verbs needed for CI/CD
   ```

9. **Create RoleBinding for ServiceAccount**:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: deployment-manager-binding
     namespace: dev
   subjects:
   - kind: ServiceAccount
     name: deployment-manager
     namespace: dev
   roleRef:
     kind: Role
     name: deployment-manager
     apiGroup: rbac.authorization.k8s.io
   ```

### Task 2: Troubleshoot Sarah's Deployment Creation Issue
*Suggested Time: 5 minutes*

Use `kubectl auth can-i` to test Sarah's permissions and identify why she can't create deployments.

1. **Test Sarah's ability to create deployments in the dev namespace**:
   - Use the `--as` flag to impersonate Sarah
   - Test the specific action she's trying to perform
   - **Hint**: Check both the resource name and API group

2. **Identify the specific permission issue**:
   - Compare what permissions Sarah has versus what she needs
   - Check the Role definition for any typos or incorrect resource names

3. **Fix the Role definition**:
   - Correct the resource name in the developer Role
   - Apply the corrected configuration

### Task 3: Troubleshoot Mike's Cross-Namespace Pod Access
*Suggested Time: 5 minutes*

Diagnose why Mike can't list pods across all namespaces despite having a ClusterRole.

1. **Test Mike's cluster-wide pod access**:
   - Test his ability to list pods in different namespaces
   - Test his ability to list pods cluster-wide (no namespace specified)

2. **Identify the binding scope issue**:
   - Examine the type of binding used for Mike's permissions
   - Determine why a ClusterRole isn't providing cluster-wide access

3. **Fix the binding configuration**:
   - Replace the incorrect binding with the proper binding type
   - Verify the fix works across multiple namespaces

### Task 4: Troubleshoot ServiceAccount Permission Issues
*Suggested Time: 4 minutes*

Debug why the CI/CD ServiceAccount can't update deployments.

1. **Test ServiceAccount permissions**:
   - Use `--as=system:serviceaccount:dev:deployment-manager` to impersonate the ServiceAccount
   - Test the specific verbs needed for deployment updates

2. **Identify missing verbs**:
   - Compare current permissions with typical CI/CD requirements
   - Determine which verbs are needed for deployment updates

3. **Update the Role with missing permissions**:
   - Add the necessary verbs to the deployment-manager Role
   - Test that the ServiceAccount can now perform updates

### Task 5: Verify and Document Authorization Testing
*Suggested Time: 3 minutes*

Create a comprehensive test to verify all permissions are working correctly.

1. **Create a test script** that verifies all users can perform their intended actions:
   - Sarah can create/manage deployments in dev namespace
   - Mike can list pods across all namespaces
   - ServiceAccount can update deployments in dev namespace

2. **Test edge cases**:
   - Verify users can't perform actions they shouldn't have access to
   - Test access to resources in different namespaces

## Verification Commands

### Verify Sarah's Permissions
```bash
# Test deployment creation (should succeed after fix)
kubectl auth can-i create deployments --namespace=dev --as=sarah

# Test deployment listing (should succeed)
kubectl auth can-i list deployments --namespace=dev --as=sarah

# Test access to other namespaces (should fail)
kubectl auth can-i create deployments --namespace=default --as=sarah
```

**Expected Output**: 
- `yes` for dev namespace deployment creation and listing
- `no` for default namespace access

### Verify Mike's Permissions
```bash
# Test pod listing across all namespaces (should succeed after fix)
kubectl auth can-i list pods --as=mike

# Test pod listing in specific namespaces (should succeed)
kubectl auth can-i list pods --namespace=kube-system --as=mike

# Test creation permissions (should fail)
kubectl auth can-i create pods --as=mike
```

**Expected Output**:
- `yes` for listing pods cluster-wide and in specific namespaces
- `no` for creation permissions

### Verify ServiceAccount Permissions
```bash
# Test deployment updates (should succeed after fix)
kubectl auth can-i update deployments --namespace=dev --as=system:serviceaccount:dev:deployment-manager

# Test deployment patching (should succeed after fix)
kubectl auth can-i patch deployments --namespace=dev --as=system:serviceaccount:dev:deployment-manager

# Test access to secrets (should fail)
kubectl auth can-i get secrets --namespace=dev --as=system:serviceaccount:dev:deployment-manager
```

**Expected Output**:
- `yes` for update and patch operations on deployments
- `no` for secret access

### Comprehensive Authorization Check
```bash
# Check all resources Sarah can access in dev namespace
kubectl auth can-i --list --namespace=dev --as=sarah

# Check all resources Mike can access cluster-wide
kubectl auth can-i --list --as=mike

# Check all resources ServiceAccount can access in dev namespace
kubectl auth can-i --list --namespace=dev --as=system:serviceaccount:dev:deployment-manager
```

**Expected Output**: Detailed lists showing exactly which resources each user/ServiceAccount can access with which verbs.

## Expected Results

After completing all tasks, you should have:

1. **Fixed developer Role**: Resource name corrected from "deployment" to "deployments"
2. **Fixed ops-viewer binding**: Changed from RoleBinding to ClusterRoleBinding for cluster-wide access
3. **Enhanced deployment-manager Role**: Added "update" and "patch" verbs for CI/CD operations
4. **Functional authorization testing**: All users can perform their intended actions
5. **Proper access boundaries**: Users cannot perform actions outside their intended scope

## Key Learning Points

- **kubectl auth can-i**: Essential tool for testing specific permissions before deployment
- **Resource name accuracy**: Kubernetes resource names must be exact (plural forms, correct spelling)
- **Binding scope matters**: RoleBinding vs ClusterRoleBinding determines access scope
- **ServiceAccount impersonation**: Use `system:serviceaccount:namespace:name` format for testing
- **Verb completeness**: Ensure all necessary verbs are granted for intended operations
- **Permission boundaries**: Regularly verify users can't access resources they shouldn't
- **Systematic debugging**: Test specific actions that are failing rather than general permissions

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Use `kubectl auth can-i` extensively**: This is the fastest way to verify permissions during the exam
- **Check resource names carefully**: Many RBAC issues are simple typos in resource names
- **Remember binding types**: ClusterRoleBinding for cluster-wide access, RoleBinding for namespace-specific
- **Test with exact user/ServiceAccount names**: Impersonation syntax must be precise
- **Verify both positive and negative permissions**: Ensure users can do what they should and can't do what they shouldn't

### Common Troubleshooting Issues
- **Resource name typos**: "deployment" vs "deployments", "service" vs "services"
- **Wrong binding type**: Using RoleBinding when ClusterRoleBinding is needed
- **Missing verbs**: Forgetting "update", "patch", "delete" when only "get", "list" are specified
- **API group confusion**: Some resources are in "" (core), others in "apps", "extensions", etc.
- **Case sensitivity**: Kubernetes names are case-sensitive in subjects and roleRefs
- **Namespace scope**: Resources in different namespaces require appropriate bindings
- **ServiceAccount format**: Must use full `system:serviceaccount:namespace:name` format for impersonation