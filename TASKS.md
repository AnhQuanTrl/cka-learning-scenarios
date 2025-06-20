# CKA Learning Scenarios - Task Tracking

## Project Status Overview
This document tracks the progress of creating CKA exam preparation scenarios based on Kubernetes concepts.

## Completed Tasks ✅

### Storage/StorageClass
- [x] **Directory Structure**: Created `Storage/StorageClass/` folder structure
- [x] **Basic StorageClass Creation**: `01-basic-storageclass-creation.md`
  - Covers StorageClass creation, default StorageClass configuration
  - Focuses on reclaim policies and volume binding modes
  - Includes StatefulSet and Deployment consuming different StorageClasses
  - Comprehensive verification commands and expected results
  - Note: Volume expansion removed (not supported by rancher.io/local-path provisioner)
- [x] **Static vs Dynamic Provisioning**: `02-dynamic-provisioning.md`
  - Compares manual PV creation (static) vs StorageClass automation (dynamic)
  - Side-by-side workflow demonstration using Deployments
  - Shows PV naming patterns and creation order differences
  - Explains when to use each provisioning approach
- [x] **Reclaim Policy Scenario**: `03-reclaim-policy.md`
  - Compares Retain vs Delete reclaim policies with practical demonstration
  - Shows PV behavior when PVCs are deleted (Released vs automatic deletion)
  - Includes data persistence testing and manual cleanup procedures
  - Explains production vs development use cases for each policy
- [x] **Volume Binding Mode Scenario**: `04-volume-binding-mode.md`
  - Compares Immediate vs WaitForFirstConsumer binding modes
  - Demonstrates timing differences in PV creation and binding
  - Shows topology-aware volume placement concepts
  - Includes practical applications consuming different binding modes
- [x] **NFS Storage Comparison Scenario**: `05-nfs-storage-comparison.md`
  - Compares NFS CSI Driver vs NFS Subdir External Provisioner
  - Demonstrates volume isolation, security, and feature differences
  - Shows deployment of both provisioners with practical applications
  - Covers advanced CSI features like volume expansion and snapshots
  - Environment: k3s bare metal with homelab NFS server
- [x] **Digital Ocean CSI Scenario**: `06-digital-ocean-csi.md`
  - Cloud-specific StorageClass configuration and CSI basics
  - Volume expansion: StorageClass with expansion enabled, demonstrate expanding PVC size dynamically
  - Cost-effective DOKS cluster setup and teardown instructions for learning
  - CSI monitoring and observability features

### Storage/VolumeSnapshots
- [x] **Volume Snapshots Scenario**: `01-volume-snapshots.md`
  - VolumeSnapshot, VolumeSnapshotClass, and VolumeSnapshotContent concepts
  - Point-in-time snapshot creation and management
  - Snapshot-to-PVC restoration workflows with PostgreSQL application
  - Advanced snapshot lifecycle and troubleshooting
  - Environment: DigitalOcean Kubernetes (DOKS)
- [x] **Volume Cloning Scenario**: `02-volume-cloning.md`
  - CSI volume cloning using PVC dataSource
  - Direct PVC-to-PVC cloning without intermediate snapshots
  - Clone vs snapshot performance and use case comparison
  - Data independence and isolation testing with MySQL application
  - Environment: DigitalOcean Kubernetes (DOKS)

### Project Setup
- [x] **CLAUDE.md**: Created with project purpose and scenario quality standards
- [x] **Scenario Quality Standards**: Defined clear task instructions, practical applications, and verification requirements

## Pending Tasks 📋

### Storage/StorageClass Scenarios

**All Storage/StorageClass scenarios completed! ✅**

## Future Scenario Categories (Not Started)

### Workloads & Scheduling (15%)
- [ ] Pod scheduling and affinity rules
- [ ] Resource limits and requests
- [ ] DaemonSets and StatefulSets
- [ ] Jobs and CronJobs

### Services & Networking (20%)
- [ ] Service types and endpoints
- [ ] Ingress controllers and rules
- [ ] Network policies
- [ ] DNS and service discovery

### Cluster Architecture (25%)
- [ ] RBAC and security contexts
- [ ] Cluster upgrades
- [ ] etcd backup and restore
- [ ] Node management

### Troubleshooting (30%)
- [ ] Pod and node troubleshooting
- [ ] Application debugging
- [ ] Cluster component issues
- [ ] Log analysis and monitoring

## Notes for Scenario Creation
- **Environment**: Primary focus on k3s bare metal, with Digital Ocean scenarios for cloud-specific features
- **Quality Standards**: Each scenario must include exact task specifications, practical applications, and comprehensive verification
- **Exam Relevance**: Avoid deprecated features, focus on current CKA exam topics
- **Time Management**: Include realistic time limits matching exam conditions

## Current Priority
**Storage domain completed!** ✅ 

**Storage/StorageClass scenarios**: 6 scenarios covering basic concepts through advanced CSI features
**Storage/VolumeSnapshots scenarios**: 2 scenarios covering snapshot and cloning functionality

Ready to move to next CKA domain:
- **Workloads & Scheduling (15%)** - Pod scheduling, resource limits, DaemonSets, StatefulSets, Jobs
- **Services & Networking (20%)** - Service types, Ingress, Network policies, DNS
- **Cluster Architecture (25%)** - RBAC, cluster upgrades, etcd backup, node management  
- **Troubleshooting (30%)** - Pod/node troubleshooting, debugging, log analysis
