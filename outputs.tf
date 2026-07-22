output "keda_namespace" {
  description = "Namespace where KEDA is installed"
  value       = kubernetes_namespace.keda.metadata[0].name
}

output "keda_chart_version" {
  description = "Installed KEDA chart version"
  value       = helm_release.keda.version
}

output "keda_status" {
  description = "KEDA Helm release status"
  value       = helm_release.keda.status
}

output "scaled_object_name" {
  description = "Name of the deployed SQS ScaledObject"
  value       = kubernetes_manifest.scaled_object.manifest.metadata.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = local.cluster_endpoint
}
