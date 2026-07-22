# Prerequisites Checklist — from zero to `terraform apply`

Follow this on ANY laptop (your Mac, a client laptop, CI runner). Most
"stuck for a day" problems come from one of these being missing. Tick each
box before you run anything.

## 1. AWS credentials (non-prod account)
- [ ] AWS CLI installed: `aws --version`
- [ ] Credentials configured for the NON-PROD account:
      `aws configure`   (or `export AWS_PROFILE=nonprod`)
- [ ] Confirm you are in the right account:
      `aws sts get-caller-identity`
      -> Account should be the non-prod one, NOT prod.
- [ ] Region matches `aws_region` in your tfvars (default us-east-1).

## 2. Terraform
- [ ] Installed: `terraform version`  (need >= 1.3.0)
- [ ] If missing on macOS: `brew install terraform`

## 3. Kubernetes access to the target EKS cluster
This module (default `create_eks = false`) installs KEDA into an EXISTING
cluster. You must be able to talk to it.
- [ ] `kubectl` installed: `kubectl version --client`
- [ ] Update local kubeconfig to the cluster:
      `aws eks update-kubeconfig --name <cluster_name> --region <region>`
- [ ] Verify you can reach the cluster:
      `kubectl get ns`
      -> If this errors, the cluster name/region/creds are wrong.
- [ ] Your IAM identity is mapped in the cluster aws-auth ConfigMap AND has
      RBAC to create namespaces + CRDs + workloads. (See
      iam-nonprod-eks-existing.txt for the keda-rbac.yaml block.)
      Quick test: `kubectl auth can-i create crd`  should return `yes`.

## 4. IAM permissions
- [ ] Terraform-running principal has eks:DescribeCluster + eks:GetToken
      (MODE A — existing cluster). See iam-nonprod-eks-existing.txt.
- [ ] If `create_eks = true`, also need eks:*/iam:*/ec2:* per
      iam-nonprod-eks-create.txt.
- [ ] SQS consumer pod role has sqs:* read on the queue (MODE C).

## 5. SQS queue (for the ScaledObject to actually scale)
- [ ] A real SQS queue exists in the same region.
- [ ] Set `sqs_queue_url` in your tfvars to that queue's URL.
- [ ] Queue name matches the IRSA policy resource ARN.

## 6. Run order
```bash
cd terraform-aws-eks-keda
terraform init
terraform validate
terraform plan -var-file=nonprod.tfvars
terraform apply -var-file=nonprod.tfvars
```
Then apply the sample consumer:
```bash
kubectl apply -f sqs-consumer.yaml
```

## Common "stuck" causes (and the fix)
| Symptom | Cause | Fix |
|---------|-------|-----|
| AccessDenied on DescribeCluster | wrong AWS profile / account | `aws sts get-caller-identity` |
| kubectl: Unable to connect | kubeconfig not updated | `aws eks update-kubeconfig ...` |
| CRD create fails | IAM not in aws-auth / no RBAC | add to aws-auth + apply keda-rbac.yaml |
| ScaledObject does nothing | wrong sqs_queue_url / pod lacks SQS perms | fix tfvars + IRSA policy |
| EKS create needs subnet_ids | only if create_eks=true | already handled in eks.tf |
