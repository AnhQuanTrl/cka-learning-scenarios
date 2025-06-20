# ConfigMap Updates, Immutability, and Versioning

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Master ConfigMap update behaviors, leverage immutable ConfigMaps for safety and performance, and implement production-grade versioning and rolling update strategies.

## Context
Your team is building a resilient, zero-downtime application. You must implement a configuration management strategy that prevents accidental changes, allows for safe, automated rollouts, and ensures that applications can reload settings without restarting.

## Prerequisites
- A running k3s cluster.
- `kubectl` access with admin privileges.
- A basic understanding of Deployments and Services.

## Tasks

### Task 1: Create Initial Application Resources
*(Time Suggestion: 3 minutes)*

To begin, create the initial ConfigMap and a simple Nginx Deployment that will consume it. This sets the stage for observing update behaviors.

**Step 1a: Create the application's configuration files.**

Create two files on your local machine.

**`app.properties`**:
```ini
# Application Properties
app.name=ConfigDemo
app.version=1.0.0
log.level=INFO
```

**`index.html`**:
```html
<!DOCTYPE html>
<html>
<head>
    <title>ConfigMap Demo</title>
</head>
<body>
    <h1>Version 1.0.0</h1>
    <p>This is the initial version of the application.</p>
</body>
</html>
```

**Step 1b: Create a ConfigMap from the files.**

Use `kubectl` to create a ConfigMap named **`app-settings-v1`** from the two files you just created.

**Step 1c: Create the Deployment manifest.**

Create a file named `deployment.yaml` with the following content. This Deployment mounts the ConfigMap as both a volume and an environment variable source.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-demo
  template:
    metadata:
      labels:
        app: config-demo
    spec:
      containers:
      - name: web-server
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: app-settings-v1
              key: app.properties
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
          readOnly: true
      volumes:
      - name: web-content
        configMap:
          name: app-settings-v1
          items:
          - key: index.html
            path: index.html
```

**Step 1d: Apply the manifest.**

Use `kubectl apply` to create the Deployment.

---

### Task 2: Observe a Volume-Mounted ConfigMap Update
*(Time Suggestion: 3 minutes)*

Test how changes to a ConfigMap are automatically propagated to pods when the ConfigMap is mounted as a volume.

**Step 2a: Update the ConfigMap data.**

Patch the **`app-settings-v1`** ConfigMap to change the content of `index.html`.

```bash
kubectl patch configmap app-settings-v1 --patch '{"data":{"index.html":"<!DOCTYPE html><html><body><h1>Version 1.1.0</h1><p>Content updated via volume mount!</p></body></html>"}}'
```

**Hint**: This change will be reflected in the mounted file inside the container automatically. The delay is typically around 30-60 seconds.

---

### Task 3: Observe Environment Variable Update Behavior
*(Time Suggestion: 2 minutes)*

Now, observe that environment variables sourced from a ConfigMap **do not** update automatically when the ConfigMap changes.

**Step 3a: Update the ConfigMap data again.**

Patch the **`app-settings-v1`** ConfigMap to change the `app.properties` data.

```bash
kubectl patch configmap app-settings-v1 --patch '{"data":{"app.properties":"app.version=2.0.0"}}'
```

**Step 3b: Check the environment variable.**

Exec into the running pod and check the value of the `APP_VERSION` environment variable. You will find it has not changed. This is because environment variables are injected only when a pod starts.

---

### Task 4: Create an Immutable ConfigMap
*(Time Suggestion: 2 minutes)*

For critical configuration that should never change, create an immutable ConfigMap. This prevents accidental modifications.

**Step 4a: Create an immutable ConfigMap manifest.**

Create a file named `immutable-cm.yaml` with the following content.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-credentials
data:
  database.host: "prod-db.example.com"
  database.user: "readonly"
immutable: true
```

**Step 4b: Apply the manifest.**

Use `kubectl apply` to create the immutable ConfigMap.

**Step 4c: Attempt to modify the ConfigMap.**

Try to patch the **`db-credentials`** ConfigMap. The API server will reject this request because the object is immutable.

```bash
kubectl patch configmap db-credentials --patch '{"data":{"database.user":"admin"}}'
```

---

### Task 5: Trigger a Rolling Update with a New ConfigMap
*(Time Suggestion: 4 minutes)*

The correct way to "update" a configuration used by a Deployment, especially when using immutable ConfigMaps, is to create a new ConfigMap and roll out a new version of the Deployment.

**Step 5a: Create a new version of the ConfigMap.**

Create a file named `app-settings-v2-cm.yaml` with updated application settings.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings-v2
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
        <h1>Version 2.0.0</h1>
        <p>This is the new, updated version of the application!</p>
    </body>
    </html>
  app.properties: |
    app.name=ConfigDemo
    app.version=2.0.0
    log.level=DEBUG
```

**Step 5b: Apply the new ConfigMap.**

Use `kubectl apply` to create **`app-settings-v2`**.

**Step 5c: Update the Deployment to use the new ConfigMap.**

Patch the **`config-demo-app`** Deployment to reference **`app-settings-v2`** in its volumes and environment variables. This change will trigger a rolling update.

```bash
kubectl patch deployment config-demo-app --patch '{"spec":{"template":{"spec":{"volumes":[{"name":"web-content","configMap":{"name":"app-settings-v2"}}],"containers":[{"name":"web-server","env":[{"name":"APP_VERSION","valueFrom":{"configMapKeyRef":{"name":"app-settings-v2","key":"app.properties"}}}]}]}}}}'
```

---

### Task 6: Trigger a Rolling Update via Annotations
*(Time Suggestion: 4 minutes)*

Another common pattern is to trigger a rolling update by changing a pod template annotation, often using a hash of the ConfigMap's data. This ensures a rollout happens every time the configuration changes.

**Step 6a: Calculate the checksum of the ConfigMap.**

Calculate the SHA256 checksum of the **`app-settings-v2`** data and store it in an environment variable.

```bash
CONFIG_HASH=$(kubectl get configmap app-settings-v2 -o yaml | sha256sum | cut -d' ' -f1)
```

**Step 6b: Add the checksum as an annotation.**

Patch the **`config-demo-app`** Deployment to add a `config/checksum` annotation to its pod template.

```bash
kubectl patch deployment config-demo-app --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"config/checksum\":\"$CONFIG_HASH\"}}}}}"
```

**Step 6c: Simulate a configuration change and trigger a new rollout.**

First, create a new version of the ConfigMap, **`app-settings-v3`**.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings-v3
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
        <h1>Version 3.0.0</h1>
        <p>A new feature release!</p>
    </body>
    </html>
```

Apply it, then update the Deployment to point to it. Finally, calculate the new hash and patch the annotation again to trigger the rollout.

```bash
# Create v3
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings-v3
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <body>
        <h1>Version 3.0.0</h1>
        <p>A new feature release!</p>
    </body>
    </html>
EOF

# Update Deployment to use v3
kubectl patch deployment config-demo-app --patch '{"spec":{"template":{"spec":{"volumes":[{"name":"web-content","configMap":{"name":"app-settings-v3"}}]}}}}'

# Calculate new hash and patch annotation to trigger rollout
NEW_CONFIG_HASH=$(kubectl get configmap app-settings-v3 -o yaml | sha256sum | cut -d' ' -f1)
kubectl patch deployment config-demo-app --patch "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"config/checksum\":\"$NEW_CONFIG_HASH\"}}}}}"
```

---

## Verification Commands

### Task 1: Verification
Verify that the initial resources were created successfully.

**Command**:
```bash
kubectl get configmap app-settings-v1 && kubectl get deployment config-demo-app
```
**Expected Result**:
The command should list the `app-settings-v1` ConfigMap and the `config-demo-app` Deployment.

**Command**:
```bash
kubectl rollout status deployment/config-demo-app
```
**Expected Result**:
The command should output `deployment "config-demo-app" successfully rolled out`.

**Command**:
```bash
# Exec into the pod and check the mounted file content
POD_NAME=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- cat /usr/share/nginx/html/index.html
```
**Expected Result**:
The HTML content should show "Version 1.0.0".

---

### Task 2: Verification
Verify that the volume-mounted file was updated automatically.

**Command**:
```bash
# Wait a moment for the update to propagate
sleep 45
POD_NAME=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- cat /usr/share/nginx/html/index.html
```
**Expected Result**:
The HTML content should now show "Version 1.1.0" and "Content updated via volume mount!".

---

### Task 3: Verification
Verify that the environment variable inside the container did **not** change.

**Command**:
```bash
POD_NAME=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- printenv APP_VERSION
```
**Expected Result**:
The output should still be `app.version=1.0.0`, not `2.0.0`. This confirms environment variables are not updated live.

---

### Task 4: Verification
Verify that the immutable ConfigMap was created and cannot be changed.

**Command**:
```bash
kubectl describe configmap db-credentials | grep 'Immutable'
```
**Expected Result**:
The output should show `Immutable:  true`.

**Command**:
```bash
kubectl patch configmap db-credentials --patch '{"data":{"database.user":"admin"}}'
```
**Expected Result**:
The command will fail with an error message stating that the ConfigMap is immutable.
`The ConfigMap "db-credentials" is invalid: data: Forbidden: field is immutable when `immutable` is set`

---

### Task 5: Verification
Verify that the Deployment was updated to use the new ConfigMap.

**Command**:
```bash
kubectl rollout status deployment/config-demo-app
```
**Expected Result**:
The command should report a successful rollout.

**Command**:
```bash
# Check the new pod's mounted content
NEW_POD_NAME=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $NEW_POD_NAME -- cat /usr/share/nginx/html/index.html
```
**Expected Result**:
The HTML content should now show "Version 2.0.0".

---

### Task 6: Verification
Verify that the annotation was added and that the final rollout was successful.

**Command**:
```bash
kubectl get deployment config-demo-app -o yaml | grep -A 1 "annotations:"
```
**Expected Result**:
You should see the `config/checksum` annotation with a SHA256 hash value.

**Command**:
```bash
kubectl rollout status deployment/config-demo-app
```
**Expected Result**:
The command should report a successful rollout to the latest version.

**Command**:
```bash
# Check the final pod's mounted content
FINAL_POD_NAME=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl exec $FINAL_POD_NAME -- cat /usr/share/nginx/html/index.html
```
**Expected Result**:
The HTML content should now show "Version 3.0.0".

---

## Expected Results
- A Deployment named `config-demo-app` is running.
- ConfigMaps `app-settings-v1`, `app-settings-v2`, `app-settings-v3`, and `db-credentials` exist.
- The `db-credentials` ConfigMap is immutable.
- The final running pod for the Deployment is mounting data from `app-settings-v3`.
- The Deployment's pod template has a `config/checksum` annotation.

## Key Learning Points
- **Volume Mounts**: ConfigMaps mounted as volumes are updated dynamically within pods. This is ideal for configuration files that applications can reload.
- **Environment Variables**: ConfigMaps consumed as environment variables are **not** updated automatically. A pod restart is required to inject new values.
- **Immutability**: Setting `immutable: true` on a ConfigMap prevents any changes to its data, providing a strong guarantee against accidental configuration drift. This is a best practice for production.
- **Rolling Updates**: The standard pattern for updating application configuration is to create a new, versioned ConfigMap and trigger a rolling update on the Deployment to adopt it.
- **Annotation-Triggered Rollouts**: Adding or changing an annotation in a Deployment's pod template is a common and effective way to programmatically trigger a rolling update, often used in CI/CD pipelines with a hash of the ConfigMap content.

## Exam & Troubleshooting Tips
- **Exam Tip**: You will almost certainly be asked to create a ConfigMap and consume it in a pod, either as a volume or an environment variable. Know the syntax for both.
- **Update Lag**: Remember that volume-mounted ConfigMap updates are not instantaneous. The kubelet checks for changes periodically. Don't be alarmed if your verification command doesn't show the update for up to a minute.
- **Immutable Errors**: If you need to change an immutable ConfigMap, you can't. You must delete it and recreate it, or (more safely) create a new version and update your workloads to point to the new one.
- **Rolling Update Not Triggering?**: If a rolling update doesn't start after you patch a Deployment, ensure you patched the **pod template** (`spec.template`), not just the top-level `spec`. Any change to the pod template will trigger a rollout.