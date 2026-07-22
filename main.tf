# ---------------------------------------------------------------------------
# Kubernetes + Helm providers
# They point at the EKS cluster (created or existing) defined in eks.tf.
# ---------------------------------------------------------------------------
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  # When we created the cluster, use the exec auth plugin; else use the token.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--region",
      var.aws_region,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        var.cluster_name,
        "--region",
        var.aws_region,
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# 1) Namespace for KEDA
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "keda" {
  metadata {
    name = var.keda_namespace
  }
}

# ---------------------------------------------------------------------------
# 2) Install KEDA via the official Helm chart
#    This is the "Helm chart templates" deliverable from the ticket.
# ---------------------------------------------------------------------------
resource "helm_release" "keda" {
  name       = "keda"
  repository = var.keda_chart_repo
  chart      = "keda"
  version    = var.keda_chart_version
  namespace  = kubernetes_namespace.keda.metadata[0].name

  # Sane defaults; override via -var or tfvars as needed.
  set {
    name  = "operator.replicaCount"
    value = "1"
  }

  # Wait for the chart to be ready before considering apply complete.
  wait          = true
  timeout       = 600
  force_update  = false
  atomic        = true
  cleanup_on_fail = true
}

# ---------------------------------------------------------------------------
# 3) Sample ScaledObject: scale the SQS consumer on queue depth.
#    Satisfies "configure an event resource like SQS" + overridable defaults.
# ---------------------------------------------------------------------------
resource "kubernetes_manifest" "scaled_object" {
  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = var.scaled_object_name
      namespace = kubernetes_namespace.keda.metadata[0].name
      labels = {
        app = var.scaled_object_workload
      }
    }
    spec = {
      scaleTargetRef = {
        name = var.scaled_object_workload
      }
      minReplicaCount = var.scaled_object_min_replicas
      maxReplicaCount = var.scaled_object_max_replicas
      cooldownPeriod  = var.scaled_object_cooldown
      pollingInterval = var.scaled_object_polling_interval
      triggers = [
        {
          type = "aws-sqs-queue"
          metadata = {
            queueURL    = var.sqs_queue_url
            queueLength = var.sqs_queue_length
            awsRegion   = var.aws_region
            # Identity: uses the pod's IAM role (IRSA) by default.
          }
        }
      ]
    }
  }

  depends_on = [helm_release.keda]
}
