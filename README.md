# KEDA Installation via Terraform + Helm

Installs [KEDA](https://keda.sh) (Kubernetes Event-Driven Autoscaling) into an
EKS cluster using the Terraform Helm provider, plus a sample SQS `ScaledObject`.
Built to satisfy ticket STRY1299865 / STRY1301146 acceptance criteria:
- Install KEDA into Kubernetes SDLC environments
- Use Helm chart templates (Terraform Helm provider)
- Configure an event resource like SQS
- Sane defaults for min/max replicas, cooldown, polling interval, triggers
- Allow developers to override those defaults

## What this does
1. (Optional) Creates an EKS cluster + node group when `create_eks = true`.
2. Installs the KEDA chart via Helm into the `keda` namespace.
3. Deploys a sample `ScaledObject` that scales a deployment on SQS queue depth.

## Usage
```bash
cd "keda installation"
terraform init
terraform plan
terraform apply
```

## Requirements
- Terraform >= 1.3
- AWS CLI configured (aws configure) with EKS permissions
- kubectl + aws eks update-kubeconfig access to the target cluster
- If create_eks = false: an existing EKS cluster and a configured kubeconfig

## Variables (see variables.tf)
- create_eks          : create a new EKS cluster (default false)
- cluster_name        : EKS cluster name to target / create
- aws_region          : AWS region
- keda_namespace      : namespace for KEDA (default "keda")
- keda_chart_version  : KEDA Helm chart version (pinned)
- scaled_object_*     : SQS ScaledObject tuning (min/max replicas, cooldown, polling interval)
- sqs_queue_url       : SQS queue the ScaledObject watches
- sqs_queue_length    : target queue length per replica
```

Overriding defaults example:
```bash
terraform apply \
  -var="scaled_object_min_replicas=1" \
  -var="scaled_object_max_replicas=20" \
  -var="scaled_object_cooldown=60" \
  -var="scaled_object_polling_interval=30" \
  -var="sqs_queue_url=https://sqs.us-east-1.amazonaws.com/123456789012/my-queue"
```
