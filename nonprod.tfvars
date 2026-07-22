# ─────────────────────────────────────────────────────────────
# nonprod.tfvars — sample non-production values (generated)
# Run: terraform apply -var-file="nonprod.tfvars"
# Replace the SQS URL / account id with your real non-prod values.
# ─────────────────────────────────────────────────────────────

aws_region = "us-east-1"

# Existing non-prod EKS cluster (create_eks = false by default)
create_eks   = false
cluster_name = "keda-nonprod-eks-7f3a"

# KEDA install
keda_namespace     = "keda"
keda_chart_version = "2.14.1"
keda_chart_repo    = "https://kedacore.github.io/charts"

# SQS ScaledObject — sane defaults, all overridable
scaled_object_name            = "sqs-consumer-so"
scaled_object_workload        = "sqs-consumer"
scaled_object_min_replicas    = 0
scaled_object_max_replicas    = 15
scaled_object_cooldown        = 300
scaled_object_polling_interval = 30

# Random-but-plausible SQS values — REPLACE with your real non-prod queue
sqs_queue_url  = "https://sqs.us-east-1.amazonaws.com/481265993824/keda-demo-queue-9c2e"
sqs_queue_length = 5

aws_account_id = "481265993824"
