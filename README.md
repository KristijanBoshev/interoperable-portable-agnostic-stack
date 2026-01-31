# Interoperable Portable Agnostic Stack

This repository provides a single container image and cloud-agnostic Kubernetes base manifests, with an AWS (EKS) overlay and Terraform provisioning for a production-grade cluster.

## What this delivers
- Production-ready EKS cluster using the official Terraform EKS module.
- VPC with private subnets and NAT gateways.
- ECR repository for the application image.
- Kubernetes base manifests with health checks, HPA, and PDB.
- AWS overlay that exposes the service via an NLB.

## Prerequisites
- AWS account and credentials with permissions to create VPC, EKS, IAM, and ECR.
- Terraform >= 1.5
- kubectl
- Docker
- AWS CLI

## End-to-end workflow
### 1) Provision EKS with Terraform
From [infra/terraform](infra/terraform):

1. Initialize and apply:
	- `terraform init`
	- `terraform apply`

2. Configure kubectl using the output:
	- `aws eks update-kubeconfig --region <region> --name <cluster_name>`

> For production, restrict `endpoint_public_access_cidrs` in [infra/terraform/variables.tf](infra/terraform/variables.tf) to trusted IP ranges.

### 2) Build and push the image to ECR
1. Get the ECR repository URL from Terraform output.
2. Build and push:
	- `docker build -t todo-api:latest .`
	- `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com`
	- `docker tag todo-api:latest <account_id>.dkr.ecr.<region>.amazonaws.com/todo-api:latest`
	- `docker push <account_id>.dkr.ecr.<region>.amazonaws.com/todo-api:latest`

### 3) Deploy to EKS
1. Update the image in [k8s/overlays/aws/kustomization.yaml](k8s/overlays/aws/kustomization.yaml).
2. Apply the overlay:
	- `kubectl apply -k k8s/overlays/aws`

3. Get the external endpoint:
	- `kubectl get svc -n todo`

## Production notes
- HPA requires metrics-server. Install it in the cluster if not present.
- For TLS and advanced routing, add AWS Load Balancer Controller and switch to an Ingress.
- The app uses an in-memory database; for real workloads, swap to a managed database (RDS) and update the connection configuration.