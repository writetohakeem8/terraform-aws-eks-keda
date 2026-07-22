variable "aws_region" {
  description = "AWS region for the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "create_eks" {
  description = "If true, Terraform creates a new EKS cluster + node group. If false, it targets an existing cluster via kubeconfig."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the EKS cluster to create or target"
  type        = string
  default     = "keda-demo-cluster"
}

variable "keda_namespace" {
  description = "Kubernetes namespace where KEDA is installed"
  type        = string
  default     = "keda"
}

variable "keda_chart_version" {
  description = "Version of the KEDA Helm chart to install (pinned for reproducibility)"
  type        = string
  default     = "2.14.1" # KEDA 2.14.x
}

variable "keda_chart_repo" {
  description = "Helm repository URL for the KEDA chart"
  type        = string
  default     = "https://kedacore.github.io/charts"
}

# --- SQS ScaledObject tuning (sane defaults, all overridable) ---
variable "scaled_object_name" {
  description = "Name of the KEDA ScaledObject"
  type        = string
  default     = "sqs-scaledobject"
}

variable "scaled_object_workload" {
  description = "Name of the Kubernetes Deployment the ScaledObject scales"
  type        = string
  default     = "sqs-consumer"
}

variable "scaled_object_min_replicas" {
  description = "Minimum replicas (KEDA default)"
  type        = number
  default     = 0
}

variable "scaled_object_max_replicas" {
  description = "Maximum replicas (KEDA default)"
  type        = number
  default     = 10
}

variable "scaled_object_cooldown" {
  description = "Cooldown period in seconds before scaling down"
  type        = number
  default     = 300
}

variable "scaled_object_polling_interval" {
  description = "Polling interval in seconds for the SQS trigger"
  type        = number
  default     = 30
}

variable "sqs_queue_url" {
  description = "SQS queue URL the ScaledObject watches (override per environment)"
  type        = string
  default     = "https://sqs.us-east-1.amazonaws.com/000000000000/REPLACE-ME"
}

variable "sqs_queue_length" {
  description = "Target queue length per replica (KEDA trigger threshold)"
  type        = number
  default     = 5
}

variable "aws_account_id" {
  description = "AWS account ID (used for IRSA / auth). Auto-detected when empty."
  type        = string
  default     = ""
}
