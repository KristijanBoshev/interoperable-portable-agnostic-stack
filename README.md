# Interoperable Portable Agnostic Stack

This repository is a deployment-first stack that ships:
- A container image build pipeline
- Kubernetes base manifests plus AWS and on‑prem overlays
- Terraform to provision a production-grade EKS cluster

> The application is a demo; the focus here is on infrastructure and deployment.

---

## Repository layout

- **Container build**: [Dockerfile](Dockerfile)
- **Kubernetes base**: [k8s/base](k8s/base)
  - Deployment: [k8s/base/deployment.yaml](k8s/base/deployment.yaml)
  - Service: [k8s/base/service.yaml](k8s/base/service.yaml)
  - HPA: [k8s/base/hpa.yaml](k8s/base/hpa.yaml)
  - PDB: [k8s/base/pdb.yaml](k8s/base/pdb.yaml)
  - Namespace: [k8s/base/namespace.yaml](k8s/base/namespace.yaml)
  - ServiceAccount: [k8s/base/serviceaccount.yaml](k8s/base/serviceaccount.yaml)
  - Kustomization: [k8s/base/kustomization.yaml](k8s/base/kustomization.yaml)
- **Kubernetes overlays**:
  - AWS: [k8s/overlays/aws](k8s/overlays/aws) using [k8s/overlays/aws/kustomization.yaml](k8s/overlays/aws/kustomization.yaml)
  - On‑prem: [k8s/overlays/onprem](k8s/overlays/onprem) using [k8s/overlays/onprem/kustomization.yaml](k8s/overlays/onprem/kustomization.yaml)
- **GitHub Actions**: [`.github/workflows/docker.yaml`](.github/workflows/docker.yaml)
- **Terraform (EKS + VPC)**: [infra](infra)

---

## 1) Provision AWS infrastructure with Terraform

All Terraform is under [infra](infra).

1) Initialize:

```sh
cd infra
terraform init 
```
Afterwards enter S3 details!

2) Review configuration:
- Variables: [infra/variables.tf](infra/variables.tf)
(Ideally variables should come from Secrets Managaer and not set here as default)

3) Apply:

```sh
terraform apply
```

4) Configure kubectl (from outputs):

```sh
aws eks update-kubeconfig --region <region> --name <cluster_name>
```

---

## 2) Build and publish the container image

### Option A: GitHub Actions (recommended)
The workflow in [`.github/workflows/docker.yaml`](.github/workflows/docker.yaml) builds and pushes to GHCR.

**Trigger by tag:**
```sh
git tag v1.0.0
git push origin v1.0.0
```

**Or manually** from the Actions tab with `release_tag`.

### Option B: Local Docker build (for testing)
Uses the multi‑stage build in [Dockerfile](Dockerfile):

```sh
docker build -t todo-api:local .
```

---

## 3) Deploy to EKS

1) Set the image/tag in [k8s/overlays/aws/kustomization.yaml](k8s/overlays/aws/kustomization.yaml).

2) Apply:

```sh
kubectl apply -k k8s/overlays/aws
```

3) Get the external endpoint:
- The AWS overlay patches the Service to `LoadBalancer` via [k8s/overlays/aws/service-aws.yaml](k8s/overlays/aws/service-aws.yaml)
- Query:

```sh
kubectl get svc -n todo
```

---

## 4) Deploy on‑prem

1) Set the image/tag in [k8s/overlays/onprem/kustomization.yaml](k8s/overlays/onprem/kustomization.yaml).

2) Apply:

```sh
kubectl apply -k k8s/overlays/onprem
```

3) Ensure your ingress controller is installed and matches:
- Ingress spec: [k8s/overlays/onprem/ingress-onprem.yaml](k8s/overlays/onprem/ingress-onprem.yaml)
- Default class: `traefik`
- Host: `<your-domain>`

---

## 5) Kubernetes base behavior

Defined in [k8s/base](k8s/base):

- **Namespace**: `todo` via [k8s/base/namespace.yaml](k8s/base/namespace.yaml)
- **ServiceAccount**: [k8s/base/serviceaccount.yaml](k8s/base/serviceaccount.yaml)
- **Deployment**:
  - Non‑root container security context
  - Probes on `/healthz`
  - Resource requests/limits
  - Read‑only root filesystem
  - Temp volume at `/tmp`
  - See [k8s/base/deployment.yaml](k8s/base/deployment.yaml)
- **Service**:
  - ClusterIP by default
  - See [k8s/base/service.yaml](k8s/base/service.yaml)
- **HPA**:
  - CPU‑based scaling
  - See [k8s/base/hpa.yaml](k8s/base/hpa.yaml)
- **PDB**:
  - Minimum 1 pod available
  - See [k8s/base/pdb.yaml](k8s/base/pdb.yaml)

---

## 6) Argo CD - GitOps

Automatic deployment if you use Argo CD, the app is defined in [k8s/argocd/application.yaml](k8s/argocd/application.yaml) and you can point to your own repo and cluster.

---

## 7) Test deployment URL

```sh
curl https://todo.kristijanboshev.com/healthz
```

---

## 8) Conclusion: Deploying to another cloud

To deploy this stack on a cloud provider other than AWS, you typically need **2 main change areas**:

1) **Terraform cloud-specific modules**
- Replace or add provider-specific infrastructure modules (cluster, networking, load balancer integrations, IAM equivalent, etc.).

2) **Provider-specific Kubernetes overlay (optional but common)**
- Keep using the same base manifests and the same `kubectl apply -k ...` flow.
- Add or adjust only provider-specific patches (for example Service/Ingress annotations and ingress class behavior).

So the deployment process stays the same with Kustomize; the main work is swapping the infrastructure layer for the target cloud and adding a small overlay if that cloud requires specific Kubernetes annotations.
