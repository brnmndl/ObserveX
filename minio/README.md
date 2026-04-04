# MinIO on Kubernetes (Mac mini)

This setup deploys MinIO as a self-hosted S3-compatible object store in your Kubernetes cluster.

## What is Included

- Namespace: `observex-storage`
- Credentials secret template
- Persistent volume claim (100Gi)
- MinIO deployment (single-node)
- ClusterIP service (API + Console)
- Optional Ingress resource

## Prerequisites

- Kubernetes cluster running on your Mac mini
- `kubectl` configured to your cluster
- A StorageClass named `local-path` (default in many k3s setups)
- Optional: NGINX Ingress Controller if you want DNS-style access

## 1) Create and Review Credentials

Copy and edit the secret template:

- `minio/k8s/secret.example.yaml`

Set strong values for:

- `MINIO_ROOT_USER`
- `MINIO_ROOT_PASSWORD`

Create the Kubernetes secret (recommended):

```bash
kubectl -n observex-storage create secret generic minio-credentials \
	--from-literal=MINIO_ROOT_USER='your-admin-user' \
	--from-literal=MINIO_ROOT_PASSWORD='your-very-strong-password'
```

## 2) Deploy MinIO

Apply manifests:

```bash
kubectl apply -f minio/k8s/namespace.yaml
kubectl apply -f minio/k8s/pvc.yaml
kubectl apply -f minio/k8s/deployment.yaml
kubectl apply -f minio/k8s/service.yaml
```

Check rollout:

```bash
kubectl -n observex-storage get pods
kubectl -n observex-storage rollout status deploy/minio
```

## 3) Access MinIO

### Option A: Port Forward (quickest)

```bash
kubectl -n observex-storage port-forward svc/minio 9000:9000 9001:9001
```

Then open:

- API: http://localhost:9000
- Console: http://localhost:9001

### Option B: Ingress (optional)

If you have NGINX Ingress:

```bash
kubectl apply -f minio/k8s/ingress.yaml
```

Add these entries in `/etc/hosts` pointing to your ingress IP:

- `minio.local`
- `s3.local`

Then open:

- Console: http://minio.local
- S3 API: http://s3.local

## Notes for Mac mini Cluster

- For local clusters, single-node MinIO is common and simple.
- This configuration uses a single persistent volume and is best for home lab/dev workloads.
- For production-grade durability, deploy distributed MinIO with multiple nodes/drives.

## Useful Commands

```bash
# Logs
kubectl -n observex-storage logs -f deploy/minio

# Service details
kubectl -n observex-storage get svc minio

# Delete deployment
kubectl delete -f minio/k8s/
```
