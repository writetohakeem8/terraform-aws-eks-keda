# ---------------------------------------------------------------------------
# OPTIONAL: create an EKS cluster + node group.
# Set create_eks = true to provision. When false, the module only installs
# KEDA into an EXISTING cluster already configured in your kubeconfig.
# ---------------------------------------------------------------------------

# Render the EKS auth/config for the Kubernetes/Helm providers.
# When create_eks = true we use the cluster we just made; otherwise we rely on
# the locally configured kubeconfig context for cluster_name.

data "aws_eks_cluster" "this" {
  count = var.create_eks ? 0 : 1
  name  = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  count = var.create_eks ? 0 : 1
  name  = var.cluster_name
}

# --- Resources created only when create_eks = true ---
resource "aws_eks_cluster" "this" {
  count    = var.create_eks ? 1 : 0
  name     = var.cluster_name
  version  = "1.29"
  role_arn = aws_iam_role.eks[0].arn

  vpc_config {
    endpoint_public_access = true
    subnet_ids             = data.aws_subnets.default[0].ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks[0]]
}

resource "aws_eks_node_group" "this" {
  count           = var.create_eks ? 1 : 0
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = data.aws_subnets.default[0].ids

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.medium"]

  depends_on = [aws_iam_role_policy_attachment.node[0]]
}

# --- IAM roles (only when creating EKS) ---
data "aws_iam_policy_document" "assume_eks" {
  count = var.create_eks ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_node" {
  count = var.create_eks ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks" {
  count              = var.create_eks ? 1 : 0
  name               = "${var.cluster_name}-eks-role"
  assume_role_policy = data.aws_iam_policy_document.assume_eks[0].json
}

resource "aws_iam_role" "node" {
  count              = var.create_eks ? 1 : 0
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_node[0].json
}

resource "aws_iam_role_policy_attachment" "eks" {
  count      = var.create_eks ? 1 : 0
  role       = aws_iam_role.eks[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "node" {
  count      = var.create_eks ? 1 : 0
  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Default VPC subnets for the node group when creating EKS
data "aws_vpc" "default" {
  count = var.create_eks ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.create_eks ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

# --- Provider connection block (decides where Helm/K8s talk to) ---
locals {
  # When we created the cluster, use its endpoint; else use existing kubeconfig.
  cluster_endpoint = var.create_eks ? aws_eks_cluster.this[0].endpoint : data.aws_eks_cluster.this[0].endpoint
  cluster_ca       = var.create_eks ? aws_eks_cluster.this[0].certificate_authority[0].data : data.aws_eks_cluster.this[0].certificate_authority[0].data
  cluster_token    = var.create_eks ? "" : data.aws_eks_cluster_auth.this[0].token
}
