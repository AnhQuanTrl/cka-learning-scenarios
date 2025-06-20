# RBAC Advanced Patterns

## Scenario Overview
- **Time Limit**: 30 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Learn to use advanced RBAC features, including aggregated ClusterRoles and the strategic use of built-in roles, to create a scalable and maintainable permissions structure.

## Context
Your organization is scaling its use of Kubernetes. You need to create a tiered system of permissions for two new roles:
1.  **`ops-lead`**: This role should have all the permissions of the built-in `view` ClusterRole, plus the ability to view secrets in all namespaces. This is for a senior operator who needs broad read-only access, including for troubleshooting secrets.
2.  **`app-developer`**: This role needs to manage Deployments, Services, and Ingresses in any namespace, but should not have access to other resources like ConfigMaps or Secrets.

To avoid duplicating permissions, you will use an aggregated ClusterRole for the `ops-lead` and create a new, focused ClusterRole for the `app-developer`.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with administrative access.

## Tasks

### Task 1: Create a ClusterRole for Secret Viewing
*Suggested Time: 5 minutes*

First, create a small, focused `ClusterRole` that only grants permission to view secrets. This will be aggregated into the main `ops-lead` role.

1.  **Create a `ClusterRole`** named `secret-viewer`.
    - Create a file named `secret-viewer-clusterrole.yaml`:
      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: secret-viewer
      rules:
      - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["get", "list", "watch"]
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f secret-viewer-clusterrole.yaml
      ```

### Task 2: Create an Aggregated ClusterRole for the Ops Lead
*Suggested Time: 10 minutes*

Now, create the main `ops-lead` role. This role will use an `aggregationRule` to automatically inherit permissions from both the built-in `view` role and your new `secret-viewer` role.

1.  **Create the `ops-lead-role` `ClusterRole`**.
    - Create a file named `ops-lead-aggregated-clusterrole.yaml`:
      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: ops-lead-role
      aggregationRule:
        clusterRoleSelectors:
        - matchLabels:
            rbac.example.com/aggregate-to-ops-lead: "true"
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f ops-lead-aggregated-clusterrole.yaml
      ```

2.  **Label the `view` and `secret-viewer` ClusterRoles** to be selected by the aggregation rule.
    ```bash
    kubectl label clusterrole view rbac.example.com/aggregate-to-ops-lead=true
    kubectl label clusterrole secret-viewer rbac.example.com/aggregate-to-ops-lead=true
    ```

3.  **Bind the `ops-lead-role`** to a user named `ops-user`.
    ```bash
    kubectl create clusterrolebinding ops-user-binding --clusterrole=ops-lead-role --user=ops-user
    ```

### Task 3: Create a Focused ClusterRole for the App Developer
*Suggested Time: 5 minutes*

Create a `ClusterRole` for the `app-developer` that grants specific permissions across all namespaces.

1.  **Create the `app-developer-role` `ClusterRole`**.
    - Create a file named `app-developer-clusterrole.yaml`:
      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: app-developer-role
      rules:
      - apiGroups: ["apps", "extensions"]
        resources: ["deployments"]
        verbs: ["*"]
      - apiGroups: [""]
        resources: ["services"]
        verbs: ["*"]
      - apiGroups: ["networking.k8s.io"]
        resources: ["ingresses"]
        verbs: ["*"]
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f app-developer-clusterrole.yaml
      ```

2.  **Bind the `app-developer-role`** to a user named `dev-user`.
    ```bash
    kubectl create clusterrolebinding dev-user-binding --clusterrole=app-developer-role --user=dev-user
    ```

### Task 4: Verify Permissions
*Suggested Time: 10 minutes*

Use `kubectl auth can-i` to verify the permissions for both new roles.

1.  **Test the `ops-user`'s permissions**.
    - Can they view pods? (Should be **yes**, from the `view` role).
      ```bash
      kubectl auth can-i list pods --as=ops-user -A
      ```
    - Can they view secrets? (Should be **yes**, from the `secret-viewer` role).
      ```bash
      kubectl auth can-i list secrets --as=ops-user -A
      ```
    - Can they edit pods? (Should be **no**).
      ```bash
      kubectl auth can-i patch pods --as=ops-user -n default
      ```

2.  **Test the `dev-user`'s permissions**.
    - Can they create deployments? (Should be **yes**).
      ```bash
      kubectl auth can-i create deployments --as=dev-user -n default
      ```
    - Can they list secrets? (Should be **no**).
      ```bash
      kubectl auth can-i list secrets --as=dev-user -n default
      ```
    - Can they list nodes? (Should be **no**).
      ```bash
      kubectl auth can-i list nodes --as=dev-user
      ```

## Verification Commands

### Task 2: Aggregated Role
- **Check the labels on the `view` role**:
  ```bash
  kubectl get clusterrole view --show-labels
  ```
  - **Expected Output**: Should show the label `rbac.example.com/aggregate-to-ops-lead=true`.
- **Describe the `ops-lead-role`**:
  ```bash
  kubectl describe clusterrole ops-lead-role
  ```
  - **Expected Output**: The `Rules` section should list the permissions inherited from both `view` and `secret-viewer`.

### Task 4: Permissions Check
- **Ops User (Success)**:
  ```bash
  kubectl auth can-i list secrets --as=ops-user -A
  ```
  - **Expected Output**: `yes`
- **Ops User (Failure)**:
  ```bash
  kubectl auth can-i patch pods --as=ops-user -n default
  ```
  - **Expected Output**: `no`
- **Dev User (Success)**:
  ```bash
  kubectl auth can-i create deployments --as=dev-user -n default
  ```
  - **Expected Output**: `yes`
- **Dev User (Failure)**:
  ```bash
  kubectl auth can-i list secrets --as=dev-user -n default
  ```
  - **Expected Output**: `no`

## Expected Results
- An aggregated `ClusterRole` named `ops-lead-role` is created, which automatically inherits permissions from any other `ClusterRole` matching its label selector.
- The `ops-user` has cluster-wide read access to most resources (via `view`) and secrets (via `secret-viewer`).
- A focused `ClusterRole` named `app-developer-role` is created, granting only the necessary permissions to manage application-related resources.
- The `dev-user` can manage deployments, services, and ingresses in any namespace but cannot access other resources.

## Key Learning Points
- **Aggregated ClusterRoles**: This is a powerful feature for building complex roles out of smaller, reusable components. It helps keep your RBAC configuration DRY (Don't Repeat Yourself) and makes it easier to manage.
- **`aggregationRule`**: This field in a `ClusterRole`'s metadata defines the label selector used to find other `ClusterRoles` to aggregate. The controller manager automatically keeps the rules in sync.
- **Built-in Roles**: Kubernetes comes with several useful default roles like `view`, `edit`, and `admin`. Leveraging these roles (especially `view`) as a base for your own custom roles is a common and effective pattern.
- **Role Granularity**: Create roles that are as granular as possible. The `app-developer-role` is a good example of a role that grants just enough permission to do a specific job, without granting overly broad access.

## Exam & Troubleshooting Tips
- **Exam Tip**: While you may not be asked to create a complex aggregated role from scratch, you should be able to understand how they work and how to debug them. Know how to check labels (`--show-labels`) and describe roles to see their effective permissions.
- **Troubleshooting**: If an aggregated role doesn't have the expected permissions, the first thing to check is the labels. Ensure that the `clusterRoleSelectors` in the aggregated role match the labels on the roles you want to include.
- **Controller Lag**: The controller that updates aggregated roles can have a slight delay. If you've just labeled a role and don't see the permissions update immediately, wait a few seconds and check again.
- **Cleanup**: Remember to remove the labels from the built-in roles when you are done, to avoid leaving your cluster in a non-standard state.
  ```bash
  kubectl label clusterrole view rbac.example.com/aggregate-to-ops-lead-
  ```
