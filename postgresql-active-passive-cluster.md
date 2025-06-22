# PostgreSQL Active-Passive Cluster with StatefulSets

## Overview

This document provides a complete implementation guide for setting up a PostgreSQL active-passive cluster using Kubernetes StatefulSets. The setup includes one primary instance (handles writes) and one replica instance (receives streamed data from primary).

## Architecture

- **Single StatefulSet**: One StatefulSet managing multiple PostgreSQL pods
- **Ordinal-based Naming**: Pods named `postgres-cluster-0`, `postgres-cluster-1`, etc.
- **Convention-based Primary**: `postgres-cluster-0` is primary by default
- **Dynamic Role Labels**: Roles assigned via Kubernetes labels (`role: primary/replica`)
- **Write Service**: Routes to pod with `role: primary` label
- **Read Service**: Routes to pods with `role: replica` label
- **Easy Scaling**: `kubectl scale` naturally adds/removes replicas
- **Failover**: Label-based role switching between any pods in cluster

## Key Concepts

### Service Types Explained

**Regular Service (`postgres-primary`)**:
- Has a ClusterIP that load balances traffic
- Used by applications to connect to PostgreSQL
- Abstracts away individual pod identities

**Write Service (`postgres-write`)**:
- Has a ClusterIP that routes to the current primary
- Uses `role: primary` label selector
- Applications use this for write operations

**Read Service (`postgres-read`)**:
- Routes to replica nodes using `role: replica` label selector
- Can load balance across multiple replicas
- Applications use this for read-only operations

**Headless Services**:
- Required by StatefulSets for stable network identities
- Enable direct pod-to-pod communication for replication
- Each StatefulSet gets its own headless service

## Implementation

### 1. Secrets and ConfigMaps

```yaml
# PostgreSQL configuration (shared by both nodes)
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  postgresql.conf: |
    listen_addresses = '*'
    wal_level = replica
    max_wal_senders = 3
    wal_keep_segments = 64
    hot_standby = on
  pg_hba.conf: |
    # Allow replication connections
    host replication replicator 0.0.0.0/0 md5
    # Allow normal connections
    host all all 0.0.0.0/0 md5
    # Local connections
    local all all trust

---
# Init script to create replication user (shared by both nodes)
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init
data:
  01-create-replication-user.sql: |
    CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'replicator';

---
# Secret for passwords
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  password: cG9zdGdyZXM=  # postgres (base64)
  replication-password: cmVwbGljYXRvcg==  # replicator (base64)
```

### 2. PostgreSQL Cluster StatefulSet

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-cluster-init
data:
  init-replica.sh: |
    #!/bin/bash
    set -e
    
    # Get the pod ordinal (0, 1, 2, etc.)
    ORDINAL=${HOSTNAME##*-}
    
    if [ "$ORDINAL" = "0" ]; then
      # Pod 0 is the primary - initialize database if needed
      echo "Initializing as primary (pod 0)"
      
      if [ ! -f "$PGDATA/PG_VERSION" ]; then
        echo "Creating new database cluster..."
        initdb -D "$PGDATA" -U postgres --pwfile=<(echo "$POSTGRES_PASSWORD")
        
        # Create database if specified
        if [ -n "$POSTGRES_DB" ] && [ "$POSTGRES_DB" != "postgres" ]; then
          echo "Creating database: $POSTGRES_DB"
          pg_ctl -D "$PGDATA" -l /tmp/postgres.log start
          createdb -U postgres "$POSTGRES_DB"
          pg_ctl -D "$PGDATA" stop
        fi
        
        # Run any init scripts
        if [ -d /docker-entrypoint-initdb.d ]; then
          echo "Running initialization scripts..."
          pg_ctl -D "$PGDATA" -l /tmp/postgres.log start
          for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
              *.sql) echo "Executing $f"; psql --username=postgres --dbname=postgres -f "$f" ;;
              *.sh)  echo "Sourcing $f"; . "$f" ;;
            esac
          done
          pg_ctl -D "$PGDATA" stop
        fi
      fi
      
      # Start PostgreSQL with configuration
      exec postgres -c config_file=/etc/postgresql/postgresql.conf -c hba_file=/etc/postgresql/pg_hba.conf
    else
      # Other pods are replicas - initialize from primary
      echo "Initializing as replica (pod $ORDINAL)"
      
      if [ ! -f "$PGDATA/PG_VERSION" ]; then
        echo "Performing base backup from primary..."
        PGPASSWORD=$POSTGRES_REPLICATION_PASSWORD pg_basebackup \
          -h postgres-cluster-0.postgres-headless \
          -D "$PGDATA" \
          -U replicator \
          -v -P -W -R
      fi
      
      # Start PostgreSQL (replica configuration comes from pg_basebackup -R)
      exec postgres
    fi

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
spec:
  serviceName: postgres-headless
  replicas: 3  # Easily scalable
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        # No role label initially - assigned dynamically
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_DB
          value: "myapp"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_REPLICATION_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: replication-password
        - name: PGDATA
          value: /var/lib/postgresql/data
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        - name: postgres-config
          mountPath: /etc/postgresql/postgresql.conf
          subPath: postgresql.conf
        - name: postgres-config
          mountPath: /etc/postgresql/pg_hba.conf
          subPath: pg_hba.conf
        - name: postgres-init
          mountPath: /docker-entrypoint-initdb.d/
        - name: postgres-cluster-init
          mountPath: /usr/local/bin/init-replica.sh
          subPath: init-replica.sh
        command: ["/bin/bash", "/usr/local/bin/init-replica.sh"]
      volumes:
      - name: postgres-config
        configMap:
          name: postgres-config
      - name: postgres-init
        configMap:
          name: postgres-init
      - name: postgres-cluster-init
        configMap:
          name: postgres-cluster-init
          defaultMode: 0755
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 3. Services

```yaml
# Write service (points to current primary)
apiVersion: v1
kind: Service
metadata:
  name: postgres-write
spec:
  selector:
    app: postgres
    role: primary  # Points to whichever pod has primary role
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP

---
# Read service (points to replicas)
apiVersion: v1
kind: Service
metadata:
  name: postgres-read
spec:
  selector:
    app: postgres
    role: replica  # Points to all pods with replica role
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP

---
# Headless service for StatefulSet
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    name: postgres
```

## Deployment Commands

```bash
# Apply all manifests
kubectl apply -f postgres-cluster.yaml

# Wait for StatefulSet to be ready
kubectl rollout status statefulset/postgres-cluster

# Assign initial roles (pod-0 = primary, others = replica)
kubectl label pod postgres-cluster-0 role=primary
kubectl label pod postgres-cluster-1 role=replica
kubectl label pod postgres-cluster-2 role=replica

# Check StatefulSet and pod status
kubectl get statefulsets
kubectl get pods -l app=postgres
kubectl get pods -l role=primary
kubectl get pods -l role=replica

# Check services and endpoints
kubectl get services
kubectl get endpoints postgres-write
kubectl get endpoints postgres-read

# Test connectivity
kubectl run postgres-client --rm -it --image=postgres:15 -- psql -h postgres-write -U postgres
```

## Failover Process

### Label-Based Failover (Any Pod Can Become Primary):

1. **Check current cluster state**:
   ```bash
   kubectl get pods -l app=postgres
   kubectl get pods -l role=primary
   kubectl get pods -l role=replica
   ```

2. **Choose new primary** (can be any replica, e.g., promote postgres-cluster-1):
   ```bash
   # Remove primary role from current primary
   kubectl label pod postgres-cluster-0 role=replica --overwrite
   
   # Assign primary role to chosen replica
   kubectl label pod postgres-cluster-1 role=primary --overwrite
   ```

3. **Promote the new primary inside PostgreSQL**:
   ```bash
   kubectl exec postgres-cluster-1 -- pg_promote
   ```

4. **Verify failover**:
   ```bash
   # Check which pod the write service now points to
   kubectl get endpoints postgres-write
   
   # Verify read service points to remaining replicas
   kubectl get endpoints postgres-read
   
   # Test connectivity
   kubectl run postgres-client --rm -it --image=postgres:15 -- psql -h postgres-write -U postgres
   ```

### Failback Process:

To switch primary back to postgres-cluster-0:

1. **Switch labels back**:
   ```bash
   kubectl label pod postgres-cluster-1 role=replica --overwrite
   kubectl label pod postgres-cluster-0 role=primary --overwrite
   ```

2. **Promote original primary**:
   ```bash
   kubectl exec postgres-cluster-0 -- pg_promote
   ```

## Scaling Operations

### Adding Replicas:

```bash
# Scale up the cluster
kubectl scale statefulset postgres-cluster --replicas=5

# Wait for new pods to be ready
kubectl rollout status statefulset/postgres-cluster

# Assign replica role to new pods
kubectl label pod postgres-cluster-3 role=replica
kubectl label pod postgres-cluster-4 role=replica

# Verify new replicas are receiving read traffic
kubectl get endpoints postgres-read
```

### Removing Replicas:

```bash
# Remove role labels from pods that will be deleted
kubectl label pod postgres-cluster-4 role-
kubectl label pod postgres-cluster-3 role-

# Scale down (StatefulSet removes highest ordinal pods first)
kubectl scale statefulset postgres-cluster --replicas=3

# Verify scaling
kubectl get pods -l app=postgres
```

### Replacing a Specific Pod:

```bash
# Delete a specific pod (StatefulSet will recreate it)
kubectl delete pod postgres-cluster-2

# Wait for recreation
kubectl rollout status statefulset/postgres-cluster

# Re-assign role if it was a replica
kubectl label pod postgres-cluster-2 role=replica
```

## How Streaming Replication Works

### Where the Replication Logic Lives

The streaming replication logic is **built into PostgreSQL itself**, not explicitly defined in the Kubernetes manifests:

**Primary Side**:
- `wal_level = replica` enables WAL logging for replication
- `max_wal_senders = 3` allows up to 3 concurrent replication connections
- `pg_hba.conf` allows replication connections from replica
- PostgreSQL's `walsender` process streams WAL records to replicas

**Replica Side**:
- `pg_basebackup -R` creates `postgresql.auto.conf` with replication settings:
  ```conf
  primary_conninfo = 'host=postgres-primary-headless port=5432 user=replicator'
  ```
- PostgreSQL's `walreceiver` process receives and applies WAL records
- Streaming happens automatically once replica starts

### Monitoring Replication

```bash
# Check current primary and replicas
kubectl get pods -l role=primary
kubectl get pods -l role=replica

# On primary - check WAL senders (replace with actual primary pod)
kubectl exec postgres-cluster-0 -- psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# On replica - check WAL receiver (replace with actual replica pod)
kubectl exec postgres-cluster-1 -- psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"

# Check replication lag on all replicas
for i in 1 2; do
  echo "Replica postgres-cluster-$i lag:"
  kubectl exec postgres-cluster-$i -- psql -U postgres -c \
    "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()));"
done

# Monitor cluster status
kubectl get pods -l app=postgres -o wide
kubectl get endpoints postgres-write postgres-read
```

## Important Notes

- **Single StatefulSet** manages all PostgreSQL pods with consistent configuration
- **Ordinal-based initialization** - pod-0 becomes primary, others initialize as replicas
- **Dynamic role assignment** - any pod can become primary using Kubernetes labels
- **Easy scaling** - `kubectl scale` naturally adds/removes replicas
- **Stable network identities** - pods get predictable DNS names like `postgres-cluster-0.postgres-headless`
- **Persistent storage** - each pod gets its own PVC that survives restarts
- **Streaming replication** - happens automatically inside PostgreSQL processes
- **Label-based services** - write/read services automatically route based on role labels
- **Manual failover** - simple label switching promotes any replica to primary
- **Production consideration** - use operators like Patroni for automatic failover and advanced features

## Production Considerations

- Use resource limits and requests
- Configure proper backup strategies
- Implement monitoring and alerting
- Consider using PostgreSQL operators for advanced features
- Set up proper RBAC and network policies
- Use init containers for more robust replica initialization
- Implement health checks and readiness probes