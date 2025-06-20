# ConfigMap Consumption Patterns

## Scenario Overview
**Time Limit**: 25 minutes  
**Difficulty**: Intermediate  
**Environment**: k3s bare metal

## Objective
Master the various methods for consuming ConfigMap data in Kubernetes Pods, including environment variable injection, volume mounting (full, partial, and subPath), and command-line arguments, while understanding update propagation and precedence rules.

## Context
Your development team relies on ConfigMaps to manage application settings. You are tasked with creating a comprehensive demonstration of all possible consumption patterns to establish best practices for the team. You will create several Pods and Deployments, each illustrating a specific way to consume configuration data.

## Prerequisites
- A running Kubernetes cluster (k3s recommended).
- `kubectl` installed and configured with admin access.
- Basic understanding of Pods, Deployments, and ConfigMaps.

## Initial Setup
Before starting the tasks, create the necessary ConfigMaps that will be consumed.

**Step 1: Create local configuration files and ConfigMaps**

First, create the ConfigMaps imperatively.

```bash
# Create a ConfigMap for general app settings
kubectl create configmap app-config \
  --from-literal=APP_COLOR=blue \
  --from-literal=APP_MODE=production

# Create a ConfigMap for database connection details
kubectl create configmap db-config \
  --from-literal=DB_HOST=mysql \
  --from-literal=DB_PORT=3306

# Create a local nginx configuration file
cat <<EOF > nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    location /health {
        access_log off;
        return 200 "healthy\n";
    }
}
EOF

# Create a ConfigMap from the nginx file
kubectl create configmap nginx-config --from-file=nginx.conf
```

## Tasks

### Task 1: Inject Individual ConfigMap Keys as Environment Variables
**(2 minutes)**

Create a Pod that consumes specific keys from two different ConfigMaps and exposes them as environment variables inside the container.

- **Pod Name**: `pod-env-single-key`
- **Container Image**: `busybox:1.35`
- **Container Command**: `["/bin/sh", "-c", "echo 'My application color is $(MY_APP_COLOR) and the database host is $(DATABASE_HOST)'; sleep 3600"]`
- **Environment Variables**:
    - Create an environment variable named `MY_APP_COLOR` that gets its value from the `APP_COLOR` key in the `app-config` ConfigMap.
    - Create an environment variable named `DATABASE_HOST` that gets its value from the `DB_HOST` key in the `db-config` ConfigMap.
- **Restart Policy**: `Never`

### Task 2: Inject All Keys from a ConfigMap using `envFrom`
**(2 minutes)**

Create a Pod that injects all key-value pairs from the `app-config` ConfigMap directly as environment variables.

- **Pod Name**: `pod-env-from`
- **Container Image**: `busybox:1.35`
- **Container Command**: `["/bin/sh", "-c", "env | grep APP_ && sleep 3600"]`
- **ConfigMap Source**: Inject all keys from the `app-config` ConfigMap as environment variables.
- **Restart Policy**: `Never`

### Task 3: Mount a Full ConfigMap as a Volume
**(3 minutes)**

Create a Pod that mounts the entire `db-config` ConfigMap as a volume. The keys in the ConfigMap will become filenames in the mounted directory.

- **Pod Name**: `pod-volume-full`
- **Container Image**: `busybox:1.35`
- **Container Command**: `["/bin/sh", "-c", "ls -l /etc/config && sleep 3600"]`
- **Volume Mount**: Mount the `db-config` ConfigMap to the path `/etc/config` inside the container.
- **Restart Policy**: `Never`

### Task 4: Mount Specific ConfigMap Keys to Custom Paths
**(3 minutes)**

Create a Pod that mounts only the `DB_HOST` key from `db-config` to a specific file path and renames it.

- **Pod Name**: `pod-volume-items`
- **Container Image**: `busybox:1.35`
- **Container Command**: `["/bin/sh", "-c", "cat /etc/config/database.host && sleep 3600"]`
- **Volume Mount**: Mount only the `DB_HOST` key from the `db-config` ConfigMap to a file named `database.host` inside the `/etc/config` directory.
- **Restart Policy**: `Never`

### Task 5: Use `subPath` to Mount a Single Key into a File
**(3 minutes)**

Create an Nginx Pod that uses `subPath` to mount the `nginx.conf` key from the `nginx-config` ConfigMap, effectively overwriting the default Nginx configuration file.

- **Pod Name**: `pod-subpath`
- **Container Image**: `nginx:stable`
- **Container Port**: `80`
- **Volume Mount**: Mount the `nginx.conf` key from the `nginx-config` ConfigMap to the file `/etc/nginx/conf.d/default.conf` using `subPath`.
- **Restart Policy**: `Always`

### Task 6: Consume ConfigMap Data as Command-Line Arguments
**(2 minutes)**

Create a Pod that first injects `APP_MODE` as an environment variable and then uses it in a command-line argument.

- **Pod Name**: `pod-cmd-args`
- **Container Image**: `busybox:1.35`
- **Container Command**: `[ "/bin/sh", "-c", "echo 'Starting application in $(APP_MODE) mode.' && sleep 3600" ]`
- **Environment Variable**: Create an environment variable named `APP_MODE` from the `APP_MODE` key in the `app-config` ConfigMap.
- **Restart Policy**: `Never`

### Task 7: Observe Automatic Updates for Volume-Mounted ConfigMaps
**(5 minutes)**

This task demonstrates that volume-mounted ConfigMaps are updated automatically inside the Pod.

- **Deployment Name**: `deployment-autoupdate`
- **Replicas**: `1`
- **Container Image**: `busybox:1.35`
- **Container Command**: `["/bin/sh", "-c", "while true; do cat /etc/config/APP_COLOR; echo; sleep 5; done"]`
- **Volume Mount**: Mount the `app-config` ConfigMap to the path `/etc/config`.

### Task 8: Understand Environment Variable Precedence
**(3 minutes)**

Create a Pod that defines an environment variable explicitly and also sources it from a ConfigMap via `envFrom`. This demonstrates that the explicit `env` entry takes precedence.

- **Pod Name**: `pod-env-precedence`
- **Container Image**: `busybox:1.e35`
- **Container Command**: `["/bin/sh", "-c", "echo 'The final application color is $(APP_COLOR)'; sleep 3600"]`
- **Environment Variables**:
    - Inject all keys from the `app-config` ConfigMap.
    - Explicitly define an environment variable named `APP_COLOR` with the value `red`.
- **Restart Policy**: `Never`

## Verification Commands

### Task 1 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-env-single-key --timeout=60s

# Check the logs
kubectl logs pod-env-single-key
```
- **Expected Result**: `My application color is blue and the database host is mysql`

### Task 2 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-env-from --timeout=60s

# Check the logs
kubectl logs pod-env-from
```
- **Expected Result**:
  ```
  APP_MODE=production
  APP_COLOR=blue
  ```

### Task 3 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-volume-full --timeout=60s

# Check the logs for the file listing
kubectl logs pod-volume-full
```
- **Expected Result**: The output should list the files `DB_HOST` and `DB_PORT`.

### Task 4 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-volume-items --timeout=60s

# Check the logs for the file content
kubectl logs pod-volume-items
```
- **Expected Result**: `mysql`

### Task 5 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-subpath --timeout=60s

# Exec into the pod and check the nginx config
kubectl exec pod-subpath -- cat /etc/nginx/conf.d/default.conf | grep "server_name"
```
- **Expected Result**: `    server_name localhost;`

### Task 6 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-cmd-args --timeout=60s

# Check the logs
kubectl logs pod-cmd-args
```
- **Expected Result**: `Starting application in production mode.`

### Task 7 Verification
```bash
# Wait for the deployment to be ready
kubectl rollout status deployment/deployment-autoupdate

# Check the initial logs
kubectl logs deployment/deployment-autoupdate
# Expected Result: The log should repeatedly print "blue".

# In a separate terminal, patch the ConfigMap
kubectl patch configmap app-config --patch '{"data":{"APP_COLOR":"green"}}'

# Observe the logs again after a minute
kubectl logs deployment/deployment-autoupdate
```
- **Expected Result**: After a short delay (up to a minute), the logs should start printing `green`, demonstrating the automatic update.

### Task 8 Verification
```bash
# Wait for the Pod to be running
kubectl wait --for=condition=Ready pod/pod-env-precedence --timeout=60s

# Check the logs
kubectl logs pod-env-precedence
```
- **Expected Result**: `The final application color is red`

## Cleanup Commands
Run these commands to delete all the resources created in this scenario.
```bash
kubectl delete pod pod-env-single-key pod-env-from pod-volume-full pod-volume-items pod-subpath pod-cmd-args pod-env-precedence --now
kubectl delete deployment deployment-autoupdate
kubectl delete configmap app-config db-config nginx-config
rm nginx.conf
```

## Key Learning Points
- **`valueFrom.configMapKeyRef`**: Consumes a single key as an environment variable.
- **`envFrom.configMapRef`**: Consumes all keys from a ConfigMap as environment variables.
- **Volume Mounts**: Project a ConfigMap into a directory, where each key becomes a file.
- **`items` in Volumes**: Allows selective mounting of keys and renaming them.
- **`subPath`**: Injects a single key as a file into an existing directory without overwriting it.
- **Update Propagation**: Volume-mounted ConfigMaps are updated automatically, while environment variables are not and require a Pod restart.
- **Precedence**: Environment variables defined in `env` override those from `envFrom`.

## Exam & Troubleshooting Tips
- **Efficiency**: For the CKA exam, `kubectl create configmap` is faster than writing YAML. Be proficient with both.
- **Updates**: Remember that environment variables are immutable after a Pod starts. If a task requires configuration to be updated live, you MUST use a volume mount.
- **`subPath` Issues**: A common issue with `subPath` is that updating the ConfigMap does not trigger an update in the Pod. This is a known limitation. If live updates are needed, use a full volume mount.
- **Verification**: Use `kubectl exec <pod> -- env` to check environment variables and `kubectl exec <pod> -- ls <path>` or `cat <path>` to inspect volume-mounted files.