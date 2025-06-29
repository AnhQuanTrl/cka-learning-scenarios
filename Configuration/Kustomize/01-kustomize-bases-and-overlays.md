# Kustomize Bases and Overlays

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal cluster

## Objective
Learn to use Kustomize to manage application configurations across different environments using bases and overlays with patches, ConfigMap and Secret generation, and resource transformations.

## Context
Your development team needs to deploy a web application across three environments: development, staging, and production. Each environment requires different configurations for replicas, resource limits, and application settings. You'll use Kustomize to create a base configuration and environment-specific overlays to manage these variations efficiently.

## Prerequisites
- Running Kubernetes cluster with kubectl access
- Basic understanding of Deployments, Services, and ConfigMaps
- kubectl version 1.14+ (includes Kustomize support)

## Tasks

### Task 1: Create Base Application Resources (10 minutes)
Create the base directory structure and core application manifests that will be shared across all environments.

**Step 1a**: Create the base directory and application deployment:
```bash
mkdir -p ~/kustomize-demo/base
cd ~/kustomize-demo/base
```

**Step 1b**: Create the base deployment manifest with exact content:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: log-level
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
        volumeMounts:
        - name: app-config-volume
          mountPath: /etc/config
        - name: app-secrets-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: app-config-volume
        configMap:
          name: app-config
      - name: app-secrets-volume
        secret:
          secretName: app-secrets
```

**Step 1c**: Create the base service manifest:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  labels:
    app: web-app
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

**Step 1d**: Create configuration files for ConfigMap generation:
```bash
# Create app.properties file
cat > app.properties << 'EOF'
database.host=localhost
database.port=5432
cache.enabled=true
cache.ttl=300
max.connections=100
EOF

# Create logging.conf file
cat > logging.conf << 'EOF'
[loggers]
keys=root

[handlers]  
keys=consoleHandler

[formatters]
keys=simpleFormatter

[logger_root]
level=INFO
handlers=consoleHandler

[handler_consoleHandler]
class=StreamHandler
level=INFO
formatter=simpleFormatter
args=(sys.stdout,)

[formatter_simpleFormatter]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
EOF
```

**Step 1e**: Create base secret files for Secret generation:
```bash
# Create base database credentials file
cat > database-base.env << 'EOF'
database-password=basic_password_123
api-key=base_api_key_456
jwt-secret=base_jwt_secret_789
EOF

# Create TLS certificate files (base64 encoded for demonstration)
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t" > tls.crt
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t" > tls.key
```

**Step 1f**: Create the base kustomization.yaml file:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: web-app-base

resources:
- deployment.yaml
- service.yaml

configMapGenerator:
- name: app-config
  literals:
  - environment=base
  - log-level=info
  files:
  - app.properties
  - logging.conf

secretGenerator:
- name: app-secrets
  envs:
  - database-base.env
- name: tls-secrets
  files:
  - tls.crt
  - tls.key
  type: kubernetes.io/tls

commonLabels:
  team: platform
  version: v1.0.0

images:
- name: nginx
  newTag: "1.21"
```

### Task 2: Create Development Environment Overlay (8 minutes)
Create a development environment overlay that increases logging verbosity and uses fewer resources.

**Step 2a**: Create the development overlay directory structure:
```bash
mkdir -p ~/kustomize-demo/overlays/development
cd ~/kustomize-demo/overlays/development
```

**Step 2b**: Create a patch to modify replica count and resources for development:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: web-app
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
```

**Step 2c**: Create development-specific secret files:
```bash
# Create development database credentials
cat > database-dev.env << 'EOF'
database-password=dev_password_secure_123
api-key=dev_api_key_xyz789
jwt-secret=dev_jwt_long_secret_string_456
EOF
```

**Step 2d**: Create the development kustomization.yaml:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: web-app-development

namespace: development

resources:
- ../../base

patches:
- path: deployment-patch.yaml

configMapGenerator:
- name: app-config
  behavior: merge
  literals:
  - environment=development
  - log-level=debug

secretGenerator:
- name: app-secrets
  behavior: replace
  envs:
  - database-dev.env
  literals:
  - debug-token=dev_debug_token_123

namePrefix: dev-

commonLabels:
  environment: development
```

### Task 3: Create Staging Environment Overlay (10 minutes)
Create a staging environment overlay with production-like settings but additional monitoring labels.

**Step 3a**: Create the staging overlay directory:
```bash
mkdir -p ~/kustomize-demo/overlays/staging
cd ~/kustomize-demo/overlays/staging
```

**Step 3b**: Create a JSON patch for advanced resource modifications:
```yaml
- op: replace
  path: /spec/replicas
  value: 3
- op: add
  path: /spec/template/metadata/annotations
  value:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
- op: replace
  path: /spec/template/spec/containers/0/resources/limits/memory
  value: "256Mi"
- op: replace
  path: /spec/template/spec/containers/0/resources/limits/cpu
  value: "1000m"
```

**Step 3c**: Create staging-specific ConfigMap content:
```bash
cat > database-staging.properties << 'EOF'
database.host=staging-db.example.com
database.port=5432
database.ssl=true
cache.enabled=true
cache.ttl=600
max.connections=200
monitoring.enabled=true
EOF
```

**Step 3d**: Create staging-specific secret files:
```bash
# Create staging database credentials
cat > database-staging.env << 'EOF'
database-password=staging_complex_password_456
api-key=staging_api_key_secure_789
jwt-secret=staging_jwt_complex_secret_string_123
oauth-client-secret=staging_oauth_secret_456
EOF

# Create staging certificates
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tU1RBR0lORw==" > staging-tls.crt
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tU1RBR0lORw==" > staging-tls.key
```

**Step 3e**: Create the staging kustomization.yaml:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: web-app-staging

namespace: staging

resources:
- ../../base

patches:
- target:
    kind: Deployment
    name: web-app
  path: deployment-patch.json

configMapGenerator:
- name: app-config
  behavior: replace
  literals:
  - environment=staging
  - log-level=warn
  files:
  - database-staging.properties

secretGenerator:
- name: app-secrets
  behavior: replace
  envs:
  - database-staging.env
- name: tls-secrets
  behavior: replace
  files:
  - tls.crt=staging-tls.crt
  - tls.key=staging-tls.key
  type: kubernetes.io/tls

namePrefix: staging-

commonLabels:
  environment: staging
  monitoring: enabled

commonAnnotations:
  managed-by: kustomize
  contact: staging-team@example.com
```

### Task 4: Create Production Environment Overlay (12 minutes)
Create a production environment overlay with high availability configuration and strict resource limits.

**Step 4a**: Create the production overlay directory:
```bash
mkdir -p ~/kustomize-demo/overlays/production
cd ~/kustomize-demo/overlays/production
```

**Step 4b**: Create a comprehensive strategic merge patch for production:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - web-app
              topologyKey: kubernetes.io/hostname
      containers:
      - name: web-app
        resources:
          requests:
            memory: "128Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Step 4c**: Create a service patch for production LoadBalancer:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  - port: 443
    targetPort: 80
    protocol: TCP
    name: https
```

**Step 4d**: Create production-specific configuration files:
```bash
cat > database-prod.properties << 'EOF'
database.host=prod-db-cluster.example.com
database.port=5432
database.ssl=true
database.ssl-mode=require
cache.enabled=true
cache.ttl=900
cache.cluster=redis-cluster.example.com:6379
max.connections=500
connection.pool.min=50
connection.pool.max=200
monitoring.enabled=true
metrics.export.interval=30
EOF

cat > security.properties << 'EOF'
security.enabled=true
auth.method=jwt
jwt.secret.key=production-secret-key
cors.allowed.origins=https://app.example.com
rate.limiting.enabled=true
rate.limit.requests.per.minute=1000
EOF
```

**Step 4e**: Create production-specific secret files:
```bash
# Create production database credentials (stronger passwords)
cat > database-prod.env << 'EOF'
database-password=prod_ultra_secure_password_XyZ789!@#
api-key=prod_api_key_complex_AbC123$%^
jwt-secret=prod_jwt_very_long_complex_secret_string_789!@#$%^
oauth-client-secret=prod_oauth_complex_secret_XyZ456!@#
encryption-key=prod_encryption_key_ultra_secure_789!@#$%^&*
EOF

# Create production certificates
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tUFJPRFVDVElPTg==" > prod-tls.crt
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tUFJPRFVDVElPTg==" > prod-tls.key

# Create production monitoring credentials
cat > monitoring-prod.env << 'EOF'
prometheus-password=prod_prometheus_secure_pass_123
grafana-admin-password=prod_grafana_admin_complex_456
alertmanager-webhook-secret=prod_alert_webhook_secret_789
EOF
```

**Step 4f**: Create the production kustomization.yaml:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: web-app-production

namespace: production

resources:
- ../../base

patches:
- path: deployment-patch.yaml
- path: service-patch.yaml

configMapGenerator:
- name: app-config
  behavior: replace
  literals:
  - environment=production
  - log-level=error
  files:
  - database-prod.properties
  - security.properties

secretGenerator:
- name: app-secrets
  behavior: replace
  envs:
  - database-prod.env
- name: tls-secrets
  behavior: replace
  files:
  - tls.crt=prod-tls.crt
  - tls.key=prod-tls.key
  type: kubernetes.io/tls
- name: monitoring-secrets
  envs:
  - monitoring-prod.env
  options:
    disableNameSuffixHash: false

namePrefix: prod-

commonLabels:
  environment: production
  tier: frontend
  cost-center: engineering

commonAnnotations:
  managed-by: kustomize
  contact: sre-team@example.com
  backup: required

images:
- name: nginx
  newTag: "1.21.6"
```

### Task 5: Deploy and Test All Environments (5 minutes)
Apply the Kustomize configurations to deploy applications across all environments and verify the customizations.

**Step 5a**: Create the namespaces and deploy all environments:
```bash
cd ~/kustomize-demo

# Create namespaces
kubectl create namespace development
kubectl create namespace staging  
kubectl create namespace production

# Deploy to each environment
kubectl apply -k overlays/development
kubectl apply -k overlays/staging
kubectl apply -k overlays/production
```

**Step 5b**: Verify that each environment has the correct customizations by checking replica counts, resource limits, and ConfigMap contents for each deployment.

## Verification Commands

### Verify Development Environment
```bash
# Check deployment replicas and resources
kubectl get deployment -n development -o jsonpath='{.items[0].spec.replicas}'
kubectl get deployment -n development -o jsonpath='{.items[0].spec.template.spec.containers[0].resources}'

# Check ConfigMap content
kubectl get configmap -n development -o jsonpath='{.items[?(@.metadata.name=="dev-app-config")].data}'

# Check Secret content (base64 decoded)
kubectl get secret -n development -o jsonpath='{.items[?(@.metadata.name=="dev-app-secrets")].data.database-password}' | base64 -d
kubectl get secret -n development -o jsonpath='{.items[?(@.metadata.name=="dev-app-secrets")].data.debug-token}' | base64 -d

# Verify labels and naming
kubectl get all -n development --show-labels
```

### Verify Staging Environment  
```bash
# Check deployment replicas and annotations
kubectl get deployment -n staging -o jsonpath='{.items[0].spec.replicas}'
kubectl get deployment -n staging -o jsonpath='{.items[0].spec.template.metadata.annotations}'

# Check ConfigMap content
kubectl get configmap -n staging -o jsonpath='{.items[?(@.metadata.name=="staging-app-config")].data}'

# Check Secret content
kubectl get secret -n staging -o jsonpath='{.items[?(@.metadata.name=="staging-app-secrets")].data.oauth-client-secret}' | base64 -d

# Verify TLS secret type
kubectl get secret -n staging -o jsonpath='{.items[?(@.metadata.name=="staging-tls-secrets")].type}'

# Verify resource limits
kubectl get deployment -n staging -o jsonpath='{.items[0].spec.template.spec.containers[0].resources.limits}'
```

### Verify Production Environment
```bash
# Check deployment replicas and anti-affinity
kubectl get deployment -n production -o jsonpath='{.items[0].spec.replicas}'
kubectl get deployment -n production -o jsonpath='{.items[0].spec.template.spec.affinity}'

# Check service type
kubectl get service -n production -o jsonpath='{.items[0].spec.type}'

# Check probes configuration
kubectl get deployment -n production -o jsonpath='{.items[0].spec.template.spec.containers[0].livenessProbe}'

# Check production secrets
kubectl get secret -n production -o jsonpath='{.items[?(@.metadata.name=="prod-app-secrets")].data.encryption-key}' | base64 -d
kubectl get secret -n production -o jsonpath='{.items[?(@.metadata.name=="prod-monitoring-secrets")].data.prometheus-password}' | base64 -d

# Verify multiple secret types
kubectl get secrets -n production -o custom-columns=NAME:.metadata.name,TYPE:.type

# Verify image tag
kubectl get deployment -n production -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```

### Verify Cross-Environment Differences
```bash
# Compare replica counts across environments
kubectl get deployments --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas | grep web-app

# Compare ConfigMap content across environments
for ns in development staging production; do
  echo "=== $ns environment ==="
  kubectl get configmap -n $ns -o jsonpath='{.items[0].data.environment}{"\n"}'
  kubectl get configmap -n $ns -o jsonpath='{.items[0].data.log-level}{"\n"}'
done

# Compare Secret content across environments  
for ns in development staging production; do
  echo "=== $ns environment secrets ==="
  kubectl get secrets -n $ns --no-headers | grep -v default-token
  echo "Database password length:"
  kubectl get secret -n $ns -o jsonpath='{.items[?(@.metadata.name~".*app-secrets")].data.database-password}' | base64 -d | wc -c
done
```

## Expected Results
- **Development namespace**: 1 replica deployment with debug logging, reduced resources, dev- prefix, debug-token secret
- **Staging namespace**: 3 replica deployment with monitoring annotations, warn logging, staging- prefix, OAuth secrets, TLS secrets
- **Production namespace**: 5 replica deployment with anti-affinity, LoadBalancer service, error logging, prod- prefix, monitoring secrets, TLS secrets
- **ConfigMaps**: Each environment has different configuration values reflecting environment-specific settings
- **Secrets**: Progressive complexity from development (basic secrets + debug token) to staging (OAuth + TLS) to production (monitoring + encryption keys)
- **Secret types**: Opaque secrets for credentials, kubernetes.io/tls secrets for certificates
- **Resource limits**: Progressive increase from development (64Mi/200m) to staging (256Mi/1000m) to production (512Mi/2000m)
- **Labels and annotations**: Environment-specific labels and annotations applied consistently

## Key Learning Points
- **Kustomize structure**: Understanding base configurations and environment-specific overlays
- **Patch strategies**: Using strategic merge patches and JSON patches for different modification needs
- **ConfigMap generation**: Creating environment-specific configurations using literals and files
- **Secret generation**: Managing sensitive data with secretGenerator using literals, files, and envs
- **Secret types**: Creating different secret types including Opaque and kubernetes.io/tls
- **Secret behaviors**: Using merge, replace, and create behaviors for environment-specific secrets
- **Resource transformation**: Applying common labels, annotations, name prefixes, and namespaces
- **Image management**: Overriding image tags in different environments
- **Configuration inheritance**: How overlays inherit and modify base configurations

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Kustomize syntax**: Remember `kubectl apply -k <directory>` instead of `-f` for Kustomize
- **Patch validation**: Use `kubectl kustomize <directory>` to preview generated manifests before applying
- **Common fields**: Focus on configMapGenerator, secretGenerator, patches, namePrefix, commonLabels for exam scenarios
- **Secret generation**: Know secretGenerator with literals, files, envs, and type fields
- **File organization**: Understand the base/overlays directory structure pattern

### Troubleshooting Tips
- **Patch conflicts**: When patches fail, check that target resource names and paths exist in base
- **ConfigMap merging**: Use `behavior: merge` or `behavior: replace` explicitly to control ConfigMap generation
- **Secret generation**: Use `behavior: replace` to override base secrets completely in overlays
- **Secret file paths**: Verify all files referenced in secretGenerator exist and are readable
- **Secret types**: Remember `type: kubernetes.io/tls` for TLS secrets, defaults to Opaque if not specified
- **Resource references**: Ensure ConfigMap and Secret references match generated names with prefixes
- **Validation errors**: Run `kustomize build` locally to catch YAML syntax issues before kubectl apply
- **Missing resources**: Verify all referenced files in configMapGenerator and secretGenerator exist
- **Base64 encoding**: Kustomize automatically base64 encodes secret data from files and literals
- **Namespace issues**: Check that target namespaces exist before applying overlays that specify them