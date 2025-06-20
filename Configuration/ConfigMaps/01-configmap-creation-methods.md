# ConfigMap Creation Methods

## Scenario Overview
**Time Limit**: 15 minutes  
**Difficulty**: Beginner  
**Environment**: k3s bare metal

## Objective
Master various methods of creating ConfigMaps in Kubernetes, understanding the differences between imperative and declarative approaches, and apply best practices for organizing configuration data from diverse sources.

## Context
Your team needs to configure a web application with multiple configuration files and settings. You will explore different ConfigMap creation methods to understand which approach works best for various scenarios and data sources, focusing on practical creation and verification.

## Prerequisites
- k3s cluster running
- kubectl access with admin privileges
- Basic understanding of Kubernetes concepts

## Tasks

### Task 1: Create ConfigMap from literal values (2 minutes)
Create a ConfigMap using imperative commands with literal key-value pairs:
- **ConfigMap Name**: `app-settings`
- **Literal Values**:
  - `app.name=WebApp`
  - `app.version=1.2.3`
  - `app.environment=development`
  - `debug.enabled=true`

**Hint**: Use `kubectl create configmap` with `--from-literal` flags.

### Task 2: Create ConfigMap from individual files (4 minutes)
Create configuration files and then create a ConfigMap from them using custom key names:

**Step 2a**: Create the configuration files with this exact content:

Create `app.properties` file with these settings:
```
# Application Configuration
server.port=8080
server.host=0.0.0.0
logging.level=INFO
cache.enabled=true
cache.size=1000
session.timeout=30m
```

Create `database.conf` file with these settings:
```
# Database Configuration
host=localhost
port=5432
database=webapp
username=appuser
pool.min=5
pool.max=20
timeout=30s
ssl.enabled=false
```

**Step 2b**: Create ConfigMap from these files:
- **ConfigMap Name**: `app-config-files`
- **Requirements**: 
  - Use custom key name `application-properties` for the `app.properties` file
  - Use custom key name `database-config` for the `database.conf` file

**Hint**: Use `kubectl create configmap` with `--from-file=custom-key=filename` syntax.

### Task 3: Create ConfigMap from directory (4 minutes)
Create multiple configuration files in a directory and create ConfigMap from the entire directory:

**Step 3a**: Create a `config/` directory with these files:

Create `config/logging.yaml` with this logging configuration:
```
# Logging Configuration
version: 1
formatters:
  default:
    format: '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
handlers:
  console:
    class: logging.StreamHandler
    formatter: default
    level: INFO
loggers:
  root:
    level: INFO
    handlers: [console]
```

Create `config/api-config.json` with this API configuration:
```
{
  "api": {
    "version": "v1",
    "base_url": "/api/v1",
    "rate_limit": {
      "requests_per_minute": 100,
      "burst_size": 10
    },
    "authentication": {
      "method": "jwt",
      "token_expiry": "24h"
    },
    "cors": {
      "enabled": true,
      "allowed_origins": ["*"]
    }
  }
}
```

**Step 3b**: Create ConfigMap from the entire directory:
- **ConfigMap Name**: `config-directory`
- **Source**: All files in the `config/` directory

**Hint**: Use `kubectl create configmap` with `--from-file=directory/` syntax.

### Task 4: Create ConfigMap using YAML manifest (3 minutes)
Create a ConfigMap using declarative YAML approach with these exact specifications:
- **ConfigMap Name**: `web-server-config`
- **Labels**: `app: web-server` and `component: configuration`
- **Single-line data keys**: 
  - `server.name` with value `production-web-server`
  - `server.threads` with value `50`
  - `maintenance.mode` with value `false`
- **Multi-line data key** `nginx.conf` containing:
```
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```
- **Multi-line data key** `environment.properties` containing:
```
NODE_ENV=production
LOG_LEVEL=warn
CACHE_TTL=3600
MAX_CONNECTIONS=1000
```

**Requirements**: 
- Use proper YAML multi-line syntax for the nginx.conf and environment.properties
- Apply the manifest using `kubectl apply`

### Task 5: Create ConfigMap with binary data (2 minutes)
Create a ConfigMap containing both text and binary data using YAML:
- **ConfigMap Name**: `binary-config`
- **Text data section**:
  - Key `config.txt` with value `This is regular text data`
- **Binary data section**:
  - Key `certificate.crt` with base64 encoded value of the string "demo-certificate-content"
  - Key `favicon.ico` with base64 encoded value of the string "fake-favicon-data"

**Requirements**:
- Use the `data` section for text content
- Use the `binaryData` section for base64 encoded content
- Encode the binary values yourself using the `base64` command

**Hint**: Use `echo "your-content" | base64` to encode strings.

## Verification Commands

### Verify Task 1: `app-settings` ConfigMap
```bash
# Check ConfigMap existence and basic details
kubectl get configmap app-settings

# Verify all literal key-value pairs
kubectl get configmap app-settings -o yaml
```

### Verify Task 2: `app-config-files` ConfigMap
```bash
# Check ConfigMap existence and basic details
kubectl get configmap app-config-files

# Verify custom key names and content for app.properties
kubectl get configmap app-config-files -o jsonpath='{.data.application-properties}'
# Expected output: Content of app.properties

# Verify custom key names and content for database.conf
kubectl get configmap app-config-files -o jsonpath='{.data.database-config}'
# Expected output: Content of database.conf
```

### Verify Task 3: `config-directory` ConfigMap
```bash
# Check ConfigMap existence and basic details
kubectl get configmap config-directory

# Verify logging.yaml content
kubectl get configmap config-directory -o jsonpath='{.data.logging\.yaml}'
# Expected output: Content of logging.yaml

# Verify api-config.json content
kubectl get configmap config-directory -o jsonpath='{.data.api-config\.json}'
# Expected output: Content of api-config.json
```

### Verify Task 4: `web-server-config` ConfigMap
```bash
# Check ConfigMap existence and labels
kubectl get configmap web-server-config --show-labels
# Expected labels: app=web-server,component=configuration

# Verify single-line data keys
kubectl get configmap web-server-config -o jsonpath='{.data.server\.name}'
# Expected output: production-web-server
kubectl get configmap web-server-config -o jsonpath='{.data.server\.threads}'
# Expected output: 50

# Verify multi-line data keys (nginx.conf and environment.properties)
kubectl get configmap web-server-config -o jsonpath='{.data.nginx\.conf}'
# Expected output: Full nginx.conf content
kubectl get configmap web-server-config -o jsonpath='{.data.environment\.properties}'
# Expected output: Full environment.properties content
```

### Verify Task 5: `binary-config` ConfigMap
```bash
# Check ConfigMap existence and sections
kubectl get configmap binary-config -o yaml
# Expected: Should show both 'data' and 'binaryData' sections

# Verify text data content
kubectl get configmap binary-config -o jsonpath='{.data.config\.txt}'
# Expected output: This is regular text data

# Verify binary data content (base64 encoded)
kubectl get configmap binary-config -o jsonpath='{.binaryData.certificate\.crt}'
# Expected output: ZGVtby1jZXJ0aWZpY2F0ZS1jb250ZW50
kubectl get configmap binary-config -o jsonpath='{.binaryData.favicon\.ico}'
# Expected output: ZmFrZS1mYXZpY29uLWRhdGE=
```

### Overall verification:
```bash
# Confirm all 5 ConfigMaps are created
kubectl get configmaps
# Expected: app-settings, app-config-files, config-directory, web-server-config, binary-config

# Inspect any ConfigMap in detail
kubectl describe configmap app-settings
kubectl get configmap web-server-config -o yaml
```

## Expected Results

1. **app-settings**: Contains 4 literal key-value pairs
2. **app-config-files**: Contains 2 keys with custom names and file content
3. **config-directory**: Contains multiple keys from directory files with default naming
4. **web-server-config**: Contains mixed single-line and multi-line YAML data with proper labels
5. **binary-config**: Contains both text data and base64 encoded binary data

## Key Learning Points
- **Imperative vs Declarative**: Command-line creation vs YAML manifests
- **Data Sources**: Literals, individual files, directories, inline content
- **Key Naming**: Default filename keys vs custom key names
- **Binary Data**: Separate `binaryData` section with base64 encoding
- **YAML Structure**: Proper syntax for single-line and multi-line data

## Creation Method Summary

| Method | Best For | Key Benefit |
|--------|----------|-------------|
| **Literal Values** | Simple key-value pairs | Quick command-line creation |
| **Individual Files** | Specific configuration files | Custom key naming |
| **Directory** | Multiple related files | Bulk import with default naming |
| **YAML Manifest** | Complex configurations | Version control and templating |
| **Binary Data** | Certificates, images | Handles non-text content |

## Real Exam Tips
- **Imperative vs. Declarative**: Be proficient in both `kubectl create configmap` (imperative) and defining ConfigMaps via YAML (declarative). The exam often tests both.
- **Data vs. BinaryData**: Understand when to use the `data` section for text-based content and `binaryData` for base64-encoded binary content.
- **Volume Mounts and Environment Variables**: While not explicitly covered in this scenario, remember that ConfigMaps are primarily consumed by pods, either by mounting them as volumes or injecting their data as environment variables.
- **Immutability**: Be aware of ConfigMap immutability (though not a core creation concept, it's related to updates).
- **Troubleshooting**: Use `kubectl describe configmap <name>` and `kubectl get configmap <name> -o yaml` for detailed inspection and troubleshooting.
- **`kubectl explain`**: Use `kubectl explain configmap.data` or `kubectl explain configmap.binaryData` during the exam for quick syntax reference.

## Troubleshooting Tips
- **File Not Found**: Ensure files exist before creating ConfigMaps from them.
- **Invalid Keys**: ConfigMap keys must follow DNS subdomain naming rules (e.g., `my-key`, `my.key`, `my_key`).
- **Size Limits**: ConfigMaps have a 1 MiB total size limit. For larger data, consider other storage solutions.
- **Binary Encoding**: Ensure binary content is correctly base64 encoded before placing it in `binaryData`.
- **YAML Syntax**: Always validate YAML syntax and indentation before applying manifests.
- **Data Retrieval**: When verifying, use `kubectl get configmap <name> -o jsonpath='{.data.<key>}'` for specific text data and `{.binaryData.<key>}'` for binary data.