# Kustomize Components and Advanced Transformations

## Scenario Overview
- **Time Limit**: 60 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal cluster

## Objective
Master Kustomize components to create reusable, modular configuration packages and apply advanced transformations including variable substitutions, multi-base compositions, conditional feature enablement, and sophisticated secret management patterns.

## Context
Your organization is building a multi-tenant SaaS platform where different customers require different feature sets. You need to create a modular deployment system using Kustomize components that allows selectively enabling features like external databases, LDAP authentication, monitoring stack, and premium features. Each tenant deployment should be able to mix and match these components based on their subscription tier.

## Prerequisites
- Running Kubernetes cluster with kubectl access
- kubectl version 1.21+ (for full component support)
- Understanding of Kustomize bases and overlays
- Familiarity with ConfigMaps, Secrets, and StatefulSets

## Tasks

### Task 1: Create Base Application Platform (12 minutes)
Create the core platform application that will serve as the foundation for all tenant deployments.

**Step 1a**: Create the base directory structure:
```bash
mkdir -p ~/kustomize-components/base
cd ~/kustomize-components/base
```

**Step 1b**: Create the main application deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: saas-app
  labels:
    app: saas-app
    component: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: saas-app
  template:
    metadata:
      labels:
        app: saas-app
        component: web
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: APP_MODE
          value: "basic"
        - name: DATABASE_TYPE
          value: "sqlite"
        - name: AUTH_METHOD
          value: "local"
        - name: FEATURES_ENABLED
          value: "basic"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        volumeMounts:
        - name: app-config
          mountPath: /etc/app/config
        - name: data-storage
          mountPath: /var/lib/app/data
      volumes:
      - name: app-config
        configMap:
          name: app-config
      - name: data-storage
        emptyDir: {}
```

**Step 1c**: Create the base service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: saas-app-service
  labels:
    app: saas-app
spec:
  selector:
    app: saas-app
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  type: ClusterIP
```

**Step 1d**: Create base configuration files:
```bash
# Create basic app configuration
cat > app-basic.conf << 'EOF'
[app]
mode=basic
debug=false
max_connections=100
session_timeout=3600
data_retention_days=30

[features]
user_management=true
basic_reporting=true
api_access=false
advanced_analytics=false

[storage]
type=local
path=/var/lib/app/data
backup=false
EOF

# Create logging configuration
cat > logging.conf << 'EOF'
[loggers]
keys=root,app

[handlers]
keys=consoleHandler

[formatters]
keys=simpleFormatter

[logger_root]
level=INFO
handlers=consoleHandler

[logger_app]  
level=INFO
handlers=consoleHandler
qualname=app

[handler_consoleHandler]
class=StreamHandler
level=INFO
formatter=simpleFormatter
args=(sys.stdout,)

[formatter_simpleFormatter]
format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
EOF
```

**Step 1e**: Create the base kustomization.yaml:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: saas-platform-base

resources:
- deployment.yaml
- service.yaml

configMapGenerator:
- name: app-config
  files:
  - app-basic.conf
  - logging.conf

secretGenerator:
- name: base-secrets
  literals:
  - default-admin-password=basic_admin_pass_123
  - session-secret=basic_session_secret_456
- name: jwt-secrets
  literals:
  - jwt-signing-key=basic_jwt_signing_key_789
  - jwt-refresh-key=basic_jwt_refresh_key_abc

commonLabels:
  platform: saas
  tier: application
```

### Task 2: Create External Database Component (10 minutes)
Create a reusable component that adds external database support to any deployment.

**Step 2a**: Create the external database component directory:
```bash
mkdir -p ~/kustomize-components/components/external-database
cd ~/kustomize-components/components/external-database
```

**Step 2b**: Create database credentials secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
type: Opaque
stringData:
  username: app_user
  password: secure_password_123
  host: postgresql.database.svc.cluster.local
  port: "5432"
  database: saas_platform
  ssl_mode: require
```

**Step 2c**: Create database configuration:
```bash
cat > database-external.conf << 'EOF'
[database]
type=postgresql
host=${DB_HOST}
port=${DB_PORT}
database=${DB_NAME}
username=${DB_USER}
password=${DB_PASSWORD}
ssl_mode=${DB_SSL_MODE}
connection_pool_min=5
connection_pool_max=50
connection_timeout=30
query_timeout=60
retry_attempts=3

[migrations]
auto_migrate=true
migration_path=/app/migrations
EOF
```

**Step 2d**: Create deployment patch for database integration:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: saas-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DATABASE_TYPE
          value: "postgresql"
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: host
        - name: DB_PORT
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: port
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: password
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: database
        - name: DB_SSL_MODE
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: ssl_mode
        volumeMounts:
        - name: database-config
          mountPath: /etc/database
      volumes:
      - name: database-config
        configMap:
          name: database-config
```

**Step 2e**: Create database certificate files for secure connections:
```bash
# Create database CA and client certificates (base64 encoded for demonstration)
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tREFUQUJBU0UgQ0E=" > ca-cert.pem
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tQ0xJRU5UIENFUlQ=" > client-cert.pem
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tQ0xJRU5UIEtFWQ==" > client-key.pem
```

**Step 2f**: Create the external database component kustomization:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Component

metadata:
  name: external-database

resources:
- secret.yaml

configMapGenerator:
- name: database-config
  files:
  - database-external.conf

secretGenerator:
- name: database-ca-certs
  files:
  - ca-cert.pem
  - client-cert.pem
  - client-key.pem
  type: Opaque
- name: database-migration-secrets
  literals:
  - migration-user=db_migration_user
  - migration-password=secure_migration_pass_789

patches:
- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: saas-app

commonLabels:
  database: external
```

### Task 3: Create LDAP Authentication Component (10 minutes)
Create a component that adds LDAP authentication capabilities.

**Step 3a**: Create the LDAP component directory:
```bash
mkdir -p ~/kustomize-components/components/ldap-auth
cd ~/kustomize-components/components/ldap-auth
```

**Step 3b**: Create LDAP configuration secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ldap-config
type: Opaque
stringData:
  server: ldap://ldap.company.com:389
  bind_dn: cn=app,ou=services,dc=company,dc=com
  bind_password: ldap_service_password
  base_dn: ou=users,dc=company,dc=com
  user_filter: (&(objectClass=person)(uid=%s))
  group_filter: (&(objectClass=groupOfNames)(member=%s))
  tls_enabled: "true"
  tls_skip_verify: "false"
```

**Step 3c**: Create LDAP configuration file:
```bash
cat > ldap-auth.conf << 'EOF'
[ldap]
server=${LDAP_SERVER}
bind_dn=${LDAP_BIND_DN}
bind_password=${LDAP_BIND_PASSWORD}
base_dn=${LDAP_BASE_DN}
user_filter=${LDAP_USER_FILTER}
group_filter=${LDAP_GROUP_FILTER}
tls_enabled=${LDAP_TLS_ENABLED}
tls_skip_verify=${LDAP_TLS_SKIP_VERIFY}
connection_timeout=10
search_timeout=30
page_size=100

[auth]
method=ldap
session_timeout=7200
remember_me_timeout=86400
max_login_attempts=5
lockout_duration=900

[groups]
admin_group=cn=admins,ou=groups,dc=company,dc=com
user_group=cn=users,ou=groups,dc=company,dc=com
readonly_group=cn=readonly,ou=groups,dc=company,dc=com
EOF
```

**Step 3d**: Create deployment patch for LDAP integration:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: saas-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: AUTH_METHOD
          value: "ldap"
        - name: LDAP_SERVER
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: server
        - name: LDAP_BIND_DN
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: bind_dn
        - name: LDAP_BIND_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: bind_password
        - name: LDAP_BASE_DN
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: base_dn
        - name: LDAP_USER_FILTER
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: user_filter
        - name: LDAP_GROUP_FILTER
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: group_filter
        - name: LDAP_TLS_ENABLED
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: tls_enabled
        - name: LDAP_TLS_SKIP_VERIFY
          valueFrom:
            secretKeyRef:
              name: ldap-config
              key: tls_skip_verify
        volumeMounts:
        - name: ldap-config
          mountPath: /etc/ldap
      volumes:
      - name: ldap-config
        configMap:
          name: ldap-config
```

**Step 3e**: Create LDAP certificate files:
```bash
# Create LDAP CA and client certificates
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tTERBUCBDQQ==" > ldap-ca.crt
echo "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tTERBUCBDTElFTlQ=" > ldap-client.crt
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tTERBUCBDTElFTlQ=" > ldap-client.key
```

**Step 3f**: Create the LDAP component kustomization:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Component

metadata:
  name: ldap-authentication

resources:
- secret.yaml

configMapGenerator:
- name: ldap-config
  files:
  - ldap-auth.conf

secretGenerator:
- name: ldap-ca-certs
  files:
  - ldap-ca.crt
  - ldap-client.crt
  - ldap-client.key
  type: Opaque
- name: ldap-service-account
  literals:
  - service-account-dn=cn=ldap-service,ou=services,dc=company,dc=com
  - service-account-password=ldap_service_secure_password_123

patches:
- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: saas-app

commonLabels:
  auth: ldap
```

### Task 4: Create Monitoring Component (8 minutes)
Create a component that adds comprehensive monitoring and observability.

**Step 4a**: Create the monitoring component directory:
```bash
mkdir -p ~/kustomize-components/components/monitoring
cd ~/kustomize-components/components/monitoring
```

**Step 4b**: Create ServiceMonitor for Prometheus:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: saas-app-metrics
  labels:
    app: saas-app
spec:
  selector:
    matchLabels:
      app: saas-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    honorLabels: true
```

**Step 4c**: Create monitoring configuration:
```bash
cat > monitoring.conf << 'EOF'
[metrics]
enabled=true
port=9090
path=/metrics
interval=30
detailed_metrics=true

[logging]
level=debug
structured=true
output=json
include_stack_trace=true

[tracing]
enabled=true
sampling_rate=0.1
exporter=jaeger
jaeger_endpoint=http://jaeger-collector:14268/api/traces

[health_checks]
enabled=true
readiness_path=/ready
liveness_path=/health
startup_path=/startup
EOF
```

**Step 4d**: Create deployment patch for monitoring:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: saas-app
  labels:
    monitoring: enabled  
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        env:
        - name: MONITORING_ENABLED
          value: "true"
        - name: METRICS_PORT
          value: "9090"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 30
        volumeMounts:
        - name: monitoring-config
          mountPath: /etc/monitoring
      volumes:
      - name: monitoring-config
        configMap:
          name: monitoring-config
```

**Step 4e**: Create the monitoring component kustomization:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Component

metadata:
  name: monitoring-stack

resources:
- servicemonitor.yaml

configMapGenerator:
- name: monitoring-config
  files:
  - monitoring.conf

secretGenerator:
- name: monitoring-credentials
  literals:
  - prometheus-basic-auth-user=monitoring_user
  - prometheus-basic-auth-password=secure_monitoring_pass_123
  - grafana-admin-password=grafana_admin_secure_456
- name: alerting-webhooks
  literals:
  - slack-webhook-url=https://hooks.slack.com/services/monitoring/webhook/secret
  - pagerduty-integration-key=monitoring_pagerduty_key_789
  - email-smtp-password=smtp_monitoring_password_456

patches:
- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: saas-app

commonLabels:
  monitoring: enabled
```

### Task 5: Create Premium Features Component (8 minutes)
Create a component that enables premium features like advanced analytics and API access.

**Step 5a**: Create the premium features component directory:
```bash
mkdir -p ~/kustomize-components/components/premium-features
cd ~/kustomize-components/components/premium-features
```

**Step 5b**: Create premium features configuration:
```bash
cat > premium-features.conf << 'EOF'
[features]
advanced_analytics=true
api_access=true
custom_branding=true
priority_support=true
advanced_reporting=true
export_functionality=true
webhook_integrations=true
sso_integration=true

[analytics]
retention_period=365
real_time_processing=true
custom_dashboards=true
data_export=true
scheduled_reports=true

[api]
rate_limit_per_minute=10000
concurrent_connections=1000
webhook_retries=5
webhook_timeout=30
api_versioning=true

[integrations]
slack_notifications=true
email_automation=true
third_party_connectors=true
custom_integrations=true
EOF
```

**Step 5c**: Create Redis cache for premium features:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  labels:
    app: redis-cache
    component: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
        component: cache
    spec:
      containers:
      - name: redis
        image: redis:6.2-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cache-service
  labels:
    app: redis-cache
spec:
  selector:
    app: redis-cache
  ports:
  - port: 6379
    targetPort: 6379
    protocol: TCP
  type: ClusterIP
```

**Step 5d**: Create deployment patch for premium features:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: saas-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: FEATURES_ENABLED
          value: "premium"
        - name: REDIS_HOST
          value: "redis-cache-service"
        - name: REDIS_PORT
          value: "6379"
        - name: CACHE_ENABLED
          value: "true"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        volumeMounts:
        - name: premium-config
          mountPath: /etc/premium
      volumes:
      - name: premium-config
        configMap:
          name: premium-config
```

**Step 5e**: Create the premium features component kustomization:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Component

metadata:
  name: premium-features

resources:
- redis.yaml

configMapGenerator:
- name: premium-config
  files:
  - premium-features.conf

secretGenerator:
- name: premium-api-keys
  literals:
  - third-party-analytics-key=premium_analytics_api_key_123
  - payment-gateway-secret=premium_payment_secret_456
  - ai-service-token=premium_ai_service_token_789
- name: premium-integrations
  literals:
  - slack-bot-token=premium_slack_bot_token_abc
  - salesforce-client-secret=premium_sf_client_secret_def
  - stripe-webhook-secret=premium_stripe_webhook_ghi

patches:
- path: deployment-patch.yaml
  target:
    kind: Deployment
    name: saas-app

commonLabels:
  tier: premium
```

### Task 6: Create Tenant-Specific Overlays (12 minutes)
Create different tenant configurations that selectively include components based on subscription tiers.

**Step 6a**: Create basic tier tenant overlay:
```bash
mkdir -p ~/kustomize-components/overlays/tenant-basic
cd ~/kustomize-components/overlays/tenant-basic
```

**Step 6b**: Create basic tenant kustomization:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: tenant-basic

namespace: tenant-basic

resources:
- ../../base

namePrefix: basic-

commonLabels:
  tenant: basic-tier
  subscription: basic

commonAnnotations:
  tenant.saas.com/tier: basic
  tenant.saas.com/features: basic-only
```

**Step 6c**: Create enterprise tier tenant overlay:
```bash
mkdir -p ~/kustomize-components/overlays/tenant-enterprise
cd ~/kustomize-components/overlays/tenant-enterprise
```

**Step 6d**: Create enterprise tenant kustomization with external database and LDAP:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: tenant-enterprise

namespace: tenant-enterprise

resources:
- ../../base

components:
- ../../components/external-database
- ../../components/ldap-auth
- ../../components/monitoring

namePrefix: enterprise-

commonLabels:
  tenant: enterprise-tier
  subscription: enterprise

commonAnnotations:
  tenant.saas.com/tier: enterprise
  tenant.saas.com/features: external-db,ldap,monitoring

patches:
- target:
    kind: Deployment
    name: saas-app
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 3
    - op: replace
      path: /spec/template/spec/containers/0/resources/requests/memory
      value: "256Mi"
    - op: replace
      path: /spec/template/spec/containers/0/resources/limits/memory
      value: "512Mi"
```

**Step 6e**: Create premium tier tenant overlay:
```bash
mkdir -p ~/kustomize-components/overlays/tenant-premium
cd ~/kustomize-components/overlays/tenant-premium
```

**Step 6f**: Create premium tenant kustomization with all components:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

metadata:
  name: tenant-premium

namespace: tenant-premium

resources:
- ../../base

components:
- ../../components/external-database
- ../../components/ldap-auth
- ../../components/monitoring
- ../../components/premium-features

namePrefix: premium-

commonLabels:
  tenant: premium-tier
  subscription: premium

commonAnnotations:
  tenant.saas.com/tier: premium
  tenant.saas.com/features: all-features-enabled
  tenant.saas.com/sla: "99.9%"

patches:
- target:
    kind: Deployment
    name: saas-app
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 5
    - op: add
      path: /spec/template/spec/affinity
      value:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - saas-app
              topologyKey: kubernetes.io/hostname
- target:
    kind: Service
    name: saas-app-service
  patch: |-
    - op: replace
      path: /spec/type
      value: LoadBalancer
```

### Task 7: Deploy and Verify Multi-Tenant Setup (10 minutes)
Deploy all tenant configurations and verify that each has the correct components enabled.

**Step 7a**: Create namespaces and deploy all tenant configurations:
```bash
cd ~/kustomize-components

# Create namespaces
kubectl create namespace tenant-basic
kubectl create namespace tenant-enterprise
kubectl create namespace tenant-premium

# Deploy each tenant
kubectl apply -k overlays/tenant-basic
kubectl apply -k overlays/tenant-enterprise
kubectl apply -k overlays/tenant-premium
```

**Step 7b**: Verify that each tenant has the expected resources and configurations based on their included components.

## Verification Commands

### Verify Basic Tenant (No Components)
```bash
# Check basic tenant resources
kubectl get all -n tenant-basic -l tenant=basic-tier

# Verify base secrets only (no component secrets)
kubectl get secrets -n tenant-basic
kubectl get secrets -n tenant-basic -o jsonpath='{.items[?(@.metadata.name~".*base-secrets")].data.default-admin-password}' | base64 -d

# Verify no component-specific secrets exist
kubectl get secrets -n tenant-basic | grep -E "(database|ldap|monitoring|premium)" || echo "No component secrets found (expected)"

# Check environment variables
kubectl get deployment -n tenant-basic -o jsonpath='{.items[0].spec.template.spec.containers[0].env[*].name}' | tr ' ' '\n'
```

### Verify Enterprise Tenant (Database + LDAP + Monitoring)
```bash
# Check enterprise tenant resources
kubectl get all -n tenant-enterprise -l tenant=enterprise-tier

# Verify component-specific resources exist
kubectl get secret database-credentials -n tenant-enterprise
kubectl get secret ldap-config -n tenant-enterprise
kubectl get servicemonitor -n tenant-enterprise

# Check component-generated secrets
kubectl get secrets -n tenant-enterprise | grep -E "(database|ldap|monitoring)"
kubectl get secret -n tenant-enterprise -o jsonpath='{.items[?(@.metadata.name~".*database-ca-certs")].data.ca-cert\.pem}' | base64 -d
kubectl get secret -n tenant-enterprise -o jsonpath='{.items[?(@.metadata.name~".*ldap-service-account")].data.service-account-password}' | base64 -d

# Check replica count
kubectl get deployment -n tenant-enterprise -o jsonpath='{.items[0].spec.replicas}'

# Verify LDAP environment variables
kubectl get deployment -n tenant-enterprise -o jsonpath='{.items[0].spec.template.spec.containers[0].env[?(@.name=="AUTH_METHOD")].value}'
```

### Verify Premium Tenant (All Components)
```bash
# Check premium tenant resources
kubectl get all -n tenant-premium -l tenant=premium-tier

# Verify all component resources exist
kubectl get secrets -n tenant-premium
kubectl get configmaps -n tenant-premium
kubectl get servicemonitor -n tenant-premium

# Check all component-generated secrets
kubectl get secrets -n tenant-premium | grep -E "(database|ldap|monitoring|premium)"
kubectl get secret -n tenant-premium -o jsonpath='{.items[?(@.metadata.name~".*premium-api-keys")].data.payment-gateway-secret}' | base64 -d
kubectl get secret -n tenant-premium -o jsonpath='{.items[?(@.metadata.name~".*monitoring-credentials")].data.grafana-admin-password}' | base64 -d

# Count total secrets (should include base + all components)
kubectl get secrets -n tenant-premium --no-headers | wc -l

# Check Redis cache deployment
kubectl get deployment redis-cache -n tenant-premium

# Verify service type
kubectl get service -n tenant-premium -o jsonpath='{.items[0].spec.type}'

# Check anti-affinity configuration
kubectl get deployment -n tenant-premium -o jsonpath='{.items[0].spec.template.spec.affinity}'

# Verify premium features environment
kubectl get deployment -n tenant-premium -o jsonpath='{.items[0].spec.template.spec.containers[0].env[?(@.name=="FEATURES_ENABLED")].value}'
```

### Verify Component Labels and Annotations
```bash
# Compare labels across tenants
kubectl get deployments --all-namespaces -l platform=saas -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TIER:.metadata.labels.tenant

# Check component-specific labels
kubectl get all -n tenant-premium -l database=external
kubectl get all -n tenant-premium -l auth=ldap
kubectl get all -n tenant-premium -l monitoring=enabled

# Verify annotations
kubectl get deployments --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.metadata.annotations.tenant\.saas\.com/features}{"\n"}{end}'
```

## Expected Results
- **Basic tenant**: Base application only, 2 replicas, local auth, sqlite database, base secrets only (2 secrets)
- **Enterprise tenant**: Base + external database + LDAP + monitoring, 3 replicas, PostgreSQL, LDAP auth, component secrets (8+ secrets)
- **Premium tenant**: All components enabled, 5 replicas, Redis cache, LoadBalancer service, anti-affinity, all secrets (12+ secrets)
- **Component isolation**: Each component adds specific resources only when included
- **Secret management**: Components contribute domain-specific secrets (DB certs, LDAP creds, monitoring tokens, API keys)
- **Configuration inheritance**: Base configuration inherited and enhanced by components
- **Resource scaling**: Progressive resource allocation based on tenant tier

## Key Learning Points
- **Component architecture**: Creating reusable, modular configuration packages with `kind: Component`
- **Selective composition**: Including components conditionally based on requirements
- **Component patches**: How components can modify base resources through patches
- **Multi-base patterns**: Combining base configurations with multiple components
- **Resource generation**: Components contributing secrets, ConfigMaps, and additional resources
- **Component secret management**: Each component managing domain-specific secrets (certificates, credentials, API keys)
- **Secret composition**: How component secrets combine with base secrets in final deployments
- **Certificate handling**: Managing TLS certificates and CA bundles through secretGenerator
- **Label and annotation inheritance**: How components contribute to resource metadata
- **Advanced transformations**: JSON patches, strategic merges, and complex resource modifications

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Component syntax**: Remember `components:` field in kustomization files, not `resources:`
- **Component validation**: Use `kubectl kustomize` to preview component compositions before applying
- **Resource ordering**: Components are applied after base resources but before patches
- **Label inheritance**: Components contribute labels that merge with base and overlay labels
- **Secret management**: Components can generate secrets alongside ConfigMaps using secretGenerator

### Troubleshooting Tips
- **Component conflicts**: When multiple components patch the same field, last one wins - use strategic merge carefully
- **Missing component resources**: Ensure component kustomization files include all required resources
- **Component secret conflicts**: Multiple components can generate secrets with same name - use unique names
- **Secret file validation**: Verify all files referenced in component secretGenerator exist and are readable
- **Certificate format**: Ensure certificate files are properly base64 encoded for secretGenerator
- **Patch target issues**: Verify that component patches target resources that exist in base
- **Resource name conflicts**: Components inherit name prefixes/suffixes from overlays that include them
- **Circular dependencies**: Avoid components that reference resources from other components
- **Version compatibility**: Component feature requires kubectl 1.21+ and Kustomize v4.1+